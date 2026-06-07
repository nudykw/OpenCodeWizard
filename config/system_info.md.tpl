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

### Usage

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

**Note:** Output is NOT returned automatically. Ask the user to check the result
in the shared terminal (bottom-left pane).
