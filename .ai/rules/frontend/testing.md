# Frontend Testing

## Стек

- **Vitest** — unit + component тесты
- **Vue Test Utils** — рендер компонентов
- **Playwright** — E2E
- **dependency-cruiser** — architecture тесты на импорты

## Структура

```
resources/js/
├── components/
│   ├── ui/Button.vue
│   └── ui/Button.test.ts          ← рядом с компонентом
├── composables/
│   ├── useOrder.ts
│   └── useOrder.test.ts
└── stores/
    ├── orderStore.ts
    └── orderStore.test.ts

tests/
└── e2e/                            ← Playwright
    ├── orders.spec.ts
    └── auth.spec.ts
```

Unit-тесты — рядом с кодом (`*.test.ts`). Vitest найдёт автоматически.
E2E — в `tests/e2e/`, запускается отдельно.

## Запуск

```bash
npm run test                         # vitest run
npm run test:watch                   # vitest watch
npm run test:coverage                # vitest --coverage
npm run test:e2e                     # playwright test
npm run arch                         # depcruise src
```

## Component test (Vue Test Utils + Vitest)

```ts
import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import OrderCard from './OrderCard.vue';
import type { Order } from '@/types/order';

const makeOrder = (overrides: Partial<Order> = {}): Order => ({
    id: 1,
    number: 'ORD-001',
    status: 'pending',
    total: 1000,
    customer: { id: 1, name: 'John' } as never,
    items: [],
    createdAt: '2026-01-01',
    paidAt: null,
    ...overrides,
});

describe('OrderCard', () => {
    it('renders the order number', () => {
        const wrapper = mount(OrderCard, {
            props: { order: makeOrder() },
        });
        expect(wrapper.text()).toContain('ORD-001');
    });

    it('emits pay when button clicked', async () => {
        const wrapper = mount(OrderCard, {
            props: { order: makeOrder({ status: 'pending' }) },
        });
        await wrapper.get('[data-test="pay-btn"]').trigger('click');
        expect(wrapper.emitted('pay')).toEqual([[1]]);
    });

    it('hides pay button when paid', () => {
        const wrapper = mount(OrderCard, {
            props: { order: makeOrder({ status: 'paid' }) },
        });
        expect(wrapper.find('[data-test="pay-btn"]').exists()).toBe(false);
    });
});
```

## Composable test

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { useOrder } from './useOrder';
import { ordersApi } from '@/api/orders';

vi.mock('@/api/orders');

describe('useOrder', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('loads an order successfully', async () => {
        vi.mocked(ordersApi.get).mockResolvedValue({ id: 1 } as never);
        const { order, loading, load } = useOrder(1);

        const promise = load();
        expect(loading.value).toBe(true);
        await promise;

        expect(loading.value).toBe(false);
        expect(order.value).toEqual({ id: 1 });
    });

    it('captures errors', async () => {
        vi.mocked(ordersApi.get).mockRejectedValue(new Error('boom'));
        const { error, load } = useOrder(1);

        await load();
        expect(error.value?.message).toBe('boom');
    });
});
```

## Store test (Pinia)

```ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useOrderStore } from './orderStore';
import { ordersApi } from '@/api/orders';

vi.mock('@/api/orders');

describe('orderStore', () => {
    beforeEach(() => {
        setActivePinia(createPinia());
        vi.clearAllMocks();
    });

    it('counts pending orders', async () => {
        vi.mocked(ordersApi.list).mockResolvedValue([
            { id: 1, status: 'pending' } as never,
            { id: 2, status: 'paid' } as never,
            { id: 3, status: 'pending' } as never,
        ]);

        const store = useOrderStore();
        await store.fetchAll();

        expect(store.pendingCount).toBe(2);
    });
});
```

## Architecture tests (dependency-cruiser)

`.dependency-cruiser.cjs`:

```js
module.exports = {
    forbidden: [
        {
            name: 'no-api-from-components',
            severity: 'error',
            from: { path: '^resources/js/components' },
            to: { path: '^resources/js/api' },
        },
        {
            name: 'no-components-from-api',
            severity: 'error',
            from: { path: '^resources/js/api' },
            to: { path: '^resources/js/components' },
        },
        {
            name: 'no-store-from-api',
            severity: 'error',
            from: { path: '^resources/js/api' },
            to: { path: '^resources/js/stores' },
        },
        {
            name: 'no-circular',
            severity: 'error',
            from: {},
            to: { circular: true },
        },
        {
            name: 'no-orphans',
            severity: 'warn',
            from: { orphan: true, pathNot: '\\.test\\.ts$' },
            to: {},
        },
    ],
    options: {
        tsConfig: { fileName: 'tsconfig.json' },
        includeOnly: '^resources/js',
    },
};
```

Запуск в CI — обязательно.

## E2E (Playwright)

```ts
import { test, expect } from '@playwright/test';

test.describe('Orders', () => {
    test('user can create and pay an order', async ({ page }) => {
        await page.goto('/login');
        await page.fill('[name=email]', 'user@example.com');
        await page.fill('[name=password]', 'password');
        await page.click('button[type=submit]');

        await page.goto('/orders/create');
        await page.selectOption('[name=customer_id]', '1');
        await page.click('text=Add item');
        await page.click('button[type=submit]');

        await expect(page).toHaveURL(/\/orders\/\d+/);
        await page.click('text=Pay');
        await expect(page.locator('[data-test=order-status]')).toHaveText('Paid');
    });
});
```

## Coverage цели

- Unit / component: **80%+** на новом коде
- Composables / stores: **90%+**
- E2E: основные user flows (login, create order, pay, cancel)
- Type coverage (бэкенд): 95% (см. `backend/testing.md`)

## Что НЕ тестируем

- UI-примитивы (`components/ui/Button.vue`) — кроме своих кастомных
- Сторонние библиотеки
- Тривиальные геттеры

## Когда писать тесты

| Что меняется | Что тестируем |
|---|---|
| Новый компонент | component test (rendering + props + emits) |
| Новый composable | composable test (все ветки логики) |
| Новый store action | store test |
| Новый API-метод | unit test API клиента (мок http) |
| Новый user flow | E2E |
| Refactor без изменения поведения | прогнать существующие |
