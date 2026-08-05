import '../../domain/entities/todo.dart';

class TodoModel {
  const TodoModel._();

  static Todo fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      priority: _priority(json['priority']),
      status: _status(json['status']),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static TodoPriority _priority(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'low':
        return TodoPriority.low;
      case 'high':
        return TodoPriority.high;
      default:
        return TodoPriority.medium;
    }
  }

  static TodoStatus _status(dynamic value) {
    return value?.toString().toLowerCase() == 'completed'
        ? TodoStatus.completed
        : TodoStatus.pending;
  }
}
