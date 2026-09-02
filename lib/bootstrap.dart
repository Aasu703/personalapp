import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'core/auth/session_store.dart';
import 'core/constants/route_paths.dart';
import 'core/di/providers.dart';
import 'core/logger/app_logger.dart';
import 'core/navigation/app_navigator.dart';
import 'core/network/api_client.dart';
import 'firebase_options.dart';
import 'core/storage/persistent_cookie_jar.dart';

/// Shared app startup, called by each flavor's main_*.dart entrypoint after
/// it sets [AppConfig.flavorBaseUrl].
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final cookieJar = kIsWeb ? null : await PersistentCookieJarBuilder.create();
  final sessionStore = SessionStore(const FlutterSecureStorage());
  await sessionStore.restore();

  late final ProviderContainer container;

  final dio = ApiClient.create(
    cookieJar: cookieJar,
    sessionStore: sessionStore,
    talker: AppLogger.talker,
    onSessionExpired: () async {
      await cookieJar?.deleteAll();
      container.read(currentUserProvider.notifier).state = null;
      AppNavigator.key.currentState?.pushNamedAndRemoveUntil(
        RoutePaths.login,
        (route) => false,
      );
    },
  );

  container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(const FlutterSecureStorage()),
      sessionStoreProvider.overrideWithValue(sessionStore),
      dioProvider.overrideWithValue(dio),
    ],
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const MeroApp()),
  );
}
