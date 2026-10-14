import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Calm wash behind every screen, varied enough for the glass bar to refract.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF071410), Color(0xFF0C221C), Color(0xFF081814)]
                : const [Color(0xFFF8F7F4), Color(0xFFEEF5F1), Color(0xFFF7F8F6)],
          ),
        ),
        child: const Stack(
          children: [
            Positioned(top: -150, right: -90, child: _Wash(360, false, true)),
            Positioned(top: 180, left: -130, child: _Wash(280, false, false)),
            Positioned(bottom: -120, right: -50, child: _Wash(320, true, false)),
          ],
        ),
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  final double size;
  final bool low;
  final bool top;
  const _Wash(this.size, this.low, this.top);

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final color = dark
        ? (top ? const Color(0xFF1A4538) : const Color(0xFF123028))
        : (top ? const Color(0xFFD3E9DF) : const Color(0xFFE5F1EB));
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: low ? .55 : .9),
        ),
      ),
    );
  }
}

/// Page shell that paints [AppBackdrop] so pushed routes stay opaque.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool extendBody;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    required this.body,
    this.extendBody = false,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF071410) : const Color(0xFFF8F7F4),
      extendBody: extendBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackdrop()),
          body,
        ],
      ),
    );
  }
}
