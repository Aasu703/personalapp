import '../repositories/finance_repository.dart';

class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final FinanceRepository _repository;

  Future<void> call(String id) => _repository.deleteTransaction(id);
}
