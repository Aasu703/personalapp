import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build-time/runtime configuration for the app.
class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Deployed backend (Render). Last-resort fallback if dotenv wasn't
  /// loaded (e.g. a target that doesn't call AppConfig.load()).
  static const String _productionBaseUrl = 'https://sockettest-api.onrender.com';

  /// Loads the flavor's .env file. Call once from main_local.dart /
  /// main_production.dart before bootstrap().
  static Future<void> load(String envFile) => dotenv.load(fileName: envFile);

  /// Base URL for the backend API.
  ///
  /// Resolution order: `--dart-define=API_BASE_URL=...` (manual override,
  /// e.g. a LAN IP on a real device) > `.env.local`/`.env.production`
  /// (loaded via [load]) > the hardcoded production fallback.
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    final dotenvUrl = dotenv.env['API_BASE_URL'];
    if (dotenvUrl != null && dotenvUrl.isNotEmpty) return dotenvUrl;
    return _productionBaseUrl;
  }
}
