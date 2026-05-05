# Git Rules

## Critical Rules для агента

- **NEVER** commit без явного запроса пользователя
- **NEVER** push в remote
- **NEVER** создавай ветки без подтверждения
- **NEVER** запускай destructive команды (`reset --hard`, `push --force`, `branch -D`, `clean -fd`) без явного запроса
- **NEVER** скипай git-хуки (`--no-verify`)
- **ALWAYS** создавай новые коммиты вместо `--amend` (если хук упал — fix → новый commit)

## Commit format

```
[<TICKET-PREFIX>-NNNN]: краткое описание в imperative
```

Примеры:
- `[<TICKET-PREFIX>-1234]: add payment handler`
- `[<TICKET-PREFIX>-1235]: fix N+1 in catalog`
- `[hotfix]: production data integrity`

Тело коммита (опционально, через пустую строку) — что и **зачем**, не как.

## Branch naming

```
<TICKET-PREFIX>-NNNN_short-kebab-description
```

Примеры:
- `<TICKET-PREFIX>-1234_payment-handler`
- `<TICKET-PREFIX>-1235_fix-catalog-n-plus-one`

## Protected branches

- `<MAIN-BRANCH>` — main
- *(добавь сюда `dev`, `stage` и т.п. если применимо)*

В protected ветки — только через MR/PR с code review.

## Pre-commit hooks

`.git-hooks/pre-commit` запускает:

1. ECS auto-fix на staged PHP-файлах
2. Pest `--arch` (быстрая проверка архитектуры)

Включить:
```bash
git config core.hooksPath .git-hooks
chmod +x .git-hooks/pre-commit
```

## Workflow

1. Создай ветку от `<MAIN-BRANCH>` после согласования с пользователем
2. Делай коммиты в правильном формате
3. Перед PR/MR — `composer all`
4. Создай PR/MR через `gh` или GitLab UI
5. Code review → merge

## Что писать в PR

- **Summary** — 1–3 пункта что и зачем
- **Test plan** — чек-лист как тестировать
- **Migrations / config / new env vars** — явно подсветить
- **Screenshots** — для UI-изменений
- **Linked tickets** — `<TICKET-PREFIX>-NNNN`

## Merge strategy

*(уточнить под проект — squash / rebase / merge commit)*

Дефолт: **squash and merge** в `<MAIN-BRANCH>` для чистой истории.
