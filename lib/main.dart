import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/constants/route_paths.dart';
import 'core/di/providers.dart';
import 'core/navigation/app_navigator.dart';
import 'core/network/api_client.dart';
import 'core/storage/persistent_cookie_jar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cookieJar = kIsWeb ? null : await PersistentCookieJarBuilder.create();

  final container = ProviderContainer(
    overrides: [
      cookieJarProvider.overrideWithValue(
        cookieJar ?? PersistCookieJar(),
      ),
      dioProvider.overrideWithValue(
        ApiClient.create(
          cookieJar: cookieJar,
          onSessionExpired: () async {
            await cookieJar?.deleteAll();
            container.read(currentUserProvider.notifier).state = null;
            AppNavigator.key.currentState?.pushNamedAndRemoveUntil(
              RoutePaths.login,
              (route) => false,
            );
          },
        ),
      ),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MeroApp(),
    ),
  );
}
