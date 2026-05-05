#!/usr/bin/env bash
# PostToolUse hook (SOFT WARN): warn about magic numbers (literals not in {0, 1, -1, 2, 100, 1000})
# Hint refactoring.guru: Replace Magic Number with Symbolic Constant.

set -euo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0
case "$file" in
    *.php) ;;
    *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# Skip migrations (string lengths like 32, 255 are conventional)
case "$file" in
    */database/migrations/*) exit 0 ;;
esac

# Numbers we allow without warning
WHITELIST="^(0|1|-1|2|10|100|1000)$"

# Find numeric literals not preceded by a name char (so not a variable/version) and not in const definitions
suspicious=$(grep -nE '\b[0-9]{2,}\b' "$file" \
    | grep -vE 'const\s+[A-Z_]+\s*=' \
    | grep -vE '@phpstan|@psalm|@var|@param|@return' \
    | grep -vE 'http[s]?://[^[:space:]]+[0-9]+' \
    || true)

if [ -n "$suspicious" ]; then
    output=""
    while IFS= read -r line; do
        nums=$(echo "$line" | grep -oE '\b[0-9]{2,}\b' | sort -u)
        for n in $nums; do
            if ! echo "$n" | grep -qE "$WHITELIST"; then
                output+="  $line"$'\n'
                break
            fi
        done
    done <<< "$suspicious"

    if [ -n "$output" ]; then
        {
            echo "  ⚠ Possible magic numbers in $file — consider Replace Magic Number with Symbolic Constant"
            printf '%s' "$output"
        } >&2
    fi
fi

exit 0
