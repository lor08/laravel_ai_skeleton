---
description: Apply named refactoring technique from refactoring.guru
argument-hint: <technique> <path>
---

# /refactor — Apply refactoring technique

Применяешь конкретную технику рефакторинга из refactoring.guru/ru.

Аргумент: `$ARGUMENTS` — `<technique> <path>`.

Примеры:
- `/refactor extract-method app/Services/CreateOrderService.php`
- `/refactor guard-clauses app/Http/Controllers/CheckoutController.php:pay`
- `/refactor replace-conditional-with-polymorphism app/Modules/Payment/`
- `/refactor introduce-parameter-object app/Repositories/OrderRepository.php:paginate`

## Поддерживаемые техники

| ID | Название | Когда применять |
|---|---|---|
| `extract-method` | Extract Method | Длинный метод → вынести часть в отдельный |
| `extract-class` | Extract Class | Класс делает несколько вещей |
| `inline-method` | Inline Method | Метод не добавляет смысла — встроить |
| `extract-variable` | Extract Variable | Сложное выражение → именованная переменная |
| `replace-temp-with-query` | Replace Temp with Query | Временная переменная → метод/геттер |
| `decompose-conditional` | Decompose Conditional | Сложный `if` → отдельные методы |
| `guard-clauses` | Replace Nested Conditional with Guard Clauses | Вложенные `if` → early return |
| `replace-conditional-with-polymorphism` | Replace Conditional with Polymorphism | `match`/`switch` по типу → стратегии |
| `introduce-parameter-object` | Introduce Parameter Object | > 4 параметров → DTO |
| `replace-magic-number` | Replace Magic Number with Symbolic Constant | Числа → именованные константы |
| `replace-type-code-with-enum` | Replace Type Code with Enum | Строковые/числовые статусы → native enum |
| `move-method` | Move Method | Метод использует чужие данные → переместить |
| `hide-delegate` | Hide Delegate | `$a->b()->c()` → `$a->c()` |
| `consolidate-conditional` | Consolidate Conditional Expression | Несколько `if` с одним результатом → одно условие |
| `replace-data-value-with-object` | Replace Data Value with Object | Примитив с поведением → Value Object |
| `split-temp-variable` | Split Temporary Variable | Одна переменная для разных целей → несколько |

Полный каталог — `.ai/rules/refactoring-techniques.md`.

## Шаги

1. **Прочитай:**
   - Целевой файл / метод
   - `.ai/rules/refactoring-techniques.md` (ту секцию, что соответствует `<technique>`)
   - `.ai/rules/code-smells.md` (для контекста — какой запах лечим)

2. **Подтверди понимание:**
   - Какую конкретно проблему решаем?
   - Где именно в файле / методе?
   - Какой результат ожидается (1–2 предложения)?

3. **Покажи план:** что станет, что не изменится, какие тесты должны продолжить проходить.

4. **Дождись `ок` от пользователя.**

5. **Реализуй:**
   - Маленькими шагами (один шаг — компилируется и проходят тесты)
   - После каждого шага: `<RUN-CMD> ecs check --fix path` + `<RUN-CMD> pest --filter=<RelevantTest>`
   - Если тесты падают — разберись, почему. Не переходи к следующему шагу со сломанными тестами.

6. **Финальные проверки:**
   ```bash
   composer style
   composer analyse
   composer arch
   composer test
   ```

7. **Если рефакторинг затронул behavior (не должен!)** — это сигнал, что тесты не покрывают, или применили технику неправильно. Откати изменения и обсуди с пользователем.

8. **Краткий отчёт:** что изменилось, до/после в нескольких строках, статусы проверок.
