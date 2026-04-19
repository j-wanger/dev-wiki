---
name: dev-debrief
description: "Use when a session ends with meaningful work. Tiered capture: full (30-60s) or quick (10-15s) mode. Do NOT use at session start (use dev-context) or to fix wiki structural issues (use dev-check)."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/_ARCHITECTURE.md, $WIKI/tasks.md, $WIKI/articles/phases/*, $ROOT/CLAUDE.md]
writes: [$WIKI/_CURRENT_STATE.md(Next Action, Journal, Key Artifacts, Cross-References), $WIKI/articles/journal/*, $WIKI/articles/decisions/*, $WIKI/log.md, $WIKI/index.md, $ROOT/.claude/rules/active-knowledge.md, $ROOT/.claude/rules/working-knowledge.md, $ROOT/CLAUDE.md]
dispatches: []
tier: complex-orchestration
---

# dev-debrief

Tiered session capture. Auto-detects session significance to choose between a full debrief (30-60s) or a quick debrief (10-15s). Full mode analyzes the conversation, extracts architectural decisions, creates a rich journal entry, and refreshes every living document. Quick mode updates tasks, writes a 3-line journal, and refreshes the next action.

This is a **single-agent skill** -- Claude does all work directly. No subagents.

---

## Section Ownership — _CURRENT_STATE.md

This skill OWNS and rewrites these sections (preserve all others verbatim):
- `## Recommended Next Action`
- `## Session Journal (last 5)`
- `## Key Artifacts`
- `## Cross-References`

Quick debrief: updates ONLY `## Recommended Next Action` and the `> Last updated` timestamp.
Full debrief: rewrites all 4 owned sections. Preserve Active Phase, Contract, Decisions, and Blockers verbatim.

---

## When to Use

- Before ending a meaningful development session
- Before context window gets full (~75% usage)
- After completing a significant piece of work
- Before a long break

**Not needed when:** The session was purely conversational with no code changes or decisions.

---

## Pre-checks

1. **Discover dev wiki.** Run `git rev-parse --show-toplevel 2>/dev/null || pwd` to find `$ROOT`. Check if `$ROOT/.dev-wiki/` exists. If not: "No dev wiki found. Run `/dev-init` to set one up." STOP.

2. **Verify living documents.** Use the Glob tool to check for `_CURRENT_STATE.md`, `_ARCHITECTURE.md`, `tasks.md`, `index.md`, and `log.md` under `.dev-wiki/`. Note any missing ones -- they will be created fresh.

3. **Ensure article directories exist:**
   ```bash
   mkdir -p "$ROOT/.dev-wiki/articles/decisions" "$ROOT/.dev-wiki/articles/journal" "$ROOT/.dev-wiki/articles/phases" "$ROOT/.dev-wiki/articles/status"
   ```

---

## Step 1: Significance Detection

Scan the conversation context and session buffer for these signals:

| Signal | Points |
|--------|--------|
| Decisions detected in conversation | +3 each |
| Commits made this session | +1 each |
| Architectural changes (new modules, changed dependencies, structural reorg) | +5 |
| Blocked tasks (tasks marked `[blocked:` this session) | +2 each |
| Phase transition (phase status changed this session) | +5 |
| Session >30 minutes (estimate from conversation length/depth) | +2 |
| <5 tool calls total in session | -3 |

| Score | Mode | Time Budget |
|-------|------|-------------|
| >= 5 | Full debrief | 30-60 seconds |
| < 5 | Quick debrief | 10-15 seconds |

Report: "Significance score: N. Running [full/quick] debrief."

---

## Quick Debrief Flow (Score < 5)

### QD Step 1: Update tasks.md
Use the Read tool on `$WIKI/tasks.md`. Cross-reference with session buffer commits and conversation to mark completed tasks `[x]`. Add any discovered tasks.

### QD Step 2: Append 3-Line Journal Entry
Create a minimal journal entry at `$WIKI/articles/journal/<today>-<slug>.md`. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section J for the quick journal template and Section A for the slugification algorithm.

### QD Step 3: Refresh _CURRENT_STATE.md Next Action
Use the Read tool on `$WIKI/_CURRENT_STATE.md`. Update ONLY `## Recommended Next Action` and the `> Last updated` timestamp. Do not rewrite the entire file.

### QD Step 3a: Architecture Staleness Detection
Run the same check as full debrief Step 9a (compare skill file mtimes against `_ARCHITECTURE.md` `Last updated` timestamp). Emit warning if stale.

### QD Step 4: Append to log.md
`[<ISO-timestamp>] DEBRIEF-QUICK -- tasks updated, quick journal, next action refreshed`

### QD Step 5: Clean Up Breadcrumbs
```bash
rm -f "$WIKI/.pending-commit" "$WIKI/.session-buffer" "$WIKI/.session-end"
```

### QD Step 6: Report to User
`Quick debrief done. Tasks: X completed, Y remaining. Next: "<next action>"`

---

## Full Debrief Flow (Score >= 5)

Throughout this flow, `$ROOT` is the project root. `$WIKI` is `$ROOT/.dev-wiki`. Today's date is `$(date +%Y-%m-%d)`.

### Step 2: Read Existing State

Use the Read tool for each of these files (skip any that do not exist):

- `$WIKI/_CURRENT_STATE.md` -- current project state
- `$WIKI/_ARCHITECTURE.md` -- project structure
- `$WIKI/tasks.md` -- tactical task list
- `$WIKI/schema.md` -- project identity and conventions

Use the Glob tool to list all files in `$WIKI/articles/phases/` and `$WIKI/articles/decisions/`, then Read each. Collect existing decision titles and aliases into a dedup list.

**Budget:** Read at most 10 articles total: active phase article + 5 most recent decisions (by `updated:` date) + 4 most recent journals. Skip status snapshots.

### Step 3: Read Session Buffer

If `$WIKI/.session-buffer` exists, use the Read tool on it. Contains accumulated commit data from PostCommit hooks. If missing, conversation analysis in Step 4 is the primary source.

### Step 4: Analyze Conversation

Analyze the **full conversation in your context window** to extract:

1. **Decisions made** -- choices where alternatives were discussed, one chosen with rationale, agreement reached
2. **Open questions** -- raised but NOT resolved during this session
3. **Problems encountered and solutions found** -- including dead ends explored
4. **Tasks completed** -- cross-reference with `tasks.md`
5. **New tasks discovered** -- not previously tracked
6. **Architectural changes** -- new modules, changed dependencies, structural reorganization
7. **Escape hatches used** -- read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section D for valid escape hatch types. Note type and justification for each deviation.
8. **Health delta** -- if `## Development Toolchain` exists in `_ARCHITECTURE.md`, compare session-end state against baseline: test count changes (new tests added/removed), type errors introduced/resolved, lint violations, tools added/removed. Include delta in journal entry under `## Health Delta` if any changes occurred.
9. **Soft observations / Phase N+1 candidates** -- if the session produced a validation-status article OR surfaced uncovered patterns, populate the optional `## Soft Observations / Phase N+1 Candidates` section in the journal entry per Section J. Source: bullet list of (observation, suggested next-phase framing, evidence link). Downstream phases use this section as their refinement-phase candidate source per [[wiki:refinement-phase-pattern]].

### Step 5: Extract Decisions

For each candidate decision from Step 4, read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section I for the full decision extraction criteria (inclusion, exclusion, signal detection, confidence levels, noise prevention).

For each qualifying decision, create a file at `$WIKI/articles/decisions/<slug>.md`. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section A for the slugification algorithm and Section I for the article template.

### Step 6: Create Journal Entry

Create ONE journal entry at `$WIKI/articles/journal/<today>-<slug>.md`. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section J for the rich journal template and Section A for slugification.

If a journal file for today with the same slug exists, append a numeric suffix.

### Step 7: Update tasks.md

Use the Read tool on `$WIKI/tasks.md`. Apply changes:

1. **Mark completed tasks** `[x]` by cross-referencing Step 4
2. **Add discovered tasks** under the appropriate phase heading
3. **Mark blocked tasks** `[blocked: reason]`
4. **Reorder** -- active phase first, then upcoming. Completed phases collapsed.

Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section B for size budgets.

### Step 8: Rewrite _CURRENT_STATE.md

Rewrite `$WIKI/_CURRENT_STATE.md` respecting section ownership. Rewrite owned sections (Recommended Next Action, Session Journal, Key Artifacts, Cross-References) from scratch. Preserve sections owned by other skills (Active Phase, Active Phase Contract, Recent Decisions, Blockers and Open Questions) verbatim. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section F for the 7-section template and Section B for size budgets.

### Step 8.5: Project CLAUDE.md Refresh Check

Read `~/.claude/skills/dev-debrief/claude-md-refresh.md` for the full refresh procedure per dev-wiki-reference.md Section U. Skip if no project `./CLAUDE.md` exists.

### Step 9: Update _ARCHITECTURE.md

Only update if structural changes occurred this session OR if the `## Development Toolchain` section needs updating (tools added/removed, config paths changed). When updating, rewrite the full file. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section G for the template and Section B for size budgets.

To scan the codebase structure, use the Glob tool with patterns like `$ROOT/src/**/*` or `$ROOT/**/*.py` (adjust for the project's language). Do NOT use `find` commands.

### Step 9a: Architecture Staleness Detection

Read `~/.claude/skills/dev-debrief/architecture-staleness-check.md` for the full procedure (catches skill files at `~/.claude/skills/` that are outside the stale-queue pipeline; runs in both full and quick debrief modes).

### Step 10: Update Phase Articles

Use the Glob tool to list phase articles in `$WIKI/articles/phases/`. For each:

- If phase became active this session, update `status: active`
- If all tasks completed AND exit criteria met, do NOT auto-complete -- note it in the report for user confirmation
- If new blocker discovered, update `status: blocked`

Phase transitions `active` -> `completed`: ALWAYS ask user, never auto-transition.

### Step 11: Create Status Snapshot

Use the Glob tool to check if `$WIKI/articles/status/$(date +%Y-%m-%d)-codebase-snapshot.md` exists. If none, create one with file metrics, module structure, dependency versions, test status, and recent commits (last 5 from `git log`).

**Scan article integration:** If `$WIKI/articles/status/*-scan.md` files exist from a prior `/dev-scan`, reference them in the snapshot rather than duplicating their content. The snapshot should summarize scan findings (module count, issue counts, hub modules), not replicate the full dependency maps.

Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section B for size budgets.

### Step 12: Update .claude/rules/active-phase.md

Always rewrite `$ROOT/.claude/rules/active-phase.md` in full debrief mode. The 10-15 line cost is negligible compared to the risk of stale compaction anchors.

Keep to 10-15 lines, 20 line hard cap. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section B for size budgets.

```markdown
# Active Phase Context

Phase: N - <Phase Name>
Objective: <one-line phase objective>
Scope: <file globs from phase article>
Key constraints:
- <constraint> (from decision: <decision-slug>)
Exit criteria:
- <criterion>
Abort: if blocked >3 attempts on any task, run /dev adjust
```

### Step 12a: Working-Knowledge Decay

Run the Section M 7-day half-life decay algorithm on `$ROOT/.claude/rules/working-knowledge.md`. This step runs BEFORE Step 12b's carry-forward writes (if any) land, so freshly carried entries are not immediately decayed.

1. If `working-knowledge.md` does not exist, skip.
2. For each entry where `today - last_decay >= 7 days`:
   - `uses = floor(uses / 2)`, minimum 1
   - Update `last_decay:` to today's date
3. After decay, evict entries where `uses: 1` AND `today - last_decay >= 21 days` (no references across 3 consecutive 7-day decay windows).
4. Re-sort remaining entries by `uses` descending. Ties broken by most recent `activated:` date.
5. If entries were decayed or evicted, note in Step 16 report: `"Working knowledge: N decayed, M evicted, K remaining."`

### Step 12b: Validate/Prune active-knowledge.md

Read `~/.claude/skills/dev-debrief/active-knowledge-transition.md` for the validate/prune/carry-forward logic. Covers two paths: phase-changed (carry forward all entries to working-knowledge, delete active-knowledge.md) and same-phase (auto-refresh stale entries). Skip if no knowledge wiki and no active-knowledge.md.

### Step 13: Rebuild index.md

Use the Glob tool to scan all files under `$WIKI/articles/`. Rebuild `$WIKI/index.md` with By Category, By Hierarchy, and Recent sections. Sort phases by numeric prefix, journal/status by date descending. Recent: last 10 articles by date.

### Step 14: Append to log.md
`[<ISO-timestamp>] DEBRIEF -- <N> decisions, 1 journal, tasks updated, state refreshed`

### Step 15: Clean Up Breadcrumbs
```bash
rm -f "$WIKI/.pending-commit" "$WIKI/.session-buffer" "$WIKI/.session-end"
```

### Step 16: Report to User

```
Session debriefed (full):
- Decisions captured: N (list titles)
- Journal: <journal entry title>
- Tasks: X completed, Y added, Z blocked
- Open questions: N carried forward
- Escape hatches used: <list or "none">
- Next action: "<recommended next action>"
```

If a phase may be ready for completion, add a note. If `active-phase.md` was updated, note that too.
If any artifact path from the session matches `~/.claude/skills/`, append: "Skill files were modified. Run `/dev-scan` to refresh `_ARCHITECTURE.md`."

---

## Stop Hook Interaction

If `/dev-debrief` was run this session, the Stop hook detects a `DEBRIEF` entry in `log.md` with today's date. It writes `.session-end` with `debriefed: yes`. The next session's `/dev-context` skips breadcrumb processing for debriefed sessions.

---

## Error Handling

- **Missing living document:** Create it fresh during the relevant step. Log a warning.
- **Malformed frontmatter:** Skip the article, note it in report, continue.
- **No git repository:** Skip git-dependent ops. Rely on conversation analysis. Note in report.
- **Empty conversation:** "No significant session activity detected. Skipping debrief." STOP.
- **File write failure:** Report the failure and continue with remaining steps.

---

## Time Budget

Full debrief: 30-60 seconds. Quick debrief: 10-15 seconds.
