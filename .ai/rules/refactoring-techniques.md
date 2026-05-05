# Refactoring Techniques

Источник: <https://refactoring.guru/ru/refactoring/techniques>

Подмножество приёмов, которые мы применяем чаще всего. Полный каталог — по ссылке.

## Composing Methods

### Extract Method
Длинный кусок → отдельный метод с говорящим именем.
- Имя метода = намерение, не реализация
- Маленький метод — это ОК, даже однострочный, если имя добавляет смысл

### Inline Method
Метод не делает ничего, кроме вызова другого, или его тело прозрачнее имени → встроить в место вызова.

### Extract Variable
Сложное условие или выражение → именованная локальная переменная.
```php
// плохо
if (
    $order->status === OrderStatus::Paid
    && $order->total > 1000
    && !$order->customer->isBanned()
) { ... }

// хорошо
$isVipPaidOrder =
    $order->status === OrderStatus::Paid
    && $order->total > 1000
    && !$order->customer->isBanned();

if ($isVipPaidOrder) { ... }
```

### Replace Temp with Query
Если временная переменная вычисляется из других данных — замени на метод/геттер.

### Split Temporary Variable
Одна переменная переиспользуется для разных целей → разные переменные с понятными именами.

### Decompose Conditional
Сложное условие → отдельные методы для условия, then-ветки, else-ветки.

### Replace Nested Conditional with Guard Clauses ⭐
**Любимый приём.** Вложенные `if` → серия early return.
```php
// плохо
public function calc(Order $order): int
{
    if ($order->status === OrderStatus::Paid) {
        if ($order->customer !== null) {
            if (!$order->customer->isBanned()) {
                return $order->total;
            }
        }
    }
    return 0;
}

// хорошо
public function calc(Order $order): int
{
    if ($order->status !== OrderStatus::Paid) {
        return 0;
    }
    if ($order->customer === null) {
        return 0;
    }
    if ($order->customer->isBanned()) {
        return 0;
    }
    return $order->total;
}
```

### Replace Conditional with Polymorphism ⭐
`match` / `switch` по типу → разные классы со общим интерфейсом.

## Moving Features Between Objects

### Move Method / Move Field
Метод/поле использует чужие данные больше, чем свои → переместить.

### Extract Class
Класс делает несколько вещей → выделить второй класс.

### Inline Class
Класс ничего полезного не делает → встроить.

### Hide Delegate
Клиент вызывает `$a->b()->c()` → добавить метод `$a->c()`, скрыть `b()`.

### Remove Middle Man
Класс только делегирует → убрать его, клиент работает напрямую.

## Organizing Data

### Replace Magic Number with Symbolic Constant
```php
// плохо
if ($daysSinceCreation > 30) { ... }

// хорошо
private const ARCHIVE_THRESHOLD_DAYS = 30;
...
if ($daysSinceCreation > self::ARCHIVE_THRESHOLD_DAYS) { ... }
```

### Encapsulate Field
Прямой доступ к полю → через геттер/сеттер. В PHP 8.5 — property hooks.

### Replace Type Code with Enum
String/int константы статуса → native PHP `enum`.

### Replace Data Value with Object
Примитив с поведением → Value Object. `Email`, `Money`, `Percent` вместо `string` / `int`.

## Simplifying Conditionals

### Consolidate Conditional Expression
Несколько `if` с одинаковым результатом → одно условие.

### Replace Conditional with Polymorphism (упомянут выше)

### Introduce Null Object
Вместо проверок на `null` — объект-заглушка с дефолтным поведением.

### Replace Exception with Test
Исключение для контролируемой ситуации → проверка условия.

## Making Method Calls Simpler

### Rename Method ⭐
Имя не отражает поведение → переименовать.

### Add / Remove Parameter
Метод нуждается в новой инфе → добавить параметр (или Parameter Object при > 4).

### Introduce Parameter Object ⭐
Долгий список параметров → DTO.
```php
// плохо
public function search(string $q, int $page, int $size, array $filters, string $sort): SearchResult

// хорошо
public function search(SearchQuery $query): SearchResult
```

### Replace Parameter with Method Call
Параметр всегда вычисляется одинаково → убрать его, вычислять внутри.

## Generalization

### Pull Up Method / Field
Метод дублируется в подклассах → переместить в родителя.

### Push Down Method / Field
Метод нужен только одному подклассу → переместить вниз.

### Extract Superclass / Interface
Два класса дублируются / должны быть взаимозаменяемы → выделить общий родитель / интерфейс.

### Replace Inheritance with Delegation
«Наследник от родителя только использует часть» → перейти на композицию.

## Big Refactorings

> Долгие — не делаются за один присест. Идут по плану в `decisions.md`.

- **Tease Apart Inheritance** — две оси изменений в одной иерархии → разделить
- **Convert Procedural Design to Objects** — процедурная мешанина → объектная модель
- **Separate Domain from Presentation** — Blade/Vue не должен знать про БД, Service не должен про HTTP
- **Extract Hierarchy** — один класс с условиями типа → иерархия

## Когда применять

В `/review` и `/refactor` всегда сверяйся с `code-smells.md` и предлагай конкретные приёмы из этого списка.
В `/refactor <technique> <path>` — `<technique>` это ID отсюда: `extract-method`, `guard-clauses`, `replace-conditional-with-polymorphism`, `introduce-parameter-object` и т.д.
