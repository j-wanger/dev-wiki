---
name: dev-wiki
description: "Route dev wiki operations and enforce development lifecycle discipline. Use when user mentions 'dev wiki', 'project state', 'phases', 'tasks', or wants lifecycle management. Also activated by SessionStart hook when .dev-wiki/ exists. Do NOT invoke when user names a specific /dev-* command — invoke that command directly (dev-context, dev-plan, etc.)."
reads: [$WIKI/_CURRENT_STATE.md]
writes: []
dispatches: []
tier: simple-orchestration
---

<EXTREMELY-IMPORTANT>
When `.dev-wiki/` exists in the current project, dev wiki operations are part of the workflow. Do not wait for the user to ask -- suggest operations at natural moments. Undocumented sessions are lost sessions. Enforce the lifecycle.
</EXTREMELY-IMPORTANT>

# dev-wiki

## The Lifecycle

Development follows a cycle. Every phase, every session, every task passes through it:

```
init (once) → context (session start) → plan (phase start) →
implement (TDD per task) → review (optional gate) → debrief (session end) → [next phase: plan]
```

Orthogonal (anytime): `/dev-scan` (codebase analysis), `/dev-check` (integrity validation), `/dev-adjust` (mid-phase replanning).

## Tool Usage Standards

All dev-wiki skills MUST follow these tool selection rules (from `tool-selection-heuristics`):

| Operation | Tool | NOT |
|-----------|------|-----|
| Find files by name/pattern | Glob | Bash find, ls |
| Search content in files | Grep | Bash grep, rg |
| Read file content | Read | Bash cat, head, tail |
| Modify existing file | Edit (sends only diff) | Bash sed, awk |
| Create new file | Write | Bash echo/heredoc |
| Git operations | Bash | — |
| File mtime comparison | Bash stat | — (no dedicated tool) |

**Exception:** Bash `find` is acceptable for bulk operations where Glob+Read would produce too many individual tool calls (e.g., batch hashing in `/dev-scan`). Document the exception when used.

## The Rule

**When `.dev-wiki/` exists, lifecycle operations are always in scope.** You do not need the user to say "dev wiki" -- if you see an opportunity to plan, capture, or validate, act on it.

## Automatic Triggers

| Condition | Action |
|-----------|--------|
| Session start, `.dev-wiki/` exists | `/dev-context` |
| Active phase has 0 open tasks, 0 completed | `/dev-plan` |
| All phase tasks completed | Suggest `/dev-review` before debrief, then phase completion + `/dev-plan` for next |
| Task blocked > 3 attempts | `/dev-adjust` |
| Session ending with code changes | `/dev-debrief` |
| State > 7 days stale | Warn, suggest `/dev-debrief` |
| Context window > 75% full | Suggest `/dev-debrief` before compaction |
| No `.dev-wiki/` but user mentions dev wiki | `/dev-init` |
| `_ARCHITECTURE.md` shallow or absent | `/dev-scan` |
| `/dev-context` emits drift warning | `/dev-check` |
| Phase count is multiple of 5 | Suggest `/dev-retro` |
| Process feels repetitive or friction is high | `/dev-retro` |

## Red Flags

These thoughts mean STOP -- you are rationalizing skipping lifecycle discipline:

| Thought | Reality |
|---------|---------|
| "I'll debrief later" | You won't. `/dev-debrief` now. |
| "This phase is too simple to plan" | Every phase goes through `/dev-plan`. Even trivial ones. |
| "I know what to do" | `/dev-context` loads actual state. Your memory may be stale. |
| "I'll skip the test" | TDD is non-negotiable. RED → GREEN → REFACTOR per task. |
| "I'll adjust the plan in my head" | `/dev-adjust` writes the changes. Mental plans evaporate. |
| "The wiki is probably fine" | Run `/dev-check`. Drift is invisible until it hurts. |

## Skill Classification

Most dev-wiki skills are **single-agent** (Claude does all work directly). Exceptions noted below:

- `/dev-init` -- Bootstrap `.dev-wiki/` scaffold
- `/dev-context` -- Session startup state loader
- `/dev-plan` -- Phase planning with wiki knowledge retrieval (dispatches approach + plan reviewer subagents)
- `/dev-debrief` -- Tiered session capture (full or quick)
- `/dev-check` -- 37-check structural validator (includes S12-S15 skill metadata checks)
- `/dev-adjust` -- Lightweight mid-phase replanning
- `/dev-scan` -- Deep codebase analysis (**hybrid:** main agent scans, subagents synthesize articles)
- `/dev-review` -- Formal review gate (**fan-out:** 3 parallel reviewer subagents, fan-in: synthesized report)
- `/dev-retro` -- Process retrospective (7 structured dimensions, run every 5-10 phases)

## Command Reference

Route user intent to the correct dev skill:

| User intent | Route to |
|-------------|----------|
| "Set up dev tracking" / "bootstrap dev wiki" | /dev-init |
| "Load project state" / "what's the current phase?" / session start | /dev-context |
| "Plan the next phase" / "what should I work on?" | /dev-plan |
| "Task is blocked" / "need to change approach" | /dev-adjust |
| "Session done" / "save progress" / "I'm stopping" | /dev-debrief |
| "Check wiki health" / "is the state consistent?" | /dev-check |
| "Scan the codebase" / "analyze code structure" | /dev-scan |
| "Review before debrief" / "run review gate" / "validate implementation" | /dev-review |

## Shared Reference

All dev-wiki skills share `~/.claude/skills/dev-wiki/dev-wiki-reference.md` (Sections A-V). Skills reference specific sections by letter (e.g., "Section A for slugification"). Do not inline or duplicate section content — read on demand. For data flow conventions see Section G, knowledge partitioning see Section M, CLAUDE.md lifecycle see Section U, developer journey conventions see Section V.

## Cross-Package Integration

- dev-wiki owns `.dev-wiki/`, knowledge-wiki owns `wiki/`
- `/dev-plan` reads wiki articles for knowledge-informed planning
- `active-knowledge.md` (written by `/dev-plan`) and `working-knowledge.md` (written by `/wiki-query`) are separate knowledge layers
- knowledge-wiki does not write to `.dev-wiki/`; dev-wiki does not write to `wiki/`

## If Unclear

When the user's dev wiki intent is ambiguous, ask:

> What would you like to do with the dev wiki?
>
> - **Context** -- Load current project state
> - **Plan** -- Plan the next development phase
> - **Adjust** -- Replan blocked or changed tasks
> - **Debrief** -- Capture this session's work
> - **Review** -- Formal review gate (before debrief)
> - **Check** -- Validate wiki integrity
> - **Scan** -- Deep codebase analysis

Do not guess. Present the options and let the user choose.
