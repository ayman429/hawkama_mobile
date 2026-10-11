import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils.dart';

/// Locale state — ar default (mobile.md §1), en fallback, persisted.
/// Listened to by MaterialApp in main.dart via AnimatedBuilder.
class L10n {
  L10n._();
  static final locale = ValueNotifier<Locale>(const Locale('ar'));
  static const _key = 'locale';

  static bool get isAr => locale.value.languageCode != 'en';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'en') locale.value = const Locale('en');
  }

  static Future<void> set(Locale l) async {
    locale.value = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, l.languageCode);
  }
}

/// Translate a key for the active locale.
String tr(String key, [Map<String, String>? params]) {
  var value = _t[L10n.isAr ? 'ar' : 'en']![key] ?? _t['en']![key] ?? key;
  params?.forEach((k, v) => value = value.replaceAll('{$k}', v));
  return value;
}

/// Locale-aware digits: Arab-Indic in ar (mobile.md §1), ASCII in en.
String locNum(Object n) => L10n.isAr ? arNum(n) : '$n';

const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _enWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Locale-aware "HH:MM" → ar: "٠٩:٣٠ ص" / en: "9:30 AM".
String locTime(String hhmm) {
  if (L10n.isAr) return arTime(hhmm);
  final parts = hhmm.split(':');
  var h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? parts[1] : '00';
  final suffix = h < 12 ? 'AM' : 'PM';
  if (h == 0) h = 12;
  if (h > 12) h -= 12;
  return '$h:$m $suffix';
}

/// Locale-aware "2026-10-14" → ar: "الثلاثاء ١٤ أكتوبر" / en: "Tuesday 14 October".
String locDate(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  if (L10n.isAr) return arDate(ymd);
  return '${_enWeekdays[d.weekday - 1]} ${d.day} ${_enMonths[d.month - 1]}';
}

/// Locale-aware "2026-10-14" + "09:30" combined.
String locDateTimeSlot(String ymd, String hhmm) =>
    '${locDate(ymd)} · ${locTime(hhmm)}';

