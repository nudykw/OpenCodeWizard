<#
.SYNOPSIS
    OpenCode & WezTerm Setup Wizard.
    Майстер встановлення OpenCode та WezTerm.
.DESCRIPTION
    Automates the installation and configuration of WezTerm and OpenCode local AI workspace on Windows.
    Автоматизує встановлення та налаштування WezTerm та локального робочого середовища OpenCode на Windows.
.PARAMETER Silent
    Runs the installation automatically using default settings without prompting.
    Запускає встановлення автоматично з типовими налаштуваннями без додаткових запитів.
.PARAMETER Lang
    Sets the default interface language (e.g. "en" or "uk").
    Встановлює типову мову інтерфейсу (наприклад, "en" або "uk").
.PARAMETER DryRun
    Simulate the setup without making any changes (safe to run on any system).
    Симуляція встановлення без жодних змін (безпечно для будь-якої системи).
.PARAMETER ListBackups
    List all saved backups without entering the restore flow.
    Показати всі збережені резервні копії без входу в режим відновлення.
.EXAMPLE
    .\OpenCodeWizard.ps1 -Silent
.EXAMPLE
    .\OpenCodeWizard.ps1 -Lang "uk"
#>
param (
    [switch]$Silent,
    [string]$Preset,
    [string]$Lang = "en",
    [switch]$ResetColor,
    [switch]$CreateBackup,
    [switch]$RestoreBackup,
    [switch]$RemoveBackups,
    [switch]$ListBackups,
    [switch]$DryRun
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Colors for terminal
$Magenta = [char]27 + "[1;35m"
$Cyan = [char]27 + "[1;36m"
$Green = [char]27 + "[1;32m"
$Yellow = [char]27 + "[1;33m"
$Red = [char]27 + "[1;31m"
$Blue = [char]27 + "[1;34m"
$ResetColorColor = [char]27 + "[0m"
$Bold = [char]27 + "[1m"

# Default Language Code
$LangCode = "en"

# Preset selection (developer, standard, minimal)
# Must stay consistent with config/variables.conf
$PresetDeveloper = "developer"
$PresetStandard = "standard"
$PresetMinimal = "minimal"

if ($Silent -and $Preset -in @($PresetDeveloper, $PresetStandard, $PresetMinimal)) {
    $global:Preset = $Preset
} else {
    $global:Preset = $PresetDeveloper
}

# Backup State
$global:BackupDir = "$HOME\.local\share\opencodeWizard\backups"
$global:BackupId = ""

# Load central configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$ScriptDir\config\plugins.conf") {
    $OpencodePlugins = Get-Content "$ScriptDir\config\plugins.conf" | Where-Object { $_ -match '\|' -and $_ -notmatch '^#' }
}
if (Test-Path "$ScriptDir\config\mcp.conf") {
    $OpencodeMcpServers = Get-Content "$ScriptDir\config\mcp.conf" | Where-Object { $_ -match '\|' -and $_ -notmatch '^#' }
}

# ==============================================================================
# Preset definitions (must match config/variables.conf)
$PresetDeveloperPlugins  = @("oh-my-openagent", "opencode-mem", "@different-ai/opencode-browser", "@tarquinen/opencode-smart-title", "opencode-token-speed-plugin", "opencode-codebase-index")
$PresetStandardPlugins = @("oh-my-openagent", "opencode-token-speed-plugin", "opencode-codebase-index")
$PresetMinimalPlugins  = @("oh-my-openagent")

$PresetDeveloperMcps  = @("fetch", "puppeteer", "postgres", "context7", "codegraph", "docs-mcp", "lsp-mcp")
$PresetStandardMcps = @("fetch", "docs-mcp")
$PresetMinimalMcps  = @("fetch")


