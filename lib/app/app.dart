import 'package:flutter/material.dart';

import '../core/constants/route_paths.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class MeroApp extends StatelessWidget {
  const MeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeroApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: RoutePaths.splash,
      routes: AppRoutes.routes,
    );
  }
}
