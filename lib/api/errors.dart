/// Typed API errors — branch on [code] (stable), never on [message]
/// (translated). Codes from FRONTEND_API_GUIDE.md §1.4.
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  /// 422 field errors: `{ "email": ["حقل البريد…"] }` → show errors[field][0]
  /// next to the form field.
  final Map<String, List<String>> fieldErrors;

  const ApiException(this.message,
      {this.code, this.statusCode, this.fieldErrors = const {}});

  String? fieldError(String field) =>
      fieldErrors[field]?.isNotEmpty == true ? fieldErrors[field]!.first : null;

  bool get isUnauthenticated => statusCode == 401;
  bool get isValidation => code == 'VALIDATION_ERROR';
  bool get isSlotGone => code == 'SLOT_NOT_AVAILABLE';
  bool get isPaymentPending => code == 'PAYMENT_PENDING_CONFIRMATION';
  bool get isPaymentFailed => code == 'PAYMENT_FAILED';
  bool get needsPaymentMethod => code == 'PAYMENT_METHOD_REQUIRED';

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
