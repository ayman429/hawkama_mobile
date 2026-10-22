import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
      baseUrl: AppConfig.apiBaseUrl,
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
       _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
      logPrint: (object) => log(object.toString(), name: 'API'),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode && _isPaymentDebugRequest(options.path)) {
          final body = options.data is Map
              ? Map<String, dynamic>.from(options.data as Map)
              : <String, dynamic>{};
          if (body.containsKey('card_token')) {
            body['card_token'] = '[REDACTED; supplied]';
          }
          log(
            'REQUEST ${options.method} ${options.uri}\n'
            'body=$body',
            name: 'PaymentAPI',
          );
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode &&
            _isPaymentDebugRequest(response.requestOptions.path)) {
          log(
            'RESPONSE ${response.statusCode} ${response.requestOptions.uri}\n'
            'body=${_paymentResponseSummary(response.data)}',
            name: 'PaymentAPI',
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode && _isPaymentDebugRequest(error.requestOptions.path)) {
          log(
            'ERROR ${error.response?.statusCode} ${error.requestOptions.uri}\n'
            'body=${_paymentResponseSummary(error.response?.data)}',
            name: 'PaymentAPI',
          );
        }
        handler.next(error);
      },
    ));
  }

  final SessionEvents _session;
  late final Dio _dio;

  Future<dynamic> get(String path, [Map<String, dynamic>? query]) =>
      _unwrap(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, [Object? data]) =>
      _unwrap(() => _dio.post(path, data: data));

  /// Preserves the HTTP status for payment creation, where a 503 can still
  /// contain the payment ID that must be verified instead of charged again.
  Future<ApiResponse> postPreservingStatus(String path, [Object? data]) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      options: Options(
          validateStatus: (status) =>
              status != null &&
              ((status >= 200 && status < 300) || status == 503)),
    );
    final body = response.data;
    final unwrapped = body is Map<String, dynamic> && body.containsKey('data')
        ? body['data']
        : body;
    return ApiResponse(response.statusCode ?? 0, unwrapped, body);
  }

  Future<dynamic> put(String path, [Object? data]) =>
      _unwrap(() => _dio.put(path, data: data));

  Future<dynamic> patch(String path, [Object? data]) =>
      _unwrap(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _unwrap(() => _dio.delete(path));

  /// Streams a binary response straight to [savePath] with the auth headers.
  /// Error bodies are JSON, so they are decoded into [ApiException] as usual.
  Future<void> download(
    String path,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        deleteOnError: true,
        options: Options(
          headers: const {'Accept': '*/*'},
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
    } on DioException catch (error) {
      if (error.error is ApiException) throw error.error as ApiException;
      throw _toApiException(error);
    }
  }

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

bool _isPaymentDebugRequest(String path) =>
    path.endsWith('/client/bookings') || path.contains('/client/payments/');

Map<String, dynamic> _paymentResponseSummary(Object? value) {
  if (value is! Map) return {'response_type': value.runtimeType.toString()};
  final root = Map<String, dynamic>.from(value);
  final summary = <String, dynamic>{};
  for (final key in ['success', 'message', 'error_code', 'errors']) {
    if (root.containsKey(key)) summary[key] = root[key];
  }
  final data = root['data'] is Map
      ? Map<String, dynamic>.from(root['data'] as Map)
      : root;
  final payment = data['payment'];
  if (payment is Map) {
    final p = Map<String, dynamic>.from(payment);
    summary['payment'] = {
      for (final key in ['id', 'status', 'requires_action', 'failure_reason'])
        if (p.containsKey(key)) key: p[key],
      if (p.containsKey('transaction_url')) 'transaction_url': '[REDACTED]',
    };
  }
  final booking = data['booking'];
  if (booking is Map) {
    final b = Map<String, dynamic>.from(booking);
    summary['booking'] = {
      for (final key in ['id', 'status', 'payment_status'])
        if (b.containsKey(key)) key: b[key],
    };
  }
  return summary;
}

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final dynamic rawBody;

  const ApiResponse(this.statusCode, this.data, this.rawBody);
}

/// The interceptor reads the token from here so it does not import auth.
class AuthTokenHolder {
  static String? token;
}
