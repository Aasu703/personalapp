import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/entities/transaction.dart';

final transactionsProvider = FutureProvider<List<Transaction>>((ref) {
  return ref.watch(financeRepositoryProvider).getTransactions();
});

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) {
  return ref.watch(financeRepositoryProvider).getSummary();
});

/// Type filter on the transaction history screen (null = all).
final financeTypeFilterProvider = StateProvider<TransactionType?>((ref) => null);
