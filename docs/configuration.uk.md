# Посібник з налаштування OpenCode

> **Як налаштовувати агенти OpenCode, плагіни, MCP-сервери та змінні середовища.**

---

## Зміст

1. [Огляд файлів конфігурації](#1-огляд-файлів-конфігурації)
2. [Налаштування агентів у OpenCodeWizard.sh (до встановлення)](#2-налаштування-агентів-у-opencodewizardsh-до-встановлення)
3. [Налаштування агентів після встановлення (вручну)](#3-налаштування-агентів-після-встановлення-вручну)
4. [Критичне правило Git-операцій](#4-критичне-правило-git-операцій)
5. [Поведінка перемикання вкладок (OPENCODE_AGENTS_SWITCH_SINGLE_MODEL)](#5-поведінка-перемикання-вкладок)

---

## 1. Огляд файлів конфігурації

| Файл | Призначення | Створюється |
|---|---|---|
| `~/.config/opencode/opencode.jsonc` | Головний конфіг (провайдери, моделі, плагіни, MCP, інструкції) | `configure_opencode()` |
| `~/.config/opencode/system_info.md` | Інструкції для AI + інформація про систему | `configure_opencode()` |
| `~/.bashrc` / `~/.zshrc` / `~/.profile` | Експорт змінних середовища (`TERMINAL`, `OPENCODE_AGENTS_SWITCH_SINGLE_MODEL`) | `configure_default_terminal()` |
| `~/.config/wezterm/wezterm.lua` | Зовнішній вигляд WezTerm, гарячі клавіші, split-панелі | `configure_wezterm()` |
| `config/variables.conf` | Визначення preset-ів (плагіни, MCP на preset) | Редагування вручну |
| `config/plugins.conf` | Список доступних плагінів | Редагування вручну |
| `config/mcp.conf` | Список доступних MCP-серверів | Редагування вручну |
| `config/system_info.md.tpl` | Шаблон системного промпту AI (інструкції + інформація про систему) | Редагування вручну |

---

## 2. Налаштування агентів у OpenCodeWizard.sh (до встановлення)

### 2.1 Preset-и

Preset-и визначені у `config/variables.conf`:

```bash
PRESET_DEVELOPER="developer"
PRESET_STANDARD="standard"
PRESET_MINIMAL="minimal"
```

Кожен preset визначає, які плагіни та MCP-сервери встановлювати:

```bash
PRESET_DEVELOPER_PLUGINS=(
    "oh-my-openagent"
    "opencode-mem"
    "@different-ai/opencode-browser"
    "@tarquinen/opencode-smart-title"
    "opencode-token-speed-plugin"
    "opencode-codebase-index"
)
PRESET_DEVELOPER_MCPS=(
    "fetch" "puppeteer" "postgres" "context7"
    "codegraph" "docs-mcp" "lsp-mcp"
)
```

**Щоб змінити:** Редагуйте `config/variables.conf` — додавайте або видаляйте записи з масивів.

### 2.2 Список плагінів

Визначений у `config/plugins.conf`:

```text
oh-my-openagent|Керування сесіями та розширені CLI-команди
opencode-mem|Довгострокова RAG-пам'ять з гібридним пошуком
@different-ai/opencode-browser|Інтеграція з веб-браузером
```

**Щоб змінити:** Редагуйте `config/plugins.conf`. Закоментуйте рядки `#`, щоб вимкнути, додайте нові рядки, щоб увімкнути.

### 2.3 Список MCP-серверів

Визначений у `config/mcp.conf`:

```text
fetch|Web fetch MCP|npx -y mcp-server-fetch-typescript
puppeteer|Автоматизація браузера|npx -y @modelcontextprotocol/server-puppeteer
docs-mcp|Читання документів (PDF, DOCX, тощо)|docling
```

**Щоб змінити:** Редагуйте `config/mcp.conf`. Закоментуйте рядки `#`, щоб вимкнути, додайте нові рядки, щоб увімкнути.

### 2.4 Як скрипт генерує конфіги

Функція `configure_opencode()` у `OpenCodeWizard.sh`:

1. Читає списки preset-ів (`preset_plugins`, `preset_mcps`) з `variables.conf`
2. Будує JSON для `opencode.jsonc` з вибраними плагінами та MCP
3. Записує `system_info.md` з інформацією про систему та критичними правилами
4. Встановлює `opencode.jsonc` посилання на `system_info.md` через `"instructions"`

### 2.5 Шаблон системного промпту (system_info.md.tpl)

Замість жорстко закодованого тексту, OpenCodeWizard використовує шаблон `config/system_info.md.tpl`. Цей файл містить інструкції для AI англійською мовою (оскільки це промпт для моделі, а не для користувача) та змінні-плейсхолдери на кшталт `{{OS}}` або `{{SHELL}}`.

Обидва скрипти (`.sh` та `.ps1`) використовують цей спільний шаблон для генерації фінального файлу `~/.config/opencode/system_info.md`.

**Щоб налаштувати промпт AI:**

1. Відредагуйте `config/system_info.md.tpl` у репозиторії.
2. Запустіть візард знову — він оновить встановлений файл інструкцій, зберігши актуальні дані про вашу систему.

---

## 3. Налаштування агентів після встановлення (вручну)

### 3.1 Головний конфіг OpenCode

Редагуйте `~/.config/opencode/opencode.jsonc`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "~/.config/opencode/system_info.md"
  ],
  "provider": {
    "my-provider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Мій провайдер",
      "options": {
        "baseURL": "http://localhost:8080/v1"
      },
      "models": {
        "my-model": {
          "name": "Моя модель",
          "limit": { "context": 128000, "output": 65536 }
        }
      }
    }
  },
  "plugin": [
    "oh-my-openagent",
    "opencode-mem"
  ],
  "mcp": {
    "fetch": {
      "type": "local",
      "command": ["npx", "-y", "mcp-server-fetch-typescript"],
      "enabled": true
    }
  }
}
```

**Щоб додати/видалити плагіни:** Редагуйте масив `"plugin"`.

**Щоб додати/видалити MCP-сервери:** Редагуйте об'єкт `"mcp"`.

**Щоб додати власні інструкції:** Додайте шляхи до файлів у масив `"instructions"`. Файли читаються по порядку — перший файл має найвищий пріоритет.

### 3.2 Додавання власних файлів інструкцій

Створіть новий `.md` файл з правилами, потім додайте його до `opencode.jsonc`:

```bash
echo "# Мої правила" > ~/.config/opencode/custom_rules.md
```

Потім у `opencode.jsonc`:

```json
"instructions": [
  "~/.config/opencode/custom_rules.md",
  "~/.config/opencode/system_info.md"
]
```

Файли обробляються по порядку. Перший файл має найвищий пріоритет.

### 3.3 Налаштування провайдерів та моделей

Додавайте або змінюйте провайдерів у секції `"provider"` файлу `opencode.jsonc`:

```json
"provider": {
  "my-local": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "Локальна LLM",
    "options": {
      "baseURL": "http://localhost:8080/v1"
    },
    "models": {
      "my-model-v1": {
        "name": "Модель v1",
        "limit": { "context": 32000, "output": 4096 }
      }
    }
  }
}
```

### 3.4 Конфігурація оболонки

Скрипт експортує змінні середовища у `~/.bashrc`, `~/.zshrc` та `~/.profile`:

```bash
# OpenCode
export TERMINAL=wezterm
export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true
```

**Щоб змінити вручну:** Відредагуйте будь-який з цих файлів та перезапустіть оболонку або виконайте `source`.

---

## 4. Критичне правило Git-операцій

### Де воно визначено

1. **Згенеровано з шаблону:** `config/system_info.md.tpl` (шаблон у репозиторії)
2. **Встановлено:** `~/.config/opencode/system_info.md` (згенерований файл)

### Правило

```text
ABSOLUTE PROHIBITION: Never commit or push to git without explicit user confirmation.

- Before git commit: ask "Commit changes?"
- Before git push: ask "Push to remote?"
- Wait for explicit "yes"/"да"/"push"/"коммить" before proceeding.
- NO auto-commit, NO auto-push, NO --no-verify shortcuts.
```

### Чому воно перше

Масив `"instructions"` у `opencode.jsonc` обробляє файли по порядку. `system_info.md` — перший (і поки що єдиний) файл у списку. Всередині нього правило git розташоване **перед** інформацією про систему — що робить його найпершою інструкцією, яку читає AI.

---

## 5. Поведінка перемикання вкладок

### Що це робить

За замовчуванням натискання **Tab** у OpenCode може змінювати як **режим агента** (Agent/Edit/Search), так і **модель AI**. Це незручно — перемикання режиму не повинно скидати модель.

### Виправлення

```bash
export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true
```

Коли встановлено, **Tab перемикає тільки режим**, залишаючи поточну модель активною.

### Де це налаштовано

1. **Скриптом:** `configure_default_terminal()` додає це у `~/.bashrc`, `~/.zshrc` та `~/.profile`
2. **Вручну:** Додайте експорт у конфіг оболонки та перезавантажте:

```bash
echo 'export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true' >> ~/.bashrc
source ~/.bashrc
```

1. **Тимчасово:** Експортуйте для поточної сесії:

```bash
export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true
```

### Перевірка

```bash
echo $OPENCODE_AGENTS_SWITCH_SINGLE_MODEL
# Має вивести: true
```
