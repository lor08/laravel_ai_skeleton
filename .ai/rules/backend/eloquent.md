# Eloquent — правила и идиомы

Запросы к БД — **только** в `App\Repositories` (см. ADR-0002). Этот файл — про то, **как** писать эти запросы.

## Чего избегаем

### ❌ Local scopes (`scopeActive`, `scopePublished`)
Магия с автоматическим вызовом методов через `Order::active()` снижает читаемость и заставляет читателя помнить, какой scope где определён. Используем явные методы Repository или Builder вместо.

### ❌ Global scopes (`addGlobalScope`)
Скрытая логика, которая стреляет в каждом запросе. Особенно вредно при отладке странных WHERE-conditions. Если нужна общая фильтрация — явный метод репозитория, или middleware на уровне модуля.

### ❌ Magic helpers
Глобальные `tap()`, `optional()`, `data_get()` — запрещены (см. `code-style.md`). Метод `Builder::tap()` — разрешён, это другое (см. ниже).

## Что используем

### `->when()` для условных where

Вместо `if`-цепочек:

```php
// плохо
$query = Order::query();
if ($filters['status'] ?? null) {
    $query->where('status', $filters['status']);
}
if ($filters['customer_id'] ?? null) {
    $query->where('customer_id', $filters['customer_id']);
}
if ($filters['period'] ?? null) {
    $query->whereBetween('created_at', $filters['period']);
}

// хорошо
$query = Order::query()
    ->when($filters['status'] ?? null, fn ($q, $status) => $q->where('status', $status))
    ->when($filters['customer_id'] ?? null, fn ($q, $id) => $q->where('customer_id', $id))
    ->when($filters['period'] ?? null, fn ($q, $period) => $q->whereBetween('created_at', $period));
```

`->when($value, $cb)` применяет callback **только если value truthy**. Это нативный chainable аналог if.

### `Builder::tap()` для chainable побочных модификаций

Когда нужно применить группу where-условий, но не разрывать chain:

```php
$orders = Order::query()
    ->where('status', OrderStatus::Paid)
    ->tap(fn ($q) => $this->applyVisibilityRules($q))
    ->orderByDesc('paid_at')
    ->get();

private function applyVisibilityRules(Builder $query): void
{
    $query->where('domain_id', $this->currentDomainId);
    $query->whereNull('hidden_at');
}
```

`tap` возвращает оригинальный объект независимо от того, что вернул callback — chain не рвётся.

**Не путать** с глобальным хелпером `tap()` — он запрещён. `Builder::tap()` / `Collection::tap()` — это методы, разрешены.

### Custom Eloquent Builder

Когда у модели много связанных запросов с одинаковыми условиями, и они нужны в нескольких репозиториях — выноси в отдельный Builder:

```php
<?php

declare(strict_types=1);

namespace App\Models\Builders;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Builder;

/**
 * @template TModel of \App\Models\Order
 * @extends Builder<TModel>
 */
final class OrderBuilder extends Builder
{
    public function paid(): self
    {
        return $this->where('status', OrderStatus::Paid);
    }

    public function inLastDays(int $days): self
    {
        return $this->where('created_at', '>=', now()->subDays($days));
    }

    public function forCustomer(int $customerId): self
    {
        return $this->where('customer_id', $customerId);
    }
}
```

В `Order::class`:
```php
public function newEloquentBuilder($query): OrderBuilder
{
    return new OrderBuilder($query);
}
```

В Repository:
```php
public function paidInLastWeek(int $customerId): Collection
{
    return Order::query()
        ->forCustomer($customerId)
        ->paid()
        ->inLastDays(7)
        ->orderByDesc('paid_at')
        ->get();
}
```

Это **не** local scope: метод явно объявлен на типизированном `Builder`-классе, его видит IDE и PHPStan.

### Eager loading — обязательно

N+1 — самая частая причина медленных страниц. Профилактика:

```php
// плохо: N+1
$orders = Order::query()->limit(20)->get();
foreach ($orders as $order) {
    echo $order->customer->name;            # query на каждый
    echo $order->items->count();            # ещё один query
}

// хорошо
$orders = Order::query()
    ->with(['customer', 'items'])
    ->limit(20)
    ->get();

// или с подсчётом, без подгрузки коллекции
$orders = Order::query()
    ->with('customer')
    ->withCount('items')
    ->limit(20)
    ->get();

// или агрегат
$orders = Order::query()
    ->with('customer')
    ->withSum('items', 'price')
    ->limit(20)
    ->get();
```

