# Template: Service

## Структура

```php
<?php

declare(strict_types=1);

namespace App\Services\<DOMAIN>;

use App\DTO\<DOMAIN>\Create<ENTITY>DTO;
use App\Events\<DOMAIN>\<ENTITY>Created;
use App\Exceptions\<DOMAIN>\<ENTITY>Exception;
use App\Models\<ENTITY>;
use App\Repositories\<DOMAIN>\<ENTITY>Repository;
use Illuminate\Contracts\Events\Dispatcher;
use Illuminate\Support\Facades\DB;

final readonly class Create<ENTITY>Service
{
    public function __construct(
        private <ENTITY>Repository $repository,
        private Dispatcher $events,
    ) {}

    public function create(Create<ENTITY>DTO $dto): <ENTITY>
    {
        return DB::transaction(function () use ($dto): <ENTITY> {
            $entity = $this->repository->create($dto);

            $this->events->dispatch(new <ENTITY>Created($entity));

            return $entity;
        });
    }
}
```

## С обработкой ошибок

```php
<?php

declare(strict_types=1);

namespace App\Services\<DOMAIN>;

use App\DTO\<DOMAIN>\Pay<ENTITY>DTO;
use App\Enums\<DOMAIN>\<ENTITY>Status;
use App\Exceptions\<DOMAIN>\<ENTITY>NotPayableException;
use App\Models\<ENTITY>;
use App\Repositories\<DOMAIN>\<ENTITY>Repository;
use Illuminate\Support\Facades\DB;

final readonly class Pay<ENTITY>Service
{
    public function __construct(
        private <ENTITY>Repository $repository,
        private PaymentGateway $gateway,
    ) {}

    public function pay(Pay<ENTITY>DTO $dto): <ENTITY>
    {
        $entity = $this->repository->findOrFail($dto->id);

        if ($entity->status !== <ENTITY>Status::Pending) {
            throw new <ENTITY>NotPayableException($entity);
        }

        return DB::transaction(function () use ($entity, $dto): <ENTITY> {
            $receipt = $this->gateway->charge($dto->amount, $dto->method);

            return $this->repository->markPaid($entity, $receipt);
        });
    }
}
```

## Правила

- `final readonly class`
- DI всех зависимостей через конструктор
- Один сервис = одна бизнес-операция (или близкая группа: `Order<Create|Pay|Cancel>Service`)
- Транзакции — здесь, не в контроллере
- Бизнес-исключения — собственные (`<DOMAIN>Exception`), не Laravel-овские
- **Нет:** прямого Eloquent (через repository), HTTP request, View
- **Есть:** Repository, другие Service, Facades для инфраструктуры (Log, DB transaction, Cache, Event)

## Грануларность

- 1 сервис на 1 бизнес-команду — **рекомендуется** (`Create<X>Service`, `Cancel<X>Service`, `Refund<X>Service`)
- 1 сервис на сущность — допустимо для простых случаев (`<X>Service` с 3–5 методами)
- «Менеджер всего» — анти-паттерн (`OrderManager`, `OrderHelper`)
