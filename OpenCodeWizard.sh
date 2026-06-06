#!/usr/bin/env bash

# ==============================================================================
# OpenCode & WezTerm Megacombo Setup Wizard (Linux/macOS)
# ==============================================================================
# Idempotent interactive setup script for OpenCode and WezTerm.
# Supports English and Ukrainian.
# ==============================================================================

set -euo pipefail

# Colors for TUI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==============================================================================
# USER-CONFIGURABLE: Plugins & MCP Servers
# Configuration moved to config/components.sh
# ==============================================================================

# Load central configuration (parses .conf files into arrays)
OPENCODE_PLUGINS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^#.* ]] || [[ -z "$line" ]] && continue
    OPENCODE_PLUGINS+=("$line")
done < "$(dirname "$0")/config/plugins.conf"

OPENCODE_MCP_SERVERS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^#.* ]] || [[ -z "$line" ]] && continue
    OPENCODE_MCP_SERVERS+=("$line")
done < "$(dirname "$0")/config/mcp.conf"

# ==============================================================================
# Global state
# ==============================================================================
LANG_CODE="en"
SILENT=false
DRY_RUN=false

# Load shared preset definitions
source "$(dirname "$0")/config/variables.conf"
PRESET="$PRESET_DEVELOPER"
COMMAND="setup"   # setup | reset | create-backup | restore-backup | remove-backups | list-backups
COMMAND="setup"   # setup | reset | create-backup | restore-backup | remove-backups | list-backups
OS=""
DISTRO=""

# Backup system
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/opencodeWizard/backups"
BACKUP_ID=""  # generated once per session by generate_backup_id()

# Show Help Message
show_help() {
    echo -e "${BOLD}OpenCode & WezTerm Setup Wizard${NC}"
    echo -e "Usage: $0 [COMMAND] [OPTIONS]"
    echo -e ""
    echo -e "${BOLD}COMMANDS:${NC}"
    echo -e "  (none)                           Run the interactive setup wizard"
    echo -e "                                   Запустити інтерактивний майстер"
    echo -e "  --reset                          Reset all wizard-managed configs to defaults."
    echo -e "                                   Creates a backup first. WezTerm/OpenCode stay installed."
    echo -e "                                   Скинути конфіги до дефолту (з бекапом)"
    echo -e "  --create-backup                  Save a snapshot of current config files."
    echo -e "                                   ID: ocw-<git_hash>-<YYYYMMDD-HHMMSS>"
    echo -e "                                   Зберегти резервну копію поточних конфігів"
    echo -e "  --restore-backup                 Show backups and restore selected (transactional)."
    echo -e "                                   Auto-saves current state before restoring."
    echo -e "                                   Відновити конфіги з резервної копії"
    echo -e "  --list-backups                    Show all saved backups (non-interactive)."
    echo -e "                                   Показати всі резервні копії"
    echo -e "  --remove-backups                 Delete ALL saved backups (with confirmation)."
    echo -e "                                   Видалити всі резервні копії"
    echo -e ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  -y, --silent, --non-interactive  Run setup automatically with default options"
    echo -e "                                   Запустити встановлення автоматично"
    echo -e "  --dry-run                        Simulate without making changes (safe on any OS)"
    echo -e "                                   Симуляція без змін (безпечно на будь-якій ОС)"
    echo -e "  -h, --help                       Show this help message"
    echo -e "                                   Показати це повідомлення допомоги"
    echo -e ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  $0                               # interactive wizard"
    echo -e "  $0 --silent                      # auto setup"
    echo -e "  $0 --dry-run                     # simulate setup (no changes)"
    echo -e "  $0 --silent --dry-run            # simulate non-interactively"
    echo -e "  $0 --create-backup               # snapshot configs now"
    echo -e "  $0 --restore-backup              # pick and restore a backup"
    echo -e "  $0 --reset                       # wipe wizard-managed configs"
    echo -e "  $0 --remove-backups              # delete all backups"
    echo -e "  $0 --list-backups                # show all backups"
    echo -e ""
    echo -e "${BOLD}CUSTOMIZING PLUGINS & MCP:${NC}"
    echo -e "  Edit OPENCODE_PLUGINS and OPENCODE_MCP_SERVERS arrays at the top of this script."
    echo -e "  Comment out a line with # to disable. Add a new line to enable."
    exit 0
}

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        --reset)           COMMAND="reset" ;;
        --create-backup)   COMMAND="create-backup" ;;
        --restore-backup)  COMMAND="restore-backup" ;;
        --remove-backups)  COMMAND="remove-backups" ;;
        --list-backups)   COMMAND="list-backups" ;;
        -y|--silent|--non-interactive)
            SILENT=true
            # Check if next argument is a valid preset
            if [[ -n "${2:-}" ]] && [[ "$2" =~ ^($PRESET_DEVELOPER|$PRESET_STANDARD|$PRESET_MINIMAL)$ ]]; then
                PRESET="$2"
                shift
            fi
            ;;
        --dry-run)
            DRY_RUN=true ;;
        -h|--help)
            show_help ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
    shift
done


# Dry-run helpers
is_dry_run() { [ "$DRY_RUN" = true ]; }

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
}

# Function to detect OpenCode path
get_opencode_path() {
    command -v opencode || echo "/usr/bin/opencode"
}

