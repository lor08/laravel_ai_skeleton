#!/usr/bin/env bash
# PostToolUse hook: BLOCK if PHPDoc block contains description text (only types allowed).
# A "description" = a non-empty line inside /** ... */ that doesn't start with @ tag,
# isn't blank, and isn't /** or */.

set -euo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0

case "$file" in
    *.blade.php) exit 0 ;;
    */vendor/*) exit 0 ;;
    */node_modules/*) exit 0 ;;
    *.php) ;;
    *) exit 0 ;;
esac

[ -f "$file" ] || exit 0

# AWK: track if we are inside /** ... */ block; flag any line that is text (not @tag, not blank, not delimiter).
violations=$(awk '
    BEGIN { inblock = 0 }
    /\/\*\*/ { inblock = 1; next }
    /\*\// { inblock = 0; next }
    inblock {
        line = $0
        # strip leading "* " or "*"
        gsub(/^[[:space:]]*\*[[:space:]]?/, "", line)
        # blank?
        if (line ~ /^[[:space:]]*$/) next
        # tag?
        if (line ~ /^@/) next
        # tag with leading whitespace?
        if (line ~ /^[[:space:]]*@/) next
        # {@inheritDoc} alone?
        if (line ~ /^[[:space:]]*\{@inheritDoc\}[[:space:]]*$/) next
        # otherwise — это описание, нельзя
        printf "  line %d: %s\n", NR, $0
    }
' "$file")

if [ -n "$violations" ]; then
    {
        echo "❌ PHPDoc descriptions are forbidden in $file (only @-tags and types allowed)."
        echo "Allowed: @param, @return, @throws, @var, @template, {@inheritDoc}."
        echo ""
        echo "$violations"
    } >&2
    exit 2
fi

exit 0
