# Template: DTO

## Базовый

```php
<?php

declare(strict_types=1);

namespace App\DTO\<DOMAIN>;

final readonly class Create<ENTITY>DTO
{
    /**
     * @param int[] $itemIds
     */
    public function __construct(
        public int $customerId,
        public string $name,
        public array $itemIds,
        public ?string $note = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            customerId: (int) $data['customer_id'],
            name:       (string) $data['name'],
            itemIds:    array_map('intval', $data['item_ids'] ?? []),
            note:       $data['note'] ?? null,
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'customer_id' => $this->customerId,
            'name'        => $this->name,
            'item_ids'    => $this->itemIds,
            'note'        => $this->note,
        ];
    }
}
```

## С валидацией в конструкторе (для VO-стиля)

```php
<?php

declare(strict_types=1);

namespace App\DTO\<DOMAIN>;

use InvalidArgumentException;

final readonly class Money
{
    public function __construct(
        public int $cents,
        public string $currency = 'USD',
    ) {
        if ($cents < 0) {
            throw new InvalidArgumentException('Amount cannot be negative');
        }

        if (strlen($currency) !== 3) {
            throw new InvalidArgumentException('Currency must be ISO-4217 (3 letters)');
        }
    }

    public function add(self $other): self
    {
        if ($this->currency !== $other->currency) {
            throw new InvalidArgumentException('Cannot add different currencies');
        }

        return new self($this->cents + $other->cents, $this->currency);
    }

    public function format(): string
    {
        return sprintf('%.2f %s', $this->cents / 100, $this->currency);
    }
}
```

## Из модели

```php
public static function fromModel(<ENTITY> $entity): self
{
    return new self(
        id:        $entity->id,
        name:      $entity->name,
        status:    $entity->status,
        createdAt: $entity->created_at?->toIso8601String(),
    );
}
```

## Правила

- `final readonly class`
- Все свойства — в конструкторе (constructor property promotion)
- Без зависимостей (никаких сервисов, репозиториев, фасадов)
- Static factory methods для частых случаев (`fromArray`, `fromRequest`, `fromModel`)
- Валидация — только в VO-стиле (Money, Email, Url) — для прозрачных DTO лучше валидируй в FormRequest
- `toArray()` — опционально, для сериализации
- Naming: `<Action><Entity>DTO` (`CreateOrderDTO`) или `<Entity>Snapshot` для read-моделей

## DTO vs VO

| | DTO | Value Object |
|---|---|---|
| Назначение | Перенос данных между слоями | Доменный примитив |
| Валидация | В FormRequest до создания | В конструкторе VO |
| Поведение | Минимум | Может иметь методы (add, format, equals) |
| Идентичность | По всем полям | По всем полям |
| Иммутабельность | Да | Да |

VO для: `Money`, `Email`, `Url`, `Percent`, `DateRange`, `Coordinates`.
DTO для: `CreateOrderDTO`, `UpdateUserDTO`, `OrderFilters`.
