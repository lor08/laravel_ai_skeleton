# Template: FormRequest

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests\<DOMAIN>;

use App\DTO\<DOMAIN>\Create<ENTITY>DTO;
use App\Enums\<DOMAIN>\<ENTITY>Status;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

final class Create<ENTITY>Request extends FormRequest
{
    public function authorize(): bool
    {
        return Auth::user()?->can('create', \App\Models\<ENTITY>::class) ?? false;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name'         => ['required', 'string', 'max:255'],
            'customer_id'  => ['required', 'integer', 'exists:customers,id'],
            'status'       => ['required', Rule::enum(<ENTITY>Status::class)],
            'items'        => ['required', 'array', 'min:1'],
            'items.*.id'   => ['required', 'integer', 'exists:items,id'],
            'items.*.qty'  => ['required', 'integer', 'min:1'],
            'meta.note'    => ['nullable', 'string', 'max:500'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'items.required' => 'At least one item is required.',
        ];
    }

    public function toDto(): Create<ENTITY>DTO
    {
        return Create<ENTITY>DTO::fromArray($this->validated());
    }
}
```

## Правила

- `final class`
- Расширяет `FormRequest`
- `authorize()` — проверка прав. **Не** возвращать `true` без причины
- `rules()` — все правила валидации
- Опциональные методы:
  - `messages()` — кастомные сообщения
  - `attributes()` — переименование полей в сообщениях
  - `toDto()` — мост до DTO для сервиса
  - `prepareForValidation()` — нормализация данных до валидации (trim, lowercase email)
- **Нет:** обращений к БД для бизнес-проверок (это в сервис), `Service` зависимостей
- **Есть:** Auth для authorize, Rule для типизированных правил, Enum в правилах через `Rule::enum`
