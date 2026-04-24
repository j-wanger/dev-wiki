# Developer Journey Conventions

Shared companion for dev-wiki skills. Defines how developer journey articles are structured, named, evaluated, and integrated into the dev-wiki review architecture.

## Journey Article Schema

Journey articles live in the knowledge wiki at `wiki/articles/patterns/developer-journey-<name>.md` with frontmatter:

```yaml
---
title: "Developer Journey: <Name>"
category: patterns
tags: [developer-journey, <relevant-domain-tags>]
parents: [<lifecycle-or-pattern-parent>]
---
```

## Step Schema (5-field)

Each journey step uses this schema:

- **tool:** The skill, hook, or manual action at this step
- **provides:** Information or artifacts the tool produces
- **expects:** Information or state required from the prior step
- **hands_off_to:** PRESENT (explicit next-step mention) | PARTIAL (implicit/conditional) | MISSING (no mention)
- **gap:** Phase 24 gap number (e.g., "#3") or "none"

The `hands_off_to` field is the primary diagnostic signal — MISSING handoffs are the main source of developer friction.

## Naming Convention

- Articles: `developer-journey-<name>.md` (kebab-case)
- Tags: always include `developer-journey`
- Parents: assign to the most relevant lifecycle or pattern parent (e.g., `session-handoff-protocols`, `session-lifecycle`, `human-in-the-loop-patterns`)

## Evaluation Criteria

| Rating | Criteria |
|--------|----------|
| COVERED | Tool exists + handoff PRESENT + info flow connected |
| PARTIAL | Tool exists but handoff implicit or info flow gapped |
| MISSING | No tool for this step or no relevant output |

**Per-journey score:** COVERED / total steps. **Suite score:** average across journeys.

## Defined Journeys (Phase 25)

1. **Cold Start** — project adoption from zero to first phase completion (7 steps)
2. **Daily Session** — resuming work through implementation to session end (7 steps)
3. **Quality Gate** — phase completion through review, debrief, next-phase (7 steps)

Deferred to Phase 26: Problem Handling, Knowledge Flow.

## Integration Roadmap (Phase 26)

- **/dev-check J-checks:** Deterministic handoff verification — grep each tool's output for next tool's name. PASS/FAIL per step.
- **/dev-retro Dimension 8:** Subjective journey coverage — cross-reference steps against journal evidence for user corrections, blocked tasks, skipped steps.

## Journey Integration Conventions (Phase 26)

<!-- SSOT for J-check + Dimension 8 conventions. SKILL.md convention-pointer comments in dev-check/dev-retro/dev-adjust are derived views — when updating conventions, edit THIS section first, then refresh the pointers. -->

**J-check convention (consumed by /dev-check Journey Handoff Checks):** Each journey step with `hands_off_to: PRESENT` is a check assertion. /dev-check J1 validates the claim via two-tier classification: HARD match requires `Run .*${next_tool}` sentence-form in the source tool's SKILL.md (the canonical handoff form); WARN match accepts a bare mention (implicit handoff). FAIL when neither pattern matches. Parse journey articles with a state-flag parser — NEVER awk range syntax (EOF-boundary regression).

**Dimension 8 convention (consumed by /dev-retro Operational Effectiveness):** Cross-reference journey step `tool:` names against last 10 journal entries. Classify each step as Correction-prone (overlaps Dim 3), Blocking-prone (overlaps Dim 1), or Skipped (zero journal mentions = aspirational step, highest-signal finding). Accept partial coverage for pre-Phase-25 journals where tool-step mapping didn't exist.
