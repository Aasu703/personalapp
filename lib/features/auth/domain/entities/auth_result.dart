import 'user.dart';

/// Outcome of an auth operation, either success or a failure message.
class AuthResult {
  const AuthResult._({required this.status, this.message, this.user});

  const AuthResult.success({User? user})
    : this._(status: AuthStatus.success, user: user);

  const AuthResult.failure(String message)
    : this._(status: AuthStatus.failure, message: message);

  final AuthStatus status;
  final String? message;
  final User? user;

  bool get isSuccess => status == AuthStatus.success;
}

enum AuthStatus { success, failure }
