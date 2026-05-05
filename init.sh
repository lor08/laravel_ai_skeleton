#!/usr/bin/env bash
# init.sh — interactive setup for laravel_ai_skeleton.
# Replaces placeholders, prunes unused frontend stacks, sets git hooks, and prints next steps.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo
    echo -e "${BOLD}${BLUE}═══ $1 ═══${NC}"
}

ask() {
    local prompt="$1"
    local default="${2:-}"
    local answer
    if [ -n "$default" ]; then
        read -r -p "$(echo -e "${BOLD}$prompt${NC} [${default}]: ")" answer
        echo "${answer:-$default}"
    else
        read -r -p "$(echo -e "${BOLD}$prompt${NC}: ")" answer
        echo "$answer"
    fi
}

ask_yn() {
    local prompt="$1"
    local default="${2:-y}"
    local opts="[y/N]"
    [ "$default" = "y" ] && opts="[Y/n]"
    local answer
    read -r -p "$(echo -e "${BOLD}$prompt${NC} $opts ")" answer
    answer="${answer:-$default}"
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

ask_choice() {
    local prompt="$1"
    shift
    local opts=("$@")
    local i=1
    echo -e "${BOLD}$prompt${NC}"
    for opt in "${opts[@]}"; do
        echo "  $i) $opt"
        i=$((i+1))
    done
    local n
    read -r -p "Choose [1]: " n
    n="${n:-1}"
    echo "${opts[$((n-1))]}"
}

# ─── Greetings ──────────────────────────────────────────────────────────────

print_header "Laravel AI Skeleton — Initialization"
echo "This script will:"
echo "  • Replace placeholders in .ai/, .claude/, AGENTS.md, configs"
echo "  • Prune unused frontend stack rules"
echo "  • Set up git hooks"
echo "  • Optionally enable Rector / mutation testing / runbook"
echo
if ! ask_yn "Continue?" "y"; then
    echo "Aborted."
    exit 0
fi

# ─── Gather inputs ──────────────────────────────────────────────────────────

print_header "Project info"

PROJECT_NAME=$(ask "Project slug (kebab-case, used in composer name and DB)" "my-app")
PROJECT_NAMESPACE=$(ask "PHP namespace (e.g. 'App' for default Laravel)" "App")
PROJECT_DOMAIN=$(ask "Local domain (for .env)" "${PROJECT_NAME}.test")
TICKET_PREFIX=$(ask "Ticket prefix (uppercase, e.g. PROJ, JIRA-XX)" "PROJ")
MAIN_BRANCH=$(ask "Main branch name" "main")

print_header "Runtime"

USE_SAIL=y
if ask_yn "Use Laravel Sail (docker-compose wrapper)?" "y"; then
    RUN_CMD="./vendor/bin/sail bin"
    APP_CONTAINER="${PROJECT_NAME}-laravel.test-1"
else
    USE_SAIL=n
    APP_CONTAINER=$(ask "Docker container name" "${PROJECT_NAME}_app")
    RUN_CMD="docker exec $APP_CONTAINER"
fi

print_header "Database"

DB_DRIVER=$(ask_choice "Database driver" "mysql" "pgsql" "sqlite")

print_header "Frontend stack"

FRONTEND_STACK=$(ask_choice "Choose frontend stack" \
    "vue3-inertia (default — Vue 3 + TS + Inertia + Pinia)" \
    "react-inertia (React 19 + TS + Inertia)" \
    "livewire (Livewire 3 + Alpine + Blade)" \
    "blade (Blade-only, no JS bundler)" \
    "none (API-only backend)")

# Take the first word as a tag
FRONTEND_TAG=$(echo "$FRONTEND_STACK" | awk '{print $1}')

print_header "Optional features"

ENABLE_RECTOR=n
if ask_yn "Enable Rector (automated refactoring)?" "n"; then
    ENABLE_RECTOR=y
fi

ENABLE_MUTATION=n
if ask_yn "Enable mutation testing in CI (slow but powerful)?" "n"; then
    ENABLE_MUTATION=y
fi

ENABLE_RUNBOOK=y
if ! ask_yn "Keep .ai/project/runbook.md (production operations)?" "y"; then
    ENABLE_RUNBOOK=n
fi

ENABLE_BOOST=y
if ! ask_yn "Keep Laravel Boost MCP entry in .mcp.json?" "y"; then
    ENABLE_BOOST=n
fi

# ─── Confirmation ───────────────────────────────────────────────────────────

print_header "Summary"
cat <<EOF
  Project name:        $PROJECT_NAME
  Namespace:           $PROJECT_NAMESPACE
  Local domain:        $PROJECT_DOMAIN
  Ticket prefix:       $TICKET_PREFIX
  Main branch:         $MAIN_BRANCH
  Run command:         $RUN_CMD
  Container name:      $APP_CONTAINER
  Database driver:     $DB_DRIVER
  Frontend stack:      $FRONTEND_TAG
  Rector enabled:      $ENABLE_RECTOR
  Mutation testing:    $ENABLE_MUTATION
  Runbook kept:        $ENABLE_RUNBOOK
  Laravel Boost:       $ENABLE_BOOST
EOF
echo
if ! ask_yn "Apply?" "y"; then
    echo "Aborted."
    exit 0
fi

# ─── Apply substitutions ────────────────────────────────────────────────────

print_header "Replacing placeholders"

# Escape sed special chars in values
escape_for_sed() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

# Build escape forms
PN_E=$(escape_for_sed "$PROJECT_NAME")
PNS_E=$(escape_for_sed "$PROJECT_NAMESPACE")
TP_E=$(escape_for_sed "$TICKET_PREFIX")
MB_E=$(escape_for_sed "$MAIN_BRANCH")
RC_E=$(escape_for_sed "$RUN_CMD")
AC_E=$(escape_for_sed "$APP_CONTAINER")
PD_E=$(escape_for_sed "$PROJECT_DOMAIN")

# In composer.json, we need namespace with double-backslashes for JSON
PNS_JSON=$(printf '%s' "$PROJECT_NAMESPACE" | sed 's/\\/\\\\/g')
PNS_JSON_E=$(escape_for_sed "$PNS_JSON")

# Find target files
mapfile -t FILES < <(find . -type f \
    \( -name '*.md' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.neon' -o -name '*.php' -o -name '*.sh' -o -name '*.example' -o -name '*.editorconfig' -o -name '.env.example' \) \
    -not -path './vendor/*' \
    -not -path './node_modules/*' \
    -not -path './.git/*' \
    -not -path './.idea/*')

for f in "${FILES[@]}"; do
    [ -f "$f" ] || continue
    # composer.json gets namespace with JSON-escaped backslashes
    if [ "$f" = "./composer.json" ]; then
        sed -i \
            -e "s|<PROJECT-NAME>|${PN_E}|g" \
            -e "s|<PROJECT-NAMESPACE>|${PNS_JSON_E}|g" \
            -e "s|<TICKET-PREFIX>|${TP_E}|g" \
            -e "s|<MAIN-BRANCH>|${MB_E}|g" \
            -e "s|<RUN-CMD>|${RC_E}|g" \
            -e "s|<APP-CONTAINER>|${AC_E}|g" \
            -e "s|<PROJECT-DOMAIN>|${PD_E}|g" \
            "$f"
    else
        sed -i \
            -e "s|<PROJECT-NAME>|${PN_E}|g" \
            -e "s|<PROJECT-NAMESPACE>|${PNS_E}|g" \
            -e "s|<TICKET-PREFIX>|${TP_E}|g" \
            -e "s|<MAIN-BRANCH>|${MB_E}|g" \
            -e "s|<RUN-CMD>|${RC_E}|g" \
            -e "s|<APP-CONTAINER>|${AC_E}|g" \
            -e "s|<PROJECT-DOMAIN>|${PD_E}|g" \
            "$f"
    fi
done

echo -e "${GREEN}✔${NC} Placeholders replaced in ${#FILES[@]} files"

# ─── Prune frontend rules ────────────────────────────────────────────────────

print_header "Frontend"

if [ "$FRONTEND_TAG" != "vue3-inertia" ]; then
    echo -e "${YELLOW}You chose '$FRONTEND_TAG'.${NC}"
    echo "Default frontend rules in .ai/rules/frontend/ are written for Vue 3 + Inertia."
    echo "You will need to manually adapt:"
    echo "  • .ai/rules/frontend/code-style.md"
    echo "  • .ai/rules/frontend/architecture.md"
    echo "  • .ai/rules/frontend/testing.md"
    echo "  • .ai/templates/frontend/*"
    case "$FRONTEND_TAG" in
        livewire|blade)
            echo "  • Vitest / Vue Test Utils references should be removed"
            echo "  • Add Livewire component / Blade view templates"
            ;;
        react-inertia)
            echo "  • Replace .vue with .tsx, Pinia with Zustand or Context"
            ;;
        none)
            echo "  • You can delete .ai/rules/frontend/ and .ai/templates/frontend/ entirely"
            ;;
    esac
    echo
fi

# ─── DB driver: adjust .env.example ─────────────────────────────────────────

print_header "Database driver"

case "$DB_DRIVER" in
    pgsql)
        sed -i \
            -e 's|^DB_CONNECTION=mysql|DB_CONNECTION=pgsql|' \
            -e 's|^DB_HOST=mysql|DB_HOST=pgsql|' \
            -e 's|^DB_PORT=3306|DB_PORT=5432|' \
            .env.example
        echo -e "${GREEN}✔${NC} .env.example switched to PostgreSQL"
        ;;
    sqlite)
        sed -i \
            -e 's|^DB_CONNECTION=mysql|DB_CONNECTION=sqlite|' \
            -e 's|^DB_HOST=mysql|# DB_HOST=|' \
            -e 's|^DB_PORT=3306|# DB_PORT=|' \
            -e "s|^DB_DATABASE=$PN_E|DB_DATABASE=database/database.sqlite|" \
            -e 's|^DB_USERNAME=sail|# DB_USERNAME=|' \
            -e 's|^DB_PASSWORD=password|# DB_PASSWORD=|' \
            .env.example
        echo -e "${GREEN}✔${NC} .env.example switched to SQLite"
        ;;
    mysql|*)
        echo -e "${GREEN}✔${NC} .env.example kept for MySQL"
        ;;
esac

# Remove mysql MCP entry if not using mysql
if [ "$DB_DRIVER" != "mysql" ]; then
    if command -v jq >/dev/null 2>&1; then
        jq 'del(.mcpServers.mysql)' .mcp.json > .mcp.json.tmp && mv .mcp.json.tmp .mcp.json
        echo -e "${GREEN}✔${NC} Removed mysql MCP entry (driver is $DB_DRIVER)"
    else
        echo -e "${YELLOW}⚠${NC} jq not found — manually remove 'mysql' from .mcp.json if needed"
    fi
fi

# ─── Optional features ──────────────────────────────────────────────────────

print_header "Optional features"

if [ "$ENABLE_RECTOR" = "n" ]; then
    rm -f rector.php
    echo -e "${GREEN}✔${NC} Removed rector.php (Rector disabled)"
else
    echo -e "${GREEN}✔${NC} Rector enabled. Install with:"
    echo "    composer require --dev rector/rector driftingly/rector-laravel"
fi

if [ "$ENABLE_MUTATION" = "n" ]; then
    sed -i '/pestphp\/pest-plugin-mutate/d' composer.json 2>/dev/null || true
    echo -e "${GREEN}✔${NC} Mutation testing job stays commented in CI"
else
    if command -v jq >/dev/null 2>&1; then
        jq '.["require-dev"]["pestphp/pest-plugin-mutate"] = "^3.0"' composer.json > composer.json.tmp && mv composer.json.tmp composer.json
    fi
    sed -i 's|^  # mutation:|  mutation:|' .github/workflows/ci.yml
    sed -i 's|^  #   |    |' .github/workflows/ci.yml || true
    echo -e "${GREEN}✔${NC} Mutation testing enabled. Install with:"
    echo "    composer require --dev pestphp/pest-plugin-mutate"
fi

if [ "$ENABLE_RUNBOOK" = "n" ]; then
    rm -f .ai/project/runbook.md
    echo -e "${GREEN}✔${NC} Removed .ai/project/runbook.md"
fi

if [ "$ENABLE_BOOST" = "n" ]; then
    if command -v jq >/dev/null 2>&1; then
        jq 'del(.mcpServers["laravel-boost"])' .mcp.json > .mcp.json.tmp && mv .mcp.json.tmp .mcp.json
    fi
    sed -i '/laravel\/boost/d' composer.json 2>/dev/null || true
    rm -f .ai/adr/0004-laravel-boost-mcp.md
    echo -e "${GREEN}✔${NC} Removed Laravel Boost integration"
fi

# ─── Git hooks ──────────────────────────────────────────────────────────────

print_header "Git hooks"

if [ -d .git ]; then
    git config core.hooksPath .git-hooks
    echo -e "${GREEN}✔${NC} git core.hooksPath set to .git-hooks"
else
    echo -e "${YELLOW}⚠${NC} Not a git repo yet. After 'git init':"
    echo "    git config core.hooksPath .git-hooks"
fi

chmod +x .git-hooks/* .claude/hooks/*.sh init.sh 2>/dev/null || true

# ─── Done ───────────────────────────────────────────────────────────────────

print_header "Done"

echo -e "${GREEN}✔ Skeleton initialized for $PROJECT_NAME${NC}"
echo
echo "Next steps:"
echo "  ${BOLD}1.${NC} Initialize git (if not yet):"
echo "       git init && git add . && git commit -m 'Initial commit from skeleton'"
echo "  ${BOLD}2.${NC} Install dependencies:"
echo "       composer install"
echo "       npm install            # if using a JS frontend"
echo "  ${BOLD}3.${NC} Bring up the environment:"
if [ "$USE_SAIL" = "y" ]; then
    echo "       ./vendor/bin/sail up -d"
else
    echo "       (start your $APP_CONTAINER container)"
fi
echo "  ${BOLD}4.${NC} Generate app key:"
echo "       cp .env.example .env && $RUN_CMD artisan key:generate"
echo "  ${BOLD}5.${NC} Run quality gate:"
echo "       composer all"
echo
echo "Read ${BOLD}AGENTS.md${NC} and ${BOLD}.ai/STARTUP.md${NC} to onboard agents."
echo
