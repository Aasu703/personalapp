import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/sleep_log.dart';

/// A single sleep history row with an optional delete action.
class SleepEntryTile extends StatelessWidget {
  const SleepEntryTile({super.key, required this.log, this.onDelete});

  final SleepLog log;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, h:mm a');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Icon(Icons.bedtime_outlined, color: scheme.onSecondaryContainer),
      ),
      title: Text('${(log.durationMinutes / 60).toStringAsFixed(1)} hours'),
      subtitle: Text(
        '${dateFormat.format(log.sleepAt)} → ${dateFormat.format(log.wokeAt)}'
        '${log.quality != null ? '  ·  Quality ${log.quality}/5' : ''}',
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          : null,
    );
  }
}
