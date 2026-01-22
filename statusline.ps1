# StatusLine command showing: working directory, git branch, and context use percentage

$ESC = [char]27

$input_text = [Console]::In.ReadToEnd()
$input_json = $input_text | ConvertFrom-Json
$current_dir = $input_json.workspace.current_dir

$dir_name = Split-Path -Leaf $current_dir

$model = $input_json.model.display_name
if ($null -eq $model -or $model -eq "") {
    $model = "unknown"
}

$branch = ""
try {
    $branch = git -C $current_dir rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -ne 0) {
        $branch = ""
    }
} catch {
    $branch = ""
}

$session_name = $input_json.session.name
if ($null -eq $session_name -or $session_name -eq "") {
    $session_name = ""
}

# Define buffer for effective context window
$buffer_tokens = 45000
$size = $input_json.context_window.context_window_size

# Try to get current token usage from multiple possible sources
$current = 0
if ($null -ne $input_json.context_window.current_usage) {
    $usage = $input_json.context_window.current_usage
    # Try direct total field first
    if ($null -ne $usage.total) {
        $current = $usage.total
    } else {
        # Fall back to summing individual token types
        $input_tok = if ($null -ne $usage.input_tokens) { $usage.input_tokens } else { 0 }
        $cache_create_tok = if ($null -ne $usage.cache_creation_input_tokens) { $usage.cache_creation_input_tokens } else { 0 }
        $cache_read_tok = if ($null -ne $usage.cache_read_input_tokens) { $usage.cache_read_input_tokens } else { 0 }
        $current = $input_tok + $cache_create_tok + $cache_read_tok
    }
}

if ($size -gt 0) {
    # Calculate effective size (accounting for 45k buffer)
    $effective_size = $size - $buffer_tokens

    # Try to use pre-calculated percentage if available
    if ($null -ne $input_json.context_window.used_percentage) {
        # Adjust pre-calculated percentage to account for buffer
        $pct = [math]::Floor($input_json.context_window.used_percentage * $size / $effective_size)
    } else {
        # Manual calculation against effective size
        $pct = [math]::Floor($current * 100 / $effective_size)
    }

    # Format current token count
    if ($current -ge 1000000) {
        $current_display = "{0:N1}M" -f ($current / 1000000)
    } elseif ($current -ge 1000) {
        $current_display = "{0:N0}k" -f ($current / 1000)
    } else {
        $current_display = $current
    }

    # Format effective size
    if ($effective_size -ge 1000000) {
        $effective_display = "{0:N1}M" -f ($effective_size / 1000000)
    } elseif ($effective_size -ge 1000) {
        $effective_display = "{0:N0}k" -f ($effective_size / 1000)
    } else {
        $effective_display = $effective_size
    }

    $context_info = "$ESC[36m${pct}% (${current_display}/${effective_display})$ESC[0m"
} else {
    $context_info = "$ESC[36m0% (0/0)$ESC[0m"
}

$session_display = ""
if ($session_name) {
    $session_display = "$ESC[34m[$session_name]$ESC[0m "
}

if ($branch) {
    Write-Output "$ESC[31m$model$ESC[0m $ESC[33m$dir_name$ESC[0m $ESC[32m[$branch]$ESC[0m $session_display$context_info"
} else {
    Write-Output "$ESC[31m$model$ESC[0m $ESC[33m$dir_name$ESC[0m $session_display$context_info"
}
