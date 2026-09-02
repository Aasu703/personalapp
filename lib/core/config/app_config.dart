import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String _productionBaseUrl =
      'https://sockettest-api.onrender.com';

  static Future<void> load(String envFile) => dotenv.load(fileName: envFile);
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    final dotenvUrl = dotenv.env['API_BASE_URL'];
    if (dotenvUrl != null && dotenvUrl.isNotEmpty) return dotenvUrl;
    return _productionBaseUrl;
  }
}
