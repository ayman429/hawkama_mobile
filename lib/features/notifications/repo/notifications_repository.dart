import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../models/client_notif.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<Result<List<ClientNotif>>> notifications() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockNotifications;
      }
      return asList(
        await _api.get(Endpoints.notifications),
        ClientNotif.fromJson,
      );
    });
  }

  Future<Result<int>> unreadCount() {
    return guard(() async {
      if (AppConfig.useMock) {
        return mockNotifications.where((item) => item.unread).length;
      }
      final data = asMap(await _api.get(Endpoints.unreadCount));
      return (data['count'] ?? data['unread_count'] ?? 0) as int? ?? 0;
    });
  }

  Future<void> markRead(String id) async {
    if (AppConfig.useMock) return;
    try {
      await _api.patch(Endpoints.markNotificationRead(id));
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (AppConfig.useMock) return;
    try {
      await _api.post(Endpoints.markAllRead);
    } catch (_) {}
  }
}
