# Code Review

## Когда запускается

- Команда `/review` (полный интервью-ревью)
- Перед открытием PR/MR
- При просьбе «сделай ревью» / «посмотри что не так»

## Подготовка

```bash
git log <MAIN-BRANCH>..HEAD --oneline
git diff <MAIN-BRANCH>..HEAD --stat
git diff <MAIN-BRANCH>..HEAD -- "*.php" "*.vue" "*.ts"
```

Если есть `<RUN-CMD> codex review --base <MAIN-BRANCH>` или другой автоматический ревью-инструмент — запусти его параллельно.

Создай (или перезапиши) `.ai/tasks/<TICKET-PREFIX>-NNNN-review.md` с шаблоном:

```markdown
# <TICKET-PREFIX>-NNNN — Code Review

## Что было сделано
- ...

## Pre-review (быстрые cleanups)

| # | Файл | Вопрос |
|---|---|---|
| Q1 | path:line | ... |

## Интервью по entry points

### Web Controller / API / Job / Event

#### метод X
**Цепочка:** Vue → Controller::method() → Service::method() → Repository → DB
**Проблемы:**
1. ... (P1/P2/P3) — варианты A/B
   ✅ ПРИНЯТО: B

## Quality чек-лист
- [ ] composer style
- [ ] composer analyse
- [ ] composer arch
- [ ] composer test
- [ ] Документация (.ai/project/, ADR при необходимости)
```

## Severity

- **P1** (block merge) — баги, security, data loss, явные нарушения архитектуры
- **P2** (желательно до merge) — нарушения правил проекта, дублирование, N+1, плохая читаемость
- **P3** (можно после) — мелочи, tech debt, мелкий рефакторинг

## Критерии ревью

| Слой | На что смотреть |
|---|---|
| **Vue / TS** | типизация, обработка ошибок, формат запроса, accessibility |
| **Controller** | FormRequest + `authorize()`, route model binding vs `int $id`, тонкость |
| **Service** | транзакции, бизнес-логика отделена, DomainException |
| **Repository** | N+1, константы вместо magic strings, кастомный Builder |
| **Model** | fillable, casts, relations, без бизнес-логики |
| **Migration** | индексы, порядок колонок, data-migration отдельно |
| **Tests** | покрытие новой функциональности, arch tests если новый модуль |
| **Frontend boundaries** | composables vs components, store usage, API-клиент в одном месте |
| **Архитектура** | Repository / Service / Module границы, не нарушены ли |
| **Code Style** | `declare(strict_types=1)`, `final class`, фасады, без хелперов, без описаний в PHPDoc |
| **Безопасность** | SQL injection, mass assignment, XSS, CSRF, authorize() |
| **Производительность** | N+1, индексы, пагинация, кэш, queue для тяжёлого |

## Чек-лист правил кода (применяется в каждом файле)

См. `.ai/rules/backend/code-style.md` и `.ai/rules/frontend/code-style.md`.

## Если найден новый паттерн

Если в ходе ревью видно повторяющееся нарушение или пользователь принимает решение, не описанное в правилах:

1. Сформулируй правило коротко
2. Получи согласие
3. Запиши:
   - Если правило стиля/паттерна → `.ai/rules/...`
   - Если архитектурное решение → `.ai/adr/{NNNN}-{title}.md`

## Финал

После прохождения всех entry points:

1. Обнови статусы в `decisions.md` / `review.md`
2. Заполни Quality чек-лист
3. Скажи пользователю: «Ревью завершено. Найдено X P1, Y P2, Z P3. Готов к `/implement`».
