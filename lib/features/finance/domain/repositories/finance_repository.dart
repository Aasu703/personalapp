import '../entities/finance_summary.dart';
import '../entities/transaction.dart';

abstract class FinanceRepository {
  Future<List<Transaction>> getTransactions({
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    String? category,
  });

  Future<Transaction> createTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    String? note,
    DateTime? occurredAt,
  });

  Future<Transaction> updateTransaction(
    String id, {
    TransactionType? type,
    double? amount,
    String? category,
    String? note,
    DateTime? occurredAt,
  });

  Future<void> deleteTransaction(String id);

  Future<FinanceSummary> getSummary({DateTime? from, DateTime? to});
}
