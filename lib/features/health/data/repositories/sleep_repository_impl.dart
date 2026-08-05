import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/entities/sleep_stats.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../models/sleep_log_model.dart';
import '../models/sleep_stats_model.dart';

class SleepRepositoryImpl implements SleepRepository {
  SleepRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<SleepLog>> getSleepLogs({DateTime? from, DateTime? to}) async {
    try {
      final response = await _dio.get(
        '/api/sleep',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
        },
      );
      return ApiClient.listData(response).map(SleepLogModel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SleepLog> logSleep({
    required DateTime sleepAt,
    required DateTime wokeAt,
    int? quality,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        '/api/sleep',
        data: {
          'sleepAt': sleepAt.toIso8601String(),
          'wokeAt': wokeAt.toIso8601String(),
          'quality': ?quality,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return SleepLogModel.fromJson(_object(response, 'log'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SleepLog> updateSleepLog(
    String id, {
    DateTime? sleepAt,
    DateTime? wokeAt,
    int? quality,
    String? note,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/sleep/$id',
        data: {
          if (sleepAt != null) 'sleepAt': sleepAt.toIso8601String(),
          if (wokeAt != null) 'wokeAt': wokeAt.toIso8601String(),
          'quality': ?quality,
          'note': ?note,
        },
      );
      return SleepLogModel.fromJson(_object(response, 'log'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteSleepLog(String id) async {
    try {
      await _dio.delete('/api/sleep/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SleepStats> getSleepStats() async {
    try {
      final response = await _dio.get('/api/sleep/stats');
      final data = ApiClient.data(response);
      if (data['stats'] is Map) {
        return SleepStatsModel.fromJson(Map<String, dynamic>.from(data['stats'] as Map));
      }
      return SleepStatsModel.fromJson(data);
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
