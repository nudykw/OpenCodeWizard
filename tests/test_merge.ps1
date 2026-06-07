<#
.SYNOPSIS
    TDD tests for config-merge feature (PowerShell)
.DESCRIPTION
    Red phase: exit 1 until Merge-ShellConfigs and -MergeBackup are implemented.
    Run: pwsh -File tests/test_merge.ps1
#>

$ErrorActionPreference = 'Continue'

# Stubs for functions referenced by Create-Backup (not relevant to regression test).
function Get-Msg { param([string]$Key, [object[]]$FormatArgs) return $Key }
function Log-Success { param([string]$Msg) Write-Host "  [stub-success] $Msg" }
function Log-Dry { param([string]$Msg) }

$TestsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $TestsDir
$Script = Join-Path $ProjectDir 'OpenCodeWizard.ps1'
$Fixture = Join-Path $TestsDir 'fixtures/backup1'

# Sanity check: fixtures must exist (Task 1 QA).
$expectedFixtures = @('opencode.jsonc', 'wezterm.lua', 'bashrc', 'zshrc', 'Microsoft.PowerShell_profile.ps1')
foreach ($f in $expectedFixtures) {
    if (-not (Test-Path (Join-Path $Fixture $f))) {
        Write-Error "FAIL: fixture missing: $f"
        exit 1
    }
}

# Extract merge function definitions from the main script using brace counting.
function Extract-FunctionBlocks {
    param(
        [string]$Path,
        [string[]]$Names
    )
    $lines = Get-Content $Path
    $result = [System.Collections.Generic.List[string]]::new()
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $matched = $false
        foreach ($name in $Names) {
            if ($line -match "^\s*function\s+$([regex]::Escape($name))\s*\{") {
                $matched = $true
                $braceCount = 1
                $result.Add($line)
                $i++
                while ($i -lt $lines.Count -and $braceCount -gt 0) {
                    $current = $lines[$i]
                    $result.Add($current)
                    $braceCount += ([regex]::Matches($current, '\{')).Count
                    $braceCount -= ([regex]::Matches($current, '\}')).Count
                    $i++
                }
                $result.Add('')  # separator
                break
            }
        }
        if (-not $matched) { $i++ }
    }
    return $result -join "`n"
}

# Extract the merge functions (existing + new one to-be-implemented).
$mergeFunctions = Extract-FunctionBlocks -Path $Script -Names @(
    'Merge-JsonConfigs',
    'Merge-LuaConfigs',
    'Merge-MarkdownConfigs',
    'Merge-ShellConfigs',
    'Smart-Merge',
    'Create-Backup',
    'Generate-BackupId',
    'Get-ContentHash',
    'Remove-OldBackups'
)

# Source the extracted functions in the current scope.
Invoke-Expression $mergeFunctions

# Test results
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:FailedTests = [System.Collections.Generic.List[string]]::new()

function Test-Passed {
    param([string]$Name)
    Write-Host "  PASS: $Name" -ForegroundColor Green
    $script:TestsPassed++
}

function Test-Failed {
    param([string]$Name, [string]$Msg)
    Write-Host "  FAIL: $Name - $Msg" -ForegroundColor Red
    $script:TestsFailed++
    $script:FailedTests.Add($Name) | Out-Null
}

function Assert-Grep {
    param(
        [string]$File,
        [string]$Pattern,
        [string]$Message
    )
    if (Select-String -Path $File -Pattern $Pattern -Quiet) {
        return $true
    }
    Write-Host "    ASSERT: $Message"
    Write-Host "    File: $File"
    Write-Host "    Pattern: $Pattern"
    return $false
}

# Sandbox
$SBox = Join-Path ([System.IO.Path]::GetTempPath()) ("ocw-merge-test-" + [System.Guid]::NewGuid().ToString().Substring(0, 8))
New-Item -ItemType Directory -Force -Path $SBox | Out-Null

