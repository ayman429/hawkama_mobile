import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/repo/auth_repository.dart';
import '../features/booking/cubit/booking_draft_cubit.dart';
import '../features/booking/cubit/bookings_cubit.dart';
import '../features/booking/repo/booking_repository.dart';
import '../features/home/cubit/home_cubit.dart';
import '../features/home/repo/home_repository.dart';
import '../features/notifications/repo/notifications_repository.dart';
import '../features/packages/repo/packages_repository.dart';
import '../features/profile/repo/profile_repository.dart';
import '../features/reports/cubit/reports_cubit.dart';
import '../features/reports/repo/reports_repository.dart';
import '../features/shell/cubit/shell_cubit.dart';
import '../features/support/repo/support_repository.dart';
import '../l10n/strings.dart';
import 'network/api_client.dart';
import 'network/session_events.dart';
import 'theme.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  await Future.wait([
    ThemeState.init(),
    L10n.init(),
  ]);

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<SessionEvents>(SessionEvents.new);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt()));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(getIt()));
  getIt.registerLazySingleton<PackagesRepository>(() => PackagesRepository(getIt()));
  getIt.registerLazySingleton<BookingRepository>(() => BookingRepository(getIt()));
  getIt.registerLazySingleton<HomeRepository>(() => HomeRepository(getIt()));
  getIt.registerLazySingleton<ReportsRepository>(() => ReportsRepository(getIt()));
  getIt.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepository(getIt()),
  );
  getIt.registerLazySingleton<SupportRepository>(() => SupportRepository(getIt()));
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository(getIt()));
  getIt.registerLazySingleton<AuthCubit>(() => AuthCubit(getIt(), getIt()));
  getIt.registerLazySingleton<BookingDraftCubit>(() => BookingDraftCubit(getIt()));
  getIt.registerLazySingleton<ShellCubit>(ShellCubit.new);
  getIt.registerLazySingleton<HomeCubit>(
    () => HomeCubit(
      getIt<HomeRepository>(),
      getIt<PackagesRepository>(),
      getIt<NotificationsRepository>(),
      getIt<AuthCubit>(),
    ),
  );
  getIt.registerLazySingleton<BookingsCubit>(
    () => BookingsCubit(getIt<BookingRepository>(), getIt<AuthCubit>()),
  );
  getIt.registerLazySingleton<ReportsCubit>(
    () => ReportsCubit(getIt<ReportsRepository>(), getIt<AuthCubit>()),
  );

  getIt<SessionEvents>().onUnauthorized = getIt<AuthCubit>().signOut;
  await getIt<AuthCubit>().restore();
}
