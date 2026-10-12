import '../../../core/config.dart';
import '../../../l10n/strings.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../models/client_user.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<Result<AuthResult>> login(String email, String password) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (email.isEmpty || password.isEmpty) {
          throw ApiException(
            tr('invalidCredentials'),
            code: 'INVALID_CREDENTIALS',
            statusCode: 422,
          );
        }
        return AuthResult('demo-token', mockUser);
      }
      final data = asMap(await _api.post(Endpoints.login, {
        'email': email,
        'password': password,
        'device_name': 'mobile',
      }));
      return AuthResult(
        data['token']?.toString() ?? '',
        ClientUser.fromJson(asMap(data['user'])),
      );
    });
  }

  Future<Result<AuthResult>> register({
    required String name,
    required String email,
    required String phone,
    required String company,
    required String password,
    required String passwordConfirmation,
  }) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 350));
        return AuthResult(
          'demo-token',
          ClientUser(
            id: 2,
            name: name.isEmpty ? tr('demoClient') : name,
            email: email,
            phone: phone,
            companyName: company,
          ),
        );
      }
      final data = asMap(await _api.post(Endpoints.register, {
        'name': name,
        'email': email,
        'phone': phone,
        'company_name': company,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': 'mobile',
      }));
      return AuthResult(
        data['token']?.toString() ?? '',
        ClientUser.fromJson(asMap(data['user'])),
      );
    });
  }

  Future<Result<ClientUser>> me() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 200));
        return mockUser;
      }
      return ClientUser.fromJson(asMap(await _api.get(Endpoints.me)));
    });
  }

  Future<void> logout() async {
    if (AppConfig.useMock) return;
    try {
      await _api.post(Endpoints.logout);
    } catch (_) {}
  }
}
