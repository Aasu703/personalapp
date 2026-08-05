import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Minimal manual service locator. Swap for provider/get_it when needed.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  AuthRepository? _authRepository;

  AuthRepository get authRepository => _authRepository ??= AuthRepositoryImpl();
}
