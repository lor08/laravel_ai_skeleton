# Template: Controller

## Single Action (рекомендуется)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\<DOMAIN>;

use App\DTO\<DOMAIN>\Create<ENTITY>DTO;
use App\Http\Controllers\Controller;
use App\Http\Requests\<DOMAIN>\Create<ENTITY>Request;
use App\Http\Resources\<DOMAIN>\<ENTITY>Resource;
use App\Services\<DOMAIN>\Create<ENTITY>Service;

final class Create<ENTITY>Controller extends Controller
{
    public function __invoke(
        Create<ENTITY>Request $request,
        Create<ENTITY>Service $service,
    ): <ENTITY>Resource {
        $entity = $service->create(Create<ENTITY>DTO::fromArray($request->validated()));

        return <ENTITY>Resource::make($entity);
    }
}
```

## RESTful resource controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\<DOMAIN>;

use App\Http\Controllers\Controller;
use App\Http\Requests\<DOMAIN>\{Index<ENTITY>Request, Show<ENTITY>Request, Update<ENTITY>Request};
use App\Http\Resources\<DOMAIN>\<ENTITY>Resource;
use App\Models\<ENTITY>;
use App\Services\<DOMAIN>\<ENTITY>Service;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class <ENTITY>Controller extends Controller
{
    public function __construct(
        private readonly <ENTITY>Service $service,
    ) {}

    public function index(Index<ENTITY>Request $request): AnonymousResourceCollection
    {
        return <ENTITY>Resource::collection(
            $this->service->paginate($request->validated())
        );
    }

    public function show(Show<ENTITY>Request $request, <ENTITY> $<entity>): <ENTITY>Resource
    {
        return <ENTITY>Resource::make($<entity>);
    }

    public function update(Update<ENTITY>Request $request, <ENTITY> $<entity>): <ENTITY>Resource
    {
        $updated = $this->service->update($<entity>, $request->validated());

        return <ENTITY>Resource::make($updated);
    }
}
```

## Правила

- `final class`
- Расширяет `App\Http\Controllers\Controller`
- Type hint FormRequest, Service, Resource в параметрах
- Метод `__invoke` для single action
- Возврат — `Resource` или `AnonymousResourceCollection`
- **Нет:** `DB::`, `Eloquent::query`, бизнес-логики, `$request->all()`
- **Есть:** `$request->validated()`, делегирование сервису
- Авторизация — в FormRequest через `authorize()` или через middleware
