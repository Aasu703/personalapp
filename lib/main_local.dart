import 'bootstrap.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  await AppConfig.load('.env.local');
  await bootstrap();
}
