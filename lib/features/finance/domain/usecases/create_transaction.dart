import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';

class CreateTransaction {
  const CreateTransaction(this._repository);

  final FinanceRepository _repository;

  Future<Transaction> call({
    required TransactionType type,
    required double amount,
    required String category,
    String? note,
    DateTime? occurredAt,
  }) {
    return _repository.createTransaction(
      type: type,
      amount: amount,
      category: category,
      note: note,
      occurredAt: occurredAt,
    );
  }
}
