# Template: Pinia Store (Setup style)

```ts
// resources/js/stores/orderStore.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { ordersApi } from '@/api/orders';
import type { Order, OrderFilters } from '@/types/order';

export const useOrderStore = defineStore('order', () => {
    const orders = ref<Order[]>([]);
    const loading = ref(false);
    const lastFetchedAt = ref<Date | null>(null);

    const pendingCount = computed<number>(() =>
        orders.value.filter(o => o.status === 'pending').length
    );

    const findById = (id: number): Order | undefined =>
        orders.value.find(o => o.id === id);

    const fetchAll = async (filters: OrderFilters = {}): Promise<void> => {
        loading.value = true;
        try {
            orders.value = await ordersApi.list(filters);
            lastFetchedAt.value = new Date();
        } finally {
            loading.value = false;
        }
    };

    const upsert = (order: Order): void => {
        const idx = orders.value.findIndex(o => o.id === order.id);
        if (idx >= 0) {
            orders.value[idx] = order;
        } else {
            orders.value.push(order);
        }
    };

    const remove = (id: number): void => {
        orders.value = orders.value.filter(o => o.id !== id);
    };

    const $reset = (): void => {
        orders.value = [];
        loading.value = false;
        lastFetchedAt.value = null;
    };

    return {
        orders,
        loading,
        lastFetchedAt,

        pendingCount,
        findById,

        fetchAll,
        upsert,
        remove,
        $reset,
    };
});
```

## Auth store (cross-feature)

```ts
// resources/js/stores/authStore.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { authApi } from '@/api/auth';
import type { User } from '@/types/user';

export const useAuthStore = defineStore('auth', () => {
    const user = ref<User | null>(null);
    const loading = ref(false);

    const isAuthenticated = computed<boolean>(() => user.value !== null);

    const can = (permission: string): boolean =>
        user.value?.permissions.includes(permission) ?? false;

    const login = async (email: string, password: string): Promise<void> => {
        loading.value = true;
        try {
            user.value = await authApi.login(email, password);
        } finally {
            loading.value = false;
        }
    };

    const logout = async (): Promise<void> => {
        await authApi.logout();
        user.value = null;
    };

    const refresh = async (): Promise<void> => {
        try {
            user.value = await authApi.me();
        } catch {
            user.value = null;
        }
    };

    return { user, loading, isAuthenticated, can, login, logout, refresh };
});
```

## Правила

- Setup style (factory function), не Options style
- Имя файла: `<domain>Store.ts` (`orderStore.ts`)
- Имя экспорта: `use<Domain>Store` (`useOrderStore`)
- Store ID — kebab-case (`'order'`, `'auth'`, `'cart'`)
- Возвращай только то, что используется снаружи
- Reactive state — через `ref` / `reactive`
- Getters — через `computed`
- Actions — обычные функции (не нужно в `actions: {...}` как в Options)
- `$reset()` — кастомный метод для сброса (Pinia setup-stores не имеет встроенного `$reset`)
- Persistence: `pinia-plugin-persistedstate` если нужно сохранять в `localStorage`

## Когда заводить store

✅ Состояние читают/меняют независимые компоненты на разных страницах
✅ Auth, корзина, нотификации, шорт-нэппы пользователя
✅ Cache данных, обновляемых редко (справочники)

❌ Состояние одной страницы (используй composable)
❌ Form-state (используй ref/v-model)
❌ Производные от props (используй computed в компоненте)

## Architecture

- Store импортирует только: `api/`, `types/`, `lib/`, другие stores
- Store **не** импортирует: components, composables (которые сами зависят от store — циклы!)
