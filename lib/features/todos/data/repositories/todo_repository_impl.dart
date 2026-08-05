import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Todo>> getTodos({
    TodoStatus? status,
    DateTime? dueBefore,
    DateTime? dueAfter,
  }) async {
    try {
      final response = await _dio.get(
        '/api/todos',
        queryParameters: {
          if (status != null) 'status': status.name,
          if (dueBefore != null) 'dueBefore': dueBefore.toIso8601String(),
          if (dueAfter != null) 'dueAfter': dueAfter.toIso8601String(),
        },
      );
      return ApiClient.listData(response).map(TodoModel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Todo> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    TodoPriority priority = TodoPriority.medium,
  }) async {
    try {
      final response = await _dio.post(
        '/api/todos',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty) 'description': description,
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          'priority': priority.name,
        },
      );
      return TodoModel.fromJson(_object(response, 'todo'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Todo> updateTodo(
    String id, {
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/todos/$id',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          if (priority != null) 'priority': priority.name,
        },
      );
      return TodoModel.fromJson(_object(response, 'todo'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Todo> toggleTodo(String id) async {
    try {
      final response = await _dio.patch('/api/todos/$id/toggle');
      return TodoModel.fromJson(_object(response, 'todo'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    try {
      await _dio.delete('/api/todos/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Map<String, dynamic> _object(Response<dynamic> response, String key) {
    final data = ApiClient.data(response);
    if (data[key] is Map) return Map<String, dynamic>.from(data[key] as Map);
    if (data['id'] != null) return data;
    return const {};
  }
}
