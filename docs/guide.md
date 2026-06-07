# OpenCode & WezTerm Beginner's Guide

*Read this in other languages: [Українська (guide.uk.md)](guide.uk.md)*

Welcome! If you are new to the command line or using local AI assistants, this guide will take you step-by-step from cloning the repository to using your new AI environment.

---

## 📋 Table of Contents

- [1. Cloning the Repository](#1-cloning-the-repository)
- [2. Running the Setup Wizard](#2-running-the-setup-wizard)
- [3. Launching WezTerm & OpenCode](#3-launching-wezterm--opencode)
  - [Opening WezTerm in a Specific Folder](#opening-wezterm-in-a-specific-folder)
- [4. Choosing an AI Model](#4-choosing-an-ai-model)
- [5. How to Use OpenCode](#5-how-to-use-opencode)
  - [Working with Sessions](sessions.md)
  - [Working Directory and File Access](#working-directory-and-file-access)
  - [Interacting with files](#interacting-with-files)
  - [Using Plugins](#using-plugins)
  - [Working with MCP Servers](mcp.md)
- [Shared Terminal](shared-terminal.md)
- [6. Customizing Plugins, MCP Servers & the AI System Prompt](#6-customizing-plugins-mcp-servers--the-ai-system-prompt)
- [7. Backups and Restore](#7-backups-and-restore)

---

## 1. Cloning the Repository

To copy this project to your local machine, open your system terminal (or command prompt) and run:

> [!NOTE]
> Make sure you have [Git](git.md) installed. See the [Git Installation Guide](git.md) for more details.

```bash
git clone https://github.com/nudykw/OpenCodeWizard.git
cd OpenCodeWizard
```

---

## 2. Running the Setup Wizard

### Linux & macOS:

1. Make the script executable:

   ```bash
   chmod +x OpenCodeWizard.sh
   ```

2. Run the script:

   ```bash
   ./OpenCodeWizard.sh
   ```

### Windows 11:

1. Open PowerShell **as Administrator**.
2. Run the script:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\OpenCodeWizard.ps1
   ```

> **Wizard Tip:** The wizard has pre-configured defaults. If you want to install everything with recommended settings, just choose your language and press **Enter** for all subsequent prompts.

---

## 3. Launching WezTerm & OpenCode

Once the wizard completes, open **WezTerm** from your desktop or application list.

- To launch your AI assistant inside WezTerm, press:
  `CTRL + SHIFT + O`
- This will split the terminal screen vertically and start **OpenCode** instantly in the right-hand panel.

---

### Opening WezTerm in a Specific Folder

OpenCode works with the **current directory** — it can see and access all files in the folder where the terminal was opened. To work with your documents, always open WezTerm inside the folder containing your files.

#### Linux

| File Manager | How to Open Terminal Here |
| --- | --- |
| **Nautilus** (GNOME, Ubuntu) | Right-click in the folder → **Open in Terminal** (or press `Ctrl+T` if the Nautilus terminal plugin is enabled) |
| **Dolphin** (KDE) | Right-click in the folder → **Open Terminal** (or press `F4`) |
| **Thunar** (XFCE) | Right-click → **Open Terminal Here** |
| **Nemo** (Cinnamon) | Right-click → **Open in Terminal** |
| Any file manager | Navigate to the folder, then press `` Ctrl+` `` (backtick) to toggle the built-in terminal panel (if available) |

> **Tip:** If "Open in Terminal" doesn't appear, you may need to install the terminal plugin for your file manager:
>
> ```bash
> # For Nautilus (Ubuntu/Debian)
> sudo apt install nautilus-extension-gnome-terminal
>
> # For Nautilus with WezTerm specifically
> sudo apt install nautilus-open-any-terminal
> ```

#### Windows 11

1. Open **File Explorer** and navigate to your folder
2. **Shift + Right-click** on an empty area inside the folder
3. Select **Open in Terminal** (opens Windows Terminal)
4. Type `wezterm` and press Enter, **or** set WezTerm as your default terminal (see [Setting WezTerm as the Default Terminal](../README.md#setting-wezterm-as-the-default-terminal))

> **Alternative:** Type `cmd` or `powershell` in the File Explorer address bar and press Enter — this opens a terminal already in that folder. Then run `wezterm` to switch.

#### macOS

1. Open **Finder** and navigate to your folder
2. **Right-click** the folder (or Ctrl+Click)
3. Go to **Services** → **New Terminal at Folder**
4. This opens the default terminal (Terminal.app or iTerm2). If you want WezTerm, install the [WezTerm CLI](https://wezfurlong.org/wezterm/install.html) and run:

   ```bash
   # From any terminal, open WezTerm in the current directory
   wezterm start
   ```

> **Tip:** To add WezTerm to Finder's toolbar, drag `/Applications/WezTerm.app` onto the toolbar while holding `Cmd`.
>
> **💡 Windows Context Menu:** If you installed the context menu during setup, right-click any folder → **"Open in OpenCode"** to launch WezTerm+OpenCode in that folder. On **Windows 11**, press **`Shift + F10`** or select **"Show more options"**. Full reference: [Windows-Specific Features](../README.md#-windows-specific-features).

---

## 4. Choosing an AI Model

By default, the `CTRL + SHIFT + O` shortcut launches OpenCode using a free model:

```bash
opencode -m opencode/deepseek-v4-flash-free
```

If you wish to use other models (like Claude 3.5 Sonnet or GPT-4o), you can switch models inside the chat:

1. Type `/models` to view all available models.
2. Type `/model provider/model-name` to change model (e.g., `/model openrouter/anthropic/claude-3.5-sonnet`).

> **Note:** Paid models require adding credits to your OpenCode account dashboard.

---

> **💡 Why context matters**
>
> Two people look out a window:
>
> — *See that man across the street? Guess his name.*
> — *No idea. Could be anything.*
> — *Exactly. Without **context** — who he is, where he's from, what I know about him — you can only guess.*
>
> Same with an AI. It knows a lot, but without details about *your* situation it can only guess. It has two sources: what you put in your prompt, and what it can discover using tools called **MCP**.
>
> Ask *"what time is it?"* — the AI checks a time server, finds your IP, figures out your time zone. Works, but wastes space. Ask *"what time is it in New York?"* — one tool. Cleaner.
>
> **No context = guessing. Context = knowing. MCP = seeing for myself.**
>
> ---
>
> **💡 Put Yourself in the AI's Shoes**
>
> Think the AI is being slow or making things up? Let’s put you in the exact same spot, working without proper context.
>
> **Task:** Quickly answer the following question:
> *"How much is 5 + ... = ?"*
>
> **Your reaction:** You probably felt confused or annoyed. Why?
>
> 1. You don't know what number goes in the blank.
> 2. You don't know the expected result (Is it 10? Is it 50?).
> 3. You are missing the "context" of the task.
>
> **Conclusion:** You aren't "slow"—you simply can't answer accurately because you only have a fragment of the data. This is exactly what happens with an AI: when you ask it to "fix this code" or "summarize this document" without providing file access or explaining the goal, it *has* to guess.
>
> **Give the AI context, and it will stop guessing.**

---

## 5. How to Use OpenCode

OpenCode acts as an agentic assistant. You can talk to it in natural language.

> **💡 Working with sessions:** Each conversation in OpenCode is a separate **session**. To get the best results, use fresh sessions for different tasks — [learn more about sessions](sessions.md).

### Working Directory and File Access

OpenCode automatically has access to **all files in the folder where you launched it** (the current working directory). This means:

- You can ask the AI to read, search, or modify any file in this folder
- The AI can navigate into **subfolders** and work with files there
- Files **outside** the current directory can also be accessed if you provide an absolute path, but it's more convenient to open OpenCode from the folder you want to work with

> **In short:** The folder you open the terminal in = the folder OpenCode can see. If your documents are in `~/Documents/Reports/`, open the terminal there.

### Interacting with files

- You can say:
  - *"Read the file `src/App.js` and explain what it does."*
  - *"Help me add a new endpoint to `routes/users.js`."*
  - *"Find all files containing the word 'database' in this directory."*
  - *"Summarize all PDF files in the `reports/` folder."*
  - *"Search through all documents for anything related to the 2024 budget."*
  - *"Create a new directory called `notes` and save a summary there."*
  - *"Compare the CSV files in this folder and tell me what changed."*

### Using Plugins

- **`opencode-mem`** lets OpenCode remember details across different chat sessions.
- **`opencode-token-speed-plugin`** prints the speed of output generation in tokens per second in real-time.

### Working with MCP Servers

[Read the detailed guide about available MCP servers](mcp.md) to understand which tools are available and why you should use them selectively to maintain context quality.

### Shared Terminal

OpenCode can execute commands in a shared terminal pane. This is useful for running tests, build scripts, or any other terminal commands while keeping the AI chat visible. [Learn more about the Shared Terminal](shared-terminal.md).

### Working with Screenshots

OpenCode has integrated browser support through the `puppeteer` MCP server or `@different-ai/opencode-browser` plugin.

1. **Taking a Screenshot**: Simply ask: *"Take a screenshot of <https://github.com>"* or *"Render the UI of <http://localhost:3000> and show it to me"*.
2. **Visual Verification**: The AI agent will launch a headless browser, navigate to the target address, take a screenshot, and analyze the image content to assist you.
3. **Inline Terminal Rendering**: Thanks to WezTerm, any screenshots captured by OpenCode will be rendered directly inside the terminal window inline, allowing you to see exactly what the AI sees without opening an external image viewer.
4. **Pasting Screenshots from Clipboard (⚠️ Not a regular paste)**:
   - **⚠️ This is NOT a standard `CTRL+V` paste.** `CTRL+SHIFT+I` is an **unconventional clipboard** mechanism built into the WezTerm config — it saves the clipboard image to a file on disk (`~/Pictures/opencode_screenshots/`) and types the `@/path/to/image.png` reference so OpenCode can read it via `docs-mcp`.
   - Take a screenshot using your system shortcut (e.g., `PrintScreen`, `Win+Shift+S`, or `Cmd+Shift+4` on macOS) to copy it to your clipboard.
   - Click inside the active OpenCode chat pane in WezTerm and press **`CTRL + SHIFT + I`**.
   - The wizard's built-in script will automatically save the clipboard image to your pictures folder (`~/Pictures/opencode_screenshots/`) and type the `@/path/to/image.png` reference directly into your prompt.
5. **Drag and Drop**: You can also drag and drop any image file directly into the terminal window, or manually type `@` followed by the path to the image file (e.g., `@/path/to/image.png`) to attach it.

---

## 6. Customizing Plugins, MCP Servers & the AI System Prompt

All plugins, MCP servers, and the AI system prompt template are stored in the `config/` directory as simple text files. No need to edit the scripts themselves.

| File | What to configure |
|---|---|
| `config/plugins.conf` | Add or disable plugins (name + description per line) |
| `config/mcp.conf` | Add or disable MCP servers (name + description + command per line) |
| `config/system_info.md.tpl` | **Customize the AI system prompt** template |
| `config/variables.conf` | Define which plugins/MCPs belong to each preset (developer / standard / minimal) |

**To customize the AI system prompt** (the instructions the AI receives at startup):

1. Open `config/system_info.md.tpl` in any text editor
2. Edit the markdown content. Use `{{PLACEHOLDER}}` variables for dynamic system info (OS, CPU, RAM)
3. Save the file and re-run: `./OpenCodeWizard.sh --silent`

**To add a plugin:**

1. Open `config/plugins.conf`
2. Add a new line: `plugin-name|Description of the plugin`
3. Save and re-run the wizard

**To disable an MCP server:**

1. Open `config/mcp.conf`
2. Add a `#` at the beginning of the line: `# fetch|Web fetch MCP|npx -y ...`
3. Save and re-run the wizard

> **Changes take effect immediately** the next time you run the setup script.

---

## 7. Backups and Restore

The wizard prioritizes safety. Every time it modifies a configuration file, it creates a transactional backup.

If you ever want to revert to a previous configuration, use the built-in CLI commands:

- `./OpenCodeWizard.sh --create-backup` : Manually create a backup.
- `./OpenCodeWizard.sh --restore-backup` : Interactive menu to view and restore a previous backup.
- `./OpenCodeWizard.sh --remove-backups` : Delete all stored backups.
- `./OpenCodeWizard.sh --reset` : Wipe all wizard-managed configurations and start fresh.

*(On Windows, use `.\OpenCodeWizard.ps1 -RestoreBackup`, etc.)*
