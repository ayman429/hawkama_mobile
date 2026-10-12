import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../booking/cubit/booking_draft_cubit.dart';
import '../cubit/packages_cubit.dart';
import '../models/consult_package.dart';
import '../models/subscription.dart';

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PackagesCubit>().state;
    final c = context.col;
    return ScreenBody(
      bottomPad: 96,
      children: [
        AppTitleHeader(tr('packagesTitle')),
        if (state.packages == null)
          const SkeletonRows()
        else
          for (final package in state.packages!)
            _PackageCard(
              pkg: package,
              current: state.subscriptions
                  .where((item) => item.isActive)
                  .map((item) => item.package.id)
                  .contains(package.id),
              subscription: state.subscriptions
                  .where((item) => item.isActive && item.package.id == package.id)
                  .firstOrNull,
              onPick: () {
                final draft = context.read<BookingDraftCubit>();
                draft.reset();
                draft.pickPackage(package);
                context.push(AppRoutes.bookingConsultant);
              },
              c: c,
            ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ConsultPackage pkg;
  final bool current;
  final Subscription? subscription;
  final VoidCallback onPick;
  final AppColors c;

  const _PackageCard({
    required this.pkg,
    required this.current,
    required this.subscription,
    required this.onPick,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final features = pkg.features;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? AppColors.gold : c.line),
        gradient: current
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.pickOn, c.surface],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(
                    pkg.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ),
                if (current) ...[
                  const SizedBox(width: 6),
                  GoldChip(tr('currentBadge')),
                ],
              ]),
            ),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${_priceOnly(pkg.priceFormatted)} ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                TextSpan(
                  text: tr('perMonth'),
                  style: TextStyle(fontSize: 9, color: c.stone),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                const Text(
                  '✓',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(feature, style: TextStyle(fontSize: 10, color: c.stone)),
                ),
              ]),
            ),
          if (pkg.isUnlimited && features.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(tr('unlimited'), style: TextStyle(fontSize: 10, color: c.stone)),
            ),
          const SizedBox(height: 8),
          if (current && (subscription?.canBook ?? false))
            AppButton(tr('bookSession'), onTap: onPick)
          else
            AppButton(
              current ? tr('currentPlan') : tr('choosePlan'),
              variant: current ? AppButtonVariant.primary : AppButtonVariant.outline,
              onTap: current ? () {} : onPick,
            ),
        ],
      ),
    );
  }

  String _priceOnly(String formatted) {
    final number = formatted.split(' ').first.replaceAll('.00', '');
    return locNum(number);
  }
}
