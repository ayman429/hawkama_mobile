import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/config.dart';
import '../../../core/di.dart';
import '../../../core/network/result.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../profile/models/saved_card.dart';
import '../../profile/models/client_location.dart';
import '../../profile/repo/profile_repository.dart';
import '../cubit/booking_draft_cubit.dart';
import '../models/booking.dart';
import '../repo/moyasar_gateway.dart';
import 'three_ds_page.dart';

class ConfirmPage extends StatefulWidget {
  const ConfirmPage({super.key});

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  final _gateway = MoyasarGateway();
  List<SavedCard> _cards = const [];
  List<ClientLocation> _locations = const [];
  int? _selectedCardId;
  int? _selectedLocationId;
  bool _useNewCard = true;
  bool _loadingCards = false;
  bool _cardsLoaded = false;
  bool _loadingLocations = false;
  bool _locationsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
    _loadLocations();
  }

  Future<void> _loadCards() async {
    if (context.read<AuthCubit>().state.user == null) {
      return;
    }
    setState(() => _loadingCards = true);
    final result = await getIt<ProfileRepository>().paymentMethods();
    if (!mounted) return;
    if (result case Success<List<SavedCard>>(:final data)) {
      final usable = data.where((card) => !card.isExpired).toList();
      final defaultId =
          context.read<AuthCubit>().state.user?.defaultPaymentMethodId;
      final preferred =
          usable.where((card) => card.id == defaultId || card.isDefault);
      setState(() {
        _cards = usable;
        if (preferred.isNotEmpty) {
          _selectedCardId = preferred.first.id;
          _useNewCard = false;
        }
        _loadingCards = false;
        _cardsLoaded = true;
      });
    } else {
      setState(() {
        _loadingCards = false;
        _cardsLoaded = true;
      });
    }
  }

  Future<void> _loadLocations() async {
    if (context.read<AuthCubit>().state.user == null) return;
    setState(() => _loadingLocations = true);
    final result = await getIt<ProfileRepository>().locations();
    if (!mounted) return;
    if (result case Success<List<ClientLocation>>(:final data)) {
      final defaultId = context.read<AuthCubit>().state.user?.defaultLocationId;
      final preferred = data.where(
        (location) => location.id == defaultId || location.isDefault,
      );
      setState(() {
        _locations = data;
        _selectedLocationId = preferred.isNotEmpty
            ? preferred.first.id
            : (data.length == 1 ? data.first.id : _selectedLocationId);
        _loadingLocations = false;
        _locationsLoaded = true;
      });
    } else {
      setState(() {
        _loadingLocations = false;
        _locationsLoaded = true;
      });
    }
  }

  Future<void> _submit(BuildContext context) async {
    final bookingDraft = context.read<BookingDraftCubit>();
    final ok = await ensureLoggedIn(context);
    if (!ok || !context.mounted) return;
    final auth = context.read<AuthCubit>();
    await auth.refreshProfile();
    if (!context.mounted) return;
    if (!_cardsLoaded) await _loadCards();
    if (!_locationsLoaded) await _loadLocations();
    if (!context.mounted) return;

    if (_selectedLocationId == null) {
      showToast(context, tr('bookingLocationRequired'), error: true);
      await context.push(AppRoutes.addresses);
      if (!context.mounted) return;
      _locationsLoaded = false;
      await _loadLocations();
      if (!context.mounted || _selectedLocationId == null) return;
    }

    final draft = context.read<BookingDraftCubit>().state;
    final requiresPayment =
        !AppConfig.useMock && (draft.quote?.requiresPayment ?? true);
    String? cardToken;
    int? paymentMethodId;
    if (requiresPayment) {
      if (_useNewCard) {
        final details = await showDialog<_CardDetails>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _NewCardDialog(),
        );
        if (details == null || !context.mounted) return;
        try {
          cardToken = await _gateway.tokenize(
            name: details.name,
            number: details.number,
            month: details.month,
            year: details.year,
            cvc: details.cvc,
          );
        } catch (error) {
          if (context.mounted) {
            showToast(context, _paymentError(error), error: true);
          }
          return;
        }
      } else {
        paymentMethodId = _selectedCardId;
        if (paymentMethodId == null) {
          showToast(context, tr('paymentChooseCard'), error: true);
          return;
        }
      }
    }

    final result = await bookingDraft.submit(
      clientLocationId: _selectedLocationId,
      paymentMethodId: paymentMethodId,
      cardToken: cardToken,
    );
    if (!context.mounted || result == null) return;
    await result.fold<Future<void>>((created) async {
      if (created.paymentId != null &&
          (created.needs3ds ||
              created.pendingConfirmation ||
              created.paymentStatus == 'initiated')) {
        if (created.needs3ds) {
          await Navigator.of(context).push<bool>(MaterialPageRoute(
            builder: (_) => ThreeDsPage(
              url: created.transactionUrl!,
              callbackUrl: AppConfig.paymentCallbackUrl,
            ),
          ));
        }
        if (context.mounted) {
          await _verifyUntilFinal(context, created.paymentId!);
        }
        return;
      }
      if (created.paymentStatus == 'failed') {
        showToast(context, tr('paymentFailed'), error: true);
        return;
      }
      final booking = created.booking;
      if (booking != null &&
          (created.paymentStatus == 'paid' ||
              created.paymentStatus == null ||
              !requiresPayment)) {
        context.push(AppRoutes.bookingSuccess, extra: booking);
      } else {
        showToast(context, tr('paymentPendingInfo'), icon: Icons.schedule);
      }
    }, (failure) async {
      if (failure.isSlotGone) {
        showToast(context, tr('slotTaken'), error: true);
        context.pop();
        return;
      }
      if (failure.isPaymentPending) {
        showToast(context, tr('paymentPendingInfo'), icon: Icons.schedule);
        return;
      }
      showToast(context, failure.message, error: true);
    });
  }

  Future<void> _verifyUntilFinal(BuildContext context, int paymentId) async {
    final bookingDraft = context.read<BookingDraftCubit>();
    for (var attempt = 0; attempt < 10; attempt++) {
      final result = await bookingDraft.verifyPayment(paymentId);
      if (!context.mounted) return;
      if (result case Success<PaymentVerification>(:final data)) {
        if (data.status == 'paid') {
          final booking = data.booking;
          if (booking != null) {
            context.push(AppRoutes.bookingSuccess, extra: booking);
          } else {
            showToast(context, tr('paymentPendingInfo'), icon: Icons.schedule);
          }
          return;
        }
        if (data.status == 'failed' || data.status == 'refunded') {
          showToast(
            context,
            data.failureReason?.isNotEmpty == true
                ? data.failureReason!
                : tr('paymentFailed'),
            error: true,
          );
          return;
        }
      }
      if (attempt < 9) await Future<void>.delayed(const Duration(seconds: 3));
    }
    if (context.mounted) {
      showToast(context, tr('paymentPendingInfo'), icon: Icons.schedule);
    }
  }

  String _paymentError(Object error) {
    final text = error.toString();
    if (text.contains('Moyasar publishable key')) {
      return tr('paymentConfigMissing');
    }
    return tr('paymentFailed');
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
    final hasAll =
        package != null && consultant != null && date != null && slot != null;

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
      if (quote != null &&
          !quote.requiresPayment &&
          quote.coveredBySubscription)
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
      if (!AppConfig.useMock && quote?.requiresPayment != false) ...[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(tr('paymentTitle'),
                style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
          ),
        ),
        if (_loadingCards)
          const Padding(
              padding: EdgeInsets.all(12), child: LinearProgressIndicator())
        else ...[
          for (final card in _cards)
            _PaymentChoice(
              title: card.label,
              subtitle: card.isDefault ? tr('defaultBadge') : card.holderName,
              selected: !_useNewCard && _selectedCardId == card.id,
              onTap: () => setState(() {
                _useNewCard = false;
                _selectedCardId = card.id;
              }),
            ),
          _PaymentChoice(
            title: tr('addNewCard'),
            subtitle: tr('cardDetailsStayWithMoyasar'),
            selected: _useNewCard,
            onTap: () => setState(() => _useNewCard = true),
          ),
        ],
      ],
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(tr('bookingLocation'),
              style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
        ),
      ),
      if (_loadingLocations)
        const Padding(
            padding: EdgeInsets.all(12), child: LinearProgressIndicator())
      else if (_locations.isEmpty)
        _PaymentChoice(
          title: tr('bookingLocationRequired'),
          subtitle: tr('addAddress'),
          selected: false,
          onTap: () async {
            await context.push(AppRoutes.addresses);
            if (mounted) {
              _locationsLoaded = false;
              await _loadLocations();
            }
          },
        )
      else
        for (final location in _locations)
          _PaymentChoice(
            title: location.name,
            subtitle: [location.city, location.address]
                .where((part) => part.isNotEmpty)
                .join(' • '),
            selected: _selectedLocationId == location.id,
            onTap: () => setState(() => _selectedLocationId = location.id),
          ),
      Container(
        decoration: cardDeco(context),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(top: 12, bottom: 12),
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
        onTap: hasAll && !_loadingCards && !_loadingLocations
            ? () => _submit(context)
            : null,
      ),
    ]);
  }
}

