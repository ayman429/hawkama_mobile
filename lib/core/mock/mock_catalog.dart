import '../../l10n/strings.dart';
import '../../features/auth/models/client_user.dart';
import '../../features/booking/models/booking.dart';
import '../../features/booking/models/consultant.dart';
import '../../features/booking/models/slot.dart';
import '../../features/notifications/models/client_notif.dart';
import '../../features/packages/models/consult_package.dart';
import '../../features/reports/models/client_report.dart';

ClientUser get mockUser => ClientUser(
      id: 2,
      name: tr('mockUserName'),
      email: 'client@company.sa',
      phone: '0550181166',
      companyName: tr('mockCompany'),
    );

List<ConsultPackage> get mockPackages => [
      ConsultPackage(
        id: 1,
        slug: 'iron',
        name: tr('mockPkgIron'),
        features: [
          tr('mockFeatIron1'),
          tr('mockFeatIron2'),
          tr('mockFeatIron3'),
        ],
        price: 190000,
        priceFormatted: '1,900.00 SAR',
        consultationsLimit: 2,
      ),
      ConsultPackage(
        id: 2,
        slug: 'silver',
        name: tr('mockPkgSilver'),
        features: [
          tr('mockFeatSilver1'),
          tr('mockFeatSilver2'),
          tr('mockFeatSilver3'),
        ],
        price: 450000,
        priceFormatted: '4,500.00 SAR',
        consultationsLimit: 5,
        isFeatured: true,
      ),
      ConsultPackage(
        id: 3,
        slug: 'gold',
        name: tr('mockPkgGold'),
        features: [
          tr('mockFeatGold1'),
          tr('mockFeatGold2'),
          tr('mockFeatGold3'),
        ],
        price: 980000,
        priceFormatted: '9,800.00 SAR',
        isFeatured: true,
      ),
    ];

List<Consultant> get mockConsultants => [
      Consultant(
        id: 3,
        name: tr('mockCons1Name'),
        title: tr('mockCons1Title'),
        specialization: tr('mockCons1Spec'),
        rating: 4.9,
        jobsLabel: tr('mockCons1Jobs'),
      ),
      Consultant(
        id: 2,
        name: tr('mockCons2Name'),
        title: tr('mockCons2Title'),
        specialization: tr('mockCons2Spec'),
        rating: 4.8,
        jobsLabel: tr('mockCons2Jobs'),
      ),
      Consultant(
        id: 8,
        name: tr('mockCons3Name'),
        title: tr('mockCons3Title'),
        specialization: tr('mockCons3Spec'),
        rating: 4.7,
        jobsLabel: tr('mockCons3Jobs'),
      ),
    ];

final mockAvailableDates = <String>[
  for (final day in [8, 12, 14, 15, 19, 22, 26, 29])
    '2026-10-${day.toString().padLeft(2, '0')}',
];

const mockSlots = <Slot>[
  Slot(time: '10:00', startsAt: '2026-10-14T10:00:00+03:00'),
  Slot(time: '11:30', startsAt: '2026-10-14T11:30:00+03:00'),
  Slot(time: '12:00', startsAt: '2026-10-14T12:00:00+03:00'),
  Slot(time: '13:30', startsAt: '2026-10-14T13:30:00+03:00'),
  Slot(time: '15:00', startsAt: '2026-10-14T15:00:00+03:00'),
  Slot(time: '16:30', startsAt: '2026-10-14T16:30:00+03:00'),
];

List<Booking> get mockBookings {
  final packages = mockPackages;
  return [
    Booking(
      id: 5,
      reference: 'BK-2026-000005',
      status: 'pending',
      statusLabel: tr('statusPending'),
      paymentStatus: 'paid',
      date: '2026-10-14',
      time: '10:00',
      amountFormatted: packages[0].priceFormatted,
      package: BookingMini(1, packages[0].name),
      consultant: BookingMini(3, tr('mockCons1Name')),
      consultantId: 3,
      meetingUrl: 'https://meet.google.com/abc-defg-hij',
    ),
    Booking(
      id: 4,
      reference: 'BK-2026-000004',
      status: 'pending_payment',
      statusLabel: tr('statusPendingPayment'),
      date: '2026-10-19',
      time: '12:00',
      amountFormatted: packages[1].priceFormatted,
      package: BookingMini(2, packages[1].name),
      consultant: BookingMini(2, tr('mockCons2Name')),
      consultantId: 2,
    ),
    Booking(
      id: 3,
      reference: 'BK-2026-000003',
      status: 'completed',
      statusLabel: tr('statusCompleted'),
      paymentStatus: 'paid',
      reportStatus: 'uploaded',
      date: '2026-09-28',
      time: '11:30',
      amountFormatted: packages[0].priceFormatted,
      package: BookingMini(1, packages[0].name),
      consultant: BookingMini(3, tr('mockCons1Name')),
      consultantId: 3,
    ),
    Booking(
      id: 2,
      reference: 'BK-2026-000002',
      status: 'completed',
      statusLabel: tr('statusCompleted'),
      paymentStatus: 'paid',
      date: '2026-09-14',
      time: '13:30',
      amountFormatted: packages[0].priceFormatted,
      package: BookingMini(1, packages[0].name),
      consultant: BookingMini(8, tr('mockCons3Name')),
      consultantId: 8,
    ),
    Booking(
      id: 1,
      reference: 'BK-2026-000001',
      status: 'cancelled',
      statusLabel: tr('statusCancelled'),
      date: '2026-09-07',
      time: '15:00',
      amountFormatted: packages[0].priceFormatted,
      package: BookingMini(1, packages[0].name),
      consultant: BookingMini(2, tr('mockCons2Name')),
      consultantId: 2,
    ),
  ];
}

List<ClientReport> get mockReports => [
      ClientReport(
        id: 3,
        title: tr('mockReport1Title'),
        meta: tr('mockReport1Meta'),
        createdAt: '2026-10-02',
      ),
      ClientReport(
        id: 2,
        title: tr('mockReport2Title'),
        meta: tr('mockReport2Meta'),
        createdAt: '2026-09-02',
        unread: true,
      ),
      ClientReport(
        id: 1,
        title: tr('mockReport3Title'),
        meta: tr('mockReport3Meta'),
        available: false,
      ),
    ];

List<ClientNotif> get mockNotifications => [
      ClientNotif(
        id: '1',
        title: tr('mockNotif1Title'),
        body: tr('mockNotif1Body'),
        timeLabel: tr('mockNotif1Time'),
        type: 'booking',
        unread: true,
      ),
      ClientNotif(
        id: '2',
        title: tr('mockNotif2Title'),
        body: tr('mockNotif2Body'),
        timeLabel: tr('mockNotif2Time'),
        type: 'report',
        unread: true,
      ),
      ClientNotif(
        id: '3',
        title: tr('mockNotif3Title'),
        body: tr('mockNotif3Body'),
        timeLabel: tr('mockNotif3Time'),
      ),
      ClientNotif(
        id: '4',
        title: tr('mockNotif4Title'),
        body: tr('mockNotif4Body'),
        timeLabel: tr('mockNotif4Time'),
        type: 'payment',
      ),
    ];
