import 'package:flutter/material.dart';

import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class ClientNotif {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final String type;
  final bool unread;

  const ClientNotif({
    required this.id,
    required this.title,
    required this.body,
    this.timeLabel = '',
    this.type = 'general',
    this.unread = false,
  });

  IconData get icon => switch (type) {
        String value when value.contains('booking') =>
          Icons.calendar_month_outlined,
        String value when value.contains('report') =>
          Icons.description_outlined,
        String value when value.contains('payment') =>
          Icons.credit_card_outlined,
        String value when value.contains('subscription') => Icons.work_outline,
        _ => Icons.notifications_outlined,
      };

  ClientNotif copyWith({bool? unread}) => ClientNotif(
        id: id,
        title: title,
        body: body,
        timeLabel: timeLabel,
        type: type,
        unread: unread ?? this.unread,
      );

  factory ClientNotif.fromJson(Map<String, dynamic> json) {
    final data = asMap(json['data']);
    final typeRaw = asString(json['type']).split('\\').last.toLowerCase();
    return ClientNotif(
      id: asString(json['id']),
      title: asString(data['title'], asString(json['title'], tr('fallbackNotif'))),
      body: asString(data['body'], asString(data['message'], asString(json['body']))),
      type: typeRaw,
      unread: json['read_at'] == null,
    );
  }
}
