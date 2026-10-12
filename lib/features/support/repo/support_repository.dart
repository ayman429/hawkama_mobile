import '../../../core/config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/result.dart';

class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;

  Future<Result<void>> send(String subject, String message) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 350));
        return;
      }
      await _api.post(Endpoints.supportTickets, {
        'subject': subject,
        'message': message,
      });
    });
  }
}
