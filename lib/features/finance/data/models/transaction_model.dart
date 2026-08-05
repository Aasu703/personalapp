import '../entities/transaction.dart';

class TransactionModel {
  const TransactionModel._();

  static Transaction fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      type: json['type']?.toString().toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: _toDouble(json['amount'] ?? 0),
      category: json['category'] as String? ?? 'Other',
      note: json['note'] as String?,
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
