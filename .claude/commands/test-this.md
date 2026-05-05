---
description: Generate Pest tests for given file/class — unit + arch hints
argument-hint: [path]
---

# /test-this — Generate Pest tests

Сгенерируй Pest-тесты для указанного файла/класса.

Аргумент: `$ARGUMENTS` — путь или класс.

## Шаги

1. **Прочитай:**
   - Целевой файл
   - Все его публичные методы
   - Зависимости (для понимания, что нужно мокать)
   - Существующие тесты этого класса (если есть)
   - `.ai/rules/backend/testing.md`

2. **Определи слой** (Controller / Service / Repository / Job / DTO / VO / Enum / Model) и тип теста:
   | Слой | Тип |
   |---|---|
   | Controller | Feature |
   | FormRequest | Feature через endpoint |
   | Service | Unit (моки на repos), Feature (full happy path) |
   | Repository | Feature (с реальной БД) |
   | Job | Unit + Feature (`Bus::fake()`) |
   | Event/Listener | `Event::fake()` |
   | Resource | Unit |
   | DTO/VO/Enum | Unit |

3. **Покажи план тестов** (имена `it(...)`, что проверяет каждый):
   ```
   tests/<Type>/<Class>Test.php
   - it('does X when Y')
   - it('throws when Z is invalid')
   - it('returns empty when no data')
   ...
   ```

4. **Дождись `ок` от пользователя** (план может быть избыточен или мало).

5. **Сгенерируй тест** по шаблону из `.ai/rules/backend/testing.md`. Используй:
   - Pest синтаксис (`it`, `beforeEach`, `expect`)
   - Mockery / `mock()` для моков
   - Datasets через `->with([...])` для параметризации
   - Higher-order tests где уместно

6. **Если затронут новый namespace / слой** — предложи добавить arch-тест в `tests/Architecture/` (см. `.ai/templates/backend/test-arch.md`).

7. **Запусти** созданные тесты:
   ```bash
   <RUN-CMD> pest --filter=<NewTestName>
   ```
   Если падают — отладь.

8. **Type coverage:**
   ```bash
   <RUN-CMD> pest --type-coverage
   ```

9. **Отчёт** — список созданных файлов, статус прогона.

## Принципы

- Покрывай **поведение**, не **реализацию** (тест должен пережить рефакторинг)
- Один `it()` = один смысловой кейс (не куча asserts)
- Имя `it('does X when Y')` — описание, а не реализация (`it('uses Eloquent::find')` ❌)
- Edge cases обязательны: пустые данные, null, граничные значения, ошибки
