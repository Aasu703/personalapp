import 'package:flutter/material.dart';

import '../../core/constants/route_paths.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static Map<String, WidgetBuilder> get routes => {
    RoutePaths.splash: (_) => const SplashScreen(),
    RoutePaths.onboarding: (_) => const OnboardingScreen(),
    RoutePaths.login: (_) => const LoginScreen(),
    RoutePaths.signup: (_) => const SignupScreen(),
    RoutePaths.forgotPassword: (_) => const ForgotPasswordScreen(),
    RoutePaths.resetPassword: (_) => const ResetPasswordScreen(),
    RoutePaths.home: (_) => const HomeScreen(),
  };
}
