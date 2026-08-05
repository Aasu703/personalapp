import '../../domain/entities/sleep_stats.dart';

class SleepStatsModel {
  const SleepStatsModel._();

  static SleepStats fromJson(Map<String, dynamic> json) {
    final trendRaw = json['trend'];
    return SleepStats(
      averageDurationMinutes:
          _toDouble(json['averageDurationMinutes'] ?? json['averageDuration'] ?? 0),
      totalEntries: _toInt(json['totalEntries'] ?? json['total'] ?? 0),
      currentStreakDays: _toInt(json['currentStreakDays'] ?? json['streak'] ?? 0),
      trend: trendRaw is List
          ? trendRaw
                .whereType<Map>()
                .map((e) {
                  final map = Map<String, dynamic>.from(e);
                  return SleepTrendPoint(
                    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
                    durationMinutes: _toDouble(map['durationMinutes'] ?? map['minutes'] ?? 0),
                  );
                })
                .toList()
          : const [],
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
