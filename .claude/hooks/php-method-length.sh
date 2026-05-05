#!/usr/bin/env bash
# PostToolUse hook (SOFT WARN): warn when method body exceeds 30 lines.
# Hint refactoring.guru: Long Method → Extract Method.

set -euo pipefail

THRESHOLD=30

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0
case "$file" in
    *.php) ;;
    *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

awk -v threshold="$THRESHOLD" -v file="$file" '
    /function\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(/ {
        method_start = NR
        method_name = $0
        gsub(/^.*function[[:space:]]+/, "", method_name)
        gsub(/[[:space:]]*\(.*/, "", method_name)
        depth = 0
        in_method = 1
        body_lines = 0
        next
    }
    in_method {
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)
            if (c == "{") depth++
            if (c == "}") {
                depth--
                if (depth == 0) {
                    if (body_lines > threshold) {
                        printf "  %s:%d  %s() body is %d lines (> %d)\n", file, method_start, method_name, body_lines, threshold
                    }
                    in_method = 0
                    body_lines = 0
                    next
                }
            }
        }
        if (depth >= 1) body_lines++
    }
' "$file" >&2 || true

exit 0
