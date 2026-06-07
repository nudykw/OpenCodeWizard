#!/usr/bin/env bash
# TDD tests for config-merge feature
# Red phase: exit 1 until merge_shell_configs and --merge-backup flag are implemented.
#
# Run: bash tests/test_merge.sh
# Expected during Red phase: exit 1 (tests fail because features don't exist).
# Expected after Green phase: exit 0 (all tests pass).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PROJECT_DIR/OpenCodeWizard.sh"
FIXTURE="$TESTS_DIR/fixtures/backup1"

# Sanity check: fixture must exist (Task 1 QA).
if [ ! -f "$FIXTURE/opencode.jsonc" ] || [ ! -f "$FIXTURE/wezterm.lua" ] \
   || [ ! -f "$FIXTURE/bashrc" ] || [ ! -f "$FIXTURE/zshrc" ] \
   || [ ! -f "$FIXTURE/Microsoft.PowerShell_profile.ps1" ]; then
    echo "FAIL: fixtures missing in $FIXTURE"
    exit 1
fi

# Stub for log_warning used by merge_json_configs fallback (no-op in tests).
log_warning() { echo "WARN: $*" >&2; }

# Extract merge function definitions from the main script (skip main() call).
MERGE_SRC=$(
    awk '
        /^# Smart Merge:/            { capture=1 }
        /^# Verify setup$/          { capture=0 }
        capture { print }
    ' "$SCRIPT" | grep -v '^# '
)

# Source the extracted merge functions.
# shellcheck disable=SC1090
eval "$MERGE_SRC"

# Sandbox for tests
SBOX=$(mktemp -d)
trap 'rm -rf "$SBOX"' EXIT

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# assert_grep <file> <pattern> <message>
assert_grep() {
    local file="$1" pattern="$2" msg="$3"
    if grep -qE "$pattern" "$file"; then
        return 0
    fi
    echo "  ASSERT FAILED: $msg"
    echo "    File: $file"
    echo "    Pattern: $pattern"
    return 1
}

# assert_not_grep <file> <pattern> <message>
assert_not_grep() {
    local file="$1" pattern="$2" msg="$3"
    if ! grep -qE "$pattern" "$file"; then
        return 0
    fi
    echo "  ASSERT FAILED: $msg (pattern found but should be absent)"
    echo "    File: $file"
    echo "    Pattern: $pattern"
    return 1
}

# Run a test, capture failures.
run_test() {
    local name="$1"
    echo ""
    echo "▶ Test: $name"
    if "$@"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ✓ $name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$name")
        echo "  ✗ $name"
    fi
}

# --- Test 1: JSON merge preserves backup fields (backup-wins) ---
test_json_merge() {
    local old_file="$SBOX/old.jsonc"
    local new_file="$SBOX/new.jsonc"

    cp "$FIXTURE/opencode.jsonc" "$old_file"

    cat > "$new_file" <<'JSON'
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
JSON

    if ! type merge_json_configs >/dev/null 2>&1; then
        echo "  REGRESSION: merge_json_configs missing"
        return 1
    fi

    merge_json_configs "$old_file" "$new_file"

    assert_grep "$new_file" 'field_from_backup' \
        "Backup field 'field_from_backup' must be preserved (backup-wins)" || return 1
    assert_grep "$new_file" 'user-custom-mcp' \
        "Backup MCP 'user-custom-mcp' must be preserved" || return 1
    assert_grep "$new_file" 'wizard-only-mcp' \
        "Wizard's new MCP entry 'wizard-only-mcp' must be added" || return 1
}

# --- Test 2: Lua merge preserves backup customizations ---
test_lua_merge() {
    local old_file="$SBOX/old.lua"
    local new_file="$SBOX/new.lua"

    cp "$FIXTURE/wezterm.lua" "$old_file"

    cat > "$new_file" <<'LUA'
-- === OpenCode Wizard ===
return {
  color_scheme = "Catppuccin Mocha",
  font_size = 12.0,
}
LUA

    if ! type merge_lua_configs >/dev/null 2>&1; then
        echo "  REGRESSION: merge_lua_configs missing"
        return 1
    fi

    merge_lua_configs "$old_file" "$new_file"

    assert_grep "$new_file" 'user-custom-event' \
        "Backup custom event 'user-custom-event' must be preserved" || return 1
    assert_grep "$new_file" 'Catppuccin Mocha' \
        "Wizard's new color scheme 'Catppuccin Mocha' must be added" || return 1
}

