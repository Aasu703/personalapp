import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the bearer `accessToken` and `csrfToken` that the backend returns in
/// JSON bodies (not cookies). Values are mirrored to secure storage so a valid
/// session can survive an app restart.
class SessionStore {
  SessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _csrfKey = 'csrf_token';

  String? _accessToken;
  String? _csrfToken;

  String? get accessToken => _accessToken;
  String? get csrfToken => _csrfToken;

  /// Loads persisted tokens (call once before building the HTTP client).
  Future<void> restore() async {
    _accessToken = await _storage.read(key: _accessKey);
    _csrfToken = await _storage.read(key: _csrfKey);
  }

  Future<void> setTokens({String? accessToken, String? csrfToken}) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      _accessToken = accessToken;
      await _storage.write(key: _accessKey, value: accessToken);
    }
    if (csrfToken != null && csrfToken.isNotEmpty) {
      _csrfToken = csrfToken;
      await _storage.write(key: _csrfKey, value: csrfToken);
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _csrfToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _csrfKey);
  }
}
