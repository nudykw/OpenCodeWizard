#!/usr/bin/env bash
set -e

run_powershell_dry_run_test() {
    echo ">>> Testing PowerShell Dry-Run"
    docker run --rm -v "/home/nudyk/Projects/OpenCodeWizard:/app:ro" mcr.microsoft.com/powershell:latest pwsh -Command "
        cd /app
        ./OpenCodeWizard.ps1 -Silent -DryRun
        exit $LASTEXITCODE
    "
}

run_powershell_dry_run_test
