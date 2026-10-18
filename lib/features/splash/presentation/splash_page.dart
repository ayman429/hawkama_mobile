import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../l10n/strings.dart';
import '../cubit/splash_cubit.dart';

/// Light: cool off-white with a mint wash. Dark: graphite with a faint mint glow.
/// Backgrounds match the native launch screens so there is no flash between them.
class _SplashPalette {
  final Color bg;
  final Color glow;
  final Color glowSoft;
  final double glowAlpha;
  final Color tile;
  final Color tileBorder;
  final Color tileShadow;
  final Color icon;
  final Color brand;
  final Color tagline;

  const _SplashPalette({
    required this.bg,
    required this.glow,
    required this.glowSoft,
    required this.glowAlpha,
    required this.tile,
    required this.tileBorder,
    required this.tileShadow,
    required this.icon,
    required this.brand,
    required this.tagline,
  });

  static const light = _SplashPalette(
    bg: Color(0xFFF4F8F6),
    glow: Color(0xFFD7EBE3),
    glowSoft: Color(0xFFE8F4EF),
    glowAlpha: 1,
    tile: Colors.white,
    tileBorder: Colors.transparent,
    tileShadow: Color(0x140E3B2E),
    icon: AppColors.greenMid,
    brand: AppColors.greenDeep,
    tagline: Color(0xFF5E726A),
  );

  static const dark = _SplashPalette(
    bg: Color(0xFF0B0F0E),
    glow: Color(0xFF1E5A46),
    glowSoft: Color(0xFF173B31),
    glowAlpha: .35,
    tile: Color(0xFF161B1A),
    tileBorder: Color(0x17FFFFFF),
    tileShadow: Color(0x73000000),
    icon: Color(0xFF5CC59C),
    brand: Color(0xFFF2F4F3),
    tagline: Color(0xFF9AA5A1),
  );
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final p = dark ? _SplashPalette.dark : _SplashPalette.light;
    final overlay = dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return BlocListener<SplashCubit, SplashDestination>(
      listenWhen: (_, next) => next != SplashDestination.pending,
      listener: (context, destination) {
        context.go(
          destination == SplashDestination.home
              ? AppRoutes.home
              : AppRoutes.onboarding,
        );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: p.bg,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: p.bg,
          body: _SplashBody(p),
        ),
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  final _SplashPalette p;
  const _SplashBody(this.p);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -50,
          child: _Glow(size: 240, color: p.glow.withValues(alpha: p.glowAlpha)),
        ),
        Positioned(
          bottom: -110,
          left: -70,
          child: _Glow(
            size: 280,
            color: p.glowSoft.withValues(alpha: p.glowAlpha),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: p.tile,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: p.tileBorder),
                      boxShadow: [
                        BoxShadow(
                          color: p.tileShadow,
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      size: 40,
                      color: p.icon,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    tr('brand'),
                    textAlign: TextAlign.center,
                    style: amiri(size: 22, color: p.brand),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('splashTagline'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: p.tagline,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: p.icon,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
