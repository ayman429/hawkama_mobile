import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  static const _icons = [
    Icons.calendar_month_outlined,
    Icons.notifications_outlined,
    Icons.verified_user_outlined,
  ];
  static const _titleKeys = ['ob1t', 'ob2t', 'ob3t'];
  static const _bodyKeys = ['ob1p', 'ob2p', 'ob3p'];

  Future<void> _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _next() {
    if (_index >= 2) {
      _goToLogin();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final last = _index == 2;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _goToLogin,
                child: Text(tr('skip'),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.stone)),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surface,
                    border: Border.all(color: c.line),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenDeep.withValues(alpha: .06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(_icons[_index],
                      size: 56, color: AppColors.greenMid),
                ),
              ),
              const SizedBox(height: 18),
              Text(tr(_titleKeys[_index]),
                  textAlign: TextAlign.center,
                  style: amiri(size: 16, color: c.text)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(tr(_bodyKeys[_index]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10.5, color: c.stone, height: 1.9)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: i == _index ? AppColors.gold : c.line,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(last ? tr('getStarted') : tr('obNext'), onTap: _next),
            ],
          ),
        ),
      ),
    );
  }
}
