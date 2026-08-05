import '../entities/auth_result.dart';

/// Contract the data layer must fulfil. Implementations live under `data/`.
abstract class AuthRepository {
  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResult> forgotPassword({required String email});

  Future<AuthResult> resetPassword({
    required String email,
    required String password,
  });

  Future<void> logout();
}
