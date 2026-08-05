enum TodoPriority { low, medium, high }

enum TodoStatus { pending, completed }

/// Todo item. Mirrors the backend Todo entity 1:1.
class Todo {
  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = TodoPriority.medium,
    this.status = TodoStatus.pending,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TodoPriority priority;
  final TodoStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;

  Todo copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
    TodoStatus? status,
    DateTime? completedAt,
  }) {
    return Todo(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }
}

extension TodoPriorityX on TodoPriority {
  String get label => name[0].toUpperCase() + name.substring(1);
}
