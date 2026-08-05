# Personal Tracker Features Implementation Plan — meroapp

## 1. Overview
meroapp today is a fully mocked auth flow (Splash → Onboarding → Login/Signup/Forgot/Reset → placeholder Home) with **no networking, no state-management library, no local persistence, and no JSON serialization**. This plan wires it up to the real `socketTest` backend and adds three new feature modules — **Health (sleep tracking)**, **Todos**, and **Finance** — each built with the same feature-based Clean Architecture split (`domain` / `data` / `presentation`) already used by the `auth` feature.

**New dependencies to add to `pubspec.yaml`:**
- `flutter_riverpod` — state management, replaces the hand-rolled `ServiceLocator` (its own doc-comment says "swap for provider/get_it when needed")
- `dio` — HTTP client (cookie-based JWT auth needs interceptors for attach + 401→refresh, which raw `http` makes painful)
- `flutter_secure_storage` — not for the JWTs themselves (those are httpOnly cookies, inaccessible to JS/Dart by design) but for the `dio` cookie jar persistence and any client-side "remember me" state
- `dio_cookie_manager` + `cookie_jar` — persist the httpOnly auth cookies across app restarts (the backend uses cookie auth, not bearer tokens, so the mobile client needs a persistent cookie jar)
- `intl` — date/time formatting across all three new features

## 2. Architecture & Design Patterns
Keep the existing pattern: feature-first folders, each with `domain/` (entities, repository interfaces, use cases), `data/` (models with `fromJson`/`toJson`, repository implementations calling the API), `presentation/` (screens, widgets, Riverpod providers). This is exactly the shape `features/auth/` already has — extend it, don't replace it.

Replace `core/di/service_locator.dart` with Riverpod providers under `core/di/providers.dart` (a `Provider`/`Provider.family` per repository), since Riverpod supersedes the manual locator directly.

### 2.1 Directory layout (additions/changes)
```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart         # Dio instance: baseUrl, cookie jar, timeouts
│   │   ├── auth_interceptor.dart   # on 401: call /api/auth/refresh once, retry original request
│   │   └── api_exception.dart      # maps ApiError-shaped backend errors to a typed exception
│   ├── storage/
│   │   └── persistent_cookie_jar.dart  # wraps dio_cookie_manager + PathProvider dir
│   └── di/
│       └── providers.dart          # riverpod Provider<ApiClient>, Provider<AuthRepository>, etc. — replaces service_locator.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/{user_model.dart, auth_result_model.dart}   # fromJson/toJson, wrap existing entities
│   │   │   └── repositories/auth_repository_impl.dart              # REWRITE: real Dio calls to /api/auth/*, remove stub
│   │   └── presentation/screens/verify_otp_screen.dart              # NEW — backend requires OTP verify after register; currently missing from the app entirely
│   ├── health/
│   │   ├── domain/
│   │   │   ├── entities/sleep_log.dart
│   │   │   ├── repositories/sleep_repository.dart
│   │   │   └── usecases/{log_sleep, update_sleep_log, delete_sleep_log, get_sleep_logs, get_sleep_stats}.dart
│   │   ├── data/
│   │   │   ├── models/sleep_log_model.dart
│   │   │   └── repositories/sleep_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/sleep_providers.dart         # riverpod StateNotifier/AsyncNotifier for list+stats
│   │       ├── screens/{health_home_screen, log_sleep_screen, sleep_history_screen}.dart
│   │       └── widgets/{sleep_summary_card, sleep_entry_tile}.dart
│   ├── todos/
│   │   ├── domain/{entities/todo.dart, repositories/todo_repository.dart, usecases/{create,update,toggle,delete,list}_todo*.dart}
│   │   ├── data/{models/todo_model.dart, repositories/todo_repository_impl.dart}
│   │   └── presentation/
│   │       ├── providers/todo_providers.dart
│   │       ├── screens/{todo_list_screen, add_edit_todo_screen}.dart
│   │       └── widgets/{todo_tile, priority_badge}.dart
│   ├── finance/
│   │   ├── domain/{entities/transaction.dart, repositories/finance_repository.dart, usecases/{create,update,delete,list}_transaction*.dart, usecases/get_finance_summary.dart}
│   │   ├── data/{models/transaction_model.dart, repositories/finance_repository_impl.dart}
│   │   └── presentation/
│   │       ├── providers/finance_providers.dart
│   │       ├── screens/{finance_home_screen, add_transaction_screen, transaction_history_screen}.dart
│   │       └── widgets/{balance_card, transaction_tile, category_chip}.dart
│   └── home/presentation/home_screen.dart   # REWRITE: real dashboard, not the "Logged in successfully" placeholder
```

