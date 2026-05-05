# ADOPTION — внедрение скелета в существующий Laravel-проект

`init.sh` рассчитан на **новый** проект с нуля. Этот документ — про то, как принести правила, команды и хуки в **существующий** проект, не сломав его.

## TL;DR

Берёшь `.ai/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`, `tests/Architecture/` — копируешь к себе. Остальное (composer, phpstan, ECS, CI) — мерджишь руками с тем, что уже есть. Применяешь по 3 уровням от лёгкого к жёсткому.

## Три уровня внедрения

Сложность нарастает. Не пропускай уровни — adoption через L1 → L2 → L3 надёжнее, чем сразу L3.

### Level 1 — Knowledge only (1 час)

Цель: **AI-агенты знают правила, но ничего в коде не меняется.**

```bash
# В корне существующего проекта:
git clone --depth=1 git@github.com:lor08/laravel_ai_skeleton.git /tmp/skel
cp -r /tmp/skel/.ai ./
cp -r /tmp/skel/.aiassistant ./
mkdir -p .codex && cp /tmp/skel/.codex/AGENTS.md .codex/
cp /tmp/skel/AGENTS.md ./AGENTS.md
cp /tmp/skel/CLAUDE.md ./CLAUDE.md
cp /tmp/skel/.editorconfig ./.editorconfig

# Если у тебя уже есть AGENTS.md / CLAUDE.md — мерджи руками или переименуй старые в `*-old.md`
```

Дальше:
1. Заполни `.ai/project/overview.md`, `glossary.md`, `data-model.md`, `gotchas.md` под **свой** проект
2. Найди-замени плейсхолдеры (`<TICKET-PREFIX>`, `<MAIN-BRANCH>`, `<RUN-CMD>`, `<APP-CONTAINER>`):
   ```bash
   grep -RIn '<TICKET-PREFIX>\|<MAIN-BRANCH>\|<RUN-CMD>\|<APP-CONTAINER>' .ai/ .claude/ AGENTS.md CLAUDE.md
   # ... затем sed -i ... как в INIT.md
   ```
3. Удали из `.ai/adr/` стартовые ADR, которые тебе не подходят
4. Зафиксируй существующие архитектурные решения как ADR (хотя бы топ-5)

**Результат:** агенты при следующем старте читают `AGENTS.md`, понимают стиль и правила. **Код не меняется**, CI не меняется. Безопасно.

### Level 2 — Soft enforcement (1 день)

Цель: **хуки в Claude Code предупреждают / блокируют**, но CI и git-хуки нетронуты.

1. Скопируй `.claude/`:
   ```bash
   mkdir -p .claude
   cp -r /tmp/skel/.claude/commands ./.claude/
   cp -r /tmp/skel/.claude/hooks ./.claude/
   cp /tmp/skel/.claude/settings.json ./.claude/
   chmod +x .claude/hooks/*.sh
   ```

2. **Отключи жёсткие хуки на старте**, чтобы не блокировать каждое касание legacy-файла:

   В `.claude/settings.json` — пометь `php-strict-types.sh`, `php-no-inline-comments.sh`, `php-no-phpdoc-descriptions.sh` как **soft warn** (`exit 0` вместо `exit 2`):

   ```bash
   # Временно делаем жёсткие хуки мягкими:
   for h in php-strict-types php-no-inline-comments php-no-phpdoc-descriptions; do
       sed -i 's/^exit 2$/echo "  ⚠ run later" >\&2; exit 0/' .claude/hooks/${h}.sh
   done
   ```

   `no-laravel-helpers.sh` оставь жёстким **только если** проект уже использует фасады. Иначе — тоже сделай мягким.

3. Скопируй MCP, slash-команды, шаблоны — они не блокируют ничего:
   ```bash
   cp /tmp/skel/.mcp.json ./.mcp.json   # если у тебя нет .mcp.json
   ```

**Результат:** агенты пишут новый код по правилам, старый не подсвечивается красным каждую секунду. Дисциплина через workflow в правилах, не через автоматику.

### Level 3 — Full CI gate (1–2 недели)

Цель: **Pest arch + PHPStan + ECS гонят в CI**, новый код блокируется при нарушении, старый прощается через baseline.

#### Шаг 3.1 — Composer-скрипты

Открой `composer.json` существующего проекта. Из скелетного `composer.json` забери только секции, которых у тебя нет:

```json
{
  "scripts": {
    "style":        "<RUN-CMD> ecs check --fix",
    "style:check":  "<RUN-CMD> ecs check",
    "analyse":      "<RUN-CMD> phpstan analyse --memory-limit=512M",
    "test":         "<RUN-CMD> pest --parallel",
    "arch":         "<RUN-CMD> pest --arch",
    "types":        "<RUN-CMD> pest --type-coverage --min=95",
    "all":          ["@style:check", "@analyse", "@arch", "@types", "@test"]
  }
}
```

Установи недостающие dev-зависимости:
```bash
composer require --dev \
    pestphp/pest:^3.7 \
    pestphp/pest-plugin-arch:^3.0 \
    pestphp/pest-plugin-laravel:^3.0 \
    pestphp/pest-plugin-type-coverage:^3.0 \
    larastan/larastan:^3.0 \
    symplify/easy-coding-standard:^12.5
```

Если у тебя PHPUnit — Pest работает поверх него, мигрировать существующие тесты не обязательно.

#### Шаг 3.2 — Architecture tests

```bash
mkdir -p tests/Architecture
cp /tmp/skel/tests/Architecture/* tests/Architecture/
```

Запусти:
```bash
<RUN-CMD> pest --arch
```

Скорее всего — **много красного**. Это нормально. Подход:

