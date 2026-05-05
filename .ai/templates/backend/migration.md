# Template: Migration

## Schema migration

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('<entities>', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('number', 32)->unique();
            $table->string('status', 32)->index();
            $table->unsignedBigInteger('total')->comment('amount in cents');
            $table->json('meta')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['customer_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('<entities>');
    }
};
```

## ALTER migration

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('<entities>', function (Blueprint $table): void {
            $table->string('priority', 16)->default('normal')->after('status');
            $table->index('priority');
        });
    }

    public function down(): void
    {
        Schema::table('<entities>', function (Blueprint $table): void {
            $table->dropIndex(['priority']);
            $table->dropColumn('priority');
        });
    }
};
```

## Data migration (отдельным файлом!)

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        DB::transaction(function (): void {
            DB::table('<entities>')
                ->whereNull('priority')
                ->update(['priority' => 'normal']);
        });
    }

    public function down(): void
    {
        // Data-migrations часто необратимы — оставить пустым или явно throw
    }
};
```

## Правила

- **`declare(strict_types=1)`** в каждой миграции
- **Schema vs data — раздельно.** Не мешай ALTER и UPDATE в одной миграции (если данные большие — это блокирует таблицу)
- **`down()` обязателен** для schema-миграций (хотя бы `dropColumn` / `dropTable`)
- **Индексы — заранее**: на FK, на колонки в `where`, на сортировку
- **Foreign keys через `constrained()`** + `cascadeOnDelete` / `restrictOnDelete`
- **`comment()` на нетривиальные колонки** (например, `total in cents`) — это попадёт в data-model.md
- **Нет** дефолтных `String::random()` или хардкода данных — это в seeders
- **Долгие миграции (> 1 минуты на проде)** — обсудить в ADR (zero-downtime, batched updates, separate window)

## Имена

- Файл: `YYYY_MM_DD_HHIISS_create_<entities>_table.php` для CREATE
- `..._add_<column>_to_<entities>_table.php` для ALTER ADD
- `..._drop_<column>_from_<entities>_table.php` для ALTER DROP
- `..._backfill_<column>_in_<entities>.php` для data-миграций

## После миграции

- Обнови `.ai/project/data-model.md`
- Если изменения нетривиальны — упомяни в `.ai/project/gotchas.md`
