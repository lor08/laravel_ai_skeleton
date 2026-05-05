---
description: Heavy workflow — architecture interview + decisions.md → implementation
argument-hint: [ticket | description]
---

# /task — Feature implementation with architecture interview

Запускаешь полный workflow для крупной задачи: интервью с A/B/C-вариантами → `decisions.md` → реализация.

Аргумент: `$ARGUMENTS` — ticket id или описание задачи.

## Шаги

1. **Прочитай:**
   - `AGENTS.md`, `.ai/STARTUP.md`
   - `.ai/rules/workflow.md` — секция «`/task` — тяжёлый»
   - `.ai/rules/backend/architecture.md` + `.ai/rules/backend/code-style.md`
   - `.ai/rules/frontend/architecture.md` + `.ai/rules/frontend/code-style.md` (если фронт)
   - `.ai/project/overview.md`, `.ai/project/glossary.md`, `.ai/project/gotchas.md`

2. **Спроси пользователя:** «Делаем `decisions.md` (для крупных задач) или сразу к плану в 5 пунктов?»

3. **Если decisions.md:**
   - Создай `.ai/tasks/<TICKET-PREFIX>-NNNN-decisions.md` по шаблону из `workflow.md`
   - Проведи архитектурное интервью (Блоки 1–4 из `workflow.md`) с A/B/C-вариантами
   - После каждого решения — записывай в `decisions.md` со статусом ✅ ПРИНЯТО
   - **Не кодируй до конца интервью**

4. **Если план в 5 пунктов:**
   - Сформулируй план: что меняем, где, в каком порядке
   - Покажи пользователю → дождись `ок`

5. **Реализация** — в порядке зависимостей из `.ai/rules/workflow.md`. После каждого PHP-файла — `<RUN-CMD> ecs check --fix path/to/File.php`.

6. **Проверки:**
   ```bash
   composer all
   ```

7. **Документация** — обязательно. Прогон по чек-листу из `.ai/rules/docs.md`. Если ничего не требуется — явно зафиксируй в отчёте.

8. **Финальный отчёт** — по шаблону из `.ai/rules/workflow.md`.

## Когда останавливаться

- Решение в `decisions.md` неоднозначно → спроси
- Файл/код удивил → предупреди
- Конфликт с правилами → предложи добавить ADR или правило, обсуди
