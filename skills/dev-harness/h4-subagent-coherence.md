# H4: Subagent Coherence

trigger: read this file when `/dev-harness` is invoked with no argument or with `H4`. Self-describing per the Phase 17 companion convention — check definitions live here, not in SKILL.md.

## Scope

Audits `~/.claude/agents/*.md` (subagent definition files) for frontmatter coherence and trigger-clarity per [[wiki:subagent-authoring-patterns]]. **OWNS** this surface: file existence + frontmatter validation belong to H4. Project `.claude/agents/*.md` is checked the same way if present. Out-of-scope: subagent file content body (only frontmatter is validated); rules/ files (H3); skills/ (no current H-check).

## Checks

| ID | Check | Pass condition | Severity if fail |
|---|---|---|---|
| H4.i   | name field present     | every `agents/*.md` has `name:` field in frontmatter (line 2-10)                  | HIGH  |
| H4.ii  | name matches filename  | `name:` value equals filename minus `.md` extension                                | MEDIUM |
| H4.iii | description present    | `description:` field present and value is ≥10 characters                          | HIGH  |
| H4.iv  | trigger verb in description | `description` contains one of `Use when`, `MUST BE USED`, `PROACTIVELY` (per [[wiki:subagent-authoring-patterns]] trigger-verb taxonomy) | MEDIUM |
| H4.v   | tools field shape      | if `tools:` present, value is a non-empty array (`["Read","Grep",…]`) — never empty `[]`, never a bare string | MEDIUM |

## Inspection Logic

For each file in `~/.claude/agents/*.md` (and `$ROOT/.claude/agents/*.md` if present):

1. **H4.i:** `head -10 <file> | grep -E '^name:' | head -1`. If empty → `[HIGH] H4.i <file>: no 'name:' frontmatter field`. If file does not start with `---` (no frontmatter at all) → `[HIGH] H4.i <file>: missing frontmatter block`.
2. **H4.ii:** Extract `name:` value: `head -10 <file> | grep -E '^name:' | sed 's/^name: *//; s/ *$//'`. Compare to `basename "<file>" .md`. Mismatch → `[MEDIUM] H4.ii <file>: name '<value>' does not match filename`.
3. **H4.iii:** `head -10 <file> | grep -E '^description:' | sed 's/^description: *//' | head -1`. If empty or `< 10` chars → `[HIGH] H4.iii <file>: description missing or <10 chars`.
4. **H4.iv:** Take description value from H4.iii. `echo "$DESC" | grep -qE 'Use when|MUST BE USED|PROACTIVELY'`. If no match → `[MEDIUM] H4.iv <file>: description lacks trigger verb (Use when|MUST BE USED|PROACTIVELY) — see [[wiki:subagent-authoring-patterns]]`.
5. **H4.v:** `head -10 <file> | grep -E '^tools:' | head -1`. If absent: PASS (tools is optional). If present: value must match `\[.+\]` (non-empty array). Empty `[]` or bare string → `[MEDIUM] H4.v <file>: tools field malformed (must be non-empty array, e.g. ["Read","Grep"])`.

If `~/.claude/agents/` does not exist, emit `H4: SKIP — ~/.claude/agents/ not present` (not a HIGH; agents are optional infrastructure).

## Report

If all checks pass for all agent files:
```
H4: PASS — N subagents coherent (5 checks each)
```

Otherwise emit per-finding lines per the SKILL.md output convention.
