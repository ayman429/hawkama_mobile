/// Typed API errors. Branch on [code] (stable), never on [message].
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  const ApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
  });

  String? fieldError(String field) {
    final values = fieldErrors[field];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  bool get isUnauthenticated => statusCode == 401;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
