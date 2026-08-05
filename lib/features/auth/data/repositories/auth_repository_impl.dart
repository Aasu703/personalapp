import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Stub implementation that simulates a network round-trip.
/// Replace with real API calls when the backend is ready.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({this.delay = const Duration(milliseconds: 1200)});

  final Duration delay;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    return const AuthResult.success(
      user: User(id: '1', name: 'Demo User', email: 'demo@meroapp.com'),
    );
  }

  @override
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    return AuthResult.success(
      user: User(id: '1', name: name, email: email),
    );
  }

  @override
  Future<AuthResult> forgotPassword({required String email}) async {
    await Future<void>.delayed(delay);
    return const AuthResult.success();
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    return const AuthResult.success();
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
