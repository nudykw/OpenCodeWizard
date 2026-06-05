# Working with OpenCode Sessions

*Read this in other languages: [Українська (sessions.uk.md)](sessions.uk.md)*

OpenCode automatically saves your conversations in **sessions** — separate chat histories stored in a SQLite database at `~/.opencode/db.sqlite`. Understanding how to use sessions effectively is key to getting the best results from your AI assistant.

---

## 📋 Table of Contents
- [What Is a Context Window?](#what-is-a-context-window)
- [Why Fresh Sessions Matter](#why-fresh-sessions-matter)
- [Session Actions Reference](#session-actions-reference)
  - [TUI (In-Chat) Commands](#tui-in-chat-commands)
  - [CLI Commands](#cli-commands)
  - [Keybinds](#keybinds)
- [Strategy: Plan then Implement](#strategy-plan-then-implement)
- [When to Create a New Session](#when-to-create-a-new-session)
- [Tips & Best Practices](#tips--best-practices)

---

## What Is a Context Window?

Every AI model has a **context window** — the maximum amount of text (measured in **tokens**) it can "see" at once. Think of it as the model's short-term memory:

- **Small models** (e.g. `deepseek-v4-flash-free`): ~32K–128K tokens
- **Large models** (e.g. Claude, GPT-4): ~200K tokens

Every message you send and every response the AI generates consumes part of this window. As the conversation grows, older messages get pushed out of the visible context.

---

## Why Fresh Sessions Matter

As a session fills up:

| Problem | Effect |
| :--- | :--- |
| **Context saturation** | The model "forgets" early instructions or details |
| **Quality degradation** | Responses become vague, less accurate |
| **Hallucinations** | The model starts guessing instead of recalling |
| **Slow performance** | Longer prompts = slower responses & higher cost |

**Starting a fresh session gives the model a "clean slate"** — it can focus entirely on the task at hand without being distracted by unrelated history.

---

## Session Actions Reference

### TUI (In-Chat) Commands

| Action | Command / Shortcut | Description |
| :--- | :--- | :--- |
| **New session** | `Ctrl+N` | Create a fresh, empty session |
| **Switch sessions** | `Ctrl+A` | Open session switcher, navigate with arrows, press `Enter` to load |
| **List & resume** | `/sessions` | Show all sessions, select one to resume |
| **Resume (alias)** | `/resume` | Same as `/sessions` |
| **Continue (alias)** | `/continue` | Same as `/sessions` |
| **Help** | `/help` | Show all available commands |

**To switch sessions interactively:**

1. Press `Ctrl+A` to open the session switcher
2. Use `↑`/`↓` or `j`/`k` to navigate
3. Press `Enter` to load the selected session

**To list and resume via command:**

1. Type `/sessions` (or `/resume` or `/continue`)
2. Browse the list of recent sessions
3. Select one to restore its full context

### CLI Commands

| Command | Description |
| :--- | :--- |
| `opencode session list` | List all sessions in table format |
| `opencode session list --format json` | List sessions as JSON |
| `opencode session list -n 5` | Show only the 5 most recent sessions |
| `opencode --continue` | Resume the last session (short: `opencode -c`) |
| `opencode --session ses_abc123` | Resume a specific session by its ID |

### Keybinds

| Keybind | Action |
| :--- | :--- |
| `Ctrl+N` | Create new session |
| `Ctrl+A` | Open session switcher |
| `Ctrl+X L` | List all sessions |
| `Ctrl+C` | Quit OpenCode |
| `Esc` | Close dialog / cancel |

---

## Strategy: Plan then Implement

The most effective way to work on complex tasks is to **split them across sessions**:

```text
Session 1: PLANNING
─────────────────────────────────────────────
  Model: lightweight / cheap (e.g. deepseek)
  Goal:  analyse requirements, produce a
         detailed step-by-step plan
─────────────────────────────────────────────
         │
         │ Copy the plan (or save to a file)
         ▼
Session 2: IMPLEMENTATION
─────────────────────────────────────────────
  Model: powerful (e.g. Claude, GPT-4)
  Goal:  execute the plan, write code,
         run tests
─────────────────────────────────────────────
```

**Why this works:**

- The planning session stays **lean and fast** — no need for a powerful model
- The implementation session starts with a **crisp, complete plan** in context
- Each session has **maximum room** in its context window for what matters
- You can use a **different model** for each phase (cheap for planning, capable for coding)

> **Pro tip:** Save the plan as a `.md` file in your project. Then in the implementation session, start by reading that file with the AI.

---

## When to Create a New Session

Create a fresh session when:

- ✅ Starting a **new feature** or **new task**
- ✅ Switching between **unrelated problems**
- ✅ The current conversation feels **slow or unfocused**
- ✅ You want to **change the AI model** mid-work
- ✅ The plan is ready and it's time to **implement**
- ✅ You need to **debug** a complex issue without history pollution

**Continue the current session when:**

- ✅ You're still working on the **same task**
- ✅ The context is not yet saturated
- ✅ You need the AI to **remember** earlier details

---

## Tips & Best Practices

1. **Name your sessions meaningfully** — OpenCode auto-titles sessions, but descriptive titles make `/sessions` much easier to navigate.
2. **Use `--continue` for quick returns** — `opencode -c` resumes your last session instantly.
3. **Fork when uncertain** — If you're unsure whether to start fresh, create a new session anyway. You can always switch back with `/sessions`.
4. **Plans are portable** — A plan written in one session works in any other. Save it as a file, not just in chat history.
5. **Match model to task** — Use fast/cheap models for exploration and planning; use powerful models for implementation and debugging.
