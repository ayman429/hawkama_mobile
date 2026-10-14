import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/cubit/home_cubit.dart';

enum SplashDestination { pending, onboarding, home }

class SplashCubit extends Cubit<SplashDestination> {
  SplashCubit(this._prefs, this._auth) : super(SplashDestination.pending) {
    _decide();
  }

  final SharedPreferences _prefs;
  final AuthCubit _auth;

  Future<void> _decide() async {
    // Home data starts while the splash is on screen, so the first frame
    // of home is already filled instead of waiting on skeletons.
    getIt<HomeCubit>();
    await Future.delayed(const Duration(milliseconds: 4200));
    if (isClosed) return;
    final auth = _auth.state;
    if (auth.isAuthed && auth.user != null) {
      emit(SplashDestination.home);
      return;
    }
    final seen = _prefs.getBool('onboarding_seen') ?? false;
    emit(seen ? SplashDestination.home : SplashDestination.onboarding);
  }
}

class OnboardingCubit extends Cubit<int> {
  OnboardingCubit(this._prefs) : super(0);

  final SharedPreferences _prefs;

  void next() {
    if (state < 2) emit(state + 1);
  }

  Future<void> markSeen() => _prefs.setBool('onboarding_seen', true);
}
