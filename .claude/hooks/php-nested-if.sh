#!/usr/bin/env bash
# PostToolUse hook (SOFT WARN): warn when if-nesting depth > 2.
# Hint refactoring.guru: Replace Nested Conditional with Guard Clauses.

set -euo pipefail

THRESHOLD=2

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0
case "$file" in
    *.php) ;;
    *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

awk -v threshold="$THRESHOLD" -v file="$file" '
    {
        line = $0
        # Count opening "if (" or "} else if (" / "} elseif ("
        # Nesting depth approximated by leading whitespace + brace tracking — keep it simple: count net braces.
        for (i = 1; i <= length(line); i++) {
            c = substr(line, i, 1)
            if (c == "{") depth++
            if (c == "}") depth--
        }
        # Match "if (" but not as part of identifier
        if (match(line, /(^|[[:space:];}])if[[:space:]]*\(/)) {
            if_depth_here = depth
            if (if_depth_here > threshold) {
                printf "  %s:%d  if-nesting depth %d (> %d) — consider Guard Clauses\n", file, NR, if_depth_here, threshold
            }
        }
    }
' "$file" >&2 || true

exit 0
