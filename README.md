# Claude Code Statusline Configuration

A custom statusline configuration for Claude Code that displays working directory, git branch, and context window usage with token count in the status bar.

## Overview

This configuration adds a custom statusline to Claude Code that shows:
- **Working Directory**: The current directory name (in yellow)
- **Git Branch**: The current git branch name in brackets (in green)
- **Context Usage**: The percentage of context window used with token count (in cyan)

## Files

### `settings.json`
Configuration file that tells Claude Code to use a custom PowerShell script for the statusline.

**Location**: `C:\Users\<YourUsername>\.claude\settings.json`

### `statusline.ps1`
PowerShell script that generates the statusline output. It reads JSON input from Claude Code, extracts workspace and context window information, and formats it with ANSI color codes.

**Location**: `C:\Users\<YourUsername>\.claude\statusline.ps1`

## Setup Instructions

### 1. Create the `.claude` Directory

If it doesn't already exist, create the `.claude` directory in your user folder:

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude" -Force
```

### 2. Create `settings.json`

Create `settings.json` in `C:\Users\<YourUsername>\.claude\` with the following content:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/<YourUsername>/.claude/statusline.ps1\""
  }
}
```

**Important**: Replace `<YourUsername>` with your actual Windows username, and use forward slashes (`/`) in the path even on Windows.

### 3. Create `statusline.ps1`

Create `statusline.ps1` in `C:\Users\<YourUsername>\.claude\` with the script content (see the file in this repository).

### 4. Verify PowerShell Execution Policy

Ensure PowerShell can execute scripts. Run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Alternatively, the command in `settings.json` uses `-ExecutionPolicy Bypass` to avoid this requirement.

## How It Works

1. **Claude Code** reads `settings.json` and executes the configured command
2. **PowerShell** runs `statusline.ps1` with JSON input piped via stdin
3. **The script**:
   - Reads JSON input containing workspace and context window data
   - Extracts the current directory name
   - Attempts to get the git branch name
   - Calculates context window usage percentage and formats token count (k/M)
   - Formats output with ANSI color codes
   - Writes the formatted statusline to stdout

## Output Format

- **Directory**: Yellow (`[33m`)
- **Git Branch**: Green (`[32m`) in brackets `[branch]`
- **Context Usage**: Cyan (`[36m`) as percentage with token count

The token count is displayed in a human-readable format:
- Less than 1,000 tokens: raw number (e.g., `500`)
- 1,000 to 999,999 tokens: thousands with `k` suffix (e.g., `45.2k`)
- 1,000,000+ tokens: millions with `M` suffix (e.g., `1.5M`)

Example output:
```
my-project [main] 45% (123.4k)
```

## Color Customization

### Current Color Configuration

The statusline uses ANSI color codes to colorize each component:
- **Directory name**: Yellow (ANSI code `33m`) - Lines 93, 105 in `statusline.ps1`
- **Git branch**: Green (ANSI code `32m`) - Line 96 in `statusline.ps1`
- **Context usage**: Cyan (ANSI code `36m`) - Lines 79, 82, 86 in `statusline.ps1`

### How to Change Colors

To customize colors, edit `statusline.ps1` and replace the ANSI codes in the `Write-Output` statements:

1. Find the color code (e.g., `[33m` for yellow) in the string
2. Replace with a different code from the reference below
3. Format: `$ESC[XXm` where `XX` is the color code
4. Always reset with `$ESC[0m` after each colored section

**Example**: To change directory name from yellow to blue:
```powershell
# Change this:
Write-Output "$ESC[33m$dir_name$ESC[0m $context_info"

# To this:
Write-Output "$ESC[34m$dir_name$ESC[0m $context_info"
```

### ANSI Color Code Reference

#### Standard Colors (8 colors - widely supported)
| Code | Color     | Code | Color     |
|------|-----------|------|-----------|
| `30m` | Black     | `31m` | Red       |
| `32m` | Green     | `33m` | Yellow    |
| `34m` | Blue      | `35m` | Magenta   |
| `36m` | Cyan      | `37m` | White     |

#### Bright Colors (8 colors - better visibility)
| Code | Color          | Code | Color          |
|------|----------------|------|----------------|
| `90m` | Bright Black  | `91m` | Bright Red    |
| `92m` | Bright Green  | `93m` | Bright Yellow |
| `94m` | Bright Blue   | `95m` | Bright Magenta|
| `96m` | Bright Cyan   | `97m` | Bright White  |

#### Recommended Color Combinations

**Default (Current)**:
- Directory: `33m` (Yellow) or `93m` (Bright Yellow) - Good visibility, neutral
- Git Branch: `32m` (Green) or `92m` (Bright Green) - Standard git convention
- Context: `36m` (Cyan) or `96m` (Bright Cyan) - Distinct, easy to read

**Alternative Suggestions**:
- **Directory**: `34m` (Blue) or `94m` (Bright Blue) - Professional, calm
- **Git Branch**: `35m` (Magenta) or `95m` (Bright Magenta) - Stands out nicely
- **Context**: `31m` (Red) or `91m` (Bright Red) - Warning color (use for high %)
- **Context**: `32m` (Green) or `92m` (Bright Green) - Positive color (use for low %)

#### Color Selection Tips

- **Bright colors** (90-97) are generally more visible on dark backgrounds
- **Standard colors** (30-37) work well on light backgrounds
- Test colors in your terminal to ensure good contrast
- Some terminals may not support all ANSI codes
- Always use `$ESC[0m` to reset colors after each colored section

## Troubleshooting

### Path Issues
- Use forward slashes (`/`) in the path in `settings.json`, even on Windows
- Ensure the path to `statusline.ps1` is correct and uses your actual username
- The path should be absolute, not relative

### PowerShell Execution
- If scripts don't run, ensure execution policy allows it or use `-ExecutionPolicy Bypass` flag
- The `-NoProfile` flag speeds up script execution by skipping profile loading

### Git Branch Not Showing
- Ensure you're in a git repository
- Git must be installed and accessible from PowerShell
- The script silently handles git errors and shows no branch if git fails

### ANSI Colors Not Displaying
- Ensure your terminal/Claude Code supports ANSI color codes
- PowerShell 5.1+ supports ANSI codes natively

## Notes

- This configuration was developed and tested on Windows 10/11
- The script uses PowerShell 5.1+ features (ANSI escape codes)
- Git branch detection gracefully handles non-git directories
- Context window calculation includes input tokens, cache creation tokens, and cache read tokens

## License

This configuration is provided as-is for personal use.