# Translations Dictionary
$Translations = @{
    "uk" = @{
        "title" = "ВСТАНОВЛЕННЯ OPENCODE ТА WEZTERM"
        "intro_text" = "Привіт! Цей скрипт допоможе налаштувати середовище штучного інтелекту.`n`nOpenCode — це ваш персональний локальний ШІ-помічник, який допомагає писати тексти, код, аналізувати файли та автоматизувати рутину.`nWezTerm — це сучасний, дуже швидкий (на Rust та GPU) термінал, який підтримує графіку та зручний розділений екран.`n`nНе бійтеся чорного вікна консолі! Ми зробимо його красивим і зручним. Робота в ньому набагато простіша, ніж здається. Ви швидко звикнете, а ШІ завжди буде поруч, щоб допомогти!"
        "ask_wezterm" = "Встановити WezTerm за допомогою winget?"
        "wezterm_exists" = "WezTerm вже встановлено:"
        "skip_wezterm" = "Пропуск встановлення WezTerm."
        "installing_wezterm" = "Встановлення WezTerm через winget..."
        "wezterm_success" = "WezTerm успішно встановлено! Перезапустіть консоль, щоб застосувати зміни."
        "wezterm_failed" = "Не вдалося встановити WezTerm через winget."
        "node_explain" = "Node.js та npm потрібні для повноцінної роботи OpenCodeWizard:`n  • Встановлення OpenCode CLI (пакет opencode-ai)`n  • Запуск MCP-серверів (fetch, puppeteer, context7, postgres тощо) через npx`n  • Частина плагінів OpenCode`nБез npm OpenCode можна встановити іншим способом, але MCP-сервери не працюватимуть."
        "ask_node" = "Встановити Node.js LTS та npm через winget?"
        "node_exists" = "Node.js та npm вже встановлено."
        "node_skip_warning" = "Node.js/npm не встановлено. OpenCode буде встановлено альтернативним способом, MCP-сервери можуть не працювати."
        "installing_node" = "Встановлення Node.js та npm..."
        "installing_node_winget" = "Встановлення Node.js через winget..."
        "installing_node_scoop" = "Встановлення Node.js через scoop..."
        "installing_node_choco" = "Встановлення Node.js через Chocolatey..."
        "dry_install_node_windows" = "Встановить Node.js через winget, scoop або Chocolatey"
        "node_install_failed" = "Не вдалося встановити Node.js/npm жодним із доступних способів."
        "node_manual" = "Будь ласка, встановіть Node.js вручну: https://nodejs.org/ , потім запустіть майстер знову."
        "node_success" = "Node.js успішно встановлено! Обов'язково перезапустіть термінал, щоб npm з'явився в PATH."
        "ask_opencode" = "Встановити OpenCode CLI?"
        "opencode_exists" = "OpenCode вже встановлено:"
        "skip_opencode" = "Пропуск встановлення OpenCode."
        "installing_opencode" = "Встановлення OpenCode..."
        "installing_opencode_script" = "Встановлення OpenCode через офіційний скрипт..."
        "installing_opencode_winget" = "Встановлення OpenCode через winget..."
        "installing_opencode_scoop" = "Встановлення OpenCode через scoop..."
        "installing_opencode_npm" = "Встановлення opencode-ai через npm..."
        "installing_opencode_direct" = "Завантаження OpenCode з GitHub..."
        "opencode_script_failed" = "Офіційний скрипт не вдався, пробую інший спосіб..."
        "opencode_success" = "OpenCode CLI успішно встановлено!"
        "opencode_failed" = "Не вдалося встановити OpenCode жодним із доступних способів."
        "opencode_manual" = "Встановіть вручну: curl -fsSL https://opencode.ai/install | bash"
        "ask_plugins" = "Налаштувати плагіни для OpenCode?"
        "skip_plugins" = "Пропуск налаштування плагінів."
        "ask_plugins_default" = "Встановити всі рекомендовані плагіни за замовчуванням?"
        "installing_plugin" = "Встановлення плагіна:"
        "plugins_success" = "Налаштування плагінів завершено."
        "plugin_oh_my_desc" = "oh-my-opencode (Керування сесіями та додаткові команди)"
        "plugin_mem_desc" = "opencode-mem (Векторна та довгострокова пам'ять асистента)"
        "plugin_browser_desc" = "@different-ai/opencode-browser (Інтеграція з реальним браузером)"
        "plugin_title_desc" = "@tarquinen/opencode-smart-title (Розумне авто-найменування сесій)"
        "plugin_speed_desc" = "opencode-token-speed-plugin (Відображення швидкості генерації токенів, TPS)"
        "ask_plugin_install" = "Встановити плагін"
        "ask_mcp" = "Налаштувати MCP-сервери?"
        "skip_mcp" = "Пропуск налаштування MCP-серверів."
        "ask_mcp_default" = "Увімкнути всі рекомендовані MCP-сервери за замовчуванням?"
        "mcp_fetch_desc" = "fetch (Швидке зчитування тексту з сайтів без запуску браузера)"
        "mcp_puppeteer_desc" = "puppeteer (Автоматизація браузера: скріншоти, кліки на сайтах)"
        "mcp_postgres_desc" = "postgres (Робота з локальною базою даних gpt_chat_bot)"
        "mcp_context7_desc" = "context7 (Робота з актуальною та версійною документацією бібліотек)"
        "ask_mcp_install" = "Увімкнути MCP-сервер"
        "backup_created" = "Створено резервну копію конфігурації:"
        "opencode_config_updated" = "Конфігурація OpenCode оновлена в"
        "ask_wezterm_config" = "Налаштувати зовнішній вигляд та гарячі клавіші WezTerm?"
        "skip_wezterm_config" = "Пропуск налаштування WezTerm."
        "wezterm_config_saved" = "Конфігурація WezTerm збережена в"
        "default_terminal_explain" = "Щоб зробити WezTerm терміналом за замовчуванням в Windows 11:`n  1. Відкрийте Windows Terminal (або Параметри -> Система -> Для розробників).`n  2. Перейдіть до розділу 'Запуск' (Startup).`n  3. Встановіть 'Термінальний додаток за замовчуванням' на 'WezTerm'."
        "verifying" = "Перевірка встановленого ПЗ..."
        "wezterm_missing_path" = "WezTerm НЕ знайдено в PATH."
        "opencode_missing_path" = "OpenCode CLI НЕ знайдено в PATH."
        "verification_passed" = "✔ ВСІ ПЕРЕВІРКИ ПРОЙДЕНО! Налаштування успішно завершено."
        "verification_tip" = "Порада: Запустіть 'wezterm' та натисніть 'CTRL + SHIFT + O', щоб відкрити OpenCode у розділеному екрані!"
        "verification_failed" = "Деякі компоненти відсутні. Будь ласка, перевірте помилки вище."
        "ask_desktop_shortcut" = "Створити ярлик швидкого запуску OpenCode в WezTerm на Робочому столі?"
        "desktop_shortcut_success" = "Ярлик на Робочому столі успішно створено!"
        "ask_context_menu" = "Додати 'Open in OpenCode' до контекстного меню папок у Провіднику? Це запускає WezTerm з OpenCode одразу в обраній папці."
        "context_menu_success" = "Пункт контекстного меню додано."
        "context_menu_failed" = "Не вдалося додати пункт контекстного меню:"
        "dry_context_menu" = "Додасть 'Open in OpenCode' до контекстного меню папок (реєстр)"
        "context_menu_text" = "Відкрити в OpenCode"
        "shortcut_intro" = "Тепер можна додати швидкі запуски. Спочатку — ярлик на робочому столі, потім — контекстне меню для папок. Якщо це не потрібно — просто відмовтеся на кожному кроці."
        "preset_label" = "Обраний пресет:"
        "dry_backup_create" = "Створить бекап у"
        "invalid_choice_abort" = "Невірний вибір. Скасовано."
        "restore_cancelled" = "Відновлення скасовано."
        "backup_files_header" = "Файли в цьому бекапі:"
        "restore_select_backup" = "Оберіть бекап для відновлення"
        "restore_confirm_overwrite" = "Відновити цей бекап? Поточна конфігурація буде перезаписана!"
        "cancelled" = "Скасовано."
        "backups_found_count" = "Знайдено"
        "list_backups_label" = "бекапів"
        "remove_backups_confirm_permanent" = "Назавжди видалити всі бекапи?"
        "dry_delete_backups" = "Видалить ВСІ бекапи в"
        "all_backups_removed" = "Всі резервні копії видалено."
        "no_backups_in_dir" = "Резервних копій не знайдено в"
        "no_backups_found_short" = "Резервних копій не знайдено."
        "backup_before_reset" = "Створення бекапу перед скиданням..."
        "dry_reset_remove_configs" = "Видалить: opencode.jsonc, system_info.md, wezterm.lua, OpenCode AI.lnk"
        "dry_reset_remove_plugins" = "Видалить плагіни OpenCode"
        "removed_file" = "Видалено:"
        "removing_plugin" = "Видалення плагіна:"
        "reset_done_config" = "Конфігурацію скинуто до типових налаштувань."
        "migrate_plugin_done" = "Міграцію завершено."
        "dry_migrate_plugin" = "Мігрує oh-my-opencode → oh-my-openagent у"
        "dry_wezterm_winget" = "Виконає: winget install --id wez.wezterm"
        "go_already_installed" = "Go вже встановлено:"
        "go_version_old" = "Версія Go застаріла — потрібна 1.22+."
        "dry_install_go_windows" = "Встановить Go для Windows"
        "go_installing_winget" = "Встановлення Go через winget..."
        "go_installed_winget" = "Go встановлено! Перезапустіть термінал після налаштування, щоб оновити PATH."
        "go_winget_failed" = "Не вдалося встановити Go через winget."
        "gomcp_already_installed" = "go-docs-mcp вже встановлено."
        "gomcp_go_required" = "Go не в PATH. Спочатку встановіть Go."
        "dry_install_gomcp" = "Виконає: go install github.com/drolosoft/go-docs-mcp@v1.1.0"
        "gomcp_installing" = "Встановлення go-docs-mcp через Go..."
        "gomcp_installed" = "go-docs-mcp успішно встановлено."
        "gomcp_failed" = "go-docs-mcp не знайдено після встановлення."
        "dry_install_opencode" = "Встановить OpenCode через офіційний скрипт, winget, scoop, пряме завантаження або npm"
        "dry_install_plugin" = "Встановить плагін:"
        "dry_write_system_info" = "Запише system_info.md у"
        "dry_write_opencode_config" = "Запише opencode.jsonc у"
        "dry_plugins_list" = "Плагіни:"
        "dry_mcp_configured" = "MCP-сервери: згідно з вашим вибором"
        "dry_wezterm_dir" = "Створить директорію:"
        "dry_wezterm_config" = "Запише конфігурацію WezTerm у"
        "verify_wezterm" = "WezTerm:"
        "verify_opencode" = "OpenCode:"
        "active_mcp_servers" = "Активні MCP-сервери:"
        "dry_desktop_shortcut" = "Створить ярлик на робочому столі:"
        "desktop_shortcut_failed" = "Не вдалося створити ярлик на робочому столі:"
        "dry_run_complete" = "DRY-RUN ЗАВЕРШЕНО — жодних змін у системі не внесено."
        "dry_run_apply" = "Запустіть без -DryRun, щоб застосувати зміни."
        "list_total" = "Всього:"
        "list_size" = "Розмір:"
        "restore_failed_generic" = "Помилка при відновленні."
        "restore_success_config" = "Конфігурацію успішно відновлено!"
        "unexpected_error" = "Сталася неочікувана помилка:"
        "select_lang_prompt" = "Оберіть мову інтерфейсу / Select wizard language:"
        "select_lang_en" = "1) English (en)"
        "select_lang_uk" = "2) Українська (uk)"
        "select_lang_choice" = "Вибір / Choice [1-2]"
        "select_preset_title" = "Оберіть пресет конфігурації:"
        "preset_developer" = "1) 🍔 Developer — все включено (рекомендовано)"
        "preset_standard" = "2) 🥪 Standard — основні плагіни + базові MCP (fetch, docs-mcp)"
        "preset_minimal" = "3) 🥗 Minimal — мінімальне налаштування"
        "preset_mcps_label" = "MCPs:"
        "preset_plugins_label" = "Plugins:"
        "preset_choice" = "Вибір [1-3] (за замовчуванням: 1)"
        "go_installing" = "Встановлення Go 1.24.0..."
        "go_manual" = "Будь ласка, встановіть Go вручну: https://go.dev/dl/ , потім запустіть майстер знову."
        "migrate_plugin" = "Виявлено застарілий плагін. Мігрую..."
        "nerdfont_exists" = "JetBrainsMono Nerd Font вже встановлено."
        "installing_nerdfont" = "Завантаження JetBrainsMono Nerd Font з GitHub..."
        "nerdfont_success" = "JetBrainsMono Nerd Font встановлено!"
        "nerdfont_failed" = "Не вдалося встановити JetBrainsMono Nerd Font"
        "dry_nerdfont" = "Завантажить та встановить JetBrainsMono Nerd Font"
        "gitui_exists" = "Gitui вже встановлено:" 
        "ask_gitui" = "Встановити Gitui (термінальний TUI для Git)?"
        "skip_gitui" = "Пропуск встановлення Gitui."
        "installing_gitui" = "Встановлення Gitui..."
        "gitui_success" = "Gitui успішно встановлено!"
        "gitui_manual" = "Будь ласка, встановіть Gitui вручну: https://github.com/extrawurst/gitui"
        "dry_install_gitui" = "Встановить Gitui за допомогою"
    }
    "en" = @{
        "title" = "OPENCODE & WEZTERM SETUP WIZARD"
        "intro_text" = "Hi! This script will help you set up an artificial intelligence environment.`n`nOpenCode is your personal local AI assistant that helps write texts, code, analyze files, and automate routine tasks.`nWezTerm is a modern, ultra-fast (Rust and GPU-based) terminal that supports inline graphics and split screens.`n`nDon't be afraid of the terminal window! We'll make it beautiful and easy to use. Working in it is much simpler than it looks. You'll get used to it quickly, and the AI will always be there to guide you!"
        "ask_wezterm" = "Install WezTerm using winget?"
        "wezterm_exists" = "WezTerm is already installed:"
        "skip_wezterm" = "Skipping WezTerm installation."
        "installing_wezterm" = "Installing WezTerm via winget..."
        "wezterm_success" = "WezTerm installed successfully! Restart your terminal to apply changes."
        "wezterm_failed" = "Failed to install WezTerm via winget."
        "node_explain" = "Node.js and npm are required for the full OpenCodeWizard experience:`n  • Installing the OpenCode CLI (opencode-ai package)`n  • Running MCP servers (fetch, puppeteer, context7, postgres, etc.) via npx`n  • Some OpenCode plugins`nWithout npm, OpenCode can still be installed another way, but MCP servers will not work."
        "ask_node" = "Install Node.js LTS and npm via winget?"
        "node_exists" = "Node.js & npm are already installed."
        "node_skip_warning" = "Node.js/npm not installed. OpenCode will be installed via an alternative method; MCP servers may not work."
        "installing_node" = "Installing Node.js & npm..."
        "installing_node_winget" = "Installing Node.js via winget..."
        "installing_node_scoop" = "Installing Node.js via scoop..."
        "installing_node_choco" = "Installing Node.js via Chocolatey..."
        "dry_install_node_windows" = "Would install Node.js via winget, scoop, or Chocolatey"
        "node_install_failed" = "Failed to install Node.js/npm using any available method."
        "node_manual" = "Please install Node.js manually from https://nodejs.org/ then re-run the wizard."
        "node_success" = "Node.js installed successfully! Make sure to restart the terminal for npm to appear in PATH."
        "ask_opencode" = "Install OpenCode CLI?"
        "opencode_exists" = "OpenCode is already installed:"
        "skip_opencode" = "Skipping OpenCode installation."
        "installing_opencode" = "Installing OpenCode..."
        "installing_opencode_script" = "Installing OpenCode via official install script..."
        "installing_opencode_winget" = "Installing OpenCode via winget..."
        "installing_opencode_scoop" = "Installing OpenCode via scoop..."
        "installing_opencode_npm" = "Installing opencode-ai via npm..."
        "installing_opencode_direct" = "Downloading OpenCode from GitHub..."
        "opencode_script_failed" = "Official install script failed, trying another method..."
        "opencode_success" = "OpenCode CLI installed successfully!"
        "opencode_failed" = "Failed to install OpenCode using any available method."
        "opencode_manual" = "Install manually: curl -fsSL https://opencode.ai/install | bash"
        "ask_plugins" = "Configure OpenCode plugins?"
        "skip_plugins" = "Skipping plugin setup."
        "ask_plugins_default" = "Install all recommended plugins by default?"
        "installing_plugin" = "Installing plugin:"
        "plugins_success" = "Plugins setup complete."
        "plugin_oh_my_desc" = "oh-my-opencode (Session management and advanced CLI commands)"
        "plugin_mem_desc" = "opencode-mem (Vector and long-term memory for the assistant)"
        "plugin_browser_desc" = "@different-ai/opencode-browser (Integration with a real web browser)"
        "plugin_title_desc" = "@tarquinen/opencode-smart-title (Smart auto-naming of active sessions)"
        "plugin_speed_desc" = "opencode-token-speed-plugin (Real-time speed indicator, Tokens Per Second)"
        "ask_plugin_install" = "Install plugin"
        "ask_mcp" = "Configure MCP servers?"
        "skip_mcp" = "Skipping MCP configuration."
        "ask_mcp_default" = "Enable all recommended MCP servers by default?"
        "mcp_fetch_desc" = "fetch (Fast retrieval of web page text content without loading GUI)"
        "mcp_puppeteer_desc" = "puppeteer (Browser automation: screenshots, clicking elements on sites)"
        "mcp_postgres_desc" = "postgres (Integration with local gpt_chat_bot database)"
        "mcp_context7_desc" = "context7 (Access real-time, version-specific package/library documentation)"
        "ask_mcp_install" = "Enable MCP server"
        "backup_created" = "Created backup of existing config:"
        "opencode_config_updated" = "OpenCode configuration updated in"
        "ask_wezterm_config" = "Configure WezTerm styling and hotkeys?"
        "skip_wezterm_config" = "Skipping WezTerm configuration."
        "wezterm_config_saved" = "WezTerm configuration saved at"
        "default_terminal_explain" = "To make WezTerm default on Windows 11:`n  1. Open Windows Terminal (or Settings -> System -> For Developers).`n  2. Go to Startup.`n  3. Set 'Default terminal application' to 'WezTerm'."
        "verifying" = "Verifying installed software..."
        "wezterm_missing_path" = "WezTerm is NOT found in PATH."
        "opencode_missing_path" = "OpenCode CLI is NOT found in PATH."
        "verification_passed" = "✔ ALL VERIFICATIONS PASSED! Setup is fully complete."
        "verification_tip" = "Tip: Launch 'wezterm' and press 'CTRL + SHIFT + O' to open OpenCode in a split pane!"
        "verification_failed" = "Some components are missing. Please review errors above."
        "ask_desktop_shortcut" = "Create a desktop shortcut to quickly launch OpenCode inside WezTerm?"
        "desktop_shortcut_success" = "Desktop shortcut created successfully!"
        "ask_context_menu" = "Add 'Open in OpenCode' to the folder right-click context menu in File Explorer? This launches WezTerm with OpenCode already running in the selected folder."
        "context_menu_success" = "Context menu entry added."
        "context_menu_failed" = "Could not add context menu entry:"
        "dry_context_menu" = "Would add 'Open in OpenCode' to folder context menu (registry)"
        "context_menu_text" = "Open in OpenCode"
        "shortcut_intro" = "Now you can add quick-launch shortcuts. First, a desktop shortcut — then a folder context menu. If you do not need these, just decline each prompt."
        "preset_label" = "Selected preset:"
        "dry_backup_create" = "Would create backup at"
        "invalid_choice_abort" = "Invalid choice. Aborting."
        "restore_cancelled" = "Restore cancelled."
        "backup_files_header" = "Files in this backup:"
        "restore_select_backup" = "Select backup to restore"
        "restore_confirm_overwrite" = "Are you sure you want to restore this backup? Current config will be overwritten!"
        "cancelled" = "Cancelled."
        "backups_found_count" = "Found"
        "list_backups_label" = "backup(s)"
        "remove_backups_confirm_permanent" = "Are you sure you want to permanently delete all backups?"
        "dry_delete_backups" = "Would delete ALL backups in"
        "all_backups_removed" = "All backups have been removed."
        "no_backups_in_dir" = "No backups found in"
        "no_backups_found_short" = "No backups found."
        "backup_before_reset" = "Creating backup before reset..."
        "dry_reset_remove_configs" = "Would remove: opencode.jsonc, system_info.md, wezterm.lua, OpenCode AI.lnk"
        "dry_reset_remove_plugins" = "Would remove OpenCode plugins"
        "removed_file" = "Removed:"
        "removing_plugin" = "Removing plugin:"
        "reset_done_config" = "Configuration reset to defaults."
        "migrate_plugin_done" = "Migration complete."
        "dry_migrate_plugin" = "Would migrate oh-my-opencode → oh-my-openagent in"
        "dry_wezterm_winget" = "Would run: winget install --id wez.wezterm"
        "go_already_installed" = "Go is already installed:"
        "go_version_old" = "Go version is too old — need 1.22+."
        "dry_install_go_windows" = "Would install Go for Windows"
        "go_installing_winget" = "Installing Go via winget..."
        "go_installed_winget" = "Go installed! Restart your terminal after setup to refresh PATH."
        "go_winget_failed" = "Failed to install Go via winget."
        "gomcp_already_installed" = "go-docs-mcp is already installed."
        "gomcp_go_required" = "Go is not in PATH. Run Install-Go first."
        "dry_install_gomcp" = "Would run: go install github.com/drolosoft/go-docs-mcp@v1.1.0"
        "gomcp_installing" = "Installing go-docs-mcp via Go..."
        "gomcp_installed" = "go-docs-mcp installed successfully."
        "gomcp_failed" = "go-docs-mcp not found after install."
        "dry_install_opencode" = "Would install OpenCode via official script, winget, scoop, direct download, or npm"
        "dry_install_plugin" = "Would install plugin:"
        "dry_write_system_info" = "Would write system_info.md to"
        "dry_write_opencode_config" = "Would write opencode.jsonc to"
        "dry_plugins_list" = "Plugins:"
        "dry_mcp_configured" = "MCP servers: configured based on your selections"
        "dry_wezterm_dir" = "Would create directory:"
        "dry_wezterm_config" = "Would write WezTerm config to"
        "verify_wezterm" = "WezTerm:"
        "verify_opencode" = "OpenCode:"
        "active_mcp_servers" = "Active MCP Servers:"
        "dry_desktop_shortcut" = "Would create desktop shortcut:"
        "desktop_shortcut_failed" = "Could not create desktop shortcut:"
        "dry_run_complete" = "DRY-RUN COMPLETE — No changes were made to your system."
        "dry_run_apply" = "Run without -DryRun to apply."
        "list_total" = "Total:"
        "list_size" = "Size:"
        "restore_failed_generic" = "Restore failed."
        "restore_success_config" = "Configuration successfully restored!"
        "unexpected_error" = "An unexpected error occurred:"
        "select_lang_prompt" = "Оберіть мову інтерфейсу / Select wizard language:"
        "select_lang_en" = "1) English (en)"
        "select_lang_uk" = "2) Українська (uk)"
        "select_lang_choice" = "Вибір / Choice [1-2]"
        "select_preset_title" = "Select configuration preset:"
        "preset_developer" = "1) 🍔 Developer — everything included (recommended)"
        "preset_standard" = "2) 🥪 Standard — essential plugins + core MCPs (fetch, docs-mcp)"
        "preset_minimal" = "3) 🥗 Minimal — minimal setup"
        "preset_mcps_label" = "MCPs:"
        "preset_plugins_label" = "Plugins:"
        "preset_choice" = "Choice [1-3] (default: 1)"
        "go_installing" = "Installing Go 1.24.0..."
        "go_manual" = "Please install Go manually from https://go.dev/dl/ then re-run the wizard."
        "migrate_plugin" = "Legacy plugin detected. Migrating..."
        "nerdfont_exists" = "JetBrainsMono Nerd Font already installed."
        "installing_nerdfont" = "Downloading JetBrainsMono Nerd Font from GitHub..."
        "nerdfont_success" = "JetBrainsMono Nerd Font installed!"
        "nerdfont_failed" = "Failed to install JetBrainsMono Nerd Font"
        "dry_nerdfont" = "Would download and install JetBrainsMono Nerd Font"
        "gitui_exists" = "Gitui is already installed:" 
        "ask_gitui" = "Install Gitui (terminal TUI for Git)?"
        "skip_gitui" = "Skipping Gitui installation."
        "installing_gitui" = "Installing Gitui..."
        "gitui_success" = "Gitui installed successfully!"
        "gitui_manual" = "Please install Gitui manually: https://github.com/extrawurst/gitui"
        "dry_install_gitui" = "Would install Gitui via"
    }
}

