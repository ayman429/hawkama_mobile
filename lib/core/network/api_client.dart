import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../../l10n/strings.dart';
import 'api_exception.dart';
import 'session_events.dart';

/// Single HTTP entry point.
///
/// Sends `Accept`, `Accept-Language`, and the Bearer token, unwraps the
/// `data` envelope, and converts non-2xx responses into [ApiException].
class ApiClient {
  ApiClient(this._session) {
    _dio = Dio(BaseOptions(
      baseUrl:'https://www.gcmc.sa/api/v1',// AppConfig.apiBaseUrl,
      headers: const {
        'Accept': 'application/json',
        'Accept-Language': 'ar',
      },
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept-Language'] = L10n.locale.value.languageCode;
        final token = AuthTokenHolder.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final hint = _toApiException(error);
        if (hint.isUnauthenticated) _session.onUnauthorized?.call();
        handler.next(DioException(
          requestOptions: error.requestOptions,
          error: hint,
          response: error.response,
          type: error.type,
        ));
      },
    ));
    if (kDebugMode) {
      _dio.interceptors.add(InterceptorsWrapper(
        onResponse: (response, handler) {
          _logHttp(
            response.requestOptions.method,
            response.requestOptions.uri,
            response.statusCode,
            response.data,
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _logHttp(
            error.requestOptions.method,
            error.requestOptions.uri,
            error.response?.statusCode,
            error.response?.data ?? error.message,
          );
          handler.next(error);
        },
      ));
    }
  }

  final SessionEvents _session;
  late final Dio _dio;

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) =>
      _unwrap(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, [Object? data]) =>
      _unwrap(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, [Object? data]) =>
      _unwrap(() => _dio.put(path, data: data));

  Future<dynamic> patch(String path, [Object? data]) =>
      _unwrap(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _unwrap(() => _dio.delete(path));

  Future<dynamic> _unwrap(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic>) return body['data'];
      return body;
    } on DioException catch (error) {
      if (error.error is ApiException) throw error.error as ApiException;
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final data = error.response?.data;
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final errorsRaw = map['errors'];
    final fieldErrors = <String, List<String>>{};
    if (errorsRaw is Map) {
      for (final entry in errorsRaw.entries) {
        final value = entry.value;
        fieldErrors['${entry.key}'] =
            value is List ? value.map((item) => '$item').toList() : ['$value'];
      }
    }
    final offline = error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout;
    final message = map['message'] as String? ??
        (offline ? tr('serverUnreachable') : tr('unexpected'));
    return ApiException(
      message,
      code: map['error_code'] as String?,
      statusCode: error.response?.statusCode,
      fieldErrors: fieldErrors,
    );
  }
}

void _logHttp(String method, Uri uri, int? status, Object? body) {
  debugPrint('API $method $uri → ${status ?? '-'}');
  final text = body?.toString() ?? '';
  const size = 800;
  for (var start = 0; start < text.length; start += size) {
    final end = start + size > text.length ? text.length : start + size;
    debugPrint(text.substring(start, end));
  }
}

/// The interceptor reads the token from here so it does not import auth.
class AuthTokenHolder {
  static String? token;
}
