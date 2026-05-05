# ADR-0002: Repository pattern for data access

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** Project owner

## Context

Eloquent в Laravel удобен, но провоцирует размазывание query-кода по контроллерам, сервисам и view-моделям. Это:

- Усложняет тестирование (моки на статические методы Eloquent)
- Делает невозможным поиск всех мест, читающих/пишущих в таблицу
- Создаёт N+1 в неожиданных местах
- Нарушает SRP — модель «знает» и про схему, и про бизнес-запросы, и про сериализацию

Альтернативы: оставить Eloquent в контроллерах/сервисах напрямую; использовать Action-классы вместо репозиториев; CQRS.

## Decision

**Все запросы к БД — только через Repository-классы.** Никакого `Order::query()->...` в контроллерах или сервисах напрямую.

- Repository — `final readonly class` с конструктором-инжектом
- Methods именуются по бизнес-намерению (`paidIn(DatePeriod)`), не по технической части (`whereStatusInDateRange()`)
- Возвращает Models, Collections, или DTO для read-моделей
- Кастомный Eloquent Builder — допустим, если запросы переиспользуются

Контролируется arch-тестом (`tests/Architecture/LayerBoundariesTest.php`):
```php
arch('services use repositories, not eloquent directly')
    ->expect('App\Services')
    ->not->toUse(['Illuminate\Database\Eloquent\Builder']);
```

## Alternatives Considered

### Option A — Eloquent everywhere (default Laravel)

- ✅ Меньше кода, привычный стиль
- ❌ Размазанные запросы, сложное тестирование, N+1

### Option B — Action classes

- ✅ Гранулярность — один класс = один use-case
- ❌ Размывает границу с Service; легко получить 200 классов вида `GetPaidOrdersForCustomerAction`

### Option C (Chosen) — Repository

- ✅ Чёткая граница «весь access к таблице — здесь»
- ✅ Легко тестировать (мокаем repository в service test)
- ✅ Все query про модель — в одном файле, легко найти и оптимизировать
- ❌ Лишний слой кода в простых случаях

## Consequences

### Positive

- Service-тесты быстрые (моки репозиториев, без БД)
- Любой query можно найти grep'ом по имени метода репозитория
- Архитектурный тест блокирует regression

### Negative

- Для CRUD-эндпоинта добавляется лишний слой
- Соблазн делать «универсальный» репозиторий с `findBy(criteria)` — это анти-паттерн

### Mitigation

- В правилах: имена методов репозиториев — по бизнес-намерению, не общие (`paidOrdersInPeriod`, не `findWhere`)
- Для очень простых сущностей (lookup-таблицы) — допустим прямой Eloquent через сервис, но это исключение и должно быть отмечено комментарием с ссылкой на этот ADR

## Related

- `.ai/rules/backend/architecture.md`
- `.ai/templates/backend/repository.md`
- `tests/Architecture/LayerBoundariesTest.php`
