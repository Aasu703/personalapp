import 'package:flutter/material.dart';

/// App-wide navigator key so non-widget code (e.g. the auth interceptor)
/// can navigate without a BuildContext.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
