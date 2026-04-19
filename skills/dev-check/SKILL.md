---
name: dev-check
description: "Validate dev wiki integrity and fix drift. Run when state feels stale, after long breaks, or when /dev-context warns about drift. Do NOT use for knowledge wiki health (use wiki-lint) or for session startup (use dev-context)."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/_ARCHITECTURE.md, $WIKI/tasks.md, $WIKI/articles/phases/*, $WIKI/index.md, $WIKI/log.md, $ROOT/.claude/rules/active-phase.md, $ROOT/.claude/rules/active-knowledge.md, $ROOT/.claude/rules/working-knowledge.md]
writes:
  # Tier 1 — auto-apply (deterministic rebuilds from source-of-truth, no user approval needed)
  - index.md
  - $ROOT/.claude/rules/active-phase.md
  - log.md
  - $ROOT/.claude/rules/active-knowledge.md
  - .session-end
  - .pending-commit
  - .session-buffer
  - .stale-queue
  # Tier 2 — user-gated (content or status changes that may have been intentionally set)
  - _CURRENT_STATE.md(Active Phase, Key Artifacts, Blockers)
  - _ARCHITECTURE.md(Directory Layout)
  - articles/phases/*(frontmatter status)
  - articles/**(broken wikilinks)
  - tasks.md(completed phase [x])
  - $ROOT/.claude/rules/working-knowledge.md(prune, reformat)
dispatches: []
tier: complex-orchestration
---

<!-- Convention: see dev-wiki-reference.md Section V (Journey Integration Conventions) for J-check two-tier classification and SSOT direction -->

# dev-check

Diagnose dev wiki structural integrity and state consistency, then offer to auto-fix issues. Two phases: DIAGNOSE (always runs, read-only) then REPAIR (user-gated).

This is a **single-agent skill** -- Claude does all work directly. No subagents.

---

## Section Ownership

This skill's REPAIR phase writes to shared files. Template adapted from `~/.claude/skills/dev-context/SKILL.md`'s 3-bucket pattern per [[wiki:harness-composition-playbook]] invariant #4 (subagent coherence) and the section-ownership-vs-metadata-writes discipline from [[wiki:skill-file-authoring]].

OWNS (Tier 1 auto-apply — deterministic rebuilds from source-of-truth, no user approval needed):
- `index.md` — full regenerate from `articles/` on disk (S7 phantoms/missing)
- `$ROOT/.claude/rules/active-phase.md` — sync from phase article (S2 mismatch)
- `log.md` — create-if-missing with bootstrap entry (S9)
- `$ROOT/.claude/rules/active-knowledge.md` — delete on phase mismatch (S10)
- `.session-end`, `.pending-commit`, `.session-buffer` — delete stale breadcrumbs (S8, >7 days)
- `.stale-queue` — remove invalid/deleted-file entries (CA5)

MAY UPDATE (Tier 2 user-gated — content or status changes that may have been intentionally set):
- `_CURRENT_STATE.md` sections (Active Phase, Key Artifacts, Blockers) — zombie-phase completion (C7), multi-error rebuild, key-artifact sync (C4)
- `_ARCHITECTURE.md` (Directory Layout) — add/remove directories (C3)
- `articles/phases/*` frontmatter — `status: completed` on zombie phase (C7), scaffold new phase article (S1)
- `articles/**` — remove/redirect broken wikilinks (S6)
- `tasks.md` — mark remaining tasks `[x]` in completed phases (C2)
- `$ROOT/.claude/rules/active-knowledge.md` — rebuild/flag-stale (C9/C10/C11)
- `$ROOT/.claude/rules/working-knowledge.md` — prune excess entries (W1), reformat malformed (W3), remove broken sources (W4)

All other sections of shared files: read-only. Phase 1 (DIAGNOSE) is strictly read-only regardless of findings — writes only occur in Phase 2 (REPAIR) after Tier 1 auto-apply or Tier 2 user approval.

---

## When to Use

- State feels stale or inconsistent after a long break
- `/dev context` emitted a drift warning
- After manual edits to `.dev-wiki/` files
- Before starting a new phase (sanity check)
- Periodically, as general wiki hygiene

---

## Pre-checks

1. **Discover dev wiki.** Locate project root:
   ```bash
   ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   ```
   Check `$ROOT/.dev-wiki/_CURRENT_STATE.md`. If missing: "No dev wiki found. Run `/dev init` to create one." STOP.

2. Set `WIKI=$ROOT/.dev-wiki`. All paths below are relative to `$WIKI`.

---

## Phase 1: DIAGNOSE (read-only)

Run ALL checks below. Use the Glob tool for file discovery and Read tool for file content -- never Bash `find`/`ls`/`cat`. If any individual check fails to execute (file read error, glob returns nothing unexpected), skip that check and note it as `SKIPPED: <reason>` in the report. Never abort the entire diagnosis because one check failed.

Collect findings into three severity buckets: ERROR, WARNING, INFO.

### Structural Integrity Checks

**S1: Active phase exists**
Read `_CURRENT_STATE.md`. Find the `## Active Phase` section. Extract the wikilink `[[phase-slug|...]]`. Use Glob to verify `articles/phases/<phase-slug>.md` exists on disk. If no active phase is referenced, this check passes (nothing to validate).
Severity: ERROR

**S2: active-phase.md sync**
Read `$ROOT/.claude/rules/active-phase.md`. Extract the `Phase:` field value. Read `_CURRENT_STATE.md` and extract the active phase from `## Active Phase`. Compare: the phase name/number in `active-phase.md` must match the active phase in `_CURRENT_STATE.md`. If `_CURRENT_STATE.md` has no active phase and `active-phase.md` says "(none)", they match.
Severity: ERROR

**S3: active-phase.md populated**
Read `$ROOT/.claude/rules/active-phase.md`. If an active phase exists in `_CURRENT_STATE.md` but `active-phase.md` contains placeholder text (`(none)` in the Phase, Objective, or Scope fields), flag it.
Severity: WARNING

**S4: Single active phase**
Use Glob to find all files in `articles/phases/`. Read each phase article's frontmatter. Count how many have `status: active`. Exactly 0 or 1 is valid. More than 1 is an error.
Severity: ERROR

**S5: Phase dependency chain**
Identify the active phase number (e.g., Phase 7). Read all phase articles with lower numbers. Each must have `status: completed` in frontmatter. Flag any with `status: active` or `status: not-started`.
Severity: WARNING

**S6: Wikilink resolution**
Read up to 30 `.md` files under `articles/` (prioritize most recently modified). Extract all `[[slug]]` and `[[slug|label]]` wikilinks (but NOT cross-wiki links `[[wiki-name:slug]]`). For each slug, verify a file named `<slug>.md` exists somewhere under `articles/`. Report unresolved links with their source file. For wikis with >30 articles: "Sampled 30 of N articles. Run /dev check --full for complete scan."
Severity: WARNING

**S7: Index completeness**
Read `index.md`. Extract all article paths listed. Use Glob to find all `.md` files under `articles/`. Compare: every file on disk should appear in index, and every entry in index should exist on disk. Report phantoms (in index but not on disk) and missing (on disk but not in index).
Severity: WARNING

**S8: Stale breadcrumbs**
Use Glob to check for `.session-end`, `.pending-commit`, `.session-buffer` in `$WIKI`. If any exist, check their modification time via `stat` (Bash). If older than 24 hours, flag. If older than 7 days, flag as stale enough for auto-deletion in repair phase.
Severity: INFO

**S9: Log exists and valid**
Read `log.md`. Verify it exists and has at least one entry line matching `[<timestamp>]`. If empty or missing, flag.
Severity: INFO

**S11: Architecture doc staleness vs skill files**
Parse the `> Last updated:` timestamp from `$WIKI/_ARCHITECTURE.md`. Use Bash `stat` to get the modification time of skill files that the architecture doc describes (Glob `~/.claude/skills/dev-*/SKILL.md`, `~/.claude/skills/dev-scan/*.md`, `~/.claude/skills/dev-wiki/dev-wiki-reference.md`). If ANY skill file has a modification time after the architecture doc's timestamp, flag with the list of newer files. This catches a known blind spot: skill files at `~/.claude/skills/` are outside the stale-queue pipeline and invisible to incremental refresh (silent-false-PASS family member — see [[wiki:silent-false-pass-pattern-family]]). See [[architecture-drift-root-cause]].
Severity: WARNING

Tier 2 fix: "Run `/dev-scan` to refresh `_ARCHITECTURE.md` with current skill file line counts and structure."

### State Consistency Checks

**C1: Task-phase alignment**
Read `tasks.md`. Extract phase section headers (e.g., `## Phase 1: ...`). For each phase referenced, verify the corresponding phase article exists in `articles/phases/` using Glob. Report any phase sections that reference nonexistent articles.
Severity: ERROR

**C2: Completed phase tasks**
For each phase article with `status: completed`, check the corresponding section in `tasks.md`. All tasks in that section should be marked `[x]`. Flag any `[ ]` or `[blocked:` tasks in completed phases.
Severity: WARNING

**C3: Architecture vs code**
Read `_ARCHITECTURE.md`. Extract directory names from the `## Directory Layout` section. Use Glob at the project root to discover actual top-level directories (excluding noise: `__pycache__`, `.venv`, `venv`, `node_modules`, `.git`, `.dev-wiki`, `.tox`, `dist`, `build`, `.mypy_cache`, `.pytest_cache`, `*.egg-info`, `.claude`). Compare documented vs actual. Report undocumented directories and phantom directories (documented but missing).
Severity: WARNING

**C4: Key artifacts exist**
Read `_CURRENT_STATE.md`. Extract file paths from the `## Key Artifacts` table. Use Glob or Read to verify each path exists on disk. Report missing artifacts.
Severity: WARNING

**C5: Dependency versions**
Read `_ARCHITECTURE.md` `## Dependencies` table. Read the project manifest (`pyproject.toml`, `package.json`, `Cargo.toml`, or `go.mod` -- use Glob to find it). Compare listed versions. Flag mismatches.
Severity: INFO

**C6: Empty journal**
Use Glob to check `articles/journal/` for `.md` files. If the directory is empty, check git log for commit count (if git available): `git rev-list --count HEAD 2>/dev/null`. If the project has 10+ commits but no journal entries, flag as an indicator that `/dev debrief` has never run.
Severity: INFO

**C7: Zombie active phase**
For each phase article with `status: active`, check its tasks in `tasks.md`. If ALL tasks are marked `[x]` (none pending or blocked), the phase is a zombie -- it should have been marked completed.
Severity: WARNING

**C8: Cross-wiki links**
Read all `.md` files under `articles/`. Extract `[[wiki-name:slug]]` cross-wiki links. For each, check if `$ROOT/wiki/` (or the path for the named wiki) exists and contains a matching article. Report unresolvable cross-wiki links.
Severity: INFO

### Scan Article Checks

These checks validate `articles/status/*-scan.md` against the actual codebase. If no scan articles exist, skip these checks (scan is optional).

**SC1: Scan article module existence**
For each `*-scan.md` file, read the `## Key Files` section. Use Glob to verify each listed file still exists on disk. Report missing files (module was refactored or deleted since scan).
Severity: WARNING

**SC2: Scan article staleness**
Compare the `updated:` date in each scan article's frontmatter against the modification time of the module's files (via Glob). If any source file is newer than the scan article by >7 days, flag the scan as stale.
Severity: INFO

Tier 2 fix for SC1/SC2: "Re-run `/dev-scan --update` to refresh stale module articles."

### Active Knowledge Checks
<!-- S10 grouped by category (Active Knowledge), not numerical sequence — see [[phase-21a-affirm-and-fix-dev-check-scope]] -->

These checks validate `.claude/rules/active-knowledge.md` against the specification in `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section L. If the file does not exist, all four checks pass (the file is optional).

**S10: Active knowledge phase match**
Read `$ROOT/.claude/rules/active-knowledge.md`. Extract the `## Phase: N - <Name>` line. Compare against the active phase in `_CURRENT_STATE.md`. If they do not match, flag.
Severity: ERROR

**C9: Active knowledge slug resolution**
Read `$ROOT/.claude/rules/active-knowledge.md`. Extract all `from: [[wiki:<slug>]]` and `from: [[decision:<slug>]]` entries. For wiki slugs, verify a matching `.md` file exists under `$ROOT/wiki/articles/`. For decision slugs, verify under `$WIKI/articles/decisions/`. Report unresolvable references.
Severity: WARNING

**C10: Active knowledge staleness**
For each entry in `active-knowledge.md`, read its `retrieved:` date. Read the source article (resolved from `from:` field) and extract its `updated:` frontmatter date. If source `updated:` > `retrieved:`, the entry may be stale. Report stale entries with both dates.
Severity: WARNING

**C11: Active knowledge size budget**
Count lines in `$ROOT/.claude/rules/active-knowledge.md`. If >30 and <=40: flag as target exceeded. If >40: flag as hard cap exceeded.
Severity: WARNING (>30 lines), ERROR (>40 lines)

### Working Knowledge Checks

These checks validate `.claude/rules/working-knowledge.md` against the specification in `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section M. If the file does not exist, all four checks pass (the file is optional).

**W1: Working knowledge entry count**
Read `$ROOT/.claude/rules/working-knowledge.md`. Count entries (lines matching `- [uses:` pattern). If >100 entries, flag.
Severity: WARNING

**W2: Working knowledge line count**
Count total lines in `$ROOT/.claude/rules/working-knowledge.md`. If >100 and <=210: flag as approaching cap. If >210: flag as exceeding hard cap.
Severity: WARNING (>100 lines), ERROR (>210 lines)

**W3: Working knowledge format validation**
For each entry, verify the 2-line format: line 1 matches `- [uses: N] <text>` and line 2 matches `  source: [[wiki:<slug>]] | activated: YYYY-MM-DD | last_decay: YYYY-MM-DD`. Flag entries that don't match (missing metadata line, unparseable `uses` value, missing `activated:` or `last_decay:` field).
Severity: WARNING

**W4: Working knowledge source resolution**
For each entry, extract the slug from `source: [[wiki:<slug>]]`. Verify a matching `.md` file exists under `$ROOT/wiki/articles/`. Report unresolvable source references.
Severity: WARNING

### Code Article Checks

These checks validate `articles/files/` and `articles/modules/` against the actual codebase. If NO code articles exist (both directories empty or absent), skip ALL checks in this section — code articles are optional and only populated by `/dev-scan`.

**CA1: File article coverage**
Glob source files at project root (excluding Section Q exclusion patterns: node_modules, .git, dist, build, __pycache__, .venv, venv, .tox, *.egg-info, .mypy_cache, .pytest_cache, binary extensions, *.md). Compare to file articles in `articles/files/`. Only flag if >50% of source files lack articles (indicates partial scan, not intentional gaps).
Severity: INFO

**CA2: Content hash freshness**
For each file article (cap at 20), read `content_hash` and `path` from frontmatter. Compute current hash: `shasum -a 256 <path> | cut -c1-16`. Compare. Flag mismatches (file changed since last scan).
Severity: WARNING

**CA3: Module-child completeness**
For each module article, read `files` list from frontmatter. Verify each path-slug has a corresponding file article in `articles/files/`. Report missing child articles.
Severity: INFO

**CA4: Cross-reference bidirectionality**
Sample up to 10 file articles. For each, read `imported_by` frontmatter. Verify that each referenced file article's `imports` list includes the current file's path. Report asymmetric references.
Severity: INFO

**CA5: Stale queue health**
If `.stale-queue` exists, read and validate entries match `[a-zA-Z0-9_./-]+`. Flag invalid entries. Report count and warn if >100 (soft cap per Section R). Flag entries referencing deleted files.
Severity: INFO

Tier 2 fix for CA2: "Run `/dev-scan` to refresh stale code articles." Tier 2 fix for CA5: "Remove invalid entries from `.stale-queue`."

### Skill Metadata Checks

These checks validate structured metadata in `~/.claude/skills/dev-*/SKILL.md` frontmatter against the specification in Section S of dev-wiki-reference.md. If a skill file has no `reads:` field in frontmatter (metadata not yet added), skip that skill with a note — do NOT report it as a failure.

**S12: Skill size vs tier**
For each skill with `tier:` in frontmatter, count total lines in the SKILL.md file. Compare against tier budget: `single-shot` 60-100, `simple-orchestration` 100-160, `complex-orchestration` 160-250. Flag if size exceeds tier cap. Note: some skills have justified exceptions (see [[accept-skill-size-exceptions]]) — flag but do not auto-fix.
Severity: WARNING

**S13: Hard gate consistency**
For each skill with `tier: complex-orchestration`, Grep for `<HARD-GATE>` tags. If the skill dispatches subagents (has `dispatches:` with non-empty array) or writes to living documents, it SHOULD have at least one hard gate. Flag skills that write to `_CURRENT_STATE.md` but have no hard gate.
Severity: INFO

**S14: Section ownership vs metadata writes**
For each skill, read its `## Section Ownership` block (if present) and its `writes:` metadata. Compare: sections listed in ownership should appear in the `writes:` array as `path(Section Name)` entries. Flag discrepancies where ownership claims a section but metadata doesn't list it, or vice versa.
Severity: WARNING

