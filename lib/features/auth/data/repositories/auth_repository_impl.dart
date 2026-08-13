import 'package:dio/dio.dart';

import '../../../../core/auth/session_store.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Real API-backed implementation using the shared [Dio] instance. The backend
/// returns a bearer `accessToken` and a `csrfToken` in the JSON body (plus an
/// httpOnly refresh cookie), so successful auth responses are persisted into
/// the [SessionStore] for the interceptor to attach.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._sessionStore);

  final Dio _dio;
  final SessionStore _sessionStore;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = ApiClient.data(response);
      await _storeTokensFrom(data);
      final userJson = data['user'];
      AppLogger.info('Login succeeded for $email');
      return AuthResult.success(
        user: userJson is Map ? User.fromJson(Map<String, dynamic>.from(userJson)) : null,
      );
    } on DioException catch (e) {
      AppLogger.error('Login failed for $email', e);
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/api/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      AppLogger.info('Signup submitted for $email');
      return const AuthResult.success();
    } on DioException catch (e) {
      AppLogger.error('Signup failed for $email', e);
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _dio.post(
        '/api/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<AuthResult> resendOtp({required String email}) async {
    try {
      await _dio.post('/api/auth/resend-otp', data: {'email': email});
      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/api/auth/reset-password',
        data: {'email': email, 'token': token, 'newPassword': password},
      );
      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<AuthResult> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      final data = ApiClient.data(response);
      final userJson = data['user'];
      if (userJson is Map) {
        return AuthResult.success(user: User.fromJson(Map<String, dynamic>.from(userJson)));
      }
      return const AuthResult.failure('Unable to load your profile.');
    } on DioException catch (e) {
      return AuthResult.failure(_message(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } on DioException {
      // Best-effort: the local session is cleared by the caller regardless.
    } finally {
      await _sessionStore.clear();
    }
  }

  Future<void> _storeTokensFrom(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'];
    final csrfToken = data['csrfToken'];
    if (accessToken is String && accessToken.isNotEmpty) {
      await _sessionStore.setTokens(
        accessToken: accessToken,
        csrfToken: csrfToken is String ? csrfToken : null,
      );
    }
  }

  String _message(DioException e) {
    return ApiException.fromDio(e).message;
  }
}

