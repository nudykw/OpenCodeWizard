# WezTerm Hotkeys Reference

## Standard Splits

| Hotkey | Action |
| ------ | ------ |
| `CTRL+SHIFT+D` | Split pane downward (50%) |
| `CTRL+SHIFT+E` | Split pane right (50%) |
| `CTRL+SHIFT+W` | Close current pane (with confirmation) |

## Developer Preset (git-aware)

| Hotkey | Action |
| ------ | ------ |
| `CTRL+SHIFT+O` | Split current pane: gitui (top-left, 28%) + shared terminal (bottom-left, 12%) + OpenCode (right, 60%) |
| `CTRL+SHIFT+G` | Same layout in a **new tab** |
| `CTRL+SHIFT+ALT+G` | Same layout in a **new workspace** |

### Hotkey Details

All three hotkeys create the same 3-pane layout but differ in **where** they
create it. The layout always consists of: gitui (top-left, 40% of width × 70% of height),
shared terminal (bottom-left, 40% × 30%), and OpenCode (right, 60% width).

#### `CTRL+SHIFT+O` — Split in Current Pane

- **Where**: Splits the **current pane** into the 3-pane layout.
- **When to use**: You are in a shell prompt and want to start coding right here.
- **Limitation**: If you press this from **within OpenCode** (not from a shell), the
  script path will be sent as text into the OpenCode chat instead of executing.
  In that case use `CTRL+SHIFT+G` instead.
- **Layout**:

  ```text
  ┌───────────────────┬───────────────────┐
  │ gitui / shell      │                   │
  │ (top-left, 70%)    │  OpenCode (60%)   │
  ├───────────────────┤                   │
  │ shared terminal   │                   │
  │ (bottom-left, 30%)│                   │
  └───────────────────┴───────────────────┘
  ```text

#### `CTRL+SHIFT+G` — Split in New Tab

- **Where**: Creates a **new WezTerm tab** with the 3-pane layout.
- **When to use**: You want to keep your current tab untouched and work in a separate tab.
- **Advantage**: Works from **anywhere** — even if you're inside OpenCode, `vim`, or any
  other program. The new tab always starts with a fresh shell, so the script runs reliably.
- **Layout**: Same as `CTRL+SHIFT+O` but in a new tab.

#### `CTRL+SHIFT+ALT+G` — Split in New Workspace

- **Where**: Creates a **new WezTerm workspace** (named `git`) with the 3-pane layout.
- **When to use**: You want **full isolation** — switch between workspaces like virtual
  desktops. Each workspace has its own set of tabs and panes.
- **Advantage**: Works from anywhere (like `G`). Workspaces persist until you close them.
  Switch between workspaces with WezTerm's workspace switcher.
- **Layout**: Same as `CTRL+SHIFT+O` but in a new workspace.

#### Conditional gitui

- If the current directory (or its parent) **is a git repository** → gitui starts
  automatically in the top-left pane.
- If the directory **is NOT a git repository** → the top-left pane just shows a
  regular shell prompt (no gitui).

### Shared Terminal

The **shared terminal** (bottom-left) is a regular shell that the AI bot can send commands to.
This allows you to ask the AI to execute commands without leaving the chat.

**Usage:**

1. Press one of the hotkeys above (from a shell, not from within OpenCode)
2. gitui opens in the top-left (only if the folder is a git repository)
3. OpenCode starts in the right pane
4. Ask the AI: *"Run \`npm install\` in the shared terminal"*
5. The AI sends the command via `wezterm cli send-text`
6. Check the result in the bottom-left pane

> **Note:** gitui only appears if the current folder is a git repository.
> Without git, the layout has just shared terminal (left) + OpenCode (right).

See [system_info.md](../.config/opencode/system_info.md) for how the AI finds
the shared terminal pane ID.
