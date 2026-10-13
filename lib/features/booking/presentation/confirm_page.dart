import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/booking_draft_cubit.dart';

class ConfirmPage extends StatelessWidget {
  const ConfirmPage({super.key});

  Future<void> _submit(BuildContext context) async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !context.mounted) return;
    final auth = context.read<AuthCubit>();
    await auth.refreshProfile();
    if (!context.mounted) return;
    final user = auth.state.user;
    final result = await context.read<BookingDraftCubit>().submit(
      clientLocationId: user?.defaultLocationId,
      paymentMethodId: user?.defaultPaymentMethodId,
    );
    if (!context.mounted || result == null) return;
    result.fold((created) {
      if (created.needs3ds) {
        showToast(context, tr('paymentWebNote'), icon: Icons.open_in_new);
      }
      context.push(AppRoutes.bookingSuccess, extra: created.booking);
    }, (failure) {
      if (failure.isSlotGone) {
        showToast(context, tr('slotTaken'), error: true);
        context.pop();
        return;
      }
      if (failure.isPaymentPending) {
        showToast(
          context,
          '${tr('loading')} — ${failure.message}',
          icon: Icons.schedule,
        );
        return;
      }
      showToast(context, failure.message, error: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BookingDraftCubit>().state;
    final c = context.col;
    final package = draft.package;
    final consultant = draft.consultant;
    final date = draft.date;
    final slot = draft.slot;
    final quote = draft.quote;
    final total = quote?.amountFormatted.isNotEmpty == true
        ? quote!.amountFormatted
        : (package?.priceFormatted ?? '—');
    final hasAll = package != null && consultant != null && date != null && slot != null;

    return ScreenBody(children: [
      BackHeader(tr('confirmBooking')),
      const WizardSteps(3),
      Container(
        decoration: cardDeco(context, radius: 14),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          _SumRow(tr('sumService'), package?.name ?? '—'),
          _SumRow(tr('sumConsultant'), consultant?.name ?? '—'),
          _SumRow(tr('sumDate'), date == null ? '—' : locDate(date)),
          _SumRow(tr('sumTime'), slot?.label ?? '—'),
          _SumRow(
            tr('sumTotal'),
            quote?.coveredBySubscription == true ? tr('paidBySub') : total,
            totalRow: true,
            last: true,
          ),
        ]),
      ),
      if (quote != null && !quote.requiresPayment && quote.coveredBySubscription)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            const Icon(Icons.verified_outlined, size: 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(tr('paidBySub'), style: TextStyle(fontSize: 10, color: c.stone)),
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
        loading: draft.submitting,
        onTap: hasAll ? () => _submit(context) : null,
      ),
    ]);
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final bool totalRow;
  final bool last;

  const _SumRow(this.label, this.value, {this.totalRow = false, this.last = false});

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
        Text(
          label,
          style: TextStyle(fontSize: totalRow ? 12 : 11, color: c.stone),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: totalRow ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ),
      ]),
    );
  }
}
