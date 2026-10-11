import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/repo.dart';
import '../core/auth_gate.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../state/booking_store.dart';
import '../widgets/common.dart';
import 'booking/service_pick_screen.dart';
import 'booking/consultant_pick_screen.dart';
import 'main_shell.dart';
import 'notifications_screen.dart';
import 'packages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Dashboard? _dash;
  List<ConsultPackage> _services = const [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final authed = AuthStore.instance.isAuthed;
      final dash = authed ? await Repo.dashboard() : null;
      final services = await Repo.packages();
      final unread = authed ? await Repo.unreadCount() : 0;
      if (!mounted) return;
      setState(() {
        _dash = dash;
        _services = services;
        _unread = unread;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final auth = AuthStore.instance;
    final user = auth.user;
    final hour = DateTime.now().hour;
    final greeting = hour >= 5 && hour < 17 ? tr('greetingM') : tr('greetingE');
    final dash = _dash;
    final next = dash?.nextBooking;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.greenDeep,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── header row
                Row(children: [
                  PersonAvatar(initialOf(user?.name ?? tr('guest'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: TextStyle(fontSize: 11, color: c.stone)),
                        Text(user?.name ?? tr('guest'),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: c.text)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final ok = await ensureLoggedIn(context);
                      if (!mounted) return;
                      if (!ok) return;
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()));
                      if (!mounted) return;
                      _load();
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: cardDeco(context, radius: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.notifications_outlined,
                              size: 20, color: c.text),
                          if (_unread > 0)
                            Positioned(
                              top: 9,
                              left: 9,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold,
                                  border: Border.all(
                                      color: c.surface, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── search → wizard
                GestureDetector(
                  onTap: _startBooking,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: cardDeco(context),
                    child: Row(children: [
                      Icon(Icons.search, size: 18, color: c.stone),
                      const SizedBox(width: 8),
                      Text(tr('searchHint'),
                          style: TextStyle(fontSize: 11, color: c.stone)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── hero
                if (_loading)
                  Container(
                      height: 120,
                      decoration: BoxDecoration(
                          color: c.chipBg,
                          borderRadius: BorderRadius.circular(16)))
                else if (next != null)
                  _HeroCard(next)
                else
                  GestureDetector(
                    onTap: _startBooking,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [
                          AppColors.greenDeep,
                          AppColors.greenMid
                        ]),
                      ),
                      child: Text(
                          '${tr('heroEmpty')} — ${tr('heroEmptyCta')}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                const SizedBox(height: 14),

                // ── quick actions
                SectionHeader(tr('quickActions')),
                Row(children: [
                  _QuickAction(Icons.add, tr('newBooking'), _startBooking),
                  _QuickAction(Icons.calendar_month_outlined, tr('myBookings'),
                      () => _openAuthTab(1)),
                  _QuickAction(Icons.description_outlined, tr('myReports'),
                      () => _openAuthTab(2)),
                  _QuickAction(Icons.work_outline, tr('myPackages'), () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PackagesScreen()));
                  }),
                ]),
                const SizedBox(height: 14),

                // ── stats
                Row(children: [
                  Expanded(
                      child: _Stat(
                          locNum(dash?.reportsTotal ?? 0),
                          tr('statReports'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _Stat(
                          locNum(dash?.upcomingCount ?? 0),
                          tr('statUpcoming'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _Stat(
                          dash?.currentPackageName.isNotEmpty == true
                              ? dash!.currentPackageName
                              : tr('noPackage'),
                          tr('statPackage'),
                          small: true)),
                ]),
                const SizedBox(height: 12),

                // ── services preview (2 rows, from packages per mobile.md §7)
                SectionHeader(tr('ourServices'),
                    action: tr('viewAll'), onAction: _startBooking),
                for (var i = 0; i < _services.length && i < 2; i++)
                  _MiniService(pkg: _services[i]),

                // ── upsell banner
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PackagesScreen())),
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.bannerLine),
                      gradient: LinearGradient(colors: [
                        c.bannerFrom,
                        c.goldSoft,
                      ]),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('bannerTitle'),
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.text)),
                            Text(tr('bannerSub'),
                                style: TextStyle(
                                    fontSize: 9, color: c.goldText)),
                          ],
                        ),
                      ),
                      Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: c.text),
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

  Future<void> _openAuthTab(int index) async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !mounted) return;
    shellIndex.value = index;
  }

  void _startBooking() {
    BookingStore.instance.reset();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ServicePickScreen()));
  }
}

class _HeroCard extends StatelessWidget {
  final Booking b;
  const _HeroCard(this.b);

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
          Text(tr('nextBooking'),
              style:
                  const TextStyle(fontSize: 9, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(b.package?.name ?? tr('nextBooking'),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 6),
          _HeroMeta(Icons.access_time, b.dateTimeLabel),
          const SizedBox(height: 4),
          _HeroMeta(Icons.person_outline,
              '${b.consultant?.name ?? ''} — ${tr('remote')}'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => shellIndex.value = 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(tr('bookingDetails'),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDarker)),
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
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: .9))),
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
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: c.text)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final bool small;
  const _Stat(this.value, this.label, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: cardDeco(context, radius: 10),
      child: Column(children: [
        Text(value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: small ? 11 : 15,
                fontWeight: FontWeight.w800,
                color: c.text)),
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
        final store = BookingStore.instance;
        store.reset();
        store.pickPackage(pkg);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ConsultantPickScreen()));
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
                Text(pkg.name,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.text)),
                const SizedBox(height: 2),
                Text(
                    pkg.isUnlimited
                        ? tr('unlimited')
                        : pkg.features.isNotEmpty
                            ? pkg.features.first
                            : pkg.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: c.stone)),
              ],
            ),
          ),
          Text(pkg.priceFormatted,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenMid)),
        ]),
      ),
    );
  }
}
