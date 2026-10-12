import '../../../core/network/json_parse.dart';
import '../../booking/models/booking.dart';

class Dashboard {
  final Booking? nextBooking;
  final int upcomingCount;
  final int completedCount;
  final int cancelledCount;
  final int reportsTotal;
  final int reportsUnread;
  final String currentPackageName;

  const Dashboard({
    this.nextBooking,
    this.upcomingCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
    this.reportsTotal = 0,
    this.reportsUnread = 0,
    this.currentPackageName = '',
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final bookings = asMap(json['bookings']);
    final reports = asMap(json['reports']);
    final subscriptions = json['active_subscriptions'] is List
        ? json['active_subscriptions'] as List
        : const [];
    var packageName = '';
    if (subscriptions.isNotEmpty) {
      packageName = asString(asMap(asMap(subscriptions.first)['package'])['name']);
    }
    return Dashboard(
      nextBooking: json['next_booking'] is Map
          ? Booking.fromJson(asMap(json['next_booking']))
          : null,
      upcomingCount: asInt(bookings['upcoming']),
      completedCount: asInt(bookings['completed']),
      cancelledCount: asInt(bookings['cancelled']),
      reportsTotal: asInt(reports['total']),
      reportsUnread: asInt(reports['unread']),
      currentPackageName: packageName,
    );
  }
}
