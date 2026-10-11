import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted light / dark / system preference (mobile.md §1, README).
class ThemeState {
  ThemeState._();

  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static const _key = 'theme_mode';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mode.value = switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
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
  );

  /// Dark surfaces keep the same brand greens and gold; only chrome flips.
  static const dark = AppColors(
    background: Color(0xFF071C17),
    surface: Color(0xFF102E26),
    text: Color(0xFFF6F2EA),
    stone: Color(0xFFB7B0A4),
    line: Color(0xFF2A4A3E),
    goldSoft: Color(0xFF3A3018),
    goldLine: Color(0xFF6B5424),
    goldText: goldLight,
    danger: Color(0xFFE07A6A),
    dangerBg: Color(0xFF3A221C),
    dangerLine: Color(0xFF6B3A32),
    doneBg: Color(0xFF16382C),
    doneText: Color(0xFF7DCAA8),
    chipBg: Color(0xFF1A3D32),
    pickOn: Color(0xFF1C3328),
    bannerFrom: Color(0xFF3D3420),
    bannerLine: Color(0xFF6B5A32),
    mutedCal: Color(0xFF6E675C),
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
      primary: AppColors.greenDeep,
      onPrimary: Colors.white,
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
