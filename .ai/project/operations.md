# Operations

> Окружения, очереди, cron, кэш-инвалидация, особенности продакшена.

## Окружения

| Env | URL | DB | Redis | Особенности |
|---|---|---|---|---|
| local | http://<PROJECT-DOMAIN> | sail mysql | sail redis | Sail Docker, Vite dev-server |
| stage | *(заполни)* | | | |
| prod | *(заполни)* | | | |

## Docker / Sail

- Команды — через `<RUN-CMD>` (по умолчанию `./vendor/bin/sail bin`)
- Контейнер app: `<PROJECT-NAME>-laravel.test-1` (Sail) или `<APP-CONTAINER>` (custom)
- `<RUN-CMD> artisan ...`
- `<RUN-CMD> pest ...`
- `<RUN-CMD> ecs check`
- Полный список — `composer.json` секция `scripts`

## Queue

- Driver: *(redis / database / sqs)*
- Connection в `.env`: `QUEUE_CONNECTION=...`
- Очереди:
  - `default` — общие задачи
  - `high` — важные (платежи, нотификации)
  - `low` — фоновые (отчёты, очистка)
- Воркеры — *(Horizon / supervisord / k8s)*
- Запуск воркера локально: `<RUN-CMD> artisan queue:work`

## Scheduled tasks (cron)

`app/Console/Kernel.php` (Laravel 12) или `routes/console.php` (Laravel 13).

| Команда | Расписание | Что делает |
|---|---|---|
| *(Заполни по мере появления)* | | |

Cron в проде — единственный entrypoint:
```
* * * * * cd /var/www && php artisan schedule:run >> /dev/null 2>&1
```

## Cache

- Driver: *(redis / database / memcached)*
- Ключи и TTL — см. отдельные модули
- Инвалидация:
  - *(описать стратегию: tag-based / event-based / TTL-only)*

## Search (если есть)

- Engine: *(Elasticsearch / Meilisearch / Algolia / native MySQL FULLTEXT)*
- Индексы:
  - *(заполни)*
- Reindex command: *(заполни)*

## Logs

- Channel: `stack` → `single` (local) / `daily` + `slack` (prod)
- Уровень: `debug` (local) / `info` (prod)
- Где смотреть в проде: *(папка / Logtail / Datadog / Sentry)*

## Monitoring / Alerts

- *(Grafana / Sentry / NewRelic — куда настроены алерты)*
- *(дашборды — URL)*

## Backups

- БД — *(периодичность, retention, где хранятся, как восстановить → runbook.md)*
- Файлы (storage) — *(аналогично)*

## Deploy

- *(Manual / Envoy / GitHub Actions / GitLab CI / Capistrano-style)*
- Шаги:
  1. *(заполни)*
- Откат: *(стратегия)*

## Обязательные ENV variables в проде

*(Список, который должен быть выставлен — чтобы при старте приложение не запустилось без них)*

- `APP_KEY`
- `DB_*`
- `REDIS_*`
- `MAIL_*`
- *(API ключи интеграций)*