function Get-Msg ($key) {
    if ($Translations[$LangCode].ContainsKey($key)) {
        return $Translations[$LangCode][$key]
    }
    return $Translations["en"][$key]
}

# 1. Ask for Language Choice
if ($Silent) {
    if ($Lang -eq "uk") {
        $LangCode = "uk"
    } else {
        $LangCode = "en"
    }
} else {
    Write-Host "$(Get-Msg 'select_lang_prompt')"
    Write-Host "  $(Get-Msg 'select_lang_en')"
    Write-Host "  $(Get-Msg 'select_lang_uk')"
    $langChoice = Read-Host -Prompt "$(Get-Msg 'select_lang_choice')"
    if ($langChoice -eq "2") {
        $LangCode = "uk"
    } else {
        $LangCode = "en"
    }
}
Write-Host ""

function Is-InPreset ($name, $presetList) {
    return $presetList -contains $name
}

function Select-Preset {
    if ($Silent) { return }
    Write-Host "`n$Bold$(Get-Msg 'select_preset_title')$ResetColorColor"
    Write-Host "  $Bold$(Get-Msg 'preset_developer')$ResetColorColor"
    Write-Host "     $Cyan$(Get-Msg 'preset_mcps_label')$ResetColorColor fetch, puppeteer, postgres, context7, codegraph, docs-mcp, lsp-mcp"
    Write-Host "     $Cyan$(Get-Msg 'preset_plugins_label')$ResetColorColor oh-my-openagent, opencode-mem, @different-ai/opencode-browser, @tarquinen/opencode-smart-title, opencode-token-speed-plugin, opencode-codebase-index"
    Write-Host "  $Bold$(Get-Msg 'preset_standard')$ResetColorColor"
    Write-Host "     $Cyan$(Get-Msg 'preset_mcps_label')$ResetColorColor fetch, docs-mcp"
    Write-Host "  $Bold$(Get-Msg 'preset_minimal')$ResetColorColor"
    Write-Host "     $Cyan$(Get-Msg 'preset_mcps_label')$ResetColorColor fetch"
    $presetChoice = Read-Host "$(Get-Msg 'preset_choice')"
    switch ($presetChoice) {
        "2" { $global:Preset = $PresetStandard }
        "3" { $global:Preset = $PresetMinimal }
        default { $global:Preset = $PresetDeveloper }
    }
    Log-Info "$(Get-Msg 'preset_label') $($global:Preset)"
    Write-Host ""
}

