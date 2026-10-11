import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hawkama_client/core/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light theme uses the cream background from mobile.md', () {
    GoogleFonts.config.allowRuntimeFetching = false;
    final theme = buildAppTheme(Brightness.light);
    final colors = theme.extension<AppColors>()!;
    expect(colors.background, const Color(0xFFF6F2EA));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F2EA));
  });
}
