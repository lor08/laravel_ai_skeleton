#!/usr/bin/env bash
# Stop hook: warn (without blocking) if session touched code that suggests
# project docs (.ai/project/, .ai/adr/) might need updating.
#
# Triggers:
#   - Edits to app/Modules/**, app/Services/**, app/Repositories/**
#   - Edits to database/migrations/**
#   - Edits to composer.json (deps changed)
#   - Edits to config/**
#
# If those happened AND nothing in .ai/project/** or .ai/adr/** was edited:
# emit a reminder to stderr.

set -euo pipefail

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# If no transcript provided, exit silently (different harness, or first turn)
[ -z "$transcript_path" ] && exit 0
[ -f "$transcript_path" ] || exit 0

# Extract all Edit/Write/MultiEdit tool_input.file_path from transcript
edits=$(jq -r '
    select(.type == "tool_use") |
    select(.name == "Edit" or .name == "Write" or .name == "MultiEdit") |
    .input.file_path // empty
' "$transcript_path" 2>/dev/null || true)

[ -z "$edits" ] && exit 0

# Track which trigger paths were touched
domain_touched=0
migration_touched=0
deps_touched=0
config_touched=0
docs_touched=0

while IFS= read -r path; do
    [ -z "$path" ] && continue
    case "$path" in
        */app/Modules/*) domain_touched=1 ;;
        */app/Services/*) domain_touched=1 ;;
        */app/Repositories/*) domain_touched=1 ;;
        */app/DTO/*) domain_touched=1 ;;
        */app/Enums/*) domain_touched=1 ;;
        */database/migrations/*) migration_touched=1 ;;
        */composer.json) deps_touched=1 ;;
        */config/*) config_touched=1 ;;
        */.ai/project/*) docs_touched=1 ;;
        */.ai/adr/*) docs_touched=1 ;;
    esac
done <<< "$edits"

# If any trigger was touched but no docs — remind
if [ "$docs_touched" -eq 0 ]; then
    msg=""

    if [ "$domain_touched" -eq 1 ]; then
        msg+="• Domain code changed (Modules / Services / Repositories / DTO / Enums) → consider updating .ai/project/glossary.md or .ai/project/domain/{module}.md"$'\n'
    fi
    if [ "$migration_touched" -eq 1 ]; then
        msg+="• Migrations changed → consider updating .ai/project/data-model.md"$'\n'
    fi
    if [ "$deps_touched" -eq 1 ]; then
        msg+="• composer.json changed → consider updating .ai/project/integrations.md or adding ADR"$'\n'
    fi
    if [ "$config_touched" -eq 1 ]; then
        msg+="• config/ changed → consider updating .ai/project/operations.md"$'\n'
    fi

    if [ -n "$msg" ]; then
        {
            echo "📝 Documentation reminder (.ai/rules/docs.md):"
            printf '%s' "$msg"
            echo "  Run /update-docs or update .ai/project/ before closing the task."
        } >&2
    fi
fi

# Stop hooks must always exit 0 unless they want to block — never block
exit 0
