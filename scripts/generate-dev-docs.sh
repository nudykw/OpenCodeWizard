#!/bin/bash
# Generate docs/developer-tools.md and docs/developer-tools.uk.md
# from config/dev-tools.conf and the preset plugin/MCP definitions.
set -euo pipefail

BASE_DIR="$(dirname "$0")/.."
CONF_FILE="$BASE_DIR/config/dev-tools.conf"

DOC_EN="$BASE_DIR/docs/developer-tools.md"
DOC_UK="$BASE_DIR/docs/developer-tools.uk.md"

source "$BASE_DIR/config/variables.conf"

# Short descriptions for plugins/MCPs that aren't in conf files
declare -A PLUGIN_DESC_EN
PLUGIN_DESC_EN["oh-my-openagent"]="Session management and advanced CLI commands"
PLUGIN_DESC_EN["opencode-mem"]="Long-term Rust RAG memory with hybrid search (BM25 + vectors)"
PLUGIN_DESC_EN["@different-ai/opencode-browser"]="Integration with a real web browser"
PLUGIN_DESC_EN["@tarquinen/opencode-smart-title"]="Smart auto-naming of active sessions"
PLUGIN_DESC_EN["opencode-token-speed-plugin"]="Real-time speed indicator (Tokens Per Second)"
PLUGIN_DESC_EN["opencode-codebase-index"]="Codebase RAG indexing with semantic search, file watching, and auto re-index"

declare -A PLUGIN_DESC_UK
PLUGIN_DESC_UK["oh-my-openagent"]="Керування сесіями та розширені CLI команди"
PLUGIN_DESC_UK["opencode-mem"]="Довгострокова Rust RAG пам'ять з гібридним пошуком (BM25 + вектори)"
PLUGIN_DESC_UK["@different-ai/opencode-browser"]="Інтеграція з реальним веб-браузером"
PLUGIN_DESC_UK["@tarquinen/opencode-smart-title"]="Розумне автоматичне іменування активних сесій"
PLUGIN_DESC_UK["opencode-token-speed-plugin"]="Індикатор швидкості в реальному часі (токени за секунду)"
PLUGIN_DESC_UK["opencode-codebase-index"]="Індексація коду RAG із семантичним пошуком та авто-переіндексацією"

declare -A MCP_DESC_EN
MCP_DESC_EN["fetch"]="Fast web page text retrieval without loading a browser"
MCP_DESC_EN["puppeteer"]="Browser automation: screenshots and clicking elements"
MCP_DESC_EN["postgres"]="Integration with local gpt_chat_bot database"
MCP_DESC_EN["context7"]="Access real-time version-specific library documentation"
MCP_DESC_EN["codegraph"]="AST code graph: semantic search, call chain, impact analysis"
MCP_DESC_EN["docs-mcp"]="Multi-format document reader: PDF, DOCX, MD, CSV, OCR"
MCP_DESC_EN["lsp-mcp"]="Code intelligence: definitions, references, diagnostics via LSP"

declare -A MCP_DESC_UK
MCP_DESC_UK["fetch"]="Швидке отримання тексту веб-сторінок без браузера"
MCP_DESC_UK["puppeteer"]="Автоматизація браузера: скріншоти, кліки по елементах"
MCP_DESC_UK["postgres"]="Інтеграція з локальною базою даних gpt_chat_bot"
MCP_DESC_UK["context7"]="Доступ до версійної документації бібліотек у реальному часі"
MCP_DESC_UK["codegraph"]="AST граф коду: семантичний пошук, ланцюги викликів, аналіз впливу"
MCP_DESC_UK["docs-mcp"]="Читання документів: PDF, DOCX, MD, CSV, OCR"
MCP_DESC_UK["lsp-mcp"]="Інтелект коду: визначення, посилання, діагностика через LSP"

