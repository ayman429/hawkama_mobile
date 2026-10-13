import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/booking/cubit/booking_detail_cubit.dart';
import '../features/booking/cubit/booking_draft_cubit.dart';
import '../features/booking/cubit/bookings_cubit.dart';
import '../features/booking/cubit/wizard_cubits.dart';
import '../features/booking/models/booking.dart';
import '../features/booking/presentation/booking_detail_page.dart';
import '../features/booking/presentation/confirm_page.dart';
import '../features/booking/presentation/consultant_pick_page.dart';
import '../features/booking/presentation/schedule_page.dart';
import '../features/booking/presentation/service_pick_page.dart';
import '../features/booking/presentation/success_page.dart';
import '../features/booking/repo/booking_repository.dart';
import '../features/home/cubit/home_cubit.dart';
import '../features/notifications/cubit/notifications_cubit.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/notifications/repo/notifications_repository.dart';
import '../features/packages/cubit/packages_cubit.dart';
import '../features/packages/presentation/packages_page.dart';
import '../features/packages/repo/packages_repository.dart';
import '../features/profile/cubit/addresses_cubit.dart';
import '../features/profile/cubit/payment_methods_cubit.dart';
import '../features/profile/cubit/personal_data_cubit.dart';
import '../features/profile/presentation/addresses_page.dart';
import '../features/profile/presentation/payment_methods_page.dart';
import '../features/profile/presentation/personal_data_page.dart';
import '../features/profile/repo/profile_repository.dart';
import '../features/reports/cubit/reports_cubit.dart';
import '../features/reports/repo/reports_repository.dart';
import '../features/home/repo/home_repository.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/splash/cubit/splash_cubit.dart';
import '../features/splash/presentation/onboarding_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/support/cubit/support_cubit.dart';
import '../features/support/presentation/contact_page.dart';
import '../features/support/repo/support_repository.dart';
import 'di.dart';
import 'routes.dart';

Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (_, state) => _fadePage(
        state,
        BlocProvider(
          create: (_) => SplashCubit(getIt<SharedPreferences>(), getIt<AuthCubit>()),
          child: const SplashPage(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (_, state) => _fadePage(
        state,
        BlocProvider(
          create: (_) => OnboardingCubit(getIt<SharedPreferences>()),
          child: const OnboardingPage(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (_, state) => _fadePage(
        state,
        MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => HomeCubit(
              getIt<HomeRepository>(),
              getIt<PackagesRepository>(),
              getIt<NotificationsRepository>(),
              getIt<AuthCubit>(),
            ),
          ),
          BlocProvider(
            create: (_) => BookingsCubit(
              getIt<BookingRepository>(),
              getIt<AuthCubit>(),
            ),
          ),
          BlocProvider(
            create: (_) => ReportsCubit(
              getIt<ReportsRepository>(),
              getIt<AuthCubit>(),
            ),
          ),
        ],
        child: const MainShell(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.packages,
      builder: (_, __) => BlocProvider(
        create: (_) => PackagesCubit(getIt<PackagesRepository>(), getIt<AuthCubit>()),
        child: const PackagesPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, __) => BlocProvider(
        create: (_) => NotificationsCubit(
          getIt<NotificationsRepository>(),
          getIt<AuthCubit>(),
        ),
        child: const NotificationsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.contact,
      builder: (_, __) => BlocProvider(
        create: (_) => SupportCubit(getIt<SupportRepository>()),
        child: const ContactPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingService,
      builder: (_, __) => BlocProvider(
        create: (_) => WizardPackagesCubit(getIt<PackagesRepository>()),
        child: const ServicePickPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingConsultant,
      builder: (_, __) => BlocProvider(
        create: (_) => ConsultantsCubit(getIt<BookingRepository>()),
        child: const ConsultantPickPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingSchedule,
      builder: (_, __) => BlocProvider(
        create: (_) {
          final cubit = ScheduleCubit(getIt<BookingRepository>());
          final consultantId = getIt<BookingDraftCubit>().state.consultant?.id;
          if (consultantId != null) cubit.loadMonth(consultantId);
          return cubit;
        },
        child: const SchedulePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingConfirm,
      builder: (_, __) => const ConfirmPage(),
    ),
    GoRoute(
      path: AppRoutes.bookingDetail,
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return BlocProvider(
          create: (_) => BookingDetailCubit(getIt<BookingRepository>())..load(id),
          child: BookingDetailPage(bookingId: id),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.personalData,
      builder: (_, __) => BlocProvider(
        create: (_) => PersonalDataCubit(getIt<ProfileRepository>(), getIt<AuthCubit>()),
        child: const PersonalDataPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.addresses,
      builder: (_, __) => BlocProvider(
        create: (_) => AddressesCubit(getIt<ProfileRepository>())..load(),
        child: const AddressesPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.paymentMethods,
      builder: (_, __) => BlocProvider(
        create: (_) => PaymentMethodsCubit(getIt<ProfileRepository>())..load(),
        child: const PaymentMethodsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingSuccess,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is! Booking) return const Scaffold(body: SizedBox.shrink());
        final draft = getIt<BookingDraftCubit>().state;
        return SuccessPage(
          booking: extra,
          serviceName: draft.package?.name ?? extra.package?.name ?? '—',
          consultantName: draft.consultant?.name ?? extra.consultant?.name ?? '—',
        );
      },
    ),
  ],
);
