# Husain Eval Framework Mapping

Maps the 4-step Husain eval playbook ([[wiki:husain-evals-playbook]]) to the dev-wiki skill suite. Reference for dev-retro dimensional analysis.

## Step 1: Error Analysis First, Not Metrics

**Implementation:** dev-retro Dimensions 1-3 (Recurring Blockers, Decision Reversals, User Corrections) analyze failure patterns before any score-based dimensions (5: Review Scores, 6: Phase Velocity). Dimension ordering enforces error-analysis-first.

## Step 2: Code Assertions First, LLM-Judge Second

| Assertion tier | Implementation | Husain alignment |
|----------------|---------------|-----------------|
| Code assertions | Task `success:` fields (bash commands, grep checks) | Direct: deterministic, per-task |
| Structural gates | dev-check (38+ checks), wiki-lint (10 checks) | Analog: post-implementation structural verification, not pre-commit unit assertions |
| LLM-judge | dev-review (3 subagent reviewers), approach/plan reviewers | Direct: model-based quality evaluation |

**Qualifier:** dev-check and wiki-lint are structural-gate analogs — they operate post-implementation rather than at Husain's pre-commit boundary. The `success:` field is the closest direct equivalent to Husain's L1 code assertions.

## Step 3: Three-Tier Test Cadence

| Tier | Husain definition | Dev-wiki implementation | Frequency |
|------|------------------|------------------------|-----------|
| L1 | Code assertions every commit | Task `success:` field verification | Every task completion |
| L2 | Model-based evals on cadence | dev-review (code/artifact/knowledge reviewers) | Every phase completion |
| L3 | Human review after major changes | dev-retro Dims 1-3+8+9 (user corrections, operational effectiveness, lifecycle eval) | Every 5-10 phases |

## Step 4: Start Small-Scale Immediately

**Implementation:** dev-retro requires only 3+ journal entries (not comprehensive eval coverage). Dimensions added incrementally (7 original → 8 Phase 25 → 9 Phase 55). Husain principle: "a few hand-labeled traces today beat a comprehensive-but-unbuilt eval suite later."
