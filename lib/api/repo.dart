import '../core/config.dart';
import 'api_client.dart';
import 'errors.dart';
import 'models.dart';

Map<String, dynamic> _m(Object? v) =>
    v is Map<String, dynamic> ? v : const {};

List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) f) {
  if (data is! List) return [];
  return data
      .whereType<Map>()
      .map((e) => f(Map<String, dynamic>.from(e)))
      .toList();
}

/// Client-facing repository. When [AppConfig.useMock] is true everything comes
/// from the demo data below so the app runs without a backend; flip it off to
/// talk to the real API (FRONTEND_API_GUIDE.md).
class Repo {
  static final _api = ApiClient.instance;

  // ════════════════════ Auth (§2.2) ════════════════════

  static Future<AuthResult> login(String email, String password) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (email.isEmpty || password.isEmpty) {
        throw const ApiException('بيانات الدخول غير صحيحة',
            code: 'INVALID_CREDENTIALS', statusCode: 422);
      }
      return AuthResult('demo-token', _mockUser);
    }
    final data = _m(await _api.post('/client/auth/login',
        {'email': email, 'password': password, 'device_name': 'mobile'}));
    return AuthResult(
        data['token']?.toString() ?? '',
        ClientUser.fromJson(_m(data['user'])));
  }

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String company,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 350));
      return AuthResult(
          'demo-token',
          ClientUser(
              id: 2,
              name: name.isEmpty ? 'عميل تجريبي' : name,
              email: email,
              phone: phone,
              companyName: company));
    }
    final data = _m(await _api.post('/client/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'company_name': company,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': 'mobile',
    }));
    return AuthResult(
        data['token']?.toString() ?? '',
        ClientUser.fromJson(_m(data['user'])));
  }

  static Future<ClientUser> me() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockUser;
    }
    return ClientUser.fromJson(_m(await _api.get('/client/auth/me')));
  }

  static Future<void> logout() async {
    if (!AppConfig.useMock) {
      try {
        await _api.post('/client/auth/logout');
      } catch (_) {/* token may already be revoked */}
    }
  }

  // ════════════════════ Public content (PUB) ════════════════════

  static Future<List<ConsultPackage>> packages() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockPackages;
    }
    return _list(await _api.get('/public/packages'), ConsultPackage.fromJson);
  }

  static Future<List<Consultant>> consultants({String? specialization}) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockConsultants;
    }
    return _list(
      await _api.get('/public/consultants', {
        if (specialization != null) 'specialization': specialization,
      }),
      Consultant.fromJson,
    );
  }

  static Future<List<String>> availableDates(int consultantId, String ym) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockAvailableDates;
    }
    final data = _m(await _api.get(
        '/public/consultants/$consultantId/available-dates', {'month': ym}));
    return (data['dates'] is List)
        ? (data['dates'] as List).map((e) => '$e').toList()
        : const [];
  }

  static Future<List<Slot>> slots(int consultantId, String date) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockSlots;
    }
    final data = _m(await _api
        .get('/public/consultants/$consultantId/slots', {'date': date}));
    return _list(data['slots'], Slot.fromJson);
  }

  // ════════════════════ Booking (CLI-BKG) ════════════════════

  static Future<Quote> quote({
    required int packageId,
    int? consultantId,
    String? date,
    String? time,
  }) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return Quote(
        amount: _mockPackages.first.price,
        amountFormatted: _mockPackages.first.priceFormatted,
        requiresPayment: true,
      );
    }
    return Quote.fromJson(_m(await _api.post('/client/bookings/quote', {
      'package_id': packageId,
      if (consultantId != null) 'consultant_id': consultantId,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
    })));
  }

  static Future<BookingCreateResult> createBooking({
    required int packageId,
    required int consultantId,
    required String date,
    required String time,
    int? clientLocationId,
    int? paymentMethodId,
    String? cardToken,
    String? notes,
  }) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return BookingCreateResult(
        booking: Booking(
          id: 6,
          reference: 'BK-2026-000006',
          status: 'pending',
          statusLabel: 'قيد الانتظار',
          paymentStatus: 'paid',
          date: date,
          time: time,
          amountFormatted: _mockPackages.first.priceFormatted,
          meetingUrl: 'https://meet.google.com/abc-defg-hij',
        ),
        paymentStatus: 'paid',
      );
    }
    final data = _m(await _api.post('/client/bookings', {
      'package_id': packageId,
      'consultant_id': consultantId,
      'date': date,
      'time': time,
      if (clientLocationId != null) 'client_location_id': clientLocationId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (cardToken != null) 'card_token': cardToken,
      if (notes != null && notes.isNotEmpty) 'client_notes': notes,
    }));
    final payment = _m(data['payment']);
    return BookingCreateResult(
      booking: Booking.fromJson(_m(data['booking'])),
      paymentStatus: payment['status'] as String?,
      transactionUrl: payment['transaction_url'] as String?,
      paymentId: payment['id'] as int?,
    );
  }

  static Future<List<Booking>> bookings() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockBookings;
    }
    return _list(await _api.get('/client/bookings'), Booking.fromJson);
  }

  static Future<void> cancelBooking(int id) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return;
    }
    await _api.post('/client/bookings/$id/cancel');
  }

  // ════════════════════ Dashboard (CLI-DSH-01) ════════════════════

  static Future<Dashboard> dashboard() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return Dashboard(
        nextBooking: _mockBookings.first,
        upcomingCount: 2,
        reportsTotal: 4,
        reportsUnread: 1,
        currentPackageName: _mockPackages[1].name,
      );
    }
    return Dashboard.fromJson(_m(await _api.get('/client/dashboard')));
  }

  // ════════════════════ Reports (CLI-RPT) ════════════════════

  static Future<List<ClientReport>> reports() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockReports;
    }
    return _list(await _api.get('/client/reports'), ClientReport.fromJson);
  }

  /// Downloads need the Bearer token, so the screen opens the endpoint via
  /// the API origin with url_launcher on web only; on native use a downloader
  /// (see README § reports).
  static String reportDownloadPath(int id) => '/client/reports/$id/download';

  // ════════════════════ Subscriptions (CLI-SUB) ════════════════════

  static Future<List<Subscription>> activeSubscriptions() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return [
        Subscription(
          id: 3,
          package: BookingMini(_mockPackages[1].id, _mockPackages[1].name),
          status: 'active',
          consultationsLimit: 5,
          consultationsUsed: 0,
          consultationsRemaining: 5,
          endsAt: '2026-11-20T00:00:00+03:00',
          pricePaidFormatted: _mockPackages[1].priceFormatted,
        ),
      ];
    }
    return _list(
        await _api.get('/client/subscriptions/active'), Subscription.fromJson);
  }

  // ════════════════════ Notifications (CLI-NTF) ════════════════════

  static Future<List<ClientNotif>> notifications() async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _mockNotifs;
    }
    return _list(await _api.get('/client/notifications'), ClientNotif.fromJson);
  }

  static Future<int> unreadCount() async {
    if (AppConfig.useMock) return _mockNotifs.where((n) => n.unread).length;
    final data = _m(await _api.get('/client/notifications/unread-count'));
    return (data['count'] ?? data['unread_count'] ?? 0) as int? ?? 0;
  }

  static Future<void> markNotifRead(String id) async {
    if (AppConfig.useMock) return;
    try {
      await _api.patch('/client/notifications/$id/read');
    } catch (_) {/* cosmetic */}
  }

  static Future<void> markAllNotifsRead() async {
    if (AppConfig.useMock) return;
    try {
      await _api.post('/client/notifications/read-all');
    } catch (_) {/* cosmetic */}
  }

  /// Real-time bell wiring (Reverb / Pusher protocol) — scratchpad for the
  /// developer; see docs/FRONTEND_NOTIFICATIONS.md. private `client.{id}`
  /// channel; on new notification → refresh [unreadCount].

  // ════════════════════ Support (contact) ════════════════════

  static Future<void> sendSupportMessage(String subject, String message) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 350));
      return;
    }
    await _api.post('/client/support-tickets',
        {'subject': subject, 'message': message});
  }

  // ════════════════════ Mock data (match the mockup) ════════════════════

  static const _mockUser = ClientUser(
    id: 2,
    name: 'أحمد المطيري',
    email: 'client@company.sa',
    phone: '0550181166',
    companyName: 'شركة الاختبار',
  );

  static final _mockPackages = <ConsultPackage>[
    const ConsultPackage(
      id: 1,
      slug: 'iron',
      name: 'الباقة الحديدية',
      features: ['استشارتان شهرياً', 'مراجعة مستندين', 'تقرير ربع سنوي'],
      price: 190000,
      priceFormatted: '1,900.00 SAR',
      consultationsLimit: 2,
    ),
    const ConsultPackage(
      id: 2,
      slug: 'silver',
      name: 'الباقة الفضية',
      features: ['٥ استشارات شهرياً', 'مراجعة ٨ مستندات', 'تقرير أداء شهري'],
      price: 450000,
      priceFormatted: '4,500.00 SAR',
      consultationsLimit: 5,
      isFeatured: true,
    ),
    const ConsultPackage(
      id: 3,
      slug: 'gold',
      name: 'الباقة الذهبية',
      features: ['استشارات غير محدودة', 'مستشار مخصص', 'دعم 24/7'],
      price: 980000,
      priceFormatted: '9,800.00 SAR',
      isFeatured: true,
    ),
  ];

  static final _mockConsultants = <Consultant>[
    const Consultant(
        id: 3,
        name: 'د. سارة الدوسري',
        title: 'متخصصة الحوكمة والامتثال',
        specialization: 'الحوكمة والامتثال',
        rating: 4.9,
        jobsLabel: '٣٢٠ استشارة'),
    const Consultant(
        id: 2,
        name: 'أ. أحمد العتيبي',
        title: 'مستشار الاستشارات الإدارية',
        specialization: 'الاستشارات الإدارية',
        rating: 4.8,
        jobsLabel: '٢٨٠ استشارة'),
    const Consultant(
        id: 8,
        name: 'أ. نورة القحطاني',
        title: 'استشارية مخاطر وامتثال',
        specialization: 'إدارة المخاطر',
        rating: 4.7,
        jobsLabel: '٢١٠ استشارات'),
  ];

  static final _mockAvailableDates = <String>[
    for (final d in [8, 12, 14, 15, 19, 22, 26, 29])
      '2026-10-${d.toString().padLeft(2, '0')}',
  ];

  static final _mockSlots = <Slot>[
    const Slot(time: '10:00', startsAt: '2026-10-14T10:00:00+03:00'),
    const Slot(time: '11:30', startsAt: '2026-10-14T11:30:00+03:00'),
    const Slot(time: '12:00', startsAt: '2026-10-14T12:00:00+03:00'),
    const Slot(time: '13:30', startsAt: '2026-10-14T13:30:00+03:00'),
    const Slot(time: '15:00', startsAt: '2026-10-14T15:00:00+03:00'),
    const Slot(time: '16:30', startsAt: '2026-10-14T16:30:00+03:00'),
  ];

  static final _mockBookings = <Booking>[
    Booking(
      id: 5,
      reference: 'BK-2026-000005',
      status: 'pending',
      statusLabel: 'قيد الانتظار',
      paymentStatus: 'paid',
      date: '2026-10-14',
      time: '10:00',
      amountFormatted: _mockPackages[0].priceFormatted,
      package: BookingMini(1, _mockPackages[0].name),
      consultant: const BookingMini(3, 'د. سارة الدوسري'),
      consultantId: 3,
      meetingUrl: 'https://meet.google.com/abc-defg-hij',
    ),
    Booking(
      id: 4,
      reference: 'BK-2026-000004',
      status: 'pending_payment',
      statusLabel: 'في انتظار الدفع',
      date: '2026-10-19',
      time: '12:00',
      amountFormatted: _mockPackages[1].priceFormatted,
      package: BookingMini(2, _mockPackages[1].name),
      consultant: const BookingMini(2, 'أ. أحمد العتيبي'),
      consultantId: 2,
    ),
    Booking(
      id: 3,
      reference: 'BK-2026-000003',
      status: 'completed',
      statusLabel: 'مكتمل',
      paymentStatus: 'paid',
      reportStatus: 'uploaded',
      date: '2026-09-28',
      time: '11:30',
      amountFormatted: _mockPackages[0].priceFormatted,
      package: BookingMini(1, _mockPackages[0].name),
      consultant: const BookingMini(3, 'د. سارة الدوسري'),
      consultantId: 3,
    ),
    Booking(
      id: 2,
      reference: 'BK-2026-000002',
      status: 'completed',
      statusLabel: 'مكتمل',
      paymentStatus: 'paid',
      date: '2026-09-14',
      time: '13:30',
      amountFormatted: _mockPackages[0].priceFormatted,
      package: BookingMini(1, _mockPackages[0].name),
      consultant: const BookingMini(8, 'أ. نورة القحطاني'),
      consultantId: 8,
    ),
    Booking(
      id: 1,
      reference: 'BK-2026-000001',
      status: 'cancelled',
      statusLabel: 'ملغي',
      date: '2026-09-07',
      time: '15:00',
      amountFormatted: _mockPackages[0].priceFormatted,
      package: BookingMini(1, _mockPackages[0].name),
      consultant: const BookingMini(2, 'أ. أحمد العتيبي'),
      consultantId: 2,
    ),
  ];

  static final _mockReports = <ClientReport>[
    const ClientReport(
        id: 3,
        title: 'تقرير الأداء الشهري — سبتمبر',
        meta: '٠٢ أكتوبر ٢٠٢٦ · PDF · ١٫٢ م.ب',
        createdAt: '2026-10-02',
        available: true),
    const ClientReport(
        id: 2,
        title: 'تقرير الأداء الشهري — أغسطس',
        meta: '٠٢ سبتمبر ٢٠٢٦ · PDF · ١٫١ م.ب',
        createdAt: '2026-09-02',
        available: true,
        unread: true),
    const ClientReport(
        id: 1,
        title: 'تقرير الامتثال الربع سنوي Q3',
        meta: 'يُصدر بنهاية أكتوبر',
        createdAt: '',
        available: false),
  ];

  static final _mockNotifs = <ClientNotif>[
    const ClientNotif(
        id: '1',
        title: 'تم تأكيد حجزك',
        body: 'استشارة الحوكمة مع د. سارة يوم الثلاثاء الساعة ١٠:٠٠ ص',
        timeLabel: 'قبل ٥ دقائق',
        type: 'booking',
        unread: true),
    const ClientNotif(
        id: '2',
        title: 'تقرير جديد متاح',
        body: 'تقرير الأداء الشهري لشهر سبتمبر جاهز الآن',
        timeLabel: 'قبل ساعتين',
        type: 'report',
        unread: true),
    const ClientNotif(
        id: '3',
        title: 'تذكير بموعدك',
        body: 'موعدك غداً الساعة ١٢:٠٠ م — الجلسة عبر Google Meet',
        timeLabel: 'أمس'),
    const ClientNotif(
        id: '4',
        title: 'تم الدفع بنجاح',
        body: 'اشتراك الباقة الفضية — ٤٬٥٠٠ ر.س',
        timeLabel: 'قبل ٣ أيام',
        type: 'payment'),
  ];
}
