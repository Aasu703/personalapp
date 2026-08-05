import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// File-backed [PersistCookieJar] so the backend's httpOnly session cookies
/// survive app restarts.
class PersistentCookieJarBuilder {
  PersistentCookieJarBuilder._();

  static Future<PersistCookieJar> create() async {
    final dir = await getApplicationDocumentsDirectory();
    return PersistCookieJar(
      storage: FileStorage('${dir.path}/.dio_cookies'),
      persistSession: true,
    );
  }
}