**S15: Companion file vs dispatches**
For each skill, read `dispatches:` from metadata. For each dispatch slug, verify a matching companion file exists: `~/.claude/skills/<skill-name>/<slug>-prompt.md` or similar. Also verify companion files on disk that are NOT listed in dispatches. Report orphaned companions and missing companions.
Severity: WARNING

**S16: Tier misclassification**
For each skill with `tier:` in frontmatter, check whether its structural complexity matches its declared tier. If `tier: simple-orchestration`, flag as likely misclassified if ANY of the following are true: (a) the skill has more than 1 labeled phase headers (lines matching `## Phase`), (b) the `dispatches:` metadata is a non-empty array, or (c) prompt companion files exist in the skill directory (Glob `~/.claude/skills/<skill-name>/*-prompt.md`). If any condition is met, flag: "Structural complexity suggests complex-orchestration tier." If the skill has no `tier:` metadata, skip with a note -- do NOT report as failure.
Severity: WARNING

Tier 2 fix for S12: "Update tier in frontmatter or refactor skill to fit tier." Tier 2 fix for S14/S15/S16: "Update metadata to match actual skill behavior."

### Journey Handoff Checks (J-checks)

Validate developer journey `hands_off_to: PRESENT` claims against source tool SKILL.md content. Parses `wiki/articles/patterns/developer-journey-*.md` step blocks and, per claim, greps the source tool's SKILL.md with two-tier [[wiki:two-tier-drift-classification]] patterns. Single-invocation diagnostic profile preserved per [[accept-skill-size-exceptions]] §Phase 20 Reaffirmation — J-checks extend detection without altering the single-sweep profile boundary.

