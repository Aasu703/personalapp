import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';

class ListTransactions {
  const ListTransactions(this._repository);

  final FinanceRepository _repository;

  Future<List<Transaction>> call({
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    String? category,
  }) {
    return _repository.getTransactions(from: from, to: to, type: type, category: category);
  }
}