function Ask-Confirm ($prompt) {
    if ($Silent) {
        return $true
    }
    while ($true) {
        $ans = Read-Host -Prompt "$Cyan$prompt [Y/n]$ResetColorColor"
        if ([string]::IsNullOrEmpty($ans)) { $ans = "y" }
        if ($ans -match '^[Yy]$') { return $true }
        if ($ans -match '^[Nn]$') { return $false }
    }
}

function Log-Info ($msg) { Write-Host "$Blue[INFO]$ResetColorColor $msg" }
function Log-Success ($msg) { Write-Host "$Green[SUCCESS]$ResetColorColor $msg" }
function Log-Warning ($msg) { Write-Host "$Yellow[WARNING]$ResetColorColor $msg" }
function Log-Error ($msg) { Write-Host "$Red[ERROR]$ResetColorColor $msg" }
function Log-Dry ($msg) { Write-Host "$Yellow[DRY-RUN]$ResetColorColor $msg" }

function Refresh-EnvPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Onboarding Show
Write-Host "$Magenta================================================================$ResetColorColor"
Write-Host "  $(Get-Msg 'title')"
Write-Host "$Magenta================================================================$ResetColorColor`n"
Write-Host "$(Get-Msg 'intro_text')"
Write-Host "`n$Magenta================================================================$ResetColorColor`n"

# ==============================================================================
# Backup system
# ==============================================================================
function Generate-BackupId {
    $hash = "local"
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $gitHash = git -C $PSScriptRoot rev-parse --short HEAD 2>$null
            if ($gitHash) { $hash = $gitHash }
        }
    } catch {}
    $dateStr = Get-Date -Format "yyyyMMdd-HHmmss"
    $global:BackupId = "ocw-$hash-$dateStr"
}

function Create-Backup {
    if ([string]::IsNullOrEmpty($global:BackupId)) { Generate-BackupId }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_backup_create') $(Join-Path $global:BackupDir $global:BackupId)"
        return
    }

    $dest = Join-Path $global:BackupDir $global:BackupId
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

    $backedUp = @()
    $opencodeCfg = "$HOME\.config\opencode\opencode.jsonc"
    $sysinfo = "$HOME\.config\opencode\system_info.md"
    $wezCfg = "$HOME\.config\wezterm\wezterm.lua"

    if (Test-Path $opencodeCfg) { Copy-Item $opencodeCfg -Destination "$dest\opencode.jsonc" -Force; $backedUp += "opencode.jsonc" }
    if (Test-Path $sysinfo) { Copy-Item $sysinfo -Destination "$dest\system_info.md" -Force; $backedUp += "system_info.md" }
    if (Test-Path $wezCfg) { Copy-Item $wezCfg -Destination "$dest\wezterm.lua" -Force; $backedUp += "wezterm.lua" }
    
    $profilePath = $PROFILE
    if (Test-Path $profilePath) { Copy-Item $profilePath -Destination "$dest\Microsoft.PowerShell_profile.ps1" -Force; $backedUp += "profile.ps1" }

    $manifest = @(
        "BACKUP_ID=$global:BackupId",
        "CREATED=$((Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz'))",
        "FILES=$($backedUp -join ' ')"
    )
    Set-Content -Path "$dest\manifest.txt" -Value $manifest -Encoding UTF8

    Log-Success "$(Get-Msg 'backup_created') $dest"
}

function List-Backups {
    if (-not (Test-Path $global:BackupDir) -or (Get-ChildItem $global:BackupDir -Directory).Count -eq 0) {
        return $null
    }

    $dirs = Get-ChildItem $global:BackupDir -Directory | Sort-Object Name
    $i = 1
    foreach ($d in $dirs) {
        $manifestPath = Join-Path $d.FullName "manifest.txt"
        $created = "unknown"
        $files = "no files"
        if (Test-Path $manifestPath) {
            $lines = Get-Content $manifestPath
            $createdLine = $lines | Where-Object { $_ -match "^CREATED=" }
            if ($createdLine) { $created = $createdLine.Split('=', 2)[1] }
            $filesLine = $lines | Where-Object { $_ -match "^FILES=" }
            if ($filesLine) { $files = $filesLine.Split('=', 2)[1] }
        }
        Write-Host "  $i) $($d.Name)  [$created]  ($files)"
        $i++
    }

    return $dirs
}

