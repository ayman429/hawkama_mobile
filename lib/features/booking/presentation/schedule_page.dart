import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/booking_draft_cubit.dart';
import '../cubit/wizard_cubits.dart';
import '../models/slot.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  Future<void> _pickDay(BuildContext context, String ymd) async {
    final consultant = context.read<BookingDraftCubit>().state.consultant;
    if (consultant == null) return;
    context.read<BookingDraftCubit>().pickDate(ymd);
    await context.read<ScheduleCubit>().loadSlots(consultant.id, ymd);
  }

  Future<void> _continue(BuildContext context) async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !context.mounted) return;
    context.push(AppRoutes.bookingConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleCubit>().state;
    final draft = context.watch<BookingDraftCubit>().state;
    final c = context.col;
    return ScreenBody(children: [
      BackHeader(tr('chooseSlot')),
      const WizardSteps(2),
      _Calendar(
        month: schedule.month,
        enabled: schedule.dates.toSet(),
        selected: draft.date,
        onPick: (ymd) => _pickDay(context, ymd),
        onPrev: () {
          final id = draft.consultant?.id;
          if (id != null) context.read<ScheduleCubit>().changeMonth(id, -1);
        },
        onNext: () {
          final id = draft.consultant?.id;
          if (id != null) context.read<ScheduleCubit>().changeMonth(id, 1);
        },
        c: c,
      ),
      const SizedBox(height: 12),
      Text(
        draft.date == null
            ? '${tr('availableTimes')} — ${tr('pickDayFirst')}'
            : '${tr('availableTimes')} — ${locDate(draft.date!)}',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.greenMid,
        ),
      ),
      const SizedBox(height: 6),
      if (schedule.loadingSlots)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else if (draft.date != null && (schedule.slots?.isEmpty ?? false))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(tr('noSlots'), style: TextStyle(fontSize: 10, color: c.stone)),
          ),
        )
      else if (schedule.slots != null)
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            for (final slot in schedule.slots!)
              _SlotChip(
                slot: slot,
                selected: draft.slot?.time == slot.time,
                onTap: () => context.read<BookingDraftCubit>().pickSlot(slot),
                c: c,
              ),
          ],
        )
      else
        const SizedBox(height: 20),
      const SizedBox(height: 14),
      AppButton(
        tr('next'),
        onTap: draft.readyForConfirm ? () => _continue(context) : null,
      ),
    ]);
  }
}

class _Calendar extends StatelessWidget {
  final DateTime month;
  final Set<String> enabled;
  final String? selected;
  final ValueChanged<String> onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final AppColors c;

  const _Calendar({
    required this.month,
    required this.enabled,
    required this.selected,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = month.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final monthLabel = '${locMonths[month.month - 1]} ${locNum(month.year)}';
    final header = locWeekHeader;

    return Container(
      decoration: cardDeco(context, radius: 14),
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          _CalArrow(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_right
                : Icons.chevron_left,
            onPrev,
          ),
          const Spacer(),
          Text(
            monthLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.text),
          ),
          const Spacer(),
          _CalArrow(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            onNext,
          ),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          children: [
            for (final label in header)
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: c.stone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (var i = 0; i < firstWeekday; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _DayCell(
                day: DateTime(month.year, month.month, day),
                enabled: enabled,
                selected: selected,
                onPick: onPick,
                c: c,
              ),
          ],
        ),
      ]),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Set<String> enabled;
  final String? selected;
  final ValueChanged<String> onPick;
  final AppColors c;

  const _DayCell({
    required this.day,
    required this.enabled,
    required this.selected,
    required this.onPick,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final ymd = ymdOf(day);
    final on = enabled.contains(ymd);
    final isSelected = selected == ymd;
    return GestureDetector(
      onTap: on ? () => onPick(ymd) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : on
                  ? c.chipBg
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          locNum(day.day),
          style: TextStyle(
            fontSize: 10,
            fontWeight: on ? FontWeight.w700 : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : on
                    ? c.text
                    : c.mutedCal,
          ),
        ),
      ),
    );
  }
}

class _CalArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalArrow(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: c.chipBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: c.text),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final Slot slot;
  final bool selected;
  final VoidCallback onTap;
  final AppColors c;

  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDeep : c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.greenDeep : c.line,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          slot.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : c.text,
          ),
        ),
      ),
    );
  }
}