1. **Открой `tests/Architecture/FinalClassesTest.php`**, добавь в `ignoring([...])` все классы, которые сейчас не final, но должны бы быть. Цель — они должны стать final, но не сегодня.

2. **`LayerBoundariesTest.php`** — то же самое: добавь в `ignoring()` нарушения, которые накопились (контроллеры с прямым Eloquent, репозитории с Request).

3. Проверь: `pest --arch` → зелёное.

4. Заведи **технический долг** на уменьшение `ignoring()` списков.

```php
// tests/Architecture/FinalClassesTest.php — пример adoption-state
arch('domain classes are final')
    ->expect('App')
    ->classes->toBeFinal()
    ->ignoring([
        'App\Http\Controllers\Controller',
        'App\Models',
        'App\Exceptions\Handler',
        // legacy — TODO: make final
        'App\Services\Legacy\OrderProcessor',
        'App\Services\Legacy\PaymentDispatcher',
        'App\Repositories\BaseRepository',
    ]);
```

#### Шаг 3.3 — PHPStan baseline

```bash
cp /tmp/skel/phpstan.neon ./phpstan.neon                    # adapt paths to your project
cp /tmp/skel/phpstan-baseline.neon ./phpstan-baseline.neon  # empty
```

Сгенерируй baseline:
```bash
<RUN-CMD> phpstan analyse --generate-baseline
```

Это запишет все текущие ошибки в `phpstan-baseline.neon`. CI становится зелёным **с этого момента**. Новый код вводящий новые ошибки — фейлит.

Со временем — уменьшаем baseline. Например, разрешено только новые модули писать без baseline:

```neon
includes:
    - phpstan-baseline.neon
parameters:
    paths:
        - app/Modules/NewModule    # без baseline, чисто
        - app
```

#### Шаг 3.4 — ECS

```bash
cp /tmp/skel/ecs.php ./ecs.php
<RUN-CMD> ecs check --fix
```

ECS auto-fix должен пройти. Просмотри изменения, закоммить отдельно — это **рефакторинг по стилю**, не задача.

#### Шаг 3.5 — CI

Если у тебя уже есть CI — **не заменяй**, добавь jobs:

```yaml
# .github/workflows/ci.yml — добавить к существующим jobs
arch:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: shivammathur/setup-php@v2
      with: { php-version: '8.5', tools: composer:v2 }
    - uses: ramsey/composer-install@v3
    - run: vendor/bin/pest --arch
```

Сначала эти jobs могут быть `continue-on-error: true` — наблюдаем красные, чиним по чуть-чуть. Когда стабильно зелёные — снимаем флаг.

#### Шаг 3.6 — git-хуки

```bash
mkdir -p .git-hooks
cp /tmp/skel/.git-hooks/pre-commit ./.git-hooks/
chmod +x .git-hooks/pre-commit
git config core.hooksPath .git-hooks
```

#### Шаг 3.7 — Постепенное ужесточение хуков Claude

Когда основной код приведён в форму, **верни жёсткость** хукам Claude (откати soft-режим из L2):
```bash
git checkout HEAD~ -- .claude/hooks/
chmod +x .claude/hooks/*.sh
```

## Стратегии по типу проекта

### Маленький проект (< 50 файлов)

L1 → сразу L3 за день. Baseline почти не нужен.

### Средний (50–500 файлов)

L1 → L2 (1 день) → L3 (3–5 дней). PHPStan baseline почти обязателен. Архитектурные тесты — много `ignoring()` на старте.

### Большой / legacy (500+ файлов)

L1 → L2 (живи в этом 2–4 недели, привыкай к стилю) → L3 поэтапно по модулям.
- Создай `tests/Architecture/<NewModule>Test.php` для каждого нового модуля без `ignoring`
- Старые модули остаются с `ignoring([...])` пока не дойдёт очередь
- Baseline PHPStan — обязателен. Постепенно урезаем.

## Что брать осторожно

| Файл | Почему осторожно |
|---|---|
| `composer.json` | Никогда не заменяй полностью. Бери секции: `scripts`, `require-dev`. |
| `phpstan.neon` | У тебя могут быть свои includes (например, `nesbot/carbon-phpstan`). Объединяй. |
| `ecs.php` | Разные стили — не накладывай скелетный на проект, который форматирован иначе. Запусти `ecs check --fix` в feature-branch'е, посмотри, что меняется. |
| `phpunit.xml` | Если переходишь на Pest — `phpunit.xml` от Pest не конфликтует с PHPUnit, можно оставить оба. |
| `.gitignore` | Добавляй секции, не заменяй (твоё `.gitignore` может содержать проектную специфику). |
| `init.sh` | Не нужен в существующем проекте — он для нового. |
| `tests/Pest.php` | Если у тебя есть свой `tests/TestCase.php` или `tests/CreatesApplication.php` — мерджи. |

## Что НЕ копировать в существующий проект

- `tests/TestCase.php` (если у тебя свой)
- `bootstrap/*` (если есть свой)
- `config/*` (точно нет)
- `routes/*`, `database/migrations/*`
- `.env.example` (только если у тебя его нет)

## Чек-лист после adoption

- [ ] `AGENTS.md` отражает реальные правила проекта
- [ ] `.ai/project/overview.md`, `glossary.md`, `gotchas.md` заполнены под проект
- [ ] `.ai/adr/` — старые архитектурные решения зафиксированы как ADR (минимум 3)
- [ ] `composer all` зелёный
- [ ] CI прошёл хотя бы один раз
- [ ] git-хук `pre-commit` работает
- [ ] Slash-команды Claude Code (`/task`, `/quick`, ...) запускаются
- [ ] Команда знает про `.ai/rules/...` и пользуется

## ADR

ADR-0006 (`.ai/adr/0006-existing-project-adoption.md`) — обоснование стратегии.
