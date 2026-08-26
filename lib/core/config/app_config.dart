/// Build-time configuration for the app.
class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Deployed backend (Render). This is the default for release builds and
  /// anyone running without a --dart-define override.
  static const String _productionBaseUrl = 'https://sockettest-api.onrender.com';

  /// Base URL for the backend API.
  ///
  /// Override at build time to point at a local dev server instead, e.g.:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000`
  /// (use `http://10.0.2.2:5000` on the Android emulator to reach your host machine)
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return _productionBaseUrl;
  }
}
