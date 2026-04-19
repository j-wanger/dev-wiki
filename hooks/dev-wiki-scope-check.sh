#!/bin/bash
# dev-wiki-scope-check.sh (PreToolUse for Write|Edit)
# Warns when writing code without open tasks in the dev wiki.
# Reads stdin JSON but does not need to parse it for this check.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

if [ -d "$ROOT/.dev-wiki" ] && [ -f "$ROOT/.dev-wiki/tasks.md" ]; then
  OPEN=$(grep -c '^- \[ \]' "$ROOT/.dev-wiki/tasks.md" 2>/dev/null || echo 0)
  if [ "$OPEN" -eq 0 ]; then
    echo '[dev-wiki:scope-check] WARNING: No open tasks in tasks.md. Implementing without a plan?'
  fi
fi

exit 0