# --- Test 3: Shell config merge function exists (Red: should FAIL) ---
test_shell_merge_function_exists() {
    if ! type merge_shell_configs >/dev/null 2>&1; then
        echo "  RED: merge_shell_configs function is not implemented yet"
        return 1
    fi
}

# --- Test 4: Shell merge preserves backup vars and adds wizard vars ---
test_shell_merge() {
    local old_file="$SBOX/old.bashrc"
    local new_file="$SBOX/new.bashrc"

    cp "$FIXTURE/bashrc" "$old_file"

    cat > "$new_file" <<'BASH'
# Wizard-managed section
export TERMINAL=wezterm
export OPENCODE_AGENTS_SWITCH_SINGLE_MODEL=true
BASH

    if ! type merge_shell_configs >/dev/null 2>&1; then
        echo "  RED: merge_shell_configs function is not implemented yet"
        return 1
    fi

    merge_shell_configs "$old_file" "$new_file"

    assert_grep "$new_file" 'MY_CUSTOM_VAR' \
        "Backup shell var 'MY_CUSTOM_VAR' must be preserved" || return 1
    assert_grep "$new_file" 'TERMINAL=wezterm' \
        "Wizard's new export 'TERMINAL=wezterm' must be added" || return 1
}

# --- Test 5: Idempotency - re-running merge does not duplicate lines ---
test_shell_idempotency() {
    local old_file="$SBOX/old.bashrc"
    local new_file="$SBOX/new.bashrc"

    cp "$FIXTURE/bashrc" "$old_file"

    cat > "$new_file" <<'BASH'
export TERMINAL=wezterm
BASH

    if ! type merge_shell_configs >/dev/null 2>&1; then
        echo "  RED: merge_shell_configs function is not implemented yet"
        return 1
    fi

    # First merge
    merge_shell_configs "$old_file" "$new_file"
    local count1
    count1=$(grep -c '^export TERMINAL=wezterm' "$new_file" || true)

    # Second merge on the result
    merge_shell_configs "$new_file" "$new_file"
    local count2
    count2=$(grep -c '^export TERMINAL=wezterm' "$new_file" || true)

    if [ "$count1" != "$count2" ]; then
        echo "  Idempotency broken: $count1 lines after 1st merge, $count2 after 2nd"
        return 1
    fi
}

# --- Test 6: --merge-backup flag is documented in help ---
test_merge_flag_in_help() {
    local help_output
    help_output=$("$SCRIPT" --help 2>&1 || true)
    if ! echo "$help_output" | grep -q -- "--merge-backup"; then
        echo "  RED: --merge-backup flag is not in --help output"
        return 1
    fi
}

# --- Test 7: --merge-backup flag actually triggers merge on a fixture path ---
# This is the end-to-end test: run the wizard with the flag and a real fixture.
test_merge_flag_end_to_end() {
    local target_home="$SBOX/home"
    mkdir -p "$target_home/.config/opencode"

    # Seed a "current" config that does NOT have the backup field
    cat > "$target_home/.config/opencode/opencode.jsonc" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "dark"
}
JSON

    # Run the wizard with --merge-backup pointing at our fixture
    # Use HOME=target so the wizard reads/writes inside the sandbox
    HOME="$target_home" XDG_CONFIG_HOME="$target_home/.config" \
        "$SCRIPT" --silent --merge-backup "$FIXTURE" 2>&1 || true

    # The merge should have added the backup's "field_from_backup"
    if [ ! -f "$target_home/.config/opencode/opencode.jsonc" ]; then
        echo "  Target config file was not created"
        return 1
    fi

    assert_grep "$target_home/.config/opencode/opencode.jsonc" 'field_from_backup' \
        "End-to-end: --merge-backup did not merge JSON field" || return 1
}

# Run all tests
echo "========================================="
echo " config-merge TDD Test Suite (Bash)"
echo "========================================="

run_test test_json_merge
run_test test_lua_merge
run_test test_shell_merge_function_exists
run_test test_shell_merge
run_test test_shell_idempotency
run_test test_merge_flag_in_help
run_test test_merge_flag_end_to_end

echo ""
echo "========================================="
echo " Results"
echo "========================================="
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo "  Failed tests:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "    - $t"
    done
fi
echo "========================================="

# Red phase: any failure => exit 1. Green phase: all pass => exit 0.
[ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
