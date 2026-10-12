import 'api_exception.dart';

class Failure {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  const Failure({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const {},
  });

  factory Failure.from(Object error) {
    if (error is ApiException) {
      return Failure(
        message: error.message,
        code: error.code,
        statusCode: error.statusCode,
        fieldErrors: error.fieldErrors,
      );
    }
    return Failure(message: error.toString());
  }

  Map<String, String> get firstFieldErrors => {
        for (final entry in fieldErrors.entries)
          if (entry.value.isNotEmpty) entry.key: entry.value.first,
      };

  bool get isSlotGone => code == 'SLOT_NOT_AVAILABLE';
  bool get isPaymentPending => code == 'PAYMENT_PENDING_CONFIRMATION';
}
