# Template: API Client

## HTTP instance (общий)

```ts
// resources/js/api/http.ts
import axios, { type AxiosInstance, type AxiosError } from 'axios';

export const http: AxiosInstance = axios.create({
    baseURL: '/api',
    headers: {
        Accept: 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
    },
    withCredentials: true,
});

http.interceptors.response.use(
    response => response,
    (error: AxiosError) => {
        if (error.response?.status === 401) {
            window.location.href = '/login';
        }
        return Promise.reject(error);
    },
);
```

## Domain API client

```ts
// resources/js/api/orders.ts
import { http } from '@/api/http';
import type {
    Order,
    OrderFilters,
    CreateOrderDTO,
    Pagination,
} from '@/types/order';

export const ordersApi = {
    list: async (filters: OrderFilters): Promise<Pagination<Order>> => {
        const { data } = await http.get<Pagination<Order>>('/orders', { params: filters });
        return data;
    },

    get: async (id: number): Promise<Order> => {
        const { data } = await http.get<Order>(`/orders/${id}`);
        return data;
    },

    create: async (dto: CreateOrderDTO): Promise<Order> => {
        const { data } = await http.post<Order>('/orders', dto);
        return data;
    },

    pay: async (id: number): Promise<Order> => {
        const { data } = await http.post<Order>(`/orders/${id}/pay`);
        return data;
    },

    cancel: async (id: number, reason?: string): Promise<Order> => {
        const { data } = await http.post<Order>(`/orders/${id}/cancel`, { reason });
        return data;
    },
};
```

## С error handling helper

```ts
// resources/js/api/errors.ts
import type { AxiosError } from 'axios';

export interface ApiError {
    status: number;
    message: string;
    errors?: Record<string, string[]>;
}

export const toApiError = (error: unknown): ApiError => {
    const ax = error as AxiosError<{ message?: string; errors?: Record<string, string[]> }>;

    if (ax.response) {
        return {
            status: ax.response.status,
            message: ax.response.data?.message ?? 'Request failed',
            errors: ax.response.data?.errors,
        };
    }

    return {
        status: 0,
        message: ax.message ?? 'Network error',
    };
};
```

## Правила

- Один файл на одну доменную область (`orders.ts`, `customers.ts`, `auth.ts`)
- Экспорт — объект (`ordersApi`), не отдельные функции
- Все методы возвращают чистые типы (`Order`), не `AxiosResponse`
- Типы — только `import type` из `@/types/`
- Никакой логики — только формирование запроса и распаковка ответа
- Без обработки ошибок (это в composable / store, чтобы UI мог отреагировать)

## Что **не** делает API client

- Не показывает уведомления
- Не редиректит (кроме 401 в interceptor — общая политика)
- Не кэширует (это в store)
- Не зависит от компонентов / composables / stores

## Architecture

- `api/` импортирует только из `types/` и `lib/`
- `api/` **никогда** не импортирует `components/`, `composables/`, `stores/`
- Контролируется dependency-cruiser (`.dependency-cruiser.cjs`)
