import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/booking_draft_cubit.dart';
import '../cubit/wizard_cubits.dart';
import '../models/consultant.dart';

class ConsultantPickPage extends StatelessWidget {
  const ConsultantPickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final consultants = context.watch<ConsultantsCubit>().state;
    final draft = context.watch<BookingDraftCubit>().state;
    final c = context.col;
    return ScreenBody(children: [
      BackHeader(tr('chooseConsultant')),
      const WizardSteps(1),
      if (consultants == null)
        const SkeletonRows()
      else
        for (final staff in consultants)
          _ConsultantPick(
            staff: staff,
            selected: draft.consultant?.id == staff.id,
            onTap: () => context.read<BookingDraftCubit>().pickConsultant(staff),
            c: c,
          ),
      AppButton(
        tr('next'),
        onTap: draft.consultant == null
            ? null
            : () => context.push(AppRoutes.bookingSchedule),
      ),
    ]);
  }
}

class _ConsultantPick extends StatelessWidget {
  final Consultant staff;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  const _ConsultantPick({
    required this.staff,
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
          PersonAvatar(avatarInitial(staff.name)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  staff.title.isEmpty ? staff.specialization : staff.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: c.stone),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, size: 12, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text(
                    staff.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      ' · ${staff.jobsText}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: c.stone),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          RadioDot(selected),
        ]),
      ),
    );
  }
}