**J1: Handoff reference integrity (two-tier HARD/WARN)**
For each journey article, parse step blocks using a state-flag parser per [[wiki:awk-section-extraction-state-flag]] (NOT awk range syntax — EOF-boundary regression guard). For each step where `hands_off_to: PRESENT`: extract the step's `tool:` (source tool) and the NEXT step's `tool:` (target tool). Grep the source tool's SKILL.md **body only** (skip frontmatter between `---` delimiters AND skip `<!-- ... -->` HTML comment blocks — both classes produce known false-positive matches on `dispatches:` and convention-pointer comments) with two patterns in order: (a) HARD regex `Run [^\n]*${target}` (sentence-form handoff) — match emits PASS; (b) WARN regex bare `${target}` mention — match emits WARN (implicit handoff, may be prose-mention not true handoff); neither matches emits FAIL (PRESENT claim unsupported). EOF-fixture: last step in last-read journey file with no trailing newline MUST parse identically to interior steps (state-flag parser guarantees this; raw awk range syntax would self-terminate and drop the step).
Severity: WARNING (per-emission: PASS=none, WARN=info, FAIL=warning)

**J2: Emissions count consistency**
Total J1 emissions must equal the count of anchored PRESENT declarations: `grep -cE '^- \*\*hands_off_to:\*\* PRESENT' wiki/articles/patterns/developer-journey-*.md` across all 5 journey articles. **Anchor is load-bearing** — unanchored `grep -c 'hands_off_to: PRESENT'` drifts silently if prose contains the substring in a non-declaration context (e.g., "previously PRESENT"). Anchoring per [[wiki:two-tier-drift-classification]] HARD tier. Mismatch indicates parser error (likely EOF-boundary regression per [[wiki:silent-false-pass-pattern-family]]).
Severity: WARNING

