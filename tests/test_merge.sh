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

# --- Test 7: create_backup is idempotent within a session (regression) ---
# Regression: a second create_backup call in the same session (e.g. from
# configure_wezterm after configure_opencode) was overwriting the
# opencode.jsonc backup with the wizard's just-written default, so
# smart_merge then saw backup == target and wrongly reported "no changes".
test_create_backup_idempotent() {
    local target_home="$SBOX/home7"
    local xdg_data="$SBOX/data7"
    local opencode_cfg_dir="$target_home/.config/opencode"
    local opencode_cfg="$opencode_cfg_dir/opencode.jsonc"
    local sysinfo="$opencode_cfg_dir/system_info.md"

    mkdir -p "$opencode_cfg_dir"

    cat > "$opencode_cfg" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": "llamaserver",
  "user_custom_field": "user-preserved-data"
}
JSON
    cat > "$sysinfo" <<'MD'
# System Info (original user version)
MD

    # Stage 1: configure_opencode calls create_backup (BEFORE writing default).
    HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        BACKUP_ID="" BACKUP_DIR="$xdg_data/opencodeWizard/backups" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    local backup_id
    backup_id=$(ls -1 "$xdg_data/opencodeWizard/backups" 2>/dev/null | head -1)
    if [ -z "$backup_id" ]; then
        echo "  Backup directory was not created"
        return 1
    fi
    local backup_path="$xdg_data/opencodeWizard/backups/$backup_id"

    if [ ! -f "$backup_path/opencode.jsonc" ]; then
        echo "  First backup did not capture opencode.jsonc"
        return 1
    fi
    assert_grep "$backup_path/opencode.jsonc" 'user-preserved-data' \
        "First backup must contain user's original (LLAMA) data" || return 1

    # Stage 2: configure_opencode overwrites user's file with wizard default.
    cat > "$opencode_cfg" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "system",
  "mcp": {}
}
JSON
    cat > "$sysinfo" <<'MD'
# System Info (wizard-default version)
MD

    # Stage 3: configure_wezterm calls create_backup again — must NOT overwrite.
    HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        BACKUP_ID="$backup_id" BACKUP_DIR="$xdg_data/opencodeWizard/backups" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    assert_grep "$backup_path/opencode.jsonc" 'user-preserved-data' \
        "REGRESSION: backup was overwritten by 2nd create_backup call (bug)" \
        || return 1
    assert_not_grep "$backup_path/opencode.jsonc" '"theme": "system"' \
        "REGRESSION: backup contains wizard's default instead of user's original" \
        || return 1
    assert_grep "$backup_path/system_info.md" 'original user version' \
        "REGRESSION: system_info.md backup was overwritten" || return 1
}

# --- Test 8: MAX_BACKUPS=15 auto-prunes oldest ---
test_max_backups_prunes_oldest() {
    local target_home="$SBOX/home8"
    local xdg_data="$SBOX/data8"
    local opencode_cfg_dir="$target_home/.config/opencode"
    local opencode_cfg="$opencode_cfg_dir/opencode.jsonc"
    local backup_root="$xdg_data/opencodeWizard/backups"

    mkdir -p "$opencode_cfg_dir"
    cat > "$opencode_cfg" <<'JSON'
{"user": "max-backups-test"}
JSON

    # Pre-create 16 fake "old" backup dirs with sortable, monotonically increasing names.
    for i in $(seq -w 1 16); do
        mkdir -p "$backup_root/ocw-test-20200101-0000${i}"
    done

    HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        MAX_BACKUPS=15 \
        BACKUP_ID="" BACKUP_DIR="$backup_root" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    local count
    count=$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "$count" -ne 15 ]; then
        echo "  Expected 15 backup dirs after prune, got $count"
        return 1
    fi
    if [ -d "$backup_root/ocw-test-20200101-000001" ]; then
        echo "  Oldest backup was NOT pruned"
        return 1
    fi
    if [ ! -d "$backup_root/ocw-test-20200101-000003" ]; then
        echo "  A backup that should have been kept was pruned"
        return 1
    fi
}

