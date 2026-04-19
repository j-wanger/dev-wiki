# Implementation Guide

Extracted from dev-plan Step 10. Read when the user chooses option A or C in Step 9.

## Option A: Continue in This Session

Follow TDD cycle embedded in each task: RED (write test, verify fail) -> GREEN (implement, verify pass) -> REFACTOR -> VERIFY (run `success:` field commands; iterate if fail; if no `success:` field, emit "No success: field — verification skipped"). Mark `[x]` in `tasks.md` only after VERIFY passes, before moving to next task.

Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section D for escape hatches and Section E for blocked task escalation.

## Option C: Subagent-Driven Parallel

Identify tasks with disjoint file sets. Construct enriched prompts per task with scope, constraints, success criteria, and TDD cycle.

**Error handling:** Set a 120-second timeout per subagent. Collect all results before applying. Check for file conflicts (multiple subagents writing the same file) — if conflicts found, report to user and apply non-conflicting results only. Report individual subagent failures: "Task N failed: [error]. Remaining tasks succeeded." Do NOT retry failed subagents automatically.

**Success-criterion validation:** Before marking any task complete, run its `success:` field commands. If a subagent's success criterion fails, report to user — do NOT auto-iterate (subagent isolation requires re-dispatch, which is the user's choice).

After all complete, update `tasks.md`, run full test suite, resolve conflicts.
