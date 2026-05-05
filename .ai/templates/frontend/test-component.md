# Template: Component Test (Vitest + Vue Test Utils)

```ts
// resources/js/components/domain/OrderCard.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mount, type VueWrapper } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import OrderCard from './OrderCard.vue';
import { ordersApi } from '@/api/orders';
import type { Order } from '@/types/order';

vi.mock('@/api/orders');

const makeOrder = (overrides: Partial<Order> = {}): Order => ({
    id: 1,
    number: 'ORD-001',
    status: 'pending',
    total: 1000,
    customer: { id: 1, name: 'John' } as never,
    items: [],
    createdAt: '2026-01-01T00:00:00Z',
    paidAt: null,
    ...overrides,
});

const mountCard = (props: { order: Order; readonly?: boolean }): VueWrapper =>
    mount(OrderCard, {
        props,
        global: {
            plugins: [createTestingPinia({ stubActions: false })],
        },
    });

describe('OrderCard', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('renders the order number and status', () => {
        const wrapper = mountCard({ order: makeOrder() });

        expect(wrapper.text()).toContain('ORD-001');
        expect(wrapper.text()).toContain('pending');
    });

    it('shows pay button for pending orders', () => {
        const wrapper = mountCard({ order: makeOrder({ status: 'pending' }) });

        expect(wrapper.find('[data-test="pay-btn"]').exists()).toBe(true);
    });

    it('hides pay button for paid orders', () => {
        const wrapper = mountCard({ order: makeOrder({ status: 'paid' }) });

        expect(wrapper.find('[data-test="pay-btn"]').exists()).toBe(false);
    });

    it('hides actions when readonly', () => {
        const wrapper = mountCard({ order: makeOrder(), readonly: true });

        expect(wrapper.find('[data-test="pay-btn"]').exists()).toBe(false);
    });

    it('emits paid event after successful payment', async () => {
        vi.mocked(ordersApi.pay).mockResolvedValue(makeOrder({ status: 'paid' }));

        const wrapper = mountCard({ order: makeOrder() });
        await wrapper.get('[data-test="pay-btn"]').trigger('click');

        await vi.waitFor(() => {
            expect(wrapper.emitted('paid')).toEqual([[1]]);
        });
    });

    it('does not emit paid event on payment failure', async () => {
        vi.mocked(ordersApi.pay).mockRejectedValue(new Error('declined'));

        const wrapper = mountCard({ order: makeOrder() });
        await wrapper.get('[data-test="pay-btn"]').trigger('click');

        await vi.waitFor(() => {
            expect(wrapper.emitted('paid')).toBeUndefined();
        });
    });
});
```

## Helper для типичных кейсов

```ts
// tests/utils/factories.ts
import type { Order, Customer } from '@/types/order';

let nextOrderId = 1;

export const makeOrder = (overrides: Partial<Order> = {}): Order => ({
    id: nextOrderId++,
    number: `ORD-${String(nextOrderId).padStart(3, '0')}`,
    status: 'pending',
    total: 0,
    customer: makeCustomer(),
    items: [],
    createdAt: new Date().toISOString(),
    paidAt: null,
    ...overrides,
});

export const makeCustomer = (overrides: Partial<Customer> = {}): Customer => ({
    id: 1,
    name: 'Test Customer',
    email: 'test@example.com',
    ...overrides,
});
```

## Правила

- Файл рядом с компонентом: `OrderCard.vue` + `OrderCard.test.ts`
- Используй `data-test="..."` для query (не классы и не текст)
- Mock API через `vi.mock('@/api/orders')` + `vi.mocked(...)`
- Pinia — через `createTestingPinia()`
- Async — `vi.waitFor()` для assertions, ждущих state-change

## Что тестировать

- ✅ Рендер ключевых полей из props
- ✅ Conditional rendering (по props.status, props.readonly)
- ✅ Эмит событий
- ✅ User interactions (click, input, submit)
- ✅ Disabled / loading states

## Что НЕ тестировать

- ❌ CSS / стили (это визуальное тестирование, отдельный pipeline)
- ❌ Сторонние UI-библиотеки
- ❌ Инлайн-форматирование текста (если поменяется текст — все тесты сломаются)
