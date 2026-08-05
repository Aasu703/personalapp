import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class UpdateTodo {
  const UpdateTodo(this._repository);

  final TodoRepository _repository;

  Future<Todo> call(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
  }) {
    return _repository.updateTodo(
      id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
  }
}
