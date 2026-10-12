import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/booking/cubit/booking_draft_cubit.dart';
import 'features/shell/cubit/shell_cubit.dart';
import 'l10n/strings.dart';

class HawkamaApp extends StatelessWidget {
  const HawkamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<BookingDraftCubit>()),
        BlocProvider.value(value: getIt<ShellCubit>()),
      ],
      child: AnimatedBuilder(
        animation: Listenable.merge([ThemeState.mode, L10n.locale]),
        builder: (context, _) {
          final isAr = L10n.isAr;
          return MaterialApp.router(
            title: tr('clientPortal'),
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: ThemeState.mode.value,
            locale: L10n.locale.value,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: appRouter,
            builder: (context, child) => Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
