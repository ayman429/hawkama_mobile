import '../../../core/network/json_parse.dart';

class Quote {
  final int amount;
  final String amountFormatted;
  final String currency;
  final bool requiresPayment;
  final bool coveredBySubscription;
  final bool? slotAvailable;

  const Quote({
    this.amount = 0,
    this.amountFormatted = '',
    this.currency = 'SAR',
    this.requiresPayment = true,
    this.coveredBySubscription = false,
    this.slotAvailable,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        amount: asInt(json['amount']),
        amountFormatted: asString(json['amount_formatted']),
        currency: asString(json['currency'], 'SAR'),
        requiresPayment: json['requires_payment'] == true,
        coveredBySubscription: json['covered_by_subscription'] == true,
        slotAvailable: json.containsKey('slot_available')
            ? json['slot_available'] == true
            : null,
      );
}
