import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
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
  /// Tabs other than home are built the first time they are opened.
  final Set<int> _built = {0};

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
    final index = context.watch<ShellCubit>().state;
    _built.add(index);
    return AppScaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: [
          const HomePage(key: PageStorageKey('home')),
          _built.contains(1)
              ? const BookingsPage(key: PageStorageKey('bookings'))
              : const SizedBox.shrink(),
          _built.contains(2)
              ? const ReportsPage(key: PageStorageKey('reports'))
              : const SizedBox.shrink(),
          _built.contains(3)
              ? const ProfilePage(key: PageStorageKey('profile'))
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _GlassNavBar(
        onBook: () {
          context.read<BookingDraftCubit>().reset();
          context.push(AppRoutes.bookingService);
        },
        items: [
          _NavSpec(Icons.home_outlined, Icons.home_rounded, tr('tabHome'),
              index == 0, () => _openTab(context, 0)),
          _NavSpec(
              Icons.calendar_month_outlined,
              Icons.calendar_month_rounded,
              tr('tabBookings'),
              index == 1,
              () => _openTab(context, 1)),
          _NavSpec(
              Icons.description_outlined,
              Icons.description_rounded,
              tr('tabReports'),
              index == 2,
              () => _openTab(context, 2)),
          _NavSpec(Icons.person_outline, Icons.person_rounded, tr('tabProfile'),
              index == 3, () => _openTab(context, 3)),
        ],
      ),
    );
  }

  Future<void> _openTab(BuildContext context, int index) async {
    if (index == 1 || index == 2) {
      if (!context.read<AuthCubit>().state.isAuthed) {
        final ok = await ensureLoggedIn(context);
        if (!ok || !context.mounted) return;
      }
    }
    if (!context.mounted) return;
    context.read<ShellCubit>().select(index);
    switch (index) {
      case 0:
        context.read<HomeCubit>().load();
      case 1:
        context.read<BookingsCubit>().load();
      case 2:
        context.read<ReportsCubit>().load();
      case 3:
        context.read<AuthCubit>().refreshProfile();
    }
  }
}

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavSpec(this.icon, this.activeIcon, this.label, this.active, this.onTap);
}

/// Floating liquid-glass capsule. A second lens stretches and travels between
/// tabs, the way the iOS selection bubble settles.
class _GlassNavBar extends StatefulWidget {
  static const _barHeight = 62.0;
  static const _buttonSize = 54.0;
  static const _lift = 22.0;

  final List<_NavSpec> items;
  final VoidCallback onBook;

  const _GlassNavBar({required this.items, required this.onBook});

  @override
  State<_GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<_GlassNavBar>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 26,
  );

  late final AnimationController _move;
  int _from = 0;
  int _to = 0;

  int get _selected {
    final index = widget.items.indexWhere((item) => item.active);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _from = _to = _selected;
    _move = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(covariant _GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _selected;
    if (next == _to) return;
    _from = _to;
    _to = next;
    _move.value = 0;
    _move.animateWith(SpringSimulation(_spring, 0, 1, 0));
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  double _center(int index, double width, bool rtl) {
    final slot = (width - _GlassNavBar._buttonSize) / 4;
    final fromStart = switch (index) {
      0 => slot * 0.5,
      1 => slot * 1.5,
      2 => slot * 2 + _GlassNavBar._buttonSize + slot * 0.5,
      _ => slot * 2 + _GlassNavBar._buttonSize + slot * 1.5,
    };
    return rtl ? width - fromStart : fromStart;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = context.isDark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final slot = (width - _GlassNavBar._buttonSize) / 4;
          return SizedBox(
            height: _GlassNavBar._barHeight + _GlassNavBar._lift,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _GlassNavBar._barHeight,
                  child: LiquidGlass.withOwnLayer(
                    settings: LiquidGlassSettings(
                      thickness: 22,
                      blur: 6,
                      refractiveIndex: 1.18,
                      lightIntensity: 1.25,
                      ambientStrength: 0.4,
                      chromaticAberration: 0.03,
                      saturation: 1.45,
                      lightAngle: -math.pi / 2,
                      glassColor: dark
                          ? const Color(0x33101412)
                          : const Color(0x2EFFFFFF),
                    ),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 31),
                    child: const SizedBox.expand(),
                  ),
                ),
                AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) {
                    final travel = _move.value.clamp(0.0, 1.0).toDouble();
                    final bulge = math.sin(travel * math.pi);
                    final center = _center(_from, width, rtl) +
                        (_center(_to, width, rtl) - _center(_from, width, rtl)) *
                            _move.value;
                    final lensWidth = (slot * 0.84) * (1 + 0.46 * bulge);
                    final lensHeight = 46 * (1 - 0.1 * bulge);
                    return Positioned(
                      left: center - lensWidth / 2,
                      bottom: (_GlassNavBar._barHeight - lensHeight) / 2,
                      width: lensWidth,
                      height: lensHeight,
                      child: LiquidGlass.withOwnLayer(
                        settings: LiquidGlassSettings(
                          thickness: 34,
                          blur: 0.4,
                          refractiveIndex: 1.42,
                          lightIntensity: 2,
                          ambientStrength: 0.12,
                          chromaticAberration: 0.1,
                          saturation: 1.85,
                          lightAngle: -math.pi / 2.4,
                          glassColor: dark
                              ? const Color(0x33FFFFFF)
                              : const Color(0x66FFFFFF),
                        ),
                        shape: LiquidRoundedSuperellipse(
                          borderRadius: lensHeight / 2,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _GlassNavBar._barHeight,
                  child: Row(
                    children: [
                      Expanded(child: _NavItem(widget.items[0])),
                      Expanded(child: _NavItem(widget.items[1])),
                      const SizedBox(width: _GlassNavBar._buttonSize),
                      Expanded(child: _NavItem(widget.items[2])),
                      Expanded(child: _NavItem(widget.items[3])),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: _BookButton(onPressed: widget.onBook)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BookButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: .38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.gold,
        elevation: 0,
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: .7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: _GlassNavBar._buttonSize,
            height: _GlassNavBar._buttonSize,
            child: Icon(Icons.add_rounded, size: 28, color: AppColors.greenDarker),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  const _NavItem(this.spec);

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final color = spec.active
        ? (dark ? Colors.white : const Color(0xFF1C1C1E))
        : (dark ? Colors.white.withValues(alpha: .46) : const Color(0xFF8E8E93));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: spec.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: spec.active ? 1.06 : 1,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                spec.active ? spec.activeIcon : spec.icon,
                key: ValueKey(spec.active),
                size: 23,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              letterSpacing: -0.2,
              color: color,
              fontWeight: spec.active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
