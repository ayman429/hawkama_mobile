import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/booking/cubit/booking_draft_cubit.dart';
import '../features/booking/cubit/bookings_cubit.dart';
import '../features/booking/cubit/wizard_cubits.dart';
import '../features/booking/models/booking.dart';
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

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => BlocProvider(
        create: (_) => SplashCubit(getIt<SharedPreferences>(), getIt<AuthCubit>()),
        child: const SplashPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => BlocProvider(
        create: (_) => OnboardingCubit(getIt<SharedPreferences>()),
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => MultiBlocProvider(
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
