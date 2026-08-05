import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_paths.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/entities/sleep_stats.dart';
import '../providers/sleep_providers.dart';
import '../widgets/sleep_entry_tile.dart';
import '../widgets/sleep_summary_card.dart';

class HealthHomeScreen extends ConsumerWidget {
  const HealthHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final logsAsync = ref.watch(sleepLogsProvider);
    final statsAsync = ref.watch(sleepStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sleepLogsProvider);
          ref.invalidate(sleepStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            logsAsync.when(
              data: (logs) {
                final sorted = [...logs]..sort((a, b) => b.sleepAt.compareTo(a.sleepAt));
                return SleepSummaryCard(
                  lastLog: sorted.isNotEmpty ? sorted.first : null,
                  stats: statsAsync.valueOrNull,
                );
              },
              loading: () => const SleepSummaryCard(),
              error: (e, _) => const SleepSummaryCard(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(RoutePaths.healthLog);
              },
              icon: const Icon(Icons.add),
              label: const Text('Log sleep'),
            ),
            const SizedBox(height: 24),
            Text('7-day trend', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            statsAsync.when(
              data: (stats) => _TrendBars(stats: stats),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Unable to load stats.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent entries', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            logsAsync.when(
              data: (logs) {
                final sorted = [...logs]..sort((a, b) => b.sleepAt.compareTo(a.sleepAt));
                if (sorted.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No sleep entries yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: sorted.take(5).map((log) => SleepEntryTile(log: log)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Unable to load entries.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RoutePaths.sleepHistory);
                },
                child: const Text('View full history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.stats});

  final SleepStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trend = stats.trend;

    if (trend.isEmpty) {
      return Text(
        'Not enough data to show a trend yet.',
        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    final max = trend.fold<double>(
          0,
          (acc, p) => p.durationMinutes > acc ? p.durationMinutes : acc,
        ) +
        1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final point in trend)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${point.durationMinutes.toStringAsFixed(0)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 72 * (point.durationMinutes / max).clamp(0.08, 1.0),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('E').format(point.date),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