const _t = <String, Map<String, String>>{
  'ar': {
    // generic
    'brand': 'المتخصصون في الحوكمة والامتثال',
    'clientPortal': 'بوابة العميل',
    'next': 'متابعة',
    'viewAll': 'عرض الكل',
    'cancel': 'إلغاء',
    'confirm': 'تأكيد',
    'yesCancel': 'نعم، إلغاء',
    'back': 'رجوع',
    // splash
    'splashTagline': 'احجز استشارتك، تابع تقاريرك، وادِر اشتراكك\nمن مكان واحد',
    'getStarted': 'ابدأ الآن',
    'continueGuest': 'متابعة كضيف',
    // onboarding
    'skip': 'تخطّي',
    'obNext': 'التالي',
    'ob1t': 'احجز موعدك بسهولة',
    'ob1p': 'اختر الخدمة والمستشار والوقت المناسب خلال أقل من دقيقة — بدون مكالمات أو انتظار.',
    'ob2t': 'تذكيرات فورية',
    'ob2p': 'إشعارات تذكّرك بمواعيدك القادمة وتصلك التقارير فور جاهزيتها.',
    'ob3t': 'مستشارون معتمدون',
    'ob3p': 'نخبة من خبراء الحوكمة والامتثال والاستشارات الإدارية لخدمة منشأتك.',
    // auth
    'loginSub': 'سجّل دخولك لإدارة استشاراتك وباقاتك',
    'tabLogin': 'تسجيل الدخول',
    'tabRegister': 'إنشاء حساب',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'passwordConfirm': 'تأكيد كلمة المرور',
    'fullName': 'الاسم الكامل',
    'phone': 'رقم الجوال',
    'company': 'اسم المنشأة',
    'forgotPassword': 'نسيت كلمة المرور؟',
    'doLogin': 'تسجيل الدخول',
    'doRegister': 'إنشاء الحساب',
    'invalidCredentials': 'بيانات الدخول غير صحيحة',
    'passwordMismatch': 'كلمتا المرور غير متطابقتين',
    // tabs
    'tabHome': 'الرئيسية',
    'tabBookings': 'مواعيدي',
    'tabReports': 'التقارير',
    'tabProfile': 'حسابي',
    // home
    'greetingM': 'صباح الخير 👋',
    'greetingE': 'مساء الخير 👋',
    'guest': 'ضيف',
    'searchHint': 'ابحث عن خدمة أو مستشار…',
    'nextBooking': 'موعدك القادم',
    'bookingDetails': 'تفاصيل الموعد',
    'remote': 'عن بُعد',
    'heroEmpty': 'لا يوجد موعد قادم',
    'heroEmptyCta': 'احجز أول استشارة',
    'quickActions': 'إجراءات سريعة',
    'newBooking': 'حجز جديد',
    'myBookings': 'مواعيدي',
    'myReports': 'تقاريري',
    'myPackages': 'باقاتي',
    'statReports': 'تقارير',
    'statUpcoming': 'مواعيد قادمة',
    'statPackage': 'الباقة الحالية',
    'noPackage': '—',
    'ourServices': 'خدماتنا',
    'bannerTitle': 'ارتقِ للباقة الذهبية',
    'bannerSub': 'مستشار مخصص + دعم 24/7',
    // bookings screen
    'pillUpcoming': 'قادمة',
    'pillPast': 'سابقة',
    'details': 'تفاصيل',
    'cancelBooking': 'إلغاء الموعد',
    'viewReport': 'عرض التقرير',
    'rebook': 'إعادة الحجز',
    'emptyUpcoming': 'لا توجد مواعيد قادمة',
    'emptyPast': 'لا توجد مواعيد سابقة',
    'bookNow': 'احجز الآن',
    'cancelTitle': 'إلغاء الموعد؟',
    'cancelBody': 'يمكنك الإلغاء مجاناً قبل ٢٤ ساعة من الموعد.',
    'cancelDone': 'تم إلغاء الموعد',
    'refundNote': 'سيتم استرداد المبلغ',
    // reports
    'reportsTitle': 'تقاريري',
    'preparing': 'قيد الإعداد',
    'emptyReports': 'لا توجد تقارير بعد',
    'download': 'تحميل',
    // packages
    'packagesTitle': 'باقات الاشتراك',
    'perMonth': 'ر.س/شهر',
    'choosePlan': 'اختر الباقة',
    'currentPlan': 'باقتك الحالية',
    'currentBadge': 'الحالية',
    'upgradePlan': 'ترقية الباقة',
    'unlimited': 'استشارات غير محدودة',
    'sessionsLeft': 'الجلسات المتبقية',
    'bookSession': 'احجز جلسة',
    'endsAt': 'ينتهي في',
    // notifications
    'notifsTitle': 'الإشعارات',
    'markAllRead': 'تحديد الكل كمقروء',
    'emptyNotifs': 'لا توجد إشعارات',
    // profile
    'personalData': 'البيانات الشخصية',
    'myAddresses': 'عناويني',
    'paymentMethods': 'طرق الدفع',
    'contactUs': 'تواصل معنا',
    'logout': 'تسجيل الخروج',
    'logoutConfirm': 'هل تريد تسجيل الخروج؟',
    'language': 'اللغة',
    'theme': 'المظهر',
    'themeSystem': 'تلقائي (حسب الجهاز)',
    'themeLight': 'فاتح',
    'themeDark': 'داكن',
    'langAr': 'العربية',
    'langEn': 'English',
    // contact
    'contactPhone': 'اتصال مباشر',
    'contactMail': 'البريد الإلكتروني',
    'contactBranch': 'الفرع الرئيسي',
    'sendMessage': 'أرسل رسالة',
    'subject': 'الموضوع',
    'subjectHint': 'موضوع الرسالة',
    'message': 'الرسالة',
    'messageHint': 'اكتب رسالتك هنا...',
    'send': 'إرسال',
    'sentOK': 'تم إرسال رسالتك',
    // wizard
    'chooseService': 'اختر الباقة',
    'chooseConsultant': 'اختر المستشار',
    'chooseSlot': 'اختر الموعد',
    'confirmBooking': 'تأكيد الحجز',
    'stepService': 'الخدمة',
    'stepConsultant': 'المستشار',
    'stepSlot': 'الموعد',
    'stepConfirm': 'التأكيد',
    'availableTimes': 'الأوقات المتاحة',
    'pickDayFirst': 'اختر يوماً أولاً',
    'noSlots': 'لا توجد مواعيد متاحة في هذا اليوم',
    'loginToContinue': 'سجّل الدخول لإتمام الحجز',
    'sumService': 'الباقة',
    'sumConsultant': 'المستشار',
    'sumDate': 'التاريخ',
    'sumTime': 'الوقت',
    'sumDuration': 'المدة',
    'sumTotal': 'الإجمالي',
    'paidBySub': 'مشمول بالاشتراك',
    'paymentNeeded': 'يتطلب الدفع',
    'benefit1': '✓ تأكيد الموعد خلال يوم عمل واحد',
    'benefit2': '✓ الجلسة حضورياً أو عن بُعد عبر Google Meet',
    'benefit3': '✓ يمكنك الإلغاء مجاناً قبل ٢٤ ساعة من الموعد',
    'confirmCta': 'تأكيد الحجز',
    'slotTaken': 'هذا الموعد لم يعد متاحاً',
    // success
    'booked': 'تم الحجز بنجاح!',
    'bookedSub': 'تم استلام طلبك وسيتم تأكيد الموعد قريباً',
    'bookingRef': 'رقم الحجز',
    'sumSlot': 'الموعد',
    'viewBookings': 'عرض مواعيدي',
    'backHome': 'العودة للرئيسية',
    // payment placeholders (Step 6 in the API guide lands here)
    'paymentTitle': 'الدفع',
    'paymentWebNote': 'يُعرض نموذج Moyasar الآمن داخل التطبيق هنا (3-D Secure).',
    'payNow': 'ادفع الآن',
    'paymentFailed': 'فشل الدفع، جرّب بطاقة أخرى',
    // errors / misc
    'serverUnreachable': 'تعذّر الاتصال بالخادم',
    'unexpected': 'حدث خطأ غير متوقع',
    'loading': 'جارٍ التحميل…',
  },
  'en': {
    'brand': 'Governance & Compliance — GCMC',
    'clientPortal': 'Client Portal',
    'next': 'Continue',
    'viewAll': 'View all',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'yesCancel': 'Yes, cancel it',
    'back': 'Back',
    'splashTagline': 'Book your consultation, track reports,\nand manage your subscription in one place',
    'getStarted': 'Get started',
    'continueGuest': 'Continue as guest',
    'skip': 'Skip',
    'obNext': 'Next',
    'ob1t': 'Book in under a minute',
    'ob1p': 'Pick the service, consultant and time that suits you — no calls, no waiting.',
    'ob2t': 'Instant reminders',
    'ob2p': 'Get notified about upcoming appointments and new reports the moment they are ready.',
    'ob3t': 'Certified consultants',
    'ob3p': 'A hand-picked panel of governance, compliance and management experts.',
    'loginSub': 'Sign in to manage your consultations and packages',
    'tabLogin': 'Sign in',
    'tabRegister': 'Create account',
    'email': 'Email',
    'password': 'Password',
    'passwordConfirm': 'Confirm password',
    'fullName': 'Full name',
    'phone': 'Mobile number',
    'company': 'Company name',
    'forgotPassword': 'Forgot password?',
    'doLogin': 'Sign in',
    'doRegister': 'Create account',
    'invalidCredentials': 'Invalid email or password',
    'passwordMismatch': 'Passwords do not match',
    'tabHome': 'Home',
    'tabBookings': 'Bookings',
    'tabReports': 'Reports',
    'tabProfile': 'Account',
    'greetingM': 'Good morning 👋',
    'greetingE': 'Good evening 👋',
    'guest': 'Guest',
    'searchHint': 'Search a service or consultant…',
    'nextBooking': 'Your next appointment',
    'bookingDetails': 'Details',
    'remote': 'Remote',
    'heroEmpty': 'No upcoming appointment',
    'heroEmptyCta': 'Book your first consultation',
    'quickActions': 'Quick actions',
    'newBooking': 'New booking',
    'myBookings': 'Bookings',
    'myReports': 'Reports',
    'myPackages': 'Packages',
    'statReports': 'Reports',
    'statUpcoming': 'Upcoming',
    'statPackage': 'Current plan',
    'noPackage': '—',
    'ourServices': 'Our services',
    'bannerTitle': 'Upgrade to the Gold plan',
    'bannerSub': 'Dedicated consultant + 24/7 support',
    'pillUpcoming': 'Upcoming',
    'pillPast': 'Past',
    'details': 'Details',
    'cancelBooking': 'Cancel booking',
    'viewReport': 'View report',
    'rebook': 'Book again',
    'emptyUpcoming': 'No upcoming bookings',
    'emptyPast': 'No past bookings',
    'bookNow': 'Book now',
    'cancelTitle': 'Cancel this booking?',
    'cancelBody': 'Cancellation is free up to 24h before the appointment.',
    'cancelDone': 'Booking cancelled',
    'refundNote': 'A refund will be issued',
    'reportsTitle': 'My reports',
    'preparing': 'In preparation',
    'emptyReports': 'No reports yet',
    'download': 'Download',
    'packagesTitle': 'Subscription plans',
    'perMonth': 'SAR/mo',
    'choosePlan': 'Choose plan',
    'currentPlan': 'Your current plan',
    'currentBadge': 'Current',
    'upgradePlan': 'Upgrade',
    'unlimited': 'Unlimited consultations',
    'sessionsLeft': 'Sessions left',
    'bookSession': 'Book a session',
    'endsAt': 'Ends on',
    'notifsTitle': 'Notifications',
    'markAllRead': 'Mark all as read',
    'emptyNotifs': 'No notifications',
    'personalData': 'Personal info',
    'myAddresses': 'My addresses',
    'paymentMethods': 'Payment methods',
    'contactUs': 'Contact us',
    'logout': 'Sign out',
    'logoutConfirm': 'Sign out of your account?',
    'language': 'Language',
    'theme': 'Appearance',
    'themeSystem': 'System default',
    'themeLight': 'Light',
    'themeDark': 'Dark',
    'langAr': 'العربية',
    'langEn': 'English',
    'contactPhone': 'Direct call',
    'contactMail': 'Email',
    'contactBranch': 'Headquarters',
    'sendMessage': 'Send a message',
    'subject': 'Subject',
    'subjectHint': 'Message subject',
    'message': 'Message',
    'messageHint': 'Write your message here…',
    'send': 'Send',
    'sentOK': 'Message sent',
    'chooseService': 'Choose a plan',
    'chooseConsultant': 'Choose a consultant',
    'chooseSlot': 'Choose date & time',
    'confirmBooking': 'Confirm booking',
    'stepService': 'Plan',
    'stepConsultant': 'Consultant',
    'stepSlot': 'Date',
    'stepConfirm': 'Confirm',
    'availableTimes': 'Available times',
    'pickDayFirst': 'pick a day first',
    'noSlots': 'No slots available on this day',
    'loginToContinue': 'Sign in to complete the booking',
    'sumService': 'Plan',
    'sumConsultant': 'Consultant',
    'sumDate': 'Date',
    'sumTime': 'Time',
    'sumDuration': 'Duration',
    'sumTotal': 'Total',
    'paidBySub': 'Covered by subscription',
    'paymentNeeded': 'Payment required',
    'benefit1': '✓ Booking confirmed within one business day',
    'benefit2': '✓ Session on-site or remote via Google Meet',
    'benefit3': '✓ Free cancellation up to 24h before',
    'confirmCta': 'Confirm booking',
    'slotTaken': 'This slot is no longer available',
    'booked': 'Booking confirmed!',
    'bookedSub': 'We received your request and will confirm it shortly',
    'bookingRef': 'Booking ref',
    'sumSlot': 'Slot',
    'viewBookings': 'View my bookings',
    'backHome': 'Back to home',
    'paymentTitle': 'Payment',
    'paymentWebNote': 'The Moyasar secure form (3-D Secure) is shown here in-app.',
    'payNow': 'Pay now',
    'paymentFailed': 'Payment failed, try another card',
    'serverUnreachable': 'Could not reach the server',
    'unexpected': 'Something went wrong',
    'loading': 'Loading…',
  },
};
