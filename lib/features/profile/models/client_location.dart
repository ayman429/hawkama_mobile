import '../../../core/network/json_parse.dart';

class ClientLocation {
  final int id;
  final String name;
  final String city;
  final String address;
  final bool isDefault;

  const ClientLocation({
    required this.id,
    required this.name,
    this.city = '',
    this.address = '',
    this.isDefault = false,
  });

  factory ClientLocation.fromJson(Map<String, dynamic> json) => ClientLocation(
        id: asInt(json['id']),
        name: asString(json['name']),
        city: asString(json['city']),
        address: asString(json['address']),
        isDefault: asBool(json['is_default']),
      );
}
