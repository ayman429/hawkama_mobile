import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../booking/cubit/booking_draft_cubit.dart';
import '../../booking/models/booking.dart';
import '../../packages/models/consult_package.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCubit>().state;
    final user = context.watch<AuthCubit>().state.user;
    final c = context.col;
    final hour = DateTime.now().hour;
    final greeting = hour >= 5 && hour < 17 ? tr('greetingM') : tr('greetingE');
    final dash = home.dashboard;
    final next = dash?.nextBooking;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.ink,
          onRefresh: () => context.read<HomeCubit>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      _GlassPanel(
                        radius: 26,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            PersonAvatar(avatarInitial(user?.name ?? tr('guest')), size: 36, fontSize: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8E8E93),
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    user?.name ?? tr('guest'),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: c.text,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final ok = await ensureLoggedIn(context);
                                if (!context.mounted || !ok) return;
                                await context.push(AppRoutes.notifications);
                                if (!context.mounted) return;
                                context.read<HomeCubit>().load();
                              },
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.notifications_none_rounded, size: 24, color: c.text),
                                    if (home.unread > 0)
                                      PositionedDirectional(
                                        top: 7,
                                        end: 7,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFFF3B30),
                                            border: Border.all(
                                              color: context.isDark ? c.surface : Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _GlassPanel(
                        radius: 22,
                        child: GestureDetector(
                          onTap: () => _startBooking(context),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            height: 44,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(children: [
                                const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8E8E93)),
                                const SizedBox(width: 8),
                                Text(
                                  tr('searchHint'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.3,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                if (home.loading)
                  const LogoLoadingWidget(size: 200)
                // OLD: const SkeletonPulse(
                //   child: SkeletonBox(height: 132, radius: 16),
                // )
                else ...[
                  if (next != null)
                    _HeroCard(next)
                  else
                    GestureDetector(
                      onTap: () => _startBooking(context),
                      child: _FloatGlass(
                        padding: const EdgeInsets.all(16),
                        fill: LinearGradient(colors: [c.heroFrom, c.heroTo]),
                        child: Text(
                          '${tr('heroEmpty')} — ${tr('heroEmptyCta')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SectionHeader(tr('quickActions')),
                  Row(children: [
                    _QuickAction(Icons.add, tr('newBooking'), () => _startBooking(context)),
                    _QuickAction(Icons.calendar_month_outlined, tr('myBookings'),
                        () => _openAuthTab(context, 1)),
                    _QuickAction(Icons.description_outlined, tr('myReports'),
                        () => _openAuthTab(context, 2)),
                    _QuickAction(Icons.work_outline, tr('myPackages'), () {
                      context.push(AppRoutes.packages);
                    }),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 148,
                    child: Row(children: [
                      Expanded(
                        flex: 12,
                        child: _PlanSlip(
                          name: dash?.currentPackageName.isNotEmpty == true
                              ? dash!.currentPackageName
                              : tr('noPackage'),
                          muted: dash?.currentPackageName.isNotEmpty != true,
                          onTap: () => context.push(AppRoutes.packages),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 10,
                        child: Column(children: [
                          Expanded(
                            child: _CountTile(
                              value: locNum(dash?.upcomingCount ?? 0),
                              label: tr('statUpcoming'),
                              onTap: () => _openAuthTab(context, 1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _CountTile(
                              value: locNum(dash?.reportsTotal ?? 0),
                              label: tr('statReports'),
                              marked: (dash?.reportsUnread ?? 0) > 0,
                              onTap: () => _openAuthTab(context, 2),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  SectionHeader(tr('ourServices'), action: tr('viewAll'), onAction: () => _startBooking(context)),
                  for (var i = 0; i < home.services.length && i < 2; i++)
                    _MiniService(pkg: home.services[i]),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.packages),
                    child: _FloatGlass(
                      margin: const EdgeInsets.only(top: 6),
                      radius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      fill: LinearGradient(colors: [c.bannerFrom, c.goldSoft]),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('bannerTitle'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                              ),
                              Text(
                                tr('bannerSub'),
                                style: TextStyle(fontSize: 9, color: c.goldText),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: c.text,
                        ),
                      ]),
                    ),
                  ),
                ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAuthTab(BuildContext context, int index) async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !context.mounted) return;
    context.read<ShellCubit>().select(index);
  }

  void _startBooking(BuildContext context) {
    context.read<BookingDraftCubit>().reset();
    context.push(AppRoutes.bookingService);
  }
}

/// Translucent card with a lit rim and a soft lift, so it reads as glass on water.
/// The scrolling shader is intentionally not used here; it tears when the list moves.
class _FloatGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? fill;

  const _FloatGlass({
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: cardDeco(context, radius: radius, gradient: fill),
      child: child,
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  const _GlassPanel({required this.child, required this.radius});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? const Color(0xCC1C2321) : const Color(0xC4FFFFFF),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? .10 : .72),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Booking booking;
  const _HeroCard(this.booking);

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return _FloatGlass(
      padding: const EdgeInsets.all(16),
      fill: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.heroFrom, c.heroTo],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('nextBooking'), style: const TextStyle(fontSize: 9, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            booking.package?.name ?? tr('nextBooking'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          _HeroMeta(Icons.access_time, booking.dateTimeLabel),
          const SizedBox(height: 4),
          _HeroMeta(
            Icons.person_outline,
            '${booking.consultant?.name ?? ''} — ${tr('remote')}',
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push(AppRoutes.bookingDetailOf(booking.id)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr('bookingDetails'),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDarker,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroMeta(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: .9)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .9)),
          ),
        ),
      ]);
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: _FloatGlass(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: context.isDark ? c.accentSoft : c.goldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: c.accent),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.text),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlanSlip extends StatelessWidget {
  final String name;
  final bool muted;
  final VoidCallback onTap;
  const _PlanSlip({required this.name, required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final dark = context.isDark;
    final forward = Directionality.of(context) == TextDirection.rtl
        ? Icons.arrow_back_rounded
        : Icons.arrow_forward_rounded;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: _FloatGlass(
            radius: 24,
            fill: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: dark
                  ? const [Color(0xFF1B2623), Color(0xFF151A19)]
                  : const [Color(0xFFF4FBF8), Color(0xFFFFFFFF)],
            ),
            child: Stack(fit: StackFit.expand, children: [
              PositionedDirectional(
                top: -36,
                end: -30,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.accent.withValues(alpha: dark ? .10 : .12),
                      width: 16,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('statPackage'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.stone,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: muted ? c.stone : c.text,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(forward, size: 16, color: c.accent),
                    ),
                  ],
                ),
              ),
            ]),
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  final bool marked;
  const _CountTile({
    required this.value,
    required this.label,
    required this.onTap,
    this.marked = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: _FloatGlass(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                color: c.text,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                  color: c.stone,
                ),
              ),
            ),
            if (marked)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsetsDirectional.only(start: 6),
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _MiniService extends StatelessWidget {
  final ConsultPackage pkg;
  const _MiniService({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return GestureDetector(
      onTap: () {
        final draft = context.read<BookingDraftCubit>();
        draft.reset();
        draft.pickPackage(pkg);
        context.push(AppRoutes.bookingConsultant);
      },
      child: _FloatGlass(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          const IconBox(Icons.work_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.name,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  pkg.isUnlimited
                      ? tr('unlimited')
                      : pkg.features.isNotEmpty
                          ? pkg.features.first
                          : pkg.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: c.stone),
                ),
              ],
            ),
          ),
          Text(
            pkg.priceFormatted,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: c.accent,
            ),
          ),
        ]),
      ),
    );
  }
}
