# OpenCode & WezTerm Setup Wizard (OpenCodeWizard)

*Read this in other languages: [Українська (README.uk.md)](README.uk.md)*

A cross-platform, idempotent, and highly customizable setup wizard to configure **OpenCode** (a local AI coding assistant) and **WezTerm** (a high-performance, GPU-accelerated terminal emulator written in Rust).

This tool is designed to help **both programmers and non-programmers** set up a state-of-the-art AI-assisted command-line environment without any hassle.

> **Not just for coders.** OpenCode is a powerful tool for anyone who works with text and documents:
>
> - ✍️ **Writers, copywriters, journalists** — instantly find information across hundreds of files, summarize research, rewrite drafts
> - 📋 **Document specialists, clerks, office workers** — search through document archives, extract data from PDFs and spreadsheets, automate document processing
> - 📊 **Analysts and researchers** — analyze CSV reports, cross-reference data across documents, generate summaries
> - 🎓 **Students and educators** — research assistance, note organization, study material preparation
> - 📝 **Everyone who works with text** — OpenCode understands natural language. Just ask: *"Find the document about the 2024 budget"* or *"Summarize all PDFs in this folder"*
> - 🖥️ **Sysadmins and everyone who configures a computer** — too lazy to dig through OS menus and config files? Just describe what you need: *"Set swappiness to 10"* or *"Add a DNS server"*. OpenCode reads your system configs, applies the change, and verifies it. **Computer slowing down?** Describe the symptoms and tell OpenCode to check `journalctl`, `htop`, `dmesg` — it will find the root cause, create a fix plan, and **fix it autonomously** without you lifting another finger.
> - 🤖 **What Microsoft and Google only promise** with Copilot — an AI agent that truly understands and controls your computer — is **already working** in OpenCode today. OpenCode has full system visibility: hardware via `/proc` and `lspci`, processes with `ps`/`top`, logs in `/var/log`, disks with `df`/`lsblk`. Anything the terminal can do, OpenCode can do for you.
> - 🔓 **Why big corporations can't ship this** — genuine unsandboxed terminal access is a security liability they won't accept. OpenCode's creators chose radical honesty instead: [read the Security Guide](docs/security.md) to understand exactly how it works, what the real risks are, and how to stay safe.

---

## Table of Contents

