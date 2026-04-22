# Post-Session Processing

Conditional processing for breadcrumbs (Phase 1) and stale queue (Phase 2). Read by dev-context SKILL.md only when skip conditions are false.

---

## Phase 1: Breadcrumb Processing

`WIKI_PATH` is already set by SKILL.md Pre-checks before this companion is read.

### Process Breadcrumbs from Prior Session

Check for breadcrumb files in `WIKI_PATH`. Process in this priority order:

#### Case A: `.session-end` exists

A prior session ended without running `/dev-debrief`.

1. Read `.session-end` for session-end metadata (timestamp, pending_commit status, session_buffer status, recent commits, uncommitted files).
2. If `debriefed: yes` is present, delete `.session-end` and continue to Phase 3 (prior session already debriefed).
3. If `debriefed: no` (or absent) AND `.session-buffer` exists: read `.session-buffer`, create a mechanical journal entry (see Journal Entry Format below), write to `WIKI_PATH/articles/journal/YYYY-MM-DD-<slug>.md`, update `_CURRENT_STATE.md` (Session Journal — keep last 5; Key Artifacts if meaningful changes), append to `log.md`, update `index.md`.
4. Delete all breadcrumb files: `.session-end`, `.pending-commit`, `.session-buffer`.
5. Note to user: "Previous session ended without debrief. I've created a basic journal entry from commit data."

#### Case B: `.pending-commit` exists (but no `.session-end`)

A commit was recorded but the session continued (or crashed without the Stop hook firing).

1. Read `.pending-commit` for the latest commit data.
2. Check `WIKI_PATH/tasks.md` -- if any open task matches the commit message or committed files, mark it `[x]`.
3. Delete `.pending-commit`.

#### Case C: No breadcrumbs

Nothing to process. Continue to Phase 3.

### Mechanical Journal Entry Format

Read Section J (mechanical journal template) and Section A (slugification) from dev-wiki/dev-wiki-reference.md. Mechanical journals are factual (data-only, 20-40 lines).

---

## Phase 2: Incremental Refresh (Step 2.5)

### Step 2.5: Process Stale Queue

<!-- SSOT: stale-queue-spec.md is authoritative for protocol details. This is a summary for inline reference. -->
If `WIKI_PATH/.stale-queue` exists and is non-empty, process changed files per dev-wiki/stale-queue-spec.md:

1. Read all paths, deduplicate, validate each matches `[a-zA-Z0-9_./-]+` (discard invalid with warning)
2. Process first **10 entries** (FIFO — oldest first; cap prevents slow startup)
3. For each path:
   - File exists: `shasum -a 256 <file> | cut -c1-16`, compare to article's `content_hash` in `WIKI_PATH/articles/files/<path-slug>.md`. If mismatch: update frontmatter `content_hash`. Only regenerate full article content if exports/imports changed (grep for export/import statements and diff against article).
   - File deleted: remove file article, update parent module article's `files` list
   - No article exists: create minimal file article (frontmatter only — path, content_hash from shasum, exports/imports from static analysis). Apply exclusion rules from `dependency-registration-spec.md` — skip excluded file types.
   - Processing fails: keep entry in queue for next session
4. Recompute composite hash for affected module articles (Section Q algorithm)
5. Remove **only successfully processed** entries from `.stale-queue`
6. If entries remain: keep for next session
7. **Soft warning** at 100+ entries: `"Stale queue has N entries. Consider /dev-scan."`
8. Report: `"[dev-wiki] Incremental refresh: N updated, M removed, K skipped."`

If `.stale-queue` does not exist or is empty: skip silently.
