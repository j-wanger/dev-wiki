# H5: MCP Config + Auth State

trigger: read this file when `/dev-harness` is invoked with no argument or with `H5`. Self-describing per the Phase 17 companion convention — check definitions live here, not in SKILL.md.

## Scope

Audits MCP server registrations across all known sources for schema validity, name uniqueness, command-path resolvability (local) / URL well-formedness (remote), and OAuth credential file presence. **Maps primarily to playbook invariant #5** (settings are structured config — `mcpServers` key is the surface). #4 adjacency: MCP servers, like skills/agents, default to global registration and project-scope is the exception. Static-only — never probes server health or validates token expiry (keeps audit offline).

## Sources Scanned

1. `~/.claude/settings.json` `.mcpServers` key (global)
2. `$ROOT/.mcp.json` (project-scope MCP, if present)
3. `~/.claude/plugins/marketplaces/**/.mcp.json` (plugin-bundled, only those whose plugin appears in `settings.json` `enabledPlugins`)

## Checks

| ID | Check | Pass condition | Severity if fail |
|---|---|---|---|
| H5.i   | source files parse        | every discovered MCP-config file parses as JSON                                    | HIGH  |
| H5.ii  | name uniqueness           | no MCP server name appears in 2+ sources at the same priority (project overrides global is OK; collision within scope is not) | HIGH  |
| H5.iii | local command resolves    | for each entry with `command:`, the executable resolves via `which <command>` or `[ -x <path> ]` | MEDIUM |
| H5.iv  | remote URL well-formed    | for each entry with `url:`, value matches `^https?://`                            | HIGH  |
| H5.v   | OAuth credentials present | for each entry whose plugin manifest declares `oauth: true`, expected credential file exists at `~/.claude/.credentials.json` or `~/.claude/oauth-cache/<server>.json` (presence only, NOT validity) | MEDIUM |
| H5.vi  | reserved namespaces       | no MCP server name starts with `mcp-` or matches reserved prefixes (`anthropic-`, `claude-`) unless from official source | MEDIUM |
| H5.vii | mcp_required expectation  | if `$ROOT/.dev-wiki/schema.md` declares `mcp_required: true` AND H5.i discovered 0 MCP servers, downgrade SKIP → MEDIUM (project intends MCP but registers none). Default: missing schema.md or flag absent/false = unchanged SKIP. | MEDIUM |

## Inspection Logic

1. **Discovery:** `JQ='jq -r ".mcpServers // {} | keys[]"'`. Collect names from `~/.claude/settings.json` (tag `global`), `$ROOT/.mcp.json` (tag `project`, if exists), and each enabled plugin's `.mcp.json` (tag `plugin:<name>`). Build name→source map. If no MCP servers found anywhere: jump to **H5.vii** (Step 8) for SKIP-vs-MEDIUM determination, then STOP.
2. **H5.i:** for each source file, `jq . <file> >/dev/null 2>&1` → fail emits `[HIGH] H5.i <file>: invalid JSON`.
3. **H5.ii:** `awk` over the name→source map; if a name appears 2+ times within the same priority tier (e.g., 2 plugins register the same name), emit `[HIGH] H5.ii <name>: collision across <source-list>`.
4. **H5.iii:** for each entry, `jq -r ".mcpServers.\"<name>\".command // empty"`; if non-empty, expand `~`/`$HOME`, then `command -v "<cmd>" >/dev/null || [ -x "$cmd" ] || emit "[MEDIUM] H5.iii <name>: command '<cmd>' not on PATH and not executable file"`.
5. **H5.iv:** `jq -r ".mcpServers.\"<name>\".url // empty"`; non-empty entries must `grep -qE "^https?://"` → fail emits `[HIGH] H5.iv <name>: url '<url>' missing http(s) scheme`.
6. **H5.v:** for plugin-bundled entries, read sibling plugin manifest for `oauth` flag if present. If `true`: `[ -f "$HOME/.claude/.credentials.json" ] || [ -f "$HOME/.claude/oauth-cache/<name>.json" ] || emit "[MEDIUM] H5.v <name>: OAuth-required server has no credential file (expected $HOME/.claude/.credentials.json or $HOME/.claude/oauth-cache/<name>.json)"`. Use `$HOME` not `~` since `~` does not expand inside double-quoted bracket tests.
7. **H5.vi:** for each name not from `claude-plugins-official` marketplace, `case "$name" in mcp-*|anthropic-*|claude-*) emit "[MEDIUM] H5.vi <name>: uses reserved name prefix without official-source provenance" ;; esac`.
8. **H5.vii (SKIP-vs-MEDIUM gate):** invoked from Step 1 when 0 MCP servers found. Read `$ROOT/.dev-wiki/schema.md` if it exists; check for declared expectation. Use `"$HOME"` not `~` in any quoted bracket test (Phase 19b H5.v bug class). Logic:
   ```
   SCHEMA="$ROOT/.dev-wiki/schema.md"
   if [ -f "$SCHEMA" ] && grep -qE "^mcp_required:[[:space:]]*true[[:space:]]*$" "$SCHEMA"; then
     emit "[MEDIUM] H5.vii: project declares mcp_required: true in $SCHEMA but 0 MCP servers registered (settings.json + .mcp.json + enabled plugin manifests all empty)"
   else
     emit "H5: SKIP — no MCP servers registered (mcp_required not declared)"
   fi
   ```
   Null-handling: missing `$ROOT/.dev-wiki/schema.md` OR `mcp_required` field absent OR field set to `false` → SKIP unchanged (default = no expectation). Only literal `mcp_required: true` (anchored `^…$`) triggers MEDIUM — guards against partial matches inside comments or other fields.

## Report

If all checks pass:
```
H5: PASS — N MCP servers across M sources coherent (7 checks)
```

Otherwise emit per-finding lines per the SKILL.md output convention.
