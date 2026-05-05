# Backend Architecture

## Слои

```
HTTP Request
    ↓
FormRequest (validation + authorize)
    ↓
Controller (тонкий — только маршрутизация)
    ↓
Service (бизнес-логика, транзакции)
    ↓
Repository (доступ к БД, query builder)
    ↓
Eloquent Model (без бизнес-логики)
    ↓
Database
```

Каждый слой **знает только о слое ниже**. Контроллер не лезет в Eloquent. Repository не знает про HTTP. Model не вызывает Service.

## Контроллер

- `final class`, расширяет `App\Http\Controllers\Controller`
- Single Action (`__invoke`) или RESTful resource
- Внутри метода: `$dto = $request->validated()` → `$service->doSomething($dto)` → `return Resource::make(...)`
- Никаких `DB::`, `Eloquent::`, `Cache::`, бизнес-логики
- Авторизация — в FormRequest через `authorize()` или middleware
- Шаблон: `.ai/templates/backend/controller.md`

## FormRequest

- `final class`, расширяет `Illuminate\Foundation\Http\FormRequest`
- `authorize()` — реальная проверка, не `return true`
- `rules()` — все правила валидации; enum через `Rule::enum(...)`
- Опционально: `toDto()` мост для сервиса
- Шаблон: `.ai/templates/backend/form-request.md`

## Service

- `final readonly class`, DI всех зависимостей через конструктор
- Один сервис = одна бизнес-операция (или близкая группа)
- Транзакции — в сервисе через `DB::transaction(...)`, не в контроллере
- Свои `DomainException` для бизнес-ошибок
- Без прямого Eloquent (через Repository), HTTP request, View
- Шаблон: `.ai/templates/backend/service.md`

## Repository

- `final readonly class`
- **Единственное** место для Eloquent / DB / Query Builder
- Имена методов — по бизнес-намерению (`paidForCustomer`), не по технике (`whereStatusAndCustomerId`)
- Возврат — Model / Collection / DTO / Paginator
- N+1 предотвращать — `with()`, `withCount()`
- Шаблон: `.ai/templates/backend/repository.md`
- Стиль запросов: `.ai/rules/backend/eloquent.md`

## Model

- Eloquent — **только** маппинг таблицы (`$fillable`, `$casts`, relations)
- Без бизнес-логики (не `->confirm()`, не `->calculateTotal()`)
- Без local/global scopes (см. `.ai/rules/backend/eloquent.md`)
- Property hooks для производных полей (PHP 8.4+) — допустимы

## DTO / Value Object

- `final readonly class` с typed properties в конструкторе
- Static factories: `fromArray`, `fromRequest`, `fromModel`
- **Без зависимостей** (никаких `Service`, `DB`, фасадов)
- Опционально `toArray()` для сериализации
- Шаблон: `.ai/templates/backend/dto.md`

## Module pattern (опционально, для крупных проектов)

```
app/Modules/{ModuleName}/
├── Console/           # Artisan commands
├── Contracts/         # Interfaces
├── DTO/               # Module-specific DTOs
├── Enums/             # Module-specific enums
├── Events/
├── Exceptions/        # DomainExceptions
├── Jobs/              # Module-specific jobs
├── Listeners/
├── Providers/         # Service providers (binding в register())
├── Repositories/      # Data access
├── Services/          # Business logic
├── Resources/         # API resources
└── Tests/             # Module tests (опц., если не хочется в tests/)
```

Модуль регистрирует свой `ServiceProvider`, который биндит контракты → реализации.
Между модулями взаимодействуют через **Bridge** (паттерн фасада модуля), не лезут друг другу во внутренности.

Не каждый Laravel-проект нуждается в модулях. Стартуй с плоской структуры (`app/Services/`, `app/Repositories/`), переходи на модули, когда:
- > 3–4 крупные доменные области
- Чёткие границы по бизнес-фичам
- Команда > 1 разработчик и нужны границы

ADR при переходе на модули — обязательно.

### Bridge между модулями

Когда модулей больше двух и они начинают друг на друга ссылаться — заводим **`app/ModuleBridge/`** (Anticorruption Layer). Подробнее — `.ai/templates/backend/module-bridge.md` и ADR-0005.

## Architecture tests (Pest)

См. `.ai/rules/backend/testing.md` и `tests/Architecture/`. Pest arch-тесты блокируют CI при нарушении границ слоёв и стиля.

## Что использовать в каком слое

| Слой | Можно | Нельзя |
|---|---|---|
| Controller | FormRequest, Service, Resource | DB, Eloquent, бизнес-логика |
| FormRequest | Auth facade, rules | DB, Service |
| Service | Repository, другие Service, DTO, Facades (Log, Event, DB::transaction) | Eloquent direct, HTTP request, View |
| Repository | Eloquent, Query Builder, DB | HTTP, бизнес-логика |
| Model | Cast, relation, scope, accessors | Service, бизнес-логика |
| DTO/VO | typed properties, фабрики | Зависимости, БД, HTTP |
| Job | Service, очередь | Direct DB, HTTP без обёртки |
| Resource | Trans, format | Бизнес-логика, query |