**Applicability:** If `wiki/articles/patterns/developer-journey-*.md` Glob returns 0 files, J-checks SKIP silently (projects without defined journeys). If found, J-checks always run.

### Diagnosis Output Format

After running all checks, print a summary report:

```
Dev Wiki Health Check

ERRORS (must fix):
  <check-id>: <description> -- <specific details>

WARNINGS (should fix):
  <check-id>: <description> -- <specific details>

INFO:
  <check-id>: <description> -- <specific details>

Summary: N errors, M warnings, K info
```

If a severity bucket is empty, omit its section. If all checks pass:
```
Dev Wiki Health Check

All checks passed. Wiki is consistent.

Summary: 0 errors, 0 warnings, 0 info
```

After printing the diagnosis, proceed to Phase 2.

---

## Phase 2: REPAIR (user-gated)

If the diagnosis found 0 errors and 0 warnings, skip repair: "No fixes needed." STOP.

Otherwise, categorize available fixes into two tiers.

### Tier 1 -- Auto-apply (deterministic, no information loss)

Apply these immediately without asking. They are safe rebuilds from source-of-truth data:

| Fix | Trigger | Action |
|-----|---------|--------|
| Rebuild index.md | S7 found phantoms or missing entries | Regenerate index.md from articles on disk using Glob. Preserve the existing header/format. |
| Sync active-phase.md | S2 found mismatch | Read the **phase article** (source of truth) for Objective, Scope, Constraints, Exit criteria. Rewrite `$ROOT/.claude/rules/active-phase.md` from the phase article — do NOT sync from `_CURRENT_STATE.md` which may itself be stale. Reference Section B for size budget. |
| Delete stale breadcrumbs | S8 found breadcrumbs >7 days old | Delete `.session-end`, `.pending-commit`, `.session-buffer` files that are >7 days old. |
| Fix log.md | S9 found missing or empty log | Create `log.md` with a single bootstrap entry: `[<ISO-timestamp>] CHECK -- log.md created by /dev check` |
| Delete phase-mismatched active-knowledge | S10 found phase mismatch | Delete `$ROOT/.claude/rules/active-knowledge.md`. It references a stale phase and will be regenerated by `/dev plan`. |

