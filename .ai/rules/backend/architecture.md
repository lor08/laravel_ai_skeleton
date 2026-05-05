# Backend Architecture

## Слои

```
HTTP Request
    ↓
FormRequest (validation + authorize)
    ↓
Controller (тонкий — только маршрутизация)
    ↓
Service (бизнес-логика, транзакции)
    ↓
Repository (доступ к БД, query builder)
    ↓
Eloquent Model (без бизнес-логики)
    ↓
Database
```

Каждый слой **знает только о слое ниже**. Контроллер не лезет в Eloquent. Repository не знает про HTTP. Model не вызывает Service.

## Контроллер

- `final class`
- Один публичный метод на endpoint (Single Action) или RESTful resource
- Внутри метода: `$dto = $request->validated()` → `$service->doSomething($dto)` → `return ...`
- Никаких `DB::`, `Eloquent::`, `Cache::`, бизнес-логики, math
- Авторизация — в FormRequest через `authorize()` или через `$this->authorize()`

```php
final class CreateOrderController extends Controller
{
    public function __invoke(
        CreateOrderRequest $request,
        CreateOrderService $service,
    ): OrderResource {
        $dto = CreateOrderDTO::fromRequest($request);
        $order = $service->create($dto);

        return OrderResource::make($order);
    }
}
```

## FormRequest

- `final class`
- `authorize()` — проверка прав
- `rules()` — валидация
- Опционально: метод `toDto(): SomeDTO` для прозрачного перехода

```php
final class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return Auth::user()?->can('order.create') ?? false;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'items'       => ['required', 'array', 'min:1'],
            'items.*.id'  => ['required', 'integer'],
        ];
    }

    public function toDto(): CreateOrderDTO
    {
        return CreateOrderDTO::fromArray($this->validated());
    }
}
```

## Service

- `final readonly class`
- Конструктор — все зависимости (DI)
- Один сервис = одна бизнес-операция (или близкая группа)
- Транзакции внутри сервиса, не в контроллере
- Бросает `DomainException` (свой) при бизнес-ошибках

```php
final readonly class CreateOrderService
{
    public function __construct(
        private OrderRepository $orders,
        private CustomerRepository $customers,
        private DispatcherContract $events,
    ) {}

    public function create(CreateOrderDTO $dto): Order
    {
        $customer = $this->customers->find($dto->customerId)
            ?? throw new CustomerNotFoundException($dto->customerId);

        return DB::transaction(function () use ($dto, $customer) {
            $order = $this->orders->create($dto, $customer);
            $this->events->dispatch(new OrderCreated($order));
            return $order;
        });
    }
}
```

## Repository

- `final readonly class`
- Доступ к БД — **только** здесь
- Возвращает Models, Collections, или DTO/VO для read-моделей
- Кастомный Builder — если запросы сложные и переиспользуются

```php
final readonly class OrderRepository
{
    public function find(int $id): ?Order
    {
        return Order::query()->find($id);
    }

    public function create(CreateOrderDTO $dto, Customer $customer): Order
    {
        return Order::query()->create([
            'customer_id' => $customer->id,
            'number'      => $dto->generateNumber(),
            'total'       => $dto->total(),
        ]);
    }

    /**
     * @return Collection<int, Order>
     */
    public function paidIn(DatePeriod $period): Collection
    {
        return Order::query()
            ->where('status', OrderStatus::Paid)
            ->whereBetween('paid_at', [$period->start, $period->end])
            ->get();
    }
}
```

## Model

- Eloquent — **только** маппинг таблицы
- `$fillable`, `$casts`, relations
- Без бизнес-логики (не `->confirm()`, не `->calculateTotal()`)
- Кастомные scopes — допустимы
- Геттеры/property hooks для производных полей — допустимы (PHP 8.4+)

## DTO / Value Object

- `final readonly class` с typed properties в конструкторе
- Statической фабрики для частых случаев (`fromRequest`, `fromArray`, `fromModel`)
- Без зависимостей (никаких `Service`, никаких `DB`)
- Опционально — `toArray(): array<string, mixed>` для сериализации

```php
final readonly class CreateOrderDTO
{
    /**
     * @param int[] $itemIds
     */
    public function __construct(
        public int $customerId,
        public array $itemIds,
        public ?string $promoCode = null,
    ) {}

    /**
     * @param array<string, mixed> $data
     */
    public static function fromArray(array $data): self
    {
        return new self(
            customerId: (int) $data['customer_id'],
            itemIds:    array_map('intval', $data['item_ids'] ?? []),
            promoCode:  $data['promo_code'] ?? null,
        );
    }
}
```

## Module pattern (опционально, для крупных проектов)

```
app/Modules/{ModuleName}/
├── Console/           # Artisan commands
├── Contracts/         # Interfaces
├── DTO/               # Module-specific DTOs
├── Enums/             # Module-specific enums
├── Events/
├── Exceptions/        # DomainExceptions
├── Jobs/              # Module-specific jobs
├── Listeners/
├── Providers/         # Service providers (binding в register())
├── Repositories/      # Data access
├── Services/          # Business logic
├── Resources/         # API resources
└── Tests/             # Module tests (опц., если не хочется в tests/)
```

Модуль регистрирует свой `ServiceProvider`, который биндит контракты → реализации.
Между модулями взаимодействуют через **Bridge** (паттерн фасада модуля), не лезут друг другу во внутренности.

Не каждый Laravel-проект нуждается в модулях. Стартуй с плоской структуры (`app/Services/`, `app/Repositories/`), переходи на модули, когда:
- > 3–4 крупные доменные области
- Чёткие границы по бизнес-фичам
- Команда > 1 разработчик и нужны границы

ADR при переходе на модули — обязательно.

## Architecture tests (Pest)

См. `.ai/rules/backend/testing.md` и `tests/Architecture/`. Pest arch-тесты блокируют CI при нарушении границ слоёв и стиля.

## Что использовать в каком слое

| Слой | Можно | Нельзя |
|---|---|---|
| Controller | FormRequest, Service, Resource | DB, Eloquent, бизнес-логика |
| FormRequest | Auth facade, rules | DB, Service |
| Service | Repository, другие Service, DTO, Facades (Log, Event, DB::transaction) | Eloquent direct, HTTP request, View |
| Repository | Eloquent, Query Builder, DB | HTTP, бизнес-логика |
| Model | Cast, relation, scope, accessors | Service, бизнес-логика |
| DTO/VO | typed properties, фабрики | Зависимости, БД, HTTP |
| Job | Service, очередь | Direct DB, HTTP без обёртки |
| Resource | Trans, format | Бизнес-логика, query |
