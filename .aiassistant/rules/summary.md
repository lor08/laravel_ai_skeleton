---
apply: always
---

# JetBrains AI agent rules

> Single source of truth: **`AGENTS.md`** в корне проекта. Этот файл — тонкий указатель для JetBrains AI Assistant / Junie.

## Загрузи в контекст в начале сессии

1. `AGENTS.md`
2. `.ai/STARTUP.md`
3. `.ai/rules/workflow.md`
4. `.ai/rules/backend/code-style.md`
5. `.ai/rules/backend/architecture.md`
6. `.ai/rules/frontend/code-style.md` *(если фронт-задача)*
7. `.ai/project/overview.md` + `.ai/project/glossary.md` + `.ai/project/gotchas.md`

## Critical rules

- **NEVER** commit / push без явного запроса
- **NEVER** создавай ветки без подтверждения
- **ALWAYS** предлагай план до реализации (анализ → план → согласование → код → проверки → docs)

## Code style — keypoints

- `declare(strict_types=1)` в каждом PHP файле
- `final class` / `final readonly class` по умолчанию
- Без `// inline-комментариев` в PHP (только PHPDoc-tags и phpstan-аннотации)
- Только Facades, без global helpers (`view()`, `trans()`, `app()`, ...)
- `$request->validated()` вместо `$request->all()`
- Без вложенных `if` — early return / Guard Clauses
- DTO на boundaries слоёв

Полный набор — `.ai/rules/backend/code-style.md`.

## Workflow

См. `.ai/rules/workflow.md`. Два режима — тяжёлый (`/task` со схемой) и лёгкий (`/quick`).

## Documentation

После задачи — обновить `.ai/project/` если необходимо. См. `.ai/rules/docs.md`.
