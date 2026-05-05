# Runbook

> Что делать в инцидентах. Процедуры восстановления, перезапуска, переиндексации, миграции.

> Этот файл опционален. Если у проекта нет prod-операций — можно удалить.

## Контакты

- On-call: *(имя / Slack)*
- Escalation: *(имя / телефон)*
- Заказчик / стейкхолдер: *(имя)*

## Доступы

- Prod SSH: *(где запросить)*
- DB прод: *(где запросить)*
- Vault / secrets: *(URL)*

## Процедуры

### Перезапуск queue worker

```bash
<RUN-CMD> artisan queue:restart        # graceful, в течение 5 минут
# или (при горящем):
sudo systemctl restart laravel-worker
```

### Очистка кэша приложения

```bash
<RUN-CMD> artisan cache:clear
<RUN-CMD> artisan config:clear
<RUN-CMD> artisan route:clear
<RUN-CMD> artisan view:clear
```

В проде — лучше сначала `cache:clear`, потом `config:cache && route:cache && view:cache` чтобы ускорить.

### Восстановление БД из бэкапа

1. Найти бэкап: *(где лежат)*
2. Перевести app в maintenance: `<RUN-CMD> artisan down`
3. Восстановить: `mysql -u user -p db < backup.sql`
4. Прогнать миграции: `<RUN-CMD> artisan migrate`
5. Снять maintenance: `<RUN-CMD> artisan up`

### Переиндексация поиска

*(Если есть search engine — описать команду)*

```bash
<RUN-CMD> artisan scout:flush "App\Models\Product"
<RUN-CMD> artisan scout:import "App\Models\Product"
```

### Откат деплоя

*(Описать процедуру отката: предыдущий релиз, миграции, кэш)*

### Утечка секрета

1. **Немедленно** ротировать ключ во внешнем сервисе
2. Удалить из git-истории (если попал в репо): `git filter-repo`
3. Force push (после согласования)
4. Уведомить команду в Slack
5. Записать инцидент в `.ai/memory.md` или ADR

### Высокая нагрузка на БД

```bash
# смотрим slow queries
<RUN-CMD> artisan db:show
<RUN-CMD> artisan db:monitor

# смотрим текущие коннекты
mysql -u root -p -e "SHOW PROCESSLIST"
```

## Известные incident-сценарии

*(Если случались — описать что произошло и как починили)*

### YYYY-MM-DD — короткое название

- **Симптомы:** ...
- **Причина:** ...
- **Что сделали:** ...
- **Что сделать, чтобы не повторилось:** ...
