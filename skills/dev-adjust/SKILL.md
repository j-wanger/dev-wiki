---
name: dev-adjust
description: "Use when a task is blocked, the plan needs modification, or implementation reveals the approach was wrong. Lightweight mid-phase replanning. Do NOT use for full phase planning or phase transitions — use dev-plan."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/tasks.md, $WIKI/articles/phases/*]
writes:
  # OWNS — direct authority for mid-phase replanning
  - $WIKI/tasks.md(active-phase section)
  - $ROOT/.claude/rules/active-phase.md
  - $WIKI/articles/phases/*(updated field, inline scope/constraint amendments; NOT status field)
  - $WIKI/articles/journal/*(adjustment entries)
  # MAY UPDATE — cross-skill coordination (sections primarily owned elsewhere)
  - $WIKI/_CURRENT_STATE.md(Recommended Next Action, Active Phase Contract, Blockers)
dispatches: []
tier: complex-orchestration
---

<!-- Convention: see dev-wiki-reference.md Section V (Journey Integration Conventions); tier reclassified simple→complex Phase 26 per skill-size-tiering.md Addendum: Tier Reclassifications -->

# dev-adjust

Lightweight mid-phase replanning. Modify the current plan without a full `/dev plan` cycle. Read current state, hear the problem, propose adjusted tasks, get approval, write updates.

This is a **single-agent skill** -- Claude does all work directly. No subagents.

---

## Section Ownership

Mid-phase replanning touches shared files owned by other skills. 3-bucket pattern adapted from dev-context per [[wiki:harness-composition-playbook]] invariant #4 + [[wiki:skill-file-authoring]] §Writes-Metadata Fidelity.

OWNS (direct authority):
- `$WIKI/tasks.md` active-phase section — task reorder, blocked-mark, additions, size retag
- `$ROOT/.claude/rules/active-phase.md` — full rewrite when constraints/exit-criteria change mid-phase
- `$WIKI/articles/phases/*` `updated:` + inline scope/constraint amendments (NOT `status:` — that's /dev-plan + /dev-debrief)
- `$WIKI/articles/journal/<today>-adjustment-<slug>.md` — NEW per invocation

MAY UPDATE `$WIKI/_CURRENT_STATE.md` sections (owned elsewhere, coordinated on mid-phase adjustment):
- `Recommended Next Action` (/dev-debrief-owned; update when next-pending-task shifts)
- `Active Phase Contract` (/dev-plan-owned; update task count + constraint changes)
- `Blockers` (append-only)

All other sections: read-only. Never touches `## Active Phase`, Recent Decisions, Session Journal, Key Artifacts, Cross-References, `_ARCHITECTURE.md`, `schema.md`, phase `status:` field, or non-journal articles.

---

## When to Use

- A task turns out to be impossible as scoped
- Tests fail and reveal a design assumption was wrong
- User changes priorities mid-phase
- A prerequisite was missed during planning
- A task has been marked `[blocked]` after 3 failed attempts

Do NOT use for starting a new phase or full replanning (use `/dev plan`). Do NOT use for session capture (use `/dev debrief`).

---

## Pre-checks

1. **Discover dev wiki.** Locate `.dev-wiki/` at project root:
   ```bash
   ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   ```
   Check `$ROOT/.dev-wiki/_CURRENT_STATE.md`. If missing: "No dev wiki found. Run `/dev init` first." STOP.

2. **Verify active phase has tasks.** Read `$ROOT/.dev-wiki/tasks.md`. If the active phase has 0 tasks: "No tasks to adjust. Run `/dev plan` to create a plan." STOP.

Throughout this flow, `$ROOT` is the project root. `$WIKI` is `$ROOT/.dev-wiki`. Today's date is `$(date +%Y-%m-%d)`.

---

## Orchestration Flow

### Step 1: Read Current State

Use the Read tool on each of these files silently. Do NOT print their contents to the user.

- `$WIKI/tasks.md` -- completed vs remaining tasks
- `$WIKI/_CURRENT_STATE.md` -- blockers, open questions, active phase contract
- Active phase article from `$WIKI/articles/phases/` (use the Glob tool to find it)

**Scan article integration:** Glob `$WIKI/articles/status/*-scan.md`. If found, read scan articles for modules within the active phase scope. Use the **Connected Files** section to assess blast radius of proposed task changes (which other files are affected?) and the **Issues** section to check if known issues relate to the blocked/failing task.

Note which tasks are completed, which are pending, which are blocked.

**Time budget:** 3-5 seconds. No codebase exploration. No cross-wiki lookup.

### Step 2: User States the Problem

Prompt the user if they have not already stated the problem:

```
What needs to change? Examples:
- "Task 3 is blocked because DuckDB MERGE has different semantics"
- "We need a prerequisite task before task 2"
- "The hashing approach from the plan won't work -- need UUID instead"
- "Priorities changed -- skip tasks 4-5, add a new task for X"
```

Wait for the user's response. Understand the problem before proposing changes.

### Step 3: Propose Adjusted Tasks

Based on the user's problem statement and the current task state:

1. **Preserve completed tasks.** Never undo work that is done.
2. **Modify remaining tasks** as needed:
   - Change descriptions, scope, success criteria, or size
   - Reorder tasks
   - Remove tasks that are no longer relevant
   - Add new prerequisite tasks
   - Unblock tasks by changing their approach
3. **Present the diff clearly:**

```
Proposed adjustment:

KEEP (completed):
  [x] Task 1: <description>
  [x] Task 2: <description>

MODIFIED:
  [ ] Task 3 (was: "<old>", now: "<new>") | scope: <globs> | success: <criterion> | size: M
  
REMOVED:
  Task 5: <description> -- reason: <why>

ADDED:
  [ ] Task 3a (NEW): <description> | scope: <globs> | success: <criterion> | size: S

UNCHANGED:
  [ ] Task 4: <description>

Approve?
```

### Step 4: User Approves Adjustment

Wait for explicit user approval.

If the user requests further changes, revise and re-present. **Maximum 3 revision rounds.** After 3: "Consider running /dev plan for a full replan if the scope has changed significantly."

### Step 5: Write Updates

Apply all changes atomically:

#### 5a: Update tasks.md

Rewrite the active phase section in `$WIKI/tasks.md` with the approved task list. Preserve the task schema format (TDD cycle, scope, success, size). Keep completed phases and upcoming phases unchanged.

#### 5b: Update _CURRENT_STATE.md

Update these sections:
- `## Recommended Next Action` -- set to the next pending task.
- `## Blockers and Open Questions` -- update with any new blockers or resolved questions.
- `## Active Phase Contract` -- update task count if it changed.

#### 5c: Update active-phase.md

If the adjustment changed constraints or exit criteria, update `$ROOT/.claude/rules/active-phase.md` to reflect the new constraints. If constraints are unchanged, skip this.

#### 5d: Update TodoWrite

Mirror the adjusted task list to TodoWrite. Preserve completion status of done tasks. Update descriptions of modified tasks.

#### 5e: Create Journal Entry

Ensure journal directory exists: `mkdir -p "$WIKI/articles/journal"`

Create a brief journal entry at `$WIKI/articles/journal/<today>-adjustment-<slug>.md`. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section A for the slugification algorithm.

Use journal frontmatter from Section J of dev-wiki-reference.md with `source: adjust`, `tags: [adjustment]`. Body (10-15 lines): ## What Changed (bullets), ## Why (user reason), ## Related (phase link).

#### 5f: Append to log.md

```
[<ISO-timestamp>] ADJUST -- <brief description>, N tasks modified
```

#### 5g: Report to User

Report: tasks modified/added/removed counts, next task description, and whether active-phase.md was updated.

---

## Error Handling

- No `.dev-wiki/` found: "No dev wiki found. Run `/dev init` first." STOP.
- No active phase tasks: "No tasks to adjust. Run `/dev plan`." STOP.
- File write failure: report and continue with remaining writes.

For working-knowledge partitioning conventions (Section M) and data flow impact of scope changes (Section G), see dev-wiki-reference.md.
