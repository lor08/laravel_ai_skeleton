# Template: Vue Component

## UI primitive (`components/ui/`)

```vue
<script setup lang="ts">
interface Props {
    label: string;
    variant?: 'primary' | 'secondary' | 'danger';
    disabled?: boolean;
    loading?: boolean;
}

interface Emits {
    (e: 'click', event: MouseEvent): void;
}

const props = withDefaults(defineProps<Props>(), {
    variant: 'primary',
    disabled: false,
    loading: false,
});

const emit = defineEmits<Emits>();

const handleClick = (event: MouseEvent): void => {
    if (props.disabled || props.loading) {
        return;
    }
    emit('click', event);
};
</script>

<template>
    <button
        :class="['btn', `btn--${variant}`, { 'is-loading': loading }]"
        :disabled="disabled || loading"
        @click="handleClick"
    >
        <span v-if="loading" class="btn__spinner" />
        <span class="btn__label">{{ label }}</span>
    </button>
</template>

<style scoped>
.btn {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
}
</style>
```

## Domain component (`components/domain/`)

```vue
<script setup lang="ts">
import { computed } from 'vue';
import Button from '@/components/ui/Button.vue';
import { useOrderActions } from '@/composables/useOrderActions';
import type { Order } from '@/types/order';

interface Props {
    order: Order;
    readonly?: boolean;
}

interface Emits {
    (e: 'paid', orderId: number): void;
    (e: 'cancelled', orderId: number): void;
}

const props = withDefaults(defineProps<Props>(), {
    readonly: false,
});

const emit = defineEmits<Emits>();

const { pay, cancel, isLoading } = useOrderActions();

const isPayable = computed<boolean>(() =>
    !props.readonly && props.order.status === 'pending'
);

const handlePay = async (): Promise<void> => {
    await pay(props.order.id);
    emit('paid', props.order.id);
};

const handleCancel = async (): Promise<void> => {
    await cancel(props.order.id);
    emit('cancelled', props.order.id);
};
</script>

<template>
    <article class="order-card">
        <header class="order-card__header">
            <h3>{{ order.number }}</h3>
            <span :class="['order-card__status', `order-card__status--${order.status}`]">
                {{ order.status }}
            </span>
        </header>

        <p class="order-card__total">{{ order.total }}</p>

        <footer v-if="!readonly" class="order-card__actions">
            <Button
                v-if="isPayable"
                label="Pay"
                variant="primary"
                :loading="isLoading"
                data-test="pay-btn"
                @click="handlePay"
            />
            <Button
                v-if="isPayable"
                label="Cancel"
                variant="secondary"
                :loading="isLoading"
                @click="handleCancel"
            />
        </footer>
    </article>
</template>

<style scoped>
.order-card {
    border: 1px solid var(--color-border);
    border-radius: 0.5rem;
    padding: 1rem;
}
</style>
```

## Page (Inertia, `pages/`)

```vue
<script setup lang="ts">
import { ref } from 'vue';
import AppLayout from '@/layouts/AppLayout.vue';
import OrderTable from '@/components/domain/OrderTable.vue';
import OrderFiltersBar from '@/components/domain/OrderFiltersBar.vue';
import type { Order, Pagination, OrderFilters } from '@/types/order';

defineOptions({ layout: AppLayout });

const props = defineProps<{
    orders: Pagination<Order>;
    filters: OrderFilters;
}>();

const localFilters = ref<OrderFilters>({ ...props.filters });
</script>

<template>
    <div>
        <header>
            <h1>Orders</h1>
            <OrderFiltersBar v-model:filters="localFilters" />
        </header>

        <OrderTable :orders="orders.data" />

        <!-- Pagination component -->
    </div>
</template>
```

## Правила

- `<script setup lang="ts">`
- Props и emits — через `defineProps<Interface>()` / `defineEmits<Interface>()`
- Дефолтные значения — через `withDefaults`
- Без бизнес-логики (она в composables)
- Без прямых API-вызовов (через composables)
- Атрибут `data-test="..."` для всех интерактивных элементов (кнопки, input'ы, ссылки)
- `scoped` стили по умолчанию

## Структура файла

1. Imports (vue → пакеты → локальные → types через `import type`)
2. `defineOptions` (если нужно — например, `layout` для Inertia page)
3. Props / Emits interfaces
4. `defineProps` / `defineEmits`
5. Composables / stores
6. State (`ref`, `reactive`)
7. Computed
8. Methods
9. Watchers
10. Lifecycle hooks
