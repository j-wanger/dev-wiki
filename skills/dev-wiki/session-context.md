[dev-wiki] Development lifecycle system active.

LIFECYCLE: init (once) → context (session start) → plan (knowledge check → design → approach review → plan review → approve) → implement (TDD per task) → review (optional gate) → debrief (session end) → retro (every 5-10 phases)

WHEN TO ACT:
- Session start? → /dev-context
- Phase needs planning? → /dev-plan
- Task blocked or approach wrong? → /dev-adjust
- Session ending with meaningful work? → /dev-debrief
- State feels stale or drift detected? → /dev-check
- All phase tasks done? → /dev-review
- Adopting existing project or deep code analysis? → /dev-scan
- Process feels repetitive or phase count % 5 == 0? → /dev-retro

RED FLAGS:
- "I'll debrief later" → You won't. /dev-debrief now.
- "This is too small to plan" → Every phase goes through /dev-plan.
- "I know the codebase" → /dev-context loads what you actually know.
- "I'll skip the TDD cycle" → Follow RED/GREEN/REFACTOR per task.
- "The plan looks fine" → /dev-plan reviews plans automatically (Steps 2.5, 7.5). Gaps amplify during implementation.

TOOL STANDARDS: Glob for file discovery, Grep for content search, Read for reading, Edit for modifying. NOT Bash find/ls/grep/cat.

COMPACTION ANCHORS: active-phase.md and active-knowledge.md survive context compaction. Read them after compaction to restore phase context.

NEVER skip debrief. Undocumented sessions are lost sessions.
