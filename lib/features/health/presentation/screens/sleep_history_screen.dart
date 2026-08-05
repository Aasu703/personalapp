import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/sleep_log.dart';
import '../providers/sleep_providers.dart';
import '../widgets/sleep_entry_tile.dart';

class SleepHistoryScreen extends ConsumerWidget {
  const SleepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final logsAsync = ref.watch(sleepLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep history')),
      body: logsAsync.when(
        data: (logs) {
          final sorted = [...logs]..sort((a, b) => b.sleepAt.compareTo(a.sleepAt));
          if (sorted.isEmpty) {
            return Center(
              child: Text(
                'No sleep entries yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(sleepLogsProvider.future),
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final log = sorted[index];
                return Dismissible(
                  key: ValueKey(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: scheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                  ),
                  confirmDismiss: (_) async => _confirmDelete(context),
                  onDismissed: (_) {
                    ref.read(sleepRepositoryProvider).deleteSleepLog(log.id);
                    ref.invalidate(sleepLogsProvider);
                  },
                  child: SleepEntryTile(
                    log: log,
                    onDelete: () async {
                      if (await _confirmDelete(context)) {
                        await ref.read(sleepRepositoryProvider).deleteSleepLog(log.id);
                        ref.invalidate(sleepLogsProvider);
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
            'Unable to load history.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(RoutePaths.healthLog);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sleep entry?'),
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
