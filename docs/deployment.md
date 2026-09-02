# Deployment pipeline

Release builds are handled by [fastlane](https://fastlane.tools), run
locally (or from any Mac for iOS). There is no hosted CI wired up yet — the
fastlane lanes themselves *are* the pipeline: each one builds, signs, and
uploads to the right track.

Both platforms expose the same four lanes, so the mental model is identical
on Android and iOS:

| Lane         | Android (Play Console track) | iOS (TestFlight / App Store)              |
|--------------|-------------------------------|--------------------------------------------|
| `internal`   | Internal testing               | Internal testers (no beta review)          |
| `alpha`      | Alpha (closed testing)         | External group **"Alpha Testers"**         |
| `beta`       | Beta (open testing)            | External group **"Beta Testers"**          |
| `production` | Production (uploaded as draft) | App Store (uploaded, not submitted)        |

`production` on both platforms uploads the build but stops short of
publishing/submitting it — you press the final "release"/"submit for
review" button yourself in Play Console / App Store Connect. This is a
deliberate safety net; remove `release_status: "draft"` /
`submit_for_review: false` in the Fastfiles once you're comfortable
automating the last step too.

## One-time setup

### 1. Install tooling

- Ruby + [Bundler](https://bundler.io/), then from `meroapp/`:
  ```
  bundle install
  ```
- [fvm](https://fvm.app) (pins the Flutter SDK version used for every
  build — see below):
  ```
  dart pub global activate fvm
  fvm install
  fvm use 3.44.4
  ```
  The pinned version lives in [`.fvmrc`](../.fvmrc). Every fastlane lane
  calls `fvm flutter ...` instead of the system `flutter`, so builds are
  reproducible regardless of what's installed globally. Set `FVM=false` in
  `.env` to fall back to the system `flutter` if you'd rather not use fvm.

### 2. Add your store credentials

Nothing above works yet because there are no real keys checked in (and
there shouldn't be — they're git-ignored). See [`keys/README.md`](../keys/README.md)
for exactly which files to drop where. In short:

1. Copy `.env.example` → `.env` at the repo root and fill in the values.
2. Copy `android/key.properties.example` → `android/key.properties` and
   fill in your release keystore details.
3. Put the actual secret files (`play-store-key.json`, `upload-keystore.jks`,
   `AuthKey.p8`) inside `keys/` — that folder is entirely git-ignored except
   for its README.

### 3. iOS-only: TestFlight groups & signing

- Create two external testing groups in App Store Connect named exactly
  `Alpha Testers` and `Beta Testers` (used by the `alpha`/`beta` lanes).
- [`ios/fastlane/ExportOptions.plist`](../ios/fastlane/ExportOptions.plist)
  ships with `signingStyle: automatic` and a `CHANGE_ME_APPLE_TEAM_ID`
  placeholder — replace it with your real Apple Developer Team ID.
- iOS builds require Xcode, so `ios` lanes must be run on macOS (or a Mac
  CI runner) even though the rest of the repo is developed on Windows.

## Running a lane

From the `meroapp/` directory:

```
bundle exec fastlane android internal
bundle exec fastlane android alpha
bundle exec fastlane android beta
bundle exec fastlane android production

bundle exec fastlane ios internal
bundle exec fastlane ios alpha
bundle exec fastlane ios beta
bundle exec fastlane ios production
```

Bump the `version:` line in [`pubspec.yaml`](../pubspec.yaml) (e.g.
`1.0.0+1` → `1.0.0+2`) before each store upload — both stores reject a
build number that's already been used.

## File map

```
meroapp/
├── Gemfile                        # fastlane's Ruby dependency
├── .env.example                   # template for the real .env (git-ignored)
├── .fvmrc                         # pinned Flutter SDK version
├── keys/README.md                 # where real secrets go (folder is git-ignored)
├── android/
│   ├── key.properties.example     # template for release keystore config
│   └── fastlane/
│       ├── Appfile                # package name + Play Console key path
│       └── Fastfile                # internal / alpha / beta / production lanes
└── ios/
    └── fastlane/
        ├── Appfile                # bundle id + Apple account info
        ├── Fastfile                # internal / alpha / beta / production lanes
        └── ExportOptions.plist    # archive export config (needs your Team ID)
```
