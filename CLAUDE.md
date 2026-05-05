# CLAUDE.md

Все правила для агентов — в `AGENTS.md` (канон). Этот файл — тонкий пойнтер для Claude Code.

## Прочитать первым

1. `AGENTS.md` — общие правила
2. `.ai/STARTUP.md` — что подгрузить в контекст

## Claude Code-specific

- Slash-команды: `.claude/commands/` (`/task`, `/quick`, `/implement`, `/review`, `/explain`, `/test-this`, `/refactor`, `/security`, `/update-docs`)
- Hooks: `.claude/hooks/` (PostToolUse + Stop)
- Permissions / hook registrations: `.claude/settings.json`

## Memory tool

Используй `~/.claude/projects/.../memory/` для долгоживущих заметок про пользователя и проект.
Между сессиями — короткие записи в `.ai/memory.md` (видны всем агентам).

## Skills

При старте — посмотреть, релевантна ли активная skill (например `claude-api`, `simplify`).
