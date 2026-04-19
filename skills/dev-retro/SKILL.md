---
name: dev-retro
description: "Use when process feels repetitive (every 5-10 phases). Analyzes journals + decisions for recurring patterns. Do NOT use for session debrief (use dev-debrief) or structural validation (use dev-check)."
reads: [$WIKI/articles/journal/*, $WIKI/articles/decisions/*]
writes: [$WIKI/articles/journal/*, $WIKI/log.md, $WIKI/index.md]
dispatches: []
tier: simple-orchestration
---

<!-- Convention: see dev-wiki-reference.md Section V (Journey Integration Conventions) for Dimension 8 cross-reference pattern and SSOT direction -->

# dev-retro

Analyze the project's development history to identify recurring patterns, user corrections, and workflow friction. Produces a dated retrospective article with actionable recommendations.

This is a **single-agent skill** -- Claude does all work directly. No subagents.

---

## Pre-checks

1. **Discover dev wiki.** `ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)`. Set `WIKI=$ROOT/.dev-wiki`.
2. **Verify journal entries.** Glob `$WIKI/articles/journal/*.md`. If fewer than 3 entries: "Not enough history for a retrospective (need 3+ journal entries). Run more phases first." STOP.
3. **Count phases completed.** Read `$WIKI/tasks.md`, count `<details>` blocks (collapsed = completed phases). Note current active phase number.

---

## Step 1: Load History (Capped Input)

Read the **last 10 journal entries** (by filename date sort, most recent first) and the **last 10 decision articles** (by `created:` frontmatter date). Cap prevents token bloat as the project grows.

Also read `$WIKI/_CURRENT_STATE.md` for active phase context. **Budget:** At most 22 file reads.

---

## Step 2: Analyze Against 7 Structured Dimensions

For each dimension, extract concrete evidence from the journal/decision corpus. Do NOT fabricate patterns — only report what the data shows. If a dimension has no findings, say "No evidence in reviewed entries."

### Dimension 1: Recurring Blockers
Scan for: blocked tasks, permission errors, subagent failures, repeated workarounds. A blocker is "recurring" if it appears in 2+ journal entries.

### Dimension 2: Decision Reversals
Scan for: decisions made then later overridden, confidence downgrades, approaches abandoned. Cross-reference decision articles with journal "Problems Solved" sections.

### Dimension 3: User Corrections
Scan for: user overrides of agent decisions, restorations of prior state, "user requested" changes, mandatory architecture loading-style reversals. This is the highest-signal dimension — it reveals preference/reliability gaps.

### Dimension 4: Skill Size Trends
For each dev-wiki skill, read `tier:` from metadata and count current lines via `wc -l`. Build a table: skill name, current lines, tier, over/under budget. Flag skills approaching or exceeding their tier cap.

### Dimension 5: Review Score Trends
Scan journal entries for `/dev-review` results (scores like "7/10, 8/10"). Track average scores across phases. Note if scores are improving, declining, or stable. If no review data exists, note "No /dev-review data in reviewed entries."

### Dimension 6: Phase Velocity
Count phases completed per day (from journal dates). Track tasks-per-phase counts. Note if phases are getting larger, smaller, or staying consistent.

### Dimension 7: Pattern Cascades
Per [[wiki:failure-mode-taxonomy]]: look for chains where one failure mode led to another. E.g., compression (optimization) → regression (behavioral break) → restoration (user correction) → size-tiering decision. These cascades reveal systemic issues.

### Dimension 8: Operational Effectiveness
<!-- See [[wiki:developer-journey-methodology]] Integration Points — Dimension 8 operationalizes the acceptance-test layer -->

Cross-reference journey steps against the last 10 journal entries. This dimension is the operational counterpart to structural dimensions 1-7: where 1-7 measure internal consistency (blockers, decisions, corrections, size, scores, velocity, cascades), Dimension 8 measures whether defined workflows are actually being followed.

**Process:**
1. Read `wiki/articles/patterns/developer-journey-*.md` for step→tool mappings (5 journeys expected post-Phase-26).
2. For each step's `tool:` name, grep the last 10 journals for mentions.
3. Classify each step into 3 categories:
   - **Correction-prone** — tool appears in journals correlated with Dim 3 user corrections (same journal entry).
   - **Blocking-prone** — tool appears in journals where Dim 1 blocked-task signals exist.
   - **Skipped** — tool has ZERO mentions across 10 journals (step is bypassed or undocumented, NOT merely infrequent).

**Interpretation:** Skipped steps are the highest-signal finding for Operational Effectiveness — they imply the journey is aspirational, not operational. Correction-prone and blocking-prone steps are secondary — they show real pain points in an actually-used workflow.

**Historical note:** Journals pre-dating Phase 25 (when journeys were defined) may have lower tool-name coverage because tool-step mapping didn't exist yet. Accept partial coverage for those phases rather than over-reporting apparent Skipped-step findings.

---

## Step 3: Write Retrospective Article

Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section T for the retro article template. Read Section A for slugification rules.

Write the article to `$WIKI/articles/journal/YYYY-MM-DD-retro-phases-N-M.md` where N and M are the first and last phase numbers covered.

Include a `## Recommendations` section with 3-5 actionable suggestions grounded in the patterns above. Recommendations should be specific enough to become tasks in a future phase.

---

## Step 4: Update Wiki Artifacts

1. Append to `$WIKI/log.md`: `[<ISO-timestamp>] RETRO -- Phases N-M, <key finding count> findings, <recommendation count> recommendations`
2. Add the retro article to `$WIKI/index.md` under Journal (Recent section).
3. Print a summary to the user: key findings count per dimension, top 3 recommendations.

---

## Step 5: Suggest Next Actions

Based on findings, suggest one of:
- "Findings are minor. Continue with current workflow."
- "Pattern X is systemic. Consider `/dev-plan` to address it in the next phase."
- "Multiple cascades detected. Consider a workflow overhaul phase."

Refinement-phase candidates should be framed per [[wiki:refinement-phase-pattern]] (3-4 tasks, 1-2hr, XS-S tier, bundle-over-split when independent).

---

## Error Handling

| Error | Response |
|-------|----------|
| No dev wiki | "No dev wiki found. Run `/dev init`." STOP. |
| <3 journal entries | "Not enough history." STOP. |
| Dimension has no findings | Report "No evidence in reviewed entries." Continue. |
| File read failure | Skip that file, note in output. Continue. |

---

## What This Skill Does NOT Do

- Does NOT modify existing articles (read-only analysis + new article write).
- Does NOT run automatically. User invokes explicitly or prompted when phase count % 5 == 0.
- Does NOT replace `/dev-debrief` (which captures single sessions, not cross-session patterns).
- Does NOT replace `/dev-check` (which validates structure, not process quality).
- Does NOT use subagents. All analysis is done in the main agent thread.

For CLAUDE.md lifecycle monitoring (Section U) and knowledge partitioning conventions (Section M), see dev-wiki-reference.md.
