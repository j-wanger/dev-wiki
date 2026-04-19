# dev-wiki

A phase-based project lifecycle system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Tracks phases, decisions, tasks, and knowledge across sessions using a local `.dev-wiki/` directory in your project. Think of it as a structured project journal that Claude Code reads at session start and writes at session end.

## What It Does

- **Phase planning** with iterative knowledge retrieval, approach review, and plan review gates
- **Task tracking** with enriched TDD cycles (RED/GREEN/REFACTOR/VERIFY) and success criteria
- **Decision capture** extracted from conversations with context, rationale, and consequences
- **Session continuity** via breadcrumb files and compaction anchors that survive context window resets
- **Automated review** with 3 parallel reviewer subagents (code, artifact, knowledge)
- **Retrospectives** analyzing patterns across phases
- **Architecture scanning** with code intelligence articles per file and module
- **Harness auditing** for your Claude Code configuration health

## Prerequisites

- **Claude Code** CLI installed and working
- **Git** (hooks use git for commit tracking)
- A project directory where you want to track development lifecycle

## Installation

### 1. Copy skills

```bash
cp -R skills/dev-* ~/.claude/skills/
```

### 2. Copy rules

```bash
cp rules/dev-wiki-hooks.md ~/.claude/rules/
```

### 3. Copy hooks

```bash
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

### 4. Register hooks in settings.json

Add hook entries to `~/.claude/settings.json`. If the file doesn't exist, create it. Merge these into the existing `hooks` object:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/session-start.sh"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/session-stop.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "command": "bash ~/.claude/hooks/dev-wiki-post-commit.sh"
      },
      {
        "matcher": "Write|Edit",
        "command": "bash ~/.claude/hooks/stale-queue.sh"
      },
      {
        "matcher": "Write|Edit",
        "command": "bash ~/.claude/hooks/dev-wiki-scope-check.sh"
      }
    ]
  }
}
```

### 5. Verify installation

Start a Claude Code session in any project. You should see the session-start hook fire. Then run:

```
/dev-init
```

This bootstraps the `.dev-wiki/` directory in your project.

## Quick Start

### Initialize a project

```
/dev-init
```

Creates `.dev-wiki/` with `_CURRENT_STATE.md`, `_ARCHITECTURE.md`, `tasks.md`, `schema.md`, `index.md`, `log.md`, and initial phase articles. Also scaffolds a project-level `CLAUDE.md` if one doesn't exist.

### Start a session

```
/dev-context
```

Loads project state, processes breadcrumbs from prior sessions, checks for staleness, detects planning needs, and emits a context summary. **Run this at the start of every session.**

### Plan a phase

```
/dev-plan
```

Retrieves knowledge from wikis, asks targeted questions, proposes an approach with review gates, drafts enriched tasks, and writes everything to the dev wiki. Every phase goes through this — even trivial ones.

### Implement

Follow the TDD cycle embedded in each task: RED (verify test fails) -> GREEN (implement) -> REFACTOR -> VERIFY (run success criteria). Mark `[x]` in `tasks.md` when done.

### Review

```
/dev-review
```

Dispatches 3 parallel reviewers (code quality, artifact consistency, knowledge alignment). Presents a gate report with score and options to fix, accept, or re-review.

### End a session

```
/dev-debrief
```

Auto-detects session significance. Full mode: extracts decisions, creates journal entry, refreshes all living documents. Quick mode: updates tasks and next action. **Run this before ending any meaningful session.**

## All Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/dev-init` | Bootstrap `.dev-wiki/` | First time setup for a project |
| `/dev-context` | Load project state | Start of every session |
| `/dev-plan` | Plan a phase | When phase needs planning (0 open tasks) |
| `/dev-review` | Review completed work | After all phase tasks are done |
| `/dev-debrief` | Capture session work | Before ending a session |
| `/dev-adjust` | Mid-phase replanning | When a task is blocked or approach is wrong |
| `/dev-check` | Validate wiki integrity | When state feels stale or after long breaks |
| `/dev-scan` | Scan codebase structure | When `_ARCHITECTURE.md` is shallow or stale |
| `/dev-harness` | Audit Claude Code config | Periodic harness health check |
| `/dev-retro` | Retrospective analysis | Every 5-10 phases |

## Development Lifecycle

