# Cross-Repo Coordination — socketTest (backend) ⟷ meroapp (Flutter)

This file is mirrored in both repos (`socketTest/docs/coordination.md` and
`meroapp/docs/coordination.md`). It exists because the two apps are built by
two separate coding agents (this repo by Cline, `meroapp` by OpenCode) that
can't see each other's session. **Read this before starting work. Append a
dated entry to the Session Log at the bottom before you stop, especially if
you changed anything that affects the other side's contract** (routes,
request/response shape, cookies, headers, status codes).

## Live API contract (as implemented, not as originally planned)

Base: `http://localhost:5000` (`http://10.0.2.2:5000` from an Android
emulator). All responses: `{ success: boolean, message: string, data?: T }`.
Errors use the same envelope with `success: false` and an appropriate HTTP
status (400/401/403/404/409/422/429).

**Auth model — read carefully, this is where most integration bugs will happen:**
- `accessToken` is returned in the **JSON body** of `login` and `refresh`
  responses. It is a bearer token — the client must send
  `Authorization: Bearer <accessToken>` on every authenticated request. It is
  **not** set as a cookie.
- `refreshToken` is set as an **httpOnly cookie** (`__Host-refreshToken` by
  default, env `REFRESH_COOKIE_NAME`). Never exposed to JSON. Sent
  automatically by the HTTP client's cookie jar to `/api/auth/refresh` and
  `/api/auth/logout`.
- `csrfToken` is returned **both** in the JSON body and as a non-httpOnly
  cookie (`csrfToken`, env `CSRF_COOKIE_NAME`). `POST /api/auth/refresh` and
  `POST /api/auth/logout` are CSRF-protected: the client must send
  `X-CSRF-Token: <csrfToken>` matching the cookie, or the request gets a 403.
  Easiest for a mobile client: just store the `csrfToken` from the response
  body and echo it back as the header — no need to read it out of the cookie
  jar.
- `GET /api/auth/me`, `DELETE /api/auth/logout-all`, `GET /api/auth/sessions`,
  `DELETE /api/auth/sessions/:sessionId` require only the bearer access
  token (no CSRF header needed — they're not cookie-authenticated state
  changes in the CSRF sense... `logout-all` still requires the bearer header
  via `authenticate`).

**Routes implemented:** `POST /register`, `POST /verify-otp`,
`POST /resend-otp`, `POST /login`, `POST /refresh`, `POST /logout`,
`DELETE /logout-all`, `GET /me`, `GET /sessions`,
`DELETE /sessions/:sessionId`, `POST /forgot-password`,
`POST /reset-password` — all under `/api/auth`.

**`/api/finance`, `/api/todos`, `/api/sleep` are now implemented** (added
2026-08-15 — see Session Log). All three require the bearer access token
(`authenticate` middleware, no CSRF — same reasoning as `/me`), are
rate-limited by the global `standardLimiter`, and are scoped to
`req.user.id` server-side (no `userId` in any request body). Shapes below
were reverse-engineered from `meroapp`'s Dio repositories, so client and
server should already agree — but verify against a real request before
assuming.

- `GET /api/finance/transactions` — query `from,to` (ISO datetime string),
  `type` (`income|expense`), `category`. `data`: bare array of
  `{ id, userId, type, amount, category, note, occurredAt, createdAt }`.
- `POST /api/finance/transactions` — body `{ type, amount, category, note?,
  occurredAt? }`. `data: { transaction }`.
- `PATCH /api/finance/transactions/:id` — partial body, same fields.
  `data: { transaction }`. 404 if not found or not owned by caller.
- `DELETE /api/finance/transactions/:id` — 404 if not found/not owned.
- `GET /api/finance/summary` — query `from,to`. `data: { summary: { income,
  expense, balance, byCategory: [{ category, total, count }] } }`.
- `GET /api/todos` — query `status` (`pending|completed`), `dueBefore`,
  `dueAfter`. `data`: bare array of `{ id, userId, title, description,
  dueDate, priority, status, completedAt, createdAt }`.
- `POST /api/todos` — body `{ title, description?, dueDate?, priority
  (low|medium|high, default medium) }`. `data: { todo }`.
- `PATCH /api/todos/:id` — partial body. `data: { todo }`.
- `PATCH /api/todos/:id/toggle` — no body, flips `status` and sets/clears
  `completedAt`. `data: { todo }`.
- `DELETE /api/todos/:id`.
- `GET /api/sleep` — query `from,to`. `data`: bare array of `{ id, userId,
  sleepAt, wokeAt, durationMinutes, quality, note, createdAt }`.
