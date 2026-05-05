---
description: Interview-style code review of current branch
argument-hint: []
---

# /review — Interview-style code review

Проводишь ревью текущей ветки в формате интервью: метод за методом, с решениями пользователя.

## Шаги

1. **Прочитай правила:**
   - `.ai/rules/review.md`
   - `.ai/rules/backend/code-style.md` + `.ai/rules/backend/architecture.md`
   - `.ai/rules/frontend/code-style.md` + `.ai/rules/frontend/architecture.md` (если есть фронт)
   - `.ai/rules/code-smells.md`, `.ai/rules/solid.md`
   - `.ai/memory.md`, `.ai/project/gotchas.md`

2. **Получи изменения:**
   ```bash
   git log <MAIN-BRANCH>..HEAD --oneline
   git diff <MAIN-BRANCH>..HEAD --stat
   git diff <MAIN-BRANCH>..HEAD -- "*.php" "*.vue" "*.ts"
   ```

3. **Определи ticket** из названия ветки (`<TICKET-PREFIX>-NNNN_description`).

4. **Создай `.ai/tasks/<TICKET-PREFIX>-NNNN-review.md`** по шаблону из `.ai/rules/review.md`.

5. **Pre-review:** беглый просмотр всей ветки. Найди и вынеси на быстрое решение пользователя:
   - Мёртвый код, MVP, закомментированное, TODO без даты
   - Явные баги
   - Удалить/оставить — очевидные случаи
   Оформи списком Q1, Q2, ... → получи ответы → запиши в `review.md`.

6. **Интервью** — entry point за entry point:
   - Web Controller (blade)
   - API Controller
   - Jobs / Commands
   - Events / Listeners

   Для каждого метода:
   - Покажи цепочку (Vue → Controller → Service → Repository → DB)
   - Найди проблемы по категориям P1/P2/P3 (баги / качество / опц.)
   - Сверься с code smells и SOLID
   - Для каждой проблемы — варианты A/B/C
   - Дождись решения → запиши в `review.md` ✅ ПРИНЯТО

7. **Если найден новый паттерн** или повторяющееся нарушение → предложи добавить:
   - Правило в `.ai/rules/...` (для стиля/паттерна)
   - ADR в `.ai/adr/...` (для архитектурного решения)

8. **Завершение:**
   - Обнови статусы в `review.md` (✅ Завершён)
   - Заполни Quality чек-лист (composer style/analyse/arch/test)
   - Скажи: «Ревью завершено. P1: X, P2: Y, P3: Z. Готов к `/implement`.»
