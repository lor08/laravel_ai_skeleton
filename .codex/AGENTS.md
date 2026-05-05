# Codex agent rules

Все правила для агентов — в корневом `AGENTS.md`. Этот файл — пойнтер для Codex.

## Read first

1. `../AGENTS.md` — общие правила
2. `../.ai/STARTUP.md` — что подгрузить в контекст
3. `../.ai/rules/workflow.md` — режимы `/task` и `/quick`
4. `../.ai/rules/backend/code-style.md` + `../.ai/rules/backend/architecture.md`
5. `../.ai/rules/frontend/code-style.md` + `../.ai/rules/frontend/architecture.md`

## Codex-specific

- Codex не использует `.claude/commands/` слэш-команды Claude Code, но логика workflow одинаковая. Открой `.ai/rules/workflow.md` и применяй её на каждом запуске.
- `decisions.md` хранится в `.ai/tasks/` — общая зона между всеми агентами.
- ADR — `.ai/adr/`.

## Memory

`.ai/memory.md` — общий блокнот между сессиями. Читай в начале и пиши короткие заметки в конце.

## Permissions

- **NEVER** commit / push без явного запроса
- **NEVER** создавай ветки без подтверждения
- **NEVER** запускай destructive git команды
- **ALWAYS** предлагай план до реализации (`workflow.md`)
