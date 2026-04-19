# Dev Wiki Reference

Shared reference material for the dev wiki skill suite (`dev-init`, `dev-plan`, `dev-debrief`, `dev-context`, `dev-adjust`, `dev-scan`, `dev-check`, `dev-review`, `dev-retro`). Skills reference specific sections by letter (A-T).

---

## Section A: Slugification Algorithm

Used for all generated filenames (phase articles, decision articles, journal entries).

1. Strip conventional-commit prefix (`feat:`, `fix:`, `refactor:`, etc.) if present
2. Lowercase
3. Replace spaces and underscores with hyphens
4. Remove all characters except `[a-z0-9-]`
5. Collapse multiple hyphens to single
6. Strip leading/trailing hyphens
7. Truncate to 50 characters (at word boundary if possible)

**Filename patterns:**
- Phase files: `phase-NN-<slug>.md` (zero-pad to two digits)
- Decision files: `<slug>.md` (append `-2`, `-3` if exists)
- Journal files: `YYYY-MM-DD-<slug>.md` (append `-2`, `-3` if exists)
- Status files: `YYYY-MM-DD-codebase-snapshot.md`
- File articles: `articles/files/<path-slug>.md`
- Module articles: `articles/modules/<module-slug>.md`

**Path-to-slug algorithm (for code articles):**

All paths are relative to `$ROOT` (the directory containing `.dev-wiki/`). The output is called a **path-slug** for both file and module articles.

_File path-slugs:_
1. Start from project-relative path (e.g., `src/auth/middleware.ts`)
2. Remove the file extension (last `.ext` segment only)
3. Replace `/` and `.` with `-`
4. Apply standard slug rules (steps 2-7 above), but truncate to **64 characters** (not 50 — paths need more room)

_Module path-slugs:_
1. Start from project-relative directory path (e.g., `src/auth/`)
2. Strip trailing `/`
3. Replace `/` with `-`
4. Apply standard slug rules (64-char truncation)

**Worked examples:**

| Source Path | Type | Path-Slug |
|-------------|------|-----------|
| `src/auth/middleware.ts` | file | `src-auth-middleware` |
| `src/auth/jwt-verify.ts` | file | `src-auth-jwt-verify` |
| `src/config/db.config.ts` | file | `src-config-db-config` |
| `lib/utils/string_helpers.rb` | file | `lib-utils-string-helpers` |
| `.eslintrc.js` | file | `eslintrc` |
| `src/auth/` | module | `src-auth` |
| `tests/unit/` | module | `tests-unit` |

**Collision handling:** If two paths produce the same path-slug (e.g., `src/a-b/c.ts` and `src/a/b-c.ts` both → `src-a-b-c`), append `-2`, `-3` to the later-created article. Dotfiles may also collide with same-named extensioned files (e.g., `.env` and `env.ts` both → `env`). In practice, collisions are rare.

### Recognized Extensions (for drift checks)

The authoritative list of file extensions stripped by step 2 of the file path-to-slug algorithm is `{md, sh, ts, py, json, yaml}`. /dev-scan's Step 6a slug-drift regression check enumerates the same set.

**Extension-expansion protocol:** when a new extension enters /dev-scan scope, edit this list AND update the /dev-scan Step 6a regex in lockstep; failure to edit both produces the exact silent-false-PASS class the enumeration exists to prevent (see [[wiki:silent-false-pass-pattern-family]]).

---

## Section B: Size Budgets

| Artifact | Target | Hard Cap | Overflow Action |
|----------|--------|----------|-----------------|
| `_CURRENT_STATE.md` | 80 lines | 100 lines | Truncate journal to 3, decisions to 3 |
| `_ARCHITECTURE.md` | 60-80 lines | 100 lines | Collapse test org, reduce tree depth |
| `tasks.md` | 60 lines active | 120 with collapsed | Collapse completed phases into `<details>` |
| Decision article | 30-60 lines | 80 lines | Trim consequences, link to related |
| Phase article | 40-80 lines | 120 lines | Summarize scope, reduce notes |
| Journal entry | 20-40 lines | 60 lines | Summarize, don't enumerate every change |
| Status snapshot | 30-50 lines | 80 lines | Drop least-useful sections |
| File article | 30-60 lines | 80 lines | Drop Key Logic, cap Exports to 10, cap Dependents to 10 |
| Module article | 20-40 lines | 60 lines | Cap Files to 15 with "...and N more", trim Dependencies |
| `active-phase.md` | 10-15 lines | 20 lines | Trim to essential constraints only |
| `active-knowledge.md` | 30 lines | 40 lines | Re-distill if >30, hard-fail if >40 |
| `working-knowledge.md` | 100 entries | 210 lines | LRU eviction at entry cap, 7-day decay |
| `schema.md` | 30-50 lines | 80 lines | Condense conventions |

---

## Section C: Task Schema

Each task in `tasks.md` follows this format:

```
- [ ] <Description>: test <what to test> (RED), implement <what to build> (GREEN), <refactor note> (REFACTOR) | scope: <globs> | success: <criterion> | size: S
```

Valid size values: `S` (<5 tool calls), `M` (5-20), `L` (20-50). Use exactly one letter — do NOT write `S|M|L` as the `|` character is the field delimiter.

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Description | Yes | What the task accomplishes |
| RED | Yes | What test to write and what it should assert |
| GREEN | Yes | What implementation makes the test pass |
| REFACTOR | No (skip for S) | What to clean up after GREEN passes |
| scope | Yes | File globs this task touches (subset of phase scope) |
| success | Yes | Testable criterion -- must be verifiable by running a command |
| size | Yes | S (<5 tool calls), M (5-20), L (20-50) |
| data_contract | No | OPTIONAL. What data this task reads and writes beyond code files. Format: `data_contract: reads <config.json, $DB_URL env>, writes <output.csv, cache/>`. Omit for pure-code tasks with no data I/O. Helps track data flow at task granularity per Section G conventions. |

### Task States

| State | Syntax | Meaning |
|-------|--------|---------|
| Pending | `- [ ]` | Not yet started |
| Done | `- [x]` | Completed, verified |
| Blocked | `- [blocked: reason]` | Stuck, needs user input or `/dev adjust` |

### Size Guidelines

- **S (Small):** Single test + single implementation file. Config changes, utility functions, type definitions.
- **M (Medium):** Multiple test cases + implementation spanning 2-3 files. Standard feature work.
- **L (Large):** Complex feature with integration tests. At most 1 per phase. Consider splitting if possible.

### Task Ordering

Order tasks by dependency. If task B depends on task A, A comes first. Independent tasks can be in any order.

