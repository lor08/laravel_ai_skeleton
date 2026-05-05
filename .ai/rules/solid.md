# SOLID

Источник: <https://refactoring.guru/ru/design-patterns/principles>

## S — Single Responsibility

> Каждый класс должен решать одну задачу.

**Признаки нарушения:**
- Класс «делает всё»: и валидация, и БД, и нотификация
- Изменения в разных бизнес-фичах требуют править один и тот же класс
- Имя класса содержит «And», «Manager», «Helper», «Util»

**В Laravel:**
- Контроллер — только маршрутизация запроса
- Сервис — одна бизнес-операция
- Repository — доступ к одной модели
- FormRequest — только валидация
- Resource — только трансформация ответа
- Job — одна асинхронная задача

## O — Open / Closed

> Классы открыты для расширения, закрыты для модификации.

**Применение:**
- Стратегии вместо `switch ($type)` — добавить новый тип = добавить класс, не править существующий
- Реестр обработчиков (tagged services), а не цепочка `if`
- События / listeners для расширения поведения

**Пример:**
```php
// Нарушение
match ($payment->type) {
    'stripe' => $this->processStripe(...),
    'paypal' => $this->processPaypal(...),
    'crypto' => $this->processCrypto(...),
};

// Правильно
final readonly class PaymentRouter
{
    public function __construct(
        /** @var iterable<PaymentHandler> */
        private iterable $handlers,
    ) {}

    public function process(Payment $payment): Receipt
    {
        foreach ($this->handlers as $handler) {
            if ($handler->supports($payment)) {
                return $handler->handle($payment);
            }
        }
        throw new UnsupportedPaymentException($payment);
    }
}
```

## L — Liskov Substitution

> Подкласс должен быть полностью заменим на родительский класс без поломки контракта.

**Признаки нарушения:**
- Переопределённый метод бросает исключение «not supported»
- Сильнее предусловия / слабее постусловия
- Игнорирует часть контракта родителя

**В Laravel:** обычно не страдает, если используешь интерфейсы (Contracts) и не наследуешь чужие реализации.

## I — Interface Segregation

> Много маленьких интерфейсов лучше одного жирного.

**Применение:**
- Не пихай в `RepositoryInterface` 30 методов — раздели по бизнес-сценариям
- Контракты под use-case: `OrderReader`, `OrderWriter`, `OrderArchiver`
- Никто не должен реализовывать методы, которые ему не нужны

## D — Dependency Inversion

> Зависим от абстракций (интерфейсов), а не от конкретных классов.

**В Laravel:**
- Type-hint интерфейсы в конструкторах сервисов
- Биндинг в `AppServiceProvider::register()`
- Тесты подменяют реализацию через container

```php
// Service зависит от контракта, не от Eloquent-репозитория
final readonly class OrderService
{
    public function __construct(
        private OrderRepository $orders,
        private PaymentRouter $payments,
        private EventDispatcher $events,
    ) {}
}
```

## Чек-лист

- [ ] Класс имеет одну причину для изменения (S)
- [ ] Расширение через новый класс, не правку старого (O)
- [ ] Подкласс не «удивляет» по сравнению с родителем (L)
- [ ] Интерфейсы маленькие и сценарные (I)
- [ ] Зависимости — через интерфейсы (D)
