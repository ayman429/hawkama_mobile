import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../booking/repo/moyasar_gateway.dart';
import '../cubit/payment_methods_cubit.dart';
import '../models/saved_card.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  Future<void> _add(BuildContext context) async {
    final draft = await showDialog<_CardDraft>(
      context: context,
      builder: (_) => const _CardDialog(),
    );
    if (draft == null || !context.mounted) return;

    // Tokenize card using Moyasar
    final gateway = MoyasarGateway();
    String? token;
    try {
      token = await gateway.tokenize(
        name: draft.name,
        number: draft.number,
        month: draft.month,
        year: draft.year,
        cvc: draft.cvc,
      );
    } catch (error) {
      if (context.mounted) {
        showToast(context, _paymentError(error), error: true);
      }
      return;
    }

    if (!context.mounted || token == null) return;

    final failure = await context.read<PaymentMethodsCubit>().save(
          token: token,
          isDefault: draft.isDefault,
        );
    if (!context.mounted) return;
    if (failure == null) {
      showToast(context, tr('savedOK'));
      return;
    }
    showToast(context, failure.message, error: true);
  }

  String _paymentError(Object error) {
    final text = error.toString();
    if (text.contains('Moyasar publishable key')) {
      return tr('paymentConfigMissing');
    }
    return tr('paymentFailed');
  }

  Future<void> _remove(BuildContext context, SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('deleteCardTitle'), style: amiri(size: 15)),
        content: Text(
          card.label,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'), style: TextStyle(color: ctx.col.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final failure = await context.read<PaymentMethodsCubit>().remove(card.id);
    if (!context.mounted) return;
    showToast(
      context,
      failure?.message ?? tr('deletedOK'),
      error: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentMethodsCubit>().state;
    return AppScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: context.col.ink,
          onRefresh: () => context.read<PaymentMethodsCubit>().load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              BackHeader(tr('paymentMethods')),
              if (state.loading && state.items.isEmpty)
                const SkeletonRows()
              else if (state.items.isEmpty)
                EmptyState(
                  Icons.credit_card_outlined,
                  state.error ?? tr('emptyCards'),
                  cta: state.error == null ? tr('addCard') : tr('retry'),
                  onCta: state.error == null
                      ? () => _add(context)
                      : () => context.read<PaymentMethodsCubit>().load(),
                )
              else
                for (final item in state.items)
                  _CardTile(
                    item,
                    busy: state.busy,
                    onDelete: () => _remove(context, item),
                    onDefault: () async {
                      final failure =
                          await context.read<PaymentMethodsCubit>().makeDefault(item.id);
                      if (!context.mounted || failure == null) return;
                      showToast(context, failure.message, error: true);
                    },
                  ),
              if (state.items.isNotEmpty) ...[
                const SizedBox(height: 4),
                AppButton(
                  tr('addCard'),
                  onTap: state.busy ? null : () => _add(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final SavedCard item;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onDefault;

  const _CardTile(
    this.item, {
    required this.busy,
    required this.onDelete,
    required this.onDefault,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const IconBox(Icons.credit_card_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                ),
              ),
            ),
            if (item.isDefault)
              Text(
                tr('defaultBadge'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              )
            else if (item.isExpired)
              Text(
                tr('expired'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: c.danger,
                ),
              ),
          ]),
          if (item.holderName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.holderName, style: TextStyle(fontSize: 10, color: c.stone)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (!item.isDefault && !item.isExpired)
              GestureDetector(
                onTap: busy ? null : onDefault,
                child: Text(
                  tr('setDefault'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ),
            GestureDetector(
              onTap: busy ? null : onDelete,
              child: Text(
                tr('delete'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c.danger,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _CardDraft {
  final String name;
  final String number;
  final String month;
  final String year;
  final String cvc;
  final bool isDefault;
  const _CardDraft(this.name, this.number, this.month, this.year, this.cvc, this.isDefault);
}

class _CardDialog extends StatefulWidget {
  const _CardDialog();

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _cvc = TextEditingController();
  var _isDefault = true;

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
    final draft = _CardDraft(
      _name.text,
      _number.text,
      _month.text,
      _year.text,
      _cvc.text,
      _isDefault,
    );
    _name.clear();
    _number.clear();
    _month.clear();
    _year.clear();
    _cvc.clear();
    Navigator.of(context).pop(draft);
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
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              activeColor: context.col.primaryFill,
              title: Text(tr('makeDefault'), style: const TextStyle(fontSize: 11)),
              onChanged: (value) => setState(() => _isDefault = value ?? false),
            ),
          ])),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel'))),
          FilledButton(onPressed: _submit, child: Text(tr('save'))),
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
