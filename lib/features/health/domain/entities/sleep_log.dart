/// Sleep entry. Mirrors the backend SleepLog entity 1:1.
class SleepLog {
  const SleepLog({
    required this.id,
    required this.userId,
    required this.sleepAt,
    required this.wokeAt,
    required this.durationMinutes,
    this.quality,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime sleepAt;
  final DateTime wokeAt;
  final int durationMinutes;
  final int? quality;
  final String? note;
  final DateTime createdAt;

  Duration get duration => Duration(minutes: durationMinutes);
}
