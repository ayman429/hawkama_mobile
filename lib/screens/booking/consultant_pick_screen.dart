import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../api/repo.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../l10n/strings.dart';
import '../../state/booking_store.dart';
import '../../widgets/common.dart';
import 'schedule_screen.dart';

/// Wizard step 2 — consultants from GET /public/consultants (PUB-03).
class ConsultantPickScreen extends StatefulWidget {
  const ConsultantPickScreen({super.key});

  @override
  State<ConsultantPickScreen> createState() => _ConsultantPickScreenState();
}

class _ConsultantPickScreenState extends State<ConsultantPickScreen> {
  List<Consultant>? _consultants;

  @override
  void initState() {
    super.initState();
    Repo.consultants().then((v) {
      if (mounted) setState(() => _consultants = v);
    }).catchError((_) {
      if (mounted) setState(() => _consultants = const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final store = BookingStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return ScreenBody(children: [
          BackHeader(tr('chooseConsultant')),
          const WizardSteps(1),
          if (_consultants == null)
            const SkeletonRows()
          else
            for (final s in _consultants!)
              _ConsultantPick(
                staff: s,
                selected: store.consultant?.id == s.id,
                onTap: () => store.pickConsultant(s),
                c: c,
              ),
          AppButton(
            tr('next'),
            onTap: store.consultant == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ScheduleScreen())),
          ),
        ]);
      },
    );
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
          border: Border.all(
              color: selected ? AppColors.gold : c.line, width: 1.5),
        ),
        child: Row(children: [
          PersonAvatar(initialOf(staff.name)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.text)),
                const SizedBox(height: 2),
                Text(
                    staff.title.isEmpty ? staff.specialization : staff.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: c.stone)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, size: 12, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text(staff.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold)),
                  Flexible(
                    child: Text(' · ${staff.jobsLabel}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: c.stone)),
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
