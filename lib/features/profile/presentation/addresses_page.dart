import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/addresses_cubit.dart';
import '../models/client_location.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  Future<void> _openForm(BuildContext context, [ClientLocation? existing]) async {
    final draft = await showDialog<_AddressDraft>(
      context: context,
      builder: (_) => _AddressDialog(existing: existing),
    );
    if (draft == null || !context.mounted) return;
    final failure = await context.read<AddressesCubit>().save(
          id: existing?.id,
          name: draft.name,
          city: draft.city,
          address: draft.address,
          isDefault: draft.isDefault,
        );
    if (!context.mounted) return;
    if (failure == null) {
      showToast(context, tr('savedOK'));
      return;
    }
    showToast(context, failure.message, error: true);
  }

  Future<void> _remove(BuildContext context, ClientLocation location) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('deleteAddressTitle'), style: amiri(size: 15)),
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
    final failure = await context.read<AddressesCubit>().remove(location.id);
    if (!context.mounted) return;
    showToast(
      context,
      failure?.message ?? tr('deletedOK'),
      error: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddressesCubit>().state;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.greenDeep,
          onRefresh: () => context.read<AddressesCubit>().load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              BackHeader(tr('myAddresses')),
              if (state.loading && state.items.isEmpty)
                const SkeletonRows()
              else if (state.items.isEmpty)
                EmptyState(
                  Icons.location_on_outlined,
                  state.error ?? tr('emptyAddresses'),
                  cta: state.error == null ? tr('addAddress') : tr('retry'),
                  onCta: state.error == null
                      ? () => _openForm(context)
                      : () => context.read<AddressesCubit>().load(),
                )
              else
                for (final item in state.items)
                  _LocationCard(
                    item,
                    busy: state.busy,
                    onEdit: () => _openForm(context, item),
                    onDelete: () => _remove(context, item),
                    onDefault: () async {
                      final failure =
                          await context.read<AddressesCubit>().makeDefault(item.id);
                      if (!context.mounted || failure == null) return;
                      showToast(context, failure.message, error: true);
                    },
                  ),
              if (state.items.isNotEmpty) ...[
                const SizedBox(height: 4),
                AppButton(
                  tr('addAddress'),
                  onTap: state.busy ? null : () => _openForm(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final ClientLocation item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDefault;

  const _LocationCard(
    this.item, {
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onDefault,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final place = [item.city, item.address].where((part) => part.isNotEmpty).join(' — ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                item.name,
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
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenMid,
                ),
              ),
          ]),
          if (place.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(place, style: TextStyle(fontSize: 10, color: c.stone)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (!item.isDefault)
              _Link(tr('setDefault'), busy ? null : onDefault),
            _Link(tr('editAddress'), busy ? null : onEdit),
            _Link(tr('delete'), busy ? null : onDelete, danger: true),
          ]),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  const _Link(this.label, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: danger ? context.col.danger : AppColors.greenMid,
        ),
      ),
    );
  }
}

class _AddressDraft {
  final String name;
  final String city;
  final String address;
  final bool isDefault;
  const _AddressDraft(this.name, this.city, this.address, this.isDefault);
}

class _AddressDialog extends StatefulWidget {
  final ClientLocation? existing;
  const _AddressDialog({this.existing});

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _city = TextEditingController(text: existing?.city ?? '');
    _address = TextEditingController(text: existing?.address ?? '');
    _isDefault = existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      showToast(context, tr('fillRequired'), error: true);
      return;
    }
    Navigator.pop(
      context,
      _AddressDraft(
        _name.text.trim(),
        _city.text.trim(),
        _address.text.trim(),
        _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? tr('addAddress') : tr('editAddress'),
        style: amiri(size: 15),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppField(tr('addressName'), controller: _name),
            AppField(tr('city'), controller: _city),
            AppField(tr('addressLine'), controller: _address, maxLines: 2),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              activeColor: AppColors.greenDeep,
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
