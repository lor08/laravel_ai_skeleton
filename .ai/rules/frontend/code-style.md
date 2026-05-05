# Frontend Code Style (Vue 3 + TypeScript + Inertia)

## Жёсткие правила

### TypeScript strict

`tsconfig.json`:
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

`any` запрещён. `unknown` + narrowing — окей.

### `<script setup lang="ts">` обязательно

```vue
<script setup lang="ts">
import { computed } from 'vue';
import type { Order } from '@/types/order';

interface Props {
    order: Order;
    readonly?: boolean;
}

interface Emits {
    (e: 'pay', orderId: number): void;
    (e: 'cancel', orderId: number): void;
}

const props = withDefaults(defineProps<Props>(), {
    readonly: false,
});

const emit = defineEmits<Emits>();

const isPayable = computed(() =>
    props.order.status === 'pending' && !props.readonly
);
</script>

<template>
    <div class="order">
        <button v-if="isPayable" @click="emit('pay', order.id)">
            Pay
        </button>
    </div>
</template>
```

### Props и emits типизировать явно
Через `defineProps<Interface>()` и `defineEmits<Interface>()`. Не через runtime-объекты.

### Без `any`, без `// @ts-ignore`
Если действительно нужно — `// @ts-expect-error <причина>` с объяснением.

### Наименование

| Тип | Стиль |
|---|---|
| Component file | `PascalCase.vue` (`OrderCard.vue`) |
| Composable file | `useCamelCase.ts` (`useOrder.ts`) |
| Store file | `camelCase.ts` (`orderStore.ts`) |
| Type file | `kebab-case.ts` (`order.ts` в `types/`) |
| Event name | `kebab-case` (`<button @click="..." @order-paid="...">`) |
| Prop | `camelCase` в JS, `kebab-case` в template |
| CSS class | `kebab-case` |

### Composition over Options

Только Composition API. Options API — нет.

### Без вычислений в template

```vue
<!-- плохо -->
<div>{{ order.items.reduce((s, i) => s + i.price * i.qty, 0) }}</div>

<!-- хорошо -->
<script setup lang="ts">
const total = computed(() =>
    order.items.reduce((s, i) => s + i.price * i.qty, 0)
);
</script>
<template>
    <div>{{ total }}</div>
</template>
```

### Без бизнес-логики в компонентах

Бизнес-логика → composable / store / API-клиент.
Компонент — только:
- Принять props
- Эмитить события
- Рендерить шаблон
- Локальный UI-state (`open/closed`, `loading`, `hover`)

## Структура файла Vue

```vue
<script setup lang="ts">
// 1. Imports (внешние, потом локальные, потом types)
// 2. Props / Emits
// 3. Composables / stores
// 4. State (ref, reactive)
// 5. Computed
// 6. Watchers
// 7. Methods
// 8. Lifecycle (onMounted и т.п.)
</script>

<template>
    <!-- разметка -->
</template>

<style scoped>
/* стили — scoped по умолчанию */
</style>
```

## API-клиент

Все запросы к API — через клиента в `resources/js/api/{domain}.ts`. Не `axios.post(...)` в компонентах.

```ts
// resources/js/api/orders.ts
import { http } from '@/api/http';
import type { Order, CreateOrderDTO } from '@/types/order';

export const ordersApi = {
    list: (filters: OrderFilters): Promise<Order[]> =>
        http.get('/api/orders', { params: filters }).then(r => r.data),

    create: (dto: CreateOrderDTO): Promise<Order> =>
        http.post('/api/orders', dto).then(r => r.data),

    pay: (orderId: number): Promise<Order> =>
        http.post(`/api/orders/${orderId}/pay`).then(r => r.data),
};
```

## State management

- **Component-local** — `ref`, `reactive`, `computed`. Дефолт.
- **Cross-component (parent ↔ children)** — props/emits, `provide/inject` при глубокой вложенности.
- **Cross-page / cross-feature** — Pinia store.
- Никаких глобальных переменных.

## Pinia store

```ts
// resources/js/stores/orderStore.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { ordersApi } from '@/api/orders';
import type { Order } from '@/types/order';

export const useOrderStore = defineStore('order', () => {
    const orders = ref<Order[]>([]);
    const loading = ref(false);

    const pendingCount = computed(() =>
        orders.value.filter(o => o.status === 'pending').length
    );

    const fetchAll = async (): Promise<void> => {
        loading.value = true;
        try {
            orders.value = await ordersApi.list({});
        } finally {
            loading.value = false;
        }
    };

    return { orders, loading, pendingCount, fetchAll };
});
```

## Composables

`useX()` — переиспользуемая логика. Возвращает объект с reactive-ссылками.

```ts
// resources/js/composables/useOrder.ts
import { ref } from 'vue';
import { ordersApi } from '@/api/orders';
import type { Order } from '@/types/order';

export const useOrder = (orderId: number) => {
    const order = ref<Order | null>(null);
    const loading = ref(false);
    const error = ref<Error | null>(null);

    const load = async (): Promise<void> => {
        loading.value = true;
        error.value = null;
        try {
            order.value = await ordersApi.get(orderId);
        } catch (e) {
            error.value = e instanceof Error ? e : new Error(String(e));
        } finally {
            loading.value = false;
        }
    };

    return { order, loading, error, load };
};
```

## Без `console.log` в продакшене

ESLint правило `no-console` (warn) на dev, error на CI.

## Imports — порядок

1. Vue / Pinia / роутер
2. Внешние пакеты
3. `@/api/*`
4. `@/composables/*`
5. `@/stores/*`
6. `@/components/*`
7. `@/types/*` (через `import type`)
8. Локальные относительные

ESLint `import/order` валидирует.

## ESLint / Prettier

- ESLint flat config: `eslint.config.js`
- Prettier: `prettier.config.js`
- Используем `eslint-plugin-vue`, `@typescript-eslint`, `eslint-plugin-import`
- Запуск:
  ```bash
  npm run lint           # eslint --fix
  npm run format         # prettier --write
  ```

## dependency-cruiser (архитектурные границы)

Файл `.dependency-cruiser.cjs` запрещает плохие импорты:
- `components/` → не импортирует `api/`
- `api/` → не импортирует `components/`
- `stores/` ↔ `api/` односторонне (store зависит от api, не наоборот)
- `types/` — листовая директория, ничего не импортирует из приложения

```bash
npm run arch     # depcruise src
```
