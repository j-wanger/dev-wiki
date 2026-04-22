# Ceremony Levels

Companion to dev-plan SKILL.md. Defines the two ceremony levels and their per-step rules. Read by dev-plan at Step 0.5.

## Design Principle: Scale Ceremony, Preserve Exploration

Exploration steps (wiki retrieval, scope analysis, knowledge completeness) stay at ALL ceremony levels because they directly improve plan quality. Both Lite and Standard run Steps 1-3 fully. What scales down at Lite is review gates and documentation formalism — overhead valuable for complex work but disproportionate for small tasks.

## Configuration

**Project default:** `.dev-wiki/config.md` with `ceremony: standard | lite`. Created by `/dev-init` during bootstrap.

**Per-phase override:** Phase article frontmatter `ceremony: lite` overrides project default for that phase only.

**Precedence:** Phase frontmatter > config.md > default (standard).

**Graceful degradation:** If neither config.md nor phase frontmatter exists, default to `standard`. Skills must not fail on missing config.

## Level Definitions

| Level | Target Use Case | Overhead Reduction |
|-------|----------------|-------------------|
| **Lite** | App projects, small features, <1 day tasks | ~50% fewer steps; no subagent reviewers |
| **Standard** | Complex features, meta-tooling, multi-day work | Full workflow (current behavior) |

**Level 0 (implicit):** No `/dev-plan` invocation. User works without phase ceremony. Not implemented — just absence.

## Per-Step Skip Rules

| Step | Name | Lite | Standard |
|------|------|------|----------|
| 1 | Load Wiki State | Run | Run |
| 2 | Cross-Wiki Knowledge | Run | Run |
| 2.5 | Iterative Retrieval | **Skip** | Run |
| 3 | Explore Phase Scope | Run | Run |
| 3.5 | Toolchain Validation | **Skip** | Run |
| 4 | Design Questions | Run (persist to Blockers) | Run |
| 5 | User Questions | 0-1 questions max | 1-3 questions |
| 6 | Propose Approach | Run (inline, no options comparison) | Run (1-2 options with trade-offs) |
| 6.1 | Contradiction Check | **Skip** | Run |
| 6.5 | Approach Reviewer | **Skip** | Dispatch subagent |
| 7 | User Approves | Run (single gate) | Run |
| 7.5 | Plan Reviewer | **Skip** | Dispatch subagent |
| 7.6 | Present Reviewed Plan | **Skip** (merged into Step 7) | Run (second approval gate) |
| 8a | Decision Articles | **Skip** | Write |
| 8b | Tasks to tasks.md | Simplified schema | Full TDD schema |
| 8c | Update _CURRENT_STATE.md | Run | Run |
| 8e | Phase Article | Minimal (objective + scope) | Full (exit criteria, notes) |
| 8f | active-phase.md | Run | Run |
| 8f-bis | active-knowledge.md | **Skip** | Run |
| 8g | TodoWrite | Run | Run |
| 8h-i | Log + Index | Run | Run |
| 9 | Transition Gate | Run | Run |
| Post-Impl | Self-Check | **Simplified** (categories 1-2 only) | Run (all 6 categories) |

Self-check categories 1-2 (Lite subset): (1) cross-reference resolution, (2) line count vs budget. Full 6-category list in `self-check-checklist.md`.

## Simplified Task Schema (Lite)

```
- [ ] <Description> | scope: <globs> | success: <criterion> | size: S
```

No TDD cycle (RED/GREEN/REFACTOR). No data_contract. Description is imperative ("Add X", "Update Y"). Success criterion must still be a runnable command.

## dev-context Per-Step Skip Rules

Core state-loading (Steps 1-5) always runs at both levels — this is exploration. Diagnostics and validation are ceremony.

| Step | Name | Lite | Standard |
|------|------|------|----------|
| 0.5 | Ceremony Level Detection | Run | Run |
| 1 | Discover Dev Wiki | Run | Run |
| 2 | Process Breadcrumbs | Run | Run |
| 2.5 | Process Stale Queue | Run | Run |
| 3 | Read Living Documents | Run | Run |
| 4 | Check Staleness | Run | Run |
| 5 | Read Active Phase Article | Run | Run |
| 5a | Fast-Lint (Drift Detection) | **Skip** | Run |
| 6 | Detect Planning Needs | Run | Run |
| 6a | Validate active-knowledge Phase Match | Run | Run |
| 7 | Check Knowledge Wiki | Run (name + count only) | Run (full) |
| 7a | Check Working Knowledge | **Simplified** (count only, skip stale) | Run (count + stale + parse errors) |
| 7b | Knowledge-Gap Detection | **Skip** | Run |
| 7c | Cadence Diagnostics | **Skip** | Run |
| 8 | Emit Context Block | **Simplified** (4 lines: NEXT ACTION, ACTIVE PHASE, TASKS, PLANNING) | Run (full block with HEALTH, SCAN, DIAGNOSTICS) |

## dev-debrief Per-Step Skip Rules

Core journal capture always runs — it is the exploration (capturing what happened). Cross-referencing, decision documentation, and knowledge maintenance are ceremony.

| Step | Name | Lite | Standard |
|------|------|------|----------|
| 0.5 | Ceremony Level Detection | Run | Run |
| 1 | Load Session Context | Run | Run |
| 2 | Significance Detection | Run | Run |
| 3 | Journal Capture | **Simplified** (shorter format, key facts only) | Run (full format with patterns + observations) |
| 4 | Phase Article Update | **Simplified** (frontmatter status only) | Run (full update with progress, notes) |
| 5 | _CURRENT_STATE.md Update | Run (Recommended Next Action + Journal) | Run (full: all owned sections) |
| 6 | Cross-Reference Updates | **Skip** | Run |
| 7 | Decision Article Creation | **Skip** | Run |
| 8 | Working-Knowledge Decay | **Skip** | Run |
| 9 | Log + Index Update | Run | Run |
| 10 | active-phase.md Update | Run | Run |

## Error Handling

| Error | Response |
|-------|----------|
| config.md missing | Default to standard. Do not warn. |
| config.md has invalid ceremony value | Warn: "Unknown ceremony level '<value>'. Defaulting to standard." |
| Phase frontmatter `ceremony:` not lite or standard | Ignore frontmatter, use config.md or default. |
