import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/session_store.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/resend_otp.dart';
import '../../features/auth/domain/usecases/reset_password.dart';
import '../../features/auth/domain/usecases/signup.dart';
import '../../features/auth/domain/usecases/verify_otp.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/health/data/repositories/sleep_repository_impl.dart';
import '../../features/health/domain/repositories/sleep_repository.dart';
import '../../features/todos/data/repositories/todo_repository_impl.dart';
import '../../features/todos/domain/repositories/todo_repository.dart';

/// Overridden in `main()` with the pre-built instances.
final cookieJarProvider = Provider<PersistCookieJar>(
  (ref) => throw UnimplementedError('cookieJarProvider is overridden in main()'),
);

final dioProvider = Provider<Dio>(
  (ref) => throw UnimplementedError('dioProvider is overridden in main()'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Bearer/CSRF tokens for the current session. Overridden in `main()`.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => throw UnimplementedError('sessionStoreProvider is overridden in main()'),
);

/// Currently signed-in user, if any.
final currentUserProvider = StateProvider<User?>((ref) => null);

// ---- Auth ----
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(sessionStoreProvider),
  ),
);

final loginProvider = Provider<Login>((ref) => Login(ref.watch(authRepositoryProvider)));
final signupProvider = Provider<Signup>((ref) => Signup(ref.watch(authRepositoryProvider)));
final verifyOtpProvider = Provider<VerifyOtp>((ref) => VerifyOtp(ref.watch(authRepositoryProvider)));
final resendOtpProvider = Provider<ResendOtp>((ref) => ResendOtp(ref.watch(authRepositoryProvider)));
final forgotPasswordProvider = Provider<ForgotPassword>(
  (ref) => ForgotPassword(ref.watch(authRepositoryProvider)),
);
final resetPasswordProvider = Provider<ResetPassword>(
  (ref) => ResetPassword(ref.watch(authRepositoryProvider)),
);

// ---- Features ----
final sleepRepositoryProvider = Provider<SleepRepository>(
  (ref) => SleepRepositoryImpl(ref.watch(dioProvider)),
);

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => TodoRepositoryImpl(ref.watch(dioProvider)),
);

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepositoryImpl(ref.watch(dioProvider)),
);
