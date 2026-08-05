import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos({
    TodoStatus? status,
    DateTime? dueBefore,
    DateTime? dueAfter,
  });

  Future<Todo> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    TodoPriority priority,
  });

  Future<Todo> updateTodo(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
  });

  Future<Todo> toggleTodo(String id);

  Future<void> deleteTodo(String id);
}
