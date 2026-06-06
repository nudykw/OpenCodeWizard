#!/usr/bin/env bash

# ==============================================================================
# OpenCodeWizard Verification Script (In-Container)
# ==============================================================================
# This script runs inside the Docker container to verify that the installation
# and configuration by OpenCodeWizard.sh was successful.
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;37m'
BOLD='\033[1m'

log_info() { echo -e "${BLUE}${BOLD}[VERIFY-INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}${BOLD}[VERIFY-WARNING]${NC} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[VERIFY-SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[VERIFY-ERROR]${NC} $1"; }

errors=0

# 1. Verify WezTerm Installation
log_info "Verifying WezTerm installation..."
if command -v wezterm &>/dev/null; then
    wez_ver=$(wezterm --version 2>&1 || true)
    log_success "WezTerm is installed: $wez_ver"
else
    log_error "WezTerm is NOT installed or not in PATH."
    ((errors++))
fi

# 2. Verify OpenCode CLI Installation
log_info "Verifying OpenCode CLI installation..."
if command -v opencode &>/dev/null; then
    opencode_ver=$(opencode --version 2>&1 || true)
    log_success "OpenCode CLI is installed: $opencode_ver"
else
    log_error "OpenCode CLI is NOT installed or not in PATH."
    ((errors++))
fi

# 3. Verify OpenCode Configuration File
log_info "Verifying OpenCode configuration..."
config_file="$HOME/.config/opencode/opencode.jsonc"
if [ -f "$config_file" ]; then
    log_success "OpenCode config file exists at $config_file"
    
    # Check for the correct plugin name (searching within the "plugin" array context)
    if grep -q "\"oh-my-openagent\"" "$config_file" || grep -q "\"oh-my-opencode\"" "$config_file"; then
        log_success "✔ Config contains 'oh-my-openagent' or 'oh-my-opencode'"
    else
        log_error "✘ Config is missing 'oh-my-openagent' or 'oh-my-opencode' plugin entry!"
        ((errors++))
    fi
    
    # Check schema and mcp
    if grep -q "config.json" "$config_file" && grep -q "mcp" "$config_file"; then
        log_success "✔ Schema and MCP structure exist in config"
    else
        log_error "✘ Missing schema or MCP structure in config"
        ((errors++))
    fi
else
    log_error "OpenCode config file is missing!"
    ((errors++))
fi

# 4. Verify WezTerm Configuration File
log_info "Verifying WezTerm configuration..."
wez_config="$HOME/.config/wezterm/wezterm.lua"
if [ -f "$wez_config" ]; then
    log_success "WezTerm config file exists at $wez_config"
    if grep -q "Catppuccin Mocha" "$wez_config"; then
        log_success "✔ WezTerm config contains 'Catppuccin Mocha' color scheme"
    else
        log_error "✘ WezTerm config is missing color scheme setup!"
        ((errors++))
    fi
else
    log_error "WezTerm config file is missing!"
    ((errors++))
fi

# 5. Verify Bash RC exports
log_info "Verifying shell configurations..."
if [ -f "$HOME/.bashrc" ]; then
    if grep -q "export TERMINAL=wezterm" "$HOME/.bashrc"; then
        log_success "✔ export TERMINAL=wezterm found in ~/.bashrc"
    else
        log_error "✘ export TERMINAL=wezterm NOT found in ~/.bashrc"
        ((errors++))
    fi
    if grep -q "export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true" "$HOME/.bashrc"; then
        log_success "✔ export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true found in ~/.bashrc"
    else
        log_warning "export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true NOT found in ~/.bashrc"
    fi
else
    log_warning "\$HOME/.bashrc file does not exist (skipping check)."
fi

# 6. Verify Desktop shortcut
log_info "Verifying desktop shortcut..."
desktop_file="$HOME/Desktop/OpenCode.desktop"
if [ -d "$HOME/Desktop" ]; then
    if [ -f "$desktop_file" ]; then
        log_success "✔ Desktop shortcut created at $desktop_file"
        if [ -x "$desktop_file" ]; then
            log_success "✔ Desktop shortcut is executable"
        else
            log_error "✘ Desktop shortcut is NOT executable!"
            ((errors++))
        fi
        if grep -q "Exec=wezterm start --" "$desktop_file" && grep -q "opencode" "$desktop_file"; then
            log_success "✔ Desktop shortcut Exec target is correct"
        else
            log_error "✘ Desktop shortcut Exec target is incorrect!"
            ((errors++))
        fi
    else
        log_error "✘ Desktop shortcut was NOT created!"
        ((errors++))
    fi
else
    log_info "No Desktop directory found (headless environment), skipping shortcut check."
fi

# 7. Verify OpenCode Query Execution
log_info "Verifying OpenCode query execution..."
if response=$(opencode run "привіт" --model opencode/deepseek-v4-flash-free 2>&1); then
    log_success "✔ OpenCode successfully replied: $(echo "$response" | tr '\n' ' ')"
else
    log_error "✘ OpenCode failed to execute query: $response"
    ((errors++))
fi

# Summary
echo -e "\n========================================="
if [ $errors -eq 0 ]; then
    log_success "ALL VERIFICATIONS PASSED IN CONTAINER!"
    exit 0
else
    log_error "$errors verification error(s) found."
    exit 1
fi