```
/dev-init (once)
    |
    v
/dev-context (every session start)
    |
    v
/dev-plan (per phase)
    |  - retrieves wiki knowledge
    |  - asks user questions
    |  - proposes approach + reviewer gate
    |  - drafts tasks + reviewer gate
    |  - writes to wiki
    v
implement (per task)
    |  - RED: write test, verify fail
    |  - GREEN: implement, verify pass
    |  - REFACTOR: clean up
    |  - VERIFY: run success criteria
    |  - mark [x] in tasks.md
    v
/dev-review (per phase)
    |  - 3 parallel reviewers
    |  - fix or accept findings
    v
/dev-debrief (every session end)
    |  - extract decisions
    |  - write journal
    |  - refresh living documents
    v
/dev-retro (every 5-10 phases)
    |  - analyze patterns
    |  - surface recommendations
    v
next /dev-plan ...
```

## Project Structure

After `/dev-init`, your project gets:

```
your-project/
  .dev-wiki/
    _CURRENT_STATE.md    # Living project state (next action, active phase, decisions, blockers)
    _ARCHITECTURE.md     # Structural snapshot (modules, dependencies, toolchain)
    tasks.md             # Task list grouped by phase with TDD cycles
    schema.md            # Project identity for the dev wiki
    index.md             # Article index by category
    log.md               # Chronological event log
    articles/
      phases/            # One article per phase (objective, scope, exit criteria)
      decisions/         # Extracted decisions (context, choice, consequences)
      journal/           # Session journals (what happened, problems, artifacts)
      status/            # Codebase snapshots and scan results
  .claude/
    rules/
      active-phase.md    # Compaction anchor: survives context resets
      active-knowledge.md # Phase-scoped wiki knowledge
      working-knowledge.md # Cross-phase facts with usage decay
  CLAUDE.md              # Project entry point (scaffolded by /dev-init)
```

## How Session Continuity Works

The dev-wiki system uses **breadcrumb files** and **compaction anchors** to maintain continuity:

- **Breadcrumbs** (`.session-end`, `.pending-commit`, `.session-buffer`): Written by hooks during a session, processed by `/dev-context` at the next session start. They bridge the gap between sessions.
- **Compaction anchors** (`active-phase.md`, `active-knowledge.md`): Small files in `.claude/rules/` that Claude Code loads into every message. When the context window compacts (drops older messages), these anchors restore phase context automatically.

## Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-start.sh` | SessionStart | Loads dev-wiki context into the session |
| `session-stop.sh` | Stop | Writes `.session-end` breadcrumb if debrief wasn't run |
| `dev-wiki-post-commit.sh` | PostToolUse (Bash) | Captures git commits to `.pending-commit` |
| `stale-queue.sh` | PostToolUse (Write/Edit) | Tracks modified files for incremental architecture refresh |
| `dev-wiki-scope-check.sh` | PostToolUse (Write/Edit) | Warns if editing files outside the active task's scope |

## Integration with Knowledge Wikis

The dev-wiki system optionally integrates with **knowledge wikis** (separate domain knowledge bases). During `/dev-plan`, it retrieves relevant articles from registered wikis to inform phase planning. This requires the [project-wiki skill suite](https://github.com/Recito) (separate package) and a `~/.claude/wikis.json` registry.

Without knowledge wikis, the dev-wiki suite works standalone — it just won't have domain knowledge to draw from during planning.

## File Inventory

| Directory | Files | Purpose |
|-----------|-------|---------|
| `skills/dev-wiki/` | 4 | Router + shared reference hub (1189 lines) + journey conventions + session context |
| `skills/dev-plan/` | 5 | Phase planning + approach reviewer + plan reviewer + implementation guide + iterative retrieval spec |
| `skills/dev-context/` | 1 | Session state loading |
| `skills/dev-debrief/` | 4 | Session capture + active-knowledge transition + architecture staleness + CLAUDE.md refresh |
| `skills/dev-review/` | 4 | Review gate + 3 reviewer prompts (code, artifact, knowledge) |
| `skills/dev-scan/` | 6 | Codebase scanning + architecture/file/module prompts + Python-specific checks |
| `skills/dev-check/` | 1 | Wiki integrity validation (38+ checks) |
| `skills/dev-adjust/` | 1 | Mid-phase replanning |
| `skills/dev-init/` | 3 | Project bootstrapping + CLAUDE.md scaffold template |
| `skills/dev-harness/` | 6 | Harness audit + 5 H-check companions |
| `skills/dev-retro/` | 1 | Retrospective analysis |
| `hooks/` | 5 | Session lifecycle hooks |
| `rules/` | 1 | Implementation discipline (TDD workflow, blocked-task escalation, escape hatches) |

**Total: 42 files**

## License

MIT
