import '../entities/sleep_log.dart';
import '../entities/sleep_stats.dart';

abstract class SleepRepository {
  Future<List<SleepLog>> getSleepLogs({DateTime? from, DateTime? to});

  Future<SleepLog> logSleep({
    required DateTime sleepAt,
    required DateTime wokeAt,
    int? quality,
    String? note,
  });

  Future<SleepLog> updateSleepLog(
    String id, {
    DateTime? sleepAt,
    DateTime? wokeAt,
    int? quality,
    String? note,
  });

  Future<void> deleteSleepLog(String id);

  Future<SleepStats> getSleepStats();
}
