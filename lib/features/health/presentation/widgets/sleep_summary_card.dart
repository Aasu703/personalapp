import 'package:flutter/material.dart';

import '../../domain/entities/sleep_log.dart';
import '../../domain/entities/sleep_stats.dart';

/// Summary card for the health home screen showing the most recent sleep.
class SleepSummaryCard extends StatelessWidget {
  const SleepSummaryCard({super.key, this.lastLog, this.stats});

  final SleepLog? lastLog;
  final SleepStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hours = lastLog != null
        ? (lastLog!.durationMinutes / 60).toStringAsFixed(1)
        : '--';

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last night',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$hours hrs',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
            if (stats != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_avg(stats!)} avg  ·  ${stats!.currentStreakDays} day streak',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _avg(SleepStats stats) {
    final h = stats.averageDurationMinutes / 60;
    return '${h.toStringAsFixed(1)}h';
  }
}
