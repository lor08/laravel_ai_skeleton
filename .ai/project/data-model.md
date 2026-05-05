# Data Model

> Ключевые таблицы, нетривиальные связи, инварианты.
> Полная схема — `schema.sql` (если есть) или `<RUN-CMD> php artisan db:show`.

## ER-обзор

*(Опционально — ASCII или Mermaid-диаграмма ключевых связей.)*

```
customers ─< orders >─ order_items >─ products
                  │
                  └─< payments
```

## Таблицы

### `<table_name>`

*(Заполняется по мере появления таблиц с нетривиальной семантикой.)*

| Колонка | Тип | Особенности |
|---|---|---|
| `id` | bigint PK | |
| `status` | string | enum: pending/paid/cancelled |
| `total` | int | в копейках |
| `created_at` | timestamp | |

**Инварианты:**
- *(условия, которые должны выполняться всегда; что нельзя изменять без серьёзного обоснования)*

**Связи:**
- *(`belongsTo`, `hasMany` с особенностями)*

**Индексы (нестандартные):**
- *(составные, partial, full-text)*

## Soft delete

*(Каждая таблица — с deleted_at? Только некоторые? — описать)*

## Multi-tenancy

*(Если есть — как это устроено: shared db / db per tenant / схема per tenant)*

## Critical invariants

*(Список жёстких инвариантов, которые проверяются триггерами / CHECK / на уровне приложения)*

- Например: «Сумма order_items.price * quantity всегда равна orders.total»

## Migrations

- Каждая миграция — обратима (`down()`)
- Data-миграции — отдельным файлом от schema-миграций
- Долгие миграции (> 1 минуты на проде) — обсудить в ADR
