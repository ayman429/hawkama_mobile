/// Runtime configuration, injected with --dart-define at build/run time.
///
/// Examples:
///   flutter run                                 # demo mode, no backend needed
///   flutter run --dart-define=USE_MOCK=false \
///               --dart-define=API_URL=http://<LAN-IP>:8000/api/v1
///   flutter build apk --dart-define=USE_MOCK=false \
///               --dart-define=API_URL=https://staging-api.gcmc.sa/api/v1
class AppConfig {
  /// true = repositories use the in-memory demo data in lib/core/mock.
  /// false = all data goes through the real GCMC API.
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  /// Base URL of the API (…/api/v1). Local default matches the API guide §1.1.
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://www.gcmc.sa/api/v1',
  );

  static const paymentCallbackUrl = String.fromEnvironment(
    'PAYMENT_CALLBACK_URL',
    defaultValue: 'https://www.hawkama.sa/bookings/payment-callback',
  );

  /// WebSocket host (Laravel Reverb) — reserved for the real-time bell
  /// (docs/FRONTEND_NOTIFICATIONS.md).
  static const wsHost = String.fromEnvironment(
    'WS_HOST',
    defaultValue: 'localhost:8080',
  );

  /// Brand contact fallbacks (normally supplied by GET /public/meta).
  static const contactPhone = '+966 550181166';
  static const contactEmail = 'GCMC@GCMC.SA';
}
