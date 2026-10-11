import 'package:flutter/material.dart';

import '../../api/errors.dart';
import '../../core/theme.dart';
import '../../core/auth_gate.dart';
import '../../l10n/strings.dart';
import '../../state/booking_store.dart';
import '../../widgets/common.dart';
import 'success_screen.dart';

/// Wizard step 4 — summary + quote + submit (API guide §5.6/§5.7).
///
/// Payment (§5.5/§5.6 3-D Secure via Moyasar) is stubbed for the source
/// handoff: when the quote says `requires_payment`, the submit path is where
/// the developer mounts the hosted form (webview) and passes `paymentMethodId`
/// or `cardToken` into [BookingStore.submit]. See README § payments.
class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool _busy = false;

  Future<void> _submit() async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await BookingStore.instance.submit();
      if (!mounted) return;
      if (result.needs3ds) {
        // Handoff note: push the WebView/launcher on result.transactionUrl,
        // then verify with POST /client/payments/{id}/verify on return.
        showToast(context, tr('paymentWebNote'),
            icon: Icons.open_in_new);
      }
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SuccessScreen(booking: result.booking)));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isSlotGone) {
        // §5.7 — bounce back to step 3 so the calendar/slots reload.
        showToast(context, tr('slotTaken'), error: true);
        Navigator.pop(context);
        return;
      }
      if (e.isPaymentPending) {
        showToast(context, '${tr('loading')} — ${e.message}',
            icon: Icons.schedule);
        return;
      }
      showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final store = BookingStore.instance;
    final p = store.package, co = store.consultant, d = store.date, s = store.slot;
    final hasAll = p != null && co != null && d != null && s != null;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final quote = store.quote;
        final total = quote?.amountFormatted.isNotEmpty == true
            ? quote!.amountFormatted
            : (p?.priceFormatted ?? '—');
        return ScreenBody(children: [
          BackHeader(tr('confirmBooking')),
          const WizardSteps(3),
          Container(
            decoration: cardDeco(context, radius: 14),
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(children: [
              _SumRow(tr('sumService'), p?.name ?? '—'),
              _SumRow(tr('sumConsultant'), co?.name ?? '—'),
              _SumRow(tr('sumDate'), d == null ? '—' : locDate(d)),
              _SumRow(tr('sumTime'), s?.label ?? '—'),
              _SumRow(tr('sumTotal'),
                  quote?.coveredBySubscription == true
                      ? tr('paidBySub')
                      : total,
                  totalRow: true,
                  last: true),
            ]),
          ),
          if (quote != null && !quote.requiresPayment && quote.coveredBySubscription)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                const Icon(Icons.verified_outlined,
                    size: 14, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(tr('paidBySub'),
                    style: TextStyle(fontSize: 10, color: c.stone)),
              ]),
            ),
          Container(
            decoration: cardDeco(context),
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${tr('benefit1')}\n${tr('benefit2')}\n${tr('benefit3')}',
              style: TextStyle(fontSize: 11, color: c.stone, height: 1.7),
            ),
          ),
          AppButton(
            tr('confirmCta'),
            variant: AppButtonVariant.gold,
            padV: 13,
            fontSize: 13,
            loading: _busy,
            onTap: hasAll ? _submit : null,
          ),
        ]);
      },
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final bool totalRow, last;
  const _SumRow(this.label, this.value,
      {this.totalRow = false, this.last = false});

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
        Text(label,
            style: TextStyle(
                fontSize: totalRow ? 12 : 11, color: c.stone)),
        const Spacer(),
        Flexible(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: totalRow ? 13 : 11,
                  fontWeight: FontWeight.w700,
                  color: c.text)),
        ),
      ]),
    );
  }
}
