import '../../../core/network/json_parse.dart';

class SavedCard {
  final int id;
  final String brand;
  final String lastFour;
  final String holderName;
  final bool isDefault;
  final bool isExpired;
  final String display;

  const SavedCard({
    required this.id,
    this.brand = '',
    this.lastFour = '',
    this.holderName = '',
    this.isDefault = false,
    this.isExpired = false,
    this.display = '',
  });

  String get label {
    if (display.isNotEmpty) return display;
    if (brand.isEmpty && lastFour.isEmpty) return '••••';
    return '$brand •••• $lastFour'.trim();
  }

  factory SavedCard.fromJson(Map<String, dynamic> json) => SavedCard(
        id: asInt(json['id']),
        brand: asString(json['brand']),
        lastFour: asString(json['last_four']),
        holderName: asString(json['holder_name']),
        isDefault: asBool(json['is_default']),
        isExpired: asBool(json['is_expired']),
        display: asString(json['display']),
      );
}
