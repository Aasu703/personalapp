# Cross-Repo Coordination — socketTest (backend) ⟷ meroapp (Flutter)

This file is mirrored in both repos (`socketTest/docs/coordination.md` and
`meroapp/docs/coordination.md`). It exists because the two apps are built by
two separate coding agents (this repo by OpenCode, `socketTest` by Cline)
that can't see each other's session. **Read this before starting work.
Append a dated entry to the Session Log at the bottom before you stop,
especially if you changed anything that affects the other side's contract**
(routes, request/response shape, cookies, headers, status codes).

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
  `/api/auth/logout` — as long as the cookie jar actually stores it (see
  issue #1 below, currently broken over plain HTTP dev).
- `csrfToken` is returned **both** in the JSON body and as a non-httpOnly
  cookie (`csrfToken`, env `CSRF_COOKIE_NAME`). `POST /api/auth/refresh` and
  `POST /api/auth/logout` are CSRF-protected: send
  `X-CSRF-Token: <csrfToken>` matching the cookie, or the request gets a 403.
  Easiest approach: store the `csrfToken` from the response body in memory
  and echo it back as the header — no need to read it out of the cookie jar.
- `GET /api/auth/me`, `DELETE /api/auth/logout-all`, `GET /api/auth/sessions`,
  `DELETE /api/auth/sessions/:sessionId` require only the bearer access
  token via the `Authorization` header.

**Routes implemented:** `POST /register`, `POST /verify-otp`,
`POST /resend-otp`, `POST /login`, `POST /refresh`, `POST /logout`,
`DELETE /logout-all`, `GET /me`, `GET /sessions`,
`DELETE /sessions/:sessionId`, `POST /forgot-password`,
`POST /reset-password` — all under `/api/auth`.

## Known open issues

| # | Owner | Issue | Status |
|---|---|---|---|
| 1 | Backend (Cline) | Refresh cookie has `secure: true` **hardcoded** (required for the `__Host-` prefix). Over the plain-HTTP dev backend this app talks to, `cookie_jar` will silently refuse to store/send it — refresh will never work in dev, sessions won't survive app restart. Waiting on the backend to make `secure` env-conditional and use a plain cookie name in dev. Until fixed, don't rely on session persistence across restarts in manual testing — that's a known backend gap, not a bug in this app. | OPEN |
| 2 | Flutter (OpenCode) | `ApiClient`/`AuthInterceptor` don't yet implement the bearer-token + CSRF-header handling described above. Current code assumes a pure httpOnly-cookie model with no bearer header and no CSRF header — every authenticated call will 401 and refresh/logout will 403 until this is fixed. Needs: attach `Authorization: Bearer` from a stored `accessToken`; on refresh, re-store `accessToken`/`csrfToken` from the response body; send `X-CSRF-Token` on `/refresh` and `/logout`. | RESOLVED — `SessionStore` (in-memory + persisted to secure storage) holds `accessToken`/`csrfToken`; `AuthInterceptor` attaches `Authorization: Bearer` to all non-public routes and `X-CSRF-Token` on `/refresh`/`/logout`; single-attempt refresh with retry. Login/refresh store tokens from the JSON body; logout clears them. |
| 3 | Flutter (OpenCode) | `flutter analyze` currently reports ~40 issues, several blocking: `core/di/providers.dart` references `features/todos/*` and `features/finance/*` repo files that don't exist yet; missing `RoutePaths.verifyOtp` / `.healthLog` / `.sleepHistory`; undefined `PersistCookieJar`; `main.dart` uses a variable before it's declared. `AuthRepositoryImpl` is still the original fake-data stub — real backend wiring per §4 of `implementation-plan.md` hasn't landed yet even though Health/Todos/Finance scaffolding has started. | RESOLVED — `flutter analyze` is clean (0 issues). Real Dio-backed `AuthRepositoryImpl` wired; Health/Todos/Finance modules (entities, repos, providers, screens) landed and routed. |
| 4 | Backend (Cline) | `container.ts`/`app.ts` DI wiring had drifted from the controller (missing csrfProtection, missing use-case deps, wrong constructor arities). | RESOLVED — fixed already, `npm run build` passes clean. |
| 5 | Both | Backend has grown scope beyond the original plan doc: `logout-all`, session list/revoke, forgot/reset-password are live. This app has forgot/reset **screens** already but they're stubbed, not wired to these routes yet. Not blocking for v1 auth, but don't forget it exists. | PARTIAL — forgot/reset screens now wired to the real routes; reset-password sends `token` from a new field (backend requires it in the DTO). `logout-all` and `sessions` list/revoke still unimplemented in the app. |

## Session Log

Append a dated entry here each time you finish meaningful work, especially
anything touching the contract above.

- 2026-08-05 — (external review) Diagnosed issues #1–#5 above; confirmed backend
  builds clean after Cline's own fix to container.ts/app.ts.
- 2026-08-05 — Flutter auth networking reworked to match the live contract:
  added `core/auth/session_store.dart` (bearer `accessToken` + `csrfToken`,
  in-memory and persisted in `flutter_secure_storage`); `AuthInterceptor` now
  sends `Authorization: Bearer` on all non-public routes and `X-CSRF-Token` on
  `/refresh`/`/logout`, refreshes once on 401 (and on 403 from logout) and
  clears the session on refresh failure. `AuthRepositoryImpl` stores
  `accessToken`/`csrfToken` from the login JSON body; reset-password now sends
  `token` (new field on the reset screen, required by the backend DTO). Marked
  issues #2 and #3 resolved, #5 partial. `flutter analyze`: 0 issues.