### Plan Review Dimensions

Applied by the plan reviewer subagent (Step 7.5) before tasks are committed. Knowledge completeness is the primary gate — checked first because insufficient knowledge produces both approach and task-level gaps.

| # | Dimension | Pass Criterion | Severity if Failed |
|---|-----------|---------------|-------------------|
| 1 | Knowledge completeness | ≥70% key concepts have wiki coverage or gaps noted | CRITICAL |
| 2 | Task completeness | All enriched fields present (description, TDD, scope, success, size) | HIGH |
| 3 | Exit criteria coverage | Bidirectional: every criterion ↔ ≥1 task | CRITICAL |
| 4 | Knowledge alignment | Tasks reflect retrieved wiki patterns | HIGH |
| 5 | Size compliance | ≤1 L task, tags present, sizes reasonable | HIGH |
| 6 | Dependency ordering | No task references output of a later task | HIGH |
| 7 | Scope precision | File globs, not vague descriptions; subset of phase scope | MEDIUM |

See `~/.claude/skills/dev-plan/plan-reviewer-prompt.md` for the full reviewer checklist.

---

## Section D: Escape Hatches

Permitted deviations from plan (explain in commit message): **SECURITY:** Fix vulnerability immediately. **DEPENDENCY:** Do prerequisite first. **USER OVERRIDE:** Follow user, note deviation. **DISCOVERY:** Add precondition to tasks.md.

---

## Section E: Blocked Task Escalation Protocol

After 3 failed attempts: mark `[blocked: <what failed>]` in `tasks.md`. Ask user: `Task "<desc>" is blocked: <reason>. A) Skip B) /dev adjust C) Abort phase`. Do NOT silently skip.

---

## Section F: _CURRENT_STATE.md Template

7-section living document. Rewrite fully on each update (do NOT patch).

```markdown
# Project: <project-name>

> Last updated: <ISO-timestamp> by /<skill-name>

## Recommended Next Action

<One concrete sentence: what the developer should do next when they resume.>

## Active Phase

**[[<phase-slug>|<Phase Title>]]** (status: <status>)

Entry criteria: MET | NOT MET
Exit criteria: <current state of exit criteria>

Progress: ~<percentage>% (<brief description>)

## Active Phase Contract

Phase: N - Name
Tasks: X (see tasks.md)
Transition: continue | new-session | subagent
Abort: if blocked >3 attempts, run /dev adjust

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[<decision-slug>]] | <confidence> | <date> |

## Blockers and Open Questions

- <Question or blocker with context> (raised <date>)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| <path> | <purpose> | <date> |

## Session Journal (last 5)

- [<date>] [[<journal-slug>]] -- <brief description>

## Cross-References

- <Cross-wiki links if applicable>
```

### Per-Section Ownership

Section-pivoted aggregate view. The per-skill `## Section Ownership` blocks in consumer SKILL.md files are the authoritative source for owned-sections enumeration; this table derives a section-indexed view for template consumers. Update SKILL.md blocks FIRST when ownership shifts; refresh this table second (derived view).

| Section | OWNS (primary writer) | MAY APPEND / UPDATE |
|---------|----------------------|---------------------|
| Recommended Next Action | dev-debrief (full + quick modes) | — |
| Active Phase | dev-plan (rewrites status active, ~0%) | dev-debrief (flips status active → completed at phase close) |
| Active Phase Contract | dev-plan (rewrites at phase plan) | — |
| Recent Decisions | dev-plan (rewrites at phase plan) | — |
| Blockers and Open Questions | dev-plan (appends `[planning]` items, never removes) | dev-context (clears resolved + appends breadcrumb-derived); dev-adjust (mid-phase replanning) |
| Key Artifacts | dev-debrief (full mode rewrite) | dev-context (updates from breadcrumb-detected meaningful changes) |
| Session Journal (last 5) | dev-debrief (full + quick modes; keeps last 5) | dev-context (appends mechanical entry from `.session-buffer` breadcrumb when prior session ended without debrief) |
| Cross-References | dev-debrief (full mode rewrite) | — |

**Drift-prevention contract.** When a SKILL.md `## Section Ownership` block adds, removes, or reassigns an owned section, edit that SKILL.md first; this Section F table second. Reverse order risks silent paired-enumeration drift per [[wiki:bidirectional-update-contract]] cousin reasoning. Single source of truth: SKILL.md blocks.

---

## Section G: _ARCHITECTURE.md Template

7-section structural snapshot. Filter out noise directories: `__pycache__`, `.venv`, `venv`, `node_modules`, `.git`, `.dev-wiki`, `.tox`, `dist`, `build`, `.mypy_cache`, `.pytest_cache`, `*.egg-info`.

```markdown
# Architecture: <project-name>

> Last updated: <ISO-timestamp> by /<skill-name>

## Directory Layout

<project-root>/
  <dir>/                # <purpose> (<N> files)

## Module Responsibilities

| Module | Purpose | Key Entry Points | Inputs | Outputs |
|--------|---------|-----------------|--------|---------|

Inputs/Outputs columns track DATA dependencies (config files, data files, APIs, env vars consumed/produced), not code imports. Leave empty for pure-logic modules with no data I/O.

## Dependencies

| Package | Version | Role |
|---------|---------|------|

## Data Flow

This section tracks DATA dependencies across modules — what each module reads (config files, data files, APIs, databases, env vars) and what it writes (output files, DB records, artifacts, API calls). This is distinct from code-level imports tracked in `## Module Responsibilities` and file articles.

| Module | Reads (data) | Writes (data) | Env Vars | Notes |
|--------|-------------|---------------|----------|-------|
| <module> | <config.json, input.csv> | <output.db, report.html> | <DB_URL, API_KEY> | <pipeline stage, optional> |

Populate incrementally: `/dev-scan` seeds from static analysis where possible; `/dev-debrief` updates when data flow changes are observed during a session. Leave rows empty for modules with no data I/O. For complex data pipelines, add a prose paragraph below the table describing the end-to-end flow.

## Test Organization

| Directory | What It Tests | Count |
|-----------|---------------|-------|

## Development Toolchain

| Category | Tool | Config Path | Status |
|----------|------|-------------|--------|

Categories: Testing, Type Checking, Linting/Formatting, Dependency Management, Build System, Virtual Environment. Status: `detected`, `not detected`, or `configured (no files)`. Written by `/dev-scan` toolchain detection. Updated by `/dev-debrief` when tools change. Read by `/dev-context` (HEALTH line) and `/dev-plan` (pre-implementation gate). If not yet scanned, omit this section entirely (do not write an empty table).

