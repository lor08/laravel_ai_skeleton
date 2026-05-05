#!/usr/bin/env bash
# PostToolUse hook: BLOCK if PHP file uses global Laravel helpers.
# Helpers must be replaced with Facades (Lang::, View::, Config:: ...).

set -euo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0

case "$file" in
    *.blade.php) exit 0 ;;
    *.php) ;;
    *) exit 0 ;;
esac

[ -f "$file" ] || exit 0

helpers="trans|view|redirect|app|config|abort|abort_if|abort_unless|auth|request|now|cache|session|back|response|route|asset|url|env|dispatch|event|logger|optional|tap|collect|info|action|old|csrf_token|csrf_field|method_field|data_get|data_set|public_path|storage_path|base_path|app_path|database_path|resource_path|config_path"

matches=$(grep -nP "(?<![a-zA-Z0-9_>:\\\\])($helpers)\s*\(" "$file" || true)

if [ -n "$matches" ]; then
    {
        echo "❌ Forbidden Laravel helpers in $file — replace with Facades (Illuminate\\Support\\Facades\\View::, Lang::, Config:: ...):"
        echo "$matches"
    } >&2
    exit 2
fi

exit 0