# Helper Translation Function
msg() {
    local key="$1"
    case "$LANG_CODE" in
        "uk")
            case "$key" in
                "title") echo "ВСТАНОВЛЕННЯ OPENCODE ТА WEZTERM" ;;
                "intro_text")
                    echo -e "Привіт! Цей скрипт допоможе налаштувати середовище штучного інтелекту.\n"
                    echo -e "${BOLD}OpenCode${NC} — це ваш персональний локальний ШІ-помічник, який допомагає писати тексти, код, аналізувати файли та автоматизувати рутину."
                    echo -e "${BOLD}WezTerm${NC} — це сучасний, дуже швидкий (на Rust та GPU) термінал, який підтримує графіку та зручний розділений екран."
                    echo -e "\n${YELLOW}${BOLD}Не бійтеся чорного вікна консолі!${NC} Ми зробимо його красивим і зручним. Робота в ньому набагато простіша, ніж здається. Ви швидко звикнете, а ШІ завжди буде поруч, щоб допомогти!"
                    ;;
                "select_lang") echo "Оберіть мову / Select language:" ;;
                "invalid_lang") echo "Невірний вибір, використовується English." ;;
                "detecting_os") echo "Визначення операційної системи..." ;;
                "os_detected") echo "Знайдено ОС:" ;;
                "ask_wezterm") echo "Встановити WezTerm?" ;;
                "wezterm_exists") echo "WezTerm вже встановлено:" ;;
                "skip_wezterm") echo "Пропуск встановлення WezTerm." ;;
                "installing_wezterm") echo "Встановлення WezTerm..." ;;
                "brew_missing") echo "Homebrew не встановлено. Будь ласка, встановіть його спочатку (https://brew.sh/)." ;;
                "adding_repo") echo "Додавання репозиторію WezTerm..." ;;
                "installing_pacman") echo "Встановлення WezTerm через Pacman..." ;;
                "unsupported_distro") echo "Цей дистрибутив не підтримується для авто-встановлення:" ;;
                "manual_wezterm") echo "Будь ласка, встановіть WezTerm вручную з https://wezfurlong.org/wezterm/install/" ;;
                "unsupported_os") echo "Ця ОС не підтримується:" ;;
                "wezterm_success") echo "WezTerm успішно встановлено!" ;;
                "node_explain")
                    echo "Node.js та npm потрібні для повноцінної роботи OpenCodeWizard:"
                    echo "  • Встановлення OpenCode CLI (пакет opencode-ai)"
                    echo "  • Запуск MCP-серверів (fetch, puppeteer, context7, postgres тощо) через npx"
                    echo "  • Частина плагінів OpenCode"
                    echo "Без npm OpenCode можна встановити іншим способом, але MCP-сервери не працюватимуть."
                    ;;
                "ask_node") echo "Встановити Node.js та npm?" ;;
                "node_exists") echo "Node.js та npm вже встановлено." ;;
                "node_skip_warning") echo "Node.js/npm не встановлено. OpenCode буде встановлено альтернативним способом, MCP-сервери можуть не працювати." ;;
                "installing_node") echo "Встановлення Node.js та npm..." ;;
                "node_success") echo "Node.js та npm успішно встановлено!" ;;
                "node_path_hint") echo "npm не знайдено в PATH. Перезапустіть термінал і запустіть скрипт знову." ;;
                "node_manual") echo "Будь ласка, встановіть Node.js вручну: https://nodejs.org/ , потім запустіть майстер знову." ;;
                "ask_opencode") echo "Встановити OpenCode CLI?" ;;
                "opencode_exists") echo "OpenCode вже встановлено:" ;;
                "skip_opencode") echo "Пропуск встановлення OpenCode." ;;
                "installing_opencode_script") echo "Встановлення OpenCode через офіційний скрипт..." ;;
                "installing_opencode_brew") echo "Встановлення OpenCode через Homebrew..." ;;
                "installing_opencode_pacman") echo "Встановлення OpenCode через Pacman..." ;;
                "installing_opencode_npm") echo "Встановлення opencode-ai через npm..." ;;
                "opencode_script_failed") echo "Офіційний скрипт не вдався, пробую інший спосіб..." ;;
                "opencode_failed") echo "Не вдалося встановити OpenCode жодним із доступних способів." ;;
                "opencode_manual") echo "Встановіть вручну: curl -fsSL https://opencode.ai/install | bash" ;;
                "opencode_success") echo "OpenCode успішно встановлено!" ;;
                "ask_plugins") echo "Налаштувати плагіни для OpenCode?" ;;
                "skip_plugins") echo "Пропуск налаштування плагінів." ;;
                "ask_plugins_default") echo "Встановити всі рекомендовані плагіни за замовчуванням?" ;;
                "installing_plugin") echo "Встановлення плагіна:" ;;
                "plugins_success") echo "Налаштування плагінів завершено." ;;
                "ask_plugin_install") echo "Встановити плагін" ;;
                "ask_mcp") echo "Налаштувати MCP-сервери?" ;;
                "skip_mcp") echo "Пропуск налаштування MCP-серверів." ;;
                "ask_mcp_default") echo "Увімкнути всі рекомендовані MCP-сервери за замовчуванням?" ;;
                "ask_mcp_install") echo "Увімкнути MCP-сервер" ;;
                "backup_created") echo "Створено резервну копію:" ;;
                "backup_id_label") echo "Backup ID:" ;;
                "backup_location") echo "Директорія:" ;;
                "no_backups_found") echo "Резервних копій не знайдено." ;;
                "select_backup") echo "Оберіть номер бекапу для відновлення:" ;;
                "restore_confirm") echo "Відновити всі файли з цього бекапу?" ;;
                "restore_success") echo "Бекап успішно відновлено!" ;;
                "restore_failed") echo "Помилка при відновленні. Відкатуючись..." ;;
                "remove_backups_confirm") echo "Видалити ВСІ резервні копії?" ;;
                "remove_backups_success") echo "Всі резервні копії видалено." ;;
                "reset_done") echo "Скидання завершено. Запустіть скрипт знову, щоб налаштувати все знову." ;;
                "migrate_plugin") echo "Виявлено застарілий плагін. Мігрую..." ;;
                "migrate_plugin_done") echo "Міграцію завершено." ;;
                "opencode_config_updated") echo "Конфігурація OpenCode оновлена в" ;;
                "ask_wezterm_config") echo "Налаштувати зовнішній вигляд та гарячі клавіші WezTerm?" ;;
                "skip_wezterm_config") echo "Пропуск налаштування WezTerm." ;;
                "wezterm_config_saved") echo "Конфігурація WezTerm збережена в" ;;
                "wezterm_legacy_conflict") echo "УВАГА: Виявлено ~/.wezterm.lua! Він має вищий пріоритет і перекриває ~/.config/wezterm/wezterm.lua." ;;
                "wezterm_legacy_remove") echo "1) Видалити ~/.wezterm.lua (рекомендовано)" ;;
                "wezterm_legacy_symlink") echo "2) Замінити ~/.wezterm.lua на симлінк до нового конфігу" ;;
                "wezterm_legacy_skip") echo "3) Залишити як є (може ігнорувати новий конфіг)" ;;
                "wezterm_legacy_removed") echo "$HOME/.wezterm.lua видалено." ;;
                "wezterm_legacy_symlinked") echo "$HOME/.wezterm.lua тепер вказує на новий конфіг." ;;
                "wezterm_legacy_skipped") echo "Пропуск, залишено ~/.wezterm.lua." ;;
                "default_terminal_title") echo "--- Налаштування терміналу за замовчуванням ---" ;;
                "default_terminal_explain")
                    echo "Встановлення WezTerm за замовчуванням дозволить:"
                    echo "  1. Запускати WezTerm при натисканні системного шорткату (наприклад, CTRL + ALT + T)."
                    echo "  2. Відкривати скрипти та консольні програми відразу в WezTerm."
                    ;;
                "ask_default_terminal") echo "Зробити WezTerm вашим основним системним терміналом?" ;;
                "skip_default_terminal") echo "Пропуск налаштування терміналу за замовчуванням." ;;
                "setting_default_emulator") echo "Реєстрація та встановлення як основного x-terminal-emulator..." ;;
                "default_terminal_success") echo "WezTerm тепер є вашим основним терміналом!" ;;
                "no_update_alternatives") echo "Утиліта update-alternatives не знайдена. Ви можете змінити термінал за замовчуванням у налаштуваннях клавіатури/додатків вашої графічної оболонки." ;;
                "updated_xdg_terminals") echo "Оновлено список XDG терміналів для підтримки сучасних дистрибутивів:" ;;
                "exporting_env") echo "Додавання змінної export TERMINAL=wezterm до конфігурації оболонки..." ;;
                "macos_default_instruction")
                    echo "На macOS для встановлення за замовчуванням:"
                    echo "1. Відкрийте Finder -> Програми -> Утиліти."
                    echo "2. Запустіть Terminal.app, оберіть Налаштування -> Загальні -> Відкривати оболонки за допомогою: Стандартної оболонки входу."
                    echo "3. Або встановіть 'duti' та виконайте: duti -s org.wezfurlong.wezterm public.unix-executable all"
                    ;;
                "verifying") echo "Перевірка встановленого ПЗ..." ;;
                "wezterm_missing_path") echo "WezTerm НЕ знайдено в PATH." ;;
                "opencode_missing_path") echo "OpenCode CLI НЕ знайдено в PATH." ;;
                "verification_passed") echo "✔ ВСІ ПЕРЕВІРКИ ПРОЙДЕНО! Налаштування успішно завершено." ;;
                "verification_tip") echo "Порада: Запустіть 'wezterm' та натисніть 'CTRL + SHIFT + O', щоб відкрити OpenCode у розділеному екрані!" ;;
                "verification_failed") echo "Деякі компоненти відсутні. Будь ласка, перевірте помилки вище." ;;
                "ask_desktop_shortcut") echo "Створити ярлик швидкого запуску OpenCode в WezTerm на Робочому столі?" ;;
                "desktop_shortcut_success") echo "Ярлик на Робочому столі успішно створено!" ;;
                "go_installing") echo "Встановлення Go 1.24.0..." ;;
                "go_installed") echo "Go успішно встановлено" ;;
                "go_install_failed") echo "Помилка встановлення Go." ;;
                "go_manual") echo "Будь ласка, встановіть Go вручну: https://go.dev/dl/ , потім запустіть майстер знову." ;;
                "gomcp_installing") echo "Встановлення go-docs-mcp через Go..." ;;
                "gomcp_installed") echo "go-docs-mcp успішно встановлено." ;;
                "gomcp_failed") echo "go-docs-mcp не знайдено після встановлення. Переконайтеся, що ~/go/bin є в PATH." ;;
                "preset_label") echo "Обраний пресет:" ;;
                "dry_backup_create") echo "Створить бекап у" ;;
                "invalid_choice_abort") echo "Невірний вибір. Скасовано." ;;
                "restore_cancelled") echo "Відновлення скасовано." ;;
                "backup_files_header") echo "Файли в цьому бекапі:" ;;
                "cancelled") echo "Скасовано." ;;
                "backups_found_count") echo "Знайдено" ;;
                "backups_total_size") echo "загалом." ;;
                "dry_delete_backups") echo "Видалить ВСІ бекапи в" ;;
                "backup_before_reset") echo "Створення бекапу перед скиданням..." ;;
                "dry_reset_remove_configs") echo "Видалить: opencode.jsonc, system_info.md, wezterm.lua, OpenCode.desktop" ;;
                "dry_reset_remove_terminal") echo "Видалить export TERMINAL з .bashrc/.zshrc" ;;
                "dry_reset_remove_plugins") echo "Видалить плагіни OpenCode" ;;
                "removed_file") echo "Видалено:" ;;
                "removed_terminal_export") echo "Видалено export TERMINAL з" ;;
                "removing_plugin") echo "Видалення плагіна:" ;;
                "dry_migrate_plugin") echo "Мігрує oh-my-opencode → oh-my-openagent у" ;;
                "dry_wezterm_brew") echo "Виконає: brew install --cask wezterm" ;;
                "dry_wezterm_ubuntu") echo "Додасть репозиторій WezTerm APT + apt install wezterm xclip wl-clipboard" ;;
                "dry_wezterm_redhat") echo "Виконає: dnf install wezterm xclip wl-clipboard" ;;
                "dry_wezterm_arch") echo "Виконає: pacman -S wezterm xclip wl-clipboard" ;;
                "dry_wezterm_unsupported_distro") echo "Дистрибутив не підтримується для авто-встановлення:" ;;
                "dry_wezterm_unsupported_os") echo "ОС не підтримується:" ;;
                "dry_wezterm_skipped") echo "Встановлення WezTerm пропущено (dry-run)" ;;
                "dry_wezterm_legacy_resolve") echo "Видалить або замінить ~/.wezterm.lua (якщо є конфлікт)" ;;
                "go_already_installed") echo "Go вже встановлено:" ;;
                "go_version_old") echo "Версія Go застаріла — потрібна 1.22+." ;;
                "dry_install_go") echo "Встановить Go 1.24.0 для" ;;
                "unsupported_arch") echo "Непідтримувана архітектура:" ;;
                "go_installed_to") echo "Go 1.24.0 встановлено в /usr/local/go" ;;
                "brew_install_first") echo "Homebrew не знайдено. Спочатку встановлюємо Homebrew..." ;;
                "dry_install_brew") echo "Встановить Homebrew (потрібен sudo)" ;;
                "go_unsupported_os") echo "ОС не підтримується для автоматичного встановлення Go:" ;;
                "go_install_path_failed") echo "Go не знайдено в PATH після встановлення." ;;
                "go_installed_version") echo "Go встановлено:" ;;
                "gomcp_already_installed") echo "go-docs-mcp вже встановлено:" ;;
                "gomcp_go_required") echo "Go потрібен для docs-mcp. Спочатку встановіть Go." ;;
                "dry_install_gomcp") echo "Виконає: go install github.com/drolosoft/go-docs-mcp@v1.1.0" ;;
                "dry_install_node") echo "Встановить Node.js/npm для" ;;
                "dry_node_brew") echo "Виконає: brew install node" ;;
                "dry_node_apt") echo "Виконає: apt install -y nodejs npm" ;;
                "dry_node_dnf") echo "Виконає: dnf install -y nodejs npm" ;;
                "dry_node_pacman") echo "Виконає: pacman -S --noconfirm nodejs npm" ;;
                "dry_install_opencode") echo "Встановить OpenCode через офіційний скрипт, менеджер пакетів або npm" ;;
                "dry_opencode_skipped") echo "Встановлення OpenCode пропущено (dry-run)" ;;
                "skip_plugin_preset") echo "Пропуск (немає в пресеті):" ;;
                "dry_install_plugin") echo "Встановить плагін:" ;;
                "plugin_install_failed") echo "Не вдалося встановити або вже встановлено:" ;;
                "skip_mcp_preset") echo "Пропуск MCP (немає в пресеті):" ;;
                "dry_write_system_info") echo "Запише system_info.md у" ;;
                "dry_write_opencode_config") echo "Запише opencode.jsonc у" ;;
                "dry_plugins_list") echo "Плагіни:" ;;
                "dry_mcp_configured") echo "MCP-сервери: згідно з вашим вибором" ;;
                "dry_opencode_config_skipped") echo "Конфігурація OpenCode пропущена (dry-run)" ;;
                "dry_wezterm_dir") echo "Створить директорію:" ;;
                "dry_wezterm_config") echo "Запише конфігурацію WezTerm у" ;;
                "dry_wezterm_config_skipped") echo "Конфігурація WezTerm пропущена (dry-run)" ;;
                "dry_default_terminal_register") echo "Зареєструє WezTerm як x-terminal-emulator за замовчуванням (update-alternatives)" ;;
                "dry_xdg_terminals") echo "Запише XDG terminal configs у ~/.config/xdg-terminals.list" ;;
                "dry_terminal_export") echo "Додасть 'export TERMINAL=wezterm' до конфігурації оболонки (bashrc/zshrc/profile)" ;;
                "update_alternatives_register_failed") echo "Не вдалося зареєструвати WezTerm у update-alternatives" ;;
                "update_alternatives_set_failed") echo "Не вдалося встановити x-terminal-emulator за замовчуванням" ;;
                "dry_desktop_shortcut") echo "Створить ярлик на робочому столі:" ;;
                "verify_wezterm") echo "WezTerm:" ;;
                "verify_opencode") echo "OpenCode:" ;;
                "active_mcp_servers") echo "Активні MCP-сервери:" ;;
                "mcp_status_failed") echo "Не вдалося отримати статус MCP." ;;
                "dry_run_complete") echo "DRY-RUN ЗАВЕРШЕНО — жодних змін у системі не внесено." ;;
                "dry_run_apply") echo "Запустіть без --dry-run, щоб застосувати зміни." ;;
                "list_total") echo "Всього:" ;;
                "list_backups_label") echo "бекапів" ;;
                "list_size") echo "Розмір:" ;;
                "select_preset_title") echo "Оберіть пресет конфігурації:" ;;
                "preset_developer") echo "1)🍔 Developer — все включено (рекомендовано)" ;;
                "preset_standard") echo "2)🥪 Standard — основні плагіни + базові MCP (fetch, docs-mcp)" ;;
                "preset_minimal") echo "3)🥗 Minimal — мінімальне налаштування" ;;
                "preset_mcps_label") echo "MCPs:" ;;
                "preset_plugins_label") echo "Plugins:" ;;
                "preset_tools_label") echo "Інструменти:" ;;
                "preset_choice") echo "Вибір [1-3] (за замовчуванням: 1):" ;;
                "nerdfont_exists") echo "JetBrainsMono Nerd Font вже встановлено." ;;
                "installing_nerdfont") echo "Завантаження JetBrainsMono Nerd Font з GitHub..." ;;
                "nerdfont_success") echo "JetBrainsMono Nerd Font встановлено!" ;;
                "nerdfont_failed") echo "Не вдалося встановити JetBrainsMono Nerd Font" ;;
                "dry_nerdfont") echo "Завантажить та встановить JetBrainsMono Nerd Font" ;;
                "gitui_exists") echo "Gitui вже встановлено:" ;;
                "ask_gitui") echo "Встановити Gitui (термінальний TUI для Git)?" ;;
                "skip_gitui") echo "Пропуск встановлення Gitui." ;;
                "installing_gitui") echo "Встановлення Gitui..." ;;
                "gitui_success") echo "Gitui успішно встановлено!" ;;
                "gitui_manual") echo "Будь ласка, встановіть Gitui вручну: https://github.com/extrawurst/gitui" ;;
                "dry_install_gitui") echo "Встановить Gitui для" ;;
            esac
            ;;
        *) # default to "en"
            case "$key" in
                "title") echo "OPENCODE & WEZTERM SETUP WIZARD" ;;
                "intro_text")
                    echo -e "Hi! This script will help you set up an artificial intelligence environment.\n"
                    echo -e "${BOLD}OpenCode${NC} is your personal local AI assistant that helps write texts, code, analyze files, and automate routine tasks."
                    echo -e "${BOLD}WezTerm${NC} is a modern, ultra-fast (Rust and GPU-based) terminal that supports inline graphics and split screens."
                    echo -e "\n${YELLOW}${BOLD}Don't be afraid of the terminal window!${NC} We'll make it beautiful and easy to use. Working in it is much simpler than it looks. You'll get used to it quickly, and the AI will always be there to guide you!"
                    ;;
                "select_lang") echo "Select language / Оберіть мову:" ;;
                "invalid_lang") echo "Invalid choice, using English." ;;
                "detecting_os") echo "Detecting operating system..." ;;
                "os_detected") echo "OS detected:" ;;
                "ask_wezterm") echo "Install WezTerm?" ;;
                "wezterm_exists") echo "WezTerm is already installed:" ;;
                "skip_wezterm") echo "Skipping WezTerm installation." ;;
                "installing_wezterm") echo "Installing WezTerm..." ;;
                "brew_missing") echo "Homebrew is not installed. Please install it first (https://brew.sh/)." ;;
                "adding_repo") echo "Adding WezTerm repository..." ;;
                "installing_pacman") echo "Installing WezTerm via Pacman..." ;;
                "unsupported_distro") echo "This distribution is not supported for automatic installation:" ;;
                "manual_wezterm") echo "Please install WezTerm manually from https://wezfurlong.org/wezterm/install/" ;;
                "unsupported_os") echo "Unsupported OS:" ;;
                "wezterm_success") echo "WezTerm installed successfully!" ;;
                "node_explain")
                    echo "Node.js and npm are required for the full OpenCodeWizard experience:"
                    echo "  • Installing the OpenCode CLI (opencode-ai package)"
                    echo "  • Running MCP servers (fetch, puppeteer, context7, postgres, etc.) via npx"
                    echo "  • Some OpenCode plugins"
                    echo "Without npm, OpenCode can still be installed another way, but MCP servers will not work."
                    ;;
                "ask_node") echo "Install Node.js and npm?" ;;
                "node_exists") echo "Node.js & npm are already installed." ;;
                "node_skip_warning") echo "Node.js/npm not installed. OpenCode will be installed via an alternative method; MCP servers may not work." ;;
                "installing_node") echo "Installing Node.js & npm..." ;;
                "node_success") echo "Node.js & npm installed successfully!" ;;
                "node_path_hint") echo "npm not found in PATH. Restart your terminal and run the wizard again." ;;
                "node_manual") echo "Please install Node.js manually from https://nodejs.org/ then re-run the wizard." ;;
                "ask_opencode") echo "Install OpenCode CLI?" ;;
                "opencode_exists") echo "OpenCode is already installed:" ;;
                "skip_opencode") echo "Skipping OpenCode installation." ;;
                "installing_opencode_script") echo "Installing OpenCode via official install script..." ;;
                "installing_opencode_brew") echo "Installing OpenCode via Homebrew..." ;;
                "installing_opencode_pacman") echo "Installing OpenCode via Pacman..." ;;
                "installing_opencode_npm") echo "Installing opencode-ai via npm..." ;;
                "opencode_script_failed") echo "Official install script failed, trying another method..." ;;
                "opencode_failed") echo "Failed to install OpenCode using any available method." ;;
                "opencode_manual") echo "Install manually: curl -fsSL https://opencode.ai/install | bash" ;;
                "opencode_success") echo "OpenCode installed successfully!" ;;
                "ask_plugins") echo "Configure OpenCode plugins?" ;;
                "skip_plugins") echo "Skipping plugin setup." ;;
                "ask_plugins_default") echo "Install all recommended plugins by default?" ;;
                "installing_plugin") echo "Installing plugin:" ;;
                "plugins_success") echo "Plugins setup complete." ;;
                "ask_plugin_install") echo "Install plugin" ;;
                "ask_mcp") echo "Configure MCP servers?" ;;
                "skip_mcp") echo "Skipping MCP configuration." ;;
                "ask_mcp_default") echo "Enable all recommended MCP servers by default?" ;;
                "ask_mcp_install") echo "Enable MCP server" ;;
                "backup_created") echo "Backup created:" ;;
                "backup_id_label") echo "Backup ID:" ;;
                "backup_location") echo "Location:" ;;
                "no_backups_found") echo "No backups found." ;;
                "select_backup") echo "Choose a backup to restore [number]:" ;;
                "restore_confirm") echo "Restore ALL files from this backup?" ;;
                "restore_success") echo "Backup restored successfully!" ;;
                "restore_failed") echo "Restore failed. Rolling back..." ;;
                "remove_backups_confirm") echo "Delete ALL backups?" ;;
                "remove_backups_success") echo "All backups deleted." ;;
                "reset_done") echo "Reset complete. Run the script again to reconfigure." ;;
                "migrate_plugin") echo "Legacy plugin detected. Migrating..." ;;
                "migrate_plugin_done") echo "Plugin migration done." ;;
                "opencode_config_updated") echo "OpenCode configuration updated in" ;;
                "ask_wezterm_config") echo "Configure WezTerm styling and hotkeys?" ;;
                "skip_wezterm_config") echo "Skipping WezTerm configuration." ;;
                "wezterm_config_saved") echo "WezTerm configuration saved at" ;;
                "wezterm_legacy_conflict") echo "WARNING: ~/.wezterm.lua exists! It has higher priority and overrides ~/.config/wezterm/wezterm.lua." ;;
                "wezterm_legacy_remove") echo "1) Remove ~/.wezterm.lua (recommended)" ;;
                "wezterm_legacy_symlink") echo "2) Replace ~/.wezterm.lua with a symlink to the new config" ;;
                "wezterm_legacy_skip") echo "3) Leave as-is (may ignore the new config)" ;;
                "wezterm_legacy_removed") echo "$HOME/.wezterm.lua removed." ;;
                "wezterm_legacy_symlinked") echo "$HOME/.wezterm.lua now points to the new config." ;;
                "wezterm_legacy_skipped") echo "Skipped, ~/.wezterm.lua left unchanged." ;;
                "default_terminal_title") echo "--- Default Terminal Configuration ---" ;;
                "default_terminal_explain")
                    echo "Setting WezTerm as the default terminal will:"
                    echo "  1. Launch WezTerm when pressing the system shortcut (e.g., CTRL + ALT + T)."
                    echo "  2. Open terminal-based scripts and tools in WezTerm automatically."
                    ;;
                "ask_default_terminal") echo "Make WezTerm your default system terminal emulator?" ;;
                "skip_default_terminal") echo "Skipping default terminal configuration." ;;
                "setting_default_emulator") echo "Registering and setting default x-terminal-emulator..." ;;
                "default_terminal_success") echo "WezTerm is now your default terminal emulator!" ;;
                "no_update_alternatives") echo "update-alternatives command not found. You can configure your default terminal in keyboard/app settings." ;;
                "updated_xdg_terminals") echo "Updated XDG terminals list for desktop environment support:" ;;
                "exporting_env") echo "Adding export TERMINAL=wezterm to shell configuration..." ;;
                "macos_default_instruction")
                    echo "To set WezTerm as default on macOS:"
                    echo "1. Open Finder -> Applications -> Utilities."
                    echo "2. Open Terminal.app, select Preferences -> General -> Shells open with: Default Login Shell."
                    echo "3. Or install 'duti' and run: duti -s org.wezfurlong.wezterm public.unix-executable all"
                    ;;
                "verifying") echo "Verifying installed software..." ;;
                "wezterm_missing_path") echo "WezTerm is NOT found in PATH." ;;
                "opencode_missing_path") echo "OpenCode CLI is NOT found in PATH." ;;
                "verification_passed") echo "✔ ALL VERIFICATIONS PASSED! Setup is fully complete." ;;
                "verification_tip") echo "Tip: Launch 'wezterm' and press 'CTRL + SHIFT + O' to open OpenCode in a split pane!" ;;
                "verification_failed") echo "Some components are missing. Please review errors above." ;;
                "ask_desktop_shortcut") echo "Create a desktop shortcut to quickly launch OpenCode inside WezTerm?" ;;
                "desktop_shortcut_success") echo "Desktop shortcut created successfully!" ;;
                "go_installing") echo "Installing Go 1.24.0..." ;;
                "go_installed") echo "Go installed successfully" ;;
                "go_install_failed") echo "Go installation failed." ;;
                "go_manual") echo "Please install Go manually from https://go.dev/dl/ then re-run the wizard." ;;
                "gomcp_installing") echo "Installing go-docs-mcp via Go..." ;;
                "gomcp_installed") echo "go-docs-mcp installed successfully." ;;
                "gomcp_failed") echo "go-docs-mcp not found after install. Check that ~/go/bin is in your PATH." ;;
                "preset_label") echo "Selected preset:" ;;
                "dry_backup_create") echo "Would create backup at" ;;
                "invalid_choice_abort") echo "Invalid choice. Aborting." ;;
                "restore_cancelled") echo "Restore cancelled." ;;
                "backup_files_header") echo "Files in this backup:" ;;
                "cancelled") echo "Cancelled." ;;
                "backups_found_count") echo "Found" ;;
                "backups_total_size") echo "total." ;;
                "dry_delete_backups") echo "Would delete ALL backups in" ;;
                "backup_before_reset") echo "Creating backup before reset..." ;;
                "dry_reset_remove_configs") echo "Would remove: opencode.jsonc, system_info.md, wezterm.lua, OpenCode.desktop" ;;
                "dry_reset_remove_terminal") echo "Would remove TERMINAL export from .bashrc/.zshrc" ;;
                "dry_reset_remove_plugins") echo "Would remove OpenCode plugins" ;;
                "removed_file") echo "Removed:" ;;
                "removed_terminal_export") echo "Removed TERMINAL export from" ;;
                "removing_plugin") echo "Removing plugin:" ;;
                "dry_migrate_plugin") echo "Would migrate oh-my-opencode → oh-my-openagent in" ;;
                "dry_wezterm_brew") echo "Would run: brew install --cask wezterm" ;;
                "dry_wezterm_ubuntu") echo "Would add WezTerm APT repo + apt install wezterm xclip wl-clipboard" ;;
                "dry_wezterm_redhat") echo "Would run: dnf install wezterm xclip wl-clipboard" ;;
                "dry_wezterm_arch") echo "Would run: pacman -S wezterm xclip wl-clipboard" ;;
                "dry_wezterm_unsupported_distro") echo "Unsupported distro for auto-install:" ;;
                "dry_wezterm_unsupported_os") echo "Unsupported OS:" ;;
                "dry_wezterm_skipped") echo "WezTerm installation skipped (dry-run)" ;;
                "go_already_installed") echo "Go is already installed:" ;;
                "go_version_old") echo "Go version is too old — need 1.22+." ;;
                "dry_install_go") echo "Would install Go 1.24.0 for" ;;
                "unsupported_arch") echo "Unsupported architecture:" ;;
                "go_installed_to") echo "Go 1.24.0 installed to /usr/local/go" ;;
                "brew_install_first") echo "Homebrew not found. Installing Homebrew first..." ;;
                "dry_install_brew") echo "Would install Homebrew (requires sudo)" ;;
                "go_unsupported_os") echo "Unsupported OS for automatic Go installation:" ;;
                "go_install_path_failed") echo "Go installation failed — not found in PATH after install." ;;
                "go_installed_version") echo "Go installed:" ;;
                "gomcp_already_installed") echo "go-docs-mcp already installed:" ;;
                "gomcp_go_required") echo "Go is required for docs-mcp. Run install_go first." ;;
                "dry_install_gomcp") echo "Would run: go install github.com/drolosoft/go-docs-mcp@v1.1.0" ;;
                "dry_install_node") echo "Would install Node.js/npm for" ;;
                "dry_node_brew") echo "Would run: brew install node" ;;
                "dry_node_apt") echo "Would run: apt install -y nodejs npm" ;;
                "dry_node_dnf") echo "Would run: dnf install -y nodejs npm" ;;
                "dry_node_pacman") echo "Would run: pacman -S --noconfirm nodejs npm" ;;
                "dry_install_opencode") echo "Would install OpenCode via official script, package manager, or npm fallback" ;;
                "dry_opencode_skipped") echo "OpenCode installation skipped (dry-run)" ;;
                "skip_plugin_preset") echo "Skipping (not in preset):" ;;
                "dry_install_plugin") echo "Would install plugin:" ;;
                "plugin_install_failed") echo "Failed to install or already installed:" ;;
                "skip_mcp_preset") echo "Skipping MCP (not in preset):" ;;
                "dry_write_system_info") echo "Would write system_info.md to" ;;
                "dry_write_opencode_config") echo "Would write opencode.jsonc to" ;;
                "dry_plugins_list") echo "Plugins:" ;;
                "dry_mcp_configured") echo "MCP servers: configured based on your selections" ;;
                "dry_opencode_config_skipped") echo "OpenCode config skipped (dry-run)" ;;
                "dry_wezterm_dir") echo "Would create directory:" ;;
                "dry_wezterm_config") echo "Would write WezTerm config to" ;;
                "dry_wezterm_config_skipped") echo "WezTerm config skipped (dry-run)" ;;
                "dry_wezterm_legacy_resolve") echo "Would remove or symlink ~/.wezterm.lua (if conflicting)" ;;
                "dry_default_terminal_register") echo "Would register WezTerm as default x-terminal-emulator (update-alternatives)" ;;
                "dry_xdg_terminals") echo "Would write XDG terminal configs to ~/.config/xdg-terminals.list" ;;
                "dry_terminal_export") echo "Would append 'export TERMINAL=wezterm' to shell configs (bashrc/zshrc/profile)" ;;
                "update_alternatives_register_failed") echo "Failed to register WezTerm in update-alternatives" ;;
                "update_alternatives_set_failed") echo "Failed to set default x-terminal-emulator" ;;
                "dry_desktop_shortcut") echo "Would create desktop shortcut:" ;;
                "verify_wezterm") echo "WezTerm:" ;;
                "verify_opencode") echo "OpenCode:" ;;
                "active_mcp_servers") echo "Active MCP Servers:" ;;
                "mcp_status_failed") echo "Could not retrieve MCP status." ;;
                "dry_run_complete") echo "DRY-RUN COMPLETE — No changes were made to your system." ;;
                "dry_run_apply") echo "Run without --dry-run to apply." ;;
                "list_total") echo "Total:" ;;
                "list_backups_label") echo "backup(s)" ;;
                "list_size") echo "Size:" ;;
                "select_preset_title") echo "Select configuration preset:" ;;
                "preset_developer") echo "1)🍔 Developer — everything included (recommended)" ;;
                "preset_standard") echo "2)🥪 Standard — essential plugins + core MCPs (fetch, docs-mcp)" ;;
                "preset_minimal") echo "3)🥗 Minimal — minimal setup" ;;
                "preset_mcps_label") echo "MCPs:" ;;
                "preset_plugins_label") echo "Plugins:" ;;
                "preset_tools_label") echo "Tools:" ;;
                "preset_choice") echo "Choice [1-3] (default: 1):" ;;
                "nerdfont_exists") echo "JetBrainsMono Nerd Font already installed." ;;
                "installing_nerdfont") echo "Downloading JetBrainsMono Nerd Font from GitHub..." ;;
                "nerdfont_success") echo "JetBrainsMono Nerd Font installed!" ;;
                "nerdfont_failed") echo "Failed to install JetBrainsMono Nerd Font" ;;
                "dry_nerdfont") echo "Would download and install JetBrainsMono Nerd Font" ;;
                "gitui_exists") echo "Gitui is already installed:" ;;
                "ask_gitui") echo "Install Gitui (terminal TUI for Git)?" ;;
                "skip_gitui") echo "Skipping Gitui installation." ;;
                "installing_gitui") echo "Installing Gitui..." ;;
                "gitui_success") echo "Gitui installed successfully!" ;;
                "gitui_manual") echo "Please install Gitui manually: https://github.com/extrawurst/gitui" ;;
                "dry_install_gitui") echo "Would install Gitui for" ;;
            esac
            ;;
    esac
}

