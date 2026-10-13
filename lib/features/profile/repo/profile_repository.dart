import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../../../l10n/strings.dart';
import '../../auth/models/client_user.dart';
import '../models/client_location.dart';
import '../models/saved_card.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;
  ClientUser? _mockUser;
  final List<ClientLocation> _mockLocations = [];
  final List<SavedCard> _mockCards = [];
  var _mockReady = false;
  var _nextLocationId = 1;
  var _nextCardId = 1;

  void _ensureMock() {
    if (_mockReady) return;
    _mockReady = true;
    _mockUser = mockUser;
    _mockLocations.add(ClientLocation(
      id: _nextLocationId++,
      name: tr('mockLocName'),
      city: tr('mockLocCity'),
      address: tr('mockLocAddress'),
      isDefault: true,
    ));
    _mockCards.add(const SavedCard(
      id: 1,
      brand: 'visa',
      lastFour: '4242',
      holderName: 'Test Card',
      isDefault: true,
      display: 'Visa •••• 4242',
    ));
    _nextCardId = 2;
  }

  Future<Result<ClientUser>> profile() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _ensureMock();
        return _mockUser!;
      }
      return ClientUser.fromJson(asMap(await _api.get(Endpoints.profile)));
    });
  }

  Future<Result<ClientUser>> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String company,
  }) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 250));
        _ensureMock();
        _mockUser = ClientUser(
          id: _mockUser!.id,
          name: name,
          email: email,
          phone: phone,
          companyName: company,
          avatarUrl: _mockUser!.avatarUrl,
          defaultLocationId: _mockUser!.defaultLocationId,
          defaultPaymentMethodId: _mockUser!.defaultPaymentMethodId,
        );
        return _mockUser!;
      }
      return ClientUser.fromJson(asMap(await _api.put(Endpoints.profile, {
        'name': name,
        'email': email,
        'phone': phone,
        'company_name': company,
      })));
    });
  }

  Future<Result<void>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (currentPassword.isEmpty || password.length < 8) {
          throw ApiException(
            tr('unexpected'),
            code: 'VALIDATION_ERROR',
            statusCode: 422,
          );
        }
        return;
      }
      await _api.put(Endpoints.profilePassword, {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    });
  }

  Future<Result<List<ClientLocation>>> locations() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _ensureMock();
        return List<ClientLocation>.of(_mockLocations);
      }
      return asList(await _api.get(Endpoints.locations), ClientLocation.fromJson);
    });
  }

  Future<Result<ClientLocation>> saveLocation({
    int? id,
    required String name,
    required String city,
    required String address,
    required bool isDefault,
  }) {
    return guard(() async {
      final body = {
        'name': name,
        'city': city,
        'address': address,
        'is_default': isDefault,
      };
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 200));
        _ensureMock();
        final location = ClientLocation(
          id: id ?? _nextLocationId++,
          name: name,
          city: city,
          address: address,
          isDefault: isDefault,
        );
        if (isDefault) _clearDefaultLocation();
        if (id == null) {
          _mockLocations.add(location);
        } else {
          final index = _mockLocations.indexWhere((item) => item.id == id);
          if (index >= 0) _mockLocations[index] = location;
        }
        return location;
      }
      final data = id == null
          ? await _api.post(Endpoints.locations, body)
          : await _api.put(Endpoints.location(id), body);
      return ClientLocation.fromJson(asMap(data));
    });
  }

  Future<Result<void>> setDefaultLocation(int id) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _ensureMock();
        _clearDefaultLocation();
        final index = _mockLocations.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final current = _mockLocations[index];
          _mockLocations[index] = ClientLocation(
            id: current.id,
            name: current.name,
            city: current.city,
            address: current.address,
            isDefault: true,
          );
        }
        return;
      }
      await _api.patch(Endpoints.locationDefault(id));
    });
  }

  Future<Result<void>> deleteLocation(int id) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _mockLocations.removeWhere((item) => item.id == id);
        return;
      }
      await _api.delete(Endpoints.location(id));
    });
  }

  Future<Result<List<SavedCard>>> paymentMethods() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _ensureMock();
        return List<SavedCard>.of(_mockCards);
      }
      return asList(
        await _api.get(Endpoints.paymentMethods),
        SavedCard.fromJson,
      );
    });
  }

  Future<Result<SavedCard>> saveCard({
    required String token,
    required bool isDefault,
  }) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (token.trim().isEmpty || token == 'tok_fake_declined') {
          throw ApiException(
            tr('paymentFailed'),
            code: 'PAYMENT_FAILED',
            statusCode: 402,
          );
        }
        _ensureMock();
        if (isDefault) _clearDefaultCard();
        final card = SavedCard(
          id: _nextCardId++,
          brand: 'visa',
          lastFour: '4242',
          isDefault: isDefault || _mockCards.isEmpty,
          display: 'Visa •••• 4242',
        );
        _mockCards.add(card);
        return card;
      }
      return SavedCard.fromJson(asMap(await _api.post(Endpoints.paymentMethods, {
        'token': token,
        'is_default': isDefault,
      })));
    });
  }

  Future<Result<void>> setDefaultCard(int id) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _clearDefaultCard();
        final index = _mockCards.indexWhere((item) => item.id == id);
        if (index >= 0) {
          final current = _mockCards[index];
          _mockCards[index] = SavedCard(
            id: current.id,
            brand: current.brand,
            lastFour: current.lastFour,
            holderName: current.holderName,
            isDefault: true,
            isExpired: current.isExpired,
            display: current.display,
          );
        }
        return;
      }
      await _api.patch(Endpoints.paymentMethodDefault(id));
    });
  }

  Future<Result<void>> deleteCard(int id) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        _mockCards.removeWhere((item) => item.id == id);
        return;
      }
      await _api.delete(Endpoints.paymentMethod(id));
    });
  }

  void _clearDefaultLocation() {
    for (var i = 0; i < _mockLocations.length; i++) {
      final current = _mockLocations[i];
      if (!current.isDefault) continue;
      _mockLocations[i] = ClientLocation(
        id: current.id,
        name: current.name,
        city: current.city,
        address: current.address,
      );
    }
  }

  void _clearDefaultCard() {
    for (var i = 0; i < _mockCards.length; i++) {
      final current = _mockCards[i];
      if (!current.isDefault) continue;
      _mockCards[i] = SavedCard(
        id: current.id,
        brand: current.brand,
        lastFour: current.lastFour,
        holderName: current.holderName,
        isExpired: current.isExpired,
        display: current.display,
      );
    }
  }
}
