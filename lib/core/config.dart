/// Runtime configuration, injected with --dart-define at build/run time.
///
/// Examples:
///   flutter run                                 # demo mode, no backend needed
///   flutter run --dart-define=USE_MOCK=false \
///               --dart-define=API_URL=http://<LAN-IP>:8000/api/v1
///   flutter build apk --dart-define=USE_MOCK=false \
///               --dart-define=API_URL=https://staging-api.gcmc.sa/api/v1
class AppConfig {
  /// true = screens use the in-memory demo data from lib/api/repo.dart.
  /// false = all data goes through the real GCMC API.
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// Base URL of the API (…/api/v1). Local default matches the API guide §1.1.
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api/v1',
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
  static const contactAddress = 'الرياض — طريق العروبة';
}
