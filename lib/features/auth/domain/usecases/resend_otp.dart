import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class ResendOtp {
  const ResendOtp(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call({required String email}) {
    return _repository.resendOtp(email: email);
  }
}
