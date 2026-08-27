import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// `flutter run --flavor local -t lib/main_local.dart`
///
/// Reads .env.local (API_BASE_URL defaults to the Android emulator's host
/// loopback). On a real device or iOS simulator, edit .env.local or pass
/// `--dart-define=API_BASE_URL=http://192.168.1.10:5000` to override.
Future<void> main() async {
  await AppConfig.load('.env.local');
  await bootstrap();
}
