import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/splash_cubit.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _icons = [
    Icons.calendar_month_outlined,
    Icons.notifications_outlined,
    Icons.verified_user_outlined,
  ];
  static const _titleKeys = ['ob1t', 'ob2t', 'ob3t'];
  static const _bodyKeys = ['ob1p', 'ob2p', 'ob3p'];

  Future<void> _finish(BuildContext context) async {
    await context.read<OnboardingCubit>().markSeen();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<OnboardingCubit>().state;
    final c = context.col;
    final last = index == 2;
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _finish(context),
                child: Text(
                  tr('skip'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.stone,
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.card,
                    border: Border.all(color: context.isDark ? c.hairline : c.line),
                    boxShadow: [
                      BoxShadow(
                        color: context.isDark
                            ? Colors.black.withValues(alpha: .4)
                            : AppColors.greenDeep.withValues(alpha: .06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(_icons[index], size: 56, color: c.accent),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr(_titleKeys[index]),
                textAlign: TextAlign.center,
                style: amiri(size: 16, color: c.text),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  tr(_bodyKeys[index]),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: c.stone, height: 1.9),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: i == index ? AppColors.gold : c.line,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                last ? tr('getStarted') : tr('obNext'),
                onTap: () {
                  if (last) {
                    _finish(context);
                  } else {
                    context.read<OnboardingCubit>().next();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
