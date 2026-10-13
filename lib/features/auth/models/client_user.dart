import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class ClientUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String companyName;
  final String? avatarUrl;
  final int? defaultLocationId;
  final int? defaultPaymentMethodId;

  const ClientUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.companyName,
    this.avatarUrl,
    this.defaultLocationId,
    this.defaultPaymentMethodId,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) => ClientUser(
        id: asInt(json['id']),
        name: asString(json['name'], tr('defaultClient')),
        email: asString(json['email']),
        phone: asString(json['phone']),
        companyName: asString(json['company_name']),
        avatarUrl: json['avatar_url'] as String?,
        defaultLocationId: _positiveId(asMap(json['default_location'])['id']),
        defaultPaymentMethodId:
            _positiveId(asMap(json['default_payment_method'])['id']),
      );
}

int? _positiveId(Object? value) {
  final id = asIntOrNull(value);
  if (id == null || id <= 0) return null;
  return id;
}

class AuthResult {
  final String token;
  final ClientUser user;
  const AuthResult(this.token, this.user);
}
