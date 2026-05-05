# INIT — настройка скелета под проект

Этот файл — резервный ручной чек-лист на случай, если `init.sh` не подходит.
Если можешь — запусти `./init.sh`, он сделает всё ниже автоматически.

## Плейсхолдеры

В файлах скелета используются плейсхолдеры в угловых скобках. Замени все вхождения:

| Плейсхолдер | Что вписать | Пример |
|---|---|---|
| `<PROJECT-NAME>` | Имя проекта (kebab-case) | `acme-shop` |
| `<PROJECT-NAMESPACE>` | PSR-4 namespace для composer | `Acme\\Shop` |
| `<TICKET-PREFIX>` | Префикс тикетов | `PROJ`, `JIRA-XX`, `TASK` |
| `<MAIN-BRANCH>` | Главная ветка | `main`, `production`, `develop` |
| `<RUN-CMD>` | Команда-обёртка | `./vendor/bin/sail bin` (по умолчанию) |
| `<APP-CONTAINER>` | Имя docker-контейнера | `myapp_app` *(если без Sail)* |
| `<PROJECT-DOMAIN>` | Локальный домен | `acme-shop.test` |

## Где встречаются

```bash
# Найти все плейсхолдеры:
grep -RIn '<TICKET-PREFIX>\|<MAIN-BRANCH>\|<RUN-CMD>\|<PROJECT-NAME>\|<PROJECT-NAMESPACE>\|<APP-CONTAINER>\|<PROJECT-DOMAIN>' \
  --exclude-dir=vendor --exclude-dir=node_modules .
```

Заменяются: в `.ai/`, `.claude/`, `AGENTS.md`, `composer.json`, `.env.example`, `phpstan.neon`, `tests/Pest.php`, CI-файлах.

## Шаги вручную

1. **Заменить плейсхолдеры.**
   ```bash
   find . -type f \( -name '*.md' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.neon' -o -name '*.php' -o -name '*.sh' -o -name '*.example' \) \
     -not -path './vendor/*' -not -path './node_modules/*' -not -path './.git/*' \
     -exec sed -i \
       -e 's|<PROJECT-NAME>|my-app|g' \
       -e 's|<PROJECT-NAMESPACE>|My\\\\App|g' \
       -e 's|<TICKET-PREFIX>|PROJ|g' \
       -e 's|<MAIN-BRANCH>|main|g' \
       -e 's|<RUN-CMD>|./vendor/bin/sail bin|g' \
       -e 's|<APP-CONTAINER>|app|g' \
       -e 's|<PROJECT-DOMAIN>|my-app.test|g' \
     {} +
   ```

2. **Выбрать frontend-стек.** В `.ai/rules/frontend/` оставь правила, релевантные стеку. Если стек не Vue/Inertia — перепиши `code-style.md` и `architecture.md`.

3. **Включить git-хуки.**
   ```bash
   git config core.hooksPath .git-hooks
   chmod +x .git-hooks/pre-commit .claude/hooks/*.sh init.sh
   ```

4. **Удалить ненужные ADR.** В `.ai/adr/` оставь только те, что отражают **твои** решения. Стартовые ADR (`0001`–`0004`) можно оставить как пример или переписать.

5. **Установить зависимости.**
   ```bash
   composer install
   npm install
   ./vendor/bin/sail up -d
   ```

6. **Проверить, что всё работает.**
   ```bash
   composer all
   ```

7. **Заполнить `.ai/project/`.**
   - `overview.md` — что за проект (1 страница)
   - `glossary.md` — термины домена
   - `data-model.md` — ключевые таблицы
   - Остальное — по мере роста

8. **Заинициализировать git.**
   ```bash
   git init
   git add .
   git commit -m "Initial commit from laravel_ai_skeleton"
   ```

## Опциональное (включается флагом в `init.sh` или вручную)

- **Rector** — установить `rector/rector`, `driftingly/rector-laravel`. Конфиг в `rector.php`. Включить в `composer fix`.
- **Mutation testing** — `composer require --dev pestphp/pest-plugin-mutate`. В CI — отдельный (медленный) job.
- **Runbook** — заполнить `.ai/project/runbook.md` (если оперируешь продакшеном).
- **Laravel Boost MCP** — в `.mcp.json` уже есть, нужно `composer require laravel/boost`.
- **Fillers** — если используешь data-versioning через `sch/fillers` или похожий пакет — см. `.ai/templates/backend/filler.md`.

## Существующий проект

Этот документ — для **нового** проекта. Если внедряешь скелет в существующий Laravel-проект — см. **`ADOPTION.md`** (3 уровня внедрения с rollout-планом).