- `POST /api/sleep` — body `{ sleepAt, wokeAt, quality?, note? }`.
  `durationMinutes` is server-computed from `sleepAt`/`wokeAt`, not
  client-supplied. `data: { log }`.
- `PATCH /api/sleep/:id` — partial body; `durationMinutes` recomputed if
  either timestamp changes. `data: { log }`.
- `DELETE /api/sleep/:id`.
- `GET /api/sleep/stats` — `data: { stats: { averageDurationMinutes,
  totalEntries, currentStreakDays, trend: [{ date, durationMinutes }] } }`.
  `currentStreakDays` is a UTC-calendar-day heuristic over the last 30 logs
  (see `ponytail:` comment in `sleep-log.mongo.repository.ts`) — not
  timezone-aware, don't treat it as exact near midnight.

All single-entity responses wrap under a named key (`transaction`/`todo`/
`log`/`summary`/`stats`); list responses are a bare array under `data`. This
matches what `FinanceRepositoryImpl`/`TodoRepositoryImpl`/
`SleepRepositoryImpl` already expect — no Flutter-side change needed.

## Known open issues

| # | Owner | Issue | Status |
|---|---|---|---|
| 1 | Backend (Cline) | ~~Refresh cookie has `secure: true` hardcoded...~~ **FIXED 2026-08-05**: refresh cookie `secure` now follows the env-driven `cookieConfig.secure`, and is only forced on when the configured cookie name uses a `__Host-` prefix (which mandates it). Dev should configure `REFRESH_COOKIE_NAME=refreshToken` (plain, works over plain HTTP so `cookie_jar` stores it); production sets `REFRESH_COOKIE_NAME=__Host-refreshToken` (forced Secure). `.env`/`.env.example` updated. | RESOLVED |
| 2 | Flutter (OpenCode) | `ApiClient`/`AuthInterceptor` don't yet implement the bearer-token + CSRF-header handling described above. As written they assume a pure httpOnly-cookie model. Needs: attach `Authorization: Bearer` from stored `accessToken`; on refresh, re-store `accessToken`/`csrfToken` from the response body; send `X-CSRF-Token` on `/refresh` and `/logout`. | OPEN |
| 3 | Flutter (OpenCode) | `flutter analyze` currently reports ~40 issues, several blocking: `core/di/providers.dart` references `features/todos/*` and `features/finance/*` repo files that don't exist yet; missing `RoutePaths.verifyOtp` / `.healthLog` / `.sleepHistory`; undefined `PersistCookieJar`; `main.dart` uses a variable before it's declared. `AuthRepositoryImpl` is still the original fake-data stub. | OPEN |
| 4 | Backend (Cline) | `container.ts`/`app.ts` DI wiring had drifted from the controller (missing csrfProtection, missing use-case deps, wrong constructor arities). | RESOLVED — fixed already, `npm run build` passes clean. |
| 5 | Both | Backend has grown scope beyond the original Flutter plan doc: `logout-all`, session list/revoke, forgot/reset-password are live. Flutter has forgot/reset **screens** already but they're stubbed, not wired to these routes yet. Not blocking for v1 auth, but don't forget it exists. | OPEN / low priority |
| 6 | Backend | `/api/finance`, `/api/todos`, `/api/sleep` didn't exist — Flutter repositories called them against nothing. | RESOLVED 2026-08-15 — see contract section above. |

## Session Log

Append a dated entry here each time you finish meaningful work, especially
anything touching the contract above.

- 2026-08-05 — (external review) Diagnosed issues #1–#5 above; confirmed backend
  builds clean after Cline's own fix to container.ts/app.ts.
- 2026-08-05 — (Cline) Resolved Issue #1: refresh cookie `secure` no longer
  hardcoded. It now follows `cookieConfig.secure` unless the configured name uses
  a `__Host-` prefix (which mandates `Secure`). Dev `.env` now uses
  `REFRESH_COOKIE_NAME=refreshToken` (plain) so the Flutter `cookie_jar` can store
  the refresh cookie over plain HTTP; production should use
  `REFRESH_COOKIE_NAME=__Host-refreshToken`. **Flutter side unchanged** — it still
  stores `accessToken`/`csrfToken` from the JSON body and echoes
  `X-CSRF-Token` on `/refresh`/`/logout`; it only needs to make sure its cookie jar
  is configured to persist cookies for the plain-HTTP dev host (which it now can).
