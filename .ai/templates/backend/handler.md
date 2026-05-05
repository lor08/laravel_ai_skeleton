# Template: Handler (Strategy + tagged services)

Паттерн: набор обработчиков реализует общий контракт, регистрируется через `app->tag()`, в потребитель инжектируется `iterable` — так добавление нового типа = новый класс, без правки существующего кода (Open/Closed).

## Когда применять

✅ Несколько типов одной операции (платежи, способы доставки, экспортёры, импортёры, нотификации)
✅ Появление нового типа — частая задача, не должно требовать правок существующих классов
✅ Условие выбора обработчика однозначно вычислимо (`supports($input): bool`)

❌ Один-два варианта без перспективы роста — лишний слой
❌ Условие выбора зависит от состояния всей системы (тогда — Service с явной логикой, не Strategy)

## Структура

```
app/Modules/<Module>/
├── Contracts/
│   └── <Module>Handler.php           # interface
├── Handlers/
│   ├── <First>Handler.php
│   ├── <Second>Handler.php
│   └── <Third>Handler.php
├── Services/
│   └── <Module>Router.php            # выбирает handler и делегирует
├── DTO/
│   ├── <Module>RequestDTO.php
│   └── <Module>ResultDTO.php
├── Exceptions/
│   └── No<Module>HandlerException.php
└── Providers/
    └── <Module>ServiceProvider.php
```

## Контракт

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Contracts;

use App\Modules\Payment\DTO\PaymentRequestDTO;
use App\Modules\Payment\DTO\PaymentResultDTO;
use App\Modules\Payment\Enums\PaymentTypeEnum;

interface PaymentHandler
{
    public function supports(PaymentTypeEnum $type): bool;

    public function handle(PaymentRequestDTO $request): PaymentResultDTO;
}
```

## Реализация одного handler'а

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Handlers;

use App\Modules\Payment\Contracts\PaymentHandler;
use App\Modules\Payment\DTO\PaymentRequestDTO;
use App\Modules\Payment\DTO\PaymentResultDTO;
use App\Modules\Payment\Enums\PaymentTypeEnum;
use App\Modules\Payment\Services\StripeGateway;

final readonly class StripeHandler implements PaymentHandler
{
    public function __construct(
        private StripeGateway $gateway,
    ) {}

    public function supports(PaymentTypeEnum $type): bool
    {
        return $type === PaymentTypeEnum::Stripe;
    }

    public function handle(PaymentRequestDTO $request): PaymentResultDTO
    {
        $charge = $this->gateway->charge($request->amount, $request->token);

        return new PaymentResultDTO(
            success: $charge->success,
            transactionId: $charge->id,
        );
    }
}
```

## Router (выбор handler'а)

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Services;

use App\Modules\Payment\Contracts\PaymentHandler;
use App\Modules\Payment\DTO\PaymentRequestDTO;
use App\Modules\Payment\DTO\PaymentResultDTO;
use App\Modules\Payment\Exceptions\NoPaymentHandlerException;

final readonly class PaymentRouter
{
    /**
     * @param iterable<PaymentHandler> $handlers
     */
    public function __construct(
        private iterable $handlers,
    ) {}

    public function process(PaymentRequestDTO $request): PaymentResultDTO
    {
        foreach ($this->handlers as $handler) {
            if ($handler->supports($request->type)) {
                return $handler->handle($request);
            }
        }

        throw new NoPaymentHandlerException($request->type);
    }
}
```

## Регистрация в ServiceProvider

```php
<?php

declare(strict_types=1);

namespace App\Modules\Payment\Providers;

use App\Modules\Payment\Contracts\PaymentHandler;
use App\Modules\Payment\Handlers\CryptoHandler;
use App\Modules\Payment\Handlers\PaypalHandler;
use App\Modules\Payment\Handlers\StripeHandler;
use App\Modules\Payment\Services\PaymentRouter;
use Illuminate\Contracts\Foundation\Application;
use Illuminate\Support\ServiceProvider;

final class PaymentServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->tag([
            StripeHandler::class,
            PaypalHandler::class,
            CryptoHandler::class,
        ], 'payment.handlers');

        $this->app->bind(
            PaymentRouter::class,
            fn (Application $app) => new PaymentRouter(
                handlers: $app->tagged('payment.handlers'),
            ),
        );
    }
}
```

`$app->tagged('payment.handlers')` возвращает `iterable` — Laravel создаёт каждый handler по требованию, не пытается мгновенно резолвить всех.

## Использование

```php
final class CheckoutController extends Controller
{
    public function __invoke(
        CheckoutRequest $request,
        PaymentRouter $router,
    ): PaymentResource {
        $result = $router->process($request->toDto());

        return PaymentResource::make($result);
    }
}
```

## Тесты

```php
use App\Modules\Payment\Contracts\PaymentHandler;
use App\Modules\Payment\Services\PaymentRouter;

it('routes to the matching handler', function () {
    $matching = mock(PaymentHandler::class);
    $matching->expects('supports')->andReturn(true);
    $matching->expects('handle')->andReturn(new PaymentResultDTO(true, 'tx-1'));

    $other = mock(PaymentHandler::class);
    $other->expects('supports')->andReturn(false);

    $router = new PaymentRouter(handlers: [$other, $matching]);

    expect($router->process($request)->transactionId)->toBe('tx-1');
});

it('throws when no handler supports the request', function () {
    $router = new PaymentRouter(handlers: [
        mock(PaymentHandler::class)->expects('supports')->andReturn(false)->getMock(),
    ]);

    expect(fn () => $router->process($request))
        ->toThrow(NoPaymentHandlerException::class);
});

arch('payment handlers implement contract')
    ->expect('App\Modules\Payment\Handlers')
    ->toImplement('App\Modules\Payment\Contracts\PaymentHandler')
    ->toBeFinal()
    ->toHaveSuffix('Handler');
```

## Правила

- Контракт — `interface` в `Contracts/`
- Каждый handler — `final readonly class`
- `supports()` принимает enum / VO, не `string` / `int` (Primitive Obsession — см. `code-smells.md`)
- Router — единственная точка, которая проходит по `iterable<Handler>`
- При отсутствии match — собственное исключение домена (`No<Module>HandlerException`)
- Регистрация через `tag()` — все handlers в одном месте, легко увидеть весь набор

## Альтернативы (когда не Strategy)

- **2-3 типа без перспективы роста** → `match` в одном Service
- **Условие — сложнее, чем «type === X»** → Service с явной логикой, тесты на каждое условие
- **Состояние решает за обработчиком** → CommandBus / state machine
