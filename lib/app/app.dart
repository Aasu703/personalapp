import 'package:flutter/material.dart';

import '../core/constants/route_paths.dart';
import '../core/navigation/app_navigator.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class MeroApp extends StatelessWidget {
  const MeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeroApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: RoutePaths.splash,
      routes: AppRoutes.routes,
    );
  }
}
