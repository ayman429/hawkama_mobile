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
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.greenDeep,
          onRefresh: () => context.read<HomeCubit>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  PersonAvatar(avatarInitial(user?.name ?? tr('guest'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: TextStyle(fontSize: 11, color: c.stone)),
                        Text(
                          user?.name ?? tr('guest'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c.text,
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
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: cardDeco(context, radius: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.notifications_outlined, size: 20, color: c.text),
                          if (home.unread > 0)
                            Positioned(
                              top: 9,
                              left: 9,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold,
                                  border: Border.all(color: c.surface, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _startBooking(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: cardDeco(context),
                    child: Row(children: [
                      Icon(Icons.search, size: 18, color: c.stone),
                      const SizedBox(width: 8),
                      Text(tr('searchHint'), style: TextStyle(fontSize: 11, color: c.stone)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                if (home.loading)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: c.chipBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  )
                else if (next != null)
                  _HeroCard(next)
                else
                  GestureDetector(
                    onTap: () => _startBooking(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.greenDeep, AppColors.greenMid],
                        ),
                      ),
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
                Row(children: [
                  Expanded(child: _Stat(locNum(dash?.reportsTotal ?? 0), tr('statReports'))),
                  const SizedBox(width: 8),
                  Expanded(child: _Stat(locNum(dash?.upcomingCount ?? 0), tr('statUpcoming'))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      dash?.currentPackageName.isNotEmpty == true
                          ? dash!.currentPackageName
                          : tr('noPackage'),
                      tr('statPackage'),
                      small: true,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SectionHeader(tr('ourServices'), action: tr('viewAll'), onAction: () => _startBooking(context)),
                for (var i = 0; i < home.services.length && i < 2; i++)
                  _MiniService(pkg: home.services[i]),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.packages),
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.bannerLine),
                      gradient: LinearGradient(colors: [c.bannerFrom, c.goldSoft]),
                    ),
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

class _HeroCard extends StatelessWidget {
  final Booking booking;
  const _HeroCard(this.booking);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenDeep, AppColors.greenMid],
        ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: cardDeco(context),
            child: Column(children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: c.goldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: AppColors.greenMid),
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool small;
  const _Stat(this.value, this.label, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: cardDeco(context, radius: 10),
      child: Column(children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: small ? 11 : 15,
            fontWeight: FontWeight.w800,
            color: c.text,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 8.5, color: c.stone)),
      ]),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: cardDeco(context),
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.greenMid,
            ),
          ),
        ]),
      ),
    );
  }
}
