import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class Slot {
  final String time;
  final String startsAt;
  final String endsAt;

  const Slot({required this.time, this.startsAt = '', this.endsAt = ''});

  String get label => locTime(time);

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        time: asString(json['time']),
        startsAt: asString(json['starts_at']),
        endsAt: asString(json['ends_at']),
      );
}
