# Git Best Practices for OpenCodeWizard

This guide outlines the Git workflow for contributors working on the OpenCodeWizard repository.

## 1. Branching Strategy

- **`main`**: The stable branch. Do not push directly to `main`.
- **Feature branches**: Use descriptive names like `feature/new-plugin-logic` or `fix/mcp-redundant-install`.

## 2. Commit Guidelines

- **Atomic commits**: Keep commits small and focused on a single logical change.
- **Commit messages**:
  - Use the imperative mood (e.g., "Add TPS plugin" instead of "Added TPS plugin").
  - Keep the subject line under 50 characters.
  - Provide a detailed body if necessary.

## 3. Pre-Push Hook

This repository includes a pre-push hook (`.githooks/pre-push`) to ensure code quality.

- **Automated Testing**: Before pushing to `main` or `master`, the hook automatically runs the full CI test suite (Docker containers for Ubuntu, Fedora, Arch, and PowerShell syntax check).
- **Triggers**: It runs **only** if `.sh` or `.ps1` files have been modified.
- **Skipping**: If you need to skip the test suite (not recommended), use `git push --no-verify`.

## 4. Pull Requests

- Ensure all CI tests pass before submitting a PR.
- Reference relevant issues in your PR description.
- Keep PRs focused on a single feature or bug fix.

## 5. Branch Protection

- Direct pushes to `main` are restricted. All changes must go through a Pull Request.
