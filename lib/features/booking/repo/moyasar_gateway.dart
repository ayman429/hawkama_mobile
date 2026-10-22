import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config.dart';
import '../../../core/network/endpoints.dart';

/// Sends card data only to Moyasar's token endpoint. This client has no logger
/// or app API interceptors, so card details cannot reach app logging. The
/// publishable key is read from the backend's public configuration to keep
/// tokenization in the same Moyasar environment as the charge.
class MoyasarGateway {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.moyasar.com/v1',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: const {'Content-Type': 'application/json'},
  ));
  final Dio _configDio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: const {'Accept': 'application/json'},
  ));

  Future<String> tokenize({
    required String name,
    required String number,
    required String month,
    required String year,
    required String cvc,
  }) async {
    final publishableKey = await _loadPublishableKey();
    if (kDebugMode) {
      log(
        'REQUEST POST https://api.moyasar.com/v1/tokens '
        '{save_only: true, publishable_key_configured: true, '
        'name: [REDACTED], number: [REDACTED], month: [REDACTED], '
        'year: [REDACTED], cvc: [REDACTED]}',
        name: 'Moyasar',
      );
    }
    final normalizedYear = year.trim();
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>('/tokens', data: {
        'publishable_api_key': publishableKey,
        'save_only': true,
        'name': name.trim(),
        'number': number.replaceAll(RegExp(r'\s+'), ''),
        'month': int.parse(month),
        'year': int.parse(normalizedYear.length == 4
            ? normalizedYear.substring(2)
            : normalizedYear),
        'cvc': cvc,
      });
    } on DioException catch (error) {
      if (kDebugMode) {
        final responseData = error.response?.data;
        final message = responseData is Map ? responseData['message'] : null;
        log(
          'ERROR status=${error.response?.statusCode} '
          'type=${error.type.name} message=${message ?? 'No response message'}',
          name: 'Moyasar',
        );
      }
      rethrow;
    }
    final id = response.data?['id'];
    if (kDebugMode) {
      log(
        'RESPONSE ${response.statusCode} '
        '{status: ${response.data?['status'] ?? 'n/a'}, '
        'token_returned: ${id is String && id.isNotEmpty}}',
        name: 'Moyasar',
      );
    }
    if (id is! String || id.isEmpty) {
      throw const FormatException('Moyasar did not return a card token');
    }
    return id;
  }

  Future<String> _loadPublishableKey() async {
    if (kDebugMode) {
      log(
        'REQUEST GET ${_configDio.options.baseUrl}${Endpoints.meta}',
        name: 'PaymentAPI',
      );
    }
    final response =
        await _configDio.get<Map<String, dynamic>>(Endpoints.meta);
    final root = response.data;
    final data = root?['data'];
    final paymentGateway =
        data is Map ? data['payment_gateway'] : null;
    final key = paymentGateway is Map ? paymentGateway['publishable_key'] : null;
    final driver = paymentGateway is Map ? paymentGateway['driver'] : null;
    if (kDebugMode) {
      final keyEnvironment = key is String && key.startsWith('pk_live_')
          ? 'live'
          : key is String && key.startsWith('pk_test_')
              ? 'test'
              : 'unknown';
      log(
        'RESPONSE ${response.statusCode} ${response.requestOptions.uri} '
        '{driver: ${driver ?? 'unknown'}, '
        'publishable_key_environment: $keyEnvironment}',
        name: 'PaymentAPI',
      );
    }
    if (key is! String || !key.startsWith('pk_')) {
      throw const FormatException('Moyasar publishable key is missing');
    }
    return key;
  }
}