- 2026-08-06 — (Cline) Added a proper structured logger (pino):
  - `src/shared/logger/logger.ts` now redacts secrets (passwords, tokens, OTP
    codes, `Authorization`/`Cookie` headers), uses pretty colourised output in
    dev, raw JSON in production (with `service=sockettest`), is silenced in
    tests, and respects a new optional `LOG_LEVEL` env var (default: `debug` in
    dev, `info` in prod). Added `createLogger(name)` for module-tagged child
    loggers. Replaced all `console.*` calls in `database.ts`,
    `nodemailer.otp-sender.ts`, and `errorHandler.ts` (which now logs the request
    id on unhandled errors). Dev dependency added: `pino-pretty`.
  - **New response header `X-Request-Id`** on every response — echoes the request
    id so client logs can correlate with server logs. It honours an inbound
    `X-Request-Id` if the client sends one. **Flutter side (optional)**: you can
    send your own `X-Request-Id` on requests and/or read it from responses to tie
    your logs to specific backend requests. No change required for auth to keep
    working.
- 2026-08-15 — (Claude) Backend hardening pass + net-new feature routes, no
  Flutter-side changes required:
  - `app.set("trust proxy", 1)` — required correctness fix once this sits
    behind a TLS-terminating proxy (secure cookies and rate-limit IP keying
    both silently break without it).
  - `standardLimiter` (100/15m) now applied globally in `app.ts`; auth
    routes still additionally get the stricter `strictAuthLimiter`.
  - `env.ts` now rejects boot in `NODE_ENV=production` if
    `ACCESS_TOKEN_SECRET`/`REFRESH_TOKEN_SECRET` are the `.env.example`
    placeholder or under 32 chars, if SMTP config is empty, or if
    `CLIENT_URL` still points at localhost.
  - `validate` middleware now validates `query`/`params` in addition to
    `body` (pass `{ body?, query?, params? }` instead of a bare schema) —
    needed so the new list endpoints can reject bad filters instead of
    500ing. Note: Express 5 makes `req.query` getter-only, so query
    validation overwrites it via `Object.defineProperty`, not assignment.
  - `authenticate.ts` no longer falls back to an `accessToken` cookie —
    bearer-only, matching this doc's contract exactly. If anything was
    relying on the cookie fallback it will now 401; nothing on the Flutter
    side should have been (contract has always said bearer-only).
  - `server.ts` now has `unhandledRejection`/`uncaughtException` handlers
    (log + exit, so a process supervisor restarts cleanly).
  - Added `.github/workflows/ci.yml` (build + test on push/PR to
    `main`/`dev`, Node 20.x/22.x matrix). Tests run against fakes, no DB
    needed in CI.
  - Added the three feature modules — see contract section above for
    routes/shapes. Each follows the existing hexagonal layering
    (domain/application/infrastructure/presentation) and reuses
    `authenticate`/`standardLimiter`/`validate`/`errorHandler`; no new
    middleware or patterns introduced. Domain entities for these three are
    plain data interfaces (not classes with private constructors like
    `User`/`RefreshToken`) since transactions/todos/sleep logs have no
    invariants to encapsulate — don't take that as the new house style for
    entities that *do* have behavior.
  - `npm run build` and `npm test` both pass clean after this batch (20/20
    tests, no new tests added — no new business logic worth a unit test
    beyond what type-checking + the existing integration test already
    cover; add real endpoint tests when `/api/finance` etc. get exercised
    for real).
- 2026-08-26 — Backend is now deployed on Render at
  `https://sockettest-api.onrender.com` (service name `sockettest-api` per
  `render.yaml`). `meroapp`'s `AppConfig.apiBaseUrl` fallback (used when no
  `--dart-define=API_BASE_URL` is passed) now points here instead of
  `localhost`/`10.0.2.2` — this was the root cause of auth failing during
  Play Console internal testing (release builds can't reach a loopback
  address, and Android release blocks cleartext HTTP anyway; this URL is
  HTTPS so both problems are gone).
  - Found and fixed a real bug while testing connectivity: `POST
    /api/auth/register` hung indefinitely (not an error — zero bytes, no
    timeout) because `NodemailerOtpSender`'s transporter
    (`infrastructure/email/nodemailer.otp-sender.ts`) had no
    `connectionTimeout`/`greetingTimeout`/`socketTimeout` set, so an
    unreachable/misconfigured SMTP host hangs the whole request forever
    instead of failing. Added 10s timeouts on all three — same fix covers
    both `sendOtpEmail` and `sendPasswordResetEmail` since they share one
    transporter. **Still needs verification**: whoever set the Render env
    vars should double check `SMTP_HOST`/`SMTP_PORT`/`SMTP_USER`/`SMTP_PASS`
    are correct and the provider is actually reachable from Render's
    network — the timeout fix makes failures visible (500 instead of a
    hang) but doesn't fix a bad SMTP config itself. `/health` and
    `/api/auth/login` were confirmed working end-to-end against the live
    deployment before this fix.
