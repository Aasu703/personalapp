import '../../domain/entities/sleep_log.dart';

class SleepLogModel {
  const SleepLogModel._();

  static SleepLog fromJson(Map<String, dynamic> json) {
    final sleepAt = DateTime.tryParse(json['sleepAt'] as String? ?? '');
    final wokeAt = DateTime.tryParse(json['wokeAt'] as String? ?? '');
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    return SleepLog(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      sleepAt: sleepAt ?? DateTime.now(),
      wokeAt: wokeAt ?? DateTime.now(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      quality: json['quality'] as int?,
      note: json['note'] as String?,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
