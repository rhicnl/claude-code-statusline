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

$usage = $input_json.context_window.current_usage
if ($null -ne $usage) {
    $current = $usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens
    $size = $input_json.context_window.context_window_size
    if ($size -gt 0) {
        $pct = [math]::Floor($current * 100 / $size)
        if ($current -ge 1000000) {
            $tokens_display = "{0:N1}M" -f ($current / 1000000)
        } elseif ($current -ge 1000) {
            $tokens_display = "{0:N1}k" -f ($current / 1000)
        } else {
            $tokens_display = $current
        }
        $context_info = "$ESC[36m${pct}% (${tokens_display})$ESC[0m"
    } else {
        $context_info = "$ESC[36m0% (0)$ESC[0m"
    }
} else {
    $context_info = "$ESC[36m0% (0)$ESC[0m"
}

if ($branch) {
    Write-Output "$ESC[31m$model$ESC[0m $ESC[33m$dir_name$ESC[0m $ESC[32m[$branch]$ESC[0m $context_info"
} else {
    Write-Output "$ESC[31m$model$ESC[0m $ESC[33m$dir_name$ESC[0m $context_info"
}
