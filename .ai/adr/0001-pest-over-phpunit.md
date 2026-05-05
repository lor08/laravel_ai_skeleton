# ADR-0001: Pest 3 over PHPUnit

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** Project owner

## Context

Проект ставит жёсткие правила кода: `final class`, `declare(strict_types=1)`, фасады вместо хелперов, тонкие контроллеры, репозитории без HTTP-зависимостей. Эти правила нужно держать не только дисциплиной, но и автоматически — иначе они становятся комментариями.

Стандартный выбор тестового фреймворка для PHP — PHPUnit. Альтернатива — Pest 3, более лаконичный фреймворк поверх PHPUnit с встроенным плагином архитектурных тестов.

## Decision

Используем **Pest 3** как основной фреймворк тестирования.

Все правила архитектуры и стиля кодифицируем в `tests/Architecture/` через `arch()` тесты. Они проверяются в CI и блокируют merge при нарушении.

PHPUnit-стиль (xUnit) допустим внутри Pest — Pest на нём работает.

## Alternatives Considered

### Option A — PHPUnit

- ✅ Стандарт PHP, все знают
- ✅ Глубокая IDE-интеграция (PhpStorm)
- ❌ Архитектурные тесты — только через сторонние пакеты (PHPat и т.п.), не нативно
- ❌ Mutation testing и type coverage — отдельные пакеты, отдельная конфигурация
- ❌ Больше boilerplate в типовых тестах

### Option B — Pest 2

- ✅ Лаконичный синтаксис, datasets, higher-order tests
- ❌ Нет встроенного mutation testing (в Pest 3 — есть)

### Option C (Chosen) — Pest 3

- ✅ Архитектурные тесты `arch()` нативно — это закрывает половину наших правил без хуков
- ✅ Mutation testing встроен (`pest --mutate`)
- ✅ Type coverage встроен (`pest --type-coverage`)
- ✅ Совместим с PHPUnit: внутри Pest можно писать классические `extends TestCase`-тесты
- ✅ Laravel сообщество перешло на Pest, новые стартеры по умолчанию — Pest
- ❌ Меньшая часть PHP-разработчиков знакома (но порог входа низкий, синтаксис интуитивен)

## Consequences

### Positive

- Architecture rules становятся **тестами в CI**, не комментариями. Нарушение = красный билд.
- Меньше кода в типовых тестах → быстрее писать → больше тестов
- Type coverage и mutation testing бесплатно в той же команде

### Negative

- Если в команде есть категорически непривыкшие к функциональному стилю — нужен onboarding
- Некоторые PHPUnit-плагины (для специфических расширений) требуют адаптации

### Mitigation

- Внутри Pest можно писать xUnit-стиль — fallback всегда есть
- Документировано в `.ai/rules/backend/testing.md` с примерами обоих стилей

## Related

- `.ai/rules/backend/testing.md`
- `tests/Architecture/`
- https://pestphp.com
- https://github.com/pestphp/pest-plugin-arch
