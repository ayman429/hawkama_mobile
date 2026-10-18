import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
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
    final failure = await context.read<PaymentMethodsCubit>().save(
          token: draft.token,
          isDefault: draft.isDefault,
        );
    if (!context.mounted) return;
    if (failure == null) {
      showToast(context, tr('savedOK'));
      return;
    }
    showToast(context, failure.message, error: true);
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
  final String token;
  final bool isDefault;
  const _CardDraft(this.token, this.isDefault);
}

class _CardDialog extends StatefulWidget {
  const _CardDialog();

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  final _token = TextEditingController();
  var _isDefault = true;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _submit() {
    if (_token.text.trim().isEmpty) {
      showToast(context, tr('fillRequired'), error: true);
      return;
    }
    Navigator.pop(context, _CardDraft(_token.text.trim(), _isDefault));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('addCard'), style: amiri(size: 15)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('cardTokenNote'),
              style: TextStyle(fontSize: 10, color: context.col.stone),
            ),
            const SizedBox(height: 8),
            AppField(
              tr('cardToken'),
              controller: _token,
              hint: tr('cardTokenHint'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              activeColor: context.col.primaryFill,
              title: Text(tr('makeDefault'), style: const TextStyle(fontSize: 11)),
              onChanged: (value) => setState(() => _isDefault = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
        TextButton(onPressed: _submit, child: Text(tr('save'))),
      ],
    );
  }
}
