import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../l10n/strings.dart';
import '../cubit/splash_cubit.dart';

/// Cool off-white with a mint wash — light, contemporary, not heritage gold.
const _splashBg = Color(0xFFF4F8F6);
const _splashMint = Color(0xFFD7EBE3);
const _splashMintSoft = Color(0xFFE8F4EF);

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: _splashBg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: const Scaffold(
          backgroundColor: _splashBg,
          body: _SplashBody(),
        ),
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: -90,
          right: -50,
          child: _Glow(size: 240, color: _splashMint),
        ),
        const Positioned(
          bottom: -110,
          left: -70,
          child: _Glow(size: 280, color: _splashMintSoft),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greenDeep.withValues(alpha: .08),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 40,
                      color: AppColors.greenMid,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    tr('brand'),
                    textAlign: TextAlign.center,
                    style: amiri(size: 22, color: AppColors.greenDeep),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('splashTagline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5E726A),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.greenMid,
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