# 1. Ask for Language Choice
select_language() {
    if [ "$SILENT" = true ]; then
        LANG_CODE="en"
        return 0
    fi
    echo "Select wizard language / Оберіть мову інтерфейсу:"
    echo "  1) English (en)"
    echo "  2) Українська (uk)"
    read -p "Choice / Вибір [1-2]: " lang_choice
    case "$lang_choice" in
        2) LANG_CODE="uk" ;;
        *) LANG_CODE="en" ;;
    esac
    echo ""
}

# Check if a name is in a preset list
# Usage: is_in_preset "$name" "${preset_array[@]}"
is_in_preset() {
    local target="$1"
    shift
    for item in "$@"; do
        [ "$item" = "$target" ] && return 0
    done
    return 1
}

# Select preset interactively
select_preset() {
    if [ "$SILENT" = true ]; then
        [ -z "$PRESET" ] && PRESET="$PRESET_DEVELOPER"
        return 0
    fi
    echo -e "\n${BOLD}$(msg "select_preset_title")${NC}"
    echo -e "  ${BOLD}$(msg "preset_developer")${NC}"
    echo -e "     ${CYAN}$(msg "preset_mcps_label")${NC} fetch, puppeteer, postgres, context7, codegraph, docs-mcp, lsp-mcp"
    echo -e "     ${CYAN}$(msg "preset_plugins_label")${NC} oh-my-openagent, opencode-mem, @different-ai/opencode-browser, @tarquinen/opencode-smart-title, opencode-token-speed-plugin, opencode-codebase-index"
    echo -e "     ${CYAN}$(msg "preset_tools_label")${NC} gitui — $(grep '^tool:gitui:' "$(dirname "$0")/config/dev-tools.conf" 2>/dev/null | cut -d: -f3- || echo "Git TUI with real-time monitoring")"
    echo -e "  ${BOLD}$(msg "preset_standard")${NC}"
    echo -e "     ${CYAN}$(msg "preset_mcps_label")${NC} fetch, docs-mcp"
    echo -e "  ${BOLD}$(msg "preset_minimal")${NC}"
    echo -e "     ${CYAN}$(msg "preset_mcps_label")${NC} fetch"
    read -p "$(msg "preset_choice") " preset_choice
    case "$preset_choice" in
        2) PRESET="$PRESET_STANDARD" ;;
        3) PRESET="$PRESET_MINIMAL" ;;
        *) PRESET="$PRESET_DEVELOPER" ;;
    esac
    log_info "$(msg "preset_label") ${BOLD}${PRESET}${NC}"
    echo ""
}

