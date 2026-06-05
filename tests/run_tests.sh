#!/usr/bin/env bash

# ==============================================================================
# OpenCodeWizard Test Runner
# ==============================================================================
# Runs automated tests inside Docker containers for Ubuntu, Fedora, Arch Linux,
# checks PowerShell syntax, and runs linters (shellcheck, markdownlint,
# PSScriptAnalyzer).
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;37m'
BOLD='\033[1m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED_TESTS=0
POST_PUSH=false

# ==============================================================================
# Help
# ==============================================================================
show_help() {
    echo -e "${BOLD}OpenCodeWizard Test Runner${NC}"
    echo -e "Usage: $0 [OPTIONS] [TARGETS...]"
    echo -e ""
    echo -e "${BOLD}TARGETS (default: all):${NC}"
    echo -e "  ubuntu          Test installation on ubuntu:latest"
    echo -e "  fedora          Test installation on fedora:latest"
    echo -e "  arch            Test installation on archlinux:latest"
    echo -e "  powershell      Check PowerShell syntax via Docker"
    echo -e "  lint            Run all linters (shellcheck + markdownlint + PSScriptAnalyzer)"
    echo -e "  lint-sh         Run shellcheck on all .sh files"
    echo -e "  lint-md         Run markdownlint-cli2 on all .md files"
    echo -e "  lint-ps1        Run PSScriptAnalyzer on .ps1 files via Docker"
    echo -e ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  --post-push     Clone repo from GitHub instead of using local copy"
    echo -e "  -h, --help      Show this help message"
    echo -e ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  $0                              # run all tests"
    echo -e "  $0 ubuntu                       # only Ubuntu"
    echo -e "  $0 ubuntu fedora                # Ubuntu + Fedora"
    echo -e "  $0 lint                         # only linters"
    echo -e "  $0 lint-sh ubuntu               # shellcheck + Ubuntu test"
    echo -e "  $0 --post-push arch             # Arch test from GitHub"
    exit 0
}

# ==============================================================================
# Parse arguments
# ==============================================================================
TARGETS=()

for arg in "$@"; do
    case "$arg" in
        -h|--help)   show_help ;;
        --post-push) POST_PUSH=true ;;
        ubuntu|fedora|arch|powershell) TARGETS+=("$arg") ;;
        lint)   TARGETS+=("lint-sh" "lint-md" "lint-ps1") ;;
        lint-sh|lint-md|lint-ps1) TARGETS+=("$arg") ;;
        *)
            echo -e "${RED}Unknown target: $arg${NC}"
            show_help
            ;;
    esac
done

# Default: run everything
if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS=("lint-sh" "lint-md" "lint-ps1" "ubuntu" "fedora" "arch" "powershell")
fi

# ==============================================================================
# Helpers
# ==============================================================================
log_header() {
    echo -e "\n${BLUE}${BOLD}================================================================${NC}"
    echo -e "${BLUE}${BOLD}>>> $1${NC}"
    echo -e "${BLUE}${BOLD}================================================================${NC}\n"
}

log_success() { echo -e "${GREEN}${BOLD}[TEST-PASS]${NC} $1"; }
log_error()   { echo -e "${RED}${BOLD}[TEST-FAIL]${NC} $1"; }
log_info()    { echo -e "${YELLOW}[TEST-INFO]${NC} $1"; }

require_docker() {
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed or not in PATH."
        exit 1
    fi
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running or current user has no permissions."
        exit 1
    fi
}

