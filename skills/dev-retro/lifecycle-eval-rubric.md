# Lifecycle Eval Rubric — Dimension 9 Companion

Per [[wiki:eval-rubric-dev-wiki-lifecycle]] — binary pass/fail rubric for plan/review/debrief outputs.

For each phase in the retro window, grade 3 sub-dimensions with binary pass/fail:

## 9a: Plan Quality (all 4 must PASS)

| Criterion | PASS | FAIL |
|-----------|------|------|
| Task count | 3-7 implementation, 2-5 audit/diagnostic | Outside range without reviewer acceptance |
| Scope precision | File globs or explicit paths | Vague descriptions |
| Exit criteria | Testable (could write a bash check) | Subjective or unmeasurable |
| YAGNI | No tasks beyond exit criteria | Gold-plating, scope creep |

## 9b: Review Accuracy (all 3 must PASS)

| Criterion | PASS | FAIL |
|-----------|------|------|
| Finding rate | At least 1 genuine issue caught | Zero findings across reviewers |
| Score calibration | Distributed range | Uniformly high or low |
| False positive handling | FPs identified and dropped | FPs driving wasted revision |

## 9c: Debrief Completeness (all 3 must PASS)

| Criterion | PASS | FAIL |
|-----------|------|------|
| Decision capture | All decisions have articles | Decisions undocumented |
| Artifact coverage | Journal lists key artifacts with paths | Major artifacts omitted |
| State freshness | _CURRENT_STATE.md updated | State references completed phase as active |

## Interpretation

Record sub-dimension failures as retro findings with the failure-mode category. Track pass rates over time to detect quality drift per [[wiki:criteria-drift]].
