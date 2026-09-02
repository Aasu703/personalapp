import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// `flutter run --flavor staging -t lib/main_staging.dart`
/// or `flutter build appbundle --flavor staging -t lib/main_staging.dart`
///
/// Reads .env.staging (API_BASE_URL = the deployed staging backend, kept
/// separate from production so QA builds never touch prod data).
Future<void> main() async {
  await AppConfig.load('.env.staging');
  await bootstrap();
}
