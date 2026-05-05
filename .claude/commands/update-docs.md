---
description: Sync .ai/project/ docs with current branch changes
argument-hint: []
---

# /update-docs — Sync project docs with code changes

Анализируешь изменения текущей ветки и обновляешь `.ai/project/` где нужно.

## Шаги

1. **Получи diff:**
   ```bash
   git log <MAIN-BRANCH>..HEAD --oneline
   git diff <MAIN-BRANCH>..HEAD --stat
   git diff <MAIN-BRANCH>..HEAD -- "app/" "database/" "config/" "composer.json" "package.json"
   ```

2. **Прочитай матрицу из `.ai/rules/docs.md`** — какие изменения требуют каких обновлений в `.ai/project/`.

3. **Сопоставь.** Для каждого набора изменений предложи конкретные обновления:

   ```markdown
   ## Предлагаемые обновления документации

   ### `.ai/project/glossary.md`
   Появились новые термины:
   - `Bonus` — баллы клиента, 1 балл = 1 копейка
   - `WaybillNumber` — номер транспортной накладной CDEK

   ### `.ai/project/domain/orders.md` (новый файл)
   Добавлен модуль Orders с бизнес-правилами:
   - Заказ проходит статусы Pending → Paid → Shipped → Delivered
   - Cancellation возможна только в Pending и Paid

   ### `.ai/project/integrations.md`
   Добавить секцию **CDEK** (новая интеграция):
   - URL: ...
   - Auth: ...
   - Rate limits: ...

   ### `.ai/project/data-model.md`
   Новые таблицы: `bonuses`, `bonus_transactions`. Связи: `bonuses ─< bonus_transactions`.

   ### `.ai/project/operations.md`
   Новый cron: `bonuses:expire` ежедневно в 00:00.

   ### `.ai/adr/` — рекомендуемый новый ADR
   `0007-cdek-integration-strategy.md` — почему выбрали SDK, а не свой клиент.

   ### `.ai/project/gotchas.md`
   - `Bonus.amount` хранится в копейках, не баллах. **Не путать.**
   ```

4. **Спроси пользователя**, какие предложения принять (можно по пунктам, можно «все»).

5. **Применяй принятые** — Edit/Write на файлы `.ai/project/` и `.ai/adr/`.

6. **Не пиши** проектные доки за пользователя в спорных местах:
   - Если бизнес-правило не понятно из кода — спроси («это всегда так? только в этом флоу?»)
   - Если ADR — обоснование решения должно идти от пользователя; ты только формализуешь

7. **Финал:**
   ```markdown
   ## Обновлено
   - `.ai/project/glossary.md` — +2 термина
   - `.ai/project/domain/orders.md` — создан, описаны статусы и transitions
   - `.ai/project/integrations.md` — +CDEK
   - `.ai/adr/0007-cdek-integration-strategy.md` — создан (драфт, ждёт уточнений)
   ```

## Когда не запускать

- В ветке только cosmetic changes (rename, formatting)
- Документация уже актуальна (никаких новых терминов / интеграций / структур)
- Перед merge в `<MAIN-BRANCH>` ты уже запускал `/update-docs` и принял изменения

В этих случаях скажи: «Документация актуальна, обновлять нечего».
