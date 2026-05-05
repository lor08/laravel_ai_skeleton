# Template: Composable

## Базовый

```ts
// resources/js/composables/useOrder.ts
import { ref, computed } from 'vue';
import { ordersApi } from '@/api/orders';
import type { Order } from '@/types/order';

interface UseOrderReturn {
    order: Ref<Order | null>;
    loading: Ref<boolean>;
    error: Ref<Error | null>;
    isLoaded: ComputedRef<boolean>;
    load: () => Promise<void>;
    refresh: () => Promise<void>;
}

export const useOrder = (orderId: number): UseOrderReturn => {
    const order = ref<Order | null>(null);
    const loading = ref(false);
    const error = ref<Error | null>(null);

    const isLoaded = computed<boolean>(() => order.value !== null);

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

    const refresh = (): Promise<void> => load();

    return { order, loading, error, isLoaded, load, refresh };
};
```

## С действиями (actions composable)

```ts
// resources/js/composables/useOrderActions.ts
import { ref } from 'vue';
import { ordersApi } from '@/api/orders';
import { useOrderStore } from '@/stores/orderStore';
import type { Order } from '@/types/order';

export const useOrderActions = () => {
    const isLoading = ref(false);
    const lastError = ref<Error | null>(null);
    const store = useOrderStore();

    const pay = async (orderId: number): Promise<Order | null> => {
        isLoading.value = true;
        lastError.value = null;
        try {
            const order = await ordersApi.pay(orderId);
            store.upsert(order);
            return order;
        } catch (e) {
            lastError.value = e instanceof Error ? e : new Error(String(e));
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    const cancel = async (orderId: number, reason?: string): Promise<Order | null> => {
        isLoading.value = true;
        lastError.value = null;
        try {
            const order = await ordersApi.cancel(orderId, reason);
            store.upsert(order);
            return order;
        } catch (e) {
            lastError.value = e instanceof Error ? e : new Error(String(e));
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    return { pay, cancel, isLoading, lastError };
};
```

## Утилитарный (без API)

```ts
// resources/js/composables/usePagination.ts
import { ref, computed } from 'vue';

export const usePagination = (initialPerPage = 20) => {
    const page = ref(1);
    const perPage = ref(initialPerPage);
    const total = ref(0);

    const totalPages = computed<number>(() =>
        Math.ceil(total.value / perPage.value)
    );

    const hasNext = computed<boolean>(() => page.value < totalPages.value);
    const hasPrev = computed<boolean>(() => page.value > 1);

    const next = (): void => {
        if (hasNext.value) page.value += 1;
    };

    const prev = (): void => {
        if (hasPrev.value) page.value -= 1;
    };

    const reset = (): void => {
        page.value = 1;
    };

    return { page, perPage, total, totalPages, hasNext, hasPrev, next, prev, reset };
};
```

## Правила

- Имя функции: `useX()` — `camelCase`, начинается с `use`
- Возвращает объект с reactive-ссылками (или явный `Return` interface)
- Тип возврата — явный (`UseOrderReturn`), либо TS выводит из `return`
- Composable **может** иметь:
  - state (ref/reactive)
  - computed
  - watchers
  - lifecycle hooks
  - вызовы API через `api/`
  - вызовы store
- Composable **не должен**:
  - импортировать компоненты
  - содержать UI-логику (`document.querySelector`, манипуляции DOM)
  - быть синглтоном без причины (если нужен — через `defineStore` Pinia)

## Когда composable, когда store

| | composable | store |
|---|---|---|
| Состояние per-component | ✅ | ❌ |
| Состояние shared | ❌ (используй store) | ✅ |
| Логика API | ✅ | ❌ (в actions опц.) |
| Список (из API) для одной страницы | ✅ | возможно |
| Auth state | ❌ | ✅ |
| Корзина | ❌ | ✅ |