# Ask for confirmation helper
ask_confirm() {
    local prompt="$1"
    local default="${2:-Y}"
    if [ "$SILENT" = true ]; then
        if [ "$default" = "Y" ] || [ "$default" = "y" ]; then
            return 0
        else
            return 1
        fi
    fi
    local response
    if [ "$default" = "Y" ]; then
        read -p "$(echo -e "${CYAN}${BOLD}${prompt} [Y/n]: ${NC}")" response
        response="${response:-y}"
    else
        read -p "$(echo -e "${CYAN}${BOLD}${prompt} [y/N]: ${NC}")" response
        response="${response:-n}"
    fi
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

log_info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} $1"
}

# Show Onboarding
show_onboarding() {
    echo -e "${MAGENTA}${BOLD}================================================================${NC}"
    msg "title"
    echo -e "${MAGENTA}${BOLD}================================================================${NC}\n"
    msg "intro_text"
    echo -e "\n${MAGENTA}${BOLD}================================================================${NC}\n"
}

# OS detection
detect_os() {
    # System Mocking: Force OS for testing
    if [[ -n "${OCW_FORCE_OS:-}" ]]; then
        OS="$OCW_FORCE_OS"
        DISTRO="mock"
        log_warning "OS Emulation enabled: Operating as $OS"
        return 0
    fi
    
    log_info "$(msg "detecting_os")"
    OS="unknown"
    DISTRO="unknown"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
            if [[ "$DISTRO" == "cachyos" || "$DISTRO" == "archos" || "$DISTRO" == "manjaro" ]]; then
                DISTRO="arch"
            elif [[ "$DISTRO" == "linuxmint" || "$DISTRO" == "pop" ]]; then
                DISTRO="ubuntu"
            elif [[ "$DISTRO" == "centos" || "$DISTRO" == "fedora" || "$DISTRO" == "rhel" ]]; then
                DISTRO="redhat"
            fi
        fi
    fi
    log_success "$(msg "os_detected") $OS ($DISTRO)"
}

# ==============================================================================
# Backup system
# ==============================================================================

generate_backup_id() {
    local script_hash
    script_hash=$(git -C "$(dirname "$0")" rev-parse --short HEAD 2>/dev/null || echo "local")
    BACKUP_ID="ocw-${script_hash}-$(date +%Y%m%d-%H%M%S)"
}

