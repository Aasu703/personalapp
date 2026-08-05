import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/entities/sleep_stats.dart';

final sleepLogsProvider = FutureProvider<List<SleepLog>>((ref) {
  return ref.watch(sleepRepositoryProvider).getSleepLogs();
});

final sleepStatsProvider = FutureProvider<SleepStats>((ref) {
  return ref.watch(sleepRepositoryProvider).getSleepStats();
});