**Правило:** в репозитории — eager load всё, что заведомо понадобится потребителю. Если потребитель использует только часть — выноси в отдельный метод репозитория.

### `whereBelongsTo()` / `whereRelation()`

Современные альтернативы цепочкам:

```php
// плохо
$orders = Order::query()->where('customer_id', $customer->id)->get();

// хорошо
$orders = Order::query()->whereBelongsTo($customer)->get();

// плохо
$orders = Order::query()
    ->whereHas('items', fn ($q) => $q->where('sku', 'X'))
    ->get();

// хорошо
$orders = Order::query()->whereRelation('items', 'sku', 'X')->get();
```

### Pagination

```php
// LengthAwarePaginator — для UI с total / pages
return Order::query()
    ->with('customer')
    ->paginate($perPage);

// CursorPaginator — для бесконечного скролла / API
return Order::query()
    ->orderBy('id')
    ->cursorPaginate($perPage);

// SimplePaginator — без подсчёта total (быстрее на больших таблицах)
return Order::query()->simplePaginate($perPage);
```

### Большие выборки — `lazy()` / `chunk()` / `cursor()`

```php
// плохо: всё в память
$orders = Order::query()->where('status', 'pending')->get();   # MOO!

// хорошо: чанки по 100, generator-based
foreach (Order::query()->where('status', 'pending')->lazy(100) as $order) {
    $this->process($order);
}

// или явный chunk
Order::query()->where('status', 'pending')->chunkById(100, function ($chunk) {
    foreach ($chunk as $order) {
        $this->process($order);
    }
});
```

**`chunkById`** безопаснее `chunk` для апдейтов — `chunk` сбивает `LIMIT/OFFSET` если изменяешь данные в процессе.

### Конкретные SELECT'ы

```php
// плохо: SELECT * на огромной таблице
$emails = User::query()->where('active', true)->get()->pluck('email');

// хорошо
$emails = User::query()->where('active', true)->pluck('email');

// или через select()
$users = User::query()
    ->select(['id', 'email', 'name'])
    ->where('active', true)
    ->get();
```

`pluck()` — возвращает Collection одной колонки, без гидрации Model'ей.

### Транзакции

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function () use ($dto): Order {
    $order = $this->repository->create($dto);
    $this->events->dispatch(new OrderCreated($order));
    return $order;
});
```

- Транзакция в **Service**, не в Repository / Controller
- Минимум кода внутри (никакого HTTP, никаких внешних API)
- При вложенных вызовах Laravel использует savepoints — можно безопасно вкладывать

### Locking

```php
DB::transaction(function () use ($id): Order {
    $order = Order::query()
        ->where('id', $id)
        ->lockForUpdate()
        ->firstOrFail();

    $order->status = OrderStatus::Paid;
    $order->save();

    return $order;
});
```

`->lockForUpdate()` — pessimistic lock, для конкурентных update'ов одной строки.

### Raw — только когда без него никак

```php
// не любим, но иногда надо
DB::table('orders')
    ->select(DB::raw('DATE(created_at) as day'), DB::raw('COUNT(*) as cnt'))
    ->groupBy('day')
    ->get();
```

`DB::raw` — последний резерв. Если используешь — обязательно через bindings, не склейкой строк.

```php
// плохо — SQL injection
$orders = DB::select("SELECT * FROM orders WHERE customer_id = $customerId");

// хорошо
$orders = DB::select('SELECT * FROM orders WHERE customer_id = ?', [$customerId]);
```

## Чек-лист в `/review` для Eloquent-кода

- [ ] Запрос только в Repository, не в Controller / Service / Model
- [ ] Eager load для всех related, к которым потребитель обращается
- [ ] N+1 проверен — `Pail` / Telescope / `DB::listen()` в dev
- [ ] Условия — через `->when()`, не if-цепочка
- [ ] Magic strings (`'paid'`, `'active'`) → enum / const
- [ ] Custom Builder если методы повторяются
- [ ] Tap для chainable модификаций, не временные переменные
- [ ] `lockForUpdate()` для конкурентных апдейтов
- [ ] Большие выборки — `lazy` / `chunkById`, не `get`
- [ ] Транзакции в Service, минимум кода внутри
