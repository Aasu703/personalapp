import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../auth/session_store.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Single [Dio] instance shared across all repositories.
///
/// The backend issues a bearer `accessToken` in the JSON body plus a httpOnly
/// refresh cookie. A persistent cookie jar holds the cookies while the
/// [AuthInterceptor] attaches the bearer token and CSRF headers.
class ApiClient {
  ApiClient._();

  static Dio create({
    PersistCookieJar? cookieJar,
    required SessionStore sessionStore,
    required Future<void> Function() onSessionExpired,
    Talker? talker,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        headers: {HttpHeaders.acceptHeader: Headers.jsonContentType},
      ),
    );

    if (!kIsWeb && cookieJar != null) {
      dio.interceptors.add(CookieManager(cookieJar));
    }
    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      sessionStore: sessionStore,
      onSessionExpired: onSessionExpired,
    ));
    if (talker != null) {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: false,
            printResponseData: true,
            printErrorData: true,
            printErrorHeaders: true,
            hiddenHeaders: {
              // Never leak credentials in logs.
              'Authorization',
              'X-CSRF-Token',
              'Cookie',
              'Set-Cookie',
            },
          ),
        ),
      );
    }

    return dio;
  }

  /// Pulls the `data` object out of the backend's `{ success, message, data }`
  /// response envelope.
  static Map<String, dynamic> data(Response<dynamic> response) {
    final body = response.data;
    if (body is Map && body['success'] == true) {
      final data = body['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    }
    throw ApiException(
      response.statusCode ?? -1,
      'Unexpected response from the server.',
      data: body,
    );
  }

  /// Extracts a list payload, tolerant of both a bare array and a paginated
  /// `{ items: [...] }` envelope.
  static List<Map<String, dynamic>> listData(Response<dynamic> response) {
    final body = response.data;
    if (body is Map && body['success'] == true) {
      return _asItemList(body['data']);
    }
    throw ApiException(
      response.statusCode ?? -1,
      'Unexpected response from the server.',
      data: body,
    );
  }

  static List<Map<String, dynamic>> _asItemList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in const ['items', 'results', 'logs', 'todos', 'transactions']) {
        final value = data[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }
}
