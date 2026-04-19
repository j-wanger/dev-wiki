# Module Article Synthesis Prompt

Subagent prompt template for creating per-directory module articles using Section P format. Read by dev-scan SKILL.md Step 6, Subagent B.

## Prompt

Create one module article per scanned directory in `<WIKI_PATH>/articles/modules/` (directory will be created on first Write).

The canonical template is in Section P of `~/.claude/skills/dev-wiki/dev-wiki-reference.md` (read only if ambiguity arises). Path-slugs use 64-character truncation per Section A.

### Slug Normalization

Strip trailing `/` from directory path, strip any file extension if the path includes a file component (see `~/.claude/skills/dev-wiki/dev-wiki-reference.md` §Recognized Extensions), THEN apply Section A's path-to-slug rules. The slug must NOT contain the source extension or trailing artifacts. Retaining them is a [[wiki:silent-false-pass-pattern-family]] instance (slug-extension-drift).

Worked example: `~/.claude/skills/dev-harness/` → `claude-skills-dev-harness` (correct) — NOT with trailing dash or `-dir` suffix.

See `file-prompt.md`'s §Slug Normalization section for the file-path analog; both share the no-extension-suffix invariant.

### Module Findings

<MODULE_FINDINGS>

### Hash Lookup

<HASH_LOOKUP>

### Per-Module Article

For each module, create: `<WIKI_PATH>/articles/modules/<module-path-slug>.md`

The `<module-path-slug>` is derived from the directory path using Section A path-to-slug rules (e.g., `src/auth/` -> `src-auth`).

Frontmatter:

```yaml
---
title: "<module-path>/"
aliases: []
category: modules
tags: [<auto-detected from language, framework>]
parents: [<parent-module-path-slug or empty for top-level>]
created: <TODAY>
updated: <TODAY>
source: scan
type: module
path: "<project-relative-directory-path>/"
files: [<path-slugs of contained file articles>]
external_deps: [<package names imported by any file in module>]
internal_deps: [<path-slugs of other modules this depends on>]
dependents: [<path-slugs of modules that depend on this>]
content_hash: "<composite-hash from Section Q>"
---
```

**Composite hash:** Sort child file hashes alphabetically by path, join with `\n` (no trailing newline), SHA-256, take first 16 hex chars. Use the hash lookup provided above.

Begin the article body with `# <module-path>/` (H1 heading with trailing slash) followed by a 1-2 sentence purpose description (no heading for purpose — it is the introductory paragraph). Then write these sections:

- **## Files** — `[[<path-slug>|<filename>]]` wiki-links with one-line purposes. Cap at 15 entries; add "...and N more" if over.
- **## Key Patterns** — Architectural or naming patterns detected. Examples: "barrel exports via index.ts", "one-class-per-file", "repository pattern". Omit the section entirely (including heading) if no distinctive patterns detected.
- **## Dependencies** — Split into Internal (`[[<path-slug>|<module-name>]]` wiki-links) and External (package names with roles). 
- **## Dependents** — `[[<path-slug>|<module-name>]]` wiki-links showing what depends on this module.

### Constraints

- Top-level modules: set `parents: []`
- Do NOT create module articles for directories deeper than 3 levels (Section P hierarchy rules)
- Do NOT use `Module: <name>` or other title formats — use exactly `# <module-path>/` with trailing slash
- Max 8 module articles total
- Max 60 lines per article (Section B budget)
- If scan findings lack dependency data for a module, write "Not determined in this scan"
- Do NOT create files outside `<WIKI_PATH>/articles/modules/`
- Do NOT modify source code
