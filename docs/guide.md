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
  - [Running MCP Servers](#running-mcp-servers)
- [6. Customizing Plugins & MCP Servers](#6-customizing-plugins--mcp-servers)
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

> **💡 Windows Context Menu:** If you chose to install the context menu during setup, right-click any folder in File Explorer and select **"Open in OpenCode"** — this launches **WezTerm** with **OpenCode already running** in that folder. On **Windows 11**, you may need to select **"Show more options"** or press **`Shift + F10`** to see it in the classic menu.

---

### Basic WezTerm Operations on Windows

WezTerm is a terminal, not a regular text editor. Mouse and clipboard work differently here:

| Action | How to do it |
|---|---|
| **Select / copy text** | Click and drag with the **left mouse button** — text is **automatically copied** to the clipboard when you release the mouse. No need to press any extra keys. |
| **Select word** | **Double-click** a word to select it (also auto-copies). |
| **Select line** | **Triple-click** a line to select it (also auto-copies). |
| **Paste text** | **Right-click** anywhere in the terminal, **or** press **`CTRL + SHIFT + V`**. |
| **Paste image** | **`CTRL + SHIFT + I`** (see [Working with Screenshots](#working-with-screenshots) above). |

> **Why not `CTRL+C` / `CTRL+V`?** In terminals, `CTRL+C` sends the "interrupt" signal (kills the current command), and `CTRL+V` is often captured by terminal programs. WezTerm uses `CTRL+SHIFT+C/V` for copy/paste to avoid conflicts. If you just select text with the mouse, it's already copied — no need for any keyboard shortcut.

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

### Running MCP Servers
OpenCode can use the following tools automatically:
- **`fetch`**: Ask *"Read the content of https://example.com/api-docs"* to fetch page text.
- **`puppeteer`**: Ask *"Take a screenshot of http://localhost:3000"* to capture webpage visuals.
- **`postgres`**: Ask *"Show me the tables in my local database"* to interact directly with PostgreSQL.
- **`context7`**: Ask *"Find the documentation for Upstash Redis"* to fetch real-time, version-specific library docs.

### Working with Screenshots
OpenCode has integrated browser support through the `puppeteer` MCP server or `@different-ai/opencode-browser` plugin.
1. **Taking a Screenshot**: Simply ask: *"Take a screenshot of https://github.com"* or *"Render the UI of http://localhost:3000 and show it to me"*.
2. **Visual Verification**: The AI agent will launch a headless browser, navigate to the target address, take a screenshot, and analyze the image content to assist you.
3. **Inline Terminal Rendering**: Thanks to WezTerm, any screenshots captured by OpenCode will be rendered directly inside the terminal window inline, allowing you to see exactly what the AI sees without opening an external image viewer.
4. **Pasting Screenshots from Clipboard (⚠️ Not a regular paste)**: 
   - **⚠️ This is NOT a standard `CTRL+V` paste.** `CTRL+SHIFT+I` is an **unconventional clipboard** mechanism built into the WezTerm config — it saves the clipboard image to a file on disk (`~/Pictures/opencode_screenshots/`) and types the `@/path/to/image.png` reference so OpenCode can read it via `docs-mcp`.
   - Take a screenshot using your system shortcut (e.g., `PrintScreen`, `Win+Shift+S`, or `Cmd+Shift+4` on macOS) to copy it to your clipboard.
   - Click inside the active OpenCode chat pane in WezTerm and press **`CTRL + SHIFT + I`**.
   - The wizard's built-in script will automatically save the clipboard image to your pictures folder (`~/Pictures/opencode_screenshots/`) and type the `@/path/to/image.png` reference directly into your prompt.
5. **Drag and Drop**: You can also drag and drop any image file directly into the terminal window, or manually type `@` followed by the path to the image file (e.g., `@/path/to/image.png`) to attach it.

---

## 6. Customizing Plugins & MCP Servers

You can easily modify which plugins and MCP servers are installed by the wizard without any programming knowledge. 

Open `OpenCodeWizard.sh` (or `OpenCodeWizard.ps1` on Windows) in a text editor and look for the arrays at the very top of the script:

```bash
OPENCODE_PLUGINS=(
    "oh-my-openagent|Session management and advanced CLI commands"
    "opencode-mem|Vector and long-term memory for the assistant"
)

OPENCODE_MCP_SERVERS=(
    "fetch|Fast web page text retrieval|npx -y mcp-server-fetch-typescript"
)
```

- **To add a plugin:** Add a new line with `"plugin-name|Description"`.
- **To disable an MCP server:** Add a `#` at the beginning of its line to comment it out.
- Run the setup script again (`./OpenCodeWizard.sh --silent`) to apply your changes.

---

## 7. Backups and Restore

The wizard prioritizes safety. Every time it modifies a configuration file, it creates a transactional backup.

If you ever want to revert to a previous configuration, use the built-in CLI commands:

- `./OpenCodeWizard.sh --create-backup` : Manually create a backup.
- `./OpenCodeWizard.sh --restore-backup` : Interactive menu to view and restore a previous backup.
- `./OpenCodeWizard.sh --remove-backups` : Delete all stored backups.
- `./OpenCodeWizard.sh --reset` : Wipe all wizard-managed configurations and start fresh.

*(On Windows, use `.\OpenCodeWizard.ps1 -RestoreBackup`, etc.)*
