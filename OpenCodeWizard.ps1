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
.EXAMPLE
    .\OpenCodeWizard.ps1 -Silent
.EXAMPLE
    .\OpenCodeWizard.ps1 -Lang "uk"
#>
param (
    [switch]$Silent,
    [string]$Lang = "en",
    [switch]$ResetColor,
    [switch]$CreateBackup,
    [switch]$RestoreBackup,
    [switch]$RemoveBackups
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Colors for terminal
$Magenta = "$([char]27)[1;35m"
$Cyan = "$([char]27)[1;36m"
$Green = "$([char]27)[1;32m"
$Yellow = "$([char]27)[1;33m"
$Red = "$([char]27)[1;31m"
$Blue = "$([char]27)[1;34m"
$ResetColorColor = "$([char]27)[0m"
$Bold = "$([char]27)[1m"

# Default Language Code
$LangCode = "en"

# Backup State
$global:BackupDir = "$HOME\.local\share\opencodeWizard\backups"
$global:BackupId = ""

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# Format: "plugin_name|plugin_description"
$OpencodePlugins = @(
    "oh-my-openagent|Session management and advanced CLI commands"
    "opencode-mem|Vector and long-term memory for the assistant"
    "@different-ai/opencode-browser|Integration with a real web browser"
    "@tarquinen/opencode-smart-title|Smart auto-naming of active sessions"
    "opencode-token-speed-plugin|Real-time speed indicator, Tokens Per Second"
)

# Format: "mcp_name|description|command"
$OpencodeMcpServers = @(
    "fetch|Fast retrieval of web page text content|npx -y mcp-server-fetch-typescript"
    "puppeteer|Browser automation (screenshots, clicks)|npx -y @modelcontextprotocol/server-puppeteer"
    "postgres|Local database|npx -y @modelcontextprotocol/server-postgres postgresql://postgres:postgres@localhost:5432/gpt_chat_bot"
    "context7|Library documentation|npx -y @upstash/context7-mcp"
)


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
        "ask_node" = "Встановити Node.js LTS через winget?"
        "node_exists" = "Node.js та npm вже встановлено."
        "node_missing" = "Для встановлення OpenCode потрібен NPM. Будь ласка, встановіть Node.js."
        "installing_node" = "Встановлення Node.js через winget..."
        "node_success" = "Node.js успішно встановлено! Обов'язково перезапустіть термінал, щоб npm з'явився в PATH."
        "ask_opencode" = "Встановити OpenCode CLI глобально через npm?"
        "opencode_exists" = "OpenCode вже встановлено:"
        "skip_opencode" = "Пропуск встановлення OpenCode."
        "installing_opencode" = "Встановлення opencode-ai глобально..."
        "opencode_success" = "OpenCode CLI успішно встановлено!"
        "opencode_failed" = "Не вдалося встановити opencode-ai через npm."
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
        "ask_node" = "Node.js is missing. Install Node.js LTS via winget?"
        "node_exists" = "Node.js & npm are already installed."
        "node_missing" = "NPM is required to install OpenCode. Please install Node.js."
        "installing_node" = "Installing Node.js via winget..."
        "node_success" = "Node.js installed successfully! Make sure to restart the terminal for npm to appear in PATH."
        "ask_opencode" = "Install OpenCode CLI globally via npm?"
        "opencode_exists" = "OpenCode is already installed:"
        "skip_opencode" = "Skipping OpenCode installation."
        "installing_opencode" = "Installing opencode-ai globally..."
        "opencode_success" = "OpenCode CLI installed successfully!"
        "opencode_failed" = "Failed to install opencode-ai via npm."
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
    Write-Host "Select wizard language / Оберіть мову інтерфейсу:"
    Write-Host "  1) English (en)"
    Write-Host "  2) Українська (uk)"
    $langChoice = Read-Host -Prompt "Choice / Вибір [1-2]"
    if ($langChoice -eq "2") {
        $LangCode = "uk"
    } else {
        $LangCode = "en"
    }
}
Write-Host ""

function Ask-Confirm ($prompt) {
    if ($Silent) {
        return $true
    }
    while ($true) {
        $ans = Read-Host -Prompt "$Cyan$prompt [Y/n]$ResetColor"
        if ([string]::IsNullOrEmpty($ans)) { $ans = "y" }
        if ($ans -match '^[Yy]$') { return $true }
        if ($ans -match '^[Nn]$') { return $false }
    }
}

function Log-Info ($msg) { Write-Host "${Blue}[INFO]${ResetColor} $msg" }
function Log-Success ($msg) { Write-Host "${Green}[SUCCESS]${ResetColor} $msg" }
function Log-Warning ($msg) { Write-Host "${Yellow}[WARNING]${ResetColor} $msg" }
function Log-Error ($msg) { Write-Host "${Red}[ERROR]${ResetColor} $msg" }

function Refresh-EnvPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Onboarding Show
Write-Host "${Magenta}================================================================${ResetColor}"
Write-Host "  $(Get-Msg 'title')"
Write-Host "${Magenta}================================================================${ResetColor}`n"
Write-Host "$(Get-Msg 'intro_text')"
Write-Host "`n${Magenta}================================================================${ResetColor}`n"

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

