# STARTUP — что прочитать в начале сессии

## Обязательно

1. `AGENTS.md` — общие правила, индекс
2. `.ai/project/overview.md` — что за проект
3. `.ai/project/glossary.md` — словарь домена
4. `.ai/project/gotchas.md` — известные подводные камни
5. `.ai/memory.md` — заметки между сессиями (текущая ветка, контекст)

## По теме задачи

| Если задача связана с... | Прочитай |
|---|---|
| архитектурой / новым модулем | `.ai/rules/backend/architecture.md` + `.ai/project/data-model.md` |
| контроллерами / API | `.ai/rules/backend/code-style.md` + `.ai/templates/backend/controller.md` |
| фронтом | `.ai/rules/frontend/code-style.md` + `.ai/rules/frontend/architecture.md` |
| тестами | `.ai/rules/backend/testing.md` или `.ai/rules/frontend/testing.md` |
| ревью | `.ai/rules/review.md` |
| рефакторингом | `.ai/rules/code-smells.md`, `.ai/rules/refactoring-techniques.md` |
| внешними API | `.ai/project/integrations.md` |
| инфраструктурой / cron / queue | `.ai/project/operations.md` |
| инцидентом | `.ai/project/runbook.md` |
| активной задачей по тикету | `.ai/tasks/<TICKET-PREFIX>-{NNNN}-decisions.md` |

## ADR

- `.ai/adr/README.md` — индекс архитектурных решений с обоснованием
- Читать, если решение пользователя противоречит коду — возможно, был ADR

## Workflow

См. `.ai/rules/workflow.md` — как именно работать (план → согласование → код → проверки → docs → отчёт).

## Definition of Done

Задача не закрыта, пока не обновлена документация.
См. `.ai/rules/docs.md`.
