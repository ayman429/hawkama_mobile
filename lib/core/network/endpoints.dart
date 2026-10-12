class Endpoints {
  static const login = '/client/auth/login';
  static const register = '/client/auth/register';
  static const me = '/client/auth/me';
  static const logout = '/client/auth/logout';
  static const packages = '/public/packages';
  static const consultants = '/public/consultants';
  static const quote = '/client/bookings/quote';
  static const bookings = '/client/bookings';
  static const dashboard = '/client/dashboard';
  static const reports = '/client/reports';
  static const activeSubscriptions = '/client/subscriptions/active';
  static const notifications = '/client/notifications';
  static const unreadCount = '/client/notifications/unread-count';
  static const markAllRead = '/client/notifications/read-all';
  static const supportTickets = '/client/support-tickets';

  static String availableDates(int consultantId) =>
      '/public/consultants/$consultantId/available-dates';

  static String slots(int consultantId) =>
      '/public/consultants/$consultantId/slots';

  static String cancelBooking(int id) => '/client/bookings/$id/cancel';

  static String reportDownload(int id) => '/client/reports/$id/download';

  static String markNotificationRead(String id) =>
      '/client/notifications/$id/read';
}
