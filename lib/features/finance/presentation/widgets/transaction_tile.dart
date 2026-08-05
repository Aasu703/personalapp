import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

/// A single transaction row with signed amount and category.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onDelete, this.onTap});

  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency();
    final sign = transaction.isIncome ? '+' : '-';
    final amountColor = transaction.isIncome ? Colors.green.shade700 : scheme.onSurface;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: transaction.isIncome
            ? scheme.secondaryContainer
            : scheme.errorContainer,
        child: Icon(
          transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: transaction.isIncome ? scheme.onSecondaryContainer : scheme.onErrorContainer,
        ),
      ),
      title: Text(transaction.category),
      subtitle: Text(
        DateFormat('MMM d, yyyy').format(transaction.occurredAt) +
            (transaction.note != null && transaction.note!.isNotEmpty
                ? '  ·  ${transaction.note}'
                : ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign${currency.format(transaction.amount)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
