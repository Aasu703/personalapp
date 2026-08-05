/// Aggregate statistics returned by the backend for a user's sleep history.
class SleepStats {
  const SleepStats({
    required this.averageDurationMinutes,
    required this.totalEntries,
    required this.currentStreakDays,
    this.trend = const [],
  });

  final double averageDurationMinutes;
  final int totalEntries;
  final int currentStreakDays;
  final List<SleepTrendPoint> trend;
}

/// A single point on the 7-day sleep trend chart.
class SleepTrendPoint {
  const SleepTrendPoint({required this.date, required this.durationMinutes});

  final DateTime date;
  final double durationMinutes;
}
