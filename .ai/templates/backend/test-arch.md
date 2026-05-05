# Template: Architecture Tests

> Кодифицируем правила проекта в виде Pest arch-тестов.
> Запуск — `composer arch` или `<RUN-CMD> pest --arch`.

## Структура

```
tests/Architecture/
├── StrictTypesTest.php
├── FinalClassesTest.php
├── LayerBoundariesTest.php
├── NamingConventionsTest.php
└── HelpersTest.php           ← запрет глобальных хелперов
```

## StrictTypesTest.php

```php
<?php

declare(strict_types=1);

arch('all PHP files use strict types')
    ->expect('App')
    ->toUseStrictTypes();
```

## FinalClassesTest.php

```php
<?php

declare(strict_types=1);

arch('all classes are final')
    ->expect('App')
    ->classes
    ->toBeFinal()
    ->ignoring([
        'App\Http\Controllers\Controller',
        'App\Models',
        'App\Exceptions',
    ]);

arch('DTOs are readonly and final')
    ->expect('App\DTO')
    ->classes
    ->toBeReadonly()
    ->classes
    ->toBeFinal();
```

## LayerBoundariesTest.php

```php
<?php

declare(strict_types=1);

arch('controllers are thin')
    ->expect('App\Http\Controllers')
    ->toBeFinal()
    ->toHaveSuffix('Controller')
    ->not->toUse([
        'Illuminate\Support\Facades\DB',
        'Illuminate\Database\Eloquent\Builder',
        'Illuminate\Database\Eloquent\Collection',
    ]);

arch('repositories never know about HTTP')
    ->expect('App\Repositories')
    ->not->toUse([
        'Illuminate\Http\Request',
        'Illuminate\Http\Response',
        'Illuminate\Foundation\Http\FormRequest',
    ]);

arch('services use repositories, not eloquent directly')
    ->expect('App\Services')
    ->not->toUse(['Illuminate\Database\Eloquent\Builder']);

arch('models stay in their lane')
    ->expect('App\Models')
    ->not->toBeUsedIn('App\Http\Controllers');

arch('DTOs have no dependencies')
    ->expect('App\DTO')
    ->not->toUse([
        'Illuminate\Support\Facades',
        'App\Services',
        'App\Repositories',
    ]);
```

## NamingConventionsTest.php

```php
<?php

declare(strict_types=1);

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

arch('events have Event suffix')
    ->expect('App\Events')
    ->toHaveSuffix('Event');

arch('listeners have Listener suffix')
    ->expect('App\Listeners')
    ->toHaveSuffix('Listener');

arch('exceptions have Exception suffix')
    ->expect('App\Exceptions')
    ->toHaveSuffix('Exception');

arch('enums are enums')
    ->expect('App\Enums')
    ->toBeEnums();
```

## HelpersTest.php

```php
<?php

declare(strict_types=1);

arch('no global helpers in PHP code')
    ->expect('App')
    ->not->toUse([
        'trans', 'view', 'redirect', 'app', 'config',
        'abort', 'abort_if', 'abort_unless',
        'auth', 'request', 'now', 'cache', 'session',
        'back', 'response', 'route', 'asset', 'url',
        'env', 'dispatch', 'event', 'logger',
        'optional', 'tap', 'collect', 'info', 'action',
        'old', 'csrf_token', 'csrf_field', 'method_field',
        'data_get', 'data_set',
        'public_path', 'storage_path', 'base_path',
        'app_path', 'database_path', 'resource_path', 'config_path',
    ])
    ->ignoring([
        'config',  // exception: app/config/* legitimately use config()
    ]);
```

## Чек-лист при добавлении нового слоя

Когда вводишь новый namespace (например, `App\Modules\Catalog\Search\`), добавь:

1. Строку в `LayerBoundariesTest.php` про границы импортов
2. Строку в `NamingConventionsTest.php` про суффикс
3. Если новый паттерн — соответствующий arch-тест
4. ADR, если решение архитектурное

Без новых arch-тестов слой остаётся неконтролируемым.
