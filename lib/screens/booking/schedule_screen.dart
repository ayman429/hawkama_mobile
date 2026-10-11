import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../api/repo.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../core/auth_gate.dart';
import '../../l10n/strings.dart';
import '../../state/booking_store.dart';
import '../../widgets/common.dart';
import 'confirm_screen.dart';

/// Wizard step 3 — month calendar from PUB-05 (available-dates) + slot grid
/// from PUB-06 (slots). Guests must sign in before continuing (mobile.md §7).
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _month; // first day of viewed month
  Set<String> _dates = {};
  List<Slot>? _slots;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final consultant = BookingStore.instance.consultant;
    if (consultant == null) return;
    try {
      final dates = await Repo.availableDates(consultant.id, ymOf(_month));
      if (mounted) setState(() => _dates = dates.toSet());
    } catch (_) {/* keep empty month */}
  }

  Future<void> _pickDay(String ymd) async {
    final store = BookingStore.instance;
    store.pickDate(ymd);
    setState(() {
      _slots = null;
      _loadingSlots = true;
    });
    try {
      final slots = await Repo.slots(store.consultant!.id, ymd);
      if (mounted) setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _slots = const [];
        _loadingSlots = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _dates = {};
    });
    _loadMonth();
  }

  Future<void> _continue() async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ConfirmScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final store = BookingStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final ready = store.readyForConfirm;
        return ScreenBody(children: [
          BackHeader(tr('chooseSlot')),
          const WizardSteps(2),
          _Calendar(
            month: _month,
            enabled: _dates,
            selected: store.date,
            onPick: _pickDay,
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            c: c,
          ),
          const SizedBox(height: 12),
          Text(
            store.date == null
                ? '${tr('availableTimes')} — ${tr('pickDayFirst')}'
                : '${tr('availableTimes')} — ${locDate(store.date!)}',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.greenMid),
          ),
          const SizedBox(height: 6),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (store.date != null && (_slots?.isEmpty ?? false))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text(tr('noSlots'),
                      style: TextStyle(fontSize: 10, color: c.stone))),
            )
          else if (_slots != null)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: [
                for (final s in _slots!)
                  _SlotChip(
                    slot: s,
                    selected: store.slot?.time == s.time,
                    onTap: () => store.pickSlot(s),
                    c: c,
                  ),
              ],
            )
          else
            const SizedBox(height: 20),
          const SizedBox(height: 14),
          AppButton(
            tr('next'),
            onTap: ready ? _continue : null,
          ),
        ]);
      },
    );
  }
}

class _Calendar extends StatelessWidget {
  final DateTime month;
  final Set<String> enabled;
  final String? selected;
  final ValueChanged<String> onPick;
  final VoidCallback onPrev, onNext;
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
    final firstWeekday = month.weekday % 7; // Sunday-first (mobile.md §3)
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final monthLabel = L10n.isAr
        ? '${kArMonths[month.month - 1]} ${arNum(month.year)}'
        : '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final header = L10n.isAr
        ? kArWeekHeader
        : const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Container(
      decoration: cardDeco(context, radius: 14),
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          _CalArrow(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              onPrev),
          const Spacer(),
          Text(monthLabel,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: c.text)),
          const Spacer(),
          _CalArrow(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              onNext),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          children: [
            for (final w in header)
              Center(
                child: Text(w,
                    style: TextStyle(
                        fontSize: 8,
                        color: c.stone,
                        fontWeight: FontWeight.w700)),
              ),
            for (var i = 0; i < firstWeekday; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              _DayCell(
                day: DateTime(month.year, month.month, d),
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
    final isSel = selected == ymd;
    return GestureDetector(
      onTap: on ? () => onPick(ymd) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSel
              ? AppColors.gold
              : on
                  ? c.chipBg
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(locNum(day.day),
            style: TextStyle(
              fontSize: 10,
              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
              color: isSel
                  ? Colors.white
                  : on
                      ? c.text
                      : c.mutedCal,
            )),
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
            color: c.chipBg, borderRadius: BorderRadius.circular(8)),
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
              color: selected ? AppColors.greenDeep : c.line, width: 1.5),
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
