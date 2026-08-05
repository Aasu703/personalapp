import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  const VerifyOtp(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call({required String email, required String otp}) {
    return _repository.verifyOtp(email: email, otp: otp);
  }
}
