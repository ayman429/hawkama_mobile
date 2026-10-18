class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const login = '/login';
  static const packages = '/packages';
  static const notifications = '/notifications';
  static const contact = '/contact';
  static const bookingService = '/booking/service';
  static const bookingConsultant = '/booking/consultant';
  static const bookingSchedule = '/booking/schedule';
  static const bookingConfirm = '/booking/confirm';
  static const bookingSuccess = '/booking/success';
  static const bookingDetail = '/bookings/:id';
  static const personalData = '/profile/personal';
  static const addresses = '/profile/addresses';
  static const paymentMethods = '/profile/payment-methods';
  static const reportViewer = '/reports/view';

  static String bookingDetailOf(int id) => '/bookings/$id';
}
