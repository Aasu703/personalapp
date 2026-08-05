import 'package:dio/dio.dart';

/// Exception surfaced to the UI when the backend returns a non-success
/// response, carrying the parsed error message from the uniform
/// `{ success, message, data }` response shape.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.data});

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    String message;
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (error.response == null) {
      message = 'Unable to reach the server. Check your connection.';
    } else {
      message = 'Something went wrong (${error.response?.statusCode}).';
    }
    return ApiException(
      error.response?.statusCode ?? -1,
      message,
      data: data,
    );
  }

  final int statusCode;
  final String message;
  final dynamic data;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
