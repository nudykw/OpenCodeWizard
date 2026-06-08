# GIT OPERATIONS RULE (CRITICAL - FIRST PRIORITY)

**ALGORITHMIC ENFORCEMENT: You MUST use the `question` tool before any git commit or push.**

1. **Trigger:** Before executing `git commit` or `git push` in bash.
2. **Action:** Call the `question` tool with the following parameters:
   - `text`: "Confirm [commit/push] of [brief description of changes]?"
   - `options`: ["Yes", "No"]
3. **Constraint:** You are strictly forbidden from running the git command until the `question` tool returns "Yes".
4. **Scope:** This applies to all repositories, branches, and sessions. No exceptions.

---

# System Environment Details

This file provides the OpenCode AI assistant with details about the current operating system and hardware environment.

- **Operating System:** {{OS_NAME}}
- **Kernel Version:** {{KERNEL_VER}}
- **Processor (CPU):** {{CPU_INFO}}
- **System Memory (RAM):** {{RAM_INFO}}
- **User Shell:** {{SHELL_PATH}} ({{SHELL_NAME}})

## OpenCode Ecosystem

You are running within the OpenCode environment, a specialized ecosystem for AI-driven development. This environment grants you access to:
- **Integrated Tools:** A suite of specialized tools for file operations, codebase analysis, and system interaction.
- **Plugins & Skills:** Extended capabilities defined in your configuration that provide domain-specific workflows.
- **MCP Servers:** Model Context Protocol servers that bridge external data and services directly into your context.

Your behavior is governed by the configurations found in `.opencode/` and `~/.config/opencode/`.

## Shared Terminal (WezTerm)

You can execute commands in a shared terminal via `wezterm cli send-text`.
The shared terminal only exists when opencode is running inside WezTerm.

All output from the shared terminal is automatically captured to a log file:
- **Linux/macOS:** `/tmp/wezterm-shared-output-${WEZTERM_PANE}.log`
- **Windows:** `$env:TEMP\wezterm-shared-output-$env:WEZTERM_PANE.txt`

### Sending Commands

```bash
# Check if shared terminal is available (only works in WezTerm)
if [ -z "$WEZTERM_PANE" ]; then
  echo "Shared terminal not available — run opencode in WezTerm."
  exit 0
fi

# Send a command to the shared terminal
SHARED=$(cat "/tmp/wezterm-shared-pane-for-$WEZTERM_PANE")
echo "your_command" | wezterm cli send-text --no-paste --pane-id "$SHARED"
```

```powershell
# Check if shared terminal is available (Windows)
if (-not $env:WEZTERM_PANE) {
  Write-Host "Shared terminal not available — run opencode in WezTerm."
  exit
}

# Send a command to the shared terminal
$SHARED = Get-Content "$env:TEMP\wezterm-shared-pane-for-$env:WEZTERM_PANE"
"your_command" | wezterm cli send-text --no-paste --pane-id $SHARED
```

### Reading Output

After sending a command, read the log file to see the results.
The log includes raw ANSI escape sequences — always strip them.

```bash
# Read output from the shared terminal log (strip ANSI escapes)
SHARED_LOG="/tmp/wezterm-shared-output-${WEZTERM_PANE}.log"
sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b\][0-9;]*[^\x07]*\x07//g; s/\x1b[=_\>]//g' "$SHARED_LOG" | tail -20
```

```powershell
# Read output from the shared terminal log (Windows)
$SharedLog = "$env:TEMP\wezterm-shared-output-$env:WEZTERM_PANE.txt"
Get-Content $SharedLog -Tail 20
```

**Tip:** To read only new output, save the file size before sending a command,
then read from that offset after the command completes.
