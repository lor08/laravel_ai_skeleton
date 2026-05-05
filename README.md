# Laravel AI Skeleton

Скелет Laravel-проекта, заточенный под совместную работу с AI-агентами (Claude Code, Codex, Cursor, JetBrains AI).

## Что внутри

- **`AGENTS.md`** — канонический файл правил, который читают все агенты.
- **`CLAUDE.md`**, **`.codex/AGENTS.md`**, **`.aiassistant/rules/summary.md`** — тонкие указатели на канон.
- **`.ai/`** — четыре слоя знания:
  - `rules/` — **как** писать код (универсально для Laravel)
  - `project/` — **что** в этом проекте (домен, словарь, gotchas)
  - `adr/` — **почему** так решили (Architecture Decision Records)
  - `templates/` — скелеты файлов (controller, service, component...)
- **`.claude/`** — команды и хуки для Claude Code:
  - `commands/` — 9 slash-команд (`/task`, `/quick`, `/implement`, `/review`, `/explain`, `/test-this`, `/refactor`, `/security`, `/update-docs`)
  - `hooks/` — 4 жёстких + 5 мягких хука + Stop-хук напоминания про документацию
- **`tests/Architecture/`** — Pest arch-тесты, кодифицирующие правила в CI.
- **`composer.json`**, **`phpstan.neon`**, **`ecs.php`**, **`rector.php`** — pipeline качества.
- **`.github/workflows/ci.yml`** + **`.gitlab-ci.yml.example`** — CI оба варианта.
- **`init.sh`** — интерактивная инициализация под конкретный проект.

## Стек по умолчанию

- PHP 8.5+
- Laravel 13
- Pest 3 (architecture, mutation, type coverage)
- Larastan / PHPStan max
- Vue 3 + TypeScript + Inertia + Pinia + Vitest *(переключается)*
- Sail (Docker)

## Старт

```bash
git clone <this-repo> my-app && cd my-app
./init.sh                                  # интерактивная настройка
composer install
./vendor/bin/sail up -d
./vendor/bin/sail bin pest --arch          # проверить базовые правила
```

`init.sh` спросит:

- Имя проекта
- Префикс тикетов (например, `PROJ`)
- Главную ветку (`main` / `production`)
- Имя контейнера / runtime (`./vendor/bin/sail` по умолчанию)
- Драйвер БД (mysql / pgsql / sqlite)
- Frontend стек (vue / react / livewire / blade)
- Включить ли Rector, mutation testing, runbook

После прогона плейсхолдеры заменены, лишние файлы удалены, `git init` сделан.

## Ручной режим без `init.sh`

См. `INIT.md` — пошаговый чек-лист, что заменить и где.

## Внедрение в существующий проект

Скелет можно подключить и к существующему Laravel-проекту. См. **`ADOPTION.md`** — 3 уровня внедрения от «только знание правил» до «полный CI-gate с baseline».

## Для агентов

При старте сессии — `AGENTS.md` и `.ai/STARTUP.md`. Дальше по индексу.
