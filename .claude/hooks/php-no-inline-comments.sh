#!/usr/bin/env bash
# PostToolUse hook: BLOCK if PHP file contains inline comments (// ...).
# Allowed: phpstan/phpcs/psalm directive comments; @phpstan-*, @psalm-*.

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

# Match // ... but exclude:
#   - Inside string literals (best effort with grep — line-level)
#   - Allowed directives: @phpstan-*, @psalm-*, @phpcs:*, @phan-*, @internal, @noinspection, http://, https://
matches=$(grep -nP '^\s*//\s*(?!@phpstan-|@psalm-|@phpcs|@phan|@noinspection|@internal|http://|https://)' "$file" || true)

# Also catch trailing inline comments after code (excluding URLs)
trailing=$(grep -nP '[^:"'\'']\K\s+//\s+(?!@phpstan-|@psalm-|@phpcs|@phan|@noinspection|http://|https://)\S' "$file" || true)

combined=$(printf '%s\n%s' "$matches" "$trailing" | sed '/^$/d')

if [ -n "$combined" ]; then
    {
        echo "❌ Inline // comments are forbidden in $file"
        echo "Use Extract Method / Rename / PHPDoc-types instead."
        echo "Allowed: //@phpstan-*, //@psalm-*, //@phpcs:*, //@noinspection, URLs."
        echo ""
        echo "$combined"
    } >&2
    exit 2
fi

exit 0
