# Retro Article Template

Process retrospective article produced by `/dev-retro`. Analyzes journal entries and decisions to identify recurring patterns and workflow friction.

## Frontmatter

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

## 9 Analysis Dimensions (required sections)

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

## 8. Operational Effectiveness
<Cross-reference journey steps against last 10 journals. Classify each step as Correction-prone, Blocking-prone, or Skipped. Skipped = highest-signal finding (aspirational, not operational).>

## 9. Lifecycle Output Quality
<Grade per lifecycle-eval-rubric.md: Plan Quality (4 criteria), Review Accuracy (3), Debrief Completeness (3). Binary pass/fail per phase. Track pass rates over time.>

## Dimension Distribution
<Per-dimension scores table. Do not normalize or average — report separately per [[wiki:dimension-coverage-asymmetry]].>

## Recommendations
<3-5 actionable suggestions for workflow improvement, grounded in the patterns above.>
```

