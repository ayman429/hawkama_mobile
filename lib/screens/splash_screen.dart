import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  /// Signed-in users go home. Guests see onboarding once, then home as guest.
  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final auth = AuthStore.instance;
    if (auth.isAuthed && auth.user != null) {
      _go(const MainShell());
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    _go(seen ? const MainShell() : const OnboardingScreen());
  }

  void _go(Widget screen) => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: .35)),
                  ),
                  child: const Center(child: LogoMark(size: 58, iconSize: 32)),
                ),
                const SizedBox(height: 18),
                Text(tr('brand'),
                    textAlign: TextAlign.center,
                    style: amiri(size: 20, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  tr('splashTagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.goldLight, height: 1.9),
                ),
                const SizedBox(height: 26),
                const CircularProgressIndicator(
                    color: AppColors.goldLight, strokeWidth: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
