import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../l10n/strings.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../booking/cubit/booking_draft_cubit.dart';
import '../../booking/cubit/bookings_cubit.dart';
import '../../booking/presentation/bookings_page.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/presentation/home_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../reports/cubit/reports_cubit.dart';
import '../../reports/presentation/reports_page.dart';
import '../cubit/shell_cubit.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    L10n.locale.addListener(_onLocale);
  }

  @override
  void dispose() {
    L10n.locale.removeListener(_onLocale);
    super.dispose();
  }

  void _onLocale() {
    if (!mounted) return;
    context.read<AuthCubit>().refreshProfile();
    context.read<HomeCubit>().load();
    context.read<BookingsCubit>().load();
    context.read<ReportsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final index = context.watch<ShellCubit>().state;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: const [
          HomePage(key: PageStorageKey('home')),
          BookingsPage(key: PageStorageKey('bookings')),
          ReportsPage(key: PageStorageKey('reports')),
          ProfilePage(key: PageStorageKey('profile')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        backgroundColor: AppColors.gold,
        shape: CircleBorder(side: BorderSide(color: c.background, width: 3)),
        onPressed: () {
          context.read<BookingDraftCubit>().reset();
          context.push(AppRoutes.bookingService);
        },
        child: const Icon(Icons.add, size: 26, color: AppColors.greenDarker),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _NotchedNavBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(Icons.home_outlined, tr('tabHome'), index == 0,
                () => context.read<ShellCubit>().select(0)),
            _NavItem(Icons.calendar_month_outlined, tr('tabBookings'),
                index == 1, () => _openAuthTab(context, 1)),
            const SizedBox(width: 56),
            _NavItem(Icons.description_outlined, tr('tabReports'), index == 2,
                () => _openAuthTab(context, 2)),
            _NavItem(Icons.person_outline, tr('tabProfile'), index == 3,
                () => context.read<ShellCubit>().select(3)),
          ],
        ),
      ),
    );
  }

  Future<void> _openAuthTab(BuildContext context, int index) async {
    if (!context.read<AuthCubit>().state.isAuthed) {
      final ok = await ensureLoggedIn(context);
      if (!ok || !context.mounted) return;
    }
    context.read<ShellCubit>().select(index);
  }
}

/// Same center notch as [BottomAppBar] + [CircularNotchedRectangle], without
/// reading [Scaffold.geometryOf] during hit tests. That read asserts in
/// current Flutter and crashes the first tap after the shell appears.
class _NotchedNavBar extends StatelessWidget {
  final Widget child;
  const _NotchedNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PhysicalShape(
      clipper: const _CenterNotchClipper(),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      color: context.col.surface,
      shadowColor: const Color(0x33000000),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(height: 56, child: child),
      ),
    );
  }
}

class _CenterNotchClipper extends CustomClipper<Path> {
  const _CenterNotchClipper();

  @override
  Path getClip(Size size) {
    const fabRadius = 28.0;
    const margin = 7.0;
    return const CircularNotchedRectangle().getOuterPath(
      Offset.zero & size,
      Rect.fromCircle(
        center: Offset(size.width / 2, 0),
        radius: fabRadius + margin,
      ),
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final color = active ? AppColors.greenDeep : c.stone;
    final shown = context.isDark && active ? AppColors.goldLight : color;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: shown),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: shown,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
