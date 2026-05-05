---
description: Implement decisions from .ai/tasks/{ticket}-decisions.md
argument-hint: [ticket]
---

# /implement — Implement decisions from decisions.md

Реализуешь все принятые решения из `decisions.md`.

Аргумент: `$ARGUMENTS` — ticket id (опц., иначе найди последний `-decisions.md` в `.ai/tasks/`).

## Шаги

1. **Найди файл:** `.ai/tasks/<TICKET-PREFIX>-NNNN-decisions.md` (по аргументу или последний модифицированный).

2. **Прочитай ВСЕ решения** со статусом ✅ ПРИНЯТО.

3. **Прочитай текущее состояние** всех затронутых файлов.

4. **Составь план реализации** в порядке зависимостей (см. `.ai/rules/workflow.md`):
   1. Migrations
   2. Models / Enums / DTOs
   3. Contracts
   4. Repositories
   5. Services
   6. FormRequests / Resources
   7. Controllers / Console commands
   8. Jobs / Events / Listeners
   9. Frontend
   10. Lang / Routes
   11. Tests
   12. Cleanup

5. **Покажи план пользователю → дождись `ок`.**

6. **Иди по плану, файл за файлом:**
   - Следуй правилам из `.ai/rules/backend/code-style.md`
   - Используй шаблоны из `.ai/templates/`
   - После каждого PHP-файла: `<RUN-CMD> ecs check --fix path/to/File.php`
   - Кратко (1 строка) скажи что сделано, переходи к следующему

   **Не жди подтверждения после каждого файла** — иди по плану. Останавливайся только если:
   - Решение в `decisions.md` неоднозначно → спроси
   - Файл удивил (неожиданные зависимости) → предупреди

7. **Тесты:**
   ```bash
   <RUN-CMD> pest --filter=<RelevantTest> --testdox
   ```
   Если падают — чини. Не оставляй сломанными.

8. **Frontend (если менялось):**
   ```bash
   npm run build && npm run test
   ```
   Проверь в браузере: основной сценарий + edge cases.

9. **Финальные проверки:**
   ```bash
   composer all
   ```

10. **Документация** — `.ai/rules/docs.md`.

11. **Финальный отчёт** — по шаблону из `.ai/rules/workflow.md`. Скажи: «Готово к коммиту. Запускай `/review` или сделай commit вручную».
