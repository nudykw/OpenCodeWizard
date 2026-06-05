# Git Installation Guide

*Read this in other languages: [Українська (git.uk.md)](git.uk.md)*

[Git](git.md) is a free and open-source distributed version control system designed to handle everything from small to very large projects with speed and efficiency. This guide will help you install [Git](git.md) on your operating system.

---

## 1. Windows

### Option A: Using Windows Package Manager (`winget`) (Recommended)
1. Open PowerShell or Command Prompt.
2. Execute the following command:
   ```powershell
   winget install --id Git.Git -e --source winget
   ```
3. Restart your terminal session for the changes to take effect.

### Option B: Using Standalone Installer
1. Download the installer from the official website: [git-scm.com](https://git-scm.com/download/win).
2. Run the downloaded `.exe` file.
3. Follow the installation wizard steps (the default options are recommended for most users).

---

## 2. macOS

### Option A: Using Homebrew (Recommended)
1. Open Terminal.
2. Install [Git](git.md) by running:
   ```bash
   brew install git
   ```

### Option B: Using Xcode Command Line Tools
1. Open Terminal.
2. Type the following command and press Enter:
   ```bash
   git --version
   ```
3. If [Git](git.md) is not installed, a prompt will appear asking if you want to install it. Click **Install** and follow the instructions.

---

## 3. Linux

Install [Git](git.md) using your distribution's package manager:

### Debian / Ubuntu
```bash
sudo apt update
sudo apt install git -y
```

### Fedora / RHEL
```bash
sudo dnf install git -y
```

### Arch Linux / CachyOS
```bash
sudo pacman -S git --noconfirm
```

---

## Verify Installation

After installing, verify that [Git](git.md) was installed successfully by running the following command in a new terminal window:
```bash
git --version
```
This should output the installed version of [Git](git.md), for example: `git version 2.45.0`.
