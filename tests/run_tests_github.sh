#!/usr/bin/env bash

# ==============================================================================
# OpenCodeWizard GitHub Test Runner
# ==============================================================================
# Runs automated installation and verification tests inside Docker containers,
# cloning the repository directly from GitHub (https://github.com/nudykw/OpenCodeWizard.git).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================="
echo ">>> Running OpenCodeWizard GitHub Test Suite"
echo ">>> This will clone from https://github.com/nudykw/OpenCodeWizard.git"
echo "================================================================="

# Execute the main test runner with the --post-push flag
"${SCRIPT_DIR}/run_tests.sh" --post-push "$@"
