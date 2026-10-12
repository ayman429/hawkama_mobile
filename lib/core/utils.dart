// Date and number helpers. Locale words live in lib/l10n/strings.dart.
// API values arrive as ASCII (ISO dates, "HH:MM"); Arabic digits are applied
// only when the active locale is Arabic.

String arNum(Object n) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return n.toString().split('').map((c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57 ? digits[code - 48] : c;
  }).join();
}

/// YYYY-MM used by available-dates.
String ymOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

String ymdOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
