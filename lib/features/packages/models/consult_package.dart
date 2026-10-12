import '../../../core/network/json_parse.dart';

class ConsultPackage {
  final int id;
  final String slug;
  final String name;
  final String description;
  final List<String> features;
  final int price;
  final String priceFormatted;
  final int? consultationsLimit;
  final bool isFeatured;

  const ConsultPackage({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    this.features = const [],
    this.price = 0,
    this.priceFormatted = '',
    this.consultationsLimit,
    this.isFeatured = false,
  });

  bool get isUnlimited => consultationsLimit == null;

  factory ConsultPackage.fromJson(Map<String, dynamic> json) => ConsultPackage(
        id: asInt(json['id']),
        slug: asString(json['slug']),
        name: asString(json['name']),
        description: asString(json['description']),
        features: json['features'] is List
            ? (json['features'] as List)
                .map((item) => item is Map ? asString(item['ar']) : asString(item))
                .where((item) => item.isNotEmpty)
                .toList()
            : const [],
        price: asInt(json['price']),
        priceFormatted: asString(json['price_formatted']),
        consultationsLimit: asIntOrNull(json['consultations_limit']),
        isFeatured: json['is_featured'] == true,
      );
}
