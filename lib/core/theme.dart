import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted light / dark / system preference (mobile.md §1, README).
class ThemeState {
  ThemeState._();

  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
  static const _key = 'theme_mode';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = switch (prefs.getString(_key)) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}

/// Brand colors from mobile.md §1, plus semantic surfaces that flip in dark mode.
class AppColors extends ThemeExtension<AppColors> {
  static const greenDeep = Color(0xFF0E3B2E);
  static const greenMid = Color(0xFF16543F);
  static const greenDarker = Color(0xFF0A2A21);
  static const gold = Color(0xFFC9A24B);
  static const goldLight = Color(0xFFE6C87A);

  final Color background;
  final Color surface;
  final Color text;
  final Color stone;
  final Color line;
  final Color goldSoft;
  final Color goldLine;
  final Color goldText;
  final Color danger;
  final Color dangerBg;
  final Color dangerLine;
  final Color doneBg;
  final Color doneText;
  final Color chipBg;
  final Color pickOn;
  final Color bannerFrom;
  final Color bannerLine;
  final Color mutedCal;

  /// Content card fill (first elevation step above the page).
  final Color card;

  /// Card rim; in dark mode this hairline is what separates layers, not the shadow.
  final Color hairline;

  /// Foreground brand color for icons, links and active states.
  final Color accent;

  /// Brand ink for headings/indicators that are deep green on light.
  final Color ink;

  /// Tinted tile behind accent icons.
  final Color accentSoft;

  /// Filled primary button.
  final Color primaryFill;

  /// Branded hero surfaces (next booking, profile header).
  final Color heroFrom;
  final Color heroTo;

