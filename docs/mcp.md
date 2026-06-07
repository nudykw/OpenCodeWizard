# Model Context Protocol (MCP) Servers

*Read this in other languages: [Українська (mcp.uk.md)](mcp.uk.md)*

MCP servers extend the AI's capabilities to interact with local APIs and tools. They allow the AI to "see" and "do" more within your system.

## Available MCP Servers

| MCP Server | Description |
| :--- | :--- |
| **[`fetch`](#fetch)** | Instantly downloads and parses web URLs. |
| **[`puppeteer`](#puppeteer)** | Full browser automation for clicks, forms, and screenshots. |
| **[`postgres`](#postgres)** | Direct, secure connection to local databases. |
| **[`context7`](#context7)** | Up-to-date library documentation and code examples. |
| **[`codegraph`](#codegraph)** | AST-level code graph analysis. |
| **[`docs-mcp`](#docs-mcp)** | Multi-format document reader (PDF, DOCX, etc.). |
| **[`lsp-mcp`](#lsp-mcp)** | Code intelligence (definitions, references, diagnostics). |

---

## Tool Details

### <a name="fetch"></a>`fetch`

Downloads and parses the text content of web URLs.

* **Why use it:** Instead of manually copying and pasting documentation or web pages, just give the URL to the AI. It will "visit" the page and read the text for you.

### <a name="puppeteer"></a>`puppeteer`

Full browser automation.

* **Why use it:** Use this when a page requires clicking buttons or executing JavaScript to see the content. It's much more powerful than [`fetch`](#fetch) but consumes more resources.

### <a name="postgres"></a>`postgres`

Secure connection to local databases.

* **Why use it:** Allows the AI to query your local `gpt_chat_bot` database directly to find information or troubleshoot data issues.
* **Note:** This is typically intended for advanced users or developers working with specific database projects. If you are not working with databases, you can safely disable this tool to save resources.

### <a name="context7"></a>`context7`

Library documentation and code examples.

* **Why use it:** Provides the AI with instant access to the latest documentation, function signatures, and implementation examples for programming libraries.
* **Note:** This tool is intended for programmers. It helps the AI write correct code by "reading" up-to-date manual pages for software libraries. If you are not writing software, you will not need this, and it can be disabled to keep the context clean.

### <a name="codegraph"></a>`codegraph`

AST-level code graph analysis.

* **Why use it:** Allows the AI to "map out" your code structure. It builds a graph of how different files, functions, and classes call each other, helping the AI understand the project architecture.
* **Note:** This tool is strictly for software development. It builds a deep understanding of your codebase, which is only necessary if you are actively modifying or refactoring code. For text editing or document tasks, this tool can be safely disabled.

### <a name="docs-mcp"></a>`docs-mcp`

Multi-format document reader.

* **Why use it:** Allows the AI to read and "chat" with files that aren't just plain text.
* **Examples of what you can do:**
  * **PDFs:** "Summarize this 50-page financial report PDF."
  * **Images (OCR):** "Look at this photo of a handwritten note and type it out for me."
  * **Spreadsheets:** "Extract the total from this CSV budget file."
  * **Word Docs:** "Rewrite this draft proposal (DOCX) in a more professional tone."
* **Note:** This is one of the most useful tools for non-programmers. Keep it enabled if you work with office documents, scanned forms, or research papers. It is very lightweight and only activates when you explicitly ask it to read a document.

### <a name="lsp-mcp"></a>`lsp-mcp`

Code intelligence (definitions, references, diagnostics).

* **Why use it:** This tool connects OpenCode to your editor's "brain" (the Language Server Protocol).
* **For Programmers:** Essential. It allows the AI to:
  * **"Go to definition":** Instantly find where a function or class is defined, even in a huge project.
  * **Find references:** See exactly where a variable or method is used across the entire codebase.
  * **See errors in real-time:** Catch type errors or syntax issues before you even run the code.
* **For Non-Programmers:** Likely not needed. This is a technical tool for navigating complex code structures. If you aren't writing software, disabling this will reduce memory usage and keep the AI focused.
