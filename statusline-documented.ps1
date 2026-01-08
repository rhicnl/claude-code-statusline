# StatusLine command showing: model, working directory, git branch, and context use percentage
# This script is executed by Claude Code and receives JSON input via stdin containing
# workspace and context window information. It outputs a formatted statusline string.
#
# COLOR CONFIGURATION:
# This script uses ANSI color codes to colorize the statusline components:
#   - Model:         Red    (ANSI code 31m) - Line 132, 138
#   - Directory name: Yellow (ANSI code 33m) - Line 132, 138
#   - Git branch:    Green  (ANSI code 32m) - Line 132
#   - Context usage:  Cyan   (ANSI code 36m) - Line 111, 114, 118
#
# To change colors, replace the ANSI codes in the Write-Output statements:
#   - Find the color code (e.g., [33m for yellow) in the string
#   - Replace with a different code from the color reference list below
#   - Format: $ESC[XXm where XX is the color code
#   - Always reset with $ESC[0m after each colored section
#
# Example: To change directory name from yellow to blue:
#   Change: "$ESC[33m$dir_name$ESC[0m"
#   To:     "$ESC[34m$dir_name$ESC[0m"

  # Define ESC character for ANSI codes (works in PowerShell 5.1+)
  # [char]27 is the ASCII escape character (ESC), used to start ANSI escape sequences
  # ANSI codes allow terminal color formatting (e.g., [33m for yellow, [0m for reset)
  $ESC = [char]27

  # Read all input from stdin until EOF
  # Claude Code pipes JSON data to this script's standard input
  # ReadToEnd() reads the entire input stream as a single string
  $input_text = [Console]::In.ReadToEnd()
  
  # Parse the JSON string into a PowerShell object
  # ConvertFrom-Json converts the JSON text into a nested object structure
  # This allows accessing properties like $input_json.workspace.current_dir
  $input_json = $input_text | ConvertFrom-Json
  
  # Extract the current workspace directory path from the parsed JSON
  # The JSON structure includes workspace.current_dir with the full path
  $current_dir = $input_json.workspace.current_dir

  # Get just the directory name for cleaner display
  # Split-Path -Leaf extracts only the last component of the path (directory name)
  # Example: "C:\Users\John\Projects\myapp" becomes "myapp"
  $dir_name = Split-Path -Leaf $current_dir

  # Extract the active Claude Code model display name from the JSON
  # The JSON structure includes a "model" object with "id" and "display_name" properties
  # Example: { "id": "claude-opus-4-5-20251101", "display_name": "Opus 4.5" }
  # We use display_name for a cleaner, more readable statusline
  $model = $input_json.model.display_name

  # Provide a fallback if model display_name is not available
  # This handles cases where the model field is null or empty
  if ($null -eq $model -or $model -eq "") {
      $model = "unknown"
  }

  # Get git branch
  # Initialize branch variable as empty string (will be used if git command fails)
  $branch = ""
  
  # Try-catch block to safely handle git command execution
  # If git is not installed, not in PATH, or directory is not a git repo, this prevents errors
  try {
      # Execute git command to get the current branch name
      # -C $current_dir: Change directory to current_dir before running git
      # rev-parse --abbrev-ref HEAD: Get the short branch name (e.g., "main" not "refs/heads/main")
      # 2>$null: Redirect stderr to null to suppress error messages if git fails
      $branch = git -C $current_dir rev-parse --abbrev-ref HEAD 2>$null
      
      # Check if the git command exited with an error code
      # $LASTEXITCODE contains the exit code of the last executed command
      # Non-zero exit codes indicate failure (e.g., not a git repo, git not found)
      if ($LASTEXITCODE -ne 0) {
          # Clear branch name if git command failed
          $branch = ""
      }
  } catch {
      # If any exception occurs (e.g., git command not found), set branch to empty string
      # This ensures the script continues even if git is unavailable
      $branch = ""
  }

  # Calculate context window percentage
  # Extract the current_usage object from the JSON, which contains token counts
  $usage = $input_json.context_window.current_usage
  
  # Check if usage data exists (may be null if context window info is unavailable)
  if ($null -ne $usage) {
      # Calculate total tokens used by summing all token types:
      # - input_tokens: Tokens from user input
      # - cache_creation_input_tokens: Tokens used to create cache
      # - cache_read_input_tokens: Tokens read from cache
      # This gives the total current token usage
      $current = $usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens
      
      # Get the total context window size (maximum tokens allowed)
      $size = $input_json.context_window.context_window_size
      
      # Ensure we don't divide by zero and that size is valid
      if ($size -gt 0) {
          # Calculate percentage: (current / size) * 100, then floor to integer
          # [math]::Floor() rounds down to nearest integer (e.g., 45.7% becomes 45%)
          $pct = [math]::Floor($current * 100 / $size)

          # Format token count for human-readable display
          # Converts raw token numbers into abbreviated format:
          # - 1,500,000 tokens -> "1.5M"
          # - 45,000 tokens -> "45.0k"
          # - 500 tokens -> "500"
          if ($current -ge 1000000) {
              # For millions: divide by 1M and format with 1 decimal place + "M" suffix
              $tokens_display = "{0:N1}M" -f ($current / 1000000)
          } elseif ($current -ge 1000) {
              # For thousands: divide by 1000 and format with 1 decimal place + "k" suffix
              $tokens_display = "{0:N1}k" -f ($current / 1000)
          } else {
              # For small numbers: display raw token count
              $tokens_display = $current
          }

          # Format context info with cyan color (ANSI code 36m) and reset (0m)
          # Shows both percentage and token count: "45% (12.3k)"
          $context_info = "$ESC[36m${pct}% (${tokens_display})$ESC[0m"
      } else {
          # If size is 0 or invalid, default to 0% with cyan color
          $context_info = "$ESC[36m0% (0)$ESC[0m"
      }
  } else {
      # If usage data is null/missing, default to 0% with cyan color
      $context_info = "$ESC[36m0% (0)$ESC[0m"
  }

  # Format the status line: model directory_name [branch] context%
  # Check if branch name was successfully retrieved (non-empty string)
  if ($branch) {
      # Output format with branch: "model dir_name [branch] context%"
      # $ESC[31m: Set foreground color to red (for model name)
      # $model: The Claude model name (e.g., "claude-sonnet-4-20250514")
      # $ESC[0m: Reset color to default
      # $ESC[33m: Set foreground color to yellow (for directory name)
      # $dir_name: The directory name (e.g., "myapp")
      # $ESC[0m: Reset color to default
      # $ESC[32m: Set foreground color to green (for branch name)
      # [$branch]: Branch name in brackets (e.g., "[main]")
      # $ESC[0m: Reset color again
      # $context_info: The context percentage already formatted with cyan color
      Write-Output "$ESC[31m$model$ESC[0m $ESC[33m$dir_name$ESC[0m $ESC[32m[$branch]$ESC[0m $context_info"
  } else {
      # Output format without branch: "model dir_name context%"
      # Same as above but without the branch section
      # Used when not in a git repo or git command failed
      Write-Output "$ESC[31m$model$ESC[0m $ESC[33m$dir_name$ESC[0m $context_info"
  }

