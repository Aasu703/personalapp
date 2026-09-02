import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// `flutter run --flavor production -t lib/main_production.dart`
/// or `flutter build appbundle --flavor production -t lib/main_production.dart`
///
/// Reads .env.production (API_BASE_URL = the deployed Render backend).
Future<void> main() async {
  await AppConfig.load('.env.production');
  await bootstrap();
}