function Restore-Backup {
    if (-not (Test-Path $global:BackupDir) -or (Get-ChildItem $global:BackupDir -Directory).Count -eq 0) {
        Log-Warning "No backups found in $global:BackupDir"
        return
    }

    Write-Host "`n${Bold}Available backups:${ResetColor}"
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

    Write-Host ""
    $choice = Read-Host "Select backup to restore [1-$($dirs.Count)]"
    $choiceInt = 0
    if (-not [int]::TryParse($choice, [ref]$choiceInt) -or $choiceInt -lt 1 -or $choiceInt -gt $dirs.Count) {
        Log-Error "Invalid choice. Aborting."
        exit 1
    }

    $selected = $dirs[$choiceInt - 1].FullName
    Write-Host "`nFiles in this backup:"
    Get-ChildItem $selected -File | Where-Object { $_.Name -ne "manifest.txt" } | ForEach-Object { Write-Host "  $($_.Name)" }
    Write-Host ""

    if (-not (Ask-Confirm "Are you sure you want to restore this backup? Current config will be overwritten!")) {
        Log-Info "Restore cancelled."
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
        Log-Error "Restore failed."
        exit 1
    }

    Log-Success "Configuration successfully restored!"
}

function Remove-Backups {
    if (-not (Test-Path $global:BackupDir) -or (Get-ChildItem $global:BackupDir -Directory).Count -eq 0) {
        Log-Warning "No backups found."
        return
    }

    $dirs = Get-ChildItem $global:BackupDir -Directory
    Write-Host "`nFound ${Bold}$($dirs.Count)${ResetColor} backup(s)."

    if (-not (Ask-Confirm "Are you sure you want to permanently delete all backups?")) {
        Log-Info "Cancelled."
        return
    }

    Remove-Item $global:BackupDir -Recurse -Force
    Log-Success "All backups have been removed."
}

function Reset-Config {
    Log-Info "Creating backup before reset..."
    Create-Backup

    $opencodeCfg = "$HOME\.config\opencode\opencode.jsonc"
    $sysinfo = "$HOME\.config\opencode\system_info.md"
    $wezCfg = "$HOME\.config\wezterm\wezterm.lua"
    $desktop = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), "OpenCode AI.lnk")

    if (Test-Path $opencodeCfg) { Remove-Item $opencodeCfg -Force; Log-Info "Removed: $opencodeCfg" }
    if (Test-Path $sysinfo) { Remove-Item $sysinfo -Force; Log-Info "Removed: $sysinfo" }
    if (Test-Path $wezCfg) { Remove-Item $wezCfg -Force; Log-Info "Removed: $wezCfg" }
    if (Test-Path $desktop) { Remove-Item $desktop -Force; Log-Info "Removed: $desktop" }

    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        foreach ($entry in $OpencodePlugins) {
            $pluginName = $entry.Split('|')[0]
            Log-Info "Removing plugin: $pluginName"
            try { opencode plugin remove $pluginName *>$null } catch {}
        }
    }

    Log-Success "Configuration reset to defaults."
}

