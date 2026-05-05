# AGENTS.md

> Канонический файл правил для AI-агентов в этом проекте.
> Читают: Claude Code (`CLAUDE.md` указывает сюда), Codex (`.codex/AGENTS.md` указывает сюда), Cursor (читает напрямую), JetBrains AI (`.aiassistant/rules/summary.md` указывает сюда).

## Старт сессии

Перед работой прочитай `.ai/STARTUP.md` — там указан минимум, который надо загрузить в контекст.

## Базовые правила

### Permissions

- **NEVER** commit / push без явного запроса пользователя
- **NEVER** создавай ветки без подтверждения
- **NEVER** запускай destructive git-команды (`reset --hard`, `push --force`, `branch -D`)
- **ALWAYS** предлагай план до реализации (см. `.ai/rules/workflow.md`)

### Workflow

- Анализ → план → согласование с пользователем → код → проверки → отчёт
- На крупной задаче — `/task` (архитектурное интервью + `decisions.md`)
- На мелкой — `/quick` (план в 5 пунктов → одобрение → код)
- Подробности: `.ai/rules/workflow.md`

### Code

- Backend (PHP): см. `.ai/rules/backend/code-style.md`, `.ai/rules/backend/architecture.md`
- Frontend (TS/Vue): см. `.ai/rules/frontend/code-style.md`, `.ai/rules/frontend/architecture.md`
- Общее: `.ai/rules/solid.md`, `.ai/rules/code-smells.md`, `.ai/rules/refactoring-techniques.md`

### Documentation

- Документация — часть Definition of Done. Без обновления `.ai/project/` задача не закрыта.
- Что и куда обновлять: `.ai/rules/docs.md`

### Git

- Коммиты, ветки, защищённые ветки: `.ai/rules/git.md`

## Индекс

| Тема | Путь |
|---|---|
| Старт сессии | `.ai/STARTUP.md` |
| Workflow (как работаем) | `.ai/rules/workflow.md` |
| Документация (как пополнять) | `.ai/rules/docs.md` |
| Git | `.ai/rules/git.md` |
| Code Review | `.ai/rules/review.md` |
| SOLID | `.ai/rules/solid.md` |
| Code Smells (refactoring.guru) | `.ai/rules/code-smells.md` |
| Refactoring Techniques | `.ai/rules/refactoring-techniques.md` |
| Backend Style | `.ai/rules/backend/code-style.md` |
| Backend Architecture | `.ai/rules/backend/architecture.md` |
| Backend Testing (Pest) | `.ai/rules/backend/testing.md` |
| Frontend Style | `.ai/rules/frontend/code-style.md` |
| Frontend Architecture | `.ai/rules/frontend/architecture.md` |
| Frontend Testing | `.ai/rules/frontend/testing.md` |
| Project Overview | `.ai/project/overview.md` |
| Glossary | `.ai/project/glossary.md` |
| Gotchas | `.ai/project/gotchas.md` |
| ADR | `.ai/adr/README.md` |
| Templates | `.ai/templates/` |
| Memory (между сессиями) | `.ai/memory.md` |

## Stack

- PHP 8.5+ • Laravel 13 • Pest 3 • Larastan / PHPStan max
- Vue 3 + TypeScript + Inertia + Pinia + Vitest *(дефолт; переключается через `init.sh`)*
- Sail (Docker) — все команды через `<RUN-CMD>` *(после `init.sh` = `./vendor/bin/sail bin`)*

## Quick reference

```bash
composer style       # ECS auto-fix
composer analyse     # PHPStan + Larastan
composer arch        # Pest architecture tests
composer test        # Pest unit + feature
composer types       # Pest type coverage
composer all         # style + analyse + arch + types + test
composer fix         # ECS + Rector (если включён)
```

## Ticket / branch / commit format

- Ticket prefix: `<TICKET-PREFIX>` *(например, `PROJ-1234`)*
- Branch: `<TICKET-PREFIX>-{NNNN}_{description}`
- Commit: `[<TICKET-PREFIX>-{NNNN}]: description`
- Main branch: `<MAIN-BRANCH>`

Подробности — `.ai/rules/git.md`.
