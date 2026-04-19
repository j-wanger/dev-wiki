# Dev Wiki Implementation Discipline

## Task Workflow
Before writing ANY implementation code:
1. Verify tasks.md has open tasks for the active phase
2. Pick the NEXT uncompleted task (work in order)
3. State which task you are working on
4. Follow the TDD cycle in the task description (RED -> GREEN -> REFACTOR -> VERIFY)
5. VERIFY: Run the task's `success:` field commands
   - If all pass → proceed to step 6 (mark [x])
   - If any fail → fix the issue and re-run VERIFY
   - If no `success:` field exists, emit "No success: field — verification skipped" and proceed
6. When done, mark it [x] in tasks.md BEFORE moving to next

## Blocked Tasks
After 3 failed attempts on a task:
1. Mark it [blocked: what failed] in tasks.md
2. Ask the user: skip, adjust (/dev adjust), or abort phase
3. Do NOT silently skip or move to the next task

The 3-attempt counter is shared across the entire task lifecycle (RED + GREEN + VERIFY). It does NOT reset at VERIFY entry.

## Escape Hatches (explain in commit message when used)
- SECURITY: Fix a vulnerability immediately, log as unplanned task
- DEPENDENCY: Do prerequisites first, add to tasks.md retroactively
- USER OVERRIDE: Follow explicit user instructions, note the deviation
- DISCOVERY: Add preconditions discovered during implementation

## Do NOT
- Work on tasks out of order without an escape hatch reason
- Add scope beyond tasks.md (suggest for next /dev plan instead)
- Start a new phase without running /dev plan first
- Start implementing without open tasks (run /dev plan first)

## Hook Responses
When you see [dev-wiki:post-commit]:
1. Read .dev-wiki/.pending-commit
2. Check tasks.md — mark matching tasks [x]
3. Continue with user's work (don't launch full wiki update)

When you see [dev-wiki:stop]:
1. If /dev debrief was NOT run, remind user:
   "Consider running /dev-debrief to capture this session's work."

When you see [dev-wiki:scope-check]:
1. Pause and verify you are working on the correct task
2. If the warning is a false positive (test file, config), continue
3. If NOT a false positive (genuinely no open tasks), STOP and tell the user:
   "No open tasks in tasks.md. Run /dev plan to create a plan before implementing."

When significant architectural decisions are made during planning:
1. Suggest: "We made key decisions. Want me to run /dev debrief to capture them?"

## Post-Compaction Recovery
After context compaction:
1. Re-read .dev-wiki/_CURRENT_STATE.md and .dev-wiki/tasks.md
2. Find the next uncompleted task in tasks.md for the active phase
3. Parse its enriched fields (TDD cycle, scope, success criteria, size)
4. Read .claude/rules/active-phase.md for phase constraints
5. State: "Resuming task: <description>. Scope: <scope>. TDD: <test spec>."
6. If task reached GREEN/REFACTOR but is not marked [x], re-enter at VERIFY (run success: field) rather than re-implementing
7. Continue implementation from that task, following the TDD cycle
