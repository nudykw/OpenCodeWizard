# Документація інструментів розробника

Цей документ описує додаткові утиліти, гарячі клавіші та компоненти, які встановлюються під час вибору пресету **Developer** в OpenCodeWizard.

## Утиліти

### gitui

- **Опис:** Git TUI with real-time repository monitoring. Browse diffs, stage files, commit, manage branches, and watch file changes — all from a fast terminal UI.
- **Встановлення:** Автоматично з пресетом **Developer**.
- **Гарячі клавіші WezTerm:**

  | Хоткей | Дія |
  | ------- | ----- |
  | `CTRL+SHIFT+G` | Відкрити gitui + OpenCode у спліті в новому табі |
  | `CTRL+SHIFT+O` | Розділити екран: gitui (зліва, 40%) + OpenCode (справа) |
  | `CTRL+SHIFT+ALT+G` | Відкрити gitui + OpenCode у спліті в новому робочому середовищі |

## Плагіни (Developer Preset)

Всі 6 плагінів встановлюються з пресетом Developer. Детальніше в [документації плагінів](plugins.uk.md).

| Плагін | Опис |
| ------- | ----- |
| [`oh-my-openagent`](oh-my-openagent.uk.md) | Керування сесіями та розширені CLI команди |
| `opencode-mem` | Довгострокова Rust RAG пам'ять з гібридним пошуком (BM25 + вектори) |
| `@different-ai/opencode-browser` | Інтеграція з реальним веб-браузером |
| `@tarquinen/opencode-smart-title` | Розумне автоматичне іменування активних сесій |
| `opencode-token-speed-plugin` | Індикатор швидкості в реальному часі (токени за секунду) |
| `opencode-codebase-index` | Індексація коду RAG із семантичним пошуком та авто-переіндексацією |

## MCP-сервери (Developer Preset)

Всі 7 MCP-серверів активуються з пресетом Developer. Детальніше в [документації MCP](mcp.uk.md).

| MCP | Опис |
| ----- | ----- |
| `fetch` | Швидке отримання тексту веб-сторінок без браузера |
| `puppeteer` | Автоматизація браузера: скріншоти, кліки по елементах |
| `postgres` | Інтеграція з локальною базою даних gpt_chat_bot |
| `context7` | Доступ до версійної документації бібліотек у реальному часі |
| `codegraph` | AST граф коду: семантичний пошук, ланцюги викликів, аналіз впливу |
| `docs-mcp` | Читання документів: PDF, DOCX, MD, CSV, OCR |
| `lsp-mcp` | Інтелект коду: визначення, посилання, діагностика через LSP |
