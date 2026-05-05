# Template: Module

> Модули — для крупных проектов с несколькими доменными контекстами.
> Маленьким проектам достаточно плоской структуры (`app/Services/`, `app/Repositories/`).
>
> Решение перейти на модули — оформляется ADR.

## Структура

```
app/Modules/<Module>/
├── Console/
│   └── <Module>Command.php
├── Contracts/
│   └── <Module>Repository.php       # interface
├── DTO/
│   └── Create<Entity>DTO.php
├── Enums/
│   └── <Module>Status.php
├── Events/
│   └── <Entity>Created.php
├── Exceptions/
│   └── <Module>Exception.php
├── Jobs/
│   └── Process<Entity>Job.php
├── Listeners/
│   └── Send<Entity>Notification.php
├── Providers/
│   └── <Module>ServiceProvider.php
├── Repositories/
│   └── Eloquent<Module>Repository.php
├── Services/
│   └── Create<Entity>Service.php
└── Resources/
    └── <Entity>Resource.php
```

## ServiceProvider

```php
<?php

declare(strict_types=1);

namespace App\Modules\<Module>\Providers;

use App\Modules\<Module>\Contracts\<Module>Repository;
use App\Modules\<Module>\Repositories\Eloquent<Module>Repository;
use Illuminate\Support\ServiceProvider;

final class <Module>ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(<Module>Repository::class, Eloquent<Module>Repository::class);
    }

    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');
        $this->loadRoutesFrom(__DIR__.'/../Routes/api.php');
    }
}
```

Регистрация в `bootstrap/providers.php` (Laravel 13):

```php
return [
    App\Providers\AppServiceProvider::class,
    App\Modules\<Module>\Providers\<Module>ServiceProvider::class,
];
```

## Bridge между модулями

Если модулю A нужны данные от модуля B — **через Anticorruption Layer**: отдельная папка `app/ModuleBridge/<Source>/` с контрактом и DTO в языке потребителя.

См. отдельный шаблон **`.ai/templates/backend/module-bridge.md`** и **ADR-0005**.

Кратко:
- Контракт + DTO в `app/ModuleBridge/<Source>/` — то, что видит потребитель
- Реализация в том же `app/ModuleBridge/<Source>/Services/` — переводит модели/DTO модуля-поставщика
- Модуль-потребитель **не импортирует** ничего из `app/Modules/<Source>/*`, только из `app/ModuleBridge/<Source>/*`

Контролируется arch-тестом — см. `module-bridge.md`.

## Architecture test

```php
arch('modules do not import each others internals')
    ->expect('App\Modules\Orders')
    ->not->toUse([
        'App\Modules\Customers\Repositories',
        'App\Modules\Customers\Services',
        'App\Modules\Customers\Models',
    ]);

arch('modules talk only through contracts')
    ->expect('App\Modules')
    ->canOnlyUse([
        'App\Modules',                  // свой модуль
        'App\Contracts',                // общие контракты
        'App\DTO',                      // shared DTO
        'Illuminate',                   // Laravel
    ]);
```

## Когда заводить новый модуль

✅ Новая бизнес-область (Orders, Catalog, Payments)
✅ > 5 связанных сервисов и репозиториев
✅ Чёткая граница ответственности

❌ Утилиты / помощники
❌ Один сервис с парой методов
❌ Чисто-инфраструктурный код (логирование, кэш) — это `app/Support/` или дефолтные провайдеры