# ============================================================================
# ANSI COLOR CODE REFERENCE
# ============================================================================
# Use these codes in the format: $ESC[XXm where XX is the code below
# Always reset colors with $ESC[0m after each colored section
#
# STANDARD COLORS (8 colors - widely supported):
#   30m - Black         31m - Red           32m - Green         33m - Yellow
#   34m - Blue          35m - Magenta        36m - Cyan          37m - White
#
# BRIGHT COLORS (8 colors - better visibility):
#   90m - Bright Black  91m - Bright Red    92m - Bright Green  93m - Bright Yellow
#   94m - Bright Blue   95m - Bright Magenta 96m - Bright Cyan   97m - Bright White
#
# RECOMMENDED COLOR COMBINATIONS:
#   Directory:  33m (Yellow) or 93m (Bright Yellow) - Good visibility, neutral
#   Git Branch: 32m (Green)  or 92m (Bright Green)  - Standard git convention
#   Context:    36m (Cyan)   or 96m (Bright Cyan)   - Distinct, easy to read
#
# ALTERNATIVE SUGGESTIONS:
#   Directory:  34m (Blue) or 94m (Bright Blue)     - Professional, calm
#   Git Branch: 35m (Magenta) or 95m (Bright Magenta) - Stands out nicely
#   Context:    31m (Red) or 91m (Bright Red)       - Warning color (use for high %)
#   Context:    32m (Green) or 92m (Bright Green)   - Positive color (use for low %)
#
# NOTES:
#   - Bright colors (90-97) are generally more visible on dark backgrounds
#   - Standard colors (30-37) work well on light backgrounds
#   - Test colors in your terminal to ensure good contrast
#   - Some terminals may not support all ANSI codes
