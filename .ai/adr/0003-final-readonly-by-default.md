# ADR-0003: Final readonly classes by default

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** Project owner

## Context

PHP позволяет наследовать любой класс. Это создаёт ряд проблем:

- Подклассы могут нарушать LSP, переопределяя поведение
- Неинкапсулированное состояние мутирует в неожиданных местах
- Тестам трудно говорить о контракте — можно унаследоваться и обойти
- Refactoring опаснее: мы не знаем, кто унаследовался

PHP 8 ввёл `readonly` свойства, PHP 8.2 — `readonly class`. PHP всегда поддерживал `final class`. Мы можем сделать **обе** ограничения дефолтом и снимать только осознанно.

## Decision

Все доменные/сервисные классы по умолчанию **`final readonly class`**:

- `final` — нельзя наследовать
- `readonly` — все свойства immutable после конструктора

Снимаем по необходимости:
- Не `final` — абстрактные классы и явно-расширяемые базы (контроллеры Laravel, базовые модели). Список — в arch-тестах через `ignoring()`.
- Не `readonly` — классы с мутирующим состоянием (Eloquent Models, Collections, классы с lifecycle).

Контролируется arch-тестами:
```php
arch('all classes are final')
    ->expect('App')
    ->classes->toBeFinal()
    ->ignoring(['App\Http\Controllers\Controller', 'App\Models']);

arch('DTOs are readonly')
    ->expect('App\DTO')
    ->classes->toBeReadonly()
    ->classes->toBeFinal();
```

## Alternatives Considered

### Option A — Default open (no `final`)

- ✅ Гибкость — наследуйся свободно
- ❌ Неуправляемые подклассы; LSP-нарушения; сложность рефакторинга

### Option B — `final` only, mutable

- ✅ Заблокировано наследование
- ❌ Состояние всё ещё мутирует — баги «откуда-то прилетело новое значение»

### Option C (Chosen) — `final readonly` by default

- ✅ Иммутабельность ловит большинство багов «откуда оно взялось»
- ✅ `final` — Phpstan/Rector могут безопаснее рефакторить
- ❌ Eloquent и часть Laravel-кода — не readonly. Нужны явные исключения.

## Consequences

### Positive

- Меньше ошибок состояния
- Безопаснее composition-only архитектура
- Совместимость с DDD/гексагональным стилем (DTO/VO immutable)

### Negative

- `Eloquent\Model` нельзя `readonly` — модели вне правила
- Mockery / тестовые двойники сложнее с `final` (но Pest mock и `mockery::mock(SomeFinalClass::class)` работают через alias)

### Mitigation

- Список исключений — в arch-тестах через `ignoring()`
- Для тестов с `final` — использовать interfaces (`Contracts\*`), а не сами классы

## Related

- `.ai/rules/backend/code-style.md`
- `tests/Architecture/FinalClassesTest.php`
- https://refactoring.guru/ru/replace-inheritance-with-delegation
