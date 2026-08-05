import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/route_paths.dart';
import '../../domain/entities/transaction.dart';
import '../providers/finance_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';

class FinanceHomeScreen extends ConsumerWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summaryAsync = ref.watch(financeSummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financeSummaryProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summaryAsync.when(
              data: (summary) => BalanceCard(summary: summary),
              loading: () => const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load balance.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent activity', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                final sorted = [...transactions]
                  ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
                if (sorted.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No transactions yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: sorted.take(5).map(_tile(context)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Unable to load transactions.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RoutePaths.financeHistory);
                },
                child: const Text('View all transactions'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(RoutePaths.financeAdd);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget Function(Transaction) _tile(BuildContext context) {
    return (transaction) => TransactionTile(transaction: transaction);
  }
}
