import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/splash_cubit.dart';

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
      child: Scaffold(
        backgroundColor: AppColors.greenDarker,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.greenDeep, AppColors.greenDarker],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: .35),
                      ),
                    ),
                    child: const Center(child: LogoMark(size: 58, iconSize: 32)),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('brand'),
                    textAlign: TextAlign.center,
                    style: amiri(size: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('splashTagline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.goldLight,
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const CircularProgressIndicator(
                    color: AppColors.goldLight,
                    strokeWidth: 2,
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
