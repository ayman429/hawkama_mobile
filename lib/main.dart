import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'l10n/strings.dart';
import 'screens/splash_screen.dart';
import 'state/auth_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ThemeState.init(),
    L10n.init(),
    AuthStore.instance.init(),
  ]);
  runApp(const HawkamaApp());
}

class HawkamaApp extends StatelessWidget {
  const HawkamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeState.mode, L10n.locale]),
      builder: (context, _) {
        final isAr = L10n.isAr;
        return MaterialApp(
          key: ValueKey('${L10n.locale.value}-${ThemeState.mode.value}'),
          title: 'بوابة العميل',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: ThemeState.mode.value,
          locale: L10n.locale.value,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
