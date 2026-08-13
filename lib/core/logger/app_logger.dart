import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';

/// Central [Talker] instance for app-wide logging.
///
/// Console output and detailed network logging are only enabled in debug /
/// profile builds. In release builds [Talker.enabled] is false and all log
/// calls become no-ops, so no sensitive data leaks into release logs.
class AppLogger {
  AppLogger._();

  static Talker? _instance;

  /// Whether full logging is enabled for the current build.
  static bool get enabled => kDebugMode;

  /// The shared [Talker] instance on top of [TalkerLogger] (console output).
  static Talker get talker {
    return _instance ??= Talker(
      settings: TalkerSettings(
        enabled: enabled,
        useConsoleLogs: enabled,
        useHistory: true,
        maxHistoryItems: 500,
      ),
    );
  }

  /// Convenience accessor for logging from anywhere without importing Talker.
  static void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    talker.debug(message, error, stackTrace);
  }

  static void info(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    talker.info(message, error, stackTrace);
  }

  static void verbose(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    talker.verbose(message, error, stackTrace);
  }

  static void warning(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    talker.warning(message, error, stackTrace);
  }

  static void error(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    talker.error(message, error, stackTrace);
  }

  static void critical(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (!enabled) return;
    talker.critical(message, error, stackTrace);
  }

  /// Logs an arbitrary [TalkerLog] (e.g. a custom data/log subclass).
  static void logCustom(TalkerLog log) {
    if (!enabled) return;
    talker.logCustom(log);
  }
}