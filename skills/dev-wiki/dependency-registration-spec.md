# Dependency Registration Spec

Per-task protocol. Run after VERIFY, before mark [x]. Maintains file articles incrementally for blast radius data.

---

## Skip Gate

Skip if: project <10 source files, task scope only excluded types, or no `.dev-wiki/articles/files/` directory.

## Protocol

For each file in the task's `scope:` that was **created or substantially modified** this task:

### 1. Extract Dependencies (language-aware)

| Language | Imports pattern | Exports pattern |
|----------|----------------|-----------------|
| Python | `import X`, `from X import Y` → resolve to project-relative path | Top-level `def`, `class`, `__all__` members |
| TypeScript | `import ... from 'X'`, `require('X')` → resolve relative paths | `export` declarations, `export default` |
| Go | `import (...)` blocks → resolve to module-relative paths | Capitalized top-level identifiers |
| Swift | `import X` (framework), internal file refs via module structure | `public`/`open` declarations |

Resolve to **project-relative paths** for local imports. Ignore external packages (those go in body only, not frontmatter `imports`).

### 1b. Extract Data Flow (best-effort heuristic)

| Language | data_reads patterns | data_writes patterns |
|----------|--------------------|--------------------|
| Python | `open(_, 'r')`, `pd.read_*`, `os.environ`/`os.getenv`, ORM `.query()`/`.filter()` | `open(_, 'w')`, `pd.to_*`, `.save()`, `.create()`, SQL INSERT/UPDATE |
| TypeScript | `fs.readFile*`, `fetch()` GET, `process.env`, DB `.find()`/`.select()` | `fs.writeFile*`, `fetch()` POST/PUT, DB `.insert()`/`.update()` |
| Go | `os.Open`, `os.ReadFile`, `os.Getenv`, SQL `Query`/`QueryRow` | `os.Create`, `os.WriteFile`, SQL `Exec`, `http.Post` |

Extract resource identifiers (file paths, table names, env var names) where inferrable. Emit `[]` when no patterns found. Markdown files always yield empty data fields.

### 2. Create or Update File Article

- **Article exists** (`articles/files/<path-slug>.md`): Update `content_hash`, `exports`, `imports`, `data_reads`, `data_writes` (per-field: heuristic fills only absent fields — manual entries are authoritative). Preserve `imported_by`, body content.
- **Article does not exist**: Create minimal article per `~/.claude/skills/dev-scan/file-prompt.md` template:
  - Frontmatter: path, content_hash (shasum first 16 hex), exports, imports, `imported_by: []`, `data_reads: []`, `data_writes: []`
  - Body: 1-2 sentence purpose + `## Exports` list. Omit Dependents/Key Logic (populated later).

### 3. Bidirectional Maintenance (critical)

For each path in this file's `imports`:
1. Check if target has a file article (`articles/files/<target-path-slug>.md`)
2. If yes: read its `imported_by` field. If this file's path is NOT listed, append it.
3. If no article exists for target: skip (target will self-register when its own task runs)

This ensures `imported_by` is always a superset of actual reverse dependencies.

### 4. Verify (quick sanity)

Confirm: file article exists, `imports` count matches source, `imported_by` on targets updated. Full-graph validation deferred to self-check Category 7.

## Exclusions

Do NOT register: test files (`*_test.*`, `test_*.*`, `*_spec.*`, `tests/**`), config (`*.json`, `*.yaml`, `*.toml`, `*.env`), generated (first 5 lines contain `// Code generated`, `# Generated`, `@generated`), binary/media (`.pyc`, `node_modules/`, `vendor/`), documentation (`*.md` unless project treats .md as source).

## Content Hash

`shasum -a 256 <file> | cut -c1-16`. If unchanged and no new imports/exports, skip update (no-op).
