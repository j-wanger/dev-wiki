# working-knowledge-spec.md

Specification for `.claude/rules/working-knowledge.md` — usage-tracked knowledge activation file. Consumed by `wiki-query` (activate, increment), `dev-debrief` (carry-forward), `dev-plan` (seeding), `dev-context` (read-only).

**Location:** `.claude/rules/working-knowledge.md`
**Ownership:** Shared. Primary: `/wiki-query` (activate + increment). Secondary: `/dev-debrief` (carry-forward), `/dev-plan` (seeding). `/dev-context` reads only.
**Lifecycle:** Added by query/debrief/plan → usage incremented on reference → manually pruned at cap.

### Template

```markdown
# Working Knowledge
- [uses: N] <distilled proposition>
  source: [[wiki:<slug>]] | activated: YYYY-MM-DD
```

### Entry Format

Each entry is exactly 2 lines:
1. `- [uses: N] <proposition>` — fact with usage counter
2. `  source: [[wiki:<slug>]] | activated: YYYY-MM-DD` — indented metadata

Sorted by usage count descending. Ties broken by most recent `activated:` date.

### Size Budget

Max 100 entries, 210-line hard cap (~800 tokens).

### Activation Criteria

After `/wiki-query` generates a substantive answer, offer activation if ALL of:
1. Answer is >3 sentences
2. Answer draws from 2+ wiki articles
3. Facts would be useful beyond this single question

Per fact: must pass at least 1 of 2 filters (multi-turn OR non-obvious). Max 3-5 propositions per activation event.

### Deduplication

Before inserting, check if an entry with the same `source:` slug exists. If so, increment `uses` instead of creating a duplicate.

### Pruning

Manual pruning at 100-entry cap. When adding entries would exceed 100, remove lowest-count entries (ties: oldest `activated:` date) until at 100. No automatic decay — usage counts persist until manually pruned.

### Usage Count Increment

When `/wiki-query` generates an answer and working-knowledge.md exists:
1. Scan entries for facts referenced in the answer (semantic match)
2. Increment `[uses: N]` → `[uses: N+1]` for each matched entry
3. Re-sort by usage count descending

### Lifecycle Events

| Event | Action | Skill |
|-------|--------|-------|
| Query answer + user confirms | Add new entries, prune if >100 | `/wiki-query` |
| Query answer (existing match) | Increment usage counts, re-sort | `/wiki-query` |
| Session start | Load + count entries | `/dev context` |
| Phase change | Carry forward cross-cutting facts from active-knowledge | `/dev debrief` |

### Partitioning Convention

Not all knowledge belongs here. Three tiers:

**Tier 1: Meta-process patterns** → working-knowledge.md. Cross-project reusable knowledge about HOW to do work.

**Tier 2: Project-specific structure** → `_ARCHITECTURE.md` + code articles. NOT in working-knowledge.

**Tier 3: Cross-phase non-obvious project facts** → working-knowledge.md. Multi-module, non-derivable-from-single-file facts only.

**Decision heuristic:** Can I find this by reading one file? → Don't store. Does `_ARCHITECTURE.md` capture it? → Don't duplicate. Cross-project reusable? → Tier 1. Project-specific, multi-module, non-obvious? → Tier 3.

**Cross-reference:** See `active-knowledge-spec.md` for phase-scoped knowledge with different lifecycle.
