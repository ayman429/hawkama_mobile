import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../packages/models/consult_package.dart';
import '../cubit/booking_draft_cubit.dart';
import '../cubit/wizard_cubits.dart';

class ServicePickPage extends StatelessWidget {
  const ServicePickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final packages = context.watch<WizardPackagesCubit>().state;
    final draft = context.watch<BookingDraftCubit>().state;
    final c = context.col;
    return ScreenBody(children: [
      BackHeader(tr('chooseService')),
      const WizardSteps(0),
      if (packages == null)
        const SkeletonRows()
      else
        for (final package in packages)
          _PackagePick(
            pkg: package,
            selected: draft.package?.id == package.id,
            onTap: () => context.read<BookingDraftCubit>().pickPackage(package),
            c: c,
          ),
      AppButton(
        tr('next'),
        onTap: draft.package == null
            ? null
            : () => context.push(AppRoutes.bookingConsultant),
      ),
    ]);
  }
}

class _PackagePick extends StatelessWidget {
  final ConsultPackage pkg;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  const _PackagePick({
    required this.pkg,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? c.pickOn : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.gold : c.line, width: 1.5),
        ),
        child: Row(children: [
          const IconBox(Icons.work_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.name,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  pkg.isUnlimited
                      ? '${tr('unlimited')} · ${pkg.priceFormatted}'
                      : '${pkg.features.isNotEmpty ? pkg.features.first : pkg.name} · ${pkg.priceFormatted}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: c.stone),
                ),
              ],
            ),
          ),
          RadioDot(selected),
        ]),
      ),
    );
  }
}
