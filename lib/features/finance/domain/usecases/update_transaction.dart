import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';

class UpdateTransaction {
  const UpdateTransaction(this._repository);

  final FinanceRepository _repository;

  Future<Transaction> call(
    String id, {
    TransactionType? type,
    double? amount,
    String? category,
    String? note,
    DateTime? occurredAt,
  }) {
    return _repository.updateTransaction(
      id,
      type: type,
      amount: amount,
      category: category,
      note: note,
      occurredAt: occurredAt,
    );
  }
}
