import '../entities/sleep_log.dart';
import '../repositories/sleep_repository.dart';

class UpdateSleepLog {
  const UpdateSleepLog(this._repository);

  final SleepRepository _repository;

  Future<SleepLog> call(
    String id, {
    DateTime? sleepAt,
    DateTime? wokeAt,
    int? quality,
    String? note,
  }) {
    return _repository.updateSleepLog(
      id,
      sleepAt: sleepAt,
      wokeAt: wokeAt,
      quality: quality,
      note: note,
    );
  }
}
