#!/usr/bin/env bash
# PostToolUse hook (SOFT WARN): warn when class body exceeds 300 lines.
# Hint refactoring.guru: Large Class → Extract Class.

set -euo pipefail

THRESHOLD=300

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0
case "$file" in
    *.php) ;;
    *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# Total lines (rough proxy for class length when one file = one class — Laravel convention)
total=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
[ -z "$total" ] && exit 0

if [ "$total" -gt "$THRESHOLD" ]; then
    echo "  ⚠ $file is $total lines (> $THRESHOLD). Consider Extract Class — see refactoring.guru/extract-class" >&2
fi

exit 0
