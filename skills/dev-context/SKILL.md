---
name: dev-context
description: "Load project development state into the current session. Run at session start. Do NOT use for planning, validation, or session capture — use dev-plan, dev-check, or dev-debrief respectively."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/_ARCHITECTURE.md, $WIKI/tasks.md, $WIKI/articles/phases/*, $ROOT/.claude/rules/active-knowledge.md, $ROOT/.claude/rules/working-knowledge.md]
writes: [$WIKI/_CURRENT_STATE.md(Blockers, Journal, Key Artifacts)]
dispatches: []
tier: complex-orchestration
---

# dev-context

Load the project's dev wiki state into the current session. Discovers wiki, processes breadcrumbs, reads living documents and active phase, checks staleness, detects planning needs, and emits a context summary. Single-agent, target time: 3-5 seconds.

---

## Section Ownership — _CURRENT_STATE.md

This skill OWNS:
- `## Blockers and Open Questions` (breadcrumb-derived updates only — clear resolved blockers, add newly discovered ones from breadcrumb processing)

May UPDATE during breadcrumb processing (Step 2):
- `## Session Journal (last 5)` — append mechanical journal entry, keep last 5
- `## Key Artifacts` — update if breadcrumbs indicate meaningful file changes

All other sections: read-only. Never rewrite Active Phase, Contract, Decisions, Next Action, or Cross-References.

## Pre-checks

Both `.dev-wiki/` and `.dev-wiki/_CURRENT_STATE.md` must exist (in CWD or git root). If missing: "No dev wiki found. Run `/dev-init` to create one." / "Dev wiki incomplete. Run `/dev-init` to repair." Then STOP.

---

## Phase 1: Breadcrumb Processing (Steps 1-2)
**Skip condition:** No breadcrumb files exist (`.session-end`, `.pending-commit`, `.session-buffer`). If skipped, proceed directly to Phase 2.

## Step 1: Discover Dev Wiki

Locate the dev wiki root:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

Check `$ROOT/.dev-wiki/` for existence. Set `WIKI_PATH` to the absolute path of the `.dev-wiki/` directory. All subsequent steps use `WIKI_PATH`.

If `.dev-wiki/` is not found at `$ROOT`, also check `$PWD/.dev-wiki/`. If neither location has it, STOP with the "No dev wiki found" message from Pre-checks.

## Step 2: Process Breadcrumbs from Prior Session

Check for breadcrumb files in `WIKI_PATH`. Process them in this priority order:

### Case A: `.session-end` exists

A prior session ended without running `/dev-debrief`.

1. Read `.session-end` for session-end metadata (timestamp, pending_commit status, session_buffer status, recent commits, uncommitted files).
2. If `debriefed: yes` is present, delete `.session-end` and continue to Step 3 (prior session already debriefed).
3. If `debriefed: no` (or absent) AND `.session-buffer` exists: read `.session-buffer`, create a mechanical journal entry (see Journal Entry Format below), write to `WIKI_PATH/articles/journal/YYYY-MM-DD-<slug>.md`, update `_CURRENT_STATE.md` (Session Journal — keep last 5; Key Artifacts if meaningful changes), append to `log.md`, update `index.md`.
4. Delete all breadcrumb files: `.session-end`, `.pending-commit`, `.session-buffer`.
5. Note to user: "Previous session ended without debrief. I've created a basic journal entry from commit data."

### Case B: `.pending-commit` exists (but no `.session-end`)

A commit was recorded but the session continued (or crashed without the Stop hook firing).

1. Read `.pending-commit` for the latest commit data.
2. Check `WIKI_PATH/tasks.md` -- if any open task matches the commit message or committed files, mark it `[x]`.
3. Delete `.pending-commit`.

### Case C: No breadcrumbs

Nothing to process. Continue to Step 3.

## Mechanical Journal Entry Format

Read Section J (mechanical journal template) and Section A (slugification) from dev-wiki/dev-wiki-reference.md. Mechanical journals are factual (data-only, 20-40 lines).

## Phase 2: Incremental Refresh (Step 2.5)
**Skip condition:** `.stale-queue` does not exist or is empty. If skipped, proceed directly to Phase 3.

## Step 2.5: Process Stale Queue (Incremental Refresh)

If `WIKI_PATH/.stale-queue` exists and is non-empty, process changed files per Section R read protocol of dev-wiki/dev-wiki-reference.md:

1. Read all paths, deduplicate, validate each matches `[a-zA-Z0-9_./-]+` (discard invalid with warning)
2. Process first **10 entries** (FIFO — oldest first; cap prevents slow startup)
3. For each path:
   - File exists: `shasum -a 256 <file> | cut -c1-16`, compare to article's `content_hash` in `WIKI_PATH/articles/files/<path-slug>.md`. If mismatch: update frontmatter `content_hash`. Only regenerate full article content if exports/imports changed (grep for export/import statements and diff against article).
   - File deleted: remove file article, update parent module article's `files` list
   - No article exists: skip (new file without prior scan — handled by next `/dev-scan`)
   - Processing fails: keep entry in queue for next session
4. Recompute composite hash for affected module articles (Section Q algorithm)
5. Remove **only successfully processed** entries from `.stale-queue`
6. If entries remain: keep for next session
7. **Soft warning** at 100+ entries: `"Stale queue has N entries. Consider /dev-scan."`
8. Report: `"[dev-wiki] Incremental refresh: N updated, M removed, K skipped."`

If `.stale-queue` does not exist or is empty: skip silently.

## Phase 3: State Loading + Emit (Steps 3-8)
**Skip condition:** None -- always runs. This is the core of dev-context.

## Step 3: Read Living Documents

Read silently (inject into context, do NOT print):

1. `WIKI_PATH/_CURRENT_STATE.md` -- project state, next action, active phase, decisions, blockers (required)
2. `WIKI_PATH/_ARCHITECTURE.md` -- project structure, modules, dependencies, data flow (note absence; do not STOP)
3. `WIKI_PATH/tasks.md` -- tactical task list grouped by phase (note absence; do not STOP)
4. `$ROOT/.claude/rules/active-knowledge.md` -- phase-scoped activated knowledge (optional — skip silently if absent)

## Step 4: Check Staleness

Parse `> Last updated: YYYY-MM-DDTHH:MM:SS by /dev-debrief` from `_CURRENT_STATE.md`. Calculate age in days.

| Age | Action |
|-----|--------|
| > 7 days | Strong warning: "State is N days stale. Run `/dev-debrief` to refresh." |
| 2-7 days | Mild note: "State is N days old." |
| 0-1 days | No warning. |

If unparseable: "Could not determine state freshness. Consider running `/dev-debrief`."

## Step 5: Read Active Phase Article

From `_CURRENT_STATE.md` `## Active Phase` section, find the `[[phase-slug|Phase Title]]` link. Read `WIKI_PATH/articles/phases/<phase-slug>.md` and extract `title`, `status`, `exit_criteria` (frontmatter) and progress estimate (`_CURRENT_STATE.md` Active Phase section). Inject full article silently.

If no active phase, note: "No active phase. All phases may be complete, or phases need to be defined."

### Step 5a: Fast-Lint (Quick Drift Detection)

Run 4 quick checks (~2 seconds total). If ANY fail, emit `"[dev-wiki] Drift detected. Run /dev check for full diagnosis."` Do NOT stop — continue to Step 6.

1. **S1: Active phase exists.** If `_CURRENT_STATE.md` references a phase via `[[phase-slug|...]]`, verify the article exists on disk.
2. **S2: active-phase.md sync.** Compare the `Phase:` field in `.claude/rules/active-phase.md` against the active phase in `_CURRENT_STATE.md`. Must match.
3. **S4: Single active phase.** Glob phase articles — count how many have `status: active` in frontmatter. 0 or 1 is valid; >1 is drift.
4. **C1: Task-phase alignment.** Verify the active phase section exists in `tasks.md`.

## Step 6: Detect Planning Needs

Count task states within the active phase section of `tasks.md` (open: `- [ ]`, completed: `- [x]`, blocked: `- [blocked:`). Apply these rules in order:

| Condition | Planning suggestion |
|-----------|-------------------|
| 0 open tasks AND 0 completed tasks | "Phase N needs planning. Run `/dev plan`." |
| 0 open tasks AND completed > 0 | "Phase N may be complete. Confirm completion or run `/dev plan` for next phase." |
| Has open tasks AND has blocked tasks | "Continue implementation. X/Y tasks remaining. N tasks blocked. Consider `/dev adjust`." |
| Has open tasks, none blocked | "Continue implementation. X/Y tasks remaining." |

Where X = completed count and Y = total count (open + completed + blocked).

Include the planning suggestion in the context block output (Step 8).

### Step 6a: Validate active-knowledge.md Phase Match

If `active-knowledge.md` was loaded in Step 3, parse its `## Phase: N - <Name>` line and compare to the active phase in `_CURRENT_STATE.md`. On mismatch, emit: `"Active knowledge references Phase X but active phase is Y. Delete file or re-plan."` If not loaded, skip.

## Step 7: Check Knowledge Wiki

Check `./wiki/schema.md` (relative to project root, NOT inside `.dev-wiki/`). If it exists, read it for the wiki name and read `./wiki/index.md` for article count; include a summary line in the context block. If absent, omit the knowledge wiki line entirely.

### Step 7a: Check Working Knowledge

Check `.claude/rules/working-knowledge.md` (relative to project root). See Section M of dev-wiki/dev-wiki-reference.md for the specification.

If it exists:
1. Count entries (`- [uses:` lines). Flag unparseable entries as parse errors.
2. Count stale entries: parseable entries where today - `activated:` date > 21 days AND `uses` < 2. Skip unparseable entries.
3. Emit: `Working knowledge: N entries (M stale)`. Append `(P parse errors — run /dev check W3)` if any. Add `"Consider running /wiki-query to trigger decay, or manually prune."` if >10 stale.

If absent, omit the working knowledge line entirely.

**Cross-package ownership:** dev-context reads but NEVER writes to working-knowledge.md.

### Step 7b: Knowledge-Gap Detection

If a knowledge wiki exists (Step 7) AND any of: (a) both `active-knowledge.md` and `working-knowledge.md` are absent/empty, OR (b) `active-knowledge.md` failed the phase-match check in Step 6a: emit `KNOWLEDGE: No domain knowledge loaded. Run /wiki-query to activate relevant facts.` If either file has valid, phase-matched content, skip.

### Step 7c: Cadence Diagnostics

Count completed phases: Glob `$WIKI/articles/phases/*.md`, read each, count those with `status: completed` in frontmatter. If count > 0 AND count % 5 == 0: emit `"DIAGNOSTICS: N completed phases — consider /dev-retro."` Parse `_ARCHITECTURE.md` line 3 for `> Last updated:` date. If age > 3 days: emit `"DIAGNOSTICS: _ARCHITECTURE.md is N days stale — consider /dev-scan."`

## Step 8: Emit Context Block

Print a context block to the user. The format depends on whether there are open tasks (execution mode) or not (planning mode).

### 8A: Planning Mode (0 open tasks, or no tasks at all)

```
[dev-wiki] Project state loaded.

NEXT ACTION: <from _CURRENT_STATE.md>  (If empty: "No recommended action set.")
ACTIVE PHASE: <phase title> (<progress>)
OPEN QUESTIONS: <count>
RECENT DECISIONS: <count>
TASKS: <done>/<total> in active phase
PLANNING: <suggestion from Step 6>
ACTIVE KNOWLEDGE: <N entries for Phase M> | not present

KNOWLEDGE: <hint from Step 7b if triggered> | omit if not triggered
HEALTH: <test framework> (<test count>), <type checker> (<mode>), <linter> | venv: <strategy> | not scanned
SCAN: <N modules scanned, M issues (H high)> | not scanned -- /dev-scan for deep analysis
Knowledge wiki: <name> (<count> articles) -- /wiki-query for domain questions
Working knowledge: <N entries> (<M stale>) | not present
DIAGNOSTICS: <retro/scan reminders from Step 7c> | omit if none
```

**HEALTH line:** Parse `## Development Toolchain` from `_ARCHITECTURE.md`. Summarize detected tools in one line. If section absent: `HEALTH: not scanned`. If no tools: `HEALTH: no tools detected`.

### 8B: Execution Mode (has open tasks — the common case)

Find the first `- [ ]` task for the active phase. Parse its enriched fields. Read `.claude/rules/active-phase.md` for constraints. Emit:

```
[dev-wiki] Execution mode. Resuming <phase title>.

NEXT TASK: <task description>
  TDD: <test spec (RED) → implement (GREEN) → refactor>
  SCOPE: <file globs from task>
  SUCCESS: <testable criterion>
  SIZE: <S/M/L>
  CONSTRAINTS: <key constraints from active-phase.md>

PROGRESS: <done>/<total> tasks | <blocked> blocked
EXIT CRITERIA: <from phase article>
OPEN QUESTIONS: <count>

ACTIVE KNOWLEDGE: <N entries for Phase M> | not present

Work this task following TDD. Mark [x] in tasks.md when done.
Next task after this: <preview of the task after the current one, or "last task in phase">

KNOWLEDGE: <hint from Step 7b if triggered> | omit if not triggered
HEALTH: <test framework> (<test count>), <type checker>, <linter> | venv: <strategy> | not scanned
SCAN: <N modules scanned, M issues (H high)> | not scanned -- /dev-scan for deep analysis
Knowledge wiki: <name> (<count> articles)
Working knowledge: <N entries> (<M stale>) | not present
DIAGNOSTICS: <retro/scan reminders from Step 7c> | omit if none
```

**Scan article detection:** Glob `WIKI_PATH/articles/status/*-scan.md`. If found, count articles and parse any `## Issues` sections to tally issue counts by severity. Include in the SCAN line. If not found, show "not scanned".

Parse enriched fields by splitting on `|` and extracting `key: value` pairs. If no enriched fields, show: `(No enriched fields — run /dev plan)`

After printing the context block, include any staleness warnings from Step 4.

The full content of `_CURRENT_STATE.md`, `_ARCHITECTURE.md`, `tasks.md`, and the active phase article has already been read and is available in context for the remainder of the session. Do NOT print these documents — they are silently available.
