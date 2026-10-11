import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/repo.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../state/booking_store.dart';
import '../widgets/common.dart';
import 'booking/consultant_pick_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<ConsultPackage>? _packages;
  List<Subscription> _subs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pkgs = await Repo.packages();
      final subs = AuthStore.instance.isAuthed
          ? await Repo.activeSubscriptions()
          : const <Subscription>[];
      if (mounted) setState(() {
        _packages = pkgs;
        _subs = subs;
      });
    } catch (_) {
      if (mounted) setState(() => _packages = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return ScreenBody(
      bottomPad: 96,
      children: [
        AppTitleHeader(tr('packagesTitle')),
        if (_packages == null)
          const SkeletonRows()
        else
          for (final p in _packages!)
            _PackageCard(
              pkg: p,
              current: _subs
                  .where((s) => s.isActive)
                  .map((s) => s.package.id)
                  .contains(p.id),
              subscription: _subs
                  .where((s) => s.isActive && s.package.id == p.id)
                  .firstOrNull,
              onPick: () {
                final store = BookingStore.instance;
                store.reset();
                store.pickPackage(p);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConsultantPickScreen()));
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
                colors: [c.pickOn, c.surface])
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(pkg.name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.text)),
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
                    text: _priceOnly(pkg.priceFormatted) + ' ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.text)),
                TextSpan(
                    text: tr('perMonth'),
                    style: TextStyle(fontSize: 9, color: c.stone)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                const Text('✓',
                    style: TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(f,
                        style: TextStyle(fontSize: 10, color: c.stone))),
              ]),
            ),
          if (pkg.isUnlimited && features.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(tr('unlimited'),
                  style: TextStyle(fontSize: 10, color: c.stone)),
            ),
          const SizedBox(height: 8),
          if (current && (subscription?.canBook ?? false))
            AppButton(tr('bookSession'), onTap: onPick)
          else
            AppButton(
              current ? tr('currentPlan') : tr('choosePlan'),
              variant: current
                  ? AppButtonVariant.primary
                  : AppButtonVariant.outline,
              onTap: current ? () {} : onPick,
            ),
        ],
      ),
    );
  }

  String _priceOnly(String formatted) {
    // "1,900.00 SAR" → "١٬٩٠٠" (ar) / "1,900" (en)
    final n = formatted.split(' ').first.replaceAll('.00', '');
    return locNum(n);
  }
}
