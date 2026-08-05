import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meroapp/app/app.dart';
import 'package:meroapp/core/di/providers.dart';
import 'package:meroapp/features/auth/domain/entities/auth_result.dart';
import 'package:meroapp/features/auth/domain/repositories/auth_repository.dart';

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';

/// Never talks to the network: the splash screen treats a failed `getMe()` as
/// "not signed in" and routes to onboarding.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login({required String email, required String password}) async {
    return const AuthResult.failure('not implemented in tests');
  }

  @override
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    return const AuthResult.failure('not implemented in tests');
  }

  @override
  Future<AuthResult> verifyOtp({required String email, required String otp}) async {
    return const AuthResult.failure('not implemented in tests');
  }

  @override
  Future<AuthResult> resendOtp({required String email}) async {
    return const AuthResult.failure('not implemented in tests');
  }

  @override
  Future<AuthResult> forgotPassword({required String email}) async {
    return const AuthResult.failure('not implemented in tests');
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    return const AuthResult.failure('not implemented in tests');
  }

  @override
  Future<AuthResult> getMe() async {
    return const AuthResult.failure('not signed in');
  }

  @override
  Future<void> logout() async {}
}

Widget _app() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: const MeroApp(),
  );
}

void main() {
  setUpAll(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
  });

  testWidgets('app starts on splash and flows to onboarding', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('MeroApp'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Secure Authentication'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('skipping onboarding opens the login screen', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('login form validates empty fields', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
