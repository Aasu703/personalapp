import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class CreateTodo {
  const CreateTodo(this._repository);

  final TodoRepository _repository;

  Future<Todo> call({
    required String title,
    String? description,
    DateTime? dueDate,
    TodoPriority priority = TodoPriority.medium,
  }) {
    return _repository.createTodo(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
  }
}
