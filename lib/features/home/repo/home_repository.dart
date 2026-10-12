import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../models/dashboard.dart';

class HomeRepository {
  HomeRepository(this._api);

  final ApiClient _api;

  Future<Result<Dashboard>> dashboard() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 200));
        return Dashboard(
          nextBooking: mockBookings.first,
          upcomingCount: 2,
          reportsTotal: 4,
          reportsUnread: 1,
          currentPackageName: mockPackages[1].name,
        );
      }
      return Dashboard.fromJson(asMap(await _api.get(Endpoints.dashboard)));
    });
  }
}