function Migrate-PluginNames {
    $config = "$HOME\.config\opencode\opencode.jsonc"
    if (Test-Path $config) {
        $content = Get-Content $config -Raw
        if ($content -match "oh-my-opencode") {
            Log-Warning "Migrating legacy plugin name (oh-my-opencode -> oh-my-openagent)..."
            Create-Backup
            $content = $content -replace "oh-my-opencode", "oh-my-openagent"
            Set-Content -Path $config -Value $content -Encoding UTF8
            if (Get-Command opencode -ErrorAction SilentlyContinue) {
                try { opencode plugin oh-my-openagent --global *>$null } catch {}
            }
            Log-Success "Migration complete."
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
    winget install --id wez.wezterm --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$(Get-Msg 'wezterm_success')"
        Refresh-EnvPath
    } else {
        Log-Error "$(Get-Msg 'wezterm_failed')"
    }
}

# 2. NodeJS installation
function Install-NodeJS {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Log-Success "$(Get-Msg 'node_exists')"
        return
    }

    if (-not (Ask-Confirm "$(Get-Msg 'ask_node')")) {
        Log-Error "$(Get-Msg 'node_missing')"
        exit 1
    }

    Log-Info "$(Get-Msg 'installing_node')"
    winget install --id OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
    Log-Warning "$(Get-Msg 'node_success')"
    Refresh-EnvPath
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

    Log-Info "$(Get-Msg 'installing_opencode')"
    npm install -g opencode-ai@latest
    if ($LASTEXITCODE -eq 0) {
        Log-Success "$(Get-Msg 'opencode_success')"
    } else {
        Log-Error "$(Get-Msg 'opencode_failed')"
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

    $installAll = Ask-Confirm "$(Get-Msg 'ask_plugins_default')"

    foreach ($entry in $OpencodePlugins) {
        $parts = $entry.Split('|')
        $pluginName = $parts[0]
        $pluginDesc = ""
        if ($parts.Length -gt 1) { $pluginDesc = $parts[1] }

        $shouldInstall = $true
        if (-not $installAll) {
            Write-Host "`n--> $Bold$pluginName$ResetColor"
            Write-Host "    $pluginDesc"
            if (-not (Ask-Confirm "$(Get-Msg 'ask_plugin_install') $pluginName?")) {
                $shouldInstall = $false
            }
        }

        if ($shouldInstall) {
            Log-Info "$(Get-Msg 'installing_plugin') $pluginName..."
            opencode plugin $pluginName --global
        }
    }
    Log-Success "$(Get-Msg 'plugins_success')"
}

# 5. OpenCode Config setup
function Configure-OpenCode {
    if (-not (Ask-Confirm "$(Get-Msg 'ask_mcp')")) {
        Log-Info "$(Get-Msg 'skip_mcp')"
        return
    }

    $configDir = Join-Path $HOME ".config\opencode"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $configFile = Join-Path $configDir "opencode.jsonc"

    # Backup existing config using session BACKUP_ID
    if (Test-Path $configFile) {
        Create-Backup
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

        $shouldEnable = $true
        if (-not $useAllMcp) {
            Write-Host "`n--> ${Bold}${mcpName}${ResetColor}"
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
        if (-not $firstPlugin) { $pluginJson += ",`n" }
        $pluginJson += "    `"$pluginName`""
        $firstPlugin = $false
    }

    # Gather system/hardware info
    $osName = (Get-CimInstance Win32_OperatingSystem).Caption
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
    $cpuInfo = (Get-CimInstance Win32_Processor).Name
    $ramGB = [Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
    $ramInfo = "${ramGB} GB RAM"

    # Write to ~/.config/opencode/system_info.md
    $systemInfoFile = Join-Path $configDir "system_info.md"
    $systemInfoContent = @"
# System Environment Details

This file provides the OpenCode AI assistant with details about the current operating system and hardware environment.

- **Operating System:** $osName ($osVersion)
- **Processor (CPU):** $cpuInfo
- **System Memory (RAM):** $ramInfo
- **User Shell:** PowerShell
"@
    [System.IO.File]::WriteAllText($systemInfoFile, $systemInfoContent, [System.Text.Encoding]::UTF8)

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

    [System.IO.File]::WriteAllText($configFile, $jsoncContent, [System.Text.Encoding]::UTF8)
    Log-Success "$(Get-Msg 'opencode_config_updated') $configFile"
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
      command = { args = { 'opencode.cmd', '-m', 'opencode/deepseek-v4-flash-free' } },
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

    [System.IO.File]::WriteAllText($wezConfig, $luaContent, [System.Text.Encoding]::UTF8)
    Log-Success "$(Get-Msg 'wezterm_config_saved') $wezConfig"
}

# 7. Default Terminal Info
function Configure-DefaultTerminal {
    Write-Host "`n$(Get-Msg 'default_terminal_explain')"
}

# 8. Verify setup
function Verify-Setup {
    Write-Host "`n$Magenta================================================================$ResetColor"
    Log-Info "$(Get-Msg 'verifying')"

    $allOk = $true

    if (Get-Command wezterm -ErrorAction SilentlyContinue) {
        Log-Success "WezTerm: $(wezterm --version | Select-Object -First 1)"
    } else {
        Log-Error "$(Get-Msg 'wezterm_missing_path')"
        $allOk = $false
    }

    if (Get-Command opencode -ErrorAction SilentlyContinue) {
        Log-Success "OpenCode: $(opencode --version)"
        Log-Info "Active MCP Servers:"
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
    Write-Host "$Magenta================================================================$ResetColor"
}

# 9. Create Desktop Shortcut (Windows 11)
function Create-DesktopShortcut {
    $desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), "OpenCode AI.lnk")
    if (Ask-Confirm "$(Get-Msg 'ask_desktop_shortcut')") {
        try {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($desktopPath)
            $wezPath = (Get-Command wezterm -ErrorAction SilentlyContinue).Source
            if (-not $wezPath) {
                $wezPath = "wezterm.exe"
            }
            $Shortcut.TargetPath = $wezPath
            $Shortcut.Arguments = "start -- opencode.cmd -m opencode/deepseek-v4-flash-free"
            $Shortcut.WorkingDirectory = $HOME
            $Shortcut.IconLocation = "$wezPath,0"
            $Shortcut.Save()
            Log-Success "$(Get-Msg 'desktop_shortcut_success')"
        } catch {
            Log-Warning "Could not create desktop shortcut: $_"
        }
    }
}


# Main Run Flow
try {
    Generate-BackupId
    Migrate-PluginNames

    if ($Reset) {
        Reset-Config
    } elseif ($CreateBackup) {
        Create-Backup
    } elseif ($RestoreBackup) {
        Restore-Backup
    } elseif ($RemoveBackups) {
        Remove-Backups
    } else {
        Install-WezTerm
        Install-NodeJS
        Install-OpenCode
        Install-Plugins
        Configure-OpenCode
        Configure-WezTerm
        Configure-DefaultTerminal
        Create-DesktopShortcut
        Verify-Setup
    }
} catch {
    Log-Error "An unexpected error occurred: $_"
    exit 1
}
