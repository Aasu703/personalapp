import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class Signup {
  const Signup(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.signup(name: name, email: email, password: password);
  }
}
