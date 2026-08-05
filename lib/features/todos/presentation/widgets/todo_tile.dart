import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/todo.dart';
import 'priority_badge.dart';

/// A todo list row with checkbox toggle, priority badge and due date.
class TodoTile extends StatelessWidget {
  const TodoTile({super.key, required this.todo, this.onToggle, this.onTap, this.onDelete});

  final Todo todo;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = todo.status == TodoStatus.completed;

    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: completed,
        onChanged: (_) => onToggle?.call(),
      ),
      title: Text(
        todo.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          decoration: completed ? TextDecoration.lineThrough : null,
          color: completed ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todo.description != null && todo.description!.isNotEmpty)
            Text(
              todo.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (todo.dueDate != null)
            Row(
              children: [
                Icon(Icons.event_outlined, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(todo.dueDate!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isOverdue(todo) ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PriorityBadge(priority: todo.priority),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  bool _isOverdue(Todo todo) {
    if (todo.status == TodoStatus.completed || todo.dueDate == null) return false;
    return todo.dueDate!.isBefore(DateTime.now());
  }
}