Report auto-applied fixes with a checkmark:
```
Auto-applying (safe):
  [ok] Rebuilt index.md (added 2 missing articles)
  [ok] Synced active-phase.md to Phase 7
```

### Tier 2 -- User approval required (content or status changes)

Present these as numbered options. Each modifies content that may have been intentionally set:

| Fix | Trigger | Action |
|-----|---------|--------|
| Mark zombie phase completed | C7 | Set `status: completed` in phase frontmatter, update `_CURRENT_STATE.md` |
| Fix broken wikilinks | S6 | Remove or redirect broken `[[slug]]` links |
| Update architecture doc | C3 | Add undocumented directories to `_ARCHITECTURE.md`, remove phantoms |
| Rewrite _CURRENT_STATE.md | Multiple errors compound | Rebuild from phase articles and tasks.md (loses human-authored annotations) |
| Create missing phase article | S1 | Scaffold a phase article from tasks.md section header |
| Populate active-phase.md | S3 | Fill in Objective, Scope, Constraints from the active phase article |
| Complete phase tasks | C2 | Mark remaining tasks `[x]` in completed phases |
| Remove broken active-knowledge refs | C9 | Remove source sections with unresolvable `from:` links |
| Flag stale active-knowledge entries | C10 | Add `<!-- STALE -->` comment to entries where source was updated. Suggest re-running `/dev plan`. |
| Trim oversized active-knowledge | C11 | Re-distill active-knowledge.md per Section L overflow rules. If >40, delete and suggest `/dev plan`. |
| Prune excess working-knowledge entries | W1 | Evict lowest-count entries until at 100 per Section M LRU eviction rules. |
| Fix malformed working-knowledge entries | W3 | Remove or reformat entries that don't match the 2-line format. |
| Remove broken working-knowledge sources | W4 | Remove entries with unresolvable `source:` slugs. |
| Clean stale queue | CA5 | Remove invalid entries and entries referencing deleted files from `.stale-queue`. |

