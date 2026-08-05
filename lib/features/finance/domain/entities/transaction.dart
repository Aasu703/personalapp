enum TransactionType { income, expense }

/// A single ledger entry. Mirrors the backend Transaction entity 1:1.
class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.occurredAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String category;
  final String? note;
  final DateTime occurredAt;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;
}
