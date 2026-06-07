# oh-my-openagent Plugin — Comprehensive Guide

> **What it is, how it works, how to configure it, and how it integrates with OpenCodeWizard.**

*Read this in other languages: [Українська (oh-my-openagent.uk.md)](oh-my-openagent.uk.md)*

This document describes the [`oh-my-openagent`](https://github.com/code-yeongyu/oh-my-openagent) OpenCode plugin in detail. It is the heart of the agent orchestration layer that OpenCodeWizard installs by default.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Editions](#2-editions)
3. [Installation State on This System](#3-installation-state-on-this-system)
4. [File and Directory Layout](#4-file-and-directory-layout)
5. [Built-in Agents](#5-built-in-agents)
6. [Built-in Skills](#6-built-in-skills)
7. [Built-in MCP Servers](#7-built-in-mcp-servers)
8. [Lifecycle Hooks](#8-lifecycle-hooks)
9. [Operating Modes and Slash Commands](#9-operating-modes-and-slash-commands)
10. [Configuration Files](#10-configuration-files)
11. [Configuration Examples](#11-configuration-examples)
12. [Sisyphus — The Orchestrator](#12-sisyphus--the-orchestrator)
13. [Prometheus — The Planner](#13-prometheus--the-planner)
14. [Other Notable Agents](#14-other-notable-agents)
15. [Team Mode](#15-team-mode)
16. [Ultrawork Discipline](#16-ultrawork-discipline)
17. [Integration with OpenCodeWizard](#17-integration-with-opencodewizard)
18. [Uninstallation](#18-uninstallation)
19. [Troubleshooting](#19-troubleshooting)
20. [References](#20-references)

---

## 1. Overview

`oh-my-openagent` (the npm package, historically published as `oh-my-opencode`) is the central orchestration plugin in the OpenCode ecosystem. The name follows the convention "oh-my-…" started by `oh-my-zsh`. The maintainer describes it as:

> "If OpenCode is Debian/Arch, oh-my-openagent is Ubuntu/[Omarchy](https://omarchy.org/)."

It bundles:

- **11+ specialized agents** with a discipline-agent orchestration model
- **A skills system** with domain-tuned prompts and on-demand MCPs
- **54+ lifecycle hooks** (61 with Team Mode enabled)
- **5 built-in MCP servers** for common tasks
- **A planner agent** (Prometheus) that interviews the user before code is written
- **A self-referential work loop** (ralph-loop / ulw-loop) that keeps the agent on task
- **Multi-agent Team Mode** for parallel coordinated work
- **Codebase-aware edit primitives** (hash-anchored edits) for more reliable model-driven changes

The philosophy: the harness is the product. Most agent failures are not the model's fault — they are the edit tool, the context budget, the missing planning step. The plugin fixes these at the infrastructure level.

**Maintainer:** `code-yeongyu` (Sisyphus Labs). The plugin is actively built in public — features and fixes are streamed live on the project's Discord.

---

## 2. Editions

The package ships in two editions.

| Edition | Harness | What you get | Install command |
|---|---|---|---|
| **Ultimate** | OpenCode | Full omo: 11 agents, 54+ hooks, 5 MCPs, all slash commands, Team Mode, ulw-loop, ultrawork, hashline edits | `bunx oh-my-openagent install` (TUI walks through it) |
| **Light** | Codex CLI | Portable subset that fits Codex's plugin system: rules, comment-checker, LSP, ultrawork, ulw-loop, start-work-continuation, telemetry. No agent orchestration, no `team_*` tools, no built-in MCPs beyond LSP | `npx lazycodex-ai install` |

This document covers the **Ultimate** edition only — that is what OpenCodeWizard installs.

### Package and command names

The published npm package and CLI binary are still named `oh-my-opencode` (dual-published as `oh-my-openagent` during the rename transition). Inside `opencode.json`, the compatibility layer prefers the plugin entry `oh-my-openagent`; legacy `oh-my-opencode` entries still load with a deprecation warning. Both `bunx oh-my-openagent install` and the older `bunx oh-my-opencode install` work.

Do **not** use `bunx omo` / `npx omo` — `omo` is a different, unrelated npm package by another author, and the package manager may resolve the wrong one. The `omo` bin alias exists but is reserved for the Codex Light edition.

### Telemetry

Anonymous telemetry is **enabled by default**. The plugin emits one `oh_my_openagent_daily_active` event per UTC day per machine, using a SHA256-hashed installation identifier (the raw hostname is never sent). PostHog person profiles are not created.

To opt out, see the configuration section below.

---

## 3. Installation State on This System

Verify what is currently installed:

```bash
ls -d ~/.cache/opencode/packages/oh-my-openagent@latest
cat ~/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/package.json \
  | python3 -c "import json,sys;p=json.load(sys.stdin);print('name:',p['name']);print('version:',p['version'])"
opencode --version
```

The version installed in this system is shown in the output above. The version at the time of writing is **4.7.5**.

The plugin is registered in the user's `opencode.jsonc` under the `plugin` array:

```json
"plugin": [
  "oh-my-openagent",
  "opencode-mem",
  "@different-ai/opencode-browser",
  "@tarquinen/opencode-smart-title",
  "opencode-token-speed-plugin",
  "opencode-codebase-index"
]
```

OpenCodeWizard's `developer` and `standard` presets install `oh-my-openagent` by default. The `minimal` preset may omit it.

---

## 4. File and Directory Layout

### Plugin source (read-only, managed by opencode's package manager)

```text
~/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/
├── package.json
├── README.md
├── bin/                          # CLI binaries
├── dist/
│   ├── index.js                  # Plugin entry
│   ├── agents/                   # Agent definitions
│   │   ├── sisyphus/             # Orchestrator (per-model variants)
│   │   │   ├── claude-opus-4-7.d.ts
│   │   │   ├── default.d.ts
│   │   │   ├── gemini.d.ts
│   │   │   ├── gpt-5-4.d.ts
│   │   │   ├── gpt-5-5.d.ts
│   │   │   └── kimi-k2-6.d.ts
│   │   ├── sisyphus-junior/      # Focused executor
│   │   ├── prometheus/           # Planner
│   │   ├── metis.d.ts
│   │   ├── momus.d.ts
│   │   └── oracle.d.ts
│   ├── config/schema/            # Zod schemas for user config
│   │   ├── agent-names.d.ts
│   │   ├── agent-definitions.d.ts
│   │   ├── agent-overrides.d.ts
│   │   ├── sisyphus.d.ts
│   │   ├── sisyphus-agent.d.ts
│   │   ├── categories.d.ts
│   │   ├── skills.d.ts
│   │   ├── hooks.d.ts
│   │   ├── commands.d.ts
│   │   ├── background-task.d.ts
│   │   ├── fallback-models.d.ts
│   │   ├── team-mode.d.ts
│   │   ├── ralph-loop.d.ts
│   │   ├── start-work.d.ts
│   │   ├── dynamic-context-pruning.d.ts
│   │   ├── experimental.d.ts
│   │   ├── websearch.d.ts
│   │   ├── notification.d.ts
│   │   ├── git-master.d.ts
│   │   ├── default-mode.d.ts
│   │   ├── oh-my-opencode-config.d.ts
│   │   └── …  (30+ schemas)
│   ├── hooks/                    # 54+ lifecycle hooks
│   │   ├── prometheus-md-only
│   │   ├── sisyphus-junior-notepad
│   │   ├── no-sisyphus-gpt
│   │   └── ralph-loop/
│   └── tools/                    # MCP tools
├── packages/
│   ├── omo-codex/
│   │   ├── plugin/
│   │   │   ├── skills/           # Skill definitions
│   │   │   │   ├── ulw-loop/
│   │   │   │   ├── ulw-plan/
│   │   │   │   ├── start-work/
│   │   │   │   ├── init-deep/
│   │   │   │   ├── refactor/
│   │   │   │   ├── review-work/
│   │   │   │   ├── remove-ai-slops/
│   │   │   │   ├── debugging/
│   │   │   │   ├── frontend-ui-ux/
│   │   │   │   ├── comment-checker/
│   │   │   │   ├── lsp/
│   │   │   │   ├── programming/
│   │   │   │   ├── rules/
│   │   │   │   └── lcx-report-bug/
│   │   │   └── components/
│   │   │       ├── ultrawork/
│   │   │       │   └── agents/
│   │   │       │       ├── metis.toml
│   │   │       │       └── momus.toml
│   │   │       └── ulw-loop/
│   │   └── README.md
│   └── shared-skills/            # Skills shared between editions
│       └── skills/
│           └── debugging/
```

### User-level configuration (where you customize the plugin)

| File | Purpose |
|---|---|
| `~/.config/opencode/oh-my-openagent.json[c]` | Main user config. Optional — defaults are baked in. |
| `~/.config/opencode/oh-my-opencode.json[c]` | Legacy alias for the same file. Still works. |

The format is **JSONC**: comments (`//`, `/* */`) and trailing commas are allowed. The schema is the union of every `dist/config/schema/*.d.ts` file in the plugin.

### Project-level overrides

OpenCode walks the directory tree from `cwd` up to `$HOME`, looking for:

```text
<dir>/.opencode/oh-my-openagent.json[c]
<dir>/.opencode/oh-my-opencode.json[c]   # legacy alias
```

The **closest** file to `cwd` wins. This lets you keep project-specific overrides (e.g. "always use the local llama.cpp for this repo") without polluting the global config.

### OpenCode main config integration

The plugin is registered in the standard `opencode.json[c]` under the `plugin` array. No other opencode-level wiring is required.

---

## 5. Built-in Agents

The plugin ships with these agents. The names and kinds come from `dist/config/schema/agent-names.d.ts`.

### User-overridable built-in agents

| Agent | Role | Notes |
|---|---|---|
| `sisyphus` | Main orchestrator | The "you" — what you talk to. Mode-aware, dispatches subagents, enforces the Ultrawork discipline. |
| `hephaestus` | Alternate orchestrator | Visual/frontend-oriented variant. |
| `prometheus` | Planner | Interviews the user, identifies scope, builds a verified plan. Used by `/start-work`. |
| `metis` | Pre-planning consultant | Spots hidden intent, ambiguities, failure modes in the request *before* planning. |
| `momus` | Plan critic | Hostile reviewer of plans. Catches gaps, ambiguities, missing verification steps. |
| `oracle` | Read-only consultant | High-IQ reasoning for hard debugging and architecture decisions. |
| `librarian` | External reference grep | Search remote repositories, retrieve official docs, find usage examples. |
| `explore` | Internal code grep | Search the local codebase. Cheap and fast. |
| `multimodal-looker` | Media interpreter | Reads PDFs and images when raw text extraction is not enough. |
| `atlas` | (Reserved) | Available for custom orchestration wiring. |
| `sisyphus-junior` | Focused executor | Same prompt as Sisyphus but **without** the orchestration harness — runs in-process, no delegation, no hooks. Used inside subagent contexts. |

### OpenCode-native agents (exposed by the plugin, not invented by it)

| Agent | Notes |
|---|---|
| `build` | OpenCode's default write/agent mode. |
| `plan` | OpenCode's read-only planning mode. |
| `OpenCode-Builder` | Alias kept for backwards compatibility. |

### How to switch the active agent

In OpenCode's chat:

- The default top-level agent is `sisyphus`.
- Subagents are invoked by the orchestrator via the `Task(subagent_type=...)` tool. You typically do not call them directly.
- To override the default agent for a session, see [Configuration Examples](#11-configuration-examples).

---

## 6. Built-in Skills

Skills are bundles of:

- Domain-tuned system instructions
- Embedded MCP servers (on-demand, scoped to the skill)
- Optional example workflows

They are loaded into the model's context when the corresponding slash command is invoked, or when the orchestrator detects the topic matches. Skills are stored under `packages/omo-codex/plugin/skills/`.

### Slash-command skills

These are triggered by typing `/<name>` in the chat:

| Slash command | What it does |
|---|---|
| `/ulw-loop` | Enter the Ultrawork loop — the agent keeps working until the task is done. |
| `/ulw-plan` | Plan in Ultrawork mode, then execute. |
| `/start-work` | Invoke Prometheus to build a verified plan from a goal, then execute it. |
| `/init-deep` | Generate hierarchical `AGENTS.md` files in the project for codebase-aware AI. |
| `/refactor` | Run the refactor skill: LSP/AST-grep analysis, codemap, TDD verification. |
| `/review-work` | Review recent changes for completeness and correctness. |
| `/remove-ai-slops` | Detect and remove AI-generated code smells from diff. |
| `/debugging` | Structured debugging methodology. |
| `/hyperplan` | 5 hostile category members cross-critique a plan, lead synthesizes. |
| `/stop-continuation` | Stop all active loops (`ulw-loop`, `ralph-loop`, todos). |
| `/cancel-ralph` | Stop only the Ralph loop. |
| `/handoff` | Create a context summary for a new session. |

### Auto-loaded skills (no slash command required)

| Skill | When the orchestrator loads it |
|---|---|
| `frontend-ui-ux` | Task involves UI/CSS/styling/animation. |
| `comment-checker` | After code is written, scans for misleading or stale comments. |
| `lsp` | Whenever LSP-aware edits or refactors are needed. |
| `programming` | General-purpose programming language guidance. |
| `rules` | Loaded once at session start, holds standing rules. |
| `lcx-report-bug` | When the user reports a bug. |

### Skill manifest (`dist/config/schema/agent-names.d.ts`)

The full list of skills the plugin claims it can load, per the schema:

```text
playwright, agent-browser, dev-browser, frontend-ui-ux,
git-master, review-work, remove-ai-slops, init-deep,
security-research, security-review, team-mode
```

These are **built-in** skills registered with OpenCode. The list above is the schema-registered set. The actual on-disk skills under `packages/omo-codex/plugin/skills/` include the workflow skills (`ulw-loop`, `ulw-plan`, `start-work`, `debugging`, `refactor`, etc.) that are listed separately.

---

## 7. Built-in MCP Servers

The plugin ships with MCP servers for common tasks. They are **runtime-injected** — they do not show up in `opencode mcp list` until a skill that needs them is loaded.

| MCP | Purpose | Source |
|---|---|---|
| `websearch` | Real-time web search (Exa-backed) | `dist/config/schema/websearch.d.ts` |
| `context7` | Up-to-date library docs lookup | per README |
| `grep_app` | Search public GitHub code (literal patterns, not keywords) | per README |
| (plus 2 more) | Reserved for in-skill use | |

Plus all MCP servers the user has registered in their own `opencode.jsonc` (e.g. `fetch`, `puppeteer`, `postgres`, `codegraph`, `docs-mcp`, `lsp-mcp` installed by OpenCodeWizard).

### Skill-embedded MCPs

Some skills bring their own MCP servers that spin up **on demand** when the skill is active and shut down when it is done. This keeps the context window clean — the MCP's tool definitions are only present while the relevant skill is in scope.

---

## 8. Lifecycle Hooks

The plugin installs **54+ lifecycle hooks** (61 with Team Mode). Hooks run at specific points in OpenCode's session lifecycle: `PreToolUse`, `PostToolUse`, `PreModel`, `PostModel`, `SessionStart`, `SessionEnd`, etc.

Some notable hooks (paths under `dist/hooks/`):

| Hook | Purpose |
|---|---|
| `prometheus-md-only` | Force the planner to write plans to `.md` files instead of inline responses. |
| `sisyphus-junior-notepad` | Subagent scratchpad — passes context between subagent turns. |
| `no-sisyphus-gpt` | Prevents a specific weak model from being assigned to Sisyphus's main loop. |
| `ralph-loop/oracle-verification-detector.d.ts` | Triggers an Oracle verification pass at the end of the Ralph loop. |

You can disable any hook from your user config (see [Configuration Examples](#11-configuration-examples)).

---

## 9. Operating Modes and Slash Commands

The plugin exposes several "modes" that change how the agent behaves. They are invoked as slash commands in the chat.

### Mode catalog

| Command | Mode | What happens |
|---|---|---|
| `/ulw-loop` (or just `ultrawork` / `ulw`) | **Ultrawork loop** | The agent works end-to-end without stopping for confirmation. Persists until the task is verifiably done. This is the "ship it" mode. |
| `/ulw-plan` | **Ultrawork planning** | Same discipline, but produces a plan first, then executes. |
| `/ralph-loop` | **Ralph loop** | Self-referential: the agent continues to invoke itself with a notepad until it reports done. Stronger guarantee of completion than ulw-loop, slower. |
| `/hyperplan` | **Hyperplan** | 5 hostile category members (different agent roles) cross-critique a draft plan. The lead synthesizes. Most thorough planning mode. |
| `/start-work` | **Prometheus-driven work** | Calls Prometheus to interview the user and produce a verified plan, then begins execution. |
| `/init-deep` | **Project initialization** | Walks the codebase, generates hierarchical `AGENTS.md` files. Improves future sessions. |
| `/refactor` | **Refactor pass** | LSP + AST-grep + codemap + TDD verification cycle. |
| `/review-work` | **Code review** | Reviews recent changes. |
| `/remove-ai-slops` | **Slop cleanup** | Detects and removes AI-generated code smells. |
| `/debugging` | **Structured debugging** | Loads a methodology reference. |
| `/handoff` | **Session handoff** | Generates a context summary for a new session. |
| `/stop-continuation` | **Stop everything** | Cancels all active loops, todos, and the worktree. |
| `/cancel-ralph` | **Stop Ralph only** | Cancels the Ralph loop but leaves other loops running. |

### When to use which

- **You know exactly what you want built** → `/ulw-loop` or just `ultrawork` / `ulw`
- **You have a goal but not a plan** → `/start-work` (Prometheus interviews you)
- **You have a draft plan and want it pressure-tested** → `/hyperplan`
- **You want guaranteed completion no matter how long it takes** → `/ralph-loop`
- **You want to clean up before committing** → `/remove-ai-slops` + `/review-work`

### How Sisyphus picks a mode automatically

In the default Sisyphus prompt, certain phrases trigger certain modes:

| Trigger phrase in user message | Auto-mode |
|---|---|
| "implement and finish", "do the whole thing", "ulw", "ultrawork", "ship it" | Ultrawork |
| "fix this whole thing", "look into" | Investigation → planning if scope is unclear |
| Long / multi-line goals | Prometheus (`/start-work`) |

This is matched by the `keyword-detector` hook and the `default-mode` config schema.

---

## 10. Configuration Files

### File precedence (closest wins)

1. `<cwd>/.opencode/oh-my-openagent.json[c]`
2. `<parent>/.opencode/oh-my-openagent.json[c]`
3. ... up to `$HOME`
4. `~/.config/opencode/oh-my-openagent.json[c]` (global user config)
5. Plugin defaults

Both `oh-my-openagent.json[c]` and the legacy `oh-my-opencode.json[c]` basenames are recognized.

### Configuration shape

The config is a single JSONC object. The top-level keys are documented by the Zod schemas in `dist/config/schema/`. A non-exhaustive list:

| Key | Schema file | Purpose |
|---|---|---|
| `agents` | `agent-definitions.d.ts` | Override model / temperature / prompt / permissions per agent. |
| `categories` | `categories.d.ts` | Map task categories (e.g. `visual`, `business-logic`) to default models. |
| `skills` | `skills.d.ts` | Enable / disable specific skills. |
| `commands` | `commands.d.ts` | Configure slash commands. |
| `hooks` | `hooks.d.ts` | Disable specific hooks. |
| `background_task` | `background-task.d.ts` | Concurrency limits per provider / model. |
| `fallback_models` | `fallback-models.d.ts` | Models to try when the primary fails. |
| `team_mode` | `team-mode.d.ts` | Team Mode settings. |
| `ralph_loop` | `ralph-loop.d.ts` | Ralph loop parameters. |
| `start_work` | `start-work.d.ts` | `/start-work` parameters. |
| `websearch` | `websearch.d.ts` | Websearch provider settings. |
| `default_mode` | `default-mode.d.ts` | Default operating mode on session start. |
| `dynamic_context_pruning` | `dynamic-context-pruning.d.ts` | Aggressive context trimming. |
| `git_master` | `git-master.d.ts` | git-master skill settings. |
| `notification` | `notification.d.ts` | OS notifications. |
| `experimental` | `experimental.d.ts` | Opt-in experimental features. |
| `i18n` | `i18n.d.ts` | UI language. |
| `sisyphus` | `sisyphus.d.ts` | Sisyphus-specific (tasks storage, claude_code_compat). |
| `sisyphus_agent` | `sisyphus-agent.d.ts` | Sisyphus agent config (model, prompt overrides). |
| `oh_my_opencode_config` | `oh-my-opencode-config.d.ts` | Legacy single-bag config (still works). |
| `claude_code` | `claude-code.d.ts` | Claude Code compatibility shim. |

---

## 11. Configuration Examples

### Override the model Sisyphus uses

```jsonc
// ~/.config/opencode/oh-my-openagent.jsonc
{
  "sisyphus_agent": {
    "model": "anthropic/claude-sonnet-4-5",
    "temperature": 0.0
  }
}
```

### Use a local model for Sisyphus (your setup)

This is exactly the configuration that fits the `llamacpp` provider added in the previous step of the setup:

```jsonc
{
  "sisyphus_agent": {
    "model": "llamacpp/Qwen3.6-27B-Q4_K_S",
    "fallback_models": [
      "opencode/deepseek-v4-flash-free"
    ]
  }
}
```

### Disable a specific skill

```jsonc
{
  "skills": {
    "remove-ai-slops": { "enabled": false }
  }
}
```

### Disable a hook

```jsonc
{
  "hooks": {
    "disabled_hooks": ["prometheus-md-only", "no-sisyphus-gpt"]
  }
}
```

### Configure a custom category

```jsonc
{
  "categories": {
    "business-logic": {
      "model": "anthropic/claude-sonnet-4-5",
      "prompt_append": "You are working on the OpenCodeWizard project. Be terse and concrete."
    }
  }
}
```

### Limit background task concurrency per model

```jsonc
{
  "background_task": {
    "concurrency": {
      "anthropic/claude-sonnet-4-5": 4,
      "llamacpp/*": 1
    }
  }
}
```

### Opt out of telemetry

```jsonc
{
  "experimental": {
    "telemetry": { "enabled": false }
  }
}
```

### Project-local override (per-repo)

```jsonc
// <repo>/.opencode/oh-my-openagent.jsonc
{
  "sisyphus_agent": {
    "model": "llamacpp/Qwen3.6-27B-Q4_K_S"
  },
  "default_mode": "ultrawork"
}
```

This file is read in addition to the global one. Keys present here override the global value for the project.

---

## 12. Sisyphus — The Orchestrator

Sisyphus is the main agent the user talks to. Its prompt lives in `dist/agents/sisyphus/`, with one variant per supported model:

| Variant | Used for |
|---|---|
| `claude-opus-4-7.d.ts` | Claude Opus 4.7 (and other Claude models in the same family) |
| `gpt-5-4.d.ts`, `gpt-5-5.d.ts` | GPT-5 family |
| `gemini.d.ts` | Gemini family |
| `kimi-k2-6.d.ts` | Kimi K2 |
| `default.d.ts` | Fallback for unrecognized models |

The variant is selected automatically based on the model assigned to the `sisyphus` agent.

### Core responsibilities

Sisyphus:

1. **Parses user intent** (planning phase, Phase 0 in the prompt).
2. **Routes work** to specialized subagents (delegation).
3. **Enforces the Ultrawork discipline** — keeps working until the task is verifiably done.
4. **Verifies results** before reporting back — uses the real tool for the surface (browser for UI, curl for HTTP, real binary for CLIs).
5. **Stays terse** — no preamble, no flattery, no status narration. Todos for tracking, not chatter.
6. **Challenges the user** when their design is wrong — proposes alternatives, never lectures.

### Key behavioral rules (from the prompt)

- **NEVER start implementing without an explicit user request** — observation, investigation, and answering questions do not commit to code.
- **DELEGATE, don't solo** — visual work goes to `visual-engineering`, deep research goes to parallel `explore`/`librarian` agents, architecture to `oracle`.
- **REAL USAGE is the verification gate** — tests passing is not enough. The agent must run the binary, click the buttons, hit the API.
- **REPORT FAITHFULLY** — failures get reported with output, never papered over.

### What Sisyphus is **not**

- Not a single-model agent. It picks **categories** (which map to model families) for each delegated task, not specific models.
- Not a chatty companion. It uses todos for tracking, not narration.
- Not omniscient. It verifies via tools, never assumes.

---

## 13. Prometheus — The Planner

Prometheus is the planning agent invoked by `/start-work` and the `/hyperplan` cross-critique flow.

### What it does

1. **Interviews the user** like a real engineer: asks about scope, ambiguities, constraints, success criteria.
2. **Spots hidden requirements** the user did not mention (Metis-style pre-pass).
3. **Builds a hierarchical plan** with clear sub-goals, verification steps, and risks.
4. **Writes the plan to disk** (the `prometheus-md-only` hook forces this — plans go to `.md` files, not the chat scroll).
5. **Hands off to execution** — once the plan is verified, Sisyphus picks it up.

### When to use Prometheus

- The task is non-trivial (more than a few file edits).
- The scope is unclear or there are multiple valid approaches.
- The user might be wrong about what they want.
- The change touches multiple modules or has cross-cutting concerns.

### When **not** to use Prometheus

- Trivial single-file changes.
- Clear, well-scoped bug fixes.
- "Just do exactly this" requests.

For trivial work, plain Sisyphus is faster.

---

## 14. Other Notable Agents

### `oracle` — Read-only consultant

Used for hard debugging and architecture decisions where the cost of being wrong is high. Oracle is **read-only**: it does not edit files, does not run side-effecting commands. It only reads, reasons, and reports.

- Cost: high token usage, slow.
- Value: catches the kind of subtle interaction bugs that surface only after 3 failed fix attempts.

### `metis` — Pre-planning

Runs before Prometheus. Surfaces hidden intent, ambiguities, and AI failure points in the request. A 5-minute Metis pass can prevent a 2-hour build into the wrong direction.

### `momus` — Plan critic

Hostile reviewer. Given a plan, it tries to break it. Catches:

- Missing verification steps
- Ambiguous acceptance criteria
- Untested edge cases
- Implicit assumptions

A plan that survives Momus is much more likely to succeed.

### `explore` and `librarian` — Search agents

- `explore`: **internal** code grep. Cheap, fast, runs in-process.
- `librarian`: **external** reference grep. Searches GitHub, retrieves official docs, finds usage examples via `gh` CLI + Context7 + Web Search. Slower, more expensive.

The default flow per the prompt: `explore`/`librarian` (background) + direct tools → `oracle` if needed.

### `sisyphus-junior` — Focused executor

Same prompt as Sisyphus, **minus the orchestration harness**. Runs inside subagent contexts where you want the discipline but not the delegation / hooks overhead.

---

## 15. Team Mode

Team Mode (introduced in v4.0) turns oh-my-openagent from "one agent with subagents" into a real multi-agent system.

A lead agent orchestrates a team of category-specialized members, all running **in parallel** and communicating through dedicated tools:

- `team_create` — create the team
- `team_send_message` — message a team member
- `team_task_create` — add a task to the shared backlog
- `team_status` — check progress

The team operates in a tmux layout with focus + grid windows — you watch every member work simultaneously.

Team Mode is enabled via the `team_mode` config key and adds 7 hooks to the default 54.

---

## 16. Ultrawork Discipline

The Ultrawork Manifesto (`docs/manifesto.md` in the plugin repo) is the design document. The core rules:

### The agent does not stop until the task is done

Confirmation is not "I think it's done". Confirmation is the task is **verifiably** done:

- File edit → `lsp_diagnostics` clean
- Build → exit code 0
- Test → pass
- Delegation → result verified file-by-file
- End-to-end delegation → agent has used the artifact through the matching real-world tool (browser for UI, curl for HTTP, the binary itself for CLIs)

### No partial fixes

If the user hands off end-to-end ("ulw", "implement and finish", "do the whole thing", "make it work", "ship it"), delegation is a **mandate to do the work**. Reading the source is not validation. Running the actual tool with the actual user input is the only valid completion.

### Honest reporting

Tests fail → say so, with the actual output. The build did not run → say "did not run", not "it should work". A failing test is never deleted to make a build green.

### Tools are first-class

The right tool is mandatory:

- TUI/CLI work → `interactive_bash` (tmux). Run the binary in a real terminal.
- Web/UI work → real browser via the `playwright` skill. Render the change.
- HTTP API → `curl` against the running service.
- Library/SDK → minimal driver script that imports + executes the code.

"Should work" is not verified. Verified means the user would agree the artifact is correct.

---

## 17. Integration with OpenCodeWizard

OpenCodeWizard installs and configures `oh-my-openagent` as part of the standard setup. The wiring is in three places:

### `config/plugins.conf`

```text
oh-my-openagent|Session management and advanced CLI commands
```

This is the canonical plugin list. The wizard reads it and adds selected entries to the user's `opencode.jsonc`.

### `config/variables.conf` — preset definitions

The `developer` and `standard` presets include `oh-my-openagent`. The `minimal` preset does not. To enable oh-my-openagent in a different preset, edit the relevant `PRESET_*_PLUGINS` array.

### `OpenCodeWizard.sh` — `configure_opencode()`

The function `configure_opencode()` builds the JSONC for `opencode.jsonc`. It writes the `plugin` array, the `mcp` object, the `instructions` array, and (optionally) the `provider` block. It does **not** generate a separate `oh-my-openagent.json[c]` — the plugin is enabled entirely through the standard `plugin` array.

### `config/system_info.md.tpl` — AI system prompt

The template can reference oh-my-openagent capabilities in the system prompt it generates. The standard template mentions the shared terminal, git operations rule, and OpenCode ecosystem — all of which integrate with the plugin's hooks.

### Verifying the integration

After running the wizard, the user's `~/.config/opencode/opencode.jsonc` should contain:

```jsonc
{
  "plugin": [
    "oh-my-openagent",
    // … other plugins …
  ]
}
```

Start opencode. The first chat should show the Sisyphus identity. If you see plain OpenCode behavior, the plugin is not loading — check the opencode logs.

---

## 18. Uninstallation

The plugin's README gives a single clean procedure. To remove `oh-my-openagent` from this system:

1. **Remove from the plugin list.** Edit `~/.config/opencode/opencode.jsonc` and remove `"oh-my-openagent"` from the `plugin` array. Optionally also remove the other plugins you no longer want.

2. **(Optional) Remove user config.** If you created a `~/.config/opencode/oh-my-openagent.json[c]` or any project-level overrides, delete them.

3. **(Optional) Clear the cache.** The plugin lives under `~/.cache/opencode/packages/oh-my-openagent@latest/`. Removing it is safe — opencode will re-download if the plugin is re-enabled.

4. **Restart opencode.** Reload to pick up the change.

5. **(Optional) Opt out of telemetry on remaining installations.** Set `"experimental": { "telemetry": { "enabled": false } }` in your user config.

There is no global "uninstall" command in the plugin itself. The above is the canonical procedure.

---

## 19. Troubleshooting

### Plugin is enabled but Sisyphus is not the active agent

Check `opencode.jsonc` for an `agent` key that overrides the default. Sisyphus is the default top-level agent when `oh-my-openagent` is loaded — but a user-level override can change it.

```jsonc
// Force Sisyphus as the default
{
  "agent": "sisyphus"
}
```

### Slash commands do nothing

Slash commands are registered by the plugin. If `/ulw-loop` is unrecognized, the plugin is not loaded. Verify:

```bash
ls -d ~/.cache/opencode/packages/oh-my-openagent@latest
grep '"oh-my-openagent"' ~/.config/opencode/opencode.jsonc
```

If the package is missing, reinstall. If the entry is missing from `plugin`, add it.

### Subagents are not being called

By default, Sisyphus delegates via the `Task` tool. If your model does not support tool use correctly, delegation will be skipped. The plugin tries to fall back to in-process execution via `sisyphus-junior`, but the discipline is weaker.

Test with a fresh `opencode` session and a clearly delegable task ("find the auth implementation in this codebase"). If Sisyphus does not invoke `explore`/`librarian`, your model may not be routing tool calls correctly.

### Telemetry opt-out is not respected

The opt-out is per-installation. The plugin uses a SHA256-hashed installation ID — clearing the cache forces a new ID and resets the opt-out. Re-apply the config after clearing.

### A skill reports "not found"

Some skills are platform-specific. `playwright` requires a Chromium binary. `agent-browser` and `dev-browser` have their own setup steps. Check the skill's `SKILL.md` for prerequisites.

### Models in `oh-my-openagent.json[c]` are silently ignored

The plugin's model-override system has a known namespace routing quirk in older opencode versions (see `oh-my-openagent` issue tracker for `@ai-sdk/openai-compatible`). For local models using the OpenAI-compatible SDK, `baseURL` and `apiKey` may not be forwarded correctly to the SDK. Workarounds:

- Pin to a recent opencode version.
- Use the per-agent `model` field in the standard `opencode.jsonc` `provider` block.

---

## 20. References

- **Plugin repo:** <https://github.com/code-yeongyu/oh-my-openagent>
- **Plugin README:** `~/.cache/opencode/packages/oh-my-openagent@latest/node_modules/oh-my-openagent/README.md` (also in `README.ja.md`, `README.ko.md`, `README.ru.md`, `README.zh-cn.md`)
- **Upstream docs (linked from the README but not in this install):**
  - `docs/guide/installation.md` — installation walkthrough
  - `docs/reference/configuration.md` — full config reference
  - `docs/reference/features.md` — feature catalog
  - `docs/manifesto.md` — the Ultrawork Manifesto
  - `ROADMAP.md` — multi-harness refactor plan
- **Schema source of truth:** the Zod schemas in `dist/config/schema/*.d.ts` inside the installed package
- **Sister project:** `lazycodex-ai` (Codex Light edition of the same plugin)
- **OpenCode ecosystem:** <https://opencode.ai>
- **OpenCodeWizard:** <https://github.com/nudykw/OpenCodeWizard> (this project's own docs)
