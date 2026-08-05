import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/finance_summary_model.dart';
import '../models/transaction_model.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Transaction>> getTransactions({
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    String? category,
  }) async {
    try {
      final response = await _dio.get(
        '/api/finance/transactions',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          if (type != null) 'type': type.name,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return ApiClient.listData(response).map(TransactionModel.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Transaction> createTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    String? note,
    DateTime? occurredAt,
  }) async {
    try {
      final response = await _dio.post(
        '/api/finance/transactions',
        data: {
          'type': type.name,
          'amount': amount,
          'category': category,
          if (note != null && note.isNotEmpty) 'note': note,
          if (occurredAt != null) 'occurredAt': occurredAt.toIso8601String(),
        },
      );
      return TransactionModel.fromJson(_object(response, 'transaction'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Transaction> updateTransaction(
    String id, {
    TransactionType? type,
    double? amount,
    String? category,
    String? note,
    DateTime? occurredAt,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/finance/transactions/$id',
        data: {
          if (type != null) 'type': type.name,
          if (amount != null) 'amount': amount,
          if (category != null) 'category': category,
          if (note != null) 'note': note,
          if (occurredAt != null) 'occurredAt': occurredAt.toIso8601String(),
        },
      );
      return TransactionModel.fromJson(_object(response, 'transaction'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/api/finance/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<FinanceSummary> getSummary({DateTime? from, DateTime? to}) async {
    try {
      final response = await _dio.get(
        '/api/finance/summary',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
        },
      );
      final data = ApiClient.data(response);
      if (data['summary'] is Map) {
        return FinanceSummaryModel.fromJson(
          Map<String, dynamic>.from(data['summary'] as Map),
        );
      }
      return FinanceSummaryModel.fromJson(data);
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