function Restore-Backup {
    $dirs = List-Backups
    if ($null -eq $dirs) {
        Log-Warning "$(Get-Msg 'no_backups_in_dir') $global:BackupDir"
        return
    }

    Write-Host ""
    $choice = Read-Host "$(Get-Msg 'restore_select_backup') [1-$($dirs.Count)]"
    $choiceInt = 0
    if (-not [int]::TryParse($choice, [ref]$choiceInt) -or $choiceInt -lt 1 -or $choiceInt -gt $dirs.Count) {
        Log-Error "$(Get-Msg 'invalid_choice_abort')"
        exit 1
    }

    $selected = $dirs[$choiceInt - 1].FullName
    Write-Host "`n$(Get-Msg 'backup_files_header')"
    Get-ChildItem $selected -File | Where-Object { $_.Name -ne "manifest.txt" } | ForEach-Object { Write-Host "  $($_.Name)" }
    Write-Host ""

    if (-not (Ask-Confirm "$(Get-Msg 'restore_confirm_overwrite')")) {
        Log-Info "$(Get-Msg 'restore_cancelled')"
        return
    }

    # Pre-restore backup
    $oldId = $global:BackupId
    Generate-BackupId
    $prerestoreDest = Join-Path $global:BackupDir $global:BackupId
    New-Item -ItemType Directory -Path $prerestoreDest -Force | Out-Null
    if (Test-Path "$HOME\.config\opencode\opencode.jsonc") { Copy-Item "$HOME\.config\opencode\opencode.jsonc" "$prerestoreDest\opencode.jsonc" -Force }
    if (Test-Path "$HOME\.config\opencode\system_info.md") { Copy-Item "$HOME\.config\opencode\system_info.md" "$prerestoreDest\system_info.md" -Force }
    if (Test-Path "$HOME\.config\wezterm\wezterm.lua") { Copy-Item "$HOME\.config\wezterm\wezterm.lua" "$prerestoreDest\wezterm.lua" -Force }
    Set-Content -Path "$prerestoreDest\manifest.txt" -Value @("BACKUP_ID=$global:BackupId", "NOTE=pre-restore snapshot") -Encoding UTF8
    $global:BackupId = $oldId

    # Apply
    $failed = $false
    try {
        if (Test-Path "$selected\opencode.jsonc") { 
            if (-not (Test-Path "$HOME\.config\opencode")) { New-Item -ItemType Directory -Path "$HOME\.config\opencode" -Force | Out-Null }
            Copy-Item "$selected\opencode.jsonc" "$HOME\.config\opencode\opencode.jsonc" -Force 
        }
        if (Test-Path "$selected\system_info.md") { 
            if (-not (Test-Path "$HOME\.config\opencode")) { New-Item -ItemType Directory -Path "$HOME\.config\opencode" -Force | Out-Null }
            Copy-Item "$selected\system_info.md" "$HOME\.config\opencode\system_info.md" -Force 
        }
        if (Test-Path "$selected\wezterm.lua") { 
            if (-not (Test-Path "$HOME\.config\wezterm")) { New-Item -ItemType Directory -Path "$HOME\.config\wezterm" -Force | Out-Null }
            Copy-Item "$selected\wezterm.lua" "$HOME\.config\wezterm\wezterm.lua" -Force 
        }
        if (Test-Path "$selected\Microsoft.PowerShell_profile.ps1") {
            $profDir = Split-Path $PROFILE
            if (-not (Test-Path $profDir)) { New-Item -ItemType Directory -Path $profDir -Force | Out-Null }
            Copy-Item "$selected\Microsoft.PowerShell_profile.ps1" $PROFILE -Force
        }
    } catch {
        $failed = $true
    }

    if ($failed) {
        Log-Error "$(Get-Msg 'restore_failed_generic')"
        exit 1
    }

    Log-Success "$(Get-Msg 'restore_success_config')"
}

function Remove-Backups {
    if (-not (Test-Path $global:BackupDir) -or (Get-ChildItem $global:BackupDir -Directory).Count -eq 0) {
        Log-Warning "$(Get-Msg 'no_backups_found_short')"
        return
    }

    $dirs = Get-ChildItem $global:BackupDir -Directory
    Write-Host "`n$(Get-Msg 'backups_found_count') $Bold$($dirs.Count)$ResetColorColor $(Get-Msg 'list_backups_label')."

    if (-not (Ask-Confirm "$(Get-Msg 'remove_backups_confirm_permanent')")) {
        Log-Info "$(Get-Msg 'cancelled')"
        return
    }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_delete_backups') $global:BackupDir"
        return
    }

    Remove-Item $global:BackupDir -Recurse -Force
    Log-Success "$(Get-Msg 'all_backups_removed')"
}

function Reset-Config {
    Log-Info "$(Get-Msg 'backup_before_reset')"
    Create-Backup

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_reset_remove_configs')"
        Log-Dry "$(Get-Msg 'dry_reset_remove_plugins')"
        return
    }

    $opencodeCfg = "$HOME\.config\opencode\opencode.jsonc"
    $sysinfo = "$HOME\.config\opencode\system_info.md"
    $wezCfg = "$HOME\.config\wezterm\wezterm.lua"
    $desktop = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), "OpenCode AI.lnk")

    if (Test-Path $opencodeCfg) { Remove-Item $opencodeCfg -Force; Log-Info "$(Get-Msg 'removed_file') $opencodeCfg" }
    if (Test-Path $sysinfo) { Remove-Item $sysinfo -Force; Log-Info "$(Get-Msg 'removed_file') $sysinfo" }
    if (Test-Path $wezCfg) { Remove-Item $wezCfg -Force; Log-Info "$(Get-Msg 'removed_file') $wezCfg" }
    if (Test-Path $desktop) { Remove-Item $desktop -Force; Log-Info "$(Get-Msg 'removed_file') $desktop" }

    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        foreach ($entry in $OpencodePlugins) {
            $pluginName = $entry.Split('|')[0]
            Log-Info "$(Get-Msg 'removing_plugin') $pluginName"
            try { opencode plugin remove $pluginName *>$null } catch {}
        }
    }

    Log-Success "$(Get-Msg 'reset_done_config')"
}

function Migrate-PluginNames {
    $config = "$HOME\.config\opencode\opencode.jsonc"
    if (Test-Path $config) {
        $content = Get-Content $config -Raw
        if ($content -match "oh-my-opencode") {
            Log-Warning "$(Get-Msg 'migrate_plugin')"
            if ($DryRun) {
                Log-Dry "$(Get-Msg 'dry_migrate_plugin') $config"
                return
            }
            Create-Backup
            $content = $content -replace "oh-my-opencode", "oh-my-openagent"
            Set-Content -Path $config -Value $content -Encoding UTF8
            if (Get-Command opencode -ErrorAction SilentlyContinue) {
                try { opencode plugin oh-my-openagent --global *>$null } catch {}
            }
            Log-Success "$(Get-Msg 'migrate_plugin_done')"
        }
    }
}

