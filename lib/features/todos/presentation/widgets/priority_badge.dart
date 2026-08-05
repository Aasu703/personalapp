import 'package:flutter/material.dart';

import '../../domain/entities/todo.dart';

/// Small colored badge showing a todo's priority.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (priority) {
      TodoPriority.high => (scheme.errorContainer, scheme.onErrorContainer, Icons.priority_high),
      TodoPriority.low => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.arrow_downward,
      ),
      _ => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.remove,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foreground),
          ),
        ],
      ),
    );
  }
}
