import '../../../core/network/json_parse.dart';
import '../../../l10n/strings.dart';

class BookingMini {
  final int id;
  final String name;
  const BookingMini(this.id, this.name);

  factory BookingMini.fromJson(Map<String, dynamic> json) =>
      BookingMini(asInt(json['id']), asString(json['name']));
}

class Booking {
  final int id;
  final String reference;
  final String status;
  final String statusLabel;
  final String paymentStatus;
  final String refundStatus;
  final String reportStatus;
  final String date;
  final String time;
  final String amountFormatted;
  final BookingMini? package;
  final BookingMini? consultant;
  final int? consultantId;
  final String? meetingUrl;

  const Booking({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    this.paymentStatus = '',
    this.refundStatus = 'none',
    this.reportStatus = 'none',
    this.date = '',
    this.time = '',
    this.amountFormatted = '',
    this.package,
    this.consultant,
    this.consultantId,
    this.meetingUrl,
  });

  bool get isUpcoming => status == 'pending' || status == 'pending_payment';
  bool get isCancelled => status == 'cancelled';
  bool get hasReport => reportStatus == 'uploaded';
  String get dateTimeLabel =>
      date.isEmpty ? '' : locDateTimeSlot(date, time);

  factory Booking.fromJson(Map<String, dynamic> json) {
    final consultant = asMap(json['consultant']);
    final meeting = asMap(json['meeting']);
    return Booking(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      status: asString(json['status']),
      statusLabel: asString(json['status_label'], asString(json['status'])),
      paymentStatus: asString(json['payment_status']),
      refundStatus: asString(json['refund_status'], 'none'),
      reportStatus: asString(json['report_status'], 'none'),
      date: asString(json['date']),
      time: asString(json['time']),
      amountFormatted: asString(json['amount_formatted']),
      package: json['package'] is Map
          ? BookingMini.fromJson(asMap(json['package']))
          : null,
      consultant: consultant.isEmpty ? null : BookingMini.fromJson(consultant),
      consultantId: consultant.isEmpty ? null : asInt(consultant['id']),
      meetingUrl: meeting['url'] as String?,
    );
  }
}

class BookingCreateResult {
  final Booking booking;
  final String? paymentStatus;
  final String? transactionUrl;
  final int? paymentId;

  const BookingCreateResult({
    required this.booking,
    this.paymentStatus,
    this.transactionUrl,
    this.paymentId,
  });

  bool get needs3ds =>
      paymentStatus == 'initiated' && (transactionUrl?.isNotEmpty ?? false);
}
