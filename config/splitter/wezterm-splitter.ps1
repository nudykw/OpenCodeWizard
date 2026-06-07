#!/usr/bin/env pwsh
# wezterm-splitter — creates 3-pane layout: gitui(optional) | shared terminal + opencode
$ErrorActionPreference = 'Stop'

$GitRoot = git rev-parse --show-toplevel 2>$null

# 1. Split left 40%
$LeftPane = wezterm cli split-pane --left --percent 40

# 2. Split left pane bottom 30% for shared terminal
$SharedPane = wezterm cli split-pane --pane-id $LeftPane --bottom --percent 30

try {
    # 3. Save shared pane ID for bot (unique per pane, NO fallback)
    $SharedPane | Out-File -FilePath "$env:TEMP\wezterm-shared-pane-for-$env:WEZTERM_PANE" -Encoding ascii

    # 4. If git repo, start gitui in top-left pane
    if ($GitRoot) {
      "cd $GitRoot && gitui" | wezterm cli send-text --no-paste --pane-id $LeftPane
    }

    # 5. Start opencode (NOT exec — cleanup runs after)
    opencode -m opencode/deepseek-v4-flash-free
}
finally {
    # 6. Cleanup: kill shared terminal and gitui panes (ignore errors)
    wezterm cli kill-pane --pane-id $SharedPane 2>$null
    wezterm cli kill-pane --pane-id $LeftPane 2>$null
}
