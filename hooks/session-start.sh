#!/bin/bash
# session-start.sh (SessionStart)
# Checks dev-wiki and project-wiki state at session start,
# emitting context hints for Claude to act on.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# --- Dev Wiki checks ---
if [ -d "$ROOT/.dev-wiki" ] && [ -f ~/.claude/skills/dev-wiki/session-context.md ]; then
  cat ~/.claude/skills/dev-wiki/session-context.md 2>/dev/null
  # Augment with breadcrumb-specific status
  if [ -f "$ROOT/.dev-wiki/.session-end" ]; then
    echo '[dev-wiki] Previous session ended. Unprocessed state available.'
  elif [ -f "$ROOT/.dev-wiki/.pending-commit" ]; then
    echo '[dev-wiki] Unprocessed commit data from previous session.'
  fi
  echo '[dev-wiki] Run /dev-context to load project state.'
elif [ -d "$ROOT/.dev-wiki" ]; then
  # Fallback if session-context.md not installed
  echo '[dev-wiki] Project state available. Run /dev-context to load.'
fi

# --- Project Wiki checks ---
if [ -d "$ROOT/wiki" ] && [ -f ~/.claude/skills/project-wiki/session-context.md ]; then
  cat ~/.claude/skills/project-wiki/session-context.md 2>/dev/null
else
  echo '[project-wiki] No wiki found. If this project involves learnings, patterns, or domain knowledge worth preserving, consider running /wiki-init.'
fi

exit 0
