# What is Git and why do you need it?

*Read this in other languages: [Українська (git.uk.md)](git.uk.md)*

Imagine you are working on an important document, book, or project. Usually, we save versions like "report_final," "report_final_v2," and so on. This gets confusing, and if something breaks or gets deleted by mistake, restoring your work is difficult.

**Git** is your personal "time machine" and "archivist" for any files.

* **Up-to-date without fear:** Git remembers every change. If you accidentally delete a paragraph or ruin a file, you can "rewind" its state at any moment to when everything was working perfectly.
* **Revision history:** You can always see **who, when, and what exactly** was changed. No more guessing: "Where did this error come from?" or "Who fixed this?"
* **Managing via communication:** You don't need to learn complex Git commands. You simply write in the chat:

> *"commit my changes"*, *"fix my current work"*, *"push everything to the server"*, or *"send my files to GitHub"*.

OpenCode will perform all technical operations within Git for you.

---

## Working with documents and tools

OpenCode can edit many types of documents, but for complex tasks, it uses specialized instruments:

1. **Tools for OpenCode:** To perform advanced actions (like indexing documents or deep file analysis), OpenCode uses [MCP servers](mcp.md). These are "extensions" that allow the AI to interact with local APIs and data sources.
2. **Tools for you:** To quickly assess the situation or track changes without "cluttering" the AI context, you can use specialized GUI tools (like TortoiseGit, Excel, or Word). OpenCode will help you install and configure these tools for your OS (Windows/Mac/Linux). [Read our guide on session context](sessions.md) to understand why keeping the AI context clean is important.

**Note on file formats:**
Without specific tools, OpenCode cannot read or edit some closed or complex binary formats. However, this is easily bypassed: simply create a [draft document](https://en.wikipedia.org/wiki/Draft_(writing)) in a format like **Markdown** (which OpenCode handles perfectly), and then convert it to the final format. And if you need to know how to convert files, [ask OpenCode](README.md#how-to-use) — it will handle the conversion and formatting for you!

---

### Your remote control center

Let's look at important concepts that will help you work more efficiently.

**What does it mean to "push"?**
It's a command to "send everything from my local machine to the cloud server." When you write in the chat:

> *"push changes"* or *"send my edits to GitHub"*,

your work becomes accessible and secure in the cloud. It is your [backup](https://en.wikipedia.org/wiki/Backup).

**Private vs. Public Repository:**

* **Private repository:** Your personal safe. Only you and those you give a key to can see it. Ideal for personal documents or work projects with confidential information.
* **Public repository:** A showcase. Your project is open to the whole world. Anyone can view it or learn from it.

**GitHub CLI ([gh](https://cli.github.com/)):**
This is a special "remote control" from GitHub developers. It allows you to communicate with the server directly. You just ask in the chat: *"create a repository on GitHub"* or *"create a private repository on GitHub"*, and everything is done in a second without needing to open a browser.

---

### Working on different computers and synchronization

You can work on the same project from a laptop, a desktop PC, or another device.

**How it works through communication:**

1. **On one computer:** You write in the chat: *"fix my changes and push them"*.
2. **On another computer:** You sit down, open the chat, and write: *"pull the latest changes from the cloud"*.

**Synchronizing OpenCode settings:**
You can also synchronize your OpenCode environment settings between different computers. Just ask:

> *"synchronize my settings and plug-ins between these computers"*.

OpenCode will explain how it works, automatically install the necessary utilities, and configure synchronization for you. You can find more details in our [synchronization guide](sessions.md).

**Your main tool is communication.** Remember: OpenCode is your interface to complex technologies. You don't need to be a programmer. Just write in the chat what you want to do, and OpenCode will ensure your work is saved, up-to-date, and accessible from any of your devices.