# Build docs
generate_en() {
  cat > "$DOC_EN" << 'HEADER'
# Developer Tools Reference

This document describes the additional tools, keybindings, and components that are installed and configured when you select the **Developer** preset in OpenCodeWizard.

## Utilities
HEADER

  while IFS=: read -r type name desc; do
    [[ "$type" == "tool" ]] || continue
    [[ -n "$name" ]] || continue
    cat >> "$DOC_EN" << TOOL

### $name

- **Description:** $desc
- **Installation:** Automatic with the **Developer** preset.
- **WezTerm Hotkeys:**

  | Hotkey | Action |
  | ------- | ------- |
  | \`CTRL+SHIFT+G\` | Open $name + OpenCode split in a new tab |
  | \`CTRL+SHIFT+O\` | Split pane: $name (left, 40%) + OpenCode (right) |
  | \`CTRL+SHIFT+ALT+G\` | Open $name + OpenCode split in a new workspace |
TOOL
  done < <(grep '^tool:' "$CONF_FILE" 2>/dev/null || true)

  cat >> "$DOC_EN" << 'PLUGINS'

## Plugins (Developer Preset)

All 6 plugins are installed with the Developer preset. See the main [Plugins reference](plugins.md) for full details.

| Plugin | Description |
| ------- | ----------- |
PLUGINS

  for plugin in "${PRESET_DEVELOPER_PLUGINS[@]}"; do
    echo "| \`$plugin\` | ${PLUGIN_DESC_EN[$plugin]} |" >> "$DOC_EN"
  done

  cat >> "$DOC_EN" << 'MCP'

## MCP Servers (Developer Preset)

All 7 MCP servers are enabled with the Developer preset. See the main [MCP reference](mcp.md) for full details.

| MCP | Description |
| ----- | ----------- |
MCP

  for mcp in "${PRESET_DEVELOPER_MCPS[@]}"; do
    echo "| \`$mcp\` | ${MCP_DESC_EN[$mcp]} |" >> "$DOC_EN"
  done
}

generate_uk() {
  cat > "$DOC_UK" << 'HEADER'
# Документація інструментів розробника

Цей документ описує додаткові утиліти, гарячі клавіші та компоненти, які встановлюються під час вибору пресету **Developer** в OpenCodeWizard.

## Утиліти
HEADER

  while IFS=: read -r type name desc; do
    [[ "$type" == "tool" ]] || continue
    [[ -n "$name" ]] || continue
    cat >> "$DOC_UK" << TOOL

### $name

- **Опис:** $desc
- **Встановлення:** Автоматично з пресетом **Developer**.
- **Гарячі клавіші WezTerm:**

  | Хоткей | Дія |
  | ------- | ----- |
  | \`CTRL+SHIFT+G\` | Відкрити $name + OpenCode у спліті в новому табі |
  | \`CTRL+SHIFT+O\` | Розділити екран: $name (зліва, 40%) + OpenCode (справа) |
  | \`CTRL+SHIFT+ALT+G\` | Відкрити $name + OpenCode у спліті в новому робочому середовищі |
TOOL
  done < <(grep '^tool:' "$CONF_FILE" 2>/dev/null || true)

  cat >> "$DOC_UK" << 'PLUGINS'

## Плагіни (Developer Preset)

Всі 6 плагінів встановлюються з пресетом Developer. Детальніше в [документації плагінів](plugins.uk.md).

| Плагін | Опис |
| ------- | ----- |
PLUGINS

  for plugin in "${PRESET_DEVELOPER_PLUGINS[@]}"; do
    echo "| \`$plugin\` | ${PLUGIN_DESC_UK[$plugin]} |" >> "$DOC_UK"
  done

  cat >> "$DOC_UK" << 'MCP'

## MCP-сервери (Developer Preset)

Всі 7 MCP-серверів активуються з пресетом Developer. Детальніше в [документації MCP](mcp.uk.md).

| MCP | Опис |
| ----- | ----- |
MCP

  for mcp in "${PRESET_DEVELOPER_MCPS[@]}"; do
    echo "| \`$mcp\` | ${MCP_DESC_UK[$mcp]} |" >> "$DOC_UK"
  done
}

main() {
  generate_en
  generate_uk
  echo "Generated: $DOC_EN"
  echo "Generated: $DOC_UK"
}

main