# Back up all currently-existing managed config files into $BACKUP_DIR/$BACKUP_ID/
# Idempotent: safe to call multiple times in one session.
create_backup() {
    [ -z "$BACKUP_ID" ] && generate_backup_id

    if is_dry_run; then
        log_dry "$(msg "dry_backup_create") $BACKUP_DIR/$BACKUP_ID"
        return 0
    fi

    local dest="$BACKUP_DIR/$BACKUP_ID"
    mkdir -p "$dest"

    local backed_up=()
    local opencode_cfg="$HOME/.config/opencode/opencode.jsonc"
    local sysinfo="$HOME/.config/opencode/system_info.md"
    local wez_cfg="$HOME/.config/wezterm/wezterm.lua"
    local bashrc="$HOME/.bashrc"
    local zshrc="$HOME/.zshrc"

    [ -f "$opencode_cfg" ] && cp "$opencode_cfg" "$dest/opencode.jsonc"  && backed_up+=("opencode.jsonc")
    [ -f "$sysinfo" ]      && cp "$sysinfo"      "$dest/system_info.md"  && backed_up+=("system_info.md")
    [ -f "$wez_cfg" ]      && cp "$wez_cfg"       "$dest/wezterm.lua"     && backed_up+=("wezterm.lua")
    [ -f "$bashrc" ]       && cp "$bashrc"        "$dest/bashrc"          && backed_up+=("bashrc")
    [ -f "$zshrc" ]        && cp "$zshrc"         "$dest/zshrc"           && backed_up+=("zshrc")

    # Write manifest
    {
        echo "BACKUP_ID=$BACKUP_ID"
        echo "CREATED=$(date -Iseconds)"
        echo "FILES=${backed_up[*]}"
    } > "$dest/manifest.txt"

    log_success "$(msg "backup_created")"
    log_info "$(msg "backup_id_label") $BACKUP_ID"
    log_info "$(msg "backup_location") $dest"
}

# List backups and return array via global BACKUPS_LIST / BACKUPS_COUNT
# Returns 0 if backups exist, 1 if none.
list_backups() {
    BACKUPS_LIST=()
    BACKUPS_COUNT=0
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        return 1
    fi

    local i=1
    while IFS= read -r -d '' dir; do
        local manifest="$dir/manifest.txt"
        local created=""
        local files=""
        if [ -f "$manifest" ]; then
            created=$(grep '^CREATED=' "$manifest" | cut -d= -f2-)
            files=$(grep '^FILES=' "$manifest" | cut -d= -f2-)
        fi
        local bname
        bname=$(basename "$dir")
        printf "  %d) %s  [%s]  (%s)\n" "$i" "$bname" "${created:-unknown}" "${files:-no files}"
        BACKUPS_LIST+=("$dir")
        i=$((i+1))
    done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    BACKUPS_COUNT=$((i - 1))
    return 0
}

restore_backup() {
    if ! list_backups; then
        log_warning "$(msg "no_backups_found")"
        return 0
    fi

    echo ""
    read -rp "$(msg "select_backup") " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$BACKUPS_COUNT" ]; then
        log_error "$(msg "invalid_choice_abort")"
        return 1
    fi

    local selected="${BACKUPS_LIST[$((choice-1))]}"
    echo -e "\n$(msg "backup_files_header")"
    find "$selected" -maxdepth 1 -type f ! -name 'manifest.txt' -printf '  %f\n'
    echo ""

    if ! ask_confirm "$(msg "restore_confirm")"; then
        log_info "$(msg "restore_cancelled")"
        return 0
    fi

    # Pre-restore backup (tихий)
    local old_id="$BACKUP_ID"
    generate_backup_id
    local prerestore_dest="$BACKUP_DIR/$BACKUP_ID"
    mkdir -p "$prerestore_dest"
    [ -f "$HOME/.config/opencode/opencode.jsonc" ] && cp "$HOME/.config/opencode/opencode.jsonc" "$prerestore_dest/opencode.jsonc"
    [ -f "$HOME/.config/opencode/system_info.md" ] && cp "$HOME/.config/opencode/system_info.md" "$prerestore_dest/system_info.md"
    [ -f "$HOME/.config/wezterm/wezterm.lua" ]     && cp "$HOME/.config/wezterm/wezterm.lua"     "$prerestore_dest/wezterm.lua"
    echo "BACKUP_ID=$BACKUP_ID" > "$prerestore_dest/manifest.txt"
    echo "CREATED=$(date -Iseconds)" >> "$prerestore_dest/manifest.txt"
    echo "NOTE=pre-restore snapshot" >> "$prerestore_dest/manifest.txt"
    BACKUP_ID="$old_id"

    # Transactional restore: copy to temp, then move
    local tmpdir
    tmpdir=$(mktemp -d)
    if ! cp -r "$selected/." "$tmpdir/"; then
        log_error "$(msg "restore_failed")"
        rm -rf "$tmpdir"
        return 1
    fi

    # Apply
    local failed=false
    [ -f "$tmpdir/opencode.jsonc" ] && { mkdir -p "$HOME/.config/opencode"; cp "$tmpdir/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc" || failed=true; }
    [ -f "$tmpdir/system_info.md" ] && { mkdir -p "$HOME/.config/opencode"; cp "$tmpdir/system_info.md"  "$HOME/.config/opencode/system_info.md"  || failed=true; }
    [ -f "$tmpdir/wezterm.lua" ]    && { mkdir -p "$HOME/.config/wezterm";  cp "$tmpdir/wezterm.lua"    "$HOME/.config/wezterm/wezterm.lua"       || failed=true; }
    [ -f "$tmpdir/bashrc" ]         && cp "$tmpdir/bashrc"  "$HOME/.bashrc"  || failed=true
    [ -f "$tmpdir/zshrc" ]          && cp "$tmpdir/zshrc"   "$HOME/.zshrc"   || failed=true

    rm -rf "$tmpdir"

    if [ "$failed" = true ]; then
        log_error "$(msg "restore_failed")"
        return 1
    fi

    log_success "$(msg "restore_success")"
}

remove_backups() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_warning "$(msg "no_backups_found")"
        return 0
    fi

    local count
    count=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
    local size
    size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "?")
    echo -e "\n$(msg "backups_found_count") ${BOLD}${count}${NC} $(msg "list_backups_label"), ~${size} $(msg "backups_total_size")"

    if ! ask_confirm "$(msg "remove_backups_confirm")"; then
        log_info "$(msg "cancelled")"
        return 0
    fi

    if is_dry_run; then
        log_dry "$(msg "dry_delete_backups") $BACKUP_DIR"
        return 0
    fi

    rm -rf "$BACKUP_DIR"
    log_success "$(msg "remove_backups_success")"
}

reset_config() {
    log_info "$(msg "backup_before_reset")"
    create_backup

    if is_dry_run; then
        log_dry "$(msg "dry_reset_remove_configs")"
        log_dry "$(msg "dry_reset_remove_terminal")"
        log_dry "$(msg "dry_reset_remove_plugins")"
        return 0
    fi

    local opencode_cfg="$HOME/.config/opencode/opencode.jsonc"
    local sysinfo="$HOME/.config/opencode/system_info.md"
    local wez_cfg="$HOME/.config/wezterm/wezterm.lua"
    local desktop="$HOME/Desktop/OpenCode.desktop"

    [ -f "$opencode_cfg" ] && { rm -f "$opencode_cfg"; log_info "$(msg "removed_file") $opencode_cfg"; }
    [ -f "$sysinfo" ]      && { rm -f "$sysinfo";      log_info "$(msg "removed_file") $sysinfo"; }
    [ -f "$wez_cfg" ]      && { rm -f "$wez_cfg";       log_info "$(msg "removed_file") $wez_cfg"; }
    [ -f "$desktop" ]      && { rm -f "$desktop";       log_info "$(msg "removed_file") $desktop"; }

    # Remove shell exports only if we previously backed up that file
    local dest="$BACKUP_DIR/$BACKUP_ID"
    for shell_file in ".bashrc" ".zshrc"; do
        local backup_name="${shell_file//./}"  # .bashrc -> bashrc
        if [ -f "$dest/$backup_name" ]; then
            local full_path="$HOME/$shell_file"
            if [ -f "$full_path" ] && grep -q "export TERMINAL=wezterm" "$full_path"; then
                sed -i.bak '/^# OpenCode default terminal$/d' "$full_path" && rm -f "$full_path.bak"
                sed -i.bak '/^export TERMINAL=wezterm$/d' "$full_path" && rm -f "$full_path.bak"
                log_info "$(msg "removed_terminal_export") $full_path"
            fi
        fi
    done

    # Remove plugins
    if command -v opencode &>/dev/null; then
        for entry in "${OPENCODE_PLUGINS[@]}"; do
            local plugin_name="${entry%%|*}"
            log_info "$(msg "removing_plugin") $plugin_name"
            opencode plugin remove "$plugin_name" 2>/dev/null || true
        done
    fi

    log_success "$(msg "reset_done")"
}

# Migrate legacy oh-my-opencode → oh-my-openagent in opencode.jsonc
migrate_plugin_names() {
    local config="$HOME/.config/opencode/opencode.jsonc"
    if [ -f "$config" ] && grep -q "oh-my-opencode" "$config"; then
        log_warning "$(msg "migrate_plugin")"
        if is_dry_run; then
            log_dry "$(msg "dry_migrate_plugin") $config"
            return 0
        fi
        create_backup
        sed -i.bak 's/oh-my-opencode/oh-my-openagent/g' "$config" && rm -f "$config.bak"
        if command -v opencode &>/dev/null; then
            opencode plugin oh-my-openagent --global 2>/dev/null || true
        fi
        log_success "$(msg "migrate_plugin_done")"
    fi
}

# Convert "npx -y pkg arg" → JSON array ["npx", "-y", "pkg", "arg"]
args_to_json_array() {
    local args_str="$1"
    local json="["
    local first=true
    for arg in $args_str; do
        [ "$first" = false ] && json="$json, "
        # Escape double quotes and backslashes inside each argument
        local escaped="${arg//\\/\\\\}"
        escaped="${escaped//\"/\\\"}"
        json="${json}\"${escaped}\""
        first=false
    done
    echo "${json}]"
}

# WezTerm Installation
install_wezterm() {
    if command -v wezterm &>/dev/null; then
        log_success "$(msg "wezterm_exists") $(wezterm --version | head -n 1)"
        return 0
    fi

    if ! ask_confirm "$(msg "ask_wezterm")"; then
        log_info "$(msg "skip_wezterm")"
        return 0
    fi

    log_info "$(msg "installing_wezterm")"

    if is_dry_run; then
        case "$OS" in
            macos)  log_dry "$(msg "dry_wezterm_brew")" ;;
            linux)
                case "$DISTRO" in
                    ubuntu) log_dry "$(msg "dry_wezterm_ubuntu")" ;;
                    redhat) log_dry "$(msg "dry_wezterm_redhat")" ;;
                    arch)   log_dry "$(msg "dry_wezterm_arch")" ;;
                    *)      log_dry "$(msg "dry_wezterm_unsupported_distro") $DISTRO" ;;
                esac ;;
            *) log_dry "$(msg "dry_wezterm_unsupported_os") $OS" ;;
        esac
        log_dry "$(msg "dry_wezterm_skipped")"
        return 0
    fi

    case "$OS" in
        macos)
            if ! command -v brew &>/dev/null; then
                log_error "$(msg "brew_missing")"
                exit 1
            fi
            brew install --cask wezterm
            ;;
        linux)
            case "$DISTRO" in
                ubuntu)
                    log_info "$(msg "adding_repo")"
                    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
                    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
                    sudo apt update
                    sudo apt install -y wezterm xclip wl-clipboard
                    ;;
                 redhat)
                    log_info "$(msg "adding_repo")"
                    sudo dnf copr enable wezfurlong/wezterm-nightly -y || true
                    sudo dnf install -y wezterm xclip wl-clipboard || sudo dnf install -y wezterm xclip wl-clipboard --disablerepo="*copr*"
                    ;;
                arch)
                    log_info "$(msg "installing_pacman")"
                    sudo pacman -S --noconfirm wezterm xclip wl-clipboard
                    ;;
                *)
                    log_error "$(msg "unsupported_distro") $DISTRO"
                    log_info "$(msg "manual_wezterm")"
                    exit 1
                    ;;
            esac
            ;;
        *)
            log_error "$(msg "unsupported_os") $OS"
            exit 1
            ;;
    esac
    log_success "$(msg "wezterm_success")"
    hash -r
}

