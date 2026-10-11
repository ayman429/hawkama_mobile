import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/repo.dart';

/// Booking-wizard state (mobile.md §4.4 / API guide §5.2).
/// Kept across the wizard's pushed screens; the FAB / "new booking" always
/// call [reset] first.
class BookingStore extends ChangeNotifier {
  BookingStore._();
  static final BookingStore instance = BookingStore._();

  ConsultPackage? package;
  Consultant? consultant;
  String? date; // YYYY-MM-DD
  Slot? slot;
  bool _guestAutoLoginNoticeShown = false;

  bool get readyForConfirm => package != null && consultant != null &&
      date != null && slot != null;

  Quote? quote;
  bool quoting = false;

  void reset() {
    package = null;
    consultant = null;
    date = null;
    slot = null;
    quote = null;
    quoting = false;
    _guestAutoLoginNoticeShown = false;
    notifyListeners();
  }

  void pickPackage(ConsultPackage p) {
    package = p;
    quote = null;
    notifyListeners();
    refreshQuote();
  }

  void pickConsultant(Consultant c) {
    consultant = c;
    date = null;
    slot = null;
    quote = null;
    notifyListeners();
    refreshQuote();
  }

  void pickDate(String d) {
    date = d;
    slot = null;
    quote = null;
    notifyListeners();
    refreshQuote();
  }

  void pickSlot(Slot s) {
    slot = s;
    notifyListeners();
    refreshQuote();
  }

  bool consumeGuestNotice() {
    if (_guestAutoLoginNoticeShown) return false;
    _guestAutoLoginNoticeShown = true;
    return true;
  }

  /// §5.6 — refresh whenever package/date/time change. Silently skipped for
  /// guests (quote needs a token); the confirm step totals then show the
  /// package price as an estimate.
  Future<void> refreshQuote() async {
    final p = package;
    if (p == null) return;
    final c = consultant, d = date;
    final t = slot?.time;
    quoting = true;
    notifyListeners();
    try {
      quote = await Repo.quote(
          packageId: p.id, consultantId: c?.id, date: d, time: t);
    } catch (_) {
      quote = null; // leave null → confirm screen shows package price
    } finally {
      quoting = false;
      notifyListeners();
    }
  }

  Future<BookingCreateResult> submit({int? paymentMethodId,
      String? cardToken,
      String? notes}) {
    final p = package!, c = consultant!, d = date!, t = slot!;
    return Repo.createBooking(
      packageId: p.id,
      consultantId: c.id,
      date: d,
      time: t.time,
      paymentMethodId: paymentMethodId,
      cardToken: cardToken,
      notes: notes,
    );
  }
}
