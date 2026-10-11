import 'package:dio/dio.dart';

import '../core/config.dart';
import '../l10n/strings.dart';
import 'errors.dart';

/// Single HTTP entry point (FRONTEND_API_GUIDE.md §1).
///
/// - Sends `Accept: application/json`, `Accept-Language: ar` and the Bearer
///   token automatically.
/// - Unwraps the response envelope (`data`); repositories never see it.
/// - Converts non-2xx into [ApiException] with the translated `message`,
///   stable `error_code` and 422 `errors` map.
class ApiClient {
  ApiClient._() {
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
        options.headers['Accept-Language'] =
            L10n.locale.value.languageCode; // ar | en — follows app locale
        final token = AuthTokenHolder.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Content-Type json only for JSON bodies; FormData sets its own.
        if (options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        final hint = _toApiException(e);
        if (hint.isUnauthenticated) onUnauthorized?.call();
        handler.next(DioException(
          requestOptions: e.requestOptions,
          error: hint,
          response: e.response,
          type: e.type,
        ));
      },
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  /// Wired by the auth store: clear token + route to login.
  static void Function()? onUnauthorized;

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
      final res = await call();
      final body = res.data;
      if (body is Map<String, dynamic>) return body['data'];
      return body;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    final map = data is Map<String, dynamic> ? data : const {};
    final errorsRaw = map['errors'];
    final fieldErrors = <String, List<String>>{};
    if (errorsRaw is Map) {
      for (final entry in errorsRaw.entries) {
        final v = entry.value;
        fieldErrors['${entry.key}'] =
            v is List ? v.map((x) => '$x').toList() : ['$v'];
      }
    }
    final message = map['message'] as String? ??
        (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout
            ? 'تعذّر الاتصال بالخادم'
            : 'حدث خطأ غير متوقع');
    return ApiException(
      message,
      code: map['error_code'] as String?,
      statusCode: e.response?.statusCode,
      fieldErrors: fieldErrors,
    );
  }
}

/// Tiny holder so the Dio interceptor can read the token without importing
/// the auth store (the auth store writes here whenever the token changes).
class AuthTokenHolder {
  static String? token;
}
