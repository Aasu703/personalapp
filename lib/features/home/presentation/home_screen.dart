import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/route_paths.dart';
import '../../../core/di/providers.dart';
import '../../finance/domain/entities/finance_summary.dart';
import '../../finance/presentation/providers/finance_providers.dart';
import '../../health/domain/entities/sleep_log.dart';
import '../../health/presentation/providers/sleep_providers.dart';
import '../../todos/domain/entities/todo.dart';
import '../../todos/presentation/providers/todo_providers.dart';

/// Dashboard landing screen after login.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(currentUserProvider.notifier).state = null;
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RoutePaths.login, (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final logsAsync = ref.watch(sleepLogsProvider);
    final todosAsync = ref.watch(todosProvider);
    final summaryAsync = ref.watch(financeSummaryProvider);

    final lastSleep = logsAsync.valueOrNull;
    final todos = todosAsync.valueOrNull;
    final summary = summaryAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name.split(' ').first ?? 'there'}'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sleepLogsProvider);
          ref.invalidate(todosProvider);
          ref.invalidate(financeSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your day at a glance',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              icon: Icons.bedtime_outlined,
              color: scheme.primary,
              title: 'Last sleep',
              value: _lastSleepLabel(lastSleep),
              onTap: () => Navigator.of(context).pushNamed(RoutePaths.health),
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              icon: Icons.check_circle_outline,
              color: scheme.tertiary,
              title: 'Todos due today',
              value: _dueTodayLabel(todos),
              onTap: () => Navigator.of(context).pushNamed(RoutePaths.todos),
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              icon: Icons.account_balance_wallet_outlined,
              color: scheme.secondary,
              title: 'Balance',
              value: summary == null
                  ? '--'
                  : NumberFormat.simpleCurrency().format(summary.balance),
              onTap: () => Navigator.of(context).pushNamed(RoutePaths.finance),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSleepLabel(List<dynamic>? logs) {
    if (logs == null || logs.isEmpty) return 'No entries yet';
    final last = logs.reduce((a, b) {
      final ta = (a as dynamic).sleepAt;
      final tb = (b as dynamic).sleepAt;
      return ta.isAfter(tb) ? a : b;
    });
    final hours = ((last as dynamic).durationMinutes / 60).toStringAsFixed(1);
    return '$hours hrs';
  }

  String _dueTodayLabel(List<dynamic>? todos) {
    if (todos == null) return '--';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueToday = todos.where((t) {
      final due = (t as dynamic).dueDate;
      final status = (t as dynamic).status?.name ?? 'pending';
      if (due == null || status == 'completed') return false;
      final day = DateTime(due.year, due.month, due.day);
      return !day.isBefore(today);
    }).length;
    return '$dueToday pending';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
