# Template: Filler (data-versioning)

> **Опциональный паттерн.** Используется, если в проекте есть пакет для версионируемых data-операций (`sch/fillers`, `kalnoy/fillers`, или собственный).
> Если используешь только стандартные Laravel `seeders` — этот файл можно игнорировать.

## Что это и зачем

**Filler** = миграция для **данных**, не схемы. Запускается один раз, регистрируется в БД (как обычные migrations), идемпотентна.

| | Migration | Seeder | Filler |
|---|---|---|---|
| Назначение | Структура БД | Тестовые данные | **Production данные** |
| Версионирование | Да | Нет | Да |
| Запуск в проде | Да | Нет | Да |
| Идемпотентность | За счёт schema-операций | Ручная | За счёт `updateOrCreate()` |
| Команда | `migrate` | `db:seed` | `db:fill` |

## Когда использовать

✅ Добавление справочного значения в production БД (новый платёжный тип, валюта, статус)
✅ Backfill значений по существующим строкам после ALTER
✅ Изменение значения в справочнике, которое должно проехать на все окружения

❌ Тестовые данные → Seeder
❌ Изменение схемы → Migration
❌ Один раз вручную через `tinker` → не filler, обычный hotfix

## Расположение

```
database/fillers/
├── 2026_05_01_120000_add_paypal_payment_type.php
├── 2026_05_03_140000_backfill_order_priority.php
└── 2026_05_05_090000_update_default_currency.php
```

## Naming convention

```
{YYYY_MM_DD_HHMMSS}_{snake_case_description}.php
```

Совпадает с migrations. Это специально — порядок обеспечен timestamp'ом.

## Базовый шаблон

```php
<?php

declare(strict_types=1);

use App\Enums\Payment\PaymentTypeEnum;
use App\Models\PaymentType;

return new class {
    public function run(): void
    {
        $this->createOrUpdate();
    }

    private function createOrUpdate(): void
    {
        PaymentType::query()->updateOrCreate(
            ['code' => PaymentTypeEnum::Paypal],
            [
                'name'    => 'PayPal',
                'tax'     => '4.50',
                'sorting' => 100,
                'active'  => true,
            ],
        );
    }
};
```

## С зависимостями

```php
<?php

declare(strict_types=1);

use App\Enums\Payment\PaymentTypeEnum;
use App\Models\Domain;
use App\Models\PaymentType;
use Illuminate\Support\Facades\DB;

return new class {
    public function run(): void
    {
        DB::transaction(function (): void {
            $payment = $this->createPayment();
            $this->linkToDomains($payment);
        });
    }

    private function createPayment(): PaymentType
    {
        return PaymentType::query()->updateOrCreate(
            ['code' => PaymentTypeEnum::Paypal],
            ['name' => 'PayPal', 'sorting' => 100],
        );
    }

    private function linkToDomains(PaymentType $payment): void
    {
        $domainIds = Domain::query()->pluck('id');

        foreach ($domainIds as $domainId) {
            $payment->domains()->syncWithoutDetaching([$domainId => ['active' => false]]);
        }
    }
};
```

## Backfill (data-migration)

```php
<?php

declare(strict_types=1);

use App\Enums\OrderPriority;
use Illuminate\Support\Facades\DB;

return new class {
    public function run(): void
    {
        DB::table('orders')
            ->whereNull('priority')
            ->update(['priority' => OrderPriority::Normal->value]);
    }
};
```

Для **больших таблиц** — chunk'ами:

```php
return new class {
    public function run(): void
    {
        Order::query()
            ->whereNull('priority')
            ->chunkById(500, function (Collection $chunk): void {
                $chunk->each->update(['priority' => OrderPriority::Normal]);
            });
    }
};
```

## Запуск

```bash
<RUN-CMD> artisan db:fill              # все pending fillers
<RUN-CMD> artisan db:fill --pretend    # dry-run (если поддерживается пакетом)
```

## Чек-лист

- [ ] `declare(strict_types=1);`
- [ ] `updateOrCreate()` или эквивалент — идемпотентно
- [ ] Без хардкода — Enums, Constants
- [ ] Логика разбита на private методы
- [ ] Транзакция при множественных операциях
- [ ] Большие backfill'ы — `chunkById()`, не `get()`/`update()` всё сразу
- [ ] Имя файла: `{YYYY_MM_DD_HHMMSS}_{description}.php`

## Альтернативы

- **Стандартный Laravel** — отдельный data-migration файл (обычная migration с `DB::table()->update()` в `up()`). Минус: не отделено от schema-миграций, сложнее различать.
- **Seeders** — только для **тестовых** данных. В прод не запускать.
- **`db:seed --class=...`** в deploy hook'е — работает, но без версионирования (можно случайно прогнать дважды).