# ==============================================================================
# JetBrainsMono Nerd Font (universal icon coverage, no mojibake)
# ==============================================================================
install_nerd_font() {
    if is_dry_run; then
        log_dry "$(msg "dry_nerdfont")"
        return 0
    fi

    case "$OS" in
        linux)
            local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
            mkdir -p "$font_dir"

            # Check if already installed
            if [ -f "$font_dir/JetBrainsMonoNerdFontMono-Regular.ttf" ]; then
                log_success "$(msg "nerdfont_exists")"
                return 0
            fi

            log_info "$(msg "installing_nerdfont")"

            local tmp_dir
            tmp_dir=$(mktemp -d)
            cd "$tmp_dir" || return 1

            if command -v curl &>/dev/null; then
                curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip" -o JetBrainsMono.zip
            else
                wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip" -O JetBrainsMono.zip
            fi

            unzip -q JetBrainsMono.zip -d JetBrainsMonoNerd
            find JetBrainsMonoNerd -name "*.ttf" -exec cp {} "$font_dir/" \;

            # Update font cache
            if command -v fc-cache &>/dev/null; then
                fc-cache -f "$font_dir" 2>/dev/null
            fi

            cd /tmp || true
            rm -rf "$tmp_dir"

            log_success "$(msg "nerdfont_success")"
            ;;
        macos)
            local font_dir="$HOME/Library/Fonts"

            # Check if already installed
            if [ -f "$font_dir/JetBrainsMonoNerdFontMono-Regular.ttf" ]; then
                log_success "$(msg "nerdfont_exists")"
                return 0
            fi

            log_info "$(msg "installing_nerdfont")"

            local tmp_dir
            tmp_dir=$(mktemp -d)
            cd "$tmp_dir" || return 1

            curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip" -o JetBrainsMono.zip
            unzip -q JetBrainsMono.zip -d JetBrainsMonoNerd
            find JetBrainsMonoNerd -name "*.ttf" -exec cp {} "$font_dir/" \;

            cd /tmp || true
            rm -rf "$tmp_dir"

            log_success "$(msg "nerdfont_success")"
            ;;
        *)
            log_info "$(msg "unsupported_os") $OS"
            return 0
            ;;
    esac
}

# ==============================================================================
# Go Installation (required for docs-mcp)
# ==============================================================================
install_go() {
    if command -v go &>/dev/null; then
        local go_ver
        go_ver=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+')
        if command -v bc &>/dev/null && [ "$(echo "$go_ver >= 1.22" | bc 2>/dev/null)" = "1" ] || [ "${go_ver%%.*}" -ge 1 ] && [ "${go_ver#*.}" -ge 22 ] 2>/dev/null; then
            log_success "$(msg "go_already_installed") ${go_ver}"
            return 0
        fi
        log_info "$(msg "go_version_old")"
    fi

    log_info "$(msg "go_installing")"

    if is_dry_run; then
        log_dry "$(msg "dry_install_go") $OS/$(uname -m)"
        return 0
    fi

    local go_arch
    case "$(uname -m)" in
        x86_64)  go_arch="amd64" ;;
        aarch64|arm64) go_arch="arm64" ;;
        *) log_error "$(msg "unsupported_arch") $(uname -m)"; return 1 ;;
    esac

    case "$OS" in
        linux)
            curl -fsSL "https://go.dev/dl/go1.24.0.linux-${go_arch}.tar.gz" | sudo tar -C /usr/local -xz
            export PATH="/usr/local/go/bin:$PATH"
            log_success "$(msg "go_installed_to")"
            ;;
        macos)
            if ! command -v brew &>/dev/null; then
                log_info "$(msg "brew_install_first")"
                if is_dry_run; then
                    log_dry "$(msg "dry_install_brew")"
                else
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    if [ "$go_arch" = "arm64" ]; then
                        export PATH="/opt/homebrew/bin:$PATH"
                    else
                        export PATH="/usr/local/bin:$PATH"
                    fi
                fi
            fi
            brew install go
            ;;
        *)
            log_warning "$(msg "go_unsupported_os") $OS"
            log_info "$(msg "go_manual")"
            return 1
            ;;
    esac

    if ! command -v go &>/dev/null; then
        log_error "$(msg "go_install_path_failed")"
        return 1
    fi
    log_success "$(msg "go_installed_version") $(go version | grep -oP 'go\K[0-9.]+')"
}

# ==============================================================================
# Install docs-mcp (go-docs-mcp) via Go
# ==============================================================================
install_docs_mcp() {
    # Resolve Go binary path dynamically (respects custom GOPATH)
    local go_mcp_path=""
    if command -v go &>/dev/null; then
        go_mcp_path="$(go env GOPATH)/bin/go-docs-mcp"
    else
        go_mcp_path="$HOME/go/bin/go-docs-mcp"
    fi

    if command -v go-docs-mcp &>/dev/null || [ -f "$go_mcp_path" ]; then
        log_success "$(msg "gomcp_already_installed")"
        return 0
    fi

    if ! command -v go &>/dev/null; then
        log_warning "$(msg "gomcp_go_required")"
        return 1
    fi

    if is_dry_run; then
        log_dry "$(msg "dry_install_gomcp")"
        return 0
    fi

    log_info "$(msg "gomcp_installing")"
    go install github.com/drolosoft/go-docs-mcp@v1.1.0

    # Resolve path again (GOPATH may have changed after install)
    go_mcp_path="$(go env GOPATH)/bin/go-docs-mcp"
    PATH="$(go env GOPATH)/bin:$PATH"
    export PATH

    if [ -f "$go_mcp_path" ] && command -v go-docs-mcp &>/dev/null; then
        log_success "$(msg "gomcp_installed") $(go-docs-mcp --version 2>/dev/null || echo 'present')"
    else
        log_error "$(msg "gomcp_failed")"
        return 1
    fi
}

# ==============================================================================
# Developer Tools
# ==============================================================================

# Read description from config/dev-tools.conf for a given tool name
show_dev_tool_info() {
    local tool_name="$1"
    local conf_file
    conf_file="$(dirname "$0")/config/dev-tools.conf"
    if [ -f "$conf_file" ]; then
        local desc
        desc=$(grep "^tool:${tool_name}:" "$conf_file" 2>/dev/null | cut -d: -f3-)
        if [ -n "$desc" ]; then
            log_info "🔧 $tool_name — $desc"
        fi
    fi
}

# Install Gitui (terminal TUI for Git)
install_gitui() {
    if command -v gitui &>/dev/null; then
        log_success "$(msg "gitui_exists") $(gitui --version 2>/dev/null || true)"
        return 0
    fi

    if ! ask_confirm "$(msg "ask_gitui")"; then
        log_info "$(msg "skip_gitui")"
        return 0
    fi

    show_dev_tool_info "gitui"

    if is_dry_run; then
        log_dry "$(msg "dry_install_gitui") $OS/$DISTRO"
        return 0
    fi

    log_info "$(msg "installing_gitui")"
    case "$OS" in
        macos)
            brew install gitui
            ;;
        linux)
            case "$DISTRO" in
                ubuntu)
                    sudo apt install -y gitui
                    ;;
                redhat)
                    sudo dnf install -y gitui
                    ;;
                arch)
                    sudo pacman -S --noconfirm gitui
                    ;;
                *)
                    log_warning "$(msg "gitui_manual")"
                    return 1
                    ;;
            esac
            ;;
        *)
            log_warning "$(msg "gitui_manual")"
            return 1
            ;;
    esac

    if command -v gitui &>/dev/null; then
        log_success "$(msg "gitui_success")"
    else
        log_warning "$(msg "gitui_manual")"
    fi
}

# Node.js / npm installation (with user consent)
install_nodejs() {
    if command -v npm &>/dev/null; then
        log_success "$(msg "node_exists")"
        return 0
    fi

    echo -e "\n$(msg "node_explain")\n"

    if ! ask_confirm "$(msg "ask_node")"; then
        log_warning "$(msg "node_skip_warning")"
        return 0
    fi

    if is_dry_run; then
        case "$OS" in
            macos) log_dry "$(msg "dry_node_brew")" ;;
            linux)
                case "$DISTRO" in
                    ubuntu) log_dry "$(msg "dry_node_apt")" ;;
                    redhat) log_dry "$(msg "dry_node_dnf")" ;;
                    arch)   log_dry "$(msg "dry_node_pacman")" ;;
                    *)      log_dry "$(msg "dry_install_node") $OS/$DISTRO" ;;
                esac ;;
            *) log_dry "$(msg "dry_install_node") $OS/$DISTRO" ;;
        esac
        return 0
    fi

    log_info "$(msg "installing_node")"

    case "$OS" in
        macos)
            if ! command -v brew &>/dev/null; then
                log_error "$(msg "brew_missing")"
                return 1
            fi
            brew install node
            ;;
        linux)
            case "$DISTRO" in
                ubuntu|debian)
                    sudo apt update
                    sudo apt install -y nodejs npm
                    ;;
                redhat|fedora)
                    sudo dnf install -y nodejs npm
                    ;;
                arch)
                    sudo pacman -S --noconfirm nodejs npm
                    ;;
                *)
                    # Fallback: Homebrew on Linux if available
                    if command -v brew &>/dev/null; then
                        brew install node
                    else
                        log_warning "$(msg "node_manual")"
                        return 1
                    fi
                    ;;
            esac
            ;;
        *)
            log_warning "$(msg "node_manual")"
            return 1
            ;;
    esac

    hash -r
    if command -v npm &>/dev/null; then
        log_success "$(msg "node_success")"
    else
        log_warning "$(msg "node_path_hint")"
    fi
}

# Ensure OpenCode binary directories are on PATH for the current session
ensure_opencode_path() {
    local candidates=(
        "$HOME/.opencode/bin"
        "$HOME/.local/bin"
        "$HOME/bin"
        "/opt/homebrew/bin"
        "/usr/local/bin"
    )
    for dir in "${candidates[@]}"; do
        if [ -x "$dir/opencode" ]; then
            if [[ ":$PATH:" != *":$dir:"* ]]; then
                export PATH="$dir:$PATH"
            fi
            return 0
        fi
    done
    return 1
}

