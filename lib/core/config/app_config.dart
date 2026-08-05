import 'package:flutter/foundation.dart';

/// Build-time configuration for the app.
class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL for the backend API.
  ///
  /// Override at build time with:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000`
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }
}
