---
description: Security review — OWASP top 10 + Laravel-specific
argument-hint: []
---

# /security — Security review

Делаешь security review текущей ветки или указанного scope.

Аргумент: `$ARGUMENTS` — путь / область (опц., иначе вся ветка относительно `<MAIN-BRANCH>`).

## Шаги

1. **Получи изменения:**
   ```bash
   git diff <MAIN-BRANCH>..HEAD -- "*.php" "*.vue" "*.ts" "*.blade.php" "*.sql"
   ```

2. **Прочитай:**
   - `.ai/rules/backend/code-style.md` (security-related)
   - `.ai/project/gotchas.md`

3. **Прогон по чек-листу.** Для каждой найденной проблемы — severity (P1/P2/P3) + предложение исправления.

## Чек-лист

### OWASP Top 10 (web)

#### A01 — Broken Access Control
- [ ] FormRequest `authorize()` не возвращает `true` без причины
- [ ] Use `$user->can('action', $resource)` вместо своих проверок
- [ ] Route model binding с явной авторизацией (`->canBe()`)
- [ ] Нет endpoint'ов без middleware `auth` где должна быть аутентификация
- [ ] IDOR (insecure direct object reference) — проверки владения ресурсом

#### A02 — Cryptographic Failures
- [ ] Пароли — `bcrypt` / `argon2` (Laravel `Hash::make`)
- [ ] Секреты — в `.env`, не в коде
- [ ] HTTPS only в проде (HSTS)
- [ ] Cookies: `Secure`, `HttpOnly`, `SameSite=Lax`
- [ ] Не логируем пароли, токены, PII

#### A03 — Injection

##### SQL injection
- [ ] Eloquent / Query Builder с параметрами (не сырые `DB::raw` со склейкой)
- [ ] Если `whereRaw` — параметризовано
- [ ] User input не передаётся в `orderBy()` без whitelist

##### XSS
- [ ] Blade `{{ }}` (auto-escape) вместо `{!! !!}`
- [ ] Vue: `v-html` только на сан-итизированных данных
- [ ] HTTP response Content-Type явно

##### Command injection
- [ ] Нет `exec()` / `system()` / `shell_exec()` с user input
- [ ] `Process::run([...])` (массив-форма), не строка

##### LDAP / NoSQL / etc.
- [ ] При наличии — параметризовано

#### A04 — Insecure Design
- [ ] Rate limiting на login, password reset, public endpoints (`Route::middleware('throttle:...')`)
- [ ] CAPTCHA там, где автоматизация может вредить
- [ ] Нет «admin panel by URL knowledge» (требует роли)

#### A05 — Security Misconfiguration
- [ ] `APP_DEBUG=false` в проде
- [ ] CORS — whitelist, не `*`
- [ ] `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `CSP`
- [ ] Storage public/private разделены

#### A06 — Vulnerable Components
- [ ] `composer audit` (или `composer require --dev roave/security-advisories:dev-latest`)
- [ ] `npm audit`
- [ ] Зависимости актуальны

#### A07 — Identification and Authentication Failures
- [ ] Lockout после N неудач
- [ ] Password policy (длина, сложность, breached check через k-anonymity)
- [ ] 2FA для админов
- [ ] Session timeout, regenerate on login

#### A08 — Software and Data Integrity Failures
- [ ] Webhook signatures проверяются
- [ ] CSRF на форму (Laravel `@csrf`)
- [ ] Файлы загружаемые — валидация MIME/extension/размер; storage вне webroot

#### A09 — Logging and Monitoring Failures
- [ ] Authentication события логируются
- [ ] Authorization failures логируются
- [ ] Logs не утекают в публичный доступ

#### A10 — Server-Side Request Forgery (SSRF)
- [ ] Если приложение делает HTTP-запросы по user input — whitelist hostnames

### Laravel-specific

- [ ] **Mass Assignment:** `$fillable` определён в каждой модели, или используется `$guarded = []` с `forceFill()`
- [ ] **Route Model Binding** — с `findOrFail`, не молчаливый `null`
- [ ] **Query scopes** не пропускают user input в WHERE без валидации
- [ ] **Tenant isolation** — если multi-tenant: каждый запрос фильтруется по tenant_id (global scope)
- [ ] **Telescope / Debugbar** — отключены в проде (или защищены)
- [ ] **Vapor / Octane** — концепция «request-bound state» соблюдается (нет мутаций синглтонов между запросами)

### Frontend-specific (Vue/TS)

- [ ] Нет `eval()` / `new Function()`
- [ ] `dangerouslySetInnerHTML` / `v-html` только на санитизованном
- [ ] Локальное хранилище (`localStorage`) — без секретов
- [ ] CSRF token в headers для запросов с состоянием

## Формат отчёта

```markdown
# Security Review — <branch>

## P1 (block merge)
1. **{Title}** at `path:line`
   {описание}
   **Fix:** {что сделать}

## P2 (желательно)
1. **{Title}** at `path:line`
   {...}

## P3 (опц.)
1. ...

## Не нашли проблем в:
- A02 (cryptography) — пароли через Hash, секреты в .env
- ...

## Verdict
- {N} P1 issues — block merge
- {N} P2 issues — fix before deploy
- {N} P3 issues — track for later
```
