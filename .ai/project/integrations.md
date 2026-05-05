# Integrations

> Внешние API, на которые мы завязаны.
> Лимиты, особенности, retry-стратегии, sandbox-credentials.

## Шаблон

### `<Provider Name>`

- **Назначение:** *(зачем используем)*
- **Документация:** *(URL)*
- **Где живёт код:** `app/Modules/{Module}/Services/{Provider}Service.php`
- **Контракт:** `App\Contracts\{Provider}Contract`
- **Тип:** REST / SOAP / gRPC / SDK
- **Auth:** API key / OAuth / Basic / mTLS
- **Лимиты:** *(rate limit, размер запроса, ограничения по объёму)*
- **Retry:** *(стратегия — exponential backoff, max attempts, какие коды ретраятся)*
- **Idempotency:** *(есть ли idempotency key, как обеспечена)*
- **Sandbox:** *(URL, креденшелы — куда смотреть, не сюда!)*
- **Webhooks:** *(если есть — endpoint, signature verification)*
- **Особенности:**
  - *(нюансы и подводные камни)*
- **ADR:** *(ссылка, если решение об интеграции записано в ADR)*

---

## Примеры (заполни своими)

### Stripe (платежи)

- **Назначение:** обработка карточных платежей в продакшене
- **Документация:** https://docs.stripe.com
- *(...)*

### Sendgrid (email)

- **Назначение:** транзакционные письма
- *(...)*

---

## Где НЕ хранить креденшелы

- ❌ В этом файле
- ❌ В коде
- ❌ В `.env.example`

## Где хранить креденшелы

- ✅ `.env` (не коммитим)
- ✅ Vault / Secrets Manager в проде
- ✅ В CI — encrypted secrets / vars
