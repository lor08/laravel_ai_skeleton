# Frontend Architecture

Структура `resources/js/` — облегчённая FSD (Feature-Sliced Design):

```
resources/js/
├── api/                  ← клиенты к Laravel API (по доменам)
│   ├── http.ts           ← общий axios instance
│   ├── orders.ts
│   └── customers.ts
├── stores/               ← Pinia (cross-feature state)
│   ├── authStore.ts
│   └── orderStore.ts
├── composables/          ← переиспользуемая логика без UI
│   ├── useOrder.ts
│   └── usePagination.ts
├── components/           ← UI-компоненты
│   ├── ui/               ← примитивы (Button, Input, Modal)
│   ├── domain/           ← доменные (OrderCard, CustomerSelect)
│   └── layout/           ← layout (AppHeader, AppSidebar)
├── pages/                ← Inertia pages (страницы)
│   ├── Orders/
│   │   ├── Index.vue
│   │   ├── Show.vue
│   │   └── Create.vue
│   └── Dashboard.vue
├── layouts/              ← Inertia layouts
│   └── AppLayout.vue
├── types/                ← TypeScript типы (DTO, enums, helpers)
│   ├── order.ts
│   └── customer.ts
├── lib/                  ← утилиты (formatters, validators)
│   ├── currency.ts
│   └── date.ts
├── app.ts                ← Inertia bootstrap
└── ssr.ts                ← SSR entrypoint (опц.)
```

## Зависимости между слоями

Один слой может импортировать **только** из слоёв ниже по списку:

```
pages          ← может всё
layouts        ← components, composables, stores
components     ← composables, stores (только для domain), types, lib
composables    ← api, stores, types, lib
stores         ← api, types, lib
api            ← types, lib
types          ← (только друг друга)
lib            ← (только друг друга)
```

Запрещено:
- `api/` → `components/`
- `api/` → `stores/`
- `components/ui/` → `stores/` (примитивы должны быть переиспользуемы)
- `types/` → что-либо кроме `types/`

Контролируется через `dependency-cruiser`.

## Pages (Inertia)

Page-компонент:
- Принимает props от Inertia (типизированно)
- Содержит верхнеуровневую логику страницы (загрузка, координация)
- Использует layouts через `defineOptions({ layout: AppLayout })`
- Не содержит сложного UI — делегирует компонентам в `components/domain/`

```vue
<!-- pages/Orders/Index.vue -->
<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue';
import OrderTable from '@/components/domain/OrderTable.vue';
import type { Order, Pagination } from '@/types/order';

defineOptions({ layout: AppLayout });

defineProps<{
    orders: Pagination<Order>;
    filters: Record<string, unknown>;
}>();
</script>

<template>
    <div>
        <h1>Orders</h1>
        <OrderTable :orders="orders.data" />
    </div>
</template>
```

## Components

### `components/ui/` — примитивы

- Не знают о домене
- Без store, без API
- Только props in / events out
- Переиспользуемы в любом проекте

### `components/domain/` — доменные

- Знают о доменных типах (`Order`, `Customer`)
- Могут использовать composables и domain stores
- Не вызывают API напрямую — через composable или store

### `components/layout/` — layout

- Header, Sidebar, Footer и т.п.
- Могут читать auth store и т.п.

## Composables

- Один use-case = один composable
- Имя: `useX()` — возвращает reactive
- Может зависеть от api/store/types
- **Не** должен зависеть от компонентов

## Stores (Pinia)

Используем **только** когда:
- Состояние нужно нескольким независимым компонентам
- Состояние переживает unmount компонента
- Нужна синхронизация между страницами

Если данные используются в одной странице — **composable**, не store.

Стиль — Composition API в стиле Pinia setup-stores (см. `code-style.md`).

## Inertia или SPA

Скелет — под Inertia. Если у проекта отдельный SPA (Vue Router):

- `pages/` → `views/`
- Добавь `router/index.ts`
- Authentication через токены, не сессии
- ADR об этом обязательно

## Типы

- `types/{domain}.ts` — один файл на доменную область
- Используй `import type`
- Avoid `any`, prefer `unknown` + narrowing
- Generic helpers — в `types/utils.ts`

```ts
// types/order.ts
export type OrderStatus = 'pending' | 'paid' | 'cancelled';

export interface Order {
    id: number;
    number: string;
    status: OrderStatus;
    total: number;
    customer: Customer;
    items: OrderItem[];
    createdAt: string;
    paidAt: string | null;
}

export interface CreateOrderDTO {
    customerId: number;
    itemIds: number[];
    promoCode?: string;
}

export interface Pagination<T> {
    data: T[];
    total: number;
    perPage: number;
    currentPage: number;
}
```

## Errors / Loading / Empty states

Каждый компонент, грузящий данные, обязан показать:
- Loading state (skeleton / spinner)
- Error state (с возможностью retry)
- Empty state

Дефолтные UI-компоненты для этого — в `components/ui/`.

## i18n

`<RUN-CMD>` Laravel-lang или Vue-i18n — определиться при старте проекта (ADR).
В коде: `t('orders.created')`, не сырые строки.
