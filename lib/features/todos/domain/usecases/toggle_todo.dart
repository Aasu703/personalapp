import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class ToggleTodo {
  const ToggleTodo(this._repository);

  final TodoRepository _repository;

  Future<Todo> call(String id) => _repository.toggleTodo(id);
}
