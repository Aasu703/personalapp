import '../repositories/todo_repository.dart';

class DeleteTodo {
  const DeleteTodo(this._repository);

  final TodoRepository _repository;

  Future<void> call(String id) => _repository.deleteTodo(id);
}
