---
name: dev-harness
description: Use when auditing the agent harness. Runs 6 H-checks (CLAUDE.md, settings, rules, agents, MCP, safety) read-only. Do NOT use for phase review (use /dev-review) or wiki health (use /wiki-lint).
reads: [~/.claude/CLAUDE.md, $ROOT/CLAUDE.md, ~/.claude/settings.json, $ROOT/.claude/settings*.json, ~/.claude/rules/**/*.md, ~/.claude/agents/*.md, $ROOT/.mcp.json, $ROOT/.dev-wiki/schema.md, ~/.claude/skills/dev-harness/*.md]
writes: []
dispatches: [h1-claude-md-coherence, h2-settings-and-hooks, h3-rules-drift, h4-subagent-coherence, h5-mcp-and-auth, h6-safety-layer-audit (all conditional on argument or run-all default)]
tier: simple-orchestration
---

# dev-harness

Read-only diagnostic skill that audits the agent harness for drift and incoherence. Inspired by `/dev-check` (which audits dev-wiki integrity), but scoped to the cross-cutting harness layers — global and project CLAUDE.md, settings.json, rules modules, subagents, and hooks. See [[wiki:harness-composition-playbook]] for the design model under audit.

H-checks are self-describing companion files (Phase 17 pattern): each companion declares its own trigger condition + check logic, keeping this SKILL.md lean and extensible.

## H-Checks (current scope)

| Check | Companion | Domain |
|---|---|---|
| H1 | `h1-claude-md-coherence.md` | Global + project CLAUDE.md exists, size, imports resolve, no project-content-leak |
| H2 | `h2-settings-and-hooks.md` | settings.json parses + schema, hook-script paths resolve + executable, no behavioral drift, mcpServers schema, hook event names |
| H3 | `h3-rules-drift.md` | common/* imports resolve, non-common rules/*.md documented (section-anchored to `## Sibling Files`), no global dynamic rules, no project-content leak in common/, overlay subdirs documented (section-anchored) |
| H4 | `h4-subagent-coherence.md` | agents/*.md frontmatter coherence — name field, name=filename, description ≥10 chars, trigger verb, tools array shape |
| H5 | `h5-mcp-and-auth.md` | MCP server discovery (settings.json + .mcp.json + plugin manifests), name uniqueness, command/url validity, OAuth credential file presence, `mcp_required` opt-in |
| H6 | `h6-safety-layer-audit.md` | Safety layer coverage (5-layer inventory), failure mode severity classification, stake-level autonomy mapping, safety primitive verification |

---

## Pre-checks

1. **Discover scope.** Run `git rev-parse --show-toplevel 2>/dev/null || pwd` to find `$ROOT`. `$WIKI = $ROOT/.dev-wiki`. `$WIKI` may not exist (some projects have no dev-wiki) — proceed regardless.
2. **Determine check set.** If invoked with no arguments, run all available H-checks (H1-H6; see H-Checks table). If invoked with `H<N>` argument, run only that check. If `H<N>` companion missing, report "Check H<N> not yet implemented" and STOP.

---

## Step 1: Load Companion(s)

For each H-check in scope:

1. Read `~/.claude/skills/dev-harness/h<N>-*.md` companion file
2. Verify the companion has a `trigger:` line (self-describing convention) — if missing, warn and skip the companion
3. Inject companion contents into context for the next step

---

## Step 2: Execute Checks

Follow the inspection logic in each loaded companion. Each companion produces a list of findings shaped as:

```
[<SEVERITY>] <check-id>: <description>
  observed: <what was found>
  expected: <what should be true>
  fix: <recommended remediation>
```

Severity scale: CRITICAL (state inconsistency, data risk), HIGH (drift, missing required artifact), MEDIUM (style, optional improvement).

Aggregate findings across all loaded companions.

---

## Step 3: Report

Print a structured report:

```
## Harness Audit — <date>

Checks run: H1 [, H2, ...]
Aggregate: PASS | DRIFT DETECTED (N findings: X CRITICAL, Y HIGH, Z MEDIUM)

### H1: <check title>
  PASS | <findings list>

### H2: ...
```

If any CRITICAL findings: tell user "Run `/dev-adjust` or fix manually before proceeding to next phase work." If only MEDIUM/HIGH: report as informational.

This skill is read-only. It does NOT auto-fix. All remediation is up to the user (or a follow-up planning skill).

---

## Error Handling

| Error | Response |
|---|---|
| No companion files in dev-harness/ | "No H-check companions installed. Reinstall the dev-harness skill or restore companions from version control." STOP. |
| Companion missing `trigger:` line | Warn, skip companion. |
| Argument names a non-existent check | "Check H<N> not yet implemented." STOP. |

---

## Related

- `/dev-check` — sibling diagnostic for `.dev-wiki/` integrity (this skill's harness-layer counterpart)
- `/wiki-lint` — sibling diagnostic for knowledge-wiki structure
- [[wiki:harness-composition-playbook]] — design model under audit
- [[wiki:claude-md-interaction-contract]] — H1's behavioral spec source
