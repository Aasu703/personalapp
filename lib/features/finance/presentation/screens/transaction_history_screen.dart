import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/transaction.dart';
import '../providers/finance_providers.dart';
import '../widgets/transaction_tile.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final transactionsAsync = ref.watch(transactionsProvider);
    final filter = ref.watch(financeTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _TypeChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () => ref.read(financeTypeFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Income',
                  selected: filter == TransactionType.income,
                  onTap: () =>
                      ref.read(financeTypeFilterProvider.notifier).state = TransactionType.income,
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Expenses',
                  selected: filter == TransactionType.expense,
                  onTap: () =>
                      ref.read(financeTypeFilterProvider.notifier).state = TransactionType.expense,
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final visible = filter == null
                    ? transactions
                    : transactions.where((t) => t.type == filter).toList();
                final sorted = [...visible]
                  ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
                if (sorted.isEmpty) {
                  return Center(
                    child: Text(
                      'No transactions match this filter.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(transactionsProvider.future),
                  child: ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final transaction = sorted[index];
                      return Dismissible(
                        key: ValueKey(transaction.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: scheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                        ),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) {
                          ref.read(financeRepositoryProvider).deleteTransaction(transaction.id);
                          ref.invalidate(transactionsProvider);
                          ref.invalidate(financeSummaryProvider);
                        },
                        child: TransactionTile(
                          transaction: transaction,
                          onDelete: () async {
                            if (await _confirmDelete(context)) {
                              await ref
                                  .read(financeRepositoryProvider)
                                  .deleteTransaction(transaction.id);
                              ref.invalidate(transactionsProvider);
                              ref.invalidate(financeSummaryProvider);
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Unable to load transactions.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
