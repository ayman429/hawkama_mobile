import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../l10n/strings.dart';

Map<String, dynamic> _m(Object? v) =>
    v is Map<String, dynamic> ? v : const {};
String _s(Object? v, [String fallback = '']) => v?.toString() ?? fallback;
int _i(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
int? _iN(Object? v) => v == null ? null : _i(v);

// ─────────────────────────── User (§2.2) ───────────────────────────

class ClientUser {
  final int id;
  final String name, email, phone, companyName;
  final String? avatarUrl;
  const ClientUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.companyName,
    this.avatarUrl,
  });

  factory ClientUser.fromJson(Map<String, dynamic> j) => ClientUser(
        id: _i(j['id']),
        name: _s(j['name'], 'العميل'),
        email: _s(j['email']),
        phone: _s(j['phone']),
        companyName: _s(j['company_name']),
        avatarUrl: j['avatar_url'] as String?,
      );
}

class AuthResult {
  final String token;
  final ClientUser user;
  const AuthResult(this.token, this.user);
}

// ─────────────────────────── Packages (PUB-01) ───────────────────────────

class ConsultPackage {
  final int id;
  final String slug, name, description;
  final List<String> features;
  final int price; // halalas
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

  factory ConsultPackage.fromJson(Map<String, dynamic> j) => ConsultPackage(
        id: _i(j['id']),
        slug: _s(j['slug']),
        name: _s(j['name']),
        description: _s(j['description']),
        features: (j['features'] is List)
            ? (j['features'] as List)
                .map((f) => f is Map ? _s(f['ar']) : _s(f))
                .where((f) => f.isNotEmpty)
                .toList()
            : const [],
        price: _i(j['price']),
        priceFormatted: _s(j['price_formatted']),
        consultationsLimit: _iN(j['consultations_limit']),
        isFeatured: j['is_featured'] == true,
      );
}

// ─────────────────────────── Consultants (PUB-03) ───────────────────────────

class Consultant {
  final int id;
  final String name, title, specialization;
  final String? avatarUrl;
  final List<int> workingDays; // 0=Sunday…6=Saturday
  final double rating; // mock-only cosmetic (المستشارون in mockup)
  final String jobsLabel;

  const Consultant({
    required this.id,
    required this.name,
    required this.title,
    this.specialization = '',
    this.avatarUrl,
    this.workingDays = const [0, 1, 2, 3, 4],
    this.rating = 4.8,
    this.jobsLabel = '٢٠٠+ استشارة',
  });

  factory Consultant.fromJson(Map<String, dynamic> j) => Consultant(
        id: _i(j['id']),
        name: _s(j['name']),
        title: _s(j['title']),
        specialization: _s(j['specialization']),
        avatarUrl: (j['avatar_thumb_url'] ?? j['avatar_url']) as String?,
        workingDays: (j['working_days'] is List)
            ? (j['working_days'] as List).map(_i).toList()
            : const [],
      );
}

// ─────────────────────────── Slots (PUB-05/06) ───────────────────────────

class Slot {
  final String time; // "HH:MM"
  final String startsAt, endsAt;
  const Slot({required this.time, this.startsAt = '', this.endsAt = ''});

  String get label => locTime(time);

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
        time: _s(j['time']),
        startsAt: _s(j['starts_at']),
        endsAt: _s(j['ends_at']),
      );
}

// ─────────────────────────── Quote (CLI-BKG-01) ───────────────────────────

class Quote {
  final int amount;
  final String amountFormatted, currency;
  final bool requiresPayment, coveredBySubscription;
  final bool? slotAvailable;

  const Quote({
    this.amount = 0,
    this.amountFormatted = '',
    this.currency = 'SAR',
    this.requiresPayment = true,
    this.coveredBySubscription = false,
    this.slotAvailable,
  });

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        amount: _i(j['amount']),
        amountFormatted: _s(j['amount_formatted']),
        currency: _s(j['currency'], 'SAR'),
        requiresPayment: j['requires_payment'] == true,
        coveredBySubscription: j['covered_by_subscription'] == true,
        slotAvailable: j.containsKey('slot_available')
            ? j['slot_available'] == true
            : null,
      );
}

// ─────────────────────────── Booking (CLI-BKG-02/03) ───────────────────────────

class BookingMini {
  final int id;
  final String name; // package/consultant display name
  const BookingMini(this.id, this.name);
  factory BookingMini.fromJson(Map<String, dynamic> j) =>
      BookingMini(_i(j['id']), _s(j['name']));
}

class Booking {
  final int id;
  final String reference, status, statusLabel;
  final String paymentStatus, refundStatus, reportStatus;
  final String date, time;
  final String amountFormatted;
  final BookingMini? package, consultant;
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
      date.isEmpty ? '' : arDateTimeSlot(date, time);

