import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/booking_draft_cubit.dart';
import '../cubit/bookings_cubit.dart';
import '../models/booking.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookingsCubit>().state;
    final upcoming = state.items.where((item) => item.isUpcoming).toList();
    final past = state.items.where((item) => !item.isUpcoming).toList();
    final list = _tab == 0 ? upcoming : past;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.greenDeep,
          onRefresh: () => context.read<BookingsCubit>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTitleHeader(tr('tabBookings')),
                Row(children: [
                  _Pill(
                    '${tr('pillUpcoming')} (${locNum(upcoming.length)})',
                    _tab == 0,
                    () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 6),
                  _Pill(
                    '${tr('pillPast')} (${locNum(past.length)})',
                    _tab == 1,
                    () => setState(() => _tab = 1),
                  ),
                ]),
                const SizedBox(height: 12),
                if (state.status == ListStatus.guest)
                  EmptyState(
                    Icons.lock_outline,
                    tr('loginToContinue'),
                    cta: tr('doLogin'),
                    onCta: () => ensureLoggedIn(context),
                  )
                else if (state.status == ListStatus.loading)
                  const SkeletonRows()
                else if (list.isEmpty)
                  EmptyState(
                    Icons.calendar_month_outlined,
                    _tab == 0 ? tr('emptyUpcoming') : tr('emptyPast'),
                    cta: _tab == 0 ? tr('bookNow') : null,
                    onCta: _tab == 0
                        ? () {
                            context.read<BookingDraftCubit>().reset();
                            context.push(AppRoutes.bookingService);
                          }
                        : null,
                  )
                else
                  for (final booking in list) _BookingCard(booking),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
            border: Border.all(color: active ? AppColors.greenDeep : c.line),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : c.stone,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard(this.booking);

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('cancelTitle'), style: amiri(size: 15)),
        content: Text(tr('cancelBody'), style: const TextStyle(fontSize: 11)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('yesCancel'), style: TextStyle(color: ctx.col.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final failure = await context.read<BookingsCubit>().cancel(booking.id);
    if (!context.mounted) return;
    if (failure == null) {
      showToast(context, tr('cancelDone'));
      return;
    }
    showToast(context, failure.message, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final upcoming = booking.isUpcoming;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: cardDeco(context, radius: 14),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text(
              booking.package?.name ?? booking.reference,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: c.text,
              ),
            ),
          ),
          StatusBadge(booking.status, booking.statusLabel),
        ]),
        const SizedBox(height: 6),
        _MetaRow(Icons.person_outline, booking.consultant?.name ?? ''),
        const SizedBox(height: 4),
        _MetaRow(Icons.calendar_month_outlined, booking.dateTimeLabel),
        if (booking.refundStatus == 'requested') ...[
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
                  ? () => context.push(AppRoutes.bookingDetailOf(booking.id))
                  : () => context.read<ShellCubit>().select(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              upcoming ? tr('cancelBooking') : tr('rebook'),
              variant: upcoming ? AppButtonVariant.dangerOutline : AppButtonVariant.primary,
              padV: 8,
              fontSize: 10,
              onTap: upcoming
                  ? () => _cancel(context)
                  : () {
                      context.read<BookingDraftCubit>().reset();
                      context.push(AppRoutes.bookingConsultant);
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
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9.5, color: c.stone),
        ),
      ),
    ]);
  }
}
