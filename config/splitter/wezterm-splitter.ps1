#!/usr/bin/env pwsh
# wezterm-splitter — creates 3-pane layout: gitui(optional) | shared terminal + opencode
$ErrorActionPreference = 'Stop'

# [Windows] Suppress NativeCommandError when not in a git repo
#   $ErrorActionPreference='Stop' turns native stderr into error records;
#   we override it locally so `fatal: not a git repository` stays silent.
$GitRoot = &{ $ErrorActionPreference = 'Continue'; git rev-parse --show-toplevel 2>$null } 2>$null
if ($LASTEXITCODE -ne 0 -or -not $GitRoot) { $GitRoot = '' }

# Shared terminal output log (AI reads this to see command results)
$SharedLog = "$env:TEMP\wezterm-shared-output-$env:WEZTERM_PANE.txt"

# 2 layout: git → left col gitui+shared, no-git → shared становится full-height left
if ($GitRoot) {
    $LeftPane = wezterm cli split-pane --left --percent 40
    $SharedPane = wezterm cli split-pane --pane-id $LeftPane --bottom --percent 30 -- powershell -NoExit -Command "Start-Transcript -Path '$SharedLog' -Append"
} else {
    $SharedPane = wezterm cli split-pane --left --percent 40 -- powershell -NoExit -Command "Start-Transcript -Path '$SharedLog' -Append"
}

try {
    # Save shared pane ID for bot (unique per pane, NO fallback)
    $SharedPane | Out-File -FilePath "$env:TEMP\wezterm-shared-pane-for-$env:WEZTERM_PANE" -Encoding ascii

    # If git repo, start gitui in top-left pane
    if ($GitRoot) {
      "cd $GitRoot && gitui" | wezterm cli send-text --no-paste --pane-id $LeftPane
    }

    # Start opencode (NOT exec — cleanup runs after)
    opencode -m opencode/deepseek-v4-flash-free
}
finally {
    # Cleanup: kill shared terminal and gitui panes (ignore errors)
    wezterm cli kill-pane --pane-id $SharedPane 2>$null
    if ($LeftPane) {
        wezterm cli kill-pane --pane-id $LeftPane 2>$null
    }
    # Remove shared terminal log
    Remove-Item -Path "$env:TEMP\wezterm-shared-output-$env:WEZTERM_PANE.txt" -Force -ErrorAction SilentlyContinue
}
