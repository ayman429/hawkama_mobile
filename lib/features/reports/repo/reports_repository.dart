import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../models/client_report.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  Future<Result<List<ClientReport>>> reports() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockReports;
      }
      return asList(await _api.get(Endpoints.reports), ClientReport.fromJson);
    });
  }

  String downloadPath(int id) => Endpoints.reportDownload(id);
}
