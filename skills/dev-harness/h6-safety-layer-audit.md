# H6: Safety Layer Audit

trigger: read this file when /dev-harness is invoked with no argument or with `H6` argument. Self-describing per the Phase 17 companion convention — check definitions live here, not in the SKILL.md.

## Scope

Audits the agent harness for safety layer coverage. Verifies that the 5 defense-in-depth layers from [[wiki:agent-safety-and-reliability]] are present and codified, classifies failure mode severity per [[wiki:failure-mode-taxonomy]], and maps stake-level autonomy profiles. Read-only — produces findings, never modifies files.

## Safety Layer Inventory

The 5 layers from [[wiki:agent-safety-and-reliability]], with current implementation status:

| Layer | Name | Implementation | Status |
|-------|------|---------------|--------|
| 1 | Prompt Rules | `~/.claude/rules/common/security.md`, CLAUDE.md behavioral constraints, `common/coding-style.md` input validation | IMPLEMENTED |
| 2 | Tool Restrictions | `allowedTools` in settings.json (reference), tool preference rules in `~/.claude/agents/*.md` (Tool Standards sections) | IMPLEMENTED |
| 3 | Hook Enforcement | `dev-wiki-scope-check.sh` (open-task gate), `stale-queue.sh` (file change tracking), `session-start.sh`/`session-stop.sh` (lifecycle) | IMPLEMENTED |
| 4 | Human Approval | Tiered permission model (settings.json), 3-attempt escalation (dev-wiki-hooks.md), interactive confirmation for destructive ops | IMPLEMENTED |
| 5 | External Monitoring | Log aggregation, anomaly detection, runtime observability | NOT_IMPLEMENTED — requires external infrastructure beyond the declarative Markdown skill framework |

## Failure Mode Severity Classification

Maps the 6 failure modes from [[wiki:failure-mode-taxonomy]] to severity levels. Use this classification when triaging agent behavior issues. **Note:** Infinite loops and tool misuse are elevated to Critical from the wiki's High classification — project-local override because both can cause irreversible damage (token burn, data loss) in an agent context.

| Severity | Failure Mode | Root Cause | Existing Mitigation |
|----------|-------------|------------|-------------------|
| Critical | Infinite loops | Unbounded retries, circular tool calls | 3-attempt escalation rule (dev-wiki-hooks.md) |
| Critical | Tool misuse | Destructive actions on wrong targets | Scope-check hook, tool restrictions (Layer 2), permission model (Layer 4) |
| High | Scope creep | Drifting beyond task boundaries | `dev-wiki-scope-check.sh`, code-reviewer agent, task scope fields |
| High | Hallucination | Acting on unverified assumptions | Pause-and-present-options discipline (security.md ## Agent Safety), Read-before-Edit discipline |
| Medium | Context drift | Stale state after compaction or long sessions | Compaction anchors (active-phase.md), post-compaction recovery protocol |
| Medium | Confidently wrong | Plausible but incorrect output | TDD enforcement (tdd-guide agent), verification-before-completion |

**Decision tree:** If action is irreversible AND uncertainty is high → treat as Critical. If action affects shared state (git, external APIs) → treat as High. If action is local and reversible → treat as Medium.

## Stake-Level Autonomy Mapping

Maps project context to permission profiles per [[wiki:human-in-the-loop-patterns]]:

| Context | Autonomy | Read ops | Write ops | Destructive ops | External actions |
|---------|----------|----------|-----------|----------------|-----------------|
| Development | High | Auto-approve | Auto-approve non-destructive | Confirm before executing | Confirm before executing |
| Review | Moderate | Auto-approve | Confirm writes to shared files | Block without explicit approval | Block without explicit approval |
| Production | Low | Auto-approve | Confirm all writes | Block — require explicit user instruction | Block — require explicit user instruction |

Configuration: Set via `allowedTools` in project-level `.claude/settings.json` and hook `PreToolUse` matchers. No global default — each project defines its own stake level.

## Checks

| ID | Check | Pass condition | Severity if fail |
|---|---|---|---|
| H6.i | Security rules exist | `~/.claude/rules/common/security.md` exists and contains `## Agent Safety` section | HIGH |
| H6.ii | Escalation rule present | `~/.claude/rules/dev-wiki-hooks.md` contains 3-attempt escalation pattern (or project equivalent) | HIGH |
| H6.iii | Scope boundary hook | At least one hook enforces scope boundaries (Glob `~/.claude/hooks/*scope*` or grep settings.json for scope-related PreToolUse) | MEDIUM |
| H6.iv | Subagent tool restrictions | `~/.claude/agents/*.md` files contain `tools:` field in frontmatter (spot-check 3 random agents) | MEDIUM |

## Inspection Logic

For each check:

1. **H6.i:** `[ -f ~/.claude/rules/common/security.md ]` then `grep -c "Agent Safety" ~/.claude/rules/common/security.md`. If file missing → `[HIGH] H6.i: security.md not found`. If no Agent Safety section → `[HIGH] H6.i: security.md missing Agent Safety section — run Phase 64 T2 or add manually`.
2. **H6.ii:** `grep -c "3 failed attempts" ~/.claude/rules/dev-wiki-hooks.md 2>/dev/null || grep -c "escalat" $ROOT/.claude/rules/*.md 2>/dev/null`. If 0 → `[HIGH] H6.ii: no escalation rule found in rules`.
3. **H6.iii:** Check `~/.claude/settings.json` for hook entries matching `scope` in command or path. Check `~/.claude/hooks/` for scope-related scripts. If neither found → `[MEDIUM] H6.iii: no scope-boundary hook detected`.
4. **H6.iv:** Pick 3 agent files from `~/.claude/agents/*.md`. For each, parse frontmatter for `tools:` field. If any lack it → `[MEDIUM] H6.iv: <agent>.md missing tools: field in frontmatter`.
