# Code Smells

Источник: <https://refactoring.guru/ru/refactoring/smells>

Список «запахов» с быстрыми эвристиками для агента. Полные определения и приёмы — по ссылкам.

## Bloaters

### Long Method (Длинный метод)
**Эвристика:** метод > 20 строк или > 1 уровня вложенности.
**Лечение:** Extract Method, Replace Temp with Query, Decompose Conditional.
**Связь с хуками:** `php-method-length.sh` (warn > 30).

### Large Class (Большой класс)
**Эвристика:** класс > 200 строк или > 10 публичных методов.
**Лечение:** Extract Class, Extract Subclass, Replace Type Code with Class.
**Связь с хуками:** `php-class-length.sh` (warn > 300).

### Primitive Obsession
**Эвристика:** строки/числа там, где должен быть Value Object или Enum.
**Лечение:** Replace Data Value with Object, Replace Type Code with Enum.
**В PHP:** native `enum`, readonly классы для VO.
**Пример:**
```php
// плохо
public function applyDiscount(string $code, int $percent): void

// хорошо
public function applyDiscount(DiscountCode $code, Percent $percent): void
```

### Long Parameter List
**Эвристика:** > 4 параметров.
**Лечение:** Introduce Parameter Object (DTO), Preserve Whole Object.
**Связь с хуками:** `php-too-many-params.sh` (warn > 4).

### Data Clumps
**Эвристика:** одни и те же группы параметров появляются в разных методах.
**Лечение:** Extract Class — собрать их в один объект (DTO / VO).

## OO Abusers

### Switch Statements
**Эвристика:** `match` / `switch` по типу или enum, который повторяется в разных местах.
**Лечение:** Replace Conditional with Polymorphism, Strategy pattern, реестр обработчиков.

### Refused Bequest
**Эвристика:** наследник игнорирует часть наследства родителя.
**Лечение:** Replace Inheritance with Delegation, Extract Superclass.

### Alternative Classes with Different Interfaces
**Эвристика:** два класса делают одно, но называют методы по-разному.
**Лечение:** Rename Method, Move Method, Extract Superclass.

## Change Preventers

### Divergent Change
**Эвристика:** один класс часто правят по разным причинам (нарушение SRP).
**Лечение:** Extract Class — разделить по осям изменений.

### Shotgun Surgery
**Эвристика:** одно изменение требует править много классов.
**Лечение:** Move Method/Field — собрать связанное в один класс.

### Parallel Inheritance Hierarchies
**Эвристика:** добавление подкласса в одной иерархии вынуждает добавить в другой.
**Лечение:** Move Method/Field, объединить иерархии через делегирование.

## Dispensables

### Comments
**Эвристика:** комментарий объясняет, **что** делает код (не зачем).
**Лечение:** Extract Method (имя метода становится «комментарием»), Rename Variable, Introduce Assertion.
**В нашем стиле:** inline-комментарии в PHP **запрещены** (хук блокирует).

### Duplicate Code
**Лечение:** Extract Method, Extract Class, Pull Up Method.
**Принцип:** Rule of Three — на третье повторение пора рефакторить.

### Lazy Class
**Эвристика:** класс ничего не делает.
**Лечение:** Inline Class.

### Data Class
**Эвристика:** класс из одних геттеров/сеттеров без поведения.
**Лечение:** Move Method — перенести поведение туда, где данные.
**Исключение:** DTO/VO (намеренно «тупые», это не запах).

### Dead Code
**Эвристика:** код не вызывается / закомментирован / TODO без даты.
**Лечение:** Delete. Без сожаления — git помнит.

### Speculative Generality
**Эвристика:** «pluggable», «extension point», «hook» без реальных потребителей.
**Лечение:** Inline Class, удалить hook без потребителей.

## Couplers

### Feature Envy
**Эвристика:** метод обращается к данным другого объекта чаще, чем к своим.
**Лечение:** Move Method.

### Inappropriate Intimacy
**Эвристика:** два класса знают друг о друге слишком много (приватные поля, внутренности).
**Лечение:** Move Method/Field, Extract Class, инкапсуляция.

### Message Chains
**Эвристика:** `$a->b()->c()->d()->e()` — Law of Demeter нарушен.
**Лечение:** Hide Delegate, Move Method.

### Middle Man
**Эвристика:** класс только делегирует, ничего сам не делает.
**Лечение:** Remove Middle Man, Inline Method.

## Чек-лист в /review

Пройдись по списку для каждого затронутого класса/метода — отметь, какие запахи нашёл, поставь severity (P1/P2/P3) и предложи варианты лечения.
