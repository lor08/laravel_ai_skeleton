#!/usr/bin/env bash
# PostToolUse hook (SOFT WARN): warn when method has > 4 parameters.
# Hint refactoring.guru: Long Parameter List → Introduce Parameter Object (DTO).

set -euo pipefail

THRESHOLD=4

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
        # Accumulate multi-line signatures into one
        if (collecting) {
            buf = buf " " $0
            if (index($0, ")") > 0) {
                collecting = 0
                process_signature(buf, signature_line)
                buf = ""
            }
            next
        }
        if (match($0, /function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(/)) {
            buf = $0
            signature_line = NR
            if (index($0, ")") == 0) {
                collecting = 1
                next
            }
            process_signature(buf, signature_line)
            buf = ""
        }
    }
    function process_signature(line, ln,    paren_open, paren_close, args, name, comma_count, i, c, depth) {
        paren_open = index(line, "(")
        # Find matching close-paren accounting for nesting
        depth = 0; paren_close = 0
        for (i = paren_open; i <= length(line); i++) {
            c = substr(line, i, 1)
            if (c == "(") depth++
            if (c == ")") { depth--; if (depth == 0) { paren_close = i; break } }
        }
        if (paren_close == 0) return
        args = substr(line, paren_open + 1, paren_close - paren_open - 1)
        gsub(/[[:space:]]+/, " ", args)
        if (args ~ /^[[:space:]]*$/) return
        # Count commas at top level (not inside nested parens / brackets / generics)
        comma_count = 0; depth = 0
        for (i = 1; i <= length(args); i++) {
            c = substr(args, i, 1)
            if (c == "(" || c == "[" || c == "<") depth++
            if (c == ")" || c == "]" || c == ">") depth--
            if (c == "," && depth == 0) comma_count++
        }
        param_count = comma_count + 1
        if (param_count > threshold) {
            sub(/^.*function[[:space:]]+/, "", line)
            sub(/[[:space:]]*\(.*/, "", line)
            printf "  %s:%d  %s() has %d parameters (> %d) — consider DTO\n", file, ln, line, param_count, threshold
        }
    }
' "$file" >&2 || true

exit 0
