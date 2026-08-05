import '../../domain/entities/finance_summary.dart';

class FinanceSummaryModel {
  const FinanceSummaryModel._();

  static FinanceSummary fromJson(Map<String, dynamic> json) {
    final byCategoryRaw = json['byCategory'];
    return FinanceSummary(
      income: _toDouble(json['income'] ?? 0),
      expense: _toDouble(json['expense'] ?? 0),
      balance: _toDouble(json['balance'] ?? 0),
      byCategory: byCategoryRaw is List
          ? byCategoryRaw
                .whereType<Map>()
                .map((e) {
                  final map = Map<String, dynamic>.from(e);
                  return CategoryTotal(
                    category: map['category'] as String? ?? 'Other',
                    total: _toDouble(map['total'] ?? 0),
                    count: map['count'] is num
                        ? (map['count'] as num).toInt()
                        : int.tryParse(map['count']?.toString() ?? '') ?? 0,
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
}
