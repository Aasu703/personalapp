import 'package:dio/dio.dart';

import '../auth/session_store.dart';

/// Attaches the bearer `Authorization` header to authenticated requests and
/// the `X-CSRF-Token` header to the CSRF-protected refresh/logout endpoints.
///
/// On a 401 (or a 403 from a CSRF-protected endpoint) it attempts a single
/// refresh via `POST /api/auth/refresh` and retries the original request. If
/// the refresh also fails it clears the local session so the app can route
/// back to the login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.sessionStore,
    required this.onSessionExpired,
  });

  final Dio dio;
  final SessionStore sessionStore;
  final Future<void> Function() onSessionExpired;

  bool _refreshing = false;

  /// Endpoints that authenticate via body/cookie and must not receive the
  /// bearer token (they would still work, but they are public anyway).
  static const List<String> _noBearerPaths = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/verify-otp',
    '/api/auth/resend-otp',
    '/api/auth/forgot-password',
    '/api/auth/reset-password',
    '/api/auth/refresh',
    '/api/auth/logout',
  ];

  /// Endpoints protected by the backend CSRF middleware (matches the
  /// `csrfToken` cookie value against the `X-CSRF-Token` header).
  static const List<String> _csrfProtectedPaths = [
    '/api/auth/refresh',
    '/api/auth/logout',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;

    if (!_noBearerPaths.any(path.startsWith)) {
      final token = sessionStore.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (_csrfProtectedPaths.any(path.startsWith)) {
      final csrf = sessionStore.csrfToken;
      if (csrf != null && csrf.isNotEmpty) {
        options.headers['X-CSRF-Token'] = csrf;
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Public, body-authenticated endpoints: never refresh for these.
    if (_noBearerPaths.any(path.startsWith) && path != '/api/auth/refresh') {
      handler.next(err);
      return;
    }

    // The refresh request itself failing means the session is gone.
    if (path.startsWith('/api/auth/refresh')) {
      if (_refreshing) {
        handler.next(err);
        return;
      }
      await _expire();
      handler.next(err);
      return;
    }

    final isAuthFailure =
        status == 401 || (status == 403 && path.startsWith('/api/auth/logout'));

    if (!isAuthFailure || _refreshing) {
      handler.next(err);
      return;
    }

    _refreshing = true;
    try {
      final refreshed = await _refresh();
      if (refreshed) {
        handler.resolve(await dio.fetch(err.requestOptions));
        return;
      }
      await _expire();
      handler.next(err);
    } on DioException catch (refreshError) {
      await _expire();
      handler.next(refreshError);
    } catch (e) {
      await _expire();
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> _refresh() async {
    final response = await dio.post('/api/auth/refresh');
    if (response.statusCode == 200) {
      final body = response.data;
      if (body is Map && body['success'] == true) {
        final data = body['data'];
        if (data is Map) {
          final accessToken = data['accessToken'];
          final csrfToken = data['csrfToken'];
          if (accessToken is String && accessToken.isNotEmpty) {
            await sessionStore.setTokens(
              accessToken: accessToken,
              csrfToken: csrfToken is String ? csrfToken : null,
            );
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _expire() async {
    await sessionStore.clear();
    await onSessionExpired();
  }
}
