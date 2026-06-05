# Automated Testing in OpenCodeWizard

*Read this in other languages: [Українська (README.uk.md)](README.uk.md)*

This directory contains the testing framework for verifying the functionality of the OpenCodeWizard automation scripts in various environments.

Testing is performed automatically using Docker containers, which allows for isolating system package installations and verifying script behavior without affecting your main host operating system.

---

## Directory Structure

- **`run_tests.sh`** — The main test runner script. It orchestrates starting containers, installing base prerequisites, cloning the repository, running the installation script in silent/non-interactive mode, and running assertions.
- **`verify_install.sh`** — The verification script executed inside each container. It runs assertions to verify that WezTerm, OpenCode CLI, and plugins are correctly installed, and that configuration files are valid and contain proper values.
- **`README.md`** — This documentation file (English).
- **`README.uk.md`** — The Ukrainian version of this documentation.

---

## Target Environments

Automated tests are executed in containers for the following Linux distributions:
1. **Ubuntu** (`ubuntu:latest`) — Tests `apt-get` integration, `update-alternatives` registration, and XDG terminal setup.
2. **Fedora** (`fedora:latest`) — Tests `dnf` integration.
3. **Arch Linux** (`archlinux:latest`) — Tests `pacman` integration.
4. **PowerShell Core** (`mcr.microsoft.com/powershell:latest`) — Verifies the syntax of the Windows script `OpenCodeWizard.ps1` using the PowerShell AST parser.

---

## How It Works

Testing in Docker is fully automated and runs without user interaction using the silent/non-interactive mode:

1. The `run_tests.sh` script checks if the Docker daemon is running.
2. It starts a container for each distro.
3. Inside the container, it installs minimum prerequisites ([Git](../docs/git.md), `sudo`, `curl`, `nodejs`, `npm`).
4. It clones the repository from the mounted workspace directory (`git clone /src/OpenCodeWizard /app`).
5. It runs `./OpenCodeWizard.sh --silent`. The wizard runs non-interactively, applying all default choices.
6. It runs `./tests/verify_install.sh` to assert that:
   - `wezterm` and `opencode` are in the PATH and return valid version numbers.
   - Configuration files (`wezterm.lua` and `opencode.jsonc`) exist.
   - The plugin entry for `"oh-my-opencode"` is correct (verifies that `"oh-my-openagent"` is not present).
   - Shell exports are correctly written to `~/.bashrc`.
   - The desktop launcher file exists, is executable, and points to the correct target.

---

## Running Tests Locally

To run the test suite, you need to have **Docker** installed and running on your host machine.

1. Open your terminal in the root directory of the project.
2. Run the test runner:
   ```bash
   ./tests/run_tests.sh
   ```

The script will run all test suites sequentially and output a final summary. If all tests pass, it exits with code `0`. If any suite fails, it exits with a non-zero code, making it suitable for CI/CD workflows.

### Test Current State (Local changes)
By default, the script copies all local modifications (including uncommitted files) to run tests against your active working directory:
```bash
./tests/run_tests.sh
```

### Test GitHub Repository State (Post-Push)
To test the exact state of the repository cloned directly from GitHub (simulating post-push behavior), run the separate GitHub test script:
```bash
./tests/run_tests_github.sh
```
