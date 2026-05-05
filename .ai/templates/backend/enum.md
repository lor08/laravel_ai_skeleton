# Template: Enum

## Базовый backed enum

```php
<?php

declare(strict_types=1);

namespace App\Enums\<DOMAIN>;

enum <ENTITY>Status: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Shipped = 'shipped';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';
}
```

## С поведением

```php
<?php

declare(strict_types=1);

namespace App\Enums\<DOMAIN>;

enum <ENTITY>Status: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Shipped = 'shipped';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';

    public function isFinal(): bool
    {
        return match ($this) {
            self::Delivered, self::Cancelled => true,
            self::Pending, self::Paid, self::Shipped => false,
        };
    }

    public function canTransitionTo(self $next): bool
    {
        return match ([$this, $next]) {
            [self::Pending, self::Paid],
            [self::Pending, self::Cancelled],
            [self::Paid, self::Shipped],
            [self::Paid, self::Cancelled],
            [self::Shipped, self::Delivered] => true,
            default => false,
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::Pending   => 'Awaiting payment',
            self::Paid      => 'Paid, processing',
            self::Shipped   => 'Shipped',
            self::Delivered => 'Delivered',
            self::Cancelled => 'Cancelled',
        };
    }
}
```

## Как кастить в Eloquent

```php
final class Order extends Model
{
    protected $casts = [
        'status' => OrderStatus::class,
    ];
}
```

## В FormRequest

```php
'status' => ['required', Rule::enum(<ENTITY>Status::class)],
```

## Правила

- Расположение: `app/Enums/<Domain>/` или `app/Modules/<Module>/Enums/`
- Backed enum со `: string` (или `: int` для битовых масок)
- Case names — `PascalCase`
- Backing values — `snake_case` или `kebab-case`
- Логика в enum — match/return, без длинных `if`
- Поведение, специфичное для одного use-case — в Service, не в Enum

## Architecture test

```php
arch('enums are real enums')
    ->expect('App\Enums')
    ->toBeEnums();
```
