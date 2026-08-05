import 'package:flutter/material.dart';

import '../../core/constants/route_paths.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/finance/presentation/screens/add_transaction_screen.dart';
import '../../features/finance/presentation/screens/finance_home_screen.dart';
import '../../features/finance/presentation/screens/transaction_history_screen.dart';
import '../../features/health/presentation/screens/health_home_screen.dart';
import '../../features/health/presentation/screens/log_sleep_screen.dart';
import '../../features/health/presentation/screens/sleep_history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/todos/presentation/screens/add_edit_todo_screen.dart';
import '../../features/todos/presentation/screens/todo_list_screen.dart';

class AppRoutes {
  AppRoutes._();

  static Map<String, WidgetBuilder> get routes => {
    RoutePaths.splash: (_) => const SplashScreen(),
    RoutePaths.onboarding: (_) => const OnboardingScreen(),
    RoutePaths.login: (_) => const LoginScreen(),
    RoutePaths.signup: (_) => const SignupScreen(),
    RoutePaths.verifyOtp: (_) => const VerifyOtpScreen(),
    RoutePaths.forgotPassword: (_) => const ForgotPasswordScreen(),
    RoutePaths.resetPassword: (_) => const ResetPasswordScreen(),
    RoutePaths.home: (_) => const HomeScreen(),
    RoutePaths.health: (_) => const HealthHomeScreen(),
    RoutePaths.healthLog: (_) => const LogSleepScreen(),
    RoutePaths.sleepHistory: (_) => const SleepHistoryScreen(),
    RoutePaths.todos: (_) => const TodoListScreen(),
    RoutePaths.todosAdd: (_) => const AddEditTodoScreen(),
    RoutePaths.finance: (_) => const FinanceHomeScreen(),
    RoutePaths.financeAdd: (_) => const AddTransactionScreen(),
    RoutePaths.financeHistory: (_) => const TransactionHistoryScreen(),
  };
}