## Related

- <cross-wiki links or "None yet">
```

---

## Section H: Phase Article Template

### Frontmatter

```yaml
---
title: "Phase N: Name"
aliases: []
category: phases
tags: []
parents: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: init | plan
status: not-started | active | completed
scope: ["path/globs/*"]
entry_criteria: "..."
exit_criteria: "..."
---
```

### Body

```markdown
# Phase N: Name

## Objective

<1-2 sentences describing what this phase accomplishes>

## Scope

Files and modules affected:
- `path/to/module/*`

## Exit Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>

## Notes

<Any relevant context from project analysis>
```

---

## Section I: Decision Article Template

### Frontmatter

```yaml
---
title: "<Decision Title>"
aliases: [<alias1>, <alias2>]
category: decisions
tags: [<relevant-tags>]
parents: [<parent-phase-slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: debrief | plan
confidence: high | medium | low
---
```

### Body (3 required sections)

```markdown
## Context

<Why this decision was needed. What problem or trade-off prompted it.>

## Decision

<What was chosen and why. Reference alternatives considered.>

## Consequences

<What follows from this decision. Trade-offs accepted. Future implications.>
```

### Decision Extraction Criteria

**Include if ALL true:** 2+ alternatives discussed, one chosen with rationale, affects architecture/tooling/data/workflow, user confirmed.
**Exclude if ANY true:** mechanical implementation detail, temporary spike, style preference (unless project-wide), unresolved question, already captured (dedup by title/aliases).

**Signal words:** "let's go with", "decided to", "chose X over Y", "agreed on", "settled on"

**Confidence:** `high` = explicit confirmation + reasoning. `medium` = implicit agreement. `low` = user said "ok" without engaging (only for data model/architecture).

**Noise prevention:** Dedup against existing. Min 2 messages of discussion. Max 5 per session.

---

## Section J: Journal Entry Templates

### Rich Journal (from /dev-debrief full mode)

Body structure (target 20-40 lines, hard cap 60):

```markdown
# <Session Title>

## What Happened
- <Rich description of work done -- includes discussion, dead ends, exploration>
- <Include context that git log alone would not capture>

## Decisions Made
- [[<decision-slug>|<Decision Title>]] -- extracted this session

## Problems Solved
- <Problem description> -- <How it was resolved>

## Open Questions
- <Question with enough context to understand later>

## Artifacts Changed
- `<file-path>` (<brief description of change>)

## Related
- [[<phase-slug>|<Phase Title>]] -- parent phase

## Soft Observations / Phase N+1 Candidates  <!-- OPTIONAL -->
- <observation> | <suggested phase-N+1 framing> | <evidence link: status article or journal section>
```

Omit empty sections (except "What Happened" and "Artifacts Changed" are always required). The `## Soft Observations / Phase N+1 Candidates` section is **OPTIONAL** — populate when the session produced a validation-status article OR surfaced uncovered patterns. Existing journals without this section remain valid (it is purely additive). See [[wiki:refinement-phase-pattern]] for how downstream phases use this section as their candidate source.

### Mechanical Journal (from /dev-context breadcrumb processing)

Body (20-40 lines, factual only): `## What Happened` (one bullet per commit), `## Artifacts Changed` (files list), `## Related` (phase link). Omit Decisions, Problems, Open Questions — those require conversation analysis.

### Quick Journal (from /dev-debrief quick mode)

Body (exactly 3 lines): `# <summary>` then 3 bullets: what was done, key outcome, next step.

### Common Frontmatter (all journal types)

```yaml
---
title: "<Session or summary title>"
aliases: []
category: journal
tags: [<infer from work done>]
parents: [<active-phase-slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: debrief | debrief-quick | hook | adjust
---
```

---

---

## Section L: active-knowledge.md Specification

Phase-scoped knowledge activation file. Distills retrieved wiki/decision knowledge into persistent Layer 2 context that survives compaction.

**Location:** `.claude/rules/active-knowledge.md`
**Ownership:** Dev-wiki skill suite exclusively. No other skill suite writes to this file.
**Lifecycle:** Created by `/dev plan` → loaded by `/dev context` → validated by `/dev debrief` → deleted on phase change.

### Template

```markdown
# Active Knowledge
<!-- Phase-scoped. Auto-generated by /dev plan. Cleared on phase change. -->
<!-- DO NOT EDIT MANUALLY — regenerate with /dev plan -->

## Phase: N - <Name>

### <Source display name>
from: [[wiki:<slug>]] | [[decision:<slug>]]
retrieved: YYYY-MM-DD

- <distilled proposition>
- <distilled proposition>
```

### Format Rules

1. **Header:** `# Active Knowledge` followed by two HTML comment lines (lifecycle + edit warning).
2. **Phase line:** `## Phase: N - <Name>` — MUST match the active phase in `_CURRENT_STATE.md`. Mismatch is an ERROR (see Staleness Protocol).
3. **Source sections:** One `###` heading per source, followed by:
   - `from:` — wiki-link to source (`[[wiki:slug]]` for knowledge wiki, `[[decision:slug]]` for dev-wiki decisions)
   - `retrieved:` — ISO date (YYYY-MM-DD) when content was distilled from source
   - 2-5 bullet propositions — distilled facts, not full article content
4. **Maximum 6 source sections.** If more sources are relevant, merge related sources or drop lowest-relevance.

### Size Budget

| Target | Hard Cap | Token Cost |
|--------|----------|------------|
| 30 lines | 40 lines | ~150 tokens |

The 30-line target is the upper bound of the 20-30 line range. For phases with fewer sources, aim for 20 lines.

### Evaluation Criteria

Before promoting a retrieved fact, apply all three filters. A fact MUST pass at least 2 of 3 to be activated (from [[wiki:knowledge-activation-patterns]] Stage 2 — Evaluate):

| # | Filter | Question | Pass example | Fail example |
|---|--------|----------|-------------|-------------|
| 1 | Multi-turn | Needed across multiple turns? | API convention used in 5+ calls | Version number checked once |
| 2 | Non-obvious | Would parametric knowledge get this wrong? | Project-specific naming rule | Standard library usage |
| 3 | Phase-dependent | Does this phase depend on this exact fact? | Schema constraint for migration | General architecture principle |

Facts failing all 3 filters are noise. Facts passing only 1 are borderline — only activate if budget permits.

### Overflow Handling

Overflow handling:

1. **>30 lines (target exceeded):** Re-distill all sections. Reduce to 1-2 propositions per source. Merge related sources under a single heading. If still >30, drop the source section with fewest passing evaluation filters.
2. **>40 lines (hard cap):** **HARD FAIL** — do not write the file. Report: `"Active knowledge exceeds 40-line cap (N lines). Reduce sources or distill further."`

### Staleness Protocol

Detects context drift ([[wiki:failure-mode-taxonomy]]) — stale activated knowledge causes the agent to act on outdated facts:

| Condition | Severity | Action |
|-----------|----------|--------|
| Source `updated:` date > entry `retrieved:` date | AUTO-REFRESH | Re-read source, re-distill 2-5 propositions, update `retrieved:` date. Report: `"Auto-refreshed [[slug]]."` |
| Phase in file ≠ active phase in `_CURRENT_STATE.md` | ERROR | `"Active knowledge references Phase X but active phase is Y. Delete file or re-plan."` |
| File not validated in >7 days | WARNING | `"Active knowledge not validated in 7+ days."` |

**Checked by:** `/dev context` (load + phase match only — does NOT check entry-level staleness), `/dev debrief` (freshness validation of all entries), `/dev check` (S10, C9, C10, C11).

**Known limitation:** The staleness protocol compares `updated:` dates, not content hashes. Cosmetic edits to source articles (typo fixes, tag changes, adding related links) will trigger staleness. With auto-refresh (added Phase 11), the consequence is elevated: cosmetic edits now cause re-distillation, and model non-determinism means the refreshed propositions may differ slightly from the originals even when the source facts haven't changed. **Guidance:** If the source diff is < 5 lines and touches only formatting/tags/links (not substantive content), treat as cosmetic and skip the refresh. The worst case of skipping is slightly stale wording, not incorrect behavior.

### Lifecycle Events

| Event | Action | Skill |
|-------|--------|-------|
| Phase planned | Create or overwrite file | `/dev plan` (Step 8f-bis) |
| Session start | Load + validate phase match (no entry-level staleness check) | `/dev context` (Steps 3, 6a) |
| Session end (same phase) | Auto-refresh stale entries (re-retrieve + re-distill) | `/dev debrief` |
| Phase change detected | Carry forward cross-cutting facts to working-knowledge, then delete | `/dev debrief` |
| Consistency audit | Checks S10, C9, C10, C11 | `/dev check` |

---

## Section M: working-knowledge.md Specification

Usage-tracked knowledge activation file. Distills ad-hoc query answers into persistent Layer 2 facts with usage counters for metric-driven eviction.

**Location:** `.claude/rules/working-knowledge.md`
**Ownership:** Shared. Primary writer: `/wiki-query` (activation on query). Secondary writers: `/dev-debrief` (session-end decay in Step 12a, phase-boundary carry-forward in Step 12b), `/dev-plan` (cross-phase seeding). Dev-context reads only.
**Lifecycle:** Entries added by `/wiki-query` on user confirmation, `/dev-debrief` on phase change (carry-forward), or `/dev-plan` on user confirmation (seeding) → usage incremented on reference → decayed on age → evicted at cap.

### Template

```markdown
# Working Knowledge
<!-- Usage-tracked. Sorted by use count descending. Max 100 entries. -->
<!-- Written by /wiki-query, /dev-debrief (carry-forward), /dev-plan (seeding). Dev-context reads only. -->

- [uses: N] <distilled proposition>
  source: [[wiki:<slug>]] | activated: YYYY-MM-DD | last_decay: YYYY-MM-DD
```

### Entry Format

Each entry is exactly 2 lines:
1. `- [uses: N] <proposition>` — the fact with its usage counter
2. `  source: [[wiki:<slug>]] | activated: YYYY-MM-DD | last_decay: YYYY-MM-DD` — indented metadata

The `last_decay:` field tracks when decay was last applied to this entry. Set to the `activated:` date on creation. Updated to today's date each time decay runs.

Entries are sorted by usage count descending. Ties broken by most recent `activated:` date.

### Size Budget

| Budget | Hard Cap | Token Cost |
|--------|----------|------------|
| 100 entries | 210 lines | ~800 tokens |

Primary enforcement: entry count (evict at >100). Line cap is a safety net for unusually long entries.

### Evaluation Criteria for Activation Offers

After `/wiki-query` generates a substantive answer, offer activation if ALL of:
1. **Substantive:** answer is >3 sentences long
2. **Multi-source:** answer draws from 2+ wiki articles
3. **Multi-turn relevance:** the facts would be useful beyond this single question

If any criterion fails, do not offer activation. This prevents noise from simple lookups.

On user confirmation, evaluate each key fact from the answer:
- **Multi-turn:** will this fact be needed again? (Pass/Fail)
- **Non-obvious:** would parametric knowledge get this wrong? (Pass/Fail)

Only facts passing at least 1 of 2 filters are activated. Distill to 3-5 propositions maximum per activation event.

### Dual Pruning Strategy

Two independent pruning mechanisms keep the file bounded (from [[wiki:persistent-state-hygiene]]):

**1. LRU Eviction (entry cap):**
When adding new entries would exceed 100 entries, evict the lowest-count entries until the file is at 100. Ties broken by oldest `activated:` date (evict oldest first).

**2. 7-Day Usage-Count Half-Life Decay:**
On each `/wiki-query` invocation that reads working-knowledge.md, and on each `/dev-debrief` session-end (Step 12a):
- For each entry where today's date - `last_decay:` date >= 7 days:
  - `uses = floor(uses / 2)`, minimum 1
  - Update `last_decay:` to today's date
- After decay, re-sort by usage count descending
- Entries that decay to `uses: 1` for 3 consecutive decay cycles (21+ days with no references) are eligible for eviction even if under the 100-entry cap

The `last_decay:` field ensures decay runs at most once per 7-day window per entry.

### Deduplication Rule

Before inserting a new entry, check if an entry with the same `source:` slug already exists. If so, increment the existing entry's `uses` count rather than creating a duplicate. This prevents carry-forward and seeding from producing redundant entries when the same wiki article is referenced across multiple phases.

### Eviction Shield

Entries with `activated:` date less than 7 days ago are exempt from LRU eviction, even if their `uses` count is the lowest. This prevents immediate pruning of freshly carried-forward entries before they have a chance to accumulate usage. The shield expires automatically — after 7 days, entries compete on usage count like all others.

### Usage Count Increment

When `/wiki-query` generates an answer and working-knowledge.md exists:
1. Scan entries for facts referenced in the answer (semantic match, not exact string)
2. Increment `[uses: N]` → `[uses: N+1]` for each matched entry
3. Re-sort by usage count descending after incrementing
4. Apply decay (see above) as part of the same operation

### Lifecycle Events

| Event | Action | Skill |
|-------|--------|-------|
| Query answer + user confirms | Add new entries, prune if >100 | `/wiki-query` |
| Query answer (existing entries match) | Increment usage counts, decay, re-sort | `/wiki-query` |
| Session start | Load + count entries + flag stale | `/dev context` (Step 7) |
| Session end (debrief) | 7-day half-life decay + eviction of 21d-stale entries | `/dev debrief` (Step 12a) |
| Phase change | NOT cleared (working knowledge is phase-independent) | -- |

### Cross-Package Read-Only Rule

`/dev context` reads working-knowledge.md to report entry count and stale entries in the context block. It NEVER writes to the file. `/wiki-query` writes (activation, usage-count increment, decay) and `/dev-debrief` writes (decay in Step 12a, carry-forward in Step 12b). This ownership boundary prevents write conflicts — dev-context remains read-only; only wiki-query and dev-debrief have write access.

### Partitioning Convention

Not all project knowledge belongs in working-knowledge.md. Use this 3-tier taxonomy to decide where knowledge lives:

**Tier 1: Meta-process patterns** → working-knowledge.md
Cross-project reusable knowledge about HOW to do work. Examples: awk state-flag extraction rule, refinement-phase-pattern conventions, DISCOVERY subtype taxonomy, bidirectional-update-contract discipline. These patterns apply regardless of which project you're working on. Decay: standard 7-day half-life.

**Tier 2: Project-specific structure** → `_ARCHITECTURE.md` + code articles (`articles/files/`, `articles/modules/`)
Knowledge about THIS project's structure: module responsibilities, dependencies, data flow, toolchain, file-level exports/imports. Scanned and updated by `/dev-scan`, refreshed by `/dev-debrief`. **Working-knowledge MUST NOT duplicate** what these surfaces already capture. If you can derive the fact by reading `_ARCHITECTURE.md` or a code article, it belongs there, not in working-knowledge.

**Tier 3: Cross-phase non-obvious project facts** → working-knowledge.md (with faster decay)
Project-specific facts that: (a) span multiple modules or surfaces; (b) are NOT derivable from reading a single file or article; (c) would be lost on context compaction. Example: "Module X depends on Module Y via shared env var $FOO — not visible in the import graph." These are the ONLY project-specific facts that belong in working-knowledge. Decay: 3-day half-life (project facts change faster than meta-process patterns).

**Decision heuristic:**
1. Can I find this by reading one file? → Don't store in working-knowledge.
2. Does `_ARCHITECTURE.md` already capture it? → Don't duplicate.
3. Is it project-specific AND single-file-derivable? → It belongs in a code article.
4. Is it cross-project reusable? → Tier 1 (standard 7-day decay).
5. Is it project-specific, multi-module, non-obvious? → Tier 3 (3-day decay).

### Partitioning Examples

**SHOULD store in working-knowledge:**
- "awk section extraction MUST use state-flag, NOT range syntax" → **Tier 1** (meta-process, cross-project reusable — applies to any markdown project using awk)
- "Module auth depends on Module config via shared JWT_SECRET env var — not visible in import graph" → **Tier 3** (cross-phase non-obvious project fact; spans modules; invisible to static analysis)
- "Bidirectional-update-contract NOT invoked when surfaces have different pivot axes — complementary-pivots framing" → **Tier 1** (meta-process pattern about when a design pattern does NOT apply)

**SHOULD NOT store in working-knowledge:**
- "Function validateToken is in auth/validators.ts" → code article captures this; single-file-derivable
- "Project uses pytest for testing with 45 tests" → `_ARCHITECTURE.md` `## Development Toolchain` captures this
- "Phase 21c had 3 tasks and completed in 50 minutes" → ephemeral phase detail; tasks.md + journal capture it; not useful cross-phase

### Per-Tier Decay Calibration

| Tier | Content Type | Decay Half-Life | Rationale |
|------|-------------|-----------------|-----------|
| 1 | Meta-process patterns | 7 days (standard) | Patterns are stable across projects; slow decay preserves proven wisdom |
| 2 | Project-specific structure | N/A (not in working-knowledge) | Lives in `_ARCHITECTURE.md` + code articles; scanned/updated by `/dev-scan` |
| 3 | Cross-phase non-obvious facts | 3 days (accelerated) | Project structure changes faster than patterns; aggressive decay prevents stale structural claims from persisting |

**Implementation note:** The existing 7-day decay in Section M `### Dual Pruning Strategy` remains the DEFAULT. Tier-specific decay is an OPTIONAL refinement: when `/wiki-query` or `/dev-debrief` writes an entry, it MAY tag the entry as Tier 3 by adding `tier: 3` after the `last_decay:` field. Entries without a `tier:` tag default to Tier 1 (7-day) behavior. This is a **convention-only** change in Phase 22; `/wiki-query` implementation to honor the tag is deferred to Phase 23.

---

## Section N: Module Scan Article Template (Legacy)

> **DEPRECATED:** Use Sections O (file articles) and P (module articles) for new code intelligence articles. Section N is retained only for reading legacy `status/` articles. Do not use Section N templates for new work.

**Deprecation:** Section N is the legacy format for one-time status snapshots. For the code intelligence layer, use **Section P** (module articles) and **Section O** (file articles). Section N articles in `articles/status/` are read-only historical artifacts.

Used by `/dev-scan` (legacy mode) for per-module articles written to `.dev-wiki/articles/status/`.

### Frontmatter

```yaml
---
title: "Module: <Name>"
aliases: []
category: status
tags: [codebase-scan]
parents: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: scan
---
```

### Body (max 80 lines)

```markdown
## Purpose
<1-2 sentences: what this module does, inferred from code>

## Key Files
- `<file>` — <purpose>

## Public API
- `<function/class>` — <signature and brief description>

## Connected Files
Imports FROM (what this module depends on):
- `<module>`: <symbols>

Imported BY (what depends on this module):
- `<file>`: <symbols>

## Issues
- [<SEVERITY>] <description> — `<file:line>`
(Omit section entirely if no issues affect this module)

## Patterns Detected
- <pattern>: <evidence file>

## Design Decisions
- <decision inferred from code structure>
```

---

## Section O: File Article Template

Used by `/dev-scan` for per-file articles written to `.dev-wiki/articles/files/`. Replaces Section N for living code intelligence (Section N remains for legacy status snapshots).

**Retrieval note:** Code articles are NOT loaded wholesale at session start. `/dev-context` loads only module articles matching the active phase `scope` globs plus articles just refreshed from the stale queue. Individual file articles are loaded on demand when an agent follows a wiki-link or needs to understand a specific file.

### Frontmatter

```yaml
---
title: "<project-relative-path>"
aliases: []
category: files
tags: [<language>, <framework-if-detected>]
parents: [<module-path-slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: scan
type: file
path: "<project-relative-path>"
content_hash: "<sha256-hex-first-16-chars>"
exports: [<bare-symbol-names>]
imports: ["<project-relative-path>", ...]
imported_by: ["<project-relative-path>", ...]
data_reads: []   # OPTIONAL: config files, data files, APIs, env vars this file reads (data deps, not code imports)
data_writes: []  # OPTIONAL: output files, DB tables, artifacts this file produces
# generated: true    (add only for build output; skips staleness checks per Section Q)
---
```

Note: `title` intentionally uses the raw path (deviates from other templates) because it is the most meaningful identifier for code files. The `parents` field links to the containing module article.

### Body (target 30-60 lines, hard cap 80)

```markdown
# <project-relative-path>

<1-2 sentence purpose description inferred from code>

## Exports

- `<symbol>(params)` -- <brief description>

## Dependencies

- [[<path-slug>|<filename>]] -- `<imported-symbol>` <usage>
- `<package>` (external) -- <usage>

## Dependents

- [[<path-slug>|<filename>]] -- uses `<exported-symbol>`

## Key Logic

- <Important algorithm, business logic, or error handling worth noting>
```

### Field Definitions

| Field | Source | Notes |
|-------|--------|-------|
| `path` | Filesystem | Project-relative to `$ROOT`, forward slashes |
| `parents` | Parent directory | Path-slug of the containing module article |
| `content_hash` | SHA-256 | First 16 hex chars of file content hash (see Section Q) |
| `exports` | Static analysis | Bare symbol names only (e.g., `[validateToken, refreshToken]`). Signatures go in body. |
| `imports` | Static analysis | **Project-relative paths** of imported local files (resolved from source import statements). External packages listed in body only. |
| `imported_by` | Reverse lookup | **Project-relative paths** of files that import this file. Populated incrementally by scan. |
| `data_reads` | Manual/scan | OPTIONAL. Data dependencies this file reads: config files, data files, APIs, env vars. Not code imports (those go in `imports`). Leave empty `[]` for pure-logic files. |
| `data_writes` | Manual/scan | OPTIONAL. Data artifacts this file produces: output files, DB writes, API calls, generated artifacts. Leave empty `[]` for files with no data output. |

### Constraints

- Omit `## Key Logic` if the file is purely declarative (types, config, constants).
- Files under 5 lines that consist solely of re-exports (barrel files) MAY be omitted. Document their exports in the parent module article instead.
- If a dependency target has no file article (excluded by Section Q rules), render as plain `` `<path>` `` not a wiki-link.
- Do NOT include function/method bodies in Key Logic — summarize the algorithm in 1-2 sentences.
- Do NOT create file articles for files matching Section Q exclusion patterns.
- Do NOT populate `imported_by` by scanning the entire codebase per file — this is populated incrementally across all files during a scan pass.

---

## Section P: Module Article Template

Used by `/dev-scan` for per-directory articles written to `.dev-wiki/articles/modules/`. Replaces Section N for living code intelligence.

### Frontmatter

```yaml
---
title: "<module-path>/"
aliases: []
category: modules
tags: [<auto-detected>]
parents: [<parent-module-path-slug>]
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: scan
type: module
path: "<project-relative-directory-path>/"
files: [<path-slugs-of-contained-file-articles>]
external_deps: [<package-names>]
internal_deps: [<module-path-slugs-this-depends-on>]
dependents: [<module-path-slugs-that-depend-on-this>]
content_hash: "<composite-hash>"
---
```

### Body (target 20-40 lines, hard cap 60)

```markdown
# <module-path>/

<1-2 sentence module purpose>

## Files

- [[<path-slug>|<filename>]] -- <one-line purpose>

## Key Patterns

- <Architectural or naming pattern in this module>

## Dependencies

Internal:
- [[<path-slug>|<module-name>]] -- <what's used>

External:
- `<package>` -- <role>

## Dependents

- [[<path-slug>|<module-name>]] -- <what it uses from this module>
```

### Field Definitions

| Field | Source | Notes |
|-------|--------|-------|
| `path` | Filesystem | Project-relative directory path with trailing `/` |
| `parents` | Parent directory | Path-slug of parent module, or empty `[]` for top-level modules |
| `files` | Scan | Path-slugs of contained file articles (Section A convention) |
| `content_hash` | Composite (Section Q) | SHA-256 of sorted child file hashes, first 16 hex chars |
| `external_deps` | Static analysis | Package names imported by any file in this module |
| `internal_deps` | Static analysis | Path-slugs of other modules this module depends on |
| `dependents` | Reverse lookup | Path-slugs of modules that depend on this module |

### Hierarchy Rules

- **Top-level modules** set `parents: []`. There is no project-root module article.
- **Nested modules** (`src/auth/strategies/`) set `parents: [src-auth]`.
- **Module depth cap: 3 levels.** Directories deeper than 3 levels do NOT get module articles. Source files within those directories get file articles with `parents` set to the deepest ancestor module (depth <= 3). Those file articles appear in the ancestor module's `files` list.
- Do NOT create module articles for directories deeper than 3 levels.

### Key Patterns Guidance

Examples of what to include: "All files export a single default class", "Uses barrel exports via index.ts", "Repository pattern: data access behind interfaces", "Test files colocated with source (*.test.ts)". Omit section if no distinctive patterns detected.

---

## Section Q: Content Hashing Specification

Staleness detection for code articles. Each article stores a hash of its source; drift = hash mismatch. `$ROOT` is the directory containing `.dev-wiki/`. All project-relative paths are relative to `$ROOT`.

### File Hash Algorithm

1. Read file content as raw bytes (encoding-agnostic; assumes consistent line endings across checkouts)
2. Compute SHA-256 hash
3. Take first 16 hex characters (64 bits — negligible collision risk for codebases under 10M files)
4. Store in frontmatter `content_hash` field

```bash
# macOS
shasum -a 256 path/to/file | cut -c1-16
# Linux
sha256sum path/to/file | cut -c1-16
```

### Module Composite Hash

1. Collect `content_hash` values from all file articles in the module
2. Sort alphabetically by `path` field
3. Join with `\n` separator (no trailing newline)
4. SHA-256 the joined string, take first 16 hex characters

A module is stale if ANY child file hash changed (composite will differ). If a file article is missing for a known source file, treat as stale (hash mismatch).

### Staleness Check

```
is_stale = (sha256(read_file(path))[:16] != article.content_hash)
```

Performed by `/dev-context` (session-start incremental) and `/dev-scan --refresh` (full).

### Edge Cases

| Case | Rule |
|------|------|
| Binary files (images, compiled) | Skip -- do not create articles |
| Empty files | Hash of empty string (`e3b0c44298fc1c14`) |
| Generated files (build output) | Mark `generated: true` in frontmatter; skip during staleness checks |
| Symlinks | Follow target, hash target content; note `symlink: true`. Skip if target is outside `$ROOT` or creates a cycle. |
| Files outside project root | Skip -- only hash files within `$ROOT` |
| Non-UTF-8 source files | Hash is computed on raw bytes (encoding-agnostic); article content analysis assumes UTF-8 |
| File deleted since last scan | Remove article; update parent module article |
| New file since last scan | Create article; update parent module article |

### Exclusion Patterns (files that NEVER get articles)

```
node_modules/**  .git/**  dist/**  build/**  __pycache__/**
.venv/**  venv/**  .tox/**  *.egg-info/**  .mypy_cache/**  .pytest_cache/**
*.png  *.jpg  *.gif  *.ico  *.woff  *.ttf  *.pdf
*.pyc  *.o  *.so  *.dylib  *.class  *.jar
```

Configurable via `.dev-wiki/scan-config.md` (future, not in R1 scope).

---

## Section R: Stale Queue Specification

Lightweight change-tracking mechanism. PostToolUse hooks mark changed files; `/dev-context` processes the queue at session start.

### File Format

**Location:** `.dev-wiki/.stale-queue`
**Format:** One project-relative file path per line. No blank lines. Best-effort dedup on write; read-side dedup before processing.

```
src/auth/middleware.ts
src/config/db.ts
lib/utils/helpers.ts
```

**Hard cap:** 200 entries. If the queue exceeds 200, new entries are dropped with a warning in the hook output. **Soft warning** at 100 entries: `/dev-context` emits "Stale queue has N entries. Consider `/dev-scan --refresh`."

### Write Protocol (PostToolUse hook on Edit/Write)

1. Extract target file path from tool result
2. Convert to project-relative path
3. **Skip** if path matches exclusion patterns: Section Q exclusions + `.dev-wiki/**` + all `*.md` files
4. **Skip** if path already present in `.stale-queue` (best-effort dedup via grep; duplicates are harmless)
5. **Skip** if queue has >= 200 entries (hard cap)
6. Append path to `.stale-queue`

Hook fires only on `Edit` and `Write` tool calls. Does NOT fire on `Read`, `Glob`, `Grep`, or `Bash`.

**Known gap — renames:** File renames via `Bash` (e.g., `mv`, `git mv`) do NOT trigger the hook. Old file articles persist with stale paths. Run `/dev-scan --refresh` after renaming files outside agent sessions. New files created outside agent sessions (e.g., `git pull`) are similarly not captured.

### Read Protocol (dev-context at session start)

1. If `.stale-queue` does not exist or is empty: skip
2. Read all paths, **deduplicate**, validate each line matches `[a-zA-Z0-9_./-]+` (discard invalid lines with warning)
3. Process first **10 entries** (FIFO order — oldest changes first; cap prevents slow startup)
4. For each path:
   - If file exists: recompute hash, compare to article. If stale: update `content_hash` in frontmatter. Only regenerate full article content if exports/imports changed (detected by diff).
   - If file deleted: remove file article, update parent module article
   - If processing fails (hash error, analysis failure): keep entry in queue for next session
5. For each affected module: recompute composite hash, update module article if changed
6. Remove only **successfully processed** entries from `.stale-queue`
7. If entries remain (>10 cap or failed), keep for next session

**In-session staleness:** Queue entries written during a session are NOT processed until the next session's `/dev-context`. Within a session, articles for recently-edited files may be stale. Run `/dev-scan --refresh` mid-session if immediate consistency is needed.

### Lifecycle

```
Edit/Write tool call
  → PostToolUse hook appends to .stale-queue (if source file, within caps)
  → [session continues, more edits may add more entries]
  
Next session start (/dev-context)
  → Reads .stale-queue, dedup, validate
  → Processes first 10 entries (FIFO)
  → Hash-only update for unchanged structure; full regeneration for changed exports/imports
  → Clears processed entries; keeps remaining
```

### Full Refresh (bypasses queue)

`/dev-scan --refresh` ignores `.stale-queue` and hashes ALL source files against ALL articles. Used when:
- Queue exceeds soft warning (100+ entries)
- File renames or deletions happened outside agent sessions
- Major refactoring (many files changed via `git pull`, manual editing, CI)
- First time setup (no articles exist yet)

After full refresh, `.stale-queue` is deleted.

---

## Section S: Skill Metadata Specification

Structured metadata in SKILL.md frontmatter. Enables mechanical verification (dev-check S12-S15) and future behavioral regression detection.

### Format

Add to SKILL.md YAML frontmatter:

```yaml
---
description: "Use when..."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/tasks.md]
writes: [$WIKI/_CURRENT_STATE.md(Active Phase, Contract, Decisions)]
dispatches: [plan-reviewer, approach-reviewer]
tier: complex-orchestration
---
```

### Field Definitions

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| reads | Yes | Array of `$WIKI/` or `$ROOT/` paths | Files the skill reads (not conditional companions) |
| writes | Yes | Array of paths, optionally with `(Section)` suffix | Files the skill creates or modifies. Append section names for living documents. |
| dispatches | Yes | Array of companion slugs, or `[]` | Subagent companion prompts dispatched via Agent tool |
| tier | Yes | `single-shot`, `simple-orchestration`, `complex-orchestration` | Size tier per [[wiki:skill-file-authoring]]: 60-100, 100-160, 160-250 lines |

### Conventions

- **$WIKI** = `.dev-wiki/` (project-relative). **$ROOT** = project root.
- `reads` includes only files the skill always reads. Conditionally-read files (companions loaded only for specific branches) are NOT listed.
- `writes` must match the skill's Section Ownership block. Discrepancy is a dev-check S14 failure.
- `dispatches: []` for single-agent skills (no subagents).
- **When to update:** After any skill modification that changes file I/O, subagent dispatch, or size tier. Dev-check S12-S15 catches drift.

---

## Section T: Retro Article Template

Process retrospective article produced by `/dev-retro`. Analyzes journal entries and decisions to identify recurring patterns and workflow friction.

### Frontmatter

```yaml
---
title: "Retrospective: Phases N-M"
aliases: []
category: journal
tags: [retrospective]
parents: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
source: retro
phases_reviewed: [N, N+1, ..., M]
---
```

### 7 Analysis Dimensions (required sections)

```markdown
## 1. Recurring Blockers
<Blockers that appear in 2+ phases. Include phase numbers and resolution status.>

## 2. Decision Reversals
<Decisions made and later overridden or significantly revised. Why did the original not hold?>

## 3. User Corrections
<Cases where the user corrected the agent's approach. What preference or principle does this reveal?>

## 4. Skill Size Trends
<Table of skill name, current lines, tier, delta since last retro. Flag approaching/exceeding caps.>

## 5. Review Score Trends
<Average review scores across phases. Improving, declining, or stable? What dimensions score lowest?>

## 6. Phase Velocity
<Phases completed per session, tasks per phase, time-to-complete trends. Accelerating or decelerating?>

## 7. Pattern Cascades
<Failure mode chains (per [[wiki:failure-mode-taxonomy]]): did drift lead to scope creep lead to issues?>

## Recommendations
<3-5 actionable suggestions for workflow improvement, grounded in the patterns above.>
```

---

## Directory Structure (created by /dev-init)

```
.dev-wiki/
  schema.md
  _CURRENT_STATE.md
  _ARCHITECTURE.md
  tasks.md
  index.md
  log.md
  articles/
    phases/
      phase-01-<slug>.md
      ...
    decisions/        (populated by /dev-debrief, /dev-plan)
    journal/          (populated by /dev-debrief, /dev-context)
    status/           (populated by /dev-scan, legacy snapshots)
    modules/          (populated by /dev-scan, per-directory code articles)
    files/            (populated by /dev-scan, per-file code articles)
```

---

## Section U: Project CLAUDE.md Lifecycle

Defines how the project-level `./CLAUDE.md` is maintained through the dev-wiki lifecycle. The project CLAUDE.md is scaffolded once by `/dev-init` and then must be kept in sync as rules, scope, and conventions evolve across phases.

### Ownership

**Primary owner:** `/dev-debrief` — performs a periodic refresh check at full-debrief Step 8.5. Reads the current project CLAUDE.md and compares machine-generated sections against actual state. If drift detected, refreshes those sections only.

**Scaffolder:** `/dev-init` — creates the initial file from `scaffold-claude-md.md` template. Never touches it again after creation.

**All other skills:** Read-only. No skill other than `/dev-debrief` may write to project CLAUDE.md.

### Triggers for Refresh

A `/dev-debrief` refresh check fires when ANY of:
1. `.claude/rules/` has modules added or removed since last refresh (compare file list against `## Project Rule Modules` section)
2. Project scope or identity changed (new primary language, renamed project, shifted purpose)
3. `## Project Pointers` section references stale paths (wiki directory moved, skill directory renamed)
4. User explicitly requests: "refresh CLAUDE.md"

If no trigger fires, skip the refresh (most debriefs will skip).

### Update Scope — Human vs Machine Sections

Project CLAUDE.md has two kinds of content. Refresh MUST NOT touch human-authored sections.

```markdown
<!-- human-authored: do not auto-refresh -->
## Identity                    <!-- written once by user/dev-init; never auto-updated -->
## Precedence                  <!-- written once; never auto-updated -->

<!-- machine-refreshable: dev-debrief may update -->
## Project Rule Modules        <!-- derived from ls .claude/rules/*.md -->
## Dynamic State               <!-- derived from ls .claude/rules/active-*.md + working-knowledge.md -->
## Project Pointers            <!-- derived from directory existence checks -->
## Project Scope               <!-- partially machine: primary language, wiki name; partially human: purpose prose -->
```

### Size Guard

Per [[wiki:harness-composition-playbook]] invariant #2, project CLAUDE.md MUST stay ≤80 lines after any refresh. If a refresh would push past 80 lines, `/dev-debrief` MUST warn: "CLAUDE.md refresh would exceed 80-line cap. Skipping auto-refresh; consider manual edit to trim." and skip the refresh.

### Lifecycle Stages

```
/dev-init (scaffold) → user edits Identity/Precedence → phases run → /dev-debrief (periodic refresh of machine sections) → compaction (Layer 2 survival) → next session (/dev-context loads)
```

The project CLAUDE.md survives context compaction as Layer 2 (project rules). It is re-read at every session start. This makes it the most persistent project-level artifact after `.dev-wiki/` itself.

## Section V: Developer Journey Conventions

Read `~/.claude/skills/dev-wiki/journey-conventions.md` for the full specification: journey article schema (5-field step format), naming conventions, evaluation criteria (COVERED/PARTIAL/MISSING), scoring model, defined journeys (Cold Start, Daily Session, Quality Gate, Problem Handling, Knowledge Flow), and integration roadmap.

### Journey Integration Conventions (Phase 26)

<!-- SSOT direction per [[wiki:bidirectional-update-contract]] cousin reasoning: This subsection is the SOURCE OF TRUTH for J-check + Dimension 8 conventions. SKILL.md convention-pointer comments in dev-check/dev-retro/dev-adjust are derived views — when updating conventions, edit THIS subsection first, then refresh the pointers. -->

**J-check convention (consumed by /dev-check Journey Handoff Checks):** Each journey step with `hands_off_to: PRESENT` is a check assertion. /dev-check J1 validates the claim via two-tier [[wiki:two-tier-drift-classification]]: HARD match requires `Run .*${next_tool}` sentence-form in the source tool's SKILL.md (the canonical handoff form); WARN match accepts a bare mention (implicit handoff). FAIL when neither pattern matches. Parse journey articles with a state-flag parser per [[wiki:awk-section-extraction-state-flag]] — NEVER awk range syntax (EOF-boundary regression).

**Dimension 8 convention (consumed by /dev-retro Operational Effectiveness):** Cross-reference journey step `tool:` names against last 10 journal entries. Classify each step as Correction-prone (overlaps Dim 3), Blocking-prone (overlaps Dim 1), or Skipped (zero journal mentions = aspirational step, highest-signal finding). Accept partial coverage for pre-Phase-25 journals where tool-step mapping didn't exist.

**Gap notation:** Two systems coexist. Phase 24 diagnostic uses **N-notation** (N1-N8, structural findings). Journey analysis uses **#-notation** (#1-#10, operational gaps). The 5×10 coverage matrix in `.dev-wiki/articles/status/2026-04-16-phase-26-gap-report.md` reconciles both with explicit "unmapped" cells where items have no 1:1 correspondence.