  const AppColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.stone,
    required this.line,
    required this.goldSoft,
    required this.goldLine,
    required this.goldText,
    required this.danger,
    required this.dangerBg,
    required this.dangerLine,
    required this.doneBg,
    required this.doneText,
    required this.chipBg,
    required this.pickOn,
    required this.bannerFrom,
    required this.bannerLine,
    required this.mutedCal,
    required this.card,
    required this.hairline,
    required this.accent,
    required this.ink,
    required this.accentSoft,
    required this.primaryFill,
    required this.heroFrom,
    required this.heroTo,
  });

  static const light = AppColors(
    background: Color(0xFFF6F2EA),
    surface: Color(0xFFFFFFFF),
    text: greenDeep,
    stone: Color(0xFF7A7468),
    line: Color(0xFFE6E0D4),
    goldSoft: Color(0xFFF7ECD2),
    goldLine: Color(0xFFECD9A8),
    goldText: Color(0xFF8A6A1F),
    danger: Color(0xFFB3402F),
    dangerBg: Color(0xFFF8E9E6),
    dangerLine: Color(0xFFEFD2CC),
    doneBg: Color(0xFFE7F2EC),
    doneText: Color(0xFF1C6B4A),
    chipBg: Color(0xFFF6F2EA),
    pickOn: Color(0xFFFFFDF6),
    bannerFrom: Color(0xFFF0E3C2),
    bannerLine: Color(0xFFE7D29A),
    mutedCal: Color(0xFFBBB2A2),
    card: Color(0xF7FFFFFF),
    hairline: Color(0xEBFFFFFF),
    accent: greenMid,
    ink: greenDeep,
    accentSoft: Color(0xFFE7F4EE),
    primaryFill: greenDeep,
    heroFrom: greenDeep,
    heroTo: greenMid,
  );

  /// Graphite layers with a faint green cast; brand green becomes a light mint
  /// accent so it reads on dark, and elevation comes from lighter surfaces.
  static const dark = AppColors(
    background: Color(0xFF0B0F0E),
    surface: Color(0xFF1E2422),
    text: Color(0xFFF2F4F3),
    stone: Color(0xFF9AA5A1),
    line: Color(0xFF2C3532),
    goldSoft: Color(0xFF2E2717),
    goldLine: Color(0xFF5E4B22),
    goldText: Color(0xFFE2C27A),
    danger: Color(0xFFFF7A6B),
    dangerBg: Color(0xFF341C19),
    dangerLine: Color(0xFF5E2E28),
    doneBg: Color(0xFF14302A),
    doneText: Color(0xFF6FD3A8),
    chipBg: Color(0xFF232B29),
    pickOn: Color(0xFF1F2B27),
    bannerFrom: Color(0xFF2C2618),
    bannerLine: Color(0xFF5A4A28),
    mutedCal: Color(0xFF5C6663),
    card: Color(0xFF161B1A),
    hairline: Color(0x17FFFFFF),
    accent: Color(0xFF5CC59C),
    ink: Color(0xFF5CC59C),
    accentSoft: Color(0x245CC59C),
    primaryFill: Color(0xFF1F7A5C),
    heroFrom: Color(0xFF1C5E48),
    heroTo: Color(0xFF103C2F),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? stone,
    Color? line,
    Color? goldSoft,
    Color? goldLine,
    Color? goldText,
    Color? danger,
    Color? dangerBg,
    Color? dangerLine,
    Color? doneBg,
    Color? doneText,
    Color? chipBg,
    Color? pickOn,
    Color? bannerFrom,
    Color? bannerLine,
    Color? mutedCal,
    Color? card,
    Color? hairline,
    Color? accent,
    Color? ink,
    Color? accentSoft,
    Color? primaryFill,
    Color? heroFrom,
    Color? heroTo,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      stone: stone ?? this.stone,
      line: line ?? this.line,
      goldSoft: goldSoft ?? this.goldSoft,
      goldLine: goldLine ?? this.goldLine,
      goldText: goldText ?? this.goldText,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerLine: dangerLine ?? this.dangerLine,
      doneBg: doneBg ?? this.doneBg,
      doneText: doneText ?? this.doneText,
      chipBg: chipBg ?? this.chipBg,
      pickOn: pickOn ?? this.pickOn,
      bannerFrom: bannerFrom ?? this.bannerFrom,
      bannerLine: bannerLine ?? this.bannerLine,
      mutedCal: mutedCal ?? this.mutedCal,
      card: card ?? this.card,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      ink: ink ?? this.ink,
      accentSoft: accentSoft ?? this.accentSoft,
      primaryFill: primaryFill ?? this.primaryFill,
      heroFrom: heroFrom ?? this.heroFrom,
      heroTo: heroTo ?? this.heroTo,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      text: mix(text, other.text),
      stone: mix(stone, other.stone),
      line: mix(line, other.line),
      goldSoft: mix(goldSoft, other.goldSoft),
      goldLine: mix(goldLine, other.goldLine),
      goldText: mix(goldText, other.goldText),
      danger: mix(danger, other.danger),
      dangerBg: mix(dangerBg, other.dangerBg),
      dangerLine: mix(dangerLine, other.dangerLine),
      doneBg: mix(doneBg, other.doneBg),
      doneText: mix(doneText, other.doneText),
      chipBg: mix(chipBg, other.chipBg),
      pickOn: mix(pickOn, other.pickOn),
      bannerFrom: mix(bannerFrom, other.bannerFrom),
      bannerLine: mix(bannerLine, other.bannerLine),
      mutedCal: mix(mutedCal, other.mutedCal),
      card: mix(card, other.card),
      hairline: mix(hairline, other.hairline),
      accent: mix(accent, other.accent),
      ink: mix(ink, other.ink),
      accentSoft: mix(accentSoft, other.accentSoft),
      primaryFill: mix(primaryFill, other.primaryFill),
      heroFrom: mix(heroFrom, other.heroFrom),
      heroTo: mix(heroTo, other.heroTo),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get col => Theme.of(this).extension<AppColors>() ?? AppColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Headings use Amiri (mobile.md §1).
TextStyle amiri({
  double size = 16,
  Color? color,
  FontWeight weight = FontWeight.w700,
}) {
  return GoogleFonts.amiri(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.4,
  );
}

ThemeData buildAppTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    dividerColor: colors.line,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.ink,
      onPrimary: brightness == Brightness.dark ? colors.background : Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.greenDarker,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
    ),
    dialogTheme: DialogThemeData(backgroundColor: colors.surface),
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    ),
  );
}