try {
    Write-Host ''
    Write-Host '========================================='
    Write-Host ' config-merge TDD Test Suite (PowerShell)'
    Write-Host '========================================='

    # --- Test 1: JSON merge preserves backup fields (backup-wins) ---
    Write-Host ''
    Write-Host 'Test: test_json_merge'
    $oldFile = Join-Path $SBox 'old.jsonc'
    $newFile = Join-Path $SBox 'new.jsonc'
    Copy-Item (Join-Path $Fixture 'opencode.jsonc') $oldFile
    @'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "dark",
  "mcpServers": {
    "fetch": {
      "type": "stdio",
      "command": ["wizard-fetch-cmd"]
    },
    "wizard-only-mcp": {
      "type": "stdio",
      "command": ["wizard-only-cmd"]
    }
  }
}
'@ | Set-Content $newFile
    if (-not (Get-Command Merge-JsonConfigs -ErrorAction SilentlyContinue)) {
        Test-Failed 'test_json_merge' 'REGRESSION: Merge-JsonConfigs missing'
    } else {
        Merge-JsonConfigs -oldFile $oldFile -newFile $newFile
        $ok = $true
        if (-not (Assert-Grep -File $newFile -Pattern 'field_from_backup' -Message "Backup field 'field_from_backup' must be preserved (backup-wins)")) { $ok = $false }
        if (-not (Assert-Grep -File $newFile -Pattern 'user-custom-mcp' -Message "Backup MCP 'user-custom-mcp' must be preserved")) { $ok = $false }
        if (-not (Assert-Grep -File $newFile -Pattern 'wizard-only-mcp' -Message "Wizard's new MCP entry 'wizard-only-mcp' must be added")) { $ok = $false }
        if ($ok) { Test-Passed 'test_json_merge' } else { Test-Failed 'test_json_merge' 'assertions failed' }
    }

    # --- Test 2: Lua merge preserves backup customizations ---
    Write-Host ''
    Write-Host 'Test: test_lua_merge'
    $oldFile = Join-Path $SBox 'old.lua'
    $newFile = Join-Path $SBox 'new.lua'
    Copy-Item (Join-Path $Fixture 'wezterm.lua') $oldFile
    @'
-- === OpenCode Wizard ===
return {
  color_scheme = "Catppuccin Mocha",
  font_size = 12.0,
}
'@ | Set-Content $newFile
    if (-not (Get-Command Merge-LuaConfigs -ErrorAction SilentlyContinue)) {
        Test-Failed 'test_lua_merge' 'REGRESSION: Merge-LuaConfigs missing'
    } else {
        Merge-LuaConfigs -oldFile $oldFile -newFile $newFile
        $ok = $true
        if (-not (Assert-Grep -File $newFile -Pattern 'user-custom-event' -Message "Backup custom event 'user-custom-event' must be preserved")) { $ok = $false }
        if (-not (Assert-Grep -File $newFile -Pattern 'Catppuccin Mocha' -Message "Wizard's new color scheme 'Catppuccin Mocha' must be added")) { $ok = $false }
        if ($ok) { Test-Passed 'test_lua_merge' } else { Test-Failed 'test_lua_merge' 'assertions failed' }
    }

    # --- Test 3: Shell config merge function exists (Red: should FAIL) ---
    Write-Host ''
    Write-Host 'Test: test_shell_merge_function_exists'
    if (-not (Get-Command Merge-ShellConfigs -ErrorAction SilentlyContinue)) {
        Test-Failed 'test_shell_merge_function_exists' 'RED: Merge-ShellConfigs function is not implemented yet'
    } else {
        Test-Passed 'test_shell_merge_function_exists'
    }

    # --- Test 4: Shell merge preserves backup vars and adds wizard vars ---
    Write-Host ''
    Write-Host 'Test: test_shell_merge'
    $oldFile = Join-Path $SBox 'old.bashrc'
    $newFile = Join-Path $SBox 'new.bashrc'
    Copy-Item (Join-Path $Fixture 'bashrc') $oldFile
    @'
