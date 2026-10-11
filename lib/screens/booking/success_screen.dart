import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../state/booking_store.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';

/// Wizard success — mobile.md §4.5. Reference is the real API value
/// (`BK-…`), rendered LTR inside the RTL gold chip.
class SuccessScreen extends StatelessWidget {
  final Booking booking;
  const SuccessScreen({super.key, required this.booking});

  void _exit(BuildContext context, int tab) {
    BookingStore.instance.reset();
    shellIndex.value = tab;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final store = BookingStore.instance;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.greenDeep,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.greenDeep.withValues(alpha: .08),
                          blurRadius: 0,
                          spreadRadius: 8),
                    ],
                  ),
                  child: const Icon(Icons.check,
                      size: 32, color: AppColors.goldLight),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                  child: Text(tr('booked'),
                      style: amiri(size: 17, color: c.text))),
              const SizedBox(height: 5),
              Text(tr('bookedSub'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: c.stone, height: 1.7)),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.goldSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${tr('bookingRef')}: '),
                      TextSpan(
                          text: booking.reference,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.goldText),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: cardDeco(context, radius: 14),
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(children: [
                  _Row(tr('sumService'),
                      store.package?.name ?? booking.package?.name ?? '—'),
                  _Row(tr('sumConsultant'),
                      store.consultant?.name ?? booking.consultant?.name ?? '—'),
                  _Row(tr('sumSlot'), booking.dateTimeLabel, last: true),
                ]),
              ),
              AppButton(tr('viewBookings'), onTap: () => _exit(context, 1)),
              const SizedBox(height: 8),
              AppButton(tr('backHome'),
                  variant: AppButtonVariant.outline,
                  onTap: () => _exit(context, 0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool last;
  const _Row(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : BorderSide(color: c.line, width: 1),
        ),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 11, color: c.stone)),
        const Spacer(),
        Flexible(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.text)),
        ),
      ]),
    );
  }
}
