# CLAUDE.md

Все правила для агентов — в `AGENTS.md` (канон). Этот файл — тонкий пойнтер для Claude Code.

## Прочитать первым

1. `AGENTS.md` — общие правила
2. `.ai/STARTUP.md` — что подгрузить в контекст

## Claude Code-specific

- Slash-команды: `.claude/commands/` (`/task`, `/quick`, `/implement`, `/review`, `/explain`, `/test-this`, `/refactor`, `/security`, `/update-docs`)
- Hooks: `.claude/hooks/` (PostToolUse + Stop)
- Permissions / hook registrations: `.claude/settings.json`

## Memory — два слоя

| Где | Что туда | Видимость |
|---|---|---|
| `~/.claude/projects/<this-project>/memory/` | **Личное знание Claude** про этого пользователя: его роль, предпочтения, привычные паттерны, прошлые корректировки. Файлы — `user.md`, `feedback_*.md`, `project.md`, `reference_*.md` (см. auto-memory спецификацию). | Только Claude Code этого пользователя. Не в git. |
| `.ai/memory.md` | **Командное знание** про текущее состояние проекта: текущая ветка / тикет, висяки, незакрытые наблюдения. | Все агенты + git (зафиксировано в репо). |

**Правило:** наблюдение про пользователя → в `~/.claude/.../memory/`. Наблюдение про проект → в `.ai/memory.md`. Если сомневаешься — командная (`.ai/memory.md`).

## Skills

При старте — посмотреть, релевантна ли активная skill (например `claude-api`, `simplify`).
