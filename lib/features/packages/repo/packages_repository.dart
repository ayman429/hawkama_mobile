import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../../booking/models/booking.dart';
import '../models/consult_package.dart';
import '../models/subscription.dart';

class PackagesRepository {
  PackagesRepository(this._api);

  final ApiClient _api;

  Future<Result<List<ConsultPackage>>> packages() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockPackages;
      }
      return asList(await _api.get(Endpoints.packages), ConsultPackage.fromJson);
    });
  }

  Future<Result<List<Subscription>>> activeSubscriptions() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return [
          Subscription(
            id: 3,
            package: BookingMini(mockPackages[1].id, mockPackages[1].name),
            status: 'active',
            consultationsLimit: 5,
            consultationsUsed: 0,
            consultationsRemaining: 5,
            endsAt: '2026-11-20T00:00:00+03:00',
            pricePaidFormatted: mockPackages[1].priceFormatted,
          ),
        ];
      }
      return asList(
        await _api.get(Endpoints.activeSubscriptions),
        Subscription.fromJson,
      );
    });
  }
}
