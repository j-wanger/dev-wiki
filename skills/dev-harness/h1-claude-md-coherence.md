# H1: CLAUDE.md Coherence

trigger: read this file when /dev-harness is invoked with no argument or with `H1` argument. Self-describing per the Phase 17 companion convention — check definitions live here, not in the SKILL.md.

## Scope

Audits global (`~/.claude/CLAUDE.md`) and project (`$ROOT/CLAUDE.md`) entry-point files for the 5 invariants from [[wiki:harness-composition-playbook]]. Read-only — produces findings, never modifies files.

## Checks

Run all 5 checks against `~/.claude/CLAUDE.md`, then re-run the project-applicable subset against `$ROOT/CLAUDE.md` (if it exists).

| ID | Check | Pass condition | Severity if fail |
|---|---|---|---|
| H1.i  | exists                | file exists at expected path                                                 | HIGH (global) / MEDIUM (project, optional)  |
| H1.ii | size cap              | `wc -l` ≤ 80                                                                 | MEDIUM                                      |
| H1.iii | imports resolve      | every `~/.claude/rules/common/*.md` referenced inside actually exists        | HIGH                                        |
| H1.iv | no project-content (global only) | no `## Phase` section header in the global file                  | HIGH                                        |
| H1.v  | precedence statement  | references `[[wiki:claude-md-interaction-contract]]` OR explicitly states which file wins | MEDIUM                                      |

H1.iv is global-only (it's the "project content leaked into global" detector that motivated Phase 18). Skip for project files.

## Inspection Logic

For each target file (`~/.claude/CLAUDE.md`, then `$ROOT/CLAUDE.md` if present):

1. **H1.i:** `[ -f <path> ]`. If false, emit `[HIGH] H1.i <path>: file missing` and skip remaining checks for that file.
2. **H1.ii:** `wc -l <path>`. If > 80, emit `[MEDIUM] H1.ii <path>: <N> lines > 80-line cap (per [[wiki:harness-composition-playbook]] invariant #2)`.
3. **H1.iii:** `grep -oE 'common/[a-z-]+\.md' <path>` to extract referenced module names. For each, verify `[ -f ~/.claude/rules/common/<name> ]`. Each unresolved import → `[HIGH] H1.iii <path>: imports common/<name> but file missing`.
4. **H1.iv (global only):** `grep -E '^## Phase\b' ~/.claude/CLAUDE.md`. Any match → `[HIGH] H1.iv ~/.claude/CLAUDE.md: contains '## Phase' header — project-specific content has leaked into global scope (invariant #1)`.
5. **H1.v:** `grep -E 'claude-md-interaction-contract|specificity wins|project (rule )?(wins|overrides)' <path>`. If no match → `[MEDIUM] H1.v <path>: no precedence statement found — consider adding reference to [[wiki:claude-md-interaction-contract]] or explicit override note`.

## Report

If all checks pass for both files, emit:
```
H1: PASS — global + project CLAUDE.md coherent (5 checks each)
```

Otherwise emit per-finding lines per the SKILL.md output convention. The orchestrator (dev-harness SKILL.md Step 3) aggregates across companions.