Present format:
```
Requires approval:
  1. Mark Phase 6 as completed (all tasks done)
  2. Update _ARCHITECTURE.md (add 2 new modules: notifications/, analytics/)
  3. Remove broken wikilink [[old-decision]] from phase-04 article
  4. Populate active-phase.md with Phase 7 data

Apply all / select by number / skip?
```

Wait for user response:
- **"all"** or **"apply all"**: Apply every listed fix.
- **Numbers** (e.g., "1, 3"): Apply only those fixes.
- **"skip"**: Apply nothing. Diagnosis still provides value.

### Post-repair

After applying any fixes (Tier 1 or Tier 2), append to `log.md`:
```
[<ISO-timestamp>] CHECK -- N errors, M warnings fixed; K items skipped
```

---

## Integration with /dev context

`/dev context` runs a **fast-lint** subset at session start: checks S1, S2, S4, and C1 only (the four ERROR-level checks that take <2 seconds). If any fail, `/dev context` emits:

```
[dev-wiki] Drift detected. Run /dev check for full diagnosis.
```

`/dev check` is the full diagnostic -- all 38 checks plus repair. It is always invoked explicitly by the user, never automatically.

---

## Error Handling

- If a check fails to execute (file read error, glob returns unexpected results), skip that check and note `SKIPPED: <reason>` in the report.
- Never abort the entire diagnosis because one check failed.
- The repair phase is optional. If the user says "skip", the diagnosis still provides value.
- If repair fails on a specific fix, report the failure and continue with remaining fixes.

---

## What This Skill Does NOT Do

- Does NOT run automatically. The user invokes it explicitly.
- Does NOT modify files during Phase 1 (diagnosis is strictly read-only).
- Does NOT apply Tier 2 fixes without explicit user approval.
- Does NOT perform conversation analysis or session capture (that is `/dev debrief`).
- Does NOT create new phases or plan work (that is `/dev plan`).
- Does NOT use subagents. All work is done in the main agent thread.
