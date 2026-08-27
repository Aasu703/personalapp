import 'main_production.dart' as production;

/// Default entrypoint, kept for `flutter run` with no `-t`/`--flavor`.
/// Prefer `lib/main_local.dart` or `lib/main_production.dart` directly with
/// the matching `--flavor` — see docs/deployment.md.
Future<void> main() async => production.main();