function Args-ToJsonArray {
    param([string]$ArgsStr)
    $argsArr = $ArgsStr -split '\s+'
    $json = "["
    $first = $true
    foreach ($arg in $argsArr) {
        if (-not $first) { $json += ", " }
        $json += "`"$arg`""
        $first = $false
    }
    $json += "]"
    return $json
}


# 0. Fix PowerShell Execution Policy (required for opencode.ps1)
function Set-OpenCodeExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy
    if ($currentPolicy -eq "Restricted") {
        Log-Info "PowerShell Execution Policy is 'Restricted'. Setting to 'RemoteSigned' for current user..."
        if ($DryRun) {
            Log-Dry "Would run: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"
        } else {
            try {
                Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
                Log-Success "Execution Policy set to RemoteSigned for CurrentUser."
                if ($Silent) {
                    # Refresh env for current session so that opencode.ps1 becomes available
                    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                }
            } catch {
                Log-Warning "Could not set Execution Policy: $_"
            }
        }
    } else {
        if (-not $Silent) {
            Log-Info "PowerShell Execution Policy is already '$currentPolicy' — no changes needed."
        }
    }
}


# 1. Install WezTerm
function Install-WezTerm {
    if (Get-Command wezterm -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'wezterm_exists') $(wezterm --version)"
        return
    }

    if (-not (Ask-Confirm "$(Get-Msg 'ask_wezterm')")) {
        Log-Info "$(Get-Msg 'skip_wezterm')"
        return
    }

    Log-Info "$(Get-Msg 'installing_wezterm')"

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_wezterm_winget')"
        return
    }

    winget install --id wez.wezterm --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$(Get-Msg 'wezterm_success')"
        Refresh-EnvPath
    } else {
        Log-Error "$(Get-Msg 'wezterm_failed')"
    }
}

# 1.4. JetBrainsMono Nerd Font (universal icon coverage, no mojibake)
function Install-NerdFont {
    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_nerdfont')"
        return
    }

    $fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

    # Check if already installed (internal font family name is "JetBrainsMono NFM")
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $installedFonts = New-Object System.Drawing.Text.InstalledFontCollection
    $alreadyInstalled = $installedFonts.Families | Where-Object { $_.Name -eq "JetBrainsMono NFM" }
    if ($alreadyInstalled -and (Test-Path "$fontDir\JetBrainsMonoNerdFontMono-Regular.ttf")) {
        Log-Success "$(Get-Msg 'nerdfont_exists')"
        return
    }

    Log-Info "$(Get-Msg 'installing_nerdfont')"

    $url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
    $zipPath = "$env:TEMP\JetBrainsMonoNerd.zip"

    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $zipPath)

        $extractPath = "$env:TEMP\JetBrainsMonoNerd"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        Get-ChildItem -Path $extractPath -Filter "*.ttf" | ForEach-Object {
            Copy-Item $_.FullName -Destination (Join-Path $fontDir $_.Name) -Force
        }

        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        Log-Success "$(Get-Msg 'nerdfont_success')"
    } catch {
        Log-Warning "$(Get-Msg 'nerdfont_failed') $_"
    }
}

# 1.5. Go installation (required for docs-mcp)
function Install-Go {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        $goVer = go version
        if ($goVer -match 'go([0-9]+)\.([0-9]+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -ge 1 -and $minor -ge 22) {
                Log-Success "$(Get-Msg 'go_already_installed') $major.$minor"
                return
            }
            Log-Warning "$(Get-Msg 'go_version_old')"
        }
    }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_install_go_windows')"
        return
    }

    Log-Info "$(Get-Msg 'go_installing_winget')"
    winget install --id GoLang.Go --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$(Get-Msg 'go_installed_winget')"
        # Add Go to PATH for current session (fallback)
        $goDirs = @(
            "$env:ProgramFiles\Go\bin",
            "$env:LocalAppData\Programs\Go\bin"
        )
        foreach ($d in $goDirs) {
            if (Test-Path "$d\go.exe") {
                $env:Path = "$d;$env:Path"
                break
            }
        }
    } else {
        Log-Error "$(Get-Msg 'go_winget_failed')"
        Log-Warning "$(Get-Msg 'go_manual')"
    }
}

function Install-DocsMcp {
    if (Get-Command go-docs-mcp -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'gomcp_already_installed')"
        return
    }

    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Log-Warning "$(Get-Msg 'gomcp_go_required')"
        return
    }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_install_gomcp')"
        return
    }

    Log-Info "$(Get-Msg 'gomcp_installing')"
    go install github.com/drolosoft/go-docs-mcp@v1.1.0

    $goBin = "$env:USERPROFILE\go\bin"
    if (Test-Path "$goBin\go-docs-mcp.exe") {
        $env:Path = "$goBin;$env:Path"
        Log-Success "$(Get-Msg 'gomcp_installed')"
    } else {
        Log-Error "$(Get-Msg 'gomcp_failed')"
    }
}

# Developer Tools

function Show-DevToolInfo ($toolName) {
    $confFile = Join-Path $PSScriptRoot "config\dev-tools.conf"
    if (Test-Path $confFile) {
        $line = Select-String "^tool:${toolName}:" $confFile | ForEach-Object { $_ -split ':', 3 }
        if ($line -and $line[2]) {
            Log-Info "🔧 $toolName — $($line[2])"
        }
    }
}

function Install-Gitui {
    if (Get-Command gitui -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'gitui_exists')"
        return
    }

    if (-not (Ask-Confirm "$(Get-Msg 'ask_gitui')")) {
        Log-Info "$(Get-Msg 'skip_gitui')"
        return
    }

    Show-DevToolInfo "gitui"

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_install_gitui') winget/scoop/choco"
        return
    }

    Log-Info "$(Get-Msg 'installing_gitui')"

    # Try winget first, then scoop, then choco
    $installed = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $result = winget install --id extrawurst.gitui --exact --silent --accept-package-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
        }
    }
    if (-not $installed -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        scoop install gitui 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $installed = $true }
    }
    if (-not $installed -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        choco install gitui -y 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $installed = $true }
    }

    if ($installed -or (Get-Command gitui -ErrorAction SilentlyContinue)) {
        Log-Success "$(Get-Msg 'gitui_success')"
    } else {
        Log-Warning "$(Get-Msg 'gitui_manual')"
    }
}

# 2. NodeJS installation (with user consent)
function Install-NodeJS {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'node_exists')"
        return
    }

    Write-Host ""
    Write-Host "$(Get-Msg 'node_explain')"
    Write-Host ""

    if (-not (Ask-Confirm "$(Get-Msg 'ask_node')")) {
        Log-Warning "$(Get-Msg 'node_skip_warning')"
        return
    }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_install_node_windows')"
        return
    }

    Log-Info "$(Get-Msg 'installing_node')"

    # Method 1: winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Log-Info "$(Get-Msg 'installing_node_winget')"
        winget install --id OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements 2>$null
        Refresh-EnvPath
    }

    # Method 2: scoop
    if (-not (Get-Command npm -ErrorAction SilentlyContinue) -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Log-Info "$(Get-Msg 'installing_node_scoop')"
        scoop install nodejs-lts 2>$null
        Refresh-EnvPath
    }

    # Method 3: Chocolatey
    if (-not (Get-Command npm -ErrorAction SilentlyContinue) -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        Log-Info "$(Get-Msg 'installing_node_choco')"
        choco install nodejs-lts -y 2>$null
        Refresh-EnvPath
    }

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'node_success')"
    } else {
        Log-Error "$(Get-Msg 'node_install_failed')"
        Log-Warning "$(Get-Msg 'node_manual')"
    }
}

function Add-OpenCodeToPath {
    $installDir = Join-Path $env:USERPROFILE ".opencode\bin"
    if (Test-Path (Join-Path $installDir "opencode.exe")) {
        if ($env:Path -notlike "*$installDir*") {
            $env:Path = "$installDir;$env:Path"
        }
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$installDir*") {
            [System.Environment]::SetEnvironmentVariable("Path", "$installDir;$userPath", "User")
        }
        return $true
    }
    return $false
}

function Install-OpenCodeDirect {
    $installDir = Join-Path $env:USERPROFILE ".opencode\bin"
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null

    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x64" }
    $filename = "opencode-windows-$arch.zip"
    $zipPath = Join-Path $env:TEMP "opencode_install_$PID.zip"
    $url = "https://github.com/anomalyco/opencode/releases/latest/download/$filename"

    Log-Info "$(Get-Msg 'installing_opencode_direct')"
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

    Add-OpenCodeToPath | Out-Null
}

# 3. OpenCode installation
function Install-OpenCode {
    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'opencode_exists') $(opencode --version)"
        return
    }

    if (-not (Ask-Confirm "$(Get-Msg 'ask_opencode')")) {
        Log-Info "$(Get-Msg 'skip_opencode')"
        return
    }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_install_opencode')"
        return
    }

    Log-Info "$(Get-Msg 'installing_opencode')"
    $installed = $false

    # Method 1: npm (preferred when available)
    if (-not $installed -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        Log-Info "$(Get-Msg 'installing_opencode_npm')"
        npm install -g opencode-ai@latest
        Refresh-EnvPath
        if (Get-Command opencode -ErrorAction SilentlyContinue) { $installed = $true }
    }

    # Method 2: Official install script via bash (Git Bash / WSL)
    if (-not $installed -and (Get-Command bash -ErrorAction SilentlyContinue)) {
        Log-Info "$(Get-Msg 'installing_opencode_script')"
        try {
            bash -c "curl -fsSL https://opencode.ai/install | bash"
            Add-OpenCodeToPath | Out-Null
            Refresh-EnvPath
            if (Get-Command opencode -ErrorAction SilentlyContinue) { $installed = $true }
        } catch {
            Log-Warning "$(Get-Msg 'opencode_script_failed')"
        }
    }

    # Method 3: winget
    if (-not $installed -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        Log-Info "$(Get-Msg 'installing_opencode_winget')"
        winget install --id Anomaly.OpenCode --silent --accept-package-agreements --accept-source-agreements 2>$null
        Refresh-EnvPath
        if (Get-Command opencode -ErrorAction SilentlyContinue) { $installed = $true }
    }

    # Method 4: scoop
    if (-not $installed -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Log-Info "$(Get-Msg 'installing_opencode_scoop')"
        scoop install opencode 2>$null
        Refresh-EnvPath
        if (Get-Command opencode -ErrorAction SilentlyContinue) { $installed = $true }
    }

    # Method 5: Direct download from GitHub
    if (-not $installed) {
        try {
            Install-OpenCodeDirect
            if (Get-Command opencode -ErrorAction SilentlyContinue) { $installed = $true }
        } catch {
            Log-Warning "$(Get-Msg 'opencode_script_failed')"
        }
    }

    if (-not $installed) {
        Add-OpenCodeToPath | Out-Null
        if (Get-Command opencode -ErrorAction SilentlyContinue) { $installed = $true }
    }

    if ($installed) {
        Log-Success "$(Get-Msg 'opencode_success')"
    } else {
        Log-Error "$(Get-Msg 'opencode_failed')"
        Log-Info "$(Get-Msg 'opencode_manual')"
        exit 1
    }
}

# 4. Plugins installation
function Install-Plugins {
    if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
        return
    }

    if (-not (Ask-Confirm "$(Get-Msg 'ask_plugins')")) {
        Log-Info "$(Get-Msg 'skip_plugins')"
        return
    }

    # Resolve preset plugin list
    $presetPlugins = switch ($global:Preset) {
        $PresetStandard { $PresetStandardPlugins }
        $PresetMinimal  { $PresetMinimalPlugins }
        default         { $PresetDeveloperPlugins }
    }

    $installAll = Ask-Confirm "$(Get-Msg 'ask_plugins_default')"

    foreach ($entry in $OpencodePlugins) {
        $parts = $entry.Split('|')
        $pluginName = $parts[0]
        $pluginDesc = ""
        if ($parts.Length -gt 1) { $pluginDesc = $parts[1] }

        # Skip if not in preset
        if (-not (Is-InPreset $pluginName $presetPlugins)) {
            continue
        }

        $shouldInstall = $true
        if (-not $installAll) {
            Write-Host "`n--> $Bold$pluginName$ResetColor"
            Write-Host "    $pluginDesc"
            if (-not (Ask-Confirm "$(Get-Msg 'ask_plugin_install') $pluginName?")) {
                $shouldInstall = $false
            }
        }

        if ($shouldInstall) {
            if ($DryRun) {
                Log-Dry "$(Get-Msg 'dry_install_plugin') $pluginName"
            } else {
                Log-Info "$(Get-Msg 'installing_plugin') $pluginName..."
                opencode plugin $pluginName --global
            }
        }
    }
    Log-Success "$(Get-Msg 'plugins_success')"
}

