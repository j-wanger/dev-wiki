# H3: Rules-Orphan + Dynamic-Rules Drift

trigger: read this file when `/dev-harness` is invoked with no argument or with `H3`. Self-describing per the Phase 17 companion convention — check definitions live here, not in SKILL.md.

## Scope

Audits `~/.claude/rules/**` for orphaned modules (not imported anywhere), undocumented siblings, dynamic-rules drift (project-only files leaking into global), and project-content leak in global rules. Implements playbook invariants #1 (global generalizable) and the "dynamic rules are project-scoped" corollary.

**Explicitly EXCLUDES `~/.claude/agents/`** — that surface is owned by H4 (subagent coherence). H3 sees agents/ only via H3.iv project-name string scan if rules/ files mention them.

## Checks

| ID | Check | Pass condition | Severity if fail |
|---|---|---|---|
| H3.i   | common/* imports resolve  | every `~/.claude/rules/common/*.md` is referenced from `~/.claude/CLAUDE.md`        | HIGH  |
| H3.ii  | non-common docs (section-anchored) | every non-common `~/.claude/rules/*.md` is documented inside the `## Sibling Files` section of `common/README.md` OR imported elsewhere. Section-anchored: a mention OUTSIDE `## Sibling Files` is silent drift (HIGH). Section-absent-with-content = HIGH; section-absent-no-content = SKIP (R3). | HIGH |
| H3.iii | no global dynamic rules   | none of `active-phase.md`, `active-knowledge.md`, `working-knowledge.md` exists at `~/.claude/rules/` (project-scope-only invariant per Phase 18a finding D1; `.bak.*` backups exempted) | HIGH  |
| H3.iv  | no project-content leak   | no project-name strings (e.g., `agentic-engineering`, `database`) in `~/.claude/rules/common/*.md` content (generalizable invariant #1) | HIGH |
| H3.v   | overlay subdirs (section-anchored) | if `~/.claude/rules/typescript/` (or any language/overlay subdir) exists, it must be referenced inside `## Sibling Files` of `common/README.md`. Same severity rules as H3.ii (R3 distinction). | HIGH |

## Inspection Logic

1. **H3.i:** `for f in ~/.claude/rules/common/*.md; do grep -qF "common/$(basename $f)" ~/.claude/CLAUDE.md || emit "[HIGH] H3.i $f: not imported by ~/.claude/CLAUDE.md"; done`. If `~/.claude/CLAUDE.md` missing: `[HIGH] H3.i: cannot verify (CLAUDE.md missing — see H1.i)` and skip remaining H3.i.
2. **H3.ii (section-anchored):** Extract the `## Sibling Files` content from `common/README.md` using a state-flag awk (NOT range syntax — range `/start/,/end/` self-terminates because `## Sibling Files` matches `^## [A-Z]`; state-flag handles EOF and back-to-back headings correctly): `SECTION=$(awk '/^## Sibling Files$/{flag=1; next} /^## [A-Z]/{flag=0} flag' "$HOME/.claude/rules/common/README.md" 2>/dev/null)`. Then: `SIBLINGS=$(ls "$HOME/.claude/rules"/*.md 2>/dev/null)`. If SIBLINGS empty AND SECTION empty: SKIP (nothing to document — R3). If SIBLINGS non-empty AND SECTION empty: emit `[HIGH] H3.ii: common/README.md missing required ## Sibling Files section (N sibling files exist)`. Otherwise for each sibling: `bn=$(basename "$f"); echo "$SECTION" | grep -qF "$bn" || grep -rqF "rules/$bn" "$HOME/.claude"/{CLAUDE.md,skills,agents} 2>/dev/null || emit "[HIGH] H3.ii $f: not documented inside ## Sibling Files section of common/README.md (drift — file may be mentioned elsewhere in README but section-anchor required)"`.
3. **H3.iii:** `for n in active-phase active-knowledge working-knowledge; do [ -f "$HOME/.claude/rules/$n.md" ] && emit "[HIGH] H3.iii ~/.claude/rules/$n.md: dynamic-rules file exists at GLOBAL scope (must be project-scope only per playbook invariant #1 corollary)"; done`. `.bak.*` backups exempted (regex `.bak.[0-9]{4}-`).
4. **H3.iv:** `grep -rE "agentic-engineering|/Users/[a-z]+/[a-z]+/" ~/.claude/rules/common/ 2>/dev/null | grep -v "^Binary" | head -5 | while read line; do emit "[HIGH] H3.iv: project-specific string in common/: $line"; done`. README references to project paths (in Sibling Files context) acceptable; flag content-body matches.
5. **H3.v (section-anchored):** Reuse SECTION from H3.ii (state-flag awk extraction). Glob overlay subdirs: `OVERLAYS=$(ls -d "$HOME/.claude/rules"/*/ 2>/dev/null | xargs -n1 basename | grep -vE '^common$')`. If OVERLAYS empty AND SECTION empty: SKIP (nothing to document — R3). If OVERLAYS non-empty AND SECTION empty: emit `[HIGH] H3.v: common/README.md missing ## Sibling Files section (overlay subdirs exist: $OVERLAYS)`. Otherwise for each overlay: `echo "$SECTION" | grep -qF "$bn/" || emit "[HIGH] H3.v $bn/: overlay subdir not referenced inside ## Sibling Files section of common/README.md"`.

If `~/.claude/rules/` does not exist, emit `[HIGH] H3: ~/.claude/rules/ missing entirely` and STOP.

## Report

If all checks pass:
```
H3: PASS — rules/ tree coherent (5 checks)
```

Otherwise emit per-finding lines per the SKILL.md output convention.