# OpenCode Installation
install_opencode() {
    if command -v opencode &>/dev/null; then
        log_success "$(msg "opencode_exists") $(opencode --version)"
        return 0
    fi

    if ! ask_confirm "$(msg "ask_opencode")"; then
        log_info "$(msg "skip_opencode")"
        return 0
    fi

    if is_dry_run; then
        log_dry "$(msg "dry_install_opencode")"
        log_dry "$(msg "dry_opencode_skipped")"
        return 0
    fi

    local installed=false

    # Method 1: npm (preferred when available)
    if command -v npm &>/dev/null; then
        log_info "$(msg "installing_opencode_npm")"
        local npm_prefix
        npm_prefix=$(npm config get prefix)
        if [ -w "$npm_prefix" ]; then
            npm install -g opencode-ai@latest
        else
            sudo npm install -g opencode-ai@latest
        fi
        command -v opencode &>/dev/null && installed=true
    fi

    # Method 2: Official install script (fallback when npm is unavailable)
    if [ "$installed" = false ] && command -v curl &>/dev/null; then
        log_info "$(msg "installing_opencode_script")"
        if curl -fsSL https://opencode.ai/install | bash; then
            ensure_opencode_path
            command -v opencode &>/dev/null && installed=true
        else
            log_warning "$(msg "opencode_script_failed")"
        fi
    fi

    # Method 3: Homebrew (macOS and Linux with Homebrew)
    if [ "$installed" = false ] && command -v brew &>/dev/null; then
        log_info "$(msg "installing_opencode_brew")"
        if brew install anomalyco/tap/opencode 2>/dev/null || brew install opencode 2>/dev/null; then
            command -v opencode &>/dev/null && installed=true
        fi
    fi

    # Method 4: Arch Linux pacman
    if [ "$installed" = false ] && [ "$DISTRO" = "arch" ] && command -v pacman &>/dev/null; then
        log_info "$(msg "installing_opencode_pacman")"
        if sudo pacman -S --noconfirm opencode 2>/dev/null; then
            command -v opencode &>/dev/null && installed=true
        fi
    fi

    if [ "$installed" = false ]; then
        ensure_opencode_path
        command -v opencode &>/dev/null && installed=true
    fi

    if [ "$installed" = false ]; then
        log_error "$(msg "opencode_failed")"
        log_info "$(msg "opencode_manual")"
        exit 1
    fi

    log_success "$(msg "opencode_success") $(opencode --version 2>/dev/null || true)"
    hash -r
}

# Plugins setup
install_plugins() {
    if ! command -v opencode &>/dev/null; then
        return 0
    fi

    if ! ask_confirm "$(msg "ask_plugins")"; then
        log_info "$(msg "skip_plugins")"
        return 0
    fi

    # Resolve preset plugin list
    # Use central definitions from components.sh
    local preset_plugins=()
    case "$PRESET" in
        "$PRESET_STANDARD") preset_plugins=("${PRESET_STANDARD_PLUGINS[@]}") ;;
        "$PRESET_MINIMAL")  preset_plugins=("${PRESET_MINIMAL_PLUGINS[@]}") ;;
        *)                  preset_plugins=("${PRESET_DEVELOPER_PLUGINS[@]}") ;;
    esac

    local install_all=true
    if ! ask_confirm "$(msg "ask_plugins_default")"; then
        install_all=false
    fi

    # Track if we've already installed a speed plugin to avoid conflicts
    local speed_plugin_installed=false

    for entry in "${OPENCODE_PLUGINS[@]}"; do
        local plugin_name="${entry%%|*}"
        local plugin_desc="${entry#*|}"
        local doc_url="https://github.com/nudykw/OpenCodeWizard/blob/main/docs/plugins.md#${plugin_name}"
        [ "$LANG_CODE" = "uk" ] && doc_url="https://github.com/nudykw/OpenCodeWizard/blob/main/docs/plugins.uk.md#${plugin_name}"

        # Skip if not in preset
        if ! is_in_preset "$plugin_name" "${preset_plugins[@]}"; then
            log_info "$(msg "skip_plugin_preset") $plugin_name"
            continue
        fi

        # Collision check for speed plugins
        if [[ "$plugin_name" == *"token-speed"* ]]; then
            if [ "$speed_plugin_installed" = true ]; then
                log_warning "Skipping $plugin_name: a speed plugin is already selected."
                continue
            fi
            speed_plugin_installed=true
        fi

        local should_install=true
        if [ "$install_all" = false ]; then
            echo -e "\n--> ${BOLD}${plugin_name}${NC}"
            echo -e "    ${plugin_desc}"
            echo -e "    ${BLUE}${doc_url}${NC}"
            if ! ask_confirm "$(msg "ask_plugin_install") ${plugin_name}?"; then
                should_install=false
            fi
        fi

        if [ "$should_install" = true ]; then
            if is_dry_run; then
                log_dry "$(msg "dry_install_plugin") $plugin_name"
            else
                log_info "$(msg "installing_plugin") ${plugin_name}..."
                opencode plugin "${plugin_name}" --global || log_warning "$(msg "plugin_install_failed") ${plugin_name}"
            fi
        fi
    done

    log_success "$(msg "plugins_success")"
}

# OpenCode Config Setup
configure_opencode() {
    if ! ask_confirm "$(msg "ask_mcp")"; then
        log_info "$(msg "skip_mcp")"
        return 0
    fi

    local config_dir="$HOME/.config/opencode"
    mkdir -p "$config_dir"
    local config_file="$config_dir/opencode.jsonc"

    # Backup existing config using session BACKUP_ID
    if [ -f "$config_file" ]; then
        create_backup
    fi

    # Resolve preset lists
    local preset_plugins=()
    local preset_mcps=()
    case "$PRESET" in
        "$PRESET_STANDARD")
            preset_plugins=("${PRESET_STANDARD_PLUGINS[@]}")
            preset_mcps=("${PRESET_STANDARD_MCPS[@]}")
            ;;
        "$PRESET_MINIMAL")
            preset_plugins=("${PRESET_MINIMAL_PLUGINS[@]}")
            preset_mcps=("${PRESET_MINIMAL_MCPS[@]}")
            ;;
        *)
            preset_plugins=("${PRESET_DEVELOPER_PLUGINS[@]}")
            preset_mcps=("${PRESET_DEVELOPER_MCPS[@]}")
            ;;
    esac

    local use_all_mcp=true
    if ! ask_confirm "$(msg "ask_mcp_default")"; then
        use_all_mcp=false
    fi

    # Build MCP JSON object from OPENCODE_MCP_SERVERS array
    local mcp_json=""
    local first_mcp=true
    for entry in "${OPENCODE_MCP_SERVERS[@]}"; do
        local mcp_name
        mcp_name="${entry%%|*}"
        local rest="${entry#*|}"
        local mcp_desc="${rest%%|*}"
        local mcp_cmd="${rest#*|}"

        # Skip if not in preset
        if ! is_in_preset "$mcp_name" "${preset_mcps[@]}"; then
            log_info "$(msg "skip_mcp_preset") $mcp_name"
            continue
        fi

        local should_enable=true
        if [ "$use_all_mcp" = false ]; then
            echo -e "\n--> ${BOLD}${mcp_name}${NC}"
            echo "    $mcp_desc"
            if ! ask_confirm "$(msg "ask_mcp_install") ${mcp_name}?"; then
                should_enable=false
            fi
        fi

        if [ "$should_enable" = true ]; then
            if [ "$mcp_name" = "docs-mcp" ]; then
                install_go
                install_docs_mcp || true
                # Use absolute path so OpenCode finds the binary regardless of $PATH
                if command -v go &>/dev/null; then
                    mcp_cmd="$(go env GOPATH)/bin/go-docs-mcp"
                else
                    mcp_cmd="$HOME/go/bin/go-docs-mcp"
                fi
            fi

            local json_arr
            json_arr=$(args_to_json_array "$mcp_cmd")
            if [ "$first_mcp" = false ]; then
                mcp_json="${mcp_json},"
            fi
            mcp_json="${mcp_json}
    \"${mcp_name}\": {
      \"type\": \"local\",
      \"command\": ${json_arr},
      \"enabled\": true
    }"
            first_mcp=false
        fi
    done

    # Build plugin JSON array from OPENCODE_PLUGINS (filtered by preset)
    local plugin_json=""
    local first_plugin=true
    for entry in "${OPENCODE_PLUGINS[@]}"; do
        local pname="${entry%%|*}"
        # Skip if not in preset
        if ! is_in_preset "$pname" "${preset_plugins[@]}"; then
            continue
        fi
        if [ "$first_plugin" = false ]; then
            plugin_json="${plugin_json},"$'\n'
        fi
        plugin_json="${plugin_json}    \"${pname}\""
        first_plugin=false
    done

    # Gather system/hardware info
    local os_name="" kernel_ver="" cpu_info="" ram_info=""

    if [ "$OS" = "linux" ]; then
        if [ -f /etc/os-release ]; then
            os_name=$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || true)
        fi
        kernel_ver=$(uname -r || true)
        cpu_info=$(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | sed -e 's/^[[:space:]]*//' || true)
        if [ -z "$cpu_info" ]; then
            cpu_info=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed -e 's/^[[:space:]]*//' || true)
        fi
        ram_info=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || true)
        [ -n "$ram_info" ] && ram_info="${ram_info} RAM"
    elif [ "$OS" = "macos" ]; then
        os_name="macOS $(sw_vers -productVersion 2>/dev/null || true)"
        kernel_ver=$(uname -r || true)
        cpu_info=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
        local raw_mem
        raw_mem=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
        [ "$raw_mem" -gt 0 ] && ram_info="$((raw_mem / 1024 / 1024 / 1024)) GB RAM"
    fi

    if is_dry_run; then
        log_dry "$(msg "dry_write_system_info") $config_dir/system_info.md"
        log_dry "$(msg "dry_write_opencode_config") $config_file"
        log_dry "  $(msg "dry_plugins_list") ${OPENCODE_PLUGINS[*]}"
        log_dry "  $(msg "dry_mcp_configured")"
        log_dry "$(msg "dry_opencode_config_skipped")"
        return 0
    fi

    # Write system_info.md
    cat << EOF > "$config_dir/system_info.md"
# System Environment Details

This file provides the OpenCode AI assistant with details about the current operating system and hardware environment.

- **Operating System:** ${os_name:-Unknown OS}
- **Kernel Version:** ${kernel_ver:-Unknown}
- **Processor (CPU):** ${cpu_info:-Unknown CPU}
- **System Memory (RAM):** ${ram_info:-Unknown RAM}
- **User Shell:** ${SHELL:-/bin/bash}
EOF

    # Write opencode.jsonc
    cat << EOF > "$config_file"
{
  "\$schema": "https://opencode.ai/config.json",
  "instructions": [
    "${config_dir}/system_info.md"
  ],
  "plugin": [
${plugin_json}
  ],
  "mcp": {${mcp_json}
  }
}
EOF
    log_success "$(msg "opencode_config_updated") $config_file"

    # Install Go + go-docs-mcp if docs-mcp is in the current preset
    # (Deprecated: logic moved to individual MCP installation block)
    :
}

