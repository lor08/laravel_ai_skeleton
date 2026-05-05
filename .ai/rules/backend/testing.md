# Backend Testing (Pest 3)

## Структура

```
tests/
├── Pest.php                  ← глобальные uses(), expect()-расширения
├── Architecture/             ← arch-тесты (правила в виде тестов)
│   ├── StrictTypesTest.php
│   ├── FinalClassesTest.php
│   ├── LayerBoundariesTest.php
│   └── NamingConventionsTest.php
├── Unit/                     ← чистые юнит-тесты (без БД, без HTTP)
└── Feature/                  ← с БД (in-memory sqlite или test mysql)
```

## Запуск

```bash
<RUN-CMD> pest                       # всё
<RUN-CMD> pest --arch                # только архитектурные
<RUN-CMD> pest --parallel            # параллельно
<RUN-CMD> pest --type-coverage       # type coverage
<RUN-CMD> pest --mutate              # mutation testing (если включено)
<RUN-CMD> pest --filter=OrderTest    # фильтр
<RUN-CMD> pest tests/Feature/Orders  # директория

# Через composer scripts:
composer arch
composer test
composer types
composer mutate
```

## Architecture tests — главное оружие

Кодифицируем правила проекта как тесты, которые блокируют CI.

### `StrictTypesTest.php`

```php
arch('all PHP files use strict types')
    ->expect('App')
    ->toUseStrictTypes();
```

### `FinalClassesTest.php`

```php
arch('all classes are final')
    ->expect('App')
    ->classes
    ->toBeFinal()
    ->ignoring([
        'App\Http\Controllers\Controller',
        'App\Models',                      // models часто extends, ok
        'App\Exceptions',
    ]);
```

### `LayerBoundariesTest.php`

```php
arch('controllers are thin')
    ->expect('App\Http\Controllers')
    ->toBeFinal()
    ->toHaveSuffix('Controller')
    ->not->toUse([
        'Illuminate\Support\Facades\DB',
        'Illuminate\Database\Eloquent\Builder',
    ]);

arch('repositories never know about HTTP')
    ->expect('App\Repositories')
    ->not->toUse([
        'Illuminate\Http\Request',
        'Illuminate\Http\Response',
    ]);

arch('models stay in their lane')
    ->expect('App\Models')
    ->not->toBeUsedIn('App\Http\Controllers');

arch('services use repositories, not eloquent directly')
    ->expect('App\Services')
    ->not->toUse(['Illuminate\Database\Eloquent\Builder']);

arch('no helpers in PHP code')
    ->expect('App')
    ->not->toUse([
        'trans', 'view', 'redirect', 'app', 'config',
        'abort', 'auth', 'request', 'now', 'cache',
        'session', 'back', 'response', 'route', 'asset',
        'url', 'env', 'dispatch', 'event', 'logger',
        'optional', 'tap', 'collect', 'info', 'action',
        'old', 'csrf_token', 'data_get', 'data_set',
    ]);
```

### `NamingConventionsTest.php`

```php
arch('controllers have Controller suffix')
    ->expect('App\Http\Controllers')
    ->toHaveSuffix('Controller');

arch('form requests have Request suffix')
    ->expect('App\Http\Requests')
    ->toHaveSuffix('Request')
    ->toExtend('Illuminate\Foundation\Http\FormRequest');

arch('services have Service suffix')
    ->expect('App\Services')
    ->toHaveSuffix('Service');

arch('repositories have Repository suffix')
    ->expect('App\Repositories')
    ->toHaveSuffix('Repository');

arch('jobs have Job suffix and implement ShouldQueue')
    ->expect('App\Jobs')
    ->toHaveSuffix('Job')
    ->toImplement('Illuminate\Contracts\Queue\ShouldQueue');

arch('enums are enums')
    ->expect('App\Enums')
    ->toBeEnums();

arch('DTOs are readonly')
    ->expect('App\DTO')
    ->classes->toBeReadonly()
    ->classes->toBeFinal();
```

## Unit-тесты — стиль Pest

```php
use App\DTO\CreateOrderDTO;
use App\Services\CreateOrderService;

beforeEach(function () {
    $this->orders    = mock(OrderRepository::class);
    $this->customers = mock(CustomerRepository::class);
    $this->events    = mock(DispatcherContract::class);
    $this->service   = new CreateOrderService(
        $this->orders, $this->customers, $this->events
    );
});

it('creates an order for an existing customer', function () {
    $dto = new CreateOrderDTO(customerId: 1, itemIds: [10, 11]);
    $customer = Customer::factory()->make(['id' => 1]);

    $this->customers->expects('find')->with(1)->andReturn($customer);
    $this->orders->expects('create')->andReturn(Order::factory()->make());
    $this->events->expects('dispatch');

    expect($this->service->create($dto))->toBeInstanceOf(Order::class);
});

it('fails when customer does not exist', function () {
    $this->customers->expects('find')->with(999)->andReturn(null);

    expect(fn () => $this->service->create(new CreateOrderDTO(999, [])))
        ->toThrow(CustomerNotFoundException::class);
});
```

## Feature-тесты

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('creates an order via API', function () {
    $customer = Customer::factory()->create();

    $response = $this->actingAs(User::factory()->create())
        ->postJson('/api/orders', [
            'customer_id' => $customer->id,
            'items'       => [['id' => 1]],
        ]);

    $response->assertCreated();
    expect(Order::count())->toBe(1);
});
```

## Datasets (параметризация)

```php
it('validates email', function (string $input, bool $valid) {
    expect(fn () => new Email($input))->{$valid ? 'not->toThrow' : 'toThrow'}(InvalidArgumentException::class);
})->with([
    'valid'         => ['user@example.com', true],
    'no @'          => ['user.example.com', false],
    'empty'         => ['', false],
    'with unicode'  => ['пользователь@почта.рф', true],
]);
```

## Higher-order tests

```php
it('returns 200 on health check')->get('/health')->assertOk();

expect([1, 2, 3])->each->toBeInt()->toBeGreaterThan(0);
```

## Mutation testing (опционально)

Включается флагом в `init.sh`. Запуск:
```bash
composer mutate
```

В CI — отдельный (медленный) job. Минимальный MSI начинай с 60–70%, повышай со временем.

## Type coverage

```bash
<RUN-CMD> pest --type-coverage --min=95
```

В CI — обязательно. Минимум 95% типизации.

## Когда писать тесты

| Слой | Тесты |
|---|---|
| Controller | Feature (один happy + edge cases) |
| Service | Unit (моки на репозитории), Feature (полный happy path) |
| Repository | Feature (с реальной БД, обычно без моков) |
| Job | Unit (моки) + Feature (`Bus::fake()`) |
| Event/Listener | Unit или Feature (`Event::fake()`) |
| FormRequest | Feature (через endpoint) или Unit (`$request->validate()` напрямую) |
| Resource | Unit (snapshot или explicit fields) |
| DTO/VO | Unit |

## Test factories

Используй `Database\Factories\*` для всех моделей. В каждой фабрике как минимум:
- `definition()` — дефолты
- `state()` для часто-используемых вариантов (`paid()`, `cancelled()`, `forCustomer()`)

## Именование

- File: `{ClassUnderTest}Test.php` для unit / `{Feature}Test.php` для feature
- Test description: `it('does X when Y')` или `test('describes the scenario')`
- Не префикс `test_`, не `should_`. По-английски, в imperative