# --- Test 9: content-hash dedup skips redundant backups ---
test_content_hash_dedup() {
    local target_home="$SBOX/home9"
    local xdg_data="$SBOX/data9"
    local opencode_cfg_dir="$target_home/.config/opencode"
    local opencode_cfg="$opencode_cfg_dir/opencode.jsonc"
    local backup_root="$xdg_data/opencodeWizard/backups"

    mkdir -p "$opencode_cfg_dir"
    cat > "$opencode_cfg" <<'JSON'
{"state": "initial"}
JSON

    HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        MAX_BACKUPS=15 BACKUP_ID="" BACKUP_DIR="$backup_root" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    local count1
    count1=$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "$count1" -ne 1 ]; then
        echo "  Expected 1 backup after first create, got $count1"
        return 1
    fi

    sleep 2.5
    HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        MAX_BACKUPS=15 BACKUP_ID="" BACKUP_DIR="$backup_root" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    local count2
    count2=$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "$count2" -ne 1 ]; then
        echo "  DEDUP REGRESSION: expected 1 backup (unchanged content), got $count2"
        return 1
    fi

    # Modify content → next backup should be created.
    cat > "$opencode_cfg" <<'JSON'
{"state": "modified"}
JSON
    sleep 2.5
    HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        MAX_BACKUPS=15 BACKUP_ID="" BACKUP_DIR="$backup_root" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    local count3
    count3=$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    if [ "$count3" -ne 2 ]; then
        echo "  Expected 2 backups after content change, got $count3"
        return 1
    fi

    # The most-recent backup's manifest must contain a CONTENT_HASH line.
    local newest_manifest
    newest_manifest=$(find "$backup_root" -mindepth 2 -maxdepth 2 -name manifest.txt 2>/dev/null | sort | tail -1)
    if ! grep -q "^CONTENT_HASH=" "$newest_manifest"; then
        echo "  Manifest missing CONTENT_HASH: $newest_manifest"
        return 1
    fi
}

# --- Test 10: BACKUP_ID collision gets _2/_3 suffix, never overwrites ---
test_collision_suffix() {
    local target_home="$SBOX/home10"
    local xdg_data="$SBOX/data10"
    local opencode_cfg_dir="$target_home/.config/opencode"
    local opencode_cfg="$opencode_cfg_dir/opencode.jsonc"
    local backup_root="$xdg_data/opencodeWizard/backups"
    local bin_dir="$SBOX/bin10"

    mkdir -p "$opencode_cfg_dir" "$bin_dir"
    cat > "$opencode_cfg" <<'JSON'
{"user": "collision-test"}
JSON

    # Fake `date` so generate_backup_id always returns the same timestamp.
    cat > "$bin_dir/date" <<EOF
#!/bin/bash
if [ "\$1" = "+%Y%m%d-%H%M%S" ]; then
    echo "20200101-000000"
fi
EOF
    chmod +x "$bin_dir/date"

    # Pre-create the dir that the FIRST call would create.
    local script_hash
    script_hash=$(git -C "$(dirname "$SCRIPT")" rev-parse --short HEAD 2>/dev/null || echo "local")
    local frozen_id="ocw-${script_hash}-20200101-000000"
    mkdir -p "$backup_root/$frozen_id"
    echo "PRE-EXISTING - must not be touched" > "$backup_root/$frozen_id/marker.txt"

    PATH="$bin_dir:$PATH" \
        HOME="$target_home" XDG_DATA_HOME="$xdg_data" \
        MAX_BACKUPS=15 BACKUP_ID="" BACKUP_DIR="$backup_root" \
        "$SCRIPT" --silent --create-backup >/dev/null 2>&1 || true

    # The pre-existing dir must be untouched.
    if [ ! -f "$backup_root/$frozen_id/marker.txt" ] \
       || ! grep -q "PRE-EXISTING" "$backup_root/$frozen_id/marker.txt"; then
        echo "  COLLISION REGRESSION: pre-existing backup was overwritten"
        return 1
    fi

    # The new backup must be at <frozen_id>_2.
    if [ ! -d "$backup_root/${frozen_id}_2" ]; then
        echo "  COLLISION REGRESSION: expected ${frozen_id}_2, not found"
        ls -la "$backup_root" >&2
        return 1
    fi
}

# --- Test 11: --merge-backup flag actually triggers merge on a fixture path ---
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
run_test test_create_backup_idempotent
run_test test_max_backups_prunes_oldest
run_test test_content_hash_dedup
run_test test_collision_suffix
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
