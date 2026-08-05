import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/todo.dart';

final todosProvider = FutureProvider<List<Todo>>((ref) {
  return ref.watch(todoRepositoryProvider).getTodos();
});

/// Selected status filter on the todo list screen (null = all).
final todoStatusFilterProvider = StateProvider<TodoStatus?>((ref) => null);
