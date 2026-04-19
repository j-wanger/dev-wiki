# H2: settings.json + Hook-Script Coherence

trigger: read this file when `/dev-harness` is invoked with no argument or with `H2`. Self-describing per the Phase 17 companion convention — check definitions live here, not in SKILL.md.

## Scope

Audits `~/.claude/settings.json` (global) and `$ROOT/.claude/settings*.json` (project, if present) for schema validity, hook-script existence + executability, and behavioral-content drift back into structured config. Implements playbook invariant #5 (settings are structured, rules are behavioral). Does NOT inspect `~/.claude/agents/` (owned by H4) or `~/.claude/rules/` (owned by H3).

## Checks

| ID | Check | Pass condition | Severity if fail |
|---|---|---|---|
| H2.i   | json parses             | `jq . <file>` exits 0                                                              | HIGH  |
| H2.ii  | known top-level keys    | every top-level key is in whitelist {`hooks`, `allowedTools`, `mcpServers`, `enabledPlugins`, `extraKnownMarketplaces`, `env`, `model`, `effortLevel`, `output-styles`} | MEDIUM (WARN) |
| H2.iii | hook commands resolve   | every `hooks.*.*.hooks[].command` script path exists on disk                       | HIGH  |
| H2.iv  | hook scripts executable | every resolved hook script has `+x` per `[ -x <path> ]`                            | HIGH  |
| H2.v   | no behavioral drift     | no `description`/`prompt`/long-prose values inside `hooks.*` (rules territory)     | MEDIUM |
| H2.vi  | mcpServers schema       | if `mcpServers` key present, every entry has `command` (local) OR `url` (remote)   | HIGH  |
| H2.vii | hook event names valid  | every `hooks.<EVENT>` key is in {`PreToolUse`,`PostToolUse`,`SessionStart`,`Stop`,`SubagentStop`,`UserPromptSubmit`,`PreCompact`,`Notification`} | MEDIUM |

Project `settings.local.json` runs the same checks; if absent, skip silently (project settings are optional).

## Inspection Logic

For each target file (`~/.claude/settings.json`, then `$ROOT/.claude/settings*.json` glob if present):

1. **H2.i:** `jq . <file> >/dev/null 2>&1`. If non-zero: emit `[HIGH] H2.i <file>: invalid JSON` and skip remaining checks for this file (downstream checks need parsed structure).
2. **H2.ii:** `jq -r 'keys[]' <file>`. For each key, if not in whitelist: `[MEDIUM] H2.ii <file>: unknown top-level key '<key>' (typo or new schema?)`.
3. **H2.iii + H2.iv:** `jq -r '.hooks // {} | to_entries[].value[].hooks[].command' <file>` then strip leading `bash ` prefix. For each path, expand `~` to `$HOME`. `[ -f "$PATH" ] || emit [HIGH] H2.iii <file>: hook script <path> missing`. Else `[ -x "$PATH" ] || emit [HIGH] H2.iv <file>: hook script <path> not executable`.
4. **H2.v:** `jq -r '.. | objects | select(.command? or .matcher?) | tostring' <file> | grep -cE '"prompt":|"description":|[A-Za-z]{200,}'`. Any match → `[MEDIUM] H2.v <file>: behavioral content (prompt/description/long-prose) inside hooks block — belongs in rules/, not settings.json`.
5. **H2.vi:** `jq -r '.mcpServers // {} | to_entries[] | "\(.key) \(.value.command // "") \(.value.url // "")"' <file>`. For each row, fail if both command and url empty: `[HIGH] H2.vi <file>: mcpServers.<name> missing both 'command' and 'url'`.
6. **H2.vii:** `jq -r '.hooks // {} | keys[]' <file>`. Each key not in valid-event set → `[MEDIUM] H2.vii <file>: unknown hook event '<event>'`.

If `<file>` does not exist, emit `H2: SKIP — <file> not present` (silent for project, since project settings are optional; HIGH for missing global settings).

## Report

If all checks pass for all target files, emit:
```
H2: PASS — settings.json + hook scripts coherent (7 checks × N files)
```

Otherwise emit per-finding lines per the SKILL.md output convention.