# 5. OpenCode Config setup
function Configure-OpenCode {
    $configDir = Join-Path $HOME ".config\opencode"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $configFile = Join-Path $configDir "opencode.jsonc"

    # Always write system_info.md (includes strict rules)
    # Detect OS, CPU, RAM using CIM if available, fallback for Linux/Core
    if (Get-Command "Get-CimInstance" -ErrorAction SilentlyContinue) {
        $osName = (Get-CimInstance Win32_OperatingSystem).Caption
        $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
        $cpuInfo = (Get-CimInstance Win32_Processor).Name
        $ramGB = [Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
    } else {
        $osName = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
        $osVersion = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        $cpuInfo = "Generic CPU"
        $ramGB = 0
    }
    $ramInfo = "${ramGB} GB RAM"
    $systemInfoFile = Join-Path $configDir "system_info.md"
    $systemInfoContent = @"
# System Environment Details

This file provides the OpenCode AI assistant with details about the current operating system and hardware environment.

- **Operating System:** $osName ($osVersion)
- **Processor (CPU):** $cpuInfo
- **System Memory (RAM):** $ramInfo
- **User Shell:** PowerShell

## ⚠️ STRICT RULES

- **NEVER** commit or push changes without explicit user permission. This is a hard rule — violation is not allowed.
"@
    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_write_system_info') $systemInfoFile"
    } else {
        [System.IO.File]::WriteAllText($systemInfoFile, $systemInfoContent, [System.Text.UTF8Encoding]::new($false))
    }

    if (-not (Ask-Confirm "$(Get-Msg 'ask_mcp')")) {
        Log-Info "$(Get-Msg 'skip_mcp')"
        return
    }

    # Backup existing config using session BACKUP_ID
    if (Test-Path $configFile) {
        Create-Backup
    }

    # Resolve preset lists
    $presetPlugins = switch ($global:Preset) {
        $PresetStandard { $PresetStandardPlugins }
        $PresetMinimal  { $PresetMinimalPlugins }
        default         { $PresetDeveloperPlugins }
    }
    $presetMcps = switch ($global:Preset) {
        $PresetStandard { $PresetStandardMcps }
        $PresetMinimal  { $PresetMinimalMcps }
        default         { $PresetDeveloperMcps }
    }

    $useAllMcp = $true
    if (-not (Ask-Confirm "$(Get-Msg 'ask_mcp_default')")) {
        $useAllMcp = $false
    }

    $mcpJson = ""
    $firstMcp = $true
    foreach ($entry in $OpencodeMcpServers) {
        $parts = $entry.Split('|', 3)
        $mcpName = $parts[0]
        $mcpDesc = ""
        $mcpCmd = ""
        if ($parts.Length -gt 1) { $mcpDesc = $parts[1] }
        if ($parts.Length -gt 2) { $mcpCmd = $parts[2] }

        # Skip if not in preset
        if (-not (Is-InPreset $mcpName $presetMcps)) {
            continue
        }

        $shouldEnable = $true
        if (-not $useAllMcp) {
            Write-Host "`n--> $Bold$mcpName$ResetColorColor"
            Write-Host "    $mcpDesc"
            if (-not (Ask-Confirm "$(Get-Msg 'ask_mcp_install') ${mcpName}?")) {
                $shouldEnable = $false
            }
        }

        if ($shouldEnable) {
            # On Windows, node scripts from npx usually run through cmd
            # We will use 'npx.cmd' instead of 'npx' for reliability, but the list uses 'npx'
            $mcpCmdStr = $mcpCmd -replace "^npx ", "npx.cmd "
            $jsonArr = Args-ToJsonArray -ArgsStr $mcpCmdStr
            if (-not $firstMcp) { $mcpJson += "," }
            $mcpJson += "`n    `"$mcpName`": {`n      `"type`": `"local`",`n      `"command`": $jsonArr,`n      `"enabled`": true`n    }"
            $firstMcp = $false
        }
    }

    $pluginJson = ""
    $firstPlugin = $true
    foreach ($entry in $OpencodePlugins) {
        $pluginName = $entry.Split('|')[0]
        # Skip if not in preset
        if (-not (Is-InPreset $pluginName $presetPlugins)) {
            continue
        }
        if (-not $firstPlugin) { $pluginJson += ",`n" }
        $pluginJson += "    `"$pluginName`""
        $firstPlugin = $false
    }

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_write_opencode_config') $configFile"
        Log-Dry "  $(Get-Msg 'dry_plugins_list') $($OpencodePlugins -join ', ')"
        Log-Dry "  $(Get-Msg 'dry_mcp_configured')"
        return
    }

    $escapedSystemInfoPath = $systemInfoFile.Replace('\', '/')

    $jsoncContent = @"
{
  "`$schema": "https://opencode.ai/config.json",
  "instructions": [
    "$escapedSystemInfoPath"
  ],
  "plugin": [
$pluginJson
  ],
  "mcp": {$mcpJson
  }
}
"@

    [System.IO.File]::WriteAllText($configFile, $jsoncContent, [System.Text.UTF8Encoding]::new($false))
    Log-Success "$(Get-Msg 'opencode_config_updated') $configFile"

    # Install Go + go-docs-mcp if docs-mcp is in current preset
    if (Is-InPreset "docs-mcp" $presetMcps) {
        Install-Go
        Install-DocsMcp
    }
}

