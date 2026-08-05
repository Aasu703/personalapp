import 'package:dio/dio.dart';

/// On a 401 response this interceptor tries to refresh the session once via
/// `POST /api/auth/refresh` (cookie-based, no body needed) and retries the
/// original request. If the refresh also fails it clears the local session
/// so the app can route back to the login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.onSessionExpired});

  final Dio dio;
  final Future<void> Function() onSessionExpired;

  bool _refreshing = false;

  static const List<String> _authPaths = [
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/refresh',
    '/api/auth/verify-otp',
    '/api/auth/resend-otp',
  ];

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final path = err.requestOptions.path;
    if (_authPaths.any(path.startsWith)) {
      handler.next(err);
      return;
    }

    if (_refreshing) {
      handler.next(err);
      return;
    }

    _refreshing = true;
    try {
      final refresh = await dio.post<void>('/api/auth/refresh');
      if (refresh.statusCode == 200) {
        handler.resolve(await dio.fetch(err.requestOptions));
        return;
      }
      await onSessionExpired();
      handler.next(err);
    } on DioException catch (refreshError) {
      await onSessionExpired();
      handler.next(refreshError);
    } catch (e) {
      await onSessionExpired();
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
