import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_providers.dart';
import '../widgets/todo_tile.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final todosAsync = ref.watch(todosProvider);
    final filter = ref.watch(todoStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () => ref.read(todoStatusFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  selected: filter == TodoStatus.pending,
                  onTap: () =>
                      ref.read(todoStatusFilterProvider.notifier).state = TodoStatus.pending,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Completed',
                  selected: filter == TodoStatus.completed,
                  onTap: () =>
                      ref.read(todoStatusFilterProvider.notifier).state = TodoStatus.completed,
                ),
              ],
            ),
          ),
          Expanded(
            child: todosAsync.when(
              data: (todos) {
                final visible = _applyFilter(todos, filter);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      'No todos here yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(todosProvider.future),
                  child: ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final todo = visible[index];
                      return Dismissible(
                        key: ValueKey(todo.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: scheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                        ),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) {
                          ref.read(todoRepositoryProvider).deleteTodo(todo.id);
                          ref.invalidate(todosProvider);
                        },
                        child: TodoTile(
                          todo: todo,
                          onToggle: () => _toggle(ref, todo),
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(RoutePaths.todosAdd, arguments: todo);
                            ref.invalidate(todosProvider);
                          },
                          onDelete: () async {
                            if (await _confirmDelete(context)) {
                              await ref.read(todoRepositoryProvider).deleteTodo(todo.id);
                              ref.invalidate(todosProvider);
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load todos.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(RoutePaths.todosAdd);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Todo> _applyFilter(List<Todo> todos, TodoStatus? filter) {
    final filtered = filter == null ? todos : todos.where((t) => t.status == filter).toList();
    filtered.sort((a, b) {
      final priority = b.priority.index.compareTo(a.priority.index);
      if (priority != 0) return priority;
      final dueA = a.dueDate?.millisecondsSinceEpoch ?? double.infinity;
      final dueB = b.dueDate?.millisecondsSinceEpoch ?? double.infinity;
      return dueA.compareTo(dueB);
    });
    return filtered;
  }

  Future<void> _toggle(WidgetRef ref, Todo todo) async {
    await ref.read(todoRepositoryProvider).toggleTodo(todo.id);
    ref.invalidate(todosProvider);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete todo?'),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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
