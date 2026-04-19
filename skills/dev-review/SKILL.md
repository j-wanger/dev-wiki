---
name: dev-review
description: "Use when phase implementation completes. Dispatches 3 parallel reviewers (code, artifact, knowledge). Do NOT use at session start (use dev-context) or for planning (use dev-plan)."
reads: [$WIKI/_CURRENT_STATE.md, $WIKI/_ARCHITECTURE.md, $WIKI/tasks.md, $WIKI/articles/phases/*]
writes: []
dispatches: [code-reviewer, artifact-reviewer, knowledge-reviewer]
tier: complex-orchestration
---

# dev-review

Formal review gate between implementation and debrief. Dispatches 3 parallel reviewer subagents with disjoint scopes, collects reports, synthesizes findings, and presents a gate decision to the user.

**Topology:** Fan-out/fan-in (parallel). NOT sequential A->W->R.

---

## When to Use

- After completing all tasks in the active phase (before `/dev-debrief`)
- After completing a significant workstream within a phase
- When the user explicitly requests a review

**Not needed when:** Session was purely planning, only 1-2 small tasks completed, or no code/artifact changes were made.

---

## Section Ownership — _CURRENT_STATE.md

Read-only. This skill does not write to `_CURRENT_STATE.md`. It creates TodoWrite tasks for fixes and delegates capture to `/dev-debrief`.

---

## Pre-checks

1. **Discover dev wiki.** `$ROOT = git rev-parse --show-toplevel 2>/dev/null || pwd`. Check `$ROOT/.dev-wiki/_CURRENT_STATE.md` exists. If missing: "No dev wiki found." STOP.

Throughout this flow, `$ROOT` is the project root. `$WIKI` is `$ROOT/.dev-wiki`. Today's date is `$(date +%Y-%m-%d)`.
2. **Verify completed work.** Read `tasks.md` — active phase must have at least 1 completed task (`- [x]`). If 0 completed: "No completed tasks to review. Complete tasks first." STOP.
3. **Ensure companion prompts exist.** Glob `~/.claude/skills/dev-review/*-prompt.md`. Expect 3 files. If missing: "Missing reviewer prompts. Re-create them." STOP.

---

## Step 1: Load Review Context

Read silently (inject into context, do NOT print):

1. `$WIKI/_CURRENT_STATE.md` — active phase, decisions, blockers
2. `$WIKI/_ARCHITECTURE.md` — project structure, modules
3. `$WIKI/tasks.md` — completed and open tasks for active phase
4. Active phase article from `$WIKI/articles/phases/`
5. Decision articles referenced in `_CURRENT_STATE.md` (max 5)
6. `$ROOT/.claude/rules/active-phase.md` — phase constraints
7. `$ROOT/.claude/rules/active-knowledge.md` — activated wiki knowledge (if exists)

**Scope file discovery:** Extract `scope` globs from the phase article. Glob each pattern to build the list of files in scope. These are passed to the code reviewer.

**Multi-wiki knowledge:** Follow the Step 2 pattern from dev-plan — read `~/.claude/wikis.json`, score wikis, retrieve up to 5 relevant articles. Pass to the knowledge reviewer.

---

## Step 2: Dispatch 3 Parallel Reviewers

Launch 3 Agent tool calls in a **single message** (parallel fan-out). Each agent gets its companion prompt + context-specific data.

### 2a: Code Reviewer

Read `~/.claude/skills/dev-review/code-reviewer-prompt.md`. Construct prompt:
- Companion prompt content
- Phase scope file list (from Step 1)
- Completed task descriptions (from tasks.md)
- Phase constraints (from active-phase.md)
- Instruction: "Read each scope file. Review for quality, conventions, size caps, security, error handling. Output Score/Issues/Verdict."

### 2b: Artifact Reviewer

Read `~/.claude/skills/dev-review/artifact-reviewer-prompt.md`. Construct prompt:
- Companion prompt content
- Paths to all dev-wiki living documents and relevant articles
- Phase exit criteria (from phase article)
- Instruction: "Validate all dev-wiki artifacts for accuracy and consistency. Output Score/Issues/Verdict."

### 2c: Knowledge Reviewer

Read `~/.claude/skills/dev-review/knowledge-reviewer-prompt.md`. Construct prompt:
- Companion prompt content
- Retrieved wiki article summaries (from Step 1 multi-wiki)
- Active-knowledge.md content (if exists)
- Scope file list
- Instruction: "Check implementation follows documented wiki patterns. Flag deviations. Output Score/Issues/Verdict."

**Timeout:** 120 seconds per agent. If an agent fails, report the failure and continue with results from the other two.

---

## Step 3: Synthesize Reports

Collect all 3 reviewer reports. For each:
1. Parse `Score: N/10`, `Issues:` list, `Verdict: accept/revise/reject`
2. Categorize each issue: CRITICAL (blocks debrief), HIGH (recommend fix), MEDIUM (informational)
3. Deduplicate cross-reviewer findings (same file + same concern = one issue)

Compute aggregate:
- **Overall score:** Average of 3 reviewer scores
- **Gate decision:** If ANY reviewer has `reject` → BLOCKED. If any has `revise` → FIX RECOMMENDED. If all `accept` → PASSED.

---

## Step 4: Present Gate Report

```
## Review Gate Report

Overall: <PASSED|FIX RECOMMENDED|BLOCKED> (score: N/10)

### Code Review: <score>/10 — <verdict>
<issues list>

### Artifact Review: <score>/10 — <verdict>
<issues list>

### Knowledge Review: <score>/10 — <verdict>
<issues list>

### Cross-Reviewer Findings
<deduplicated issues that appeared in 2+ reviewers>

---
Options:
  A) Fix issues (creates TodoWrite tasks for each HIGH+ issue)
  B) Accept and proceed to /dev-debrief
  C) Re-review after fixes
```

---

## Step 5: Handle User Choice

- **A) Fix issues:** Create TodoWrite tasks for each CRITICAL and HIGH issue. Set first to `in_progress`. User implements fixes, then can run `/dev-review` again (option C).
- **B) Accept:** Note accepted issues in the journal context. Tell user: "Run `/dev-debrief` to capture this session."
- **C) Re-review:** Return to Step 1 with fresh context. Max 2 review cycles. After 2: "Recommend accepting current state and noting remaining issues for next phase."

---

## Error Handling

| Error | Response |
|-------|----------|
| No dev wiki | "No dev wiki found. Run `/dev-init`." STOP. |
| No completed tasks | "No work to review. Complete tasks first." STOP. |
| Agent timeout | Report which reviewer timed out, present partial results. |
| Agent failure | Skip failed reviewer, present 2/3 results with note. |
| Missing companion prompt | "Missing reviewer prompt files. Recreate them." STOP. |

For data flow conventions that inform code review context, see dev-wiki-reference.md Section G.