class _PaymentChoice extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: cardDeco(context, radius: 12).copyWith(
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? c.accent : c.stone, size: 19),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: TextStyle(color: c.stone, fontSize: 10)),
              ])),
          const Icon(Icons.credit_card_outlined, size: 20),
        ]),
      ),
    );
  }
}

class _CardDetails {
  final String name, number, month, year, cvc;
  const _CardDetails(this.name, this.number, this.month, this.year, this.cvc);
}

class _NewCardDialog extends StatefulWidget {
  const _NewCardDialog();

  @override
  State<_NewCardDialog> createState() => _NewCardDialogState();
}

class _NewCardDialogState extends State<_NewCardDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _cvc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _month.dispose();
    _year.dispose();
    _cvc.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final details = _CardDetails(
        _name.text, _number.text, _month.text, _year.text, _cvc.text);
    _name.clear();
    _number.clear();
    _month.clear();
    _year.clear();
    _cvc.clear();
    Navigator.of(context).pop(details);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(tr('addNewCard')),
        content: Form(
          key: _form,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(_name, tr('cardHolderName')),
            _field(_number, tr('cardNumber'),
                keyboard: TextInputType.number, obscure: true),
            Row(children: [
              Expanded(
                  child: _field(_month, tr('expiryMonth'),
                      keyboard: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(
                  child: _field(_year, tr('expiryYear'),
                      keyboard: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(
                  child: _field(_cvc, 'CVC',
                      keyboard: TextInputType.number, obscure: true)),
            ]),
          ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel'))),
          FilledButton(onPressed: _submit, child: Text(tr('continue'))),
        ],
      );

  Widget _field(TextEditingController controller, String label,
          {TextInputType? keyboard, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: label == tr('cardNumber')
              ? const [AutofillHints.creditCardNumber]
              : null,
          decoration: InputDecoration(labelText: label, isDense: true),
          validator: (value) => _validate(label, value),
        ),
      );

  String? _validate(String label, String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return tr('fillRequired');
    if (label == tr('cardHolderName') &&
        input.split(RegExp(r'\s+')).length < 2) {
      return tr('cardNameNeedsTwoWords');
    }
    if (label == tr('cardNumber') &&
        !RegExp(r'^\d{12,19}$')
            .hasMatch(input.replaceAll(RegExp(r'\s+'), ''))) {
      return tr('invalidCardNumber');
    }
    if (label == tr('expiryMonth')) {
      final month = int.tryParse(input);
      if (month == null || month < 1 || month > 12) return tr('invalidExpiry');
    }
    if (label == tr('expiryYear')) {
      final year = int.tryParse(input);
      if ((input.length != 2 && input.length != 4) || year == null) {
        return tr('invalidExpiry');
      }
      final fullYear = input.length == 2 ? 2000 + year : year;
      final expiryMonth = int.tryParse(_month.text);
      final now = DateTime.now();
      if (fullYear < now.year ||
          (fullYear == now.year &&
              (expiryMonth == null || expiryMonth < now.month))) {
        return tr('invalidExpiry');
      }
    }
    if (label == 'CVC' && !RegExp(r'^\d{3,4}$').hasMatch(input)) {
      return tr('invalidCvc');
    }
    return null;
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final bool totalRow;
  final bool last;

  const _SumRow(this.label, this.value,
      {this.totalRow = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                last ? BorderSide.none : BorderSide(color: c.line, width: 1)),
      ),
      child: Row(children: [
        Text(label,
            style: TextStyle(fontSize: totalRow ? 12 : 11, color: c.stone)),
        const Spacer(),
        Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: totalRow ? 13 : 11,
                    fontWeight: FontWeight.w700,
                    color: c.text))),
      ]),
    );
  }
}
