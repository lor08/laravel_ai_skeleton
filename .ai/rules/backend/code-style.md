# Backend Code Style (PHP 8.5 / Laravel 13)

## Жёсткие правила (нарушение блокирует merge через arch tests / hooks)

### `declare(strict_types=1);`
Каждый PHP-файл, **первая строка после `<?php`**, без пробелов.

```php
<?php

declare(strict_types=1);

namespace App\Services;
```

### `final class` / `final readonly class` по умолчанию
Все доменные/сервисные классы `final`. `readonly` — там, где состояние не меняется (DTO, VO, сервисы без мутирующих полей).

Исключения (не финальные): абстрактные классы, базовые контроллеры/моделей, явно расширяемые классы. Их явно перечислить в `tests/Architecture/FinalClassesTest.php` через `ignoring()`.

```php
final class OrderController extends Controller
final readonly class CreateOrderService
final readonly class OrderDTO
```

### Без inline-комментариев в PHP-коде
**Запрещено:** `// что-то делает X`.
**Разрешено:**
- PHPDoc только с типами (`@param`, `@return`, `@throws`, `@var`, `{@inheritDoc}`)
- Аннотации статанализа (`// @phpstan-ignore-next-line`, `// @phpcs:disable`)

### Без описаний в PHPDoc
PHPDoc нужен **только для типов**, которые PHP не может выразить (массивы с дженериками, generic templates).

```php
// Запрещено
/**
 * Returns IDs filtered by parameters.
 *
 * @param array<string, mixed> $filters Filter parameters
 * @return int[] Array of matching IDs
 */
public function getIds(array $filters): array

// Правильно
/**
 * @param array<string, mixed> $filters
 * @return int[]
 */
public function getIds(array $filters): array
```

### Только Facades, без global helpers
**Запрещено:** `trans()`, `view()`, `redirect()`, `app()`, `config()`, `abort()`, `auth()`, `request()`, `now()`, `cache()`, `session()`, `back()`, `response()`, `route()`, `asset()`, `url()`, `env()` *(кроме `config/`)*, `dispatch()`, `event()`, `logger()`, `optional()`, `tap()`, `collect()`, `info()`, `action()`, `old()`, `csrf_token()`, `data_get()`, `data_set()`, `*_path()`.

**Правильно:** facades `Illuminate\Support\Facades\*`.

```php
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Lang;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;

Config::get('services.payment.key');
Cache::store('redis')->remember($key, $ttl, fn () => $value);
Log::warning('Order failed', ['order_id' => $order->id]);
Auth::user();
Lang::get('orders.created');
```

Хук `.claude/hooks/no-laravel-helpers.sh` блокирует помещения хелперов в `.php` (кроме `.blade.php`).

### `$request->validated()` вместо `$request->all()`
Контроллер получает данные **только** из `validated()` после FormRequest.

### Без вложенных `if`
Глубина — 1 уровень. Вместо вложенности — early return / Guard Clauses (см. `refactoring-techniques.md`).

### DTO на boundaries
Между слоями (FormRequest → Service, Service → внешний API, Job ← Service) — DTO/VO, не `array<string, mixed>`.

## Class member ordering

```
1. Constants (public → protected → private)
2. Properties (public → protected → private)
3. Methods (public → protected → private)
   3a. Static factory methods первые в группе public
```

```php
final class Order
{
    public const STATUS_PAID = 'paid';
    private const MAX_ITEMS = 50;

    public string $number;
    private array $items = [];

    public static function fromDTO(OrderDTO $dto): self { ... }
    public function pay(): void { ... }
    private function validate(): void { ... }
}
```

## PHP 8.5 идиомы

### Pipe operator `|>`
Цепочки трансформаций — через `|>`, не через временные переменные.

```php
// плохо
$temp = trim($input);
$temp = strtolower($temp);
$temp = str_replace('_', '-', $temp);
$slug = $temp;

// хорошо
$slug = $input
    |> trim(...)
    |> strtolower(...)
    |> (fn (string $s) => str_replace('_', '-', $s));
```

### Property hooks (PHP 8.4+)
Для virtual properties и валидации без бойлерплейта.

```php
final class Person
{
    public string $fullName {
        get => "{$this->firstName} {$this->lastName}";
    }

    public string $email {
        set {
            if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                throw new InvalidArgumentException('Invalid email');
            }
            $this->email = strtolower($value);
        }
    }
}
```

### Asymmetric visibility
`public private(set)` — публичное чтение, приватная запись.

```php
final class Counter
{
    public function __construct(
        public private(set) int $value = 0,
    ) {}

    public function increment(): void
    {
        $this->value++;
    }
}
```

### Named arguments
Используй для методов с > 2 опциональных параметров — повышает читаемость.

```php
$user = User::create(
    email: $dto->email,
    name: $dto->name,
    role: UserRole::Member,
    locale: $dto->locale,
);
```

### Enums с поведением
```php
enum OrderStatus: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Cancelled = 'cancelled';

    public function isFinal(): bool
    {
        return match ($this) {
            self::Paid, self::Cancelled => true,
            self::Pending => false,
        };
    }
}
```

## Имена

| Тип | Стиль |
|---|---|
| Class | `PascalCase` (`OrderController`, `CreateOrderService`) |
| Method / property | `camelCase` |
| Constant | `UPPER_SNAKE_CASE` |
| Variable | `camelCase` |
| Enum case | `PascalCase` |
| Database table | `snake_case` plural (`orders`, `order_items`) |
| Database column | `snake_case` |
| Migration file | timestamp + `snake_case` (`2026_05_01_120000_create_orders_table.php`) |

## Suffixes

| Слой | Суффикс |
|---|---|
| Controller | `Controller` |
| FormRequest | `Request` |
| Resource | `Resource` |
| Service | `Service` |
| Repository | `Repository` |
| Job | `Job` |
| Event | `Event` |
| Listener | `Listener` |
| Exception | `Exception` |
| DTO | `DTO` или `Dto` (выбрать один стиль; default: `DTO`) |

## Магические числа

Числа кроме `0`, `1`, `-1`, `2` — в `private const` со смысловым именем.
Хук `php-magic-numbers.sh` подсветит.

## PHPStan / Larastan

- Уровень: `max` (10)
- Larastan для понимания Eloquent
- `phpstan-baseline.neon` — для постепенного ужесточения

## ECS

Конфиг — `ecs.php`. Запуск:
```bash
<RUN-CMD> ecs check          # проверка
<RUN-CMD> ecs check --fix    # авто-фикс
```