- [OpenCode \& WezTerm Setup Wizard (OpenCodeWizard)](#opencode--wezterm-setup-wizard-opencodewizard)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Features](#features)
  - [📖 Beginner's Guide](#-beginners-guide)
  - [Included Components](#included-components)
    - [OpenCode Plugins](#opencode-plugins)
    - [Model Context Protocol (MCP) Servers](#model-context-protocol-mcp-servers)
    - [Supported Document Formats](#supported-document-formats)
  - [How to Use](#how-to-use)
    - [Linux \& macOS](#linux--macos)
    - [Windows 11](#windows-11)
  - [💡 Windows-Specific Features](#-windows-specific-features)
  - [CLI Reference](#cli-reference)
  - [Presets](#presets)
  - [Customizing Plugins, MCP Servers \& Presets](#customizing-plugins-mcp-servers--presets)
  - [Backups \& Restore](#backups--restore)
  - [WezTerm Customizations](#wezterm-customizations)
  - [Setting WezTerm as the Default Terminal](#setting-wezterm-as-the-default-terminal)
    - [Linux:](#linux)
    - [Windows 11:](#windows-11-1)
    - [macOS:](#macos)
  - [Safety \& Idempotency](#safety--idempotency)
  - [🔒 Security](#-security)
    - [At a Glance: Threat Levels](#at-a-glance-threat-levels)
  - [⚖️ License](#️-license)

---

## Introduction

Command-line environments can be intimidating. However, they are incredibly powerful, and with the help of local AI, they become extremely productive and easy to navigate.

**OpenCodeWizard** automates the installation and configuration of **OpenCode** and **WezTerm** to create a unified, beautiful workspace. We configure WezTerm with smooth fonts, a premium dark theme, and split panes, so you can interact with the AI assistant side-by-side with your project files.

![WezTerm with OpenCode Terminal Settings Preview](assets/terminal_preview.gif)

---

## Features

- **Multilingual Support:** Fully translated into **English** and **Ukrainian**.
- **Interactive Onboarding:** Tailored menus that let you install the default bundle instantly or customize your setup step-by-step.
- **Safety Backups:** Automatically copies any existing configuration files (`wezterm.lua` and `opencode.jsonc`) to `.bak` before writing new ones.
- **Desktop Shortcuts:** Optional one-click desktop shortcut creation to launch OpenCode inside WezTerm instantly (Linux & Windows).
- **Windows Context Menu:** Optionally adds "Open in OpenCode" to the folder right-click menu in File Explorer — launches WezTerm with OpenCode already running in the selected folder.
- **Cross-Platform:** Out-of-the-box support for **Ubuntu/Debian**, **Fedora/RHEL**, **Arch/CachyOS**, **macOS**, and **Windows 11**.
- **Session Management:** Learn how to use OpenCode sessions effectively — [read the guide](docs/sessions.md). ⚠️ **Important:** Without understanding how sessions and context work, you cannot work effectively with *any* AI assistant. This is a fundamental skill for getting actual results.
- **Developer Preset:** Automatic gitui setup, dedicated WezTerm workspaces, and specialized hotkeys for git-aware AI coding. [See docs](docs/developer-tools.md).
- **Shared Terminal:** Execute commands in a shared terminal pane directly from OpenCode. [Read more](docs/shared-terminal.md).

---

## 📖 Beginner's Guide

If you are new to AI coding assistants or using the command line, please read our step-by-step:
👉 **[Beginner's Guide (docs/guide.md)](docs/guide.md)**

It covers cloning, launching, choosing AI models, and basic usage instructions.

---

## Included Components

### OpenCode Plugins

During the wizard, you can install the following plugins:

| Plugin Name | Description |
| :--- | :--- |
| **`oh-my-opencode`** | Session management, workspace utilities, and advanced helper CLI commands. |
| **`opencode-mem`** | Long-term Rust RAG memory with hybrid search (BM25 + vector). |
| **`@different-ai/opencode-browser`** | Real browser integration, allowing the AI to browse the web when answering questions. |
| **`@tarquinen/opencode-smart-title`** | Generates smart titles for your active chats automatically based on context. |
| **`opencode-token-speed-plugin`** | Displays real-time model speed (Tokens Per Second, TPS) during streaming. |
| **`DepsCian/opencode-codebase-index`** | Codebase RAG indexing with semantic search, file watching, and auto re-index on changes. |

### [Model Context Protocol (MCP) Servers](docs/mcp.md)

MCP servers extend the AI's capabilities to interact with local APIs and tools. [Read more about available MCP servers](docs/mcp.md).

### Supported Document Formats

Thanks to the **docs-mcp** server configured by OpenCodeWizard, you can work with a wide range of document types directly through the AI:

| Format | Description | Supported |
| --- | --- | --- |
| **PDF** | Scanned documents, reports, forms | ✅ Read + OCR |
| **DOCX** | Microsoft Word documents | ✅ Read |
| **MD** | Markdown notes and documentation | ✅ Read |
| **CSV** | Spreadsheets and data tables | ✅ Read + table extraction |
| **TXT** | Plain text files | ✅ Read |
| **Images** (PNG, JPG, TIFF, BMP) | Screenshots, diagrams, photos of text | ✅ OCR text extraction |

**Can't find your format?** The MCP ecosystem is extensible. With additional MCP servers, you can add support for:

- **EPUB** (ebooks), **ODT** (LibreOffice), **RTF** (rich text)
- **XLSX** (Excel), **PPTX** (PowerPoint)
- **HTML** (web pages), **XML** (structured data)
- **ZIP archives** (scan inside compressed files)
- And more — search for MCP servers in the npm registry or build your own.

---

## How to Use

> [!NOTE]
> Make sure you have [Git](docs/git.md) installed before proceeding.

### Linux & macOS

1. Open your terminal and clone the repository:

   ```bash
   git clone https://github.com/nudykw/OpenCodeWizard.git
   cd OpenCodeWizard
   ```

2. Make the script executable and run:

   ```bash
   chmod +x OpenCodeWizard.sh
   ./OpenCodeWizard.sh
   ```

3. Follow the friendly interactive prompt (defaults are preselected—just press `Enter` to proceed).

### Windows 11

1. Open PowerShell **as Administrator**.
2. Clone the repository and navigate into it:

   ```powershell
   git clone https://github.com/nudykw/OpenCodeWizard.git
   cd OpenCodeWizard
   ```

3. Execute the script:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\OpenCodeWizard.ps1
   ```

---

## 💡 Windows-Specific Features

This section covers everything that's unique to the Windows version of OpenCodeWizard.

### 📋 Folder Context Menu ("Open in OpenCode")

During setup, you can opt to add **"Open in OpenCode"** to File Explorer's right-click menu.

| Right-click on | Action |
|---|---|
| **A folder** | Opens WezTerm in that folder with OpenCode already running |
| **Empty space** (inside a folder) | Same — opens WezTerm in the current folder |

> **Windows 11 note:** The item appears in the **classic** context menu. Press **`Shift + F10`** or select **"Show more options"** to see it. To make it appear in the streamlined menu, set WezTerm as your [default terminal](#setting-wezterm-as-the-default-terminal).

### 🖼️ Unconventional Clipboard (`CTRL + SHIFT + I`)

This is **not** a regular `CTRL+V` paste. The `CTRL+SHIFT+I` hotkey is a file-based image sharing mechanism:

1. Copy an image to your clipboard (`PrintScreen`, `Win+Shift+S`, etc.)
2. Press `CTRL+SHIFT+I` inside WezTerm
3. The image is saved to `Pictures\opencode_screenshots\screenshot_<timestamp>.png`
4. A `@C:/path/to/screenshot.png` reference is typed into your prompt
5. OpenCode reads the image via the `docs-mcp` server

This works because OpenCode's document reader (`docs-mcp`) can access files by path, but cannot directly read the Windows clipboard. The hotkey bridges that gap by writing the clipboard to a file first.

On Linux/macOS, `CTRL+SHIFT+I` also works (Wayland `wl-paste`, X11 `xclip`, macOS `osascript`).

### ⌨️ Basic Terminal Operations

In WezTerm, mouse and keyboard work differently from a regular text editor:

| Action | How |
|---|---|
| **Select / copy** | Left-click drag — **auto-copies** on release |
| **Select word** | Double-click |
| **Select line** | Triple-click |
| **Copy text** (keyboard) | `CTRL + Insert` (standard Windows) |
| **Paste text** | Right-click, `SHIFT + Insert`, or `CTRL + SHIFT + V` |
| **Paste image** | `CTRL + SHIFT + I` (see above) |

> `CTRL+C` sends an interrupt signal (kills the running command). `CTRL+V` is often captured by the program inside the terminal. Use `CTRL+Insert` / `SHIFT+Insert` or `CTRL+SHIFT+C` passthrough (inside OpenCode) / `CTRL+SHIFT+V` instead. But if you select text with the mouse, it's already copied — no keyboard needed.

### ⚙️ PowerShell Execution Policy

OpenCode is installed as `opencode.ps1`, which requires PowerShell's execution policy to allow script execution. The wizard **automatically** sets it to `RemoteSigned` for the current user. No manual action needed.

---

## CLI Reference

| Command | Description |
| :--- | :--- |
| `./OpenCodeWizard.sh` | Run the interactive setup wizard |
| `./OpenCodeWizard.sh --silent [preset]` | Automated setup with optional preset (developer\|standard\|minimal) |
| `./OpenCodeWizard.sh --dry-run` | Preview all changes without applying anything |
| `./OpenCodeWizard.sh --create-backup` | Save a snapshot of current config files |
| `./OpenCodeWizard.sh --restore-backup` | Interactively restore a previous snapshot |
| `./OpenCodeWizard.sh --list-backups` | List all saved backups with timestamps |
| `./OpenCodeWizard.sh --reset` | Wipe all wizard-managed configs (backup created first) |
| `./OpenCodeWizard.sh --remove-backups` | Delete ALL saved backups |
| `./OpenCodeWizard.sh --help` | Show full help with all commands |

On **Windows**, replace `./OpenCodeWizard.sh` with `.\OpenCodeWizard.ps1` and use the equivalent parameters: `-CreateBackup`, `-RestoreBackup`, `-ListBackups`, `-Reset`, `-RemoveBackups`, `-DryRun`.

---

## Presets

The wizard includes three presets that control how many plugins and MCP servers are installed. You'll be prompted to choose during setup, or the **Standard** preset is selected by default.

| Preset | Plugins | MCP Servers | Best For |
| :--- | :--- | :--- | :--- |
| **🍔 Developer** | All 6 plugins + [dev tools](docs/developer-tools.md) | All 7 MCPs | Full-featured AI coding environment |
| **🥪 Standard** | Essential plugins | Core MCPs | Balanced — general use & writing |
| **🥗 Minimal** | Minimal setup | Basic MCPs | Quickest — essential tools only |

---

## Customizing Plugins, MCP Servers & Presets

All plugins and MCP servers are defined in central configuration files located in the `config/` directory:

- **Plugins:** `config/plugins.conf`
- **MCP Servers:** `config/mcp.conf`
- **AI System Prompt:** `config/system_info.md.tpl`

The plugin and MCP files use a simple pipe-separated format (`|`) and are shared by both the Bash (`OpenCodeWizard.sh`) and PowerShell (`OpenCodeWizard.ps1`) versions of the wizard.

**To add or disable a plugin or MCP server:**

1. Open the corresponding configuration file.
2. **To disable:** Add a `#` at the beginning of the line to comment it out.
3. **To enable/add:** Uncomment the line or add a new one following the format.

### Plugin Format (`plugins.conf`):

```text
# name|Description
my-cool-plugin|What this plugin does
```

### MCP Format (`mcp.conf`):

```text
# name|Description|Command
my-mcp|Local tool description|npx -y package-name [args]
```

*Note: Changes to these files automatically propagate to the interactive installation flow next time you run the wizard.*

---

## Backups & Restore

Every time the wizard modifies a config file, it creates a **transactional backup** first.

- **Backup location:** `~/.local/share/opencodeWizard/backups/`
- **Backup ID format:** `ocw-<git_hash>-<YYYYMMDD-HHMMSS>` (unique per session)
- **All files from one session share one ID** — making it easy to identify and restore.

```bash
# Create a manual snapshot
./OpenCodeWizard.sh --create-backup

# Restore interactively (shows list of backups)
./OpenCodeWizard.sh --restore-backup

# Delete all backups
./OpenCodeWizard.sh --remove-backups
```

Restoration is **transactional**: all files are restored together or none at all. A silent pre-restore backup is created automatically before any restore operation.

## WezTerm Customizations

The script sets up a premium terminal layout using the `wezterm.lua` file:

- **Theme:** Catppuccin Mocha (elegant, high-contrast dark theme).
- **Font:** JetBrainsMono Nerd Font Mono (full Unicode/Nerd Font icon coverage for terminals, no mojibake).
- **Hotkeys:**
  - `CTRL + SHIFT + O`: Split pane: gitui (left 40%), OpenCode starts automatically in the right pane.
    [Full hotkey reference →](docs/hotkeys.md)
  - `CTRL + SHIFT + I`: **Unconventional clipboard** — paste clipboard images as `@filepath` references. Works on all platforms. See [Windows-Specific Features](#-windows-specific-features) for details.

> 🛠️ **Developer preset** adds `CTRL+SHIFT+G` (gitui + OpenCode split in new tab), `CTRL+SHIFT+O` (gitui + OpenCode split in current pane), and `CTRL+SHIFT+ALT+G` (gitui + OpenCode split in new workspace). [Full reference →](docs/developer-tools.md)

---

## Setting WezTerm as the Default Terminal

### Linux:

The script automatically handles default registration using three methods:

1. Registers via **`update-alternatives`** (`x-terminal-emulator`).
2. Configures modern Freedesktop **`xdg-terminals.list`** layouts.
3. Appends `export TERMINAL=wezterm` and `export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true` to `~/.bashrc` / `~/.zshrc` without duplicate lines.

> `OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true` fixes Tab switching behaviour — Tab changes only the agent mode (Agent/Edit/Search), not the AI model.

### Windows 11:

Instructions are shown at the end of the PowerShell wizard:

1. Open Windows Terminal (or Settings -> System -> For Developers).
2. Go to the **Startup** section.
3. Change the **Default terminal application** to **WezTerm**.

### macOS:

1. Open Finder -> Applications -> Utilities -> Terminal.app.
2. Go to Preferences -> General -> Shells open with.
3. Set it to the **Default Login Shell**.

---

## Safety & Idempotency

- All commands are **idempotent** (can be re-run safely multiple times).
- Shell RC exports are guarded with `grep` checks to prevent duplicate lines.
- Safe backup copy creations prevent your customized lua/json configs from being accidentally overwritten.

---

## 🔒 Security

> **Working with sensitive documents? Read our full [Security Guide](docs/security.md).**

OpenCode gives AI assistants powerful access to your files and system. Understanding the security model is essential — especially when working with confidential or sensitive data.

**Key facts you should know:**

- OpenCode runs with **your user permissions** — it can read, write, and execute commands
- There is **no OS-level sandbox** — the AI has access to everything you do
- **Prompt injection** is the #1 risk — a malicious file could trick the AI into taking unintended actions
- **Offline mode + local model** eliminates data exfiltration risk, but does not prevent local damage
- **Fewer plugins/MCPs = smaller attack surface**

### At a Glance: Threat Levels

| Risk | Level | Mitigation |
| --- | --- | --- |
| Data exfiltration (offline) | 🟢 None | Air gap (no network) |
| Data exfiltration (online) | 🔴 High | Disable network; use local model |
| File deletion/modification | 🟡 Medium | File permissions, backups |
| Prompt injection | 🔴 High | Don't read untrusted files |
| Session DB theft | 🟡 Medium | `chmod 600`, encrypt |

👉 **Full analysis, attack vectors, safest configuration, and checklist:** [`docs/security.md`](docs/security.md)

---

## ⚖️ License

Distributed under the **MIT License with Ethical Peace Protest Clause**.

> [!IMPORTANT]
> **Ethical Peace Protest Clause (Section 3)**:
> In memory of the lessons of WWII, and as a peaceful humanitarian protest against the unprovoked military aggression, violence, and invasion of Ukraine by the Russian Federation:
>
> 1. This software, its components, or derivatives **MUST NOT be translated or localized into the Russian language** in any UI, resources, or documentation.
> 2. Any deployment **MUST NOT present a Russian language user interface**.
> 3. These restrictions will be automatically repealed upon the complete cessation of military activities, full withdrawal of occupation forces from all internationally recognized territories of Ukraine (borders of 1991), and payment of war reparations.
> 4. All forks and derivatives **MUST preserve active backlinks** to the official parent repository: `https://github.com/nudykw/OpenCodeWizard`.
