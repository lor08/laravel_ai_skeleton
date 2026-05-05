# Template: Module Bridge (Anticorruption Layer)

> Относится к проектам с **несколькими модулями** или **legacy-кодом**, между которыми нужно изолировать языки и контракты.

## Что это

**Module Bridge** = Anticorruption Layer (DDD-термин). Прослойка между двумя ограниченными контекстами, переводящая один язык в другой и не давая внутренностям одного модуля «протекать» в другой.

Не путать с GoF Bridge (разделение абстракции и реализации). Здесь Bridge — **межмодульный**.

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Module Orders  │ ──────▶ │   ModuleBridge  │ ──────▶ │  Module Bonuses │
│  (свой язык)    │         │   (transformer  │         │  (свой язык)    │
│                 │ ◀────── │   + contract)   │ ◀────── │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

## Структура

Папка верхнего уровня **`app/ModuleBridge/`** — отдельно от `app/Modules/`:

```
app/ModuleBridge/
└── <ConsumerName>/                          # Кому нужен мост (или общее имя)
    ├── Contracts/
    │   └── <Domain>BridgeContract.php       # interface, что предоставляет bridge
    ├── DTO/
    │   └── <Domain>SnapshotDTO.php          # язык потребителя
    ├── Services/
    │   └── <Domain>BridgeService.php        # реализация контракта
    ├── Transformers/
    │   └── <Domain>Transformer.php          # перевод DTO модуля → snapshot потребителя
    └── Providers/
        └── <Domain>BridgeServiceProvider.php
```

Альтернативная организация — по поставщику:
```
app/ModuleBridge/
├── Bonuses/
│   ├── Contracts/
│   ├── DTO/
│   └── Services/
├── WMSCore/
│   ├── Contracts/
│   ├── DTO/
│   ├── Services/
│   └── Transformers/
└── SchPure/
    └── ...
```

## Контракт

```php
<?php

declare(strict_types=1);

namespace App\ModuleBridge\Bonuses\Contracts;

use App\ModuleBridge\Bonuses\DTO\BonusSnapshotDTO;
use App\ModuleBridge\Bonuses\DTO\BonusSelectionRequestDTO;

interface BonusBridgeContract
{
    public function getAvailable(int $customerId): BonusSnapshotDTO;

    public function applySelection(BonusSelectionRequestDTO $request): BonusSnapshotDTO;
}
```

## DTO потребителя (snapshot)

DTO bridge'а — **в терминах потребителя**, не поставщика. Это вся суть: потребителю не нужно знать про `BonusRule`, `BonusTransaction`, `BonusBalance` поставщика. Он работает с одним плоским snapshot.

```php
<?php

declare(strict_types=1);

namespace App\ModuleBridge\Bonuses\DTO;

final readonly class BonusSnapshotDTO
{
    /**
     * @param int[] $appliedRuleIds
     */
    public function __construct(
        public int $customerId,
        public int $availableAmount,         # в копейках
        public int $maxApplicable,           # лимит для текущей корзины
        public array $appliedRuleIds = [],
    ) {}
}
```

## Service (реализация)

```php
<?php

declare(strict_types=1);

namespace App\ModuleBridge\Bonuses\Services;

use App\Modules\Bonuses\Repositories\BonusRepository;
use App\Modules\Bonuses\Services\BonusCalculator;
use App\ModuleBridge\Bonuses\Contracts\BonusBridgeContract;
use App\ModuleBridge\Bonuses\DTO\BonusSelectionRequestDTO;
use App\ModuleBridge\Bonuses\DTO\BonusSnapshotDTO;
use App\ModuleBridge\Bonuses\Transformers\BonusSnapshotTransformer;

final readonly class BonusBridgeService implements BonusBridgeContract
{
    public function __construct(
        private BonusRepository $repository,
        private BonusCalculator $calculator,
        private BonusSnapshotTransformer $transformer,
    ) {}

    public function getAvailable(int $customerId): BonusSnapshotDTO
    {
        $balance = $this->repository->balanceFor($customerId);
        $applicableRules = $this->calculator->applicableFor($customerId);

        return $this->transformer->toSnapshot($balance, $applicableRules);
    }

    public function applySelection(BonusSelectionRequestDTO $request): BonusSnapshotDTO
    {
        $result = $this->calculator->select($request->customerId, $request->ruleIds);

        return $this->transformer->fromCalculation($result);
    }
}
```

## Регистрация

```php
final class BonusBridgeServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            BonusBridgeContract::class,
            BonusBridgeService::class,
        );
    }
}
```

Потребитель (другой модуль) импортирует **только** `BonusBridgeContract` и `BonusSnapshotDTO`. Никаких `App\Modules\Bonuses\*`.

## Architecture tests

```php
arch('bridges export only contracts and DTOs to consumers')
    ->expect('App\Modules')
    ->not->toUse([
        'App\Modules\Bonuses\Repositories',
        'App\Modules\Bonuses\Services',
        'App\Modules\Bonuses\Models',
    ]);

arch('bridges depend on their source module, not vice versa')
    ->expect('App\Modules\Bonuses')
    ->not->toUse('App\ModuleBridge');

arch('bridge service implements its contract')
    ->expect('App\ModuleBridge\Bonuses\Services')
    ->toImplement('App\ModuleBridge\Bonuses\Contracts\BonusBridgeContract')
    ->toBeFinal()
    ->toHaveSuffix('Service');
```

## Когда применять

✅ Между двумя независимыми модулями есть множество точек контакта (5+ методов)
✅ Модули развиваются разными темпами / разными командами
✅ Один модуль — legacy, второй — новый, и хочется не «протащить» легаси-имена в новое
✅ Множество потребителей одного модуля — каждый со своим взглядом на данные

❌ Один-два метода — это просто `Service` с DI, без отдельной папки
❌ Модули в одном bounded context — мост избыточен
❌ Простая утилита — это `app/Support/`, не Bridge

## Альтернативы

| Альтернатива | Когда |
|---|---|
| Прямой импорт `Service` другого модуля | Близкие модули, контракт стабилен |
| Event-driven (Event/Listener) | Асинхронное оповещение, не запрос-ответ |
| Shared kernel (общий пакет / `app/Shared/`) | Действительно shared concept между модулями |
| Bridge | Есть язык-перевод, нужна изоляция, > 5 точек контакта |

## Признаки правильно сделанного Bridge

- Потребитель не знает имён классов, моделей, репозиториев модуля-поставщика
- Замена реализации модуля-поставщика не требует правок в потребителе (только в Bridge)
- Bridge переводит **термины**, не просто транспортирует данные («`Order::status`» поставщика → «`isFulfilled: bool`» потребителя)
- Тесты Bridge живут в `tests/Unit/ModuleBridge/...` отдельно от обоих модулей

## ADR

ADR-0005 (`.ai/adr/0005-module-bridge-as-anticorruption-layer.md`) — обоснование, когда заводим этот слой и какие критерии входа.