# ==============================================================================
# Linters
# ==============================================================================
run_lint_sh() {
    log_header "Linting: shellcheck (.sh files)"
    if ! command -v shellcheck &>/dev/null; then
        echo -e "${YELLOW}[SKIP]${NC} shellcheck not found. Install: sudo apt install shellcheck"
        return 0
    fi
    local sh_files
    mapfile -t sh_files < <(find "$PROJECT_DIR" -name "*.sh" -not -path "*/.git/*")
    if shellcheck --severity=warning "${sh_files[@]}"; then
        log_success "shellcheck passed"
    else
        log_error "shellcheck FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

run_lint_md() {
    log_header "Linting: markdownlint-cli2 (.md files)"
    if ! command -v markdownlint-cli2 &>/dev/null; then
        echo -e "${YELLOW}[SKIP]${NC} markdownlint-cli2 not found. Install: npm install -g markdownlint-cli2"
        return 0
    fi
    if (cd "$PROJECT_DIR" && markdownlint-cli2 "**/*.md" "#node_modules"); then
        log_success "markdownlint-cli2 passed"
    else
        log_error "markdownlint-cli2 FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

run_lint_ps1() {
    log_header "Linting: PSScriptAnalyzer (OpenCodeWizard.ps1) via Docker"
    require_docker
    log_info "Running PSScriptAnalyzer in Docker (first run may pull image)..."
    if docker run --rm \
        -v "${PROJECT_DIR}:/app:ro" \
        mcr.microsoft.com/powershell pwsh -Command "
            Install-Module PSScriptAnalyzer -Force -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
            \$results = Invoke-ScriptAnalyzer -Path /app/OpenCodeWizard.ps1 -Severity Error,Warning
            if (\$results) {
                \$results | ForEach-Object { Write-Error \$_ }
                exit 1
            }
            Write-Host 'PSScriptAnalyzer: no issues found'
            exit 0
        "; then
        log_success "PSScriptAnalyzer passed"
    else
        log_error "PSScriptAnalyzer FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# ==============================================================================
# Distro tests
# ==============================================================================
run_distro_test() {
    local distro="$1"
    local base_image="$2"
    local prep_cmd="$3"

    log_header "Testing on $distro ($base_image)"
    log_info "Starting container, installing prerequisites, running installation..."

    local clone_source="/src/OpenCodeWizard"
    local copy_cmd=""
    if [ "$POST_PUSH" = "false" ]; then
        copy_cmd="cp -rp /src/OpenCodeWizard/. /app/"
    else
        clone_source="https://github.com/nudykw/OpenCodeWizard.git"
        log_info "Will clone from GitHub: $clone_source"
    fi

    if docker run --rm \
        -v "${PROJECT_DIR}:/src/OpenCodeWizard:ro" \
        "$base_image" \
        sh -c "
            set -eu
            $prep_cmd
            log_info() { echo \"[TEST-PREP] \$*\"; }
            log_info 'Cloning repository...'
            git config --global --add safe.directory '*'
            git clone $clone_source /app
            $copy_cmd
            cd /app
            mkdir -p \$HOME/Desktop
            log_info 'Running OpenCodeWizard.sh --silent...'
            ./OpenCodeWizard.sh --silent
            log_info 'Running verification script...'
            ./tests/verify_install.sh
        "; then
        log_success "$distro test PASSED"
    else
        log_error "$distro test FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

run_powershell_syntax_test() {
    log_header "Testing PowerShell Script Syntax"
    require_docker
    log_info "Launching PowerShell Core container to parse OpenCodeWizard.ps1..."

    if docker run --rm \
        -v "${PROJECT_DIR}:/app:ro" \
        mcr.microsoft.com/powershell:latest pwsh -Command "
            \$errors = \$null
            [System.Management.Automation.Language.Parser]::ParseFile('/app/OpenCodeWizard.ps1', [ref]\$null, [ref]\$errors)
            if (\$errors) {
                \$errors | ForEach-Object { Write-Error \$_ }
                exit 1
            }
            Write-Host 'OpenCodeWizard.ps1 syntax is valid!'
            exit 0
        "; then
        log_success "PowerShell syntax test PASSED"
    else
        log_error "PowerShell syntax test FAILED"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# ==============================================================================
# Run selected targets
# ==============================================================================
# De-duplicate targets (lint expands to lint-sh lint-md lint-ps1)
declare -A seen
unique_targets=()
for t in "${TARGETS[@]}"; do
    if [ -z "${seen[$t]+_}" ]; then
        unique_targets+=("$t")
        seen[$t]=1
    fi
done

for target in "${unique_targets[@]}"; do
    case "$target" in
        lint-sh)    run_lint_sh ;;
        lint-md)    run_lint_md ;;
        lint-ps1)   run_lint_ps1 ;;
        ubuntu)
            require_docker
            run_distro_test "Ubuntu" "ubuntu:latest" \
                "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo curl git nodejs npm"
            ;;
        fedora)
            require_docker
            run_distro_test "Fedora" "fedora:latest" \
                "dnf install -y sudo curl git nodejs npm"
            ;;
        arch)
            require_docker
            run_distro_test "Arch Linux" "archlinux:latest" \
                "pacman -Syu --noconfirm && pacman -S --noconfirm sudo curl git nodejs npm"
            ;;
        powershell)
            require_docker
            run_powershell_syntax_test
            ;;
    esac
done

# ==============================================================================
# Summary
# ==============================================================================
log_header "Test Execution Summary"
if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests completed successfully!"
    exit 0
else
    log_error "$FAILED_TESTS test suite(s) failed."
    exit 1
fi
