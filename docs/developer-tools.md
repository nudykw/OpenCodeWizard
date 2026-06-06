# Developer Tools Reference

This document describes the additional tools, keybindings, and components that are installed and configured when you select the **Developer** preset in OpenCodeWizard.

## Utilities

### gitui

- **Description:** Git TUI with real-time repository monitoring. Browse diffs, stage files, commit, manage branches, and watch file changes — all from a fast terminal UI.
- **Installation:** Automatic with the **Developer** preset.
- **WezTerm Hotkeys:**

  | Hotkey | Action |
  |--------|--------|
  | `CTRL+SHIFT+G` | Open gitui + OpenCode split in a new tab |
  | `CTRL+SHIFT+O` | Split pane: gitui (left, 40%) + OpenCode (right) |
  | `CTRL+SHIFT+ALT+G` | Open gitui + OpenCode split in a new workspace |

## Plugins (Developer Preset)

All 6 plugins are installed with the Developer preset. See the main [Plugins reference](plugins.md) for full details.

| Plugin | Description |
|--------|-------------|
| `oh-my-openagent` | Session management and advanced CLI commands |
| `opencode-mem` | Long-term Rust RAG memory with hybrid search (BM25 + vectors) |
| `@different-ai/opencode-browser` | Integration with a real web browser |
| `@tarquinen/opencode-smart-title` | Smart auto-naming of active sessions |
| `opencode-token-speed-plugin` | Real-time speed indicator (Tokens Per Second) |
| `opencode-codebase-index` | Codebase RAG indexing with semantic search, file watching, and auto re-index |

## MCP Servers (Developer Preset)

All 7 MCP servers are enabled with the Developer preset. See the main [MCP reference](mcp.md) for full details.

| MCP | Description |
|-----|-------------|
| `fetch` | Fast web page text retrieval without loading a browser |
| `puppeteer` | Browser automation: screenshots and clicking elements |
| `postgres` | Integration with local gpt_chat_bot database |
| `context7` | Access real-time version-specific library documentation |
| `codegraph` | AST code graph: semantic search, call chain, impact analysis |
| `docs-mcp` | Multi-format document reader: PDF, DOCX, MD, CSV, OCR |
| `lsp-mcp` | Code intelligence: definitions, references, diagnostics via LSP |
