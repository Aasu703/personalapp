import '../entities/sleep_stats.dart';
import '../repositories/sleep_repository.dart';

class GetSleepStats {
  const GetSleepStats(this._repository);

  final SleepRepository _repository;

  Future<SleepStats> call() => _repository.getSleepStats();
}
