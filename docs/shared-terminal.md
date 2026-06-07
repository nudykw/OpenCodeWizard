# Shared Terminal and 3-Pane Layout

OpenCodeWizard configures WezTerm with a specialized 3-pane layout to create a productive AI-assisted environment. This setup ensures you have full visibility and control over your project while working with the AI.

## The 3-Pane Layout

When you launch OpenCode in the recommended mode, WezTerm splits into three distinct areas:

1.  **OpenCode (Right Pane)**: This is your primary workspace where you talk to the AI assistant. It occupies the right half of the screen.
2.  **Gitui (Top-Left Pane)**: A terminal-based git interface. It provides instant visual feedback on every file the AI modifies.
3.  **Shared Terminal (Bottom-Left Pane)**: A standard, interactive shell that both you and the AI can use.

## Why Gitui?

AI assistants can move fast. Sometimes they modify multiple files in a single turn. Gitui is included in the layout so you don't have to guess what changed. You can see the diffs immediately, stage only what you want, and revert any accidental changes without leaving the terminal. It puts you in the driver's seat of the AI's implementation process.

## The Shared Terminal

The Shared Terminal is a critical part of the OpenCode ecosystem. While OpenCode can run background commands on its own, it has some limitations because it runs in its own isolated process.

### Why it's necessary

*   **Live Streaming Output**: OpenCode's internal command execution isn't ideal for long-running processes like `npm run dev`, `docker-compose up`, or test watchers. The Shared Terminal handles these perfectly, showing you the live, scrolling logs as they happen.
*   **Interactive Prompts**: If a command asks for a password, a confirmation, or any other manual input, you can handle it directly in the Shared Terminal.
*   **Real Shell Environment**: It's a genuine shell (bash, fish, or powershell) with your full environment, aliases, and history.

### How the AI uses it

OpenCode doesn't just "watch" this terminal. It can actually "type" into it. Using the `wezterm cli send-text` command, the AI can send complex commands directly to the Shared Terminal. This allows the AI to start servers, run builds, or execute scripts in a way that you can see and interact with.

## Usage Examples

There are two main ways to interact with the Shared Terminal.

### Mode 1: Per-Command Instructions

Simply include "in the shared terminal" (or "in the terminal") in each request. This is the most transparent approach — you always control where each command is executed.

**Examples:**
*   "Start the development server **in the shared terminal**."
*   "Run the tests **in the terminal** and let me see the output."
*   "Install the dependencies **in the shared terminal** and show me the progress."
*   "Run `git status` **in the terminal**."
*   "Start `npm run build` **in the shared terminal**."

### Mode 2: Session Mode

You can tell the AI once that all subsequent commands should go to the shared terminal, and it will remember this for the rest of the session. This is convenient when you're focused on a single task that requires running many commands.

**Your first message:**
> "Execute all commands in the shared terminal from now on. First, run `git pull`, then install dependencies with `npm install`, and finally run the tests with `npm test`."

**The AI will execute sequentially:**
1. `git pull` → in the shared terminal
2. `npm install` → in the shared terminal (you see the installation progress)
3. `npm test` → in the shared terminal (you see the test results)

**Then you can simply follow up with:**
> "Start the dev server."

The AI understands this should also go to the shared terminal since the session mode is active.

**More session mode examples:**
> "Run `git add .` and `git commit -m 'fix: resolved the bug'`, but show me the diff first."

> "Start `docker-compose up -d` and show me the logs after startup."

> "Find all Node.js processes with `ps aux | grep node` and kill them."

This layout turns your terminal into a unified command center where the AI acts as a pair programmer, while you maintain full oversight through Gitui and the Shared Terminal.
