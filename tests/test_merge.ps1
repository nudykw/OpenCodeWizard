<#
.SYNOPSIS
    TDD tests for config-merge feature (PowerShell)
.DESCRIPTION
    Red phase: exit 1 until Merge-ShellConfigs and -MergeBackup are implemented.
    Run: pwsh -File tests/test_merge.ps1
#>

$ErrorActionPreference = 'Continue'

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
    'Smart-Merge'
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

    # --- Test 7: End-to-end - run wizard with -MergeBackup pointing at fixture ---
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