# 6. WezTerm config
function Configure-WezTerm {
    if (-not (Ask-Confirm "$(Get-Msg 'ask_wezterm_config')")) {
        Log-Info "$(Get-Msg 'skip_wezterm_config')"
        return
    }

    $wezDir = Join-Path $HOME ".config\wezterm"
    if (-not (Test-Path $wezDir)) {
        New-Item -ItemType Directory -Path $wezDir -Force | Out-Null
    }
    $wezConfig = Join-Path $wezDir "wezterm.lua"

    if ($DryRun) {
        Log-Dry "$(Get-Msg 'dry_wezterm_dir') $wezDir"
        Log-Dry "$(Get-Msg 'dry_wezterm_config') $wezConfig (Catppuccin Mocha, JetBrainsMono NFM, custom hotkeys)"
        return
    }

    if (Test-Path $wezConfig) {
        Create-Backup
    }

    $luaContent = @'
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
  -- Copy via CTRL+Insert / Paste via SHIFT+Insert (standard Windows)
  {
    key = 'Insert',
    mods = 'CTRL',
    action = wezterm.action.CopyTo 'Clipboard',
  },
  {
    key = 'Insert',
    mods = 'SHIFT',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- CTRL+SHIFT+C passthrough — don't intercept for Copy, let the app handle it
  {
    key = 'C',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SendKey { key = 'c', mods = 'CTRL|SHIFT' },
  },
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
'@

    [System.IO.File]::WriteAllText($wezConfig, $luaContent, [System.Text.UTF8Encoding]::new($false))
    Log-Success "$(Get-Msg 'wezterm_config_saved') $wezConfig"
}

# 7. Default Terminal Info
function Configure-DefaultTerminal {
    Write-Host "`n$(Get-Msg 'default_terminal_explain')"
}

# 8. Verify setup
function Verify-Setup {
    Write-Host "`n$Magenta================================================================$ResetColorColor"
    Log-Info "$(Get-Msg 'verifying')"

    $allOk = $true

    if (Get-Command wezterm -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'verify_wezterm') $(wezterm --version | Select-Object -First 1)"
    } else {
        Log-Error "$(Get-Msg 'wezterm_missing_path')"
        $allOk = $false
    }

    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'verify_opencode') $(opencode --version)"
        Log-Info "$(Get-Msg 'active_mcp_servers')"
        opencode mcp list
    } else {
        Log-Error "$(Get-Msg 'opencode_missing_path')"
        $allOk = $false
    }

    if ($allOk) {
        Write-Host "`n$Green$(Get-Msg 'verification_passed')$ResetColor"
        Write-Host "$Yellow$(Get-Msg 'verification_tip')$ResetColor"
    } else {
        Log-Warning "$(Get-Msg 'verification_failed')"
    }

    if ($DryRun) {
        Write-Host "`n$Yellow══════════════════════════════════════════════════════════$ResetColorColor"
        Write-Host "$Yellow  $(Get-Msg 'dry_run_complete')$ResetColorColor"
        Write-Host "$Yellow  $(Get-Msg 'dry_run_apply')$ResetColorColor"
        Write-Host "$Yellow══════════════════════════════════════════════════════════$ResetColorColor"
    }
    Write-Host "$Magenta================================================================$ResetColorColor"
}

# 9. Create Desktop Shortcut (Windows 11)
function Create-DesktopShortcut {
    $shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "OpenCode AI.lnk"

    if (-not (Ask-Confirm "$(Get-Msg 'ask_desktop_shortcut')")) { return }
    if ($DryRun) { Log-Dry "$(Get-Msg 'dry_desktop_shortcut') $shortcutPath"; return }

    try {
        $wezDir = Split-Path -Parent (Get-Command wezterm -ErrorAction Stop).Source
        $wezGui = Join-Path $wezDir "wezterm-gui.exe"
        if (-not (Test-Path $wezGui)) { throw "wezterm-gui.exe not found in $wezDir" }

        # Resolve full path to opencode for robustness
        # Prefer .cmd over .ps1 — .ps1 is blocked by execution policy and not directly executable
        $opencodePath = if (Get-Command opencode.cmd -ErrorAction SilentlyContinue) {
            (Get-Command opencode.cmd -ErrorAction Stop).Source
        } elseif (Get-Command opencode -ErrorAction SilentlyContinue) {
            # Ensure we don't pick the .ps1 variant — swap extension to .cmd if needed
            $resolved = (Get-Command opencode -ErrorAction Stop).Source
            if ($resolved -match '\.ps1$') {
                [System.IO.Path]::ChangeExtension($resolved, ".cmd")
            } else {
                $resolved
            }
        } else {
            "opencode.cmd"
        }

        # Create a .cmd wrapper that kills stale mux processes before launching
        $wrapperPath = [System.IO.Path]::ChangeExtension($shortcutPath, ".cmd")
        $wrapperContent = @"
@echo off
taskkill /f /im wezterm-gui.exe 2>nul
taskkill /f /im wezterm-mux-server.exe 2>nul
timeout /t 1 /nobreak >nul
start "" "$wezGui" start -- "$opencodePath" -m opencode/deepseek-v4-flash-free
"@
        [System.IO.File]::WriteAllText($wrapperPath, $wrapperContent, [System.Text.UTF8Encoding]::new($false))

        # Create LNK pointing to the wrapper
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $wrapperPath
        $shortcut.WorkingDirectory = $HOME
        $shortcut.IconLocation = "$wezGui, 0"
        $shortcut.Description = "OpenCode AI in WezTerm"
        $shortcut.Save()
        Log-Success "$(Get-Msg 'desktop_shortcut_success')"
    } catch {
        Log-Warning "$(Get-Msg 'desktop_shortcut_failed') $_"
    }
}


# 10. Add Windows Explorer context menu (right-click folder → Open in OpenCode)
function Install-ContextMenu {
    if (-not (Ask-Confirm "$(Get-Msg 'ask_context_menu')")) { return }

    if ($DryRun) { Log-Dry "$(Get-Msg 'dry_context_menu')"; return }

    try {
        $wezDir = Split-Path -Parent (Get-Command wezterm -ErrorAction Stop).Source
        $wezGui = Join-Path $wezDir "wezterm-gui.exe"
        if (-not (Test-Path $wezGui)) { throw "wezterm-gui.exe not found in $wezDir" }

        $opencodePath = if (Get-Command opencode.cmd -ErrorAction SilentlyContinue) {
            (Get-Command opencode.cmd -ErrorAction Stop).Source
        } elseif (Get-Command opencode -ErrorAction SilentlyContinue) {
            $resolved = (Get-Command opencode -ErrorAction Stop).Source
            if ($resolved -match '\.ps1$') {
                [System.IO.Path]::ChangeExtension($resolved, ".cmd")
            } else {
                $resolved
            }
        } else {
            "opencode.cmd"
        }

        $command = '"' + $wezGui + '" start --cwd "%1" -- "' + $opencodePath + '" -m opencode/deepseek-v4-flash-free'
        $commandBg = '"' + $wezGui + '" start --cwd "%V" -- "' + $opencodePath + '" -m opencode/deepseek-v4-flash-free'

        # Right-click on a folder
        $dirKey = "HKCU:\Software\Classes\Directory\shell\OpenCodeInWezTerm"
        New-Item -Path "$dirKey\command" -Force | Out-Null
        Set-ItemProperty -Path $dirKey -Name "(default)" -Value "$(Get-Msg 'context_menu_text')"
        Set-ItemProperty -Path $dirKey -Name "Icon" -Value "$wezGui,0"
        Set-ItemProperty -Path "$dirKey\command" -Name "(default)" -Value $command

        # Right-click on empty space in a folder (background)
        $bgKey = "HKCU:\Software\Classes\Directory\Background\shell\OpenCodeInWezTerm"
        New-Item -Path "$bgKey\command" -Force | Out-Null
        Set-ItemProperty -Path $bgKey -Name "(default)" -Value "$(Get-Msg 'context_menu_text')"
        Set-ItemProperty -Path $bgKey -Name "Icon" -Value "$wezGui,0"
        Set-ItemProperty -Path "$bgKey\command" -Name "(default)" -Value $commandBg

        Log-Success "$(Get-Msg 'context_menu_success')"
    } catch {
        Log-Warning "$(Get-Msg 'context_menu_failed') $_"
    }
}


# Main Run Flow
try {
    Generate-BackupId
    Migrate-PluginNames

    if ($ListBackups) {
        $dirs = List-Backups
        if ($null -eq $dirs) {
            Log-Warning "$(Get-Msg 'no_backups_found_short')"
        } else {
            $totalSize = (Get-ChildItem $global:BackupDir -Recurse -File | Measure-Object Length -Sum).Sum / 1KB
            Write-Host "`n$Bold$(Get-Msg 'list_total')$ResetColorColor $($dirs.Count) $(Get-Msg 'list_backups_label')"
            Write-Host "$Bold$(Get-Msg 'list_size')$ResetColorColor ~$([Math]::Round($totalSize, 1)) KB"
        }
    } elseif ($Reset) {
        Reset-Config
    } elseif ($CreateBackup) {
        Create-Backup
    } elseif ($RestoreBackup) {
        Restore-Backup
    } elseif ($RemoveBackups) {
        Remove-Backups
    } else {
        # Generate developer docs upfront if configs exist
        & "$PSScriptRoot\scripts\generate-dev-docs.sh" 2>$null
        Select-Preset
        Set-OpenCodeExecutionPolicy
        Install-WezTerm
        Install-NodeJS
        Install-OpenCode
        Install-Plugins
        Configure-OpenCode
        Install-NerdFont
        if ($global:Preset -eq "developer") { Install-Gitui }
        Configure-WezTerm
        if ($global:Preset -eq "developer") {
            & "$PSScriptRoot\scripts\generate-dev-docs.sh"
        }
        Configure-DefaultTerminal
        Write-Host "`n$Cyan$(Get-Msg 'shortcut_intro')$ResetColorColor`n"
        Create-DesktopShortcut
        Install-ContextMenu
        Verify-Setup
    }
} catch {
    Log-Error "$(Get-Msg 'unexpected_error') $_"
    exit 1
}
