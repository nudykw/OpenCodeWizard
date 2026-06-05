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
NC='\033[0;37m' # No Color
BOLD='\033[1m'

# ==============================================================================
# USER-CONFIGURABLE: Plugins & MCP Servers
# Add, remove, or comment out entries to customise your setup.
# Plugin format : "package-name|Description shown in wizard"
# MCP format    : "name|Description|npx -y package [extra-args]"
# ==============================================================================

OPENCODE_PLUGINS=(
    "oh-my-openagent|Session management and advanced CLI commands"
    "opencode-mem|Vector and long-term memory for the assistant"
    "@different-ai/opencode-browser|Integration with a real web browser"
    "@tarquinen/opencode-smart-title|Smart auto-naming of active sessions"
    "opencode-token-speed-plugin|Real-time speed indicator (Tokens Per Second)"
)

OPENCODE_MCP_SERVERS=(
    "fetch|Fast web page text retrieval without loading a browser|npx -y mcp-server-fetch-typescript"
    "puppeteer|Browser automation: screenshots and clicking elements|npx -y @modelcontextprotocol/server-puppeteer"
    "postgres|Integration with local gpt_chat_bot database|npx -y @modelcontextprotocol/server-postgres postgresql://postgres:postgres@localhost:5432/gpt_chat_bot"
    "context7|Access real-time version-specific library documentation|npx -y @upstash/context7-mcp"
)

# ==============================================================================
# Global state
# ==============================================================================
LANG_CODE="en"
SILENT=false
COMMAND="setup"   # setup | reset | create-backup | restore-backup | remove-backups
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
    echo -e "  --remove-backups                 Delete ALL saved backups (with confirmation)."
    echo -e "                                   Видалити всі резервні копії"
    echo -e ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  -y, --silent, --non-interactive  Run setup automatically with default options"
    echo -e "                                   Запустити встановлення автоматично"
    echo -e "  -h, --help                       Show this help message"
    echo -e "                                   Показати це повідомлення допомоги"
    echo -e ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  $0                               # interactive wizard"
    echo -e "  $0 --silent                      # auto setup"
    echo -e "  $0 --create-backup               # snapshot configs now"
    echo -e "  $0 --restore-backup              # pick and restore a backup"
    echo -e "  $0 --reset                       # wipe wizard-managed configs"
    echo -e "  $0 --remove-backups              # delete all backups"
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
        -y|--silent|--non-interactive)
            SILENT=true ;;
        -h|--help)
            show_help ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
    shift
done


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
                "ask_opencode") echo "Встановити OpenCode CLI?" ;;
                "opencode_exists") echo "OpenCode вже встановлено:" ;;
                "skip_opencode") echo "Пропуск встановлення OpenCode." ;;
                "checking_npm") echo "Перевірка Node.js та npm..." ;;
                "npm_missing") echo "Для встановлення OpenCode потрібен NPM. Будь ласка, встановіть Node.js/NPM." ;;
                "installing_opencode_global") echo "Встановлення opencode-ai глобально..." ;;
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
                "ask_opencode") echo "Install OpenCode CLI?" ;;
                "opencode_exists") echo "OpenCode is already installed:" ;;
                "skip_opencode") echo "Skipping OpenCode installation." ;;
                "checking_npm") echo "Checking Node.js & npm..." ;;
                "npm_missing") echo "NPM is required to install OpenCode. Please install Node.js/NPM first." ;;
                "installing_opencode_global") echo "Installing opencode-ai globally..." ;;
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

restore_backup() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        log_warning "$(msg "no_backups_found")"
        return 0
    fi

    echo -e "\n${BOLD}Available backups:${NC}"
    local backups=()
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
        backups+=("$dir")
        i=$((i+1))
    done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    echo ""
    read -rp "$(msg "select_backup") " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#backups[@]}" ]; then
        log_error "Invalid choice. Aborting."
        return 1
    fi

    local selected="${backups[$((choice-1))]}"
    echo -e "\nFiles in this backup:"
    find "$selected" -maxdepth 1 -type f ! -name 'manifest.txt' -printf '  %f\n'
    echo ""

    if ! ask_confirm "$(msg "restore_confirm")"; then
        log_info "Restore cancelled."
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
    echo -e "\nFound ${BOLD}${count}${NC} backup(s), ~${size} total."

    if ! ask_confirm "$(msg "remove_backups_confirm")"; then
        log_info "Cancelled."
        return 0
    fi

    rm -rf "$BACKUP_DIR"
    log_success "$(msg "remove_backups_success")"
}