# Wizard-managed section
$env:TERMINAL = "wezterm"
$env:OPENCODE_AGENTS_SWITCH_SINGLE_MODEL = "true"
'@ | Set-Content $newFile
    if (-not (Get-Command Merge-ShellConfigs -ErrorAction SilentlyContinue)) {
        Test-Failed 'test_shell_merge' 'RED: Merge-ShellConfigs function is not implemented yet'
    } else {
        Merge-ShellConfigs -oldFile $oldFile -newFile $newFile
        $ok = $true
        if (-not (Assert-Grep -File $newFile -Pattern 'MY_CUSTOM_VAR' -Message "Backup shell var 'MY_CUSTOM_VAR' must be preserved")) { $ok = $false }
        if (-not (Assert-Grep -File $newFile -Pattern 'TERMINAL' -Message "Wizard's new export 'TERMINAL' must be added")) { $ok = $false }
        if ($ok) { Test-Passed 'test_shell_merge' } else { Test-Failed 'test_shell_merge' 'assertions failed' }
    }

    # --- Test 5: Idempotency - re-running merge does not duplicate lines ---
    Write-Host ''
    Write-Host 'Test: test_shell_idempotency'
    $oldFile = Join-Path $SBox 'old.bashrc'
    $newFile = Join-Path $SBox 'new.bashrc'
    Copy-Item (Join-Path $Fixture 'bashrc') $oldFile
    @'
