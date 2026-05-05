# ADR-0004: Laravel Boost MCP for AI workflows

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** Project owner

## Context

Проект работает с AI-агентами (Claude Code, Codex, Cursor). Им нужен доступ к актуальной Laravel-документации и встроенным помощникам.

Laravel 13 выпустил **Laravel Boost** — first-party MCP-сервер от команды Laravel, специально для интеграции с AI-кодинг-агентами. Он предоставляет:

- Slash-команды типа `/upgrade-laravel-v13` для управляемой миграции
- Контекстные подсказки про API текущей версии Laravel
- Интеграцию с Tinker/Telescope для read-only-инспекции состояния

Альтернатива — context7 (universal docs MCP) и/или web search.

## Decision

Включаем **Laravel Boost** в `.mcp.json` скелета как один из дефолтных MCP-серверов наряду с context7 (общая документация), playwright (браузерная автоматизация) и mysql.

Установка опциональна (требует `composer require laravel/boost`), но конфигурация в `.mcp.json` — есть из коробки.

## Alternatives Considered

### Option A — Только context7

- ✅ Универсально, покрывает не только Laravel
- ❌ Не знает про конкретное состояние нашего приложения, миграции, Tinker

### Option B — Только Laravel Boost

- ✅ Глубокая Laravel-специфика
- ❌ Не помогает с PHP-stdlib, Pest, Vue, другими инструментами

### Option C (Chosen) — Laravel Boost + context7 параллельно

- ✅ Boost для Laravel-специфики и текущего состояния приложения
- ✅ context7 для всех остальных библиотек и общих API
- ✅ Агент сам выбирает источник по контексту вопроса
- ❌ Два MCP — больше startup time, но это секунды

## Consequences

### Positive

- AI-агенты не путаются в версиях Laravel (Boost знает текущую)
- Команды Boost доступны через slash в Claude Code
- Upgrade'ы Laravel становятся управляемыми через AI

### Negative

- Зависимость от стороннего пакета (`laravel/boost`)
- Возможные конфликты MCP-серверов при перегрузке инструментов

### Mitigation

- Boost опционален: можно убрать из `.mcp.json` и удалить пакет, скелет продолжит работать
- В `init.sh` — флаг для включения/выключения Boost

## Related

- `.mcp.json`
- https://github.com/laravel/boost
- ADR-0001 (Pest) — комплементарно: Boost для рантайма, Pest для тестов
