import '../repositories/sleep_repository.dart';

class DeleteSleepLog {
  const DeleteSleepLog(this._repository);

  final SleepRepository _repository;

  Future<void> call(String id) => _repository.deleteSleepLog(id);
}