$env:TERMINAL = "wezterm"
'@ | Set-Content $newFile
    if (-not (Get-Command Merge-ShellConfigs -ErrorAction SilentlyContinue)) {
        Test-Failed 'test_shell_idempotency' 'RED: Merge-ShellConfigs function is not implemented yet'
    } else {
        Merge-ShellConfigs -oldFile $oldFile -newFile $newFile
        $count1 = @(Select-String -Path $newFile -Pattern 'TERMINAL').Count
        Merge-ShellConfigs -oldFile $newFile -newFile $newFile
        $count2 = @(Select-String -Path $newFile -Pattern 'TERMINAL').Count
        if ($count1 -ne $count2) {
            Test-Failed 'test_shell_idempotency' "Idempotency broken: $count1 vs $count2"
        } else {
            Test-Passed 'test_shell_idempotency'
        }
    }

    # --- Test 6: -MergeBackup parameter exists in param() block ---
    Write-Host ''
    Write-Host 'Test: test_merge_flag_in_help'
    $scriptContent = Get-Content $Script -Raw
    if ($scriptContent -notmatch '\$MergeBackup') {
        Test-Failed 'test_merge_flag_in_help' 'RED: $MergeBackup parameter is not defined in the script'
    } else {
        Test-Passed 'test_merge_flag_in_help'
    }

    # --- Test 7: Create-Backup is idempotent within a session (regression) ---
    # Regression: a second Create-Backup call in the same session was
    # overwriting the opencode.jsonc backup with the wizard's just-written
    # default, so Smart-Merge then saw backup == target and wrongly
    # reported "no changes (skipping)".
    Write-Host ''
    Write-Host 'Test: test_create_backup_idempotent'
    $targetHome7 = Join-Path $SBox 'home7'
    $xdgData7 = Join-Path $SBox 'data7'
    $opencodeDir7 = Join-Path $targetHome7 '.config\opencode'
    $opencodeCfg7 = Join-Path $opencodeDir7 'opencode.jsonc'
    $sysinfo7 = Join-Path $opencodeDir7 'system_info.md'
    New-Item -ItemType Directory -Force -Path $opencodeDir7 | Out-Null
    @'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": "llamaserver",
  "user_custom_field": "user-preserved-data"
}
'@ | Set-Content $opencodeCfg7
    '# System Info (original user version)' | Set-Content $sysinfo7

    $global:BackupDir = Join-Path $xdgData7 'opencodeWizard\backups'
    $global:BackupId = $null
    # Stage 1: configure_opencode calls Create-Backup BEFORE writing default.
    $oldHome = $HOME
    Set-Variable -Name HOME -Value $targetHome7 -Scope Global -Force
    try {
        Create-Backup
    } finally {
        Set-Variable -Name HOME -Value $oldHome -Scope Global -Force
    }
    $destDirs = @(Get-ChildItem -Directory -Path $global:BackupDir -ErrorAction SilentlyContinue)
    if ($destDirs.Count -eq 0) {
        Test-Failed 'test_create_backup_idempotent' 'Backup directory was not created'
    } else {
        $backupPath = $destDirs[0].FullName
        $backupOpencode = Join-Path $backupPath 'opencode.jsonc'
        $backupSysinfo = Join-Path $backupPath 'system_info.md'
        $ok = $true
        if (-not (Test-Path $backupOpencode)) {
            Test-Failed 'test_create_backup_idempotent' 'First backup did not capture opencode.jsonc'
            $ok = $false
        } elseif (-not (Select-String -Path $backupOpencode -Pattern 'user-preserved-data' -Quiet)) {
            Test-Failed 'test_create_backup_idempotent' 'First backup must contain user data'
            $ok = $false
        }

        if ($ok) {
            # Stage 2: configure_opencode overwrites user's file with wizard default.
            @'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "system",
  "mcp": {}
}
'@ | Set-Content $opencodeCfg7
            '# System Info (wizard-default version)' | Set-Content $sysinfo7

            # Stage 3: configure_wezterm calls Create-Backup again — must NOT overwrite.
            Set-Variable -Name HOME -Value $targetHome7 -Scope Global -Force
            try {
                Create-Backup
            } finally {
                Set-Variable -Name HOME -Value $oldHome -Scope Global -Force
            }

            if (-not (Select-String -Path $backupOpencode -Pattern 'user-preserved-data' -Quiet)) {
                Test-Failed 'test_create_backup_idempotent' 'REGRESSION: backup was overwritten by 2nd Create-Backup call (bug)'
                $ok = $false
            }
            if (Select-String -Path $backupOpencode -Pattern '"theme": "system"' -Quiet) {
                Test-Failed 'test_create_backup_idempotent' 'REGRESSION: backup contains wizard default instead of user original'
                $ok = $false
            }
            if (-not (Select-String -Path $backupSysinfo -Pattern 'original user version' -Quiet)) {
                Test-Failed 'test_create_backup_idempotent' 'REGRESSION: system_info.md backup was overwritten'
                $ok = $false
            }
        }
        if ($ok) { Test-Passed 'test_create_backup_idempotent' }
    }

    # --- Test 8: MAX_BACKUPS=15 auto-prunes oldest ---
    Write-Host ''
    Write-Host 'Test: test_max_backups_prunes_oldest'
    $targetHome8 = Join-Path $SBox 'home8'
    $xdgData8 = Join-Path $SBox 'data8'
    $opencodeDir8 = Join-Path $targetHome8 '.config\opencode'
    $backupRoot8 = Join-Path $xdgData8 'opencodeWizard\backups'
    New-Item -ItemType Directory -Force -Path $opencodeDir8 | Out-Null
    '{"user": "max-backups-test"}' | Set-Content (Join-Path $opencodeDir8 'opencode.jsonc')
    for ($i = 1; $i -le 16; $i++) {
        $padded = '{0:D2}' -f $i
        New-Item -ItemType Directory -Force -Path (Join-Path $backupRoot8 "ocw-test-20200101-0000$padded") | Out-Null
    }
    $global:BackupDir = $backupRoot8
    $global:BackupId = $null
    $global:MaxBackups = 15
    Set-Variable -Name HOME -Value $targetHome8 -Scope Global -Force
    try { Create-Backup } finally { Set-Variable -Name HOME -Value $oldHome -Scope Global -Force }
    $count8 = @(Get-ChildItem -Directory -Path $backupRoot8 -ErrorAction SilentlyContinue).Count
    if ($count8 -ne 15) {
        Test-Failed 'test_max_backups_prunes_oldest' "Expected 15 dirs after prune, got $count8"
    } elseif (Test-Path (Join-Path $backupRoot8 'ocw-test-20200101-000001')) {
        Test-Failed 'test_max_backups_prunes_oldest' 'Oldest backup was NOT pruned'
    } elseif (-not (Test-Path (Join-Path $backupRoot8 'ocw-test-20200101-000003'))) {
        Test-Failed 'test_max_backups_prunes_oldest' 'A backup that should have been kept was pruned'
    } else {
        Test-Passed 'test_max_backups_prunes_oldest'
    }

    # --- Test 9: content-hash dedup skips redundant backups ---
    Write-Host ''
    Write-Host 'Test: test_content_hash_dedup'
    $targetHome9 = Join-Path $SBox 'home9'
    $xdgData9 = Join-Path $SBox 'data9'
    $opencodeDir9 = Join-Path $targetHome9 '.config\opencode'
    $backupRoot9 = Join-Path $xdgData9 'opencodeWizard\backups'
    New-Item -ItemType Directory -Force -Path $opencodeDir9 | Out-Null
    '{"state": "initial"}' | Set-Content (Join-Path $opencodeDir9 'opencode.jsonc')
    $global:BackupDir = $backupRoot9
    $global:MaxBackups = 15
    Set-Variable -Name HOME -Value $targetHome9 -Scope Global -Force
    $global:BackupId = $null
    try { Create-Backup } finally { Set-Variable -Name HOME -Value $oldHome -Scope Global -Force }
    $count9a = @(Get-ChildItem -Directory -Path $backupRoot9 -ErrorAction SilentlyContinue).Count
    Write-Host "    [debug] after 1st: count=$count9a, dirs=$((Get-ChildItem -Directory $backupRoot9 -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) -join ',')"
    Start-Sleep -Seconds 2.5
    $global:BackupId = $null
    Set-Variable -Name HOME -Value $targetHome9 -Scope Global -Force
    try { Create-Backup } finally { Set-Variable -Name HOME -Value $oldHome -Scope Global -Force }
    $count9b = @(Get-ChildItem -Directory -Path $backupRoot9 -ErrorAction SilentlyContinue).Count
    Write-Host "    [debug] after 2nd: count=$count9b, dirs=$((Get-ChildItem -Directory $backupRoot9 -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) -join ',')"
    '{"state": "modified"}' | Set-Content (Join-Path $opencodeDir9 'opencode.jsonc')
    Start-Sleep -Seconds 2.5
    $global:BackupId = $null
    Set-Variable -Name HOME -Value $targetHome9 -Scope Global -Force
    try { Create-Backup } finally { Set-Variable -Name HOME -Value $oldHome -Scope Global -Force }
    $count9c = @(Get-ChildItem -Directory -Path $backupRoot9 -ErrorAction SilentlyContinue).Count
    $ok9 = $true
    if ($count9a -ne 1) { Test-Failed 'test_content_hash_dedup' "Expected 1 after 1st create, got $count9a"; $ok9 = $false }
    if ($count9b -ne 1) { Test-Failed 'test_content_hash_dedup' "DEDUP REGRESSION: expected 1 (unchanged), got $count9b"; $ok9 = $false }
    if ($count9c -ne 2) { Test-Failed 'test_content_hash_dedup' "Expected 2 after content change, got $count9c"; $ok9 = $false }
    if ($ok9) {
        $newest9 = Get-ChildItem -Directory -Path $backupRoot9 | Sort-Object Name | Select-Object -Last 1
        $manifestPath9 = Join-Path $newest9.FullName 'manifest.txt'
        $manifestContent9 = Get-Content $manifestPath9
        if (-not ($manifestContent9 | Where-Object { $_ -match '^CONTENT_HASH=' })) {
            Test-Failed 'test_content_hash_dedup' "Manifest missing CONTENT_HASH: $manifestPath9"
            $ok9 = $false
        }
    }
    if ($ok9) { Test-Passed 'test_content_hash_dedup' }

    # --- Test 10: BACKUP_ID collision gets _2 suffix, never overwrites ---
    Write-Host ''
    Write-Host 'Test: test_collision_suffix'
    $targetHome10 = Join-Path $SBox 'home10'
    $xdgData10 = Join-Path $SBox 'data10'
    $opencodeDir10 = Join-Path $targetHome10 '.config\opencode'
    $backupRoot10 = Join-Path $xdgData10 'opencodeWizard\backups'
    New-Item -ItemType Directory -Force -Path $opencodeDir10 | Out-Null
    '{"user": "collision-test"}' | Set-Content (Join-Path $opencodeDir10 'opencode.jsonc')
    $scriptHash10 = 'local'
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $gh = git -C (Split-Path -Parent $Script) rev-parse --short HEAD 2>$null
            if ($gh) { $scriptHash10 = $gh }
        }
    } catch {}
    $frozenId10 = "ocw-${scriptHash10}-20200101-000000"
    $frozenDir10 = Join-Path $backupRoot10 $frozenId10
    New-Item -ItemType Directory -Force -Path $frozenDir10 | Out-Null
    'PRE-EXISTING - must not be touched' | Set-Content (Join-Path $frozenDir10 'marker.txt')

    # Override Get-Date so Generate-BackupId always returns the same timestamp.
    $originalGetDate = Get-Item function:Get-Date -ErrorAction SilentlyContinue
    function Global:Get-Date {
        param([string]$Format)
        if ($Format -eq 'yyyyMMdd-HHmmss') { return '20200101-000000' }
        if ([string]::IsNullOrEmpty($Format)) { Microsoft.PowerShell.Utility\Get-Date }
        else { Microsoft.PowerShell.Utility\Get-Date -Format $Format }
    }

    $global:BackupDir = $backupRoot10
    $global:BackupId = $null
    $global:MaxBackups = 15
    Set-Variable -Name HOME -Value $targetHome10 -Scope Global -Force
    try { Create-Backup } finally { Set-Variable -Name HOME -Value $oldHome -Scope Global -Force }

    if ($originalGetDate) { Set-Item function:Get-Date -Value $originalGetDate.ScriptBlock }
    else { Remove-Item function:Get-Date -ErrorAction SilentlyContinue }

    $marker10 = Get-Content (Join-Path $frozenDir10 'marker.txt') -ErrorAction SilentlyContinue
    $suffixDir10 = Join-Path $backupRoot10 "${frozenId10}_2"
    $ok10 = $true
    if ($marker10 -notmatch 'PRE-EXISTING') {
        Test-Failed 'test_collision_suffix' "COLLISION REGRESSION: pre-existing backup was overwritten (marker=$marker10)"
        $ok10 = $false
    }
    if (-not (Test-Path $suffixDir10)) {
        Test-Failed 'test_collision_suffix' "COLLISION REGRESSION: expected ${frozenId10}_2, not found"
        $ok10 = $false
    }
    if ($ok10) { Test-Passed 'test_collision_suffix' }

    # --- Test 11: End-to-end - run wizard with -MergeBackup pointing at fixture ---
    Write-Host ''
    Write-Host 'Test: test_merge_flag_end_to_end'
    $targetHome = Join-Path $SBox 'home'
    $configDir = Join-Path $targetHome '.config\opencode'
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    @'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "dark"
}
'@ | Set-Content (Join-Path $configDir 'opencode.jsonc')
    $env:USERPROFILE = $targetHome
    $env:BackupRoot = $null
    & $Script -Silent -MergeBackup $Fixture 2>&1 | Out-Null
    $cfgFile = Join-Path $configDir 'opencode.jsonc'
    if (-not (Test-Path $cfgFile)) {
        Test-Failed 'test_merge_flag_end_to_end' 'Target config file was not created'
    } elseif (-not (Select-String -Path $cfgFile -Pattern 'field_from_backup' -Quiet)) {
        Test-Failed 'test_merge_flag_end_to_end' 'End-to-end: -MergeBackup did not merge JSON field'
    } else {
        Test-Passed 'test_merge_flag_end_to_end'
    }

    Write-Host ''
    Write-Host '========================================='
    Write-Host ' Results'
    Write-Host '========================================='
    Write-Host "  Passed: $($script:TestsPassed)"
    Write-Host "  Failed: $($script:TestsFailed)"
    if ($script:FailedTests.Count -gt 0) {
        Write-Host '  Failed tests:'
        foreach ($t in $script:FailedTests) {
            Write-Host "    - $t"
        }
    }
    Write-Host '========================================='
} finally {
    if (Test-Path $SBox) {
        Remove-Item -Recurse -Force $SBox -ErrorAction SilentlyContinue
    }
}

# Red phase: any failure => exit 1. Green phase: all pass => exit 0.
if ($script:TestsFailed -eq 0) { exit 0 } else { exit 1 }
