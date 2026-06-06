#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SCRIPT_DIR/config/variables.conf"

run_macos_mock_test() {
    echo ">>> Testing macOS Mock (Dry-Run)"
    OCW_FORCE_OS=macos ./OpenCodeWizard.sh --silent --dry-run
}

# Run PowerShell Syntax Check
run_powershell_syntax_check() {
    echo ">>> Testing PowerShell Syntax"
    docker run --rm -v "$(pwd):/app:ro" mcr.microsoft.com/powershell:latest pwsh -Command "
        \$errors = @()
        \$tokens = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw /app/OpenCodeWizard.ps1), [ref]\$errors)
        if (\$errors.Count -eq 0) {
            Write-Host 'Syntax OK'
        } else {
            Write-Error 'Syntax Error'
            exit 1
        }
    "
}

run_linux_test() {
    local distro=$1
    local preset=$2
    echo ">>> Testing Linux ($distro) with preset: $preset"
    docker run --rm -v "$(pwd):/app" "$distro" bash -c "
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y sudo git nodejs npm curl unzip
        elif command -v dnf &>/dev/null; then
            dnf install -y sudo git nodejs npm curl unzip
        elif command -v pacman &>/dev/null; then
            pacman -Sy --noconfirm sudo git nodejs npm curl unzip
        fi
        cd /app
        chmod +x OpenCodeWizard.sh tests/verify_install.sh
        ./OpenCodeWizard.sh --silent $preset
        ./tests/verify_install.sh
    "
}

case "${1:-}" in
    ubuntu) run_linux_test "ubuntu:latest" "${2:-developer}" ;;
    fedora) run_linux_test "fedora:latest" "${2:-developer}" ;;
    arch)   run_linux_test "archlinux:latest" "${2:-developer}" ;;
    powershell) run_powershell_syntax_check ;;
    macos)      run_macos_mock_test ;;
    *)
        run_powershell_syntax_check
        run_macos_mock_test
        for preset in "$PRESET_DEVELOPER" "$PRESET_STANDARD" "$PRESET_MINIMAL"; do
            run_linux_test "ubuntu:latest" "$preset"
            run_linux_test "fedora:latest" "$preset"
            run_linux_test "archlinux:latest" "$preset"
        done
        ;;
esac
