# dev-debrief — Active Knowledge Transition Logic

Companion to `SKILL.md` Step 12a. Handle `.claude/rules/active-knowledge.md` based on phase state. Read `~/.claude/skills/dev-wiki/dev-wiki-reference.md` Section L for the specification.

## If phase changed this session (phase transitioned to a new phase, or phase marked completed)

1. **Carry forward all entries** (keep all, let decay prune). Read `.claude/rules/active-knowledge.md`. Convert every distilled proposition to a working-knowledge entry — no semantic classification needed.
   - Example (domain rule): `"- Fan-out topology: reviewers run in parallel"` → `- [uses: 1] Fan-out topology: reviewers run in parallel with disjoint scopes` / `source: [[wiki:subagent-delegation-patterns]] | activated: 2026-04-14 | last_decay: 2026-04-14`
   - Example (API convention): `"- Dedup by source slug before appending"` → `- [uses: 1] Dedup by source slug before appending to working-knowledge` / `source: [[decision:knowledge-persistence-strategy]] | activated: 2026-04-14 | last_decay: 2026-04-14`
2. **Write to working-knowledge.md** using Section M format. If the file doesn't exist, create it with the Section M header. Dedup against existing entries by source slug (increment `uses` if duplicate). Apply LRU eviction if >100 entries.
3. Delete `.claude/rules/active-knowledge.md` (`rm -f`).
4. Report: "Active knowledge cleared. N facts carried forward to working knowledge."

## If same phase (no phase transition)

1. Check if `.claude/rules/active-knowledge.md` exists. If not, skip.
2. Read the file. Parse each source section's `from:` and `retrieved:` fields.
3. For each `from: [[wiki:<slug>]]` entry, read the source article at `$ROOT/wiki/articles/**/<slug>.md` and extract its `updated:` frontmatter date.
4. For each `from: [[decision:<slug>]]` entry, read the source at `$WIKI/articles/decisions/<slug>.md` and extract its `updated:` date.
5. Compare: if source `updated:` > entry `retrieved:`, **auto-refresh**: re-read the source article, re-distill 2-5 propositions using Section L evaluation criteria, update `retrieved:` to today. Write updated active-knowledge.md (respect 30-line target, 40-line cap).
6. Report refreshed entries: `"Auto-refreshed active knowledge from [[slug]] (source updated YYYY-MM-DD)."`

## Skip condition

If no knowledge wiki and no active-knowledge.md file, skip entirely.
