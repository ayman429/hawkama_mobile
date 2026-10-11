import 'package:flutter/material.dart';

import '../api/errors.dart';
import '../api/models.dart';
import '../api/repo.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../state/booking_store.dart';
import '../widgets/common.dart';
import 'booking/consultant_pick_screen.dart';
import 'booking/service_pick_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _tab = 0;
  List<Booking>? _all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthStore.instance.isAuthed) {
      setState(() => _all = const []);
      return;
    }
    try {
      final list = await Repo.bookings();
      if (mounted) setState(() => _all = list);
    } catch (_) {
      if (mounted) setState(() => _all = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = (_all ?? []).where((b) => b.isUpcoming).toList();
    final past = (_all ?? []).where((b) => !b.isUpcoming).toList();
    final list = _tab == 0 ? upcoming : past;

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
                AppTitleHeader(tr('tabBookings')),
                Row(children: [
                  _Pill('${tr('pillUpcoming')} (${locNum(upcoming.length)})',
                      _tab == 0, () => setState(() => _tab = 0)),
                  const SizedBox(width: 6),
                  _Pill('${tr('pillPast')} (${locNum(past.length)})', _tab == 1,
                      () => setState(() => _tab = 1)),
                ]),
                const SizedBox(height: 12),
                if (!AuthStore.instance.isAuthed)
                  EmptyState(Icons.lock_outline, tr('loginToContinue'),
                      cta: tr('doLogin'), onCta: _goLogin)
                else if (_all == null)
                  const SkeletonRows()
                else if (list.isEmpty)
                  EmptyState(
                      Icons.calendar_month_outlined,
                      _tab == 0 ? tr('emptyUpcoming') : tr('emptyPast'),
                      cta: _tab == 0 ? tr('bookNow') : null,
                      onCta: _tab == 0
                          ? () {
                              BookingStore.instance.reset();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ServicePickScreen()));
                            }
                          : null)
                else
                  for (final b in list) _BookingCard(b, onChanged: _load),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goLogin() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.greenDeep : c.surface,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: active ? AppColors.greenDeep : c.line),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : c.stone)),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking b;
  final Future<void> Function() onChanged;
  const _BookingCard(this.b, {required this.onChanged});

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('cancelTitle'), style: amiri(size: 15)),
        content: Text(tr('cancelBody'), style: const TextStyle(fontSize: 11)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('yesCancel'),
                  style: TextStyle(color: context.col.danger))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await Repo.cancelBooking(b.id);
      if (context.mounted) showToast(context, tr('cancelDone'));
      await onChanged();
    } on ApiException catch (e) {
      if (context.mounted) showToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final upcoming = b.isUpcoming;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: cardDeco(context, radius: 14),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text(b.package?.name ?? b.reference,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: c.text)),
          ),
          StatusBadge(b.status, b.statusLabel),
        ]),
        const SizedBox(height: 6),
        _MetaRow(Icons.person_outline, b.consultant?.name ?? ''),
        const SizedBox(height: 4),
        _MetaRow(Icons.calendar_month_outlined, b.dateTimeLabel),
        if (b.refundStatus == 'requested') ...[
          const SizedBox(height: 4),
          _MetaRow(Icons.replay_outlined, tr('refundNote')),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: AppButton(
              upcoming ? tr('details') : tr('viewReport'),
              variant: AppButtonVariant.outline,
              padV: 8,
              fontSize: 10,
              onTap: upcoming
                  ? (b.meetingUrl == null
                      ? () {}
                      : () {/* open meeting via url_launcher */})
                  : () => shellIndex.value = 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              upcoming ? tr('cancelBooking') : tr('rebook'),
              variant: upcoming
                  ? AppButtonVariant.dangerOutline
                  : AppButtonVariant.primary,
              padV: 8,
              fontSize: 10,
              onTap: upcoming
                  ? () => _cancel(context)
                  : () {
                      // re-pre-fill the consultant (mobile.md §4.6)
                      final store = BookingStore.instance;
                      store.reset();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConsultantPickScreen()));
                    },
            ),
          ),
        ]),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final c = context.col;
    return Row(children: [
      Icon(icon, size: 13, color: c.stone),
      const SizedBox(width: 7),
      Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: c.stone))),
    ]);
  }
}
