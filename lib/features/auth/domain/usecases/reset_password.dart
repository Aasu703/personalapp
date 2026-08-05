import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class ResetPassword {
  const ResetPassword(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call({required String email, required String password}) {
    return _repository.resetPassword(email: email, password: password);
  }
}
