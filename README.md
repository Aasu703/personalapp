# meroapp

Personal dashboard app: auth, sleep/health tracking, todos, and finance
tracking in one Flutter client. Talks to the `socketTest` backend (sibling
directory) over HTTP.

## Features

- **Auth** — login, signup, OTP verification, forgot/reset password
- **Health** — sleep logging and stats
- **Todos** — task CRUD
- **Finance** — transactions and summaries
- Onboarding / splash / home shell screens

## Architecture

Feature-based clean architecture under `lib/`:

```
lib/
├── app/                  # MaterialApp shell + route table
├── core/
│   ├── auth/             # SessionStore — bearer accessToken + csrfToken
│   ├── config/           # API_BASE_URL resolution (dart-define)
│   ├── di/providers.dart # Riverpod composition root
│   ├── network/          # Dio client + auth/CSRF/refresh interceptor
│   └── storage/          # cookie jar for httpOnly refresh token
└── features/<feature>/
    ├── domain/            # entities, repository contracts, use cases (pure Dart)
    ├── data/              # DTOs + Dio-backed repository implementations
    └── presentation/      # screens, widgets, Riverpod providers
```

State management: Riverpod. Networking: a single `Dio` instance
(`ApiClient`) with cookie-jar persistence and an `AuthInterceptor` that
attaches `Authorization`/`X-CSRF-Token` headers and retries once on 401 via
token refresh. Logging goes through `Talker`, redacting auth secrets.

See [`docs/coordination.md`](docs/coordination.md) for the live API
contract and known cross-repo issues — it's the source of truth over the
older plan docs, and is mirrored in `socketTest/docs/coordination.md`.

> **Note:** `core/di/providers.dart` currently wires auth to
> `FirebaseAuthRepositoryImpl`, not the backend-backed
> `AuthRepositoryImpl` — despite the detailed backend auth contract, auth
> in the running app bypasses `socketTest` entirely. Check
> `providers.dart` before assuming otherwise.

## Getting started

Pinned Flutter SDK: `3.44.4` via [fvm](https://fvm.app) (`.fvmrc`). Either
`fvm flutter ...` or a plain `flutter ...` matching that version works.

```bash
flutter pub get                 # install deps
flutter analyze                 # lint/type-check — keep at 0 issues
flutter test                    # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000   # point at a non-default backend host
```

Default backend host is `http://localhost:5000` (or `10.0.2.2:5000` from
the Android emulator).

## Deployment

Store builds (internal / alpha / beta / production, Android + iOS) go
through fastlane. See [`docs/deployment.md`](docs/deployment.md) for setup
and lane usage. Bump `version:` in `pubspec.yaml` before every store
upload.
