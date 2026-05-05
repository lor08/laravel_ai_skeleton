# ADR-0005: Module Bridge as Anticorruption Layer

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** Project owner

## Context

В проектах с несколькими модулями (`app/Modules/...`) часто возникает соблазн напрямую импортировать `Service` или `Repository` одного модуля из другого. Это приводит к:

- **Связности** через имена внутренних классов и моделей: переименовал `BonusBalance` → ломается всё
- **Утечке языка**: модуль-потребитель оперирует терминами модуля-поставщика, а не своими
- **Невозможности параллельной разработки**: команды наступают друг другу на код
- **Сложности в legacy-миграциях**: нельзя плавно заменить старый модуль новым, не трогая всех потребителей

В DDD это решается **Anticorruption Layer (ACL)** — слоем между ограниченными контекстами, который переводит язык одного контекста в язык другого.

## Decision

Заводим отдельную папку **`app/ModuleBridge/`** на верхнем уровне (рядом с `app/Modules/`, не внутри). Каждая под-папка — bridge между двумя контекстами или для определённого потребителя.

Bridge содержит:
- `Contracts/` — interface, который видит потребитель
- `DTO/` — типы в **языке потребителя**, не поставщика
- `Services/` — реализация контракта
- `Transformers/` — перевод моделей/DTO поставщика в DTO потребителя
- `Providers/` — биндинг контракта к реализации

**Потребитель импортирует только Contract и DTO.** Никаких `App\Modules\<Provider>\Repositories\*`, `Models\*`, `Services\*`.

Контролируется arch-тестами:
```php
arch('modules do not see bridge internals')
    ->expect('App\Modules')
    ->not->toUse([
        'App\Modules\Bonuses\Repositories',
        'App\Modules\Bonuses\Services',
        'App\Modules\Bonuses\Models',
    ]);
```

## Alternatives Considered

### Option A — Прямой импорт между модулями

- ✅ Минимум кода
- ✅ Знакомо всем
- ❌ Связность языков: `OrderService` знает про `BonusBalance::class`, `BonusRule::class`, `BonusTransaction::class`
- ❌ Любая внутренняя реструктуризация поставщика ломает потребителя
- ❌ Тесты потребителя должны мокать модели поставщика

### Option B — Events / Listeners только

- ✅ Полная развязка
- ✅ Хорошо для асинхронного оповещения
- ❌ Не работает для request/response (получить актуальный balance — не event)
- ❌ Скрытая логика (нашёл вызов? найди всех слушателей)

### Option C — Shared kernel в `app/Shared/`

- ✅ Меньше папок
- ❌ «Shared» становится свалкой, теряется граница
- ❌ Если concept нужен **не всем** — это не shared

### Option D (Chosen) — `app/ModuleBridge/` ACL

- ✅ Явная граница: импортируется только Contract + DTO
- ✅ Каждый bridge — на одного потребителя или одну пару контекстов
- ✅ Перепиливание поставщика — правки только в Bridge
- ✅ Тесты bridge'а — изолированы от обоих модулей
- ❌ Лишний слой кода (доп. transformer, доп. interface)

## Consequences

### Positive

- Модули могут жить и развиваться независимо
- Замена внутренней реализации одного модуля — без правок в потребителях
- Архитектурные тесты блокируют утечку внутренних имён
- Onboarding нового разработчика проще: «хочешь данные модуля X — смотри `Contracts/`»

### Negative

- При мелких контактах (1–2 метода) — overhead
- Дополнительные классы (Transformer, DTO Snapshot)

### Mitigation

- **Критерий входа:** Bridge заводим, когда **5+ точек контакта** или модуль legacy/новый — иначе прямой DI без слоя
- **Критерий выхода:** если Bridge не имеет ничего, кроме делегирования — это Middle Man (запах кода), удалить
- Шаблон `.ai/templates/backend/module-bridge.md` показывает структуру

## Related

- `.ai/templates/backend/module-bridge.md`
- `.ai/templates/backend/module.md`
- ADR-0002 — Repository pattern (комплементарно: Repository — внутри модуля, Bridge — между ними)
- DDD: <https://martinfowler.com/bliki/AnticorruptionLayer.html>
