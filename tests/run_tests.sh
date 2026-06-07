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

    # Map distro short name to pre-built image tag
    local test_image="ocw-test:$distro"
    local distro_file="tests/Dockerfile.test"
    local base_image=""
    case "$distro" in
        ubuntu)  base_image="ubuntu:24.04" ;;
        fedora)  base_image="fedora:40" ;;
        arch)    base_image="archlinux:latest" ;;
        *)       echo "[ERROR] Unknown distro: $distro" >&2; return 1 ;;
    esac

    # Build pre-built image if missing
    if ! docker image inspect "$test_image" &>/dev/null; then
        echo ">>> Building pre-built image: $test_image (base: $base_image)"
        docker build --build-arg "DISTRO=$base_image" -t "$test_image" -f "$distro_file" .
    fi

    echo ">>> Testing Linux ($distro) with preset: $preset"
    docker run --rm -v "$(pwd):/app" "$test_image" bash -c "
        cd /app
        chmod +x OpenCodeWizard.sh tests/verify_install.sh
        ./OpenCodeWizard.sh --silent $preset
        ./tests/verify_install.sh
    "
}

case "${1:-}" in
    ubuntu)     run_linux_test "ubuntu" "${2:-developer}" ;;
    fedora)     run_linux_test "fedora" "${2:-developer}" ;;
    arch)       run_linux_test "arch"   "${2:-developer}" ;;
    powershell) run_powershell_syntax_check ;;
    macos)      run_macos_mock_test ;;
    *)
        run_powershell_syntax_check
        run_macos_mock_test
        for preset in "$PRESET_DEVELOPER" "$PRESET_STANDARD" "$PRESET_MINIMAL"; do
            run_linux_test "ubuntu" "$preset"
            run_linux_test "fedora" "$preset"
            run_linux_test "arch"   "$preset"
        done
        ;;
esac