reset_config() {
    log_info "Creating backup before reset..."
    create_backup

    local opencode_cfg="$HOME/.config/opencode/opencode.jsonc"
    local sysinfo="$HOME/.config/opencode/system_info.md"
    local wez_cfg="$HOME/.config/wezterm/wezterm.lua"
    local desktop="$HOME/Desktop/OpenCode.desktop"

    [ -f "$opencode_cfg" ] && { rm -f "$opencode_cfg"; log_info "Removed: $opencode_cfg"; }
    [ -f "$sysinfo" ]      && { rm -f "$sysinfo";      log_info "Removed: $sysinfo"; }
    [ -f "$wez_cfg" ]      && { rm -f "$wez_cfg";       log_info "Removed: $wez_cfg"; }
    [ -f "$desktop" ]      && { rm -f "$desktop";       log_info "Removed: $desktop"; }

    # Remove shell exports only if we previously backed up that file
    local dest="$BACKUP_DIR/$BACKUP_ID"
    for shell_file in ".bashrc" ".zshrc"; do
        local backup_name="${shell_file//./}"  # .bashrc -> bashrc
        if [ -f "$dest/$backup_name" ]; then
            local full_path="$HOME/$shell_file"
            if [ -f "$full_path" ] && grep -q "export TERMINAL=wezterm" "$full_path"; then
                sed -i '/^# OpenCode default terminal$/d' "$full_path"
                sed -i '/^export TERMINAL=wezterm$/d' "$full_path"
                log_info "Removed TERMINAL export from $full_path"
            fi
        fi
    done

    # Remove plugins
    if command -v opencode &>/dev/null; then
        for entry in "${OPENCODE_PLUGINS[@]}"; do
            local plugin_name="${entry%%|*}"
            log_info "Removing plugin: $plugin_name"
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
        create_backup
        sed -i 's/oh-my-opencode/oh-my-openagent/g' "$config"
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
        json="${json}\"${arg}\""
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
                    sudo apt install -y wezterm xclip wl-clipboard fonts-jetbrains-mono
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

    log_info "$(msg "checking_npm")"
    if ! command -v npm &>/dev/null; then
        log_error "$(msg "npm_missing")"
        exit 1
    fi

    local npm_prefix
    npm_prefix=$(npm config get prefix)
    if [ -w "$npm_prefix" ]; then
        log_info "$(msg "installing_opencode_global")"
        npm install -g opencode-ai@latest
    else
        log_info "$(msg "installing_opencode_global") (sudo)"
        sudo npm install -g opencode-ai@latest
    fi

    log_success "$(msg "opencode_success")"
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

    local install_all=true
    if ! ask_confirm "$(msg "ask_plugins_default")"; then
        install_all=false
    fi

    for entry in "${OPENCODE_PLUGINS[@]}"; do
        local plugin_name="${entry%%|*}"
        local plugin_desc="${entry#*|}"

        local should_install=true
        if [ "$install_all" = false ]; then
            echo -e "\n--> ${BOLD}${plugin_name}${NC}"
            echo "    $plugin_desc"
            if ! ask_confirm "$(msg "ask_plugin_install") ${plugin_name}?"; then
                should_install=false
            fi
        fi

        if [ "$should_install" = true ]; then
            log_info "$(msg "installing_plugin") ${plugin_name}..."
            opencode plugin "${plugin_name}" --global || log_warning "Failed to install ${plugin_name} or already installed."
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

        local should_enable=true
        if [ "$use_all_mcp" = false ]; then
            echo -e "\n--> ${BOLD}${mcp_name}${NC}"
            echo "    $mcp_desc"
            if ! ask_confirm "$(msg "ask_mcp_install") ${mcp_name}?"; then
                should_enable=false
            fi
        fi

        if [ "$should_enable" = true ]; then
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

    # Build plugin JSON array from OPENCODE_PLUGINS
    local plugin_json=""
    local first_plugin=true
    for entry in "${OPENCODE_PLUGINS[@]}"; do
        local pname="${entry%%|*}"
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
}


# WezTerm Lua configuration
configure_wezterm() {
    if ! ask_confirm "$(msg "ask_wezterm_config")"; then
        log_info "$(msg "skip_wezterm_config")"
        return 0
    fi

    local wez_dir="$HOME/.config/wezterm"
    mkdir -p "$wez_dir"
    local wez_config="$wez_dir/wezterm.lua"

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
config.font = wezterm.font 'JetBrains Mono'
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
  -- Split pane vertically and launch OpenCode with deepseek-v4-flash-free
  {
    key = 'O',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitPane {
      direction = 'Right',
      size = { Percent = 40 },
      command = { args = { os.getenv("SHELL") or "bash", "-l", "-i", "-c", "opencode -m opencode/deepseek-v4-flash-free" } },
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
            if command -v update-alternatives &>/dev/null; then
                local wez_path
                wez_path=$(command -v wezterm)
                log_info "$(msg "setting_default_emulator")"
                sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$wez_path" 50 || log_warning "Failed to register WezTerm in update-alternatives"
                sudo update-alternatives --set x-terminal-emulator "$wez_path" || log_warning "Failed to set default x-terminal-emulator"
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
                        echo -e "\n# OpenCode default terminal\nexport TERMINAL=wezterm" >> "$s_conf"
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
    echo -e "\n${MAGENTA}${BOLD}================================================================${NC}"
    log_info "$(msg "verifying")"

    local all_ok=true

    if command -v wezterm &>/dev/null; then
        log_success "WezTerm: $(wezterm --version | head -n 1)"
    else
        log_error "$(msg "wezterm_missing_path")"
        all_ok=false
    fi

    if command -v opencode &>/dev/null; then
        log_success "OpenCode: $(opencode --version)"
        log_info "Active MCP Servers:"
        opencode mcp list || log_warning "Could not retrieve MCP status."
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
        setup)
            select_language
            show_onboarding
            detect_os
            install_wezterm
            install_opencode
            install_plugins
            configure_opencode
            configure_wezterm
            configure_default_terminal
            create_desktop_shortcut
            verify_setup
            ;;
    esac
}

main
