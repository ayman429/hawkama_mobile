/// Arabic display helpers — mobile.md §1/§6.
///
/// API values always arrive as ASCII (ISO dates, halalas, "HH:MM"); everything
/// shown to the user goes through these converters (Arab-Indic digits,
/// Arabic months/weekdays, Asia/Riyadh semantics).

const kArMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

/// DateTime.weekday 1=Mon … 7=Sun.
const kArWeekdays = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
];

/// Calendar header row, Sunday-first per mobile.md §3 (.cal).
const kArWeekHeader = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

String arNum(Object n) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return n.toString().split('').map((c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57 ? digits[code - 48] : c;
  }).join();
}

/// "09:30" → "٠٩:٣٠ ص", "14:30" → "٠٢:٣٠ م".
String arTime(String hhmm) {
  final parts = hhmm.split(':');
  var h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? parts[1] : '00';
  final suffix = h < 12 ? 'ص' : 'م';
  if (h == 0) h = 12;
  if (h > 12) h -= 12;
  return '${arNum(h.toString().padLeft(2, '0'))}:${arNum(m)} $suffix';
}

/// "2026-10-14" → "الثلاثاء ١٤ أكتوبر".
String arDate(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  return arDateTime(d);
}

String arDateTime(DateTime d) {
  return '${kArWeekdays[d.weekday - 1]} ${arNum(d.day)} ${kArMonths[d.month - 1]}';
}

/// "2026-10-14" + "09:30" → "الثلاثاء ١٤ أكتوبر · ٠٩:٣٠ ص".
String arDateTimeSlot(String ymd, String hhmm) =>
    '${arDate(ymd)} · ${arTime(hhmm)}';

/// YYYY-MM used by PUB-05 available-dates.
String ymOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

String ymdOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// First character for the avatar initial.
String initialOf(String? name) =>
    (name == null || name.trim().isEmpty) ? '؟' : name.trim()[0];