# WezTerm Lua configuration
configure_wezterm() {
    if ! ask_confirm "$(msg "ask_wezterm_config")"; then
        log_info "$(msg "skip_wezterm_config")"
        return 0
    fi

    local wez_dir="$HOME/.config/wezterm"
    local wez_config="$wez_dir/wezterm.lua"

    if is_dry_run; then
        log_dry "$(msg "dry_wezterm_dir") $wez_dir"
        log_dry "$(msg "dry_wezterm_config") $wez_config (Catppuccin Mocha, JetBrainsMono NFM, custom hotkeys)"
        log_dry "$(msg "dry_wezterm_config_skipped")"
        return 0
    fi

    mkdir -p "$wez_dir"

    if [ -f "$wez_config" ]; then
        create_backup
    fi

    cat << 'EOF' > "$wez_config"
local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Appearance & Styling
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font 'JetBrainsMono NFM'
config.font_size = 11.0
config.window_background_opacity = 0.90
config.text_background_opacity = 0.90
config.window_padding = {
  left = 12,
  right = 12,
  top = 12,
  bottom = 12,
}
config.hide_tab_bar_if_only_one_tab = true

-- Keybindings
config.keys = {
  -- Gitui + OpenCode split in new tab (left: gitui 40%, right: opencode)
  {
    key = 'G',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { "sh", "-c",
        "root=$(git rev-parse --show-toplevel 2>/dev/null) || root=\".\"; "
        .. "wezterm cli split-pane --left --percent 40 --cwd \"$root\" -- "
        .. "bash -l -c 'gitui' "
        .. "&& opencode -m opencode/deepseek-v4-flash-free"
      },
    },
  },
  -- Gitui + OpenCode split (left: gitui 40%, right: opencode)
  {
    key = 'O',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        wezterm.action.SplitPane {
          direction = 'Left',
          size = { Percent = 40 },
          command = { args = { "sh", "-c", "root=$(git rev-parse --show-toplevel 2>/dev/null) && cd \"$root\" && gitui || echo 'Not in a git repository here - cd to a repo first'; sleep 3" } },
        },
        pane
      )
      pane:send_text("opencode -m opencode/deepseek-v4-flash-free\n")
    end),
  },
  -- Gitui + OpenCode split in new workspace (left: gitui 40%, right: opencode)
  {
    key = 'G',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.SwitchToWorkspace {
      name = 'git',
      spawn = { args = { "sh", "-c",
        "root=$(git rev-parse --show-toplevel 2>/dev/null) || root=\".\"; "
        .. "wezterm cli split-pane --left --percent 40 --cwd \"$root\" -- "
        .. "bash -l -c 'gitui' "
        .. "&& opencode -m opencode/deepseek-v4-flash-free"
      } },
    },
  },
  -- Standard splits
  {
    key = 'D',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitPane {
      direction = 'Down',
      size = { Percent = 50 },
    },
  },
  {
    key = 'E',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitPane {
      direction = 'Right',
      size = { Percent = 50 },
    },
  },
  -- Close current pane
  {
    key = 'W',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- Paste screenshot from clipboard
  {
    key = 'I',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local is_windows = wezterm.target_triple:find("windows") ~= nil
      local success = false
      local filename = ""

      if is_windows then
        local home = os.getenv("USERPROFILE")
        local pictures_dir = home .. "\\Pictures\\opencode_screenshots"
        os.execute('powershell -Command "New-Item -ItemType Directory -Force -Path \'' .. pictures_dir .. '\'" >nul 2>&1')
        local timestamp = os.date("%Y%m%d_%H%M%S")
        filename = pictures_dir .. "\\screenshot_" .. timestamp .. ".png"
        local ps_cmd = 'powershell -Command "Add-Type -AssemblyName System.Windows.Forms; if ([System.Windows.Forms.Clipboard]::ContainsImage()) { $img = [System.Windows.Forms.Clipboard]::GetImage(); $img.Save(\'' .. filename .. '\', [System.Drawing.Imaging.ImageFormat]::Png); exit 0 } else { exit 1 }"'
        if os.execute(ps_cmd) == 0 then
          success = true
          filename = filename:gsub("\\", "/")
        end
      else
        local home = os.getenv("HOME")
        local pictures_dir = home .. "/Pictures/opencode_screenshots"
        os.execute("mkdir -p " .. pictures_dir)
        local timestamp = os.date("%Y%m%d_%H%M%S")
        filename = pictures_dir .. "/screenshot_" .. timestamp .. ".png"

        -- Try Wayland (wl-paste)
        if os.execute("wl-paste --type image/png > " .. filename .. " 2>/dev/null") == 0 then
          success = true
        -- Try X11 (xclip)
        elseif os.execute("xclip -selection clipboard -target image/png -out > " .. filename .. " 2>/dev/null") == 0 then
          success = true
        -- Try macOS AppleScript
        else
          local mac_cmd = "osascript -e 'try' -e 'write (the clipboard as «class PNGf») to (open for access POSIX file \"" .. filename .. "\" with write permission)' -e 'on error' -e 'shell exit 1' -e 'end try'"
          if os.execute(mac_cmd) == 0 then
            success = true
          end
        end
      end

      if success then
        pane:send_text("@" .. filename)
        window:toast_notification("OpenCode Wizard", "Screenshot saved and attached!", 2000)
      else
        window:toast_notification("OpenCode Wizard", "No image found in clipboard!", 2000)
      end
    end),
  },
}

return config
EOF
    log_success "$(msg "wezterm_config_saved") $wez_config"

    # Check for ~/.wezterm.lua conflict (has higher priority than $wez_config)
    local legacy="$HOME/.wezterm.lua"
    if [ -f "$legacy" ] || [ -L "$legacy" ]; then
        if [ -L "$legacy" ] && [ "$(readlink "$legacy")" = "$wez_config" ]; then
            : # Already a symlink to our config — all good
        else
            log_warning "$(msg "wezterm_legacy_conflict")"

            if is_dry_run; then
                log_dry "$(msg "dry_wezterm_legacy_resolve")"
                return 0
            fi

            if [ "$SILENT" = true ]; then
                rm -f "$legacy"
                log_info "$(msg "wezterm_legacy_removed")"
            else
                echo ""
                echo "1) $(msg "wezterm_legacy_remove")"
                echo "2) $(msg "wezterm_legacy_symlink")"
                echo "3) $(msg "wezterm_legacy_skip")"
                read -r choice
                case $choice in
                    1|remove)
                        rm -f "$legacy"
                        log_success "$(msg "wezterm_legacy_removed")"
                        ;;
                    2|symlink)
                        ln -sf "$wez_config" "$legacy"
                        log_success "$(msg "wezterm_legacy_symlinked")"
                        ;;
                    *)
                        log_info "$(msg "wezterm_legacy_skipped")"
                        ;;
                esac
            fi
        fi
    fi
}

# Configure default terminal
configure_default_terminal() {
    if ! command -v wezterm &>/dev/null; then
        return 0
    fi

    echo -e "\n$(msg "default_terminal_title")"
    msg "default_terminal_explain"
    echo ""

    if ! ask_confirm "$(msg "ask_default_terminal")"; then
        log_info "$(msg "skip_default_terminal")"
        return 0
    fi

    case "$OS" in
        linux)
            if is_dry_run; then
                log_dry "$(msg "dry_default_terminal_register")"
                log_dry "$(msg "dry_xdg_terminals")"
                log_dry "$(msg "dry_terminal_export")"
                return 0
            fi

            if command -v update-alternatives &>/dev/null; then
                local wez_path
                wez_path=$(command -v wezterm)
                log_info "$(msg "setting_default_emulator")"
                sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$wez_path" 50 || log_warning "$(msg "update_alternatives_register_failed")"
                sudo update-alternatives --set x-terminal-emulator "$wez_path" || log_warning "$(msg "update_alternatives_set_failed")"
                log_success "$(msg "default_terminal_success")"
            else
                log_info "$(msg "no_update_alternatives")"
            fi

            # Set XDG terminal configurations
            local xdg_files=("$HOME/.config/xdg-terminals.list" "$HOME/.config/ubuntu-xdg-terminals.list")
            for xdg_file in "${xdg_files[@]}"; do
                mkdir -p "$(dirname "$xdg_file")"
                echo "org.wezfurlong.wezterm.desktop" > "$xdg_file"
                log_success "$(msg "updated_xdg_terminals") $xdg_file"
            done

            # Set TERMINAL env var without duplication
            local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
            for s_conf in "${shell_configs[@]}"; do
                if [ -f "$s_conf" ]; then
            if ! grep -q "export TERMINAL=" "$s_conf"; then
                    log_info "$(msg "exporting_env") -> $s_conf"
                    echo -e "\n# OpenCode\nexport TERMINAL=wezterm\nexport OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true" >> "$s_conf"
                elif ! grep -q "export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=" "$s_conf"; then
                    echo -e "\nexport OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true" >> "$s_conf"
                fi
                fi
            done
            ;;
        macos)
            msg "macos_default_instruction"
            ;;
    esac
}

# Create Desktop Shortcut (Linux only)
create_desktop_shortcut() {
    if [ "$OS" = "linux" ] && [ -d "$HOME/Desktop" ]; then
        if ask_confirm "$(msg "ask_desktop_shortcut")" "Y"; then
            if is_dry_run; then
                log_dry "$(msg "dry_desktop_shortcut") $HOME/Desktop/OpenCode.desktop"
                return 0
            fi
            local desktop_file="$HOME/Desktop/OpenCode.desktop"
            cat << EOF > "$desktop_file"
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenCode AI
Comment=Launch OpenCode inside WezTerm
Exec=wezterm start -- bash -l -c "opencode -m opencode/deepseek-v4-flash-free"
Icon=org.wezfurlong.wezterm
Terminal=false
Categories=Utility;Development;
EOF
            chmod +x "$desktop_file"
            log_success "$(msg "desktop_shortcut_success")"
        fi
    fi
}

# Verify setup
verify_setup() {
    # Enable pre-push hook (full Docker tests before push to main)
    if [ -f "$(dirname "$0")/.githooks/pre-push" ]; then
        git config core.hooksPath "$(cd "$(dirname "$0")/.githooks" && pwd)" 2>/dev/null || true
    fi

    echo -e "\n${MAGENTA}${BOLD}================================================================${NC}"
    log_info "$(msg "verifying")"

    local all_ok=true

    if command -v wezterm &>/dev/null; then
        log_success "$(msg "verify_wezterm") $(wezterm --version | head -n 1)"
    else
        log_error "$(msg "wezterm_missing_path")"
        all_ok=false
    fi

    if command -v opencode &>/dev/null; then
        log_success "$(msg "verify_opencode") $(opencode --version)"
        log_info "$(msg "active_mcp_servers")"
        opencode mcp list || log_warning "$(msg "mcp_status_failed")"
    else
        log_error "$(msg "opencode_missing_path")"
        all_ok=false
    fi

    if [ "$all_ok" = true ]; then
        echo -e "\n${GREEN}${BOLD}$(msg "verification_passed")${NC}"
        echo -e "${YELLOW}$(msg "verification_tip")${NC}"
    else
        log_warning "$(msg "verification_failed")"
    fi

    if is_dry_run; then
        echo -e "\n${YELLOW}${BOLD}══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}${BOLD}  $(msg "dry_run_complete")${NC}"
        echo -e "${YELLOW}${BOLD}  $(msg "dry_run_apply")${NC}"
        echo -e "${YELLOW}${BOLD}══════════════════════════════════════════════════════════${NC}"
    fi
    echo -e "${MAGENTA}${BOLD}================================================================${NC}"
}

# Main
main() {
    generate_backup_id   # generate session BACKUP_ID once, before anything else
    migrate_plugin_names # auto-migrate oh-my-opencode → oh-my-openagent if needed

    case "$COMMAND" in
        reset)
            select_language
            reset_config
            ;;
        create-backup)
            create_backup
            ;;
        restore-backup)
            restore_backup
            ;;
        remove-backups)
            remove_backups
            ;;
        list-backups)
            if list_backups; then
                echo -e "\n${BOLD}$(msg "list_total")${NC} $BACKUPS_COUNT $(msg "list_backups_label")"
                local total_size
                total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "?")
                echo -e "${BOLD}$(msg "list_size")${NC} ~${total_size}"
            else
                log_warning "$(msg "no_backups_found")"
            fi
            ;;
        setup)
            bash "$(dirname "$0")/scripts/generate-dev-docs.sh" 2>/dev/null || true
            select_language
            show_onboarding
            detect_os
            select_preset
            install_wezterm
            install_nodejs
            install_opencode
            install_plugins
            configure_opencode
            install_nerd_font
            [[ "$PRESET" == "$PRESET_DEVELOPER" ]] && install_gitui
            configure_wezterm
            [[ "$PRESET" == "$PRESET_DEVELOPER" ]] && bash "$(dirname "$0")/scripts/generate-dev-docs.sh"
            configure_default_terminal
            create_desktop_shortcut
            verify_setup
            ;;
    esac
}

main
