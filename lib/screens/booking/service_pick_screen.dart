import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../api/repo.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../state/booking_store.dart';
import '../../widgets/common.dart';
import 'consultant_pick_screen.dart';

/// Wizard step 1 — package/offer list from GET /public/packages
/// (mobile.md §7 reconciliation table).
class ServicePickScreen extends StatefulWidget {
  const ServicePickScreen({super.key});

  @override
  State<ServicePickScreen> createState() => _ServicePickScreenState();
}

class _ServicePickScreenState extends State<ServicePickScreen> {
  List<ConsultPackage>? _packages;

  @override
  void initState() {
    super.initState();
    Repo.packages().then((v) {
      if (mounted) setState(() => _packages = v);
    }).catchError((_) {
      if (mounted) setState(() => _packages = const []);
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
          BackHeader(tr('chooseService')),
          const WizardSteps(0),
          if (_packages == null)
            const SkeletonRows()
          else
            for (final p in _packages!)
              _PackagePick(
                pkg: p,
                selected: store.package?.id == p.id,
                onTap: () => store.pickPackage(p),
                c: c,
              ),
          AppButton(
            tr('next'),
            onTap: store.package == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConsultantPickScreen())),
          ),
        ]);
      },
    );
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
          border: Border.all(
              color: selected ? AppColors.gold : c.line, width: 1.5),
        ),
        child: Row(children: [
          const IconBox(Icons.work_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg.name,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.text)),
                const SizedBox(height: 2),
                Text(
                    pkg.isUnlimited
                        ? '${tr('unlimited')} · ${pkg.priceFormatted}'
                        : '${pkg.features.isNotEmpty ? pkg.features.first : pkg.name} · ${pkg.priceFormatted}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: c.stone)),
              ],
            ),
          ),
          RadioDot(selected),
        ]),
      ),
    );
  }
}
