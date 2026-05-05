# Architecture Decision Records (ADR)

ADR — короткие записи об **архитектурных решениях**: что решили, **почему**, и какие последствия. Шаблон Майкла Найгарда.

## Когда писать ADR

Создаём ADR, если решение:

- **Архитектурное** (паттерн, граница, технология)
- **Долгоиграющее** (откатить будет дорого)
- **Не очевидно** из кода (есть альтернативы, и не понятно, почему выбрали эту)

Когда **не** пишем:

- Решение прозрачно из кода
- Это локальная тактика, не стратегия
- Это бизнес-правило (его место — `.ai/project/domain/`)

## Формат

`{NNNN}-{kebab-case-title}.md`, где `NNNN` — порядковый номер с ведущими нулями (`0001`, `0023`).

## Правила

- **ADR неизменяем после принятия.** Если решение пересмотрели — создаём новый ADR со статусом `Supersedes ADR-NNNN` и в старом меняем статус на `Superseded by ADR-MMMM`.
- **Не редактировать историю** — это историческая запись, как git commit.
- **Короткий ADR лучше длинного.** 1 страница > 5 страниц.

## Шаблон

См. `0000-template.md`.

## Стартовые ADR

| # | Название | Статус |
|---|---|---|
| 0001 | Pest 3 over PHPUnit | Accepted |
| 0002 | Repository pattern for data access | Accepted |
| 0003 | Final readonly classes by default | Accepted |
| 0004 | Laravel Boost MCP for AI workflows | Accepted |
| 0005 | Module Bridge as Anticorruption Layer | Accepted |
| 0006 | Existing project adoption strategy | Accepted |

*(Стартовые ADR можно переписать или удалить под нужды проекта в `init.sh`.)*

## Индекс ADR

| # | Название | Статус | Дата |
|---|---|---|---|
| 0001 | Pest 3 over PHPUnit | Accepted | YYYY-MM-DD |
| 0002 | Repository pattern for data access | Accepted | YYYY-MM-DD |
| 0003 | Final readonly classes by default | Accepted | YYYY-MM-DD |
| 0004 | Laravel Boost MCP for AI workflows | Accepted | YYYY-MM-DD |
| 0005 | Module Bridge as Anticorruption Layer | Accepted | YYYY-MM-DD |
| 0006 | Existing project adoption strategy | Accepted | YYYY-MM-DD |

*(Обновляй индекс при каждом новом ADR.)*
