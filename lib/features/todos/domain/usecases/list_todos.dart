import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class ListTodos {
  const ListTodos(this._repository);

  final TodoRepository _repository;

  Future<List<Todo>> call({
    TodoStatus? status,
    DateTime? dueBefore,
    DateTime? dueAfter,
  }) {
    return _repository.getTodos(status: status, dueBefore: dueBefore, dueAfter: dueAfter);
  }
}
