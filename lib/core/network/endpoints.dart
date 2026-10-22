class Endpoints {
  static const login = '/client/auth/login';
  static const register = '/client/auth/register';
  static const me = '/client/auth/me';
  static const logout = '/client/auth/logout';
  static const packages = '/public/packages';
  static const consultants = '/public/consultants';
  static const meta = '/public/meta';
  static const quote = '/client/bookings/quote';
  static const bookings = '/client/bookings';
  static const dashboard = '/client/dashboard';
  static const reports = '/client/reports';
  static const activeSubscriptions = '/client/subscriptions/active';
  static const notifications = '/client/notifications';
  static const unreadCount = '/client/notifications/unread-count';
  static const markAllRead = '/client/notifications/read-all';
  static const supportTickets = '/client/support-tickets';
  static const profile = '/client/profile';
  static const profilePassword = '/client/profile/password';
  static const locations = '/client/locations';
  static const paymentMethods = '/client/payment-methods';

  static String verifyPayment(int paymentId) =>
      '/client/payments/$paymentId/verify';

  static String availableDates(int consultantId) =>
      '/public/consultants/$consultantId/available-dates';

  static String slots(int consultantId) =>
      '/public/consultants/$consultantId/slots';

  static String booking(int id) => '/client/bookings/$id';

  static String cancelBooking(int id) => '/client/bookings/$id/cancel';

  static String location(int id) => '/client/locations/$id';

  static String locationDefault(int id) => '/client/locations/$id/default';

  static String paymentMethod(int id) => '/client/payment-methods/$id';

  static String paymentMethodDefault(int id) =>
      '/client/payment-methods/$id/default';

  static String reportDownload(int id) => '/client/reports/$id/download';

  static String markNotificationRead(String id) =>
      '/client/notifications/$id/read';
}
