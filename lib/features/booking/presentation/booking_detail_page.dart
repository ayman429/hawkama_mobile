import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/booking_detail_cubit.dart';
import '../models/booking.dart';

class BookingDetailPage extends StatelessWidget {
  final int bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookingDetailCubit>().state;
    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            BackHeader(tr('bookingDetails')),
            if (state.loading)
              const SkeletonRows(count: 3)
            else if (state.booking == null)
              EmptyState(
                Icons.event_busy_outlined,
                state.error ?? tr('loadFailed'),
                cta: tr('retry'),
                onCta: () => context.read<BookingDetailCubit>().load(bookingId),
              )
            else
              _DetailCard(state.booking!),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Booking booking;
  const _DetailCard(this.booking);

  Future<void> _join(BuildContext context) async {
    final url = booking.meetingUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      showToast(context, tr('linkFailed'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final duration = booking.durationMinutes > 0
        ? '${locNum(booking.durationMinutes)} ${tr('minutes')}'
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDeco(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                booking.package?.name ?? booking.reference,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                ),
              ),
            ),
            StatusBadge(booking.status, booking.statusLabel),
          ]),
          const SizedBox(height: 10),
          _Row(tr('bookingRef'), booking.reference, ltr: true),
          _Row(tr('sumConsultant'), booking.consultant?.name ?? ''),
          _Row(tr('sumDate'), booking.date.isEmpty ? '' : locDate(booking.date)),
          _Row(tr('sumTime'), booking.time.isEmpty ? '' : locTime(booking.time)),
          _Row(tr('sumDuration'), duration),
          _Row(tr('sumTotal'), booking.amountFormatted, ltr: true),
          _Row(tr('location'), booking.locationLabel),
          _Row(tr('paymentTitle'), booking.paymentLabel, ltr: true),
          _Row(tr('clientNotes'), booking.clientNotes),
          if (booking.meetingUrl != null && booking.meetingUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppButton(
              tr('joinMeeting'),
              variant: AppButtonVariant.gold,
              onTap: () => _join(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;
  const _Row(this.label, this.value, {this.ltr = false});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final c = context.col;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 10, color: c.stone)),
        ),
        Flexible(
          child: Text(
            value,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
      ]),
    );
  }
}
