import '../../../core/network/json_parse.dart';
import '../../booking/models/booking.dart';

class Subscription {
  final int id;
  final BookingMini package;
  final String status;
  final int? consultationsLimit;
  final int? consultationsUsed;
  final int? consultationsRemaining;
  final bool isUnlimited;
  final String endsAt;
  final String pricePaidFormatted;

  const Subscription({
    required this.id,
    required this.package,
    required this.status,
    this.consultationsLimit,
    this.consultationsUsed,
    this.consultationsRemaining,
    this.isUnlimited = false,
    this.endsAt = '',
    this.pricePaidFormatted = '',
  });

  bool get isActive => status == 'active';

  bool get canBook =>
      isActive && (isUnlimited || (consultationsRemaining ?? 0) > 0);

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: asInt(json['id']),
        package: BookingMini.fromJson(asMap(json['package'])),
        status: asString(json['status']),
        consultationsLimit: asIntOrNull(json['consultations_limit']),
        consultationsUsed: asIntOrNull(json['consultations_used']),
        consultationsRemaining: asIntOrNull(json['consultations_remaining']),
        isUnlimited: json['is_unlimited'] == true,
        endsAt: asString(json['ends_at']),
        pricePaidFormatted: asString(json['price_paid_formatted']),
      );
}