  factory Booking.fromJson(Map<String, dynamic> j) {
    final consultant = _m(j['consultant']);
    final meeting = _m(j['meeting']);
    return Booking(
      id: _i(j['id']),
      reference: _s(j['reference']),
      status: _s(j['status']),
      statusLabel: _s(j['status_label'], _s(j['status'])),
      paymentStatus: _s(j['payment_status']),
      refundStatus: _s(j['refund_status'], 'none'),
      reportStatus: _s(j['report_status'], 'none'),
      date: _s(j['date']),
      time: _s(j['time']),
      amountFormatted: _s(j['amount_formatted']),
      package: j['package'] is Map
          ? BookingMini.fromJson(_m(j['package']))
          : null,
      consultant:
          consultant.isEmpty ? null : BookingMini.fromJson(consultant),
      consultantId: consultant.isEmpty ? null : _i(consultant['id']),
      meetingUrl: meeting['url'] as String?,
    );
  }
}

class BookingCreateResult {
  final Booking booking;
  final String? paymentStatus, transactionUrl;
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

// ─────────────────────────── Dashboard (CLI-DSH-01) ───────────────────────────

class Dashboard {
  final Booking? nextBooking;
  final int upcomingCount, completedCount, cancelledCount;
  final int reportsTotal, reportsUnread;
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

  factory Dashboard.fromJson(Map<String, dynamic> j) {
    final bookings = _m(j['bookings']);
    final reports = _m(j['reports']);
    final subs = j['active_subscriptions'] is List
        ? j['active_subscriptions'] as List
        : const [];
    String pkgName = '';
    if (subs.isNotEmpty) {
      pkgName = _s(_m(_m(subs.first)['package'])['name']);
    }
    return Dashboard(
      nextBooking: j['next_booking'] is Map
          ? Booking.fromJson(_m(j['next_booking']))
          : null,
      upcomingCount: _i(bookings['upcoming']),
      completedCount: _i(bookings['completed']),
      cancelledCount: _i(bookings['cancelled']),
      reportsTotal: _i(reports['total']),
      reportsUnread: _i(reports['unread']),
      currentPackageName: pkgName,
    );
  }
}

// ─────────────────────────── Reports (CLI-RPT-01) ───────────────────────────

class ClientReport {
  final int id;
  final String title, meta, createdAt;
  final bool available; // file present
  final bool unread;    // never downloaded

  const ClientReport({
    required this.id,
    required this.title,
    this.meta = '',
    this.createdAt = '',
    this.available = true,
    this.unread = false,
  });

  factory ClientReport.fromJson(Map<String, dynamic> j) {
    final fileName = _s(j['file_name']);
    final size = _s(j['file_size_formatted']);
    final created = _s(j['created_at']);
    final createdDate = locDate(
        created.length >= 10 ? created.substring(0, 10) : created);
    final metaParts = <String>[
      if (created.isNotEmpty) createdDate,
      if (fileName.isNotEmpty)
        fileName.split('.').last.toUpperCase(),
      if (size.isNotEmpty) size,
    ];
    return ClientReport(
      id: _i(j['id']),
      title: _s(j['title'], 'تقرير'),
      meta: metaParts.join(' · '),
      createdAt: created,
      available: fileName.isNotEmpty || j['download_url'] != null,
      unread: j['first_downloaded_at'] == null,
    );
  }
}

// ─────────────────────────── Subscriptions (CLI-SUB-01/02) ───────────────────────────

class Subscription {
  final int id;
  final BookingMini package;
  final String status; // active | expired | cancelled
  final int? consultationsLimit, consultationsUsed, consultationsRemaining;
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
  bool get canBook => isActive &&
      (isUnlimited || (consultationsRemaining ?? 0) > 0);

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: _i(j['id']),
        package: BookingMini.fromJson(_m(j['package'])),
        status: _s(j['status']),
        consultationsLimit: _iN(j['consultations_limit']),
        consultationsUsed: _iN(j['consultations_used']),
        consultationsRemaining: _iN(j['consultations_remaining']),
        isUnlimited: j['is_unlimited'] == true,
        endsAt: _s(j['ends_at']),
        pricePaidFormatted: _s(j['price_paid_formatted']),
      );
}

// ─────────────────────────── Notifications (CLI-NTF-01) ───────────────────────────

class ClientNotif {
  final String id;
  final String title, body, timeLabel, type;
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
        String s when s.contains('booking') => Icons.calendar_month_outlined,
        String s when s.contains('report') => Icons.description_outlined,
        String s when s.contains('payment') => Icons.credit_card_outlined,
        String s when s.contains('subscription') => Icons.work_outline,
        _ => Icons.notifications_outlined,
      };

  /// Laravel notifications shape: { id, type, data:{title, body/…}, read_at, created_at }
  factory ClientNotif.fromJson(Map<String, dynamic> j) {
    final data = _m(j['data']);
    final typeRaw = _s(j['type']).split('\\').last.toLowerCase();
    return ClientNotif(
      id: _s(j['id']),
      title: _s(data['title'], _s(j['title'], 'إشعار')),
      body: _s(data['body'], _s(data['message'], _s(j['body']))),
      type: typeRaw,
      unread: j['read_at'] == null,
    );
  }
}