## 3. Networking Foundation
- `ApiClient` (`core/network/api_client.dart`): single `Dio` instance, `baseUrl` from a build-time config (dev default `http://10.0.2.2:5000` for Android emulator / `http://localhost:5000` for iOS sim/web), `PersistCookieJar` attached via `CookieManager` interceptor so the backend's httpOnly `accessToken`/`refreshToken` cookies survive app restarts exactly like a browser would hold them.
- `AuthInterceptor`: on a `401` response, calls `POST /api/auth/refresh` once (cookie-based, no body needed), and if that succeeds retries the original request; if refresh also fails, clears local state and the app should route to `/login`.
- `ApiException`: parses the backend's uniform `{ success, message, data }` / error shape into a typed Dart exception surfaced to the UI layer as a message.
- Every new `*_repository_impl.dart` (auth, sleep, todo, finance) is a thin adapter: build the request, call `ApiClient`, map JSON → domain entity via the matching `*_model.dart`. This mirrors exactly how the backend's `*.mongo.repository.ts` files adapt Mongoose to domain entities — same pattern, opposite direction.

## 4. Auth Flow Gap (must fix before other features are useful)
The backend's register flow is register → **verify-otp** → login; the Flutter signup screen currently just calls a stub and jumps straight to Home. Need to:
1. Add `verify_otp_screen.dart` (6-digit code entry + resend), reached after signup.
2. Add `VerifyOtp`/`ResendOtp` use cases + repository methods, mirroring the existing `Login`/`Signup` use-case shape in `features/auth/domain/usecases/`.
3. Give `User`/`AuthResult` real `fromJson`/`toJson` (currently plain classes with no serialization) matching the backend's `{ id, name, email, isVerified }` shape from `GET /api/auth/me`.

## 5. Feature Modules (Health / Todos / Finance)
Each of the three follows an identical internal shape (domain → data → presentation), so it's described once:
- **Domain**: a plain entity class (mirrors the backend entity fields 1:1), a repository interface, and one use-case class per operation (thin wrappers calling the repository — keeps parity with the backend's use-case-per-operation pattern and keeps screens free of business logic).
- **Data**: a `*_model.dart` extending/wrapping the entity with `fromJson`/`toJson`, and a `*_repository_impl.dart` implementing the domain interface via `ApiClient` calls to the matching backend routes from the backend's `features-implementation-plan.md` §5.
- **Presentation**: a Riverpod provider (`AsyncNotifier` for list+detail state, e.g. `sleepLogsProvider`, `todosProvider`, `transactionsProvider` + a `financeSummaryProvider`), screens for list/detail/add-edit, and small reusable widgets (summary card, list tile).

Specifics per module:
- **Health**: `health_home_screen.dart` shows last night's duration + a "log sleep" CTA (two-tap flow: "went to bed" then "woke up", or a single retroactive-entry form — support the form first, it's simpler and covers both cases) and a 7-day trend from `GetSleepStats`.
- **Todos**: `todo_list_screen.dart` with status filter (pending/completed) and priority sort; swipe-to-complete/delete; `add_edit_todo_screen.dart` for title/description/due date/priority.
- **Finance**: `finance_home_screen.dart` shows `balance_card` (from `GetFinanceSummary`) + recent transactions; `add_transaction_screen.dart` for income/expense entry; `transaction_history_screen.dart` with date-range/category filters.

## 6. Dashboard & Navigation
- Rewrite `features/home/presentation/home_screen.dart` into a real dashboard: three summary cards (last sleep, todos due today, finance balance) each navigating into its feature's list screen, replacing the current "Logged in successfully" placeholder.
- Add route constants in `core/constants/route_paths.dart` and entries in `app/routes/app_routes.dart` for: `/verify-otp`, `/health`, `/health/log`, `/todos`, `/todos/add`, `/finance`, `/finance/add`, `/finance/history` — same Navigator 1.0 named-route style already in use, no need to introduce go_router for this scope.

## 7. Implementation Order
1. `pubspec.yaml` — add `flutter_riverpod`, `dio`, `dio_cookie_manager`, `cookie_jar`, `flutter_secure_storage`, `intl`; wrap `main.dart`'s root widget in `ProviderScope`
2. `core/network/` (ApiClient, AuthInterceptor, ApiException) + `core/storage/persistent_cookie_jar.dart`
3. `core/di/providers.dart` — replace `service_locator.dart`; update all call sites (`login_screen.dart`, `signup_screen.dart`, etc. currently pulling from `ServiceLocator.instance`)
4. Auth: real `AuthRepositoryImpl`, `User`/`AuthResult` JSON models, `verify_otp_screen.dart` + use cases (§4) — validate end-to-end against the running backend before moving on, since every other feature depends on a working session
5. Health module (domain → data → presentation)
6. Todos module (domain → data → presentation)
7. Finance module (domain → data → presentation)
8. Dashboard rewrite (`home_screen.dart`) + route wiring
9. Manual verification (see §8)

## 8. Manual Verification
- Start backend: `npm run dev` in `socketTest` (requires local MongoDB running).
- Run app against it (`flutter run`), full flow: signup → verify OTP (check dev SMTP/console per backend's nodemailer config) → login → land on dashboard.
- Exercise each feature's create/list/update/delete against the real API; confirm data survives app restart (session persists via cookie jar) and confirm a second test account never sees the first account's data (ownership scoping from backend plan §6).
- No automated test suite exists on either side yet — this stays a manual smoke test for v1, same as the backend's own auth plan.

## 9. Explicitly out of scope for v1
- Offline-first / local DB sync
- Push notifications / reminders
- Charts beyond simple trend numbers (no charting library added yet)
