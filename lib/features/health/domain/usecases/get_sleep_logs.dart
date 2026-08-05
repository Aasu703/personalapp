import '../entities/sleep_log.dart';
import '../repositories/sleep_repository.dart';

class GetSleepLogs {
  const GetSleepLogs(this._repository);

  final SleepRepository _repository;

  Future<List<SleepLog>> call({DateTime? from, DateTime? to}) {
    return _repository.getSleepLogs(from: from, to: to);
  }
}
