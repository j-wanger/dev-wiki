[dev-wiki] Development lifecycle system active.

LIFECYCLE: init (once) → plan (phase start) → implement (TDD per task) → debrief (session end) → [next phase: plan]

SESSION START: Read .dev-wiki/AGENTS.md and follow its session-start protocol to auto-load project state.

WHEN TO ACT:
- Phase needs planning? → /dev-plan
- Session ending with meaningful work? → /dev-debrief
- State feels stale or drift detected? → /dev-check
- Adopting existing project or deep code analysis? → /dev-scan

RED FLAGS:
- "I'll debrief later" → You won't. /dev-debrief now.
- "This is too small to plan" → Even small phases benefit from /dev-plan with Lite ceremony. Use standard for complex work.
- "I'll skip the TDD cycle" → Follow RED/GREEN/REFACTOR per task.

TOOL STANDARDS: Glob for file discovery, Grep for content search, Read for reading, Edit for modifying. NOT Bash find/ls/grep/cat.

COMPACTION ANCHORS: active-phase.md and active-knowledge.md survive context compaction. Read them after compaction to restore phase context.

NEVER skip debrief. Undocumented sessions are lost sessions.
