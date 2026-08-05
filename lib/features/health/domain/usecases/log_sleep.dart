import '../entities/sleep_log.dart';
import '../repositories/sleep_repository.dart';

class LogSleep {
  const LogSleep(this._repository);

  final SleepRepository _repository;

  Future<SleepLog> call({
    required DateTime sleepAt,
    required DateTime wokeAt,
    int? quality,
    String? note,
  }) {
    return _repository.logSleep(
      sleepAt: sleepAt,
      wokeAt: wokeAt,
      quality: quality,
      note: note,
    );
  }
}
