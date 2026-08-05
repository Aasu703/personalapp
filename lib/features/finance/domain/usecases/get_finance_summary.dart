import '../entities/finance_summary.dart';
import '../repositories/finance_repository.dart';

class GetFinanceSummary {
  const GetFinanceSummary(this._repository);

  final FinanceRepository _repository;

  Future<FinanceSummary> call({DateTime? from, DateTime? to}) {
    return _repository.getSummary(from: from, to: to);
  }
}
