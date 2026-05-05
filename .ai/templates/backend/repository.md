# Template: Repository

## Базовая структура

```php
<?php

declare(strict_types=1);

namespace App\Repositories\<DOMAIN>;

use App\DTO\<DOMAIN>\Create<ENTITY>DTO;
use App\Enums\<DOMAIN>\<ENTITY>Status;
use App\Exceptions\<DOMAIN>\<ENTITY>NotFoundException;
use App\Models\<ENTITY>;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;

final readonly class <ENTITY>Repository
{
    public function find(int $id): ?<ENTITY>
    {
        return <ENTITY>::query()->find($id);
    }

    public function findOrFail(int $id): <ENTITY>
    {
        return $this->find($id) ?? throw new <ENTITY>NotFoundException($id);
    }

    public function create(Create<ENTITY>DTO $dto): <ENTITY>
    {
        return <ENTITY>::query()->create([
            'name'   => $dto->name,
            'status' => <ENTITY>Status::Pending,
        ]);
    }

    public function markPaid(<ENTITY> $entity, string $receipt): <ENTITY>
    {
        $entity->update([
            'status'         => <ENTITY>Status::Paid,
            'paid_at'        => now(),
            'payment_receipt' => $receipt,
        ]);

        return $entity->fresh();
    }

    /**
     * @return Collection<int, <ENTITY>>
     */
    public function pendingForCustomer(int $customerId): Collection
    {
        return <ENTITY>::query()
            ->where('customer_id', $customerId)
            ->where('status', <ENTITY>Status::Pending)
            ->orderByDesc('created_at')
            ->get();
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, <ENTITY>>
     */
    public function paginate(array $filters, int $perPage = 20): LengthAwarePaginator
    {
        return <ENTITY>::query()
            ->when($filters['status'] ?? null, fn ($q, $status) => $q->where('status', $status))
            ->when($filters['customer_id'] ?? null, fn ($q, $id) => $q->where('customer_id', $id))
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }
}
```

## С кастомным Builder

```php
<?php

declare(strict_types=1);

namespace App\Models\Builders;

use App\Enums\<DOMAIN>\<ENTITY>Status;
use Illuminate\Database\Eloquent\Builder;

/**
 * @template TModel of \App\Models\<ENTITY>
 * @extends Builder<TModel>
 */
final class <ENTITY>Builder extends Builder
{
    public function paid(): self
    {
        return $this->where('status', <ENTITY>Status::Paid);
    }

    public function inLastDays(int $days): self
    {
        return $this->where('created_at', '>=', now()->subDays($days));
    }
}
```

В `<ENTITY>::class`:
```php
public function newEloquentBuilder($query): <ENTITY>Builder
{
    return new <ENTITY>Builder($query);
}
```

В Repository:
```php
public function paidInLastWeek(): Collection
{
    return <ENTITY>::query()->paid()->inLastDays(7)->get();
}
```

## Правила

- `final readonly class`
- **Только** здесь — Eloquent / DB / Query Builder
- Имена методов — по бизнес-намерению (`paidForCustomer`), не по технике (`whereStatusAndCustomerId`)
- Возврат — Model / Collection / DTO / Paginator
- N+1 предотвращать — `with()`, `withCount()`
- Magic strings (`'status'`) — заменять enum/const
- **Нет:** HTTP, бизнес-исключений (только NotFound-типа), local/global scopes (см. `.ai/rules/backend/eloquent.md`)
- **Есть:** Eloquent, Builder, DB::transaction *(если транзакция чисто DB-уровневая)*

## См. также

- `.ai/rules/backend/eloquent.md` — `tap`, `when`, custom Builder, eager loading, query optimization
- `.ai/templates/backend/dto.md` — DTO для read-моделей и параметров
- ADR-0002 — почему вообще Repository pattern
