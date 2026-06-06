# Model Context Protocol (MCP) Servers

MCP servers extend the AI's capabilities to interact with local APIs and tools. They allow the AI to "see" and "do" more within your system.

## Available MCP Servers

| MCP Server | Description |
| :--- | :--- |
| **`fetch`** | Instantly downloads and parses the text content of web URLs without loading a GUI. |
| **`puppeteer`** | Full browser automation, allowing the agent to click buttons, fill forms, and take screenshots. |
| **`postgres`** | Direct, secure connection to local databases (pre-configured for the `gpt_chat_bot` database). |
| **`context7`** | Up-to-date library documentation and code examples. |
| **`codegraph`** | AST-level code graph: semantic search, call chain analysis, impact analysis. |
| **`docs-mcp`** | Multi-format document reader: PDF, DOCX, MD, CSV, OCR (via `go-docs-mcp`). |
| **`lsp-mcp`** | Code intelligence: definitions, references, diagnostics via LSP protocol. |

## Why use MCP?

* **No Context Window Waste:** Instead of pasting large docs or parsing huge files yourself, the AI fetches exactly what it needs.
* **System Visibility:** MCP gives the AI tools to explore your system—databases, browser, and code graph—instead of relying on "guessing" from its training data.
* **Extensibility:** The MCP ecosystem is open. You can add support for new formats, APIs, or custom tools by adding new MCP servers.
