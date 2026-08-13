# keys/

This folder holds the real store-signing secrets. Everything except this
file is git-ignored (`/keys/*` in `.gitignore`) — nothing here is ever
committed.

Once you have your Google Play Console and Apple Developer accounts ready,
drop the following files in here:

| File                     | What it is                                              | Where to get it |
|---------------------------|----------------------------------------------------------|------------------|
| `play-store-key.json`     | Google Play service-account key (JSON)                   | Play Console → Setup → API access → Service accounts |
| `upload-keystore.jks`     | Android release signing keystore                          | Generate with `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` |
| `AuthKey.p8`               | App Store Connect API key                                 | App Store Connect → Users and Access → Integrations → App Store Connect API |

After adding a file, fill in the matching values in `.env` (copy it from
`.env.example` at the repo root) and, for Android signing, in
`android/key.properties` (copy it from `android/key.properties.example`).

See [`docs/deployment.md`](../docs/deployment.md) for the full setup guide.