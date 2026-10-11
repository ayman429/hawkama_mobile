import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/repo.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<ClientReport>? _reports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AuthStore.instance.isAuthed) {
      setState(() => _reports = const []);
      return;
    }
    try {
      final list = await Repo.reports();
      if (mounted) setState(() => _reports = list);
    } catch (_) {
      if (mounted) setState(() => _reports = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.greenDeep,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTitleHeader(tr('reportsTitle')),
                if (!AuthStore.instance.isAuthed)
                  EmptyState(Icons.lock_outline, tr('loginToContinue'),
                      cta: tr('doLogin'),
                      onCta: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())))
                else if (_reports == null)
                  const SkeletonRows()
                else if (_reports!.isEmpty)
                  EmptyState(Icons.description_outlined, tr('emptyReports'))
                else
                  for (final r in _reports!)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: cardDeco(context),
                      child: Row(children: [
                        const IconBox(Icons.description_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c.text)),
                              const SizedBox(height: 2),
                              Text(r.meta,
                                  style: TextStyle(
                                      fontSize: 9, color: c.stone)),
                            ],
                          ),
                        ),
                        if (r.available)
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              // Download needs the Bearer token — native: use
                              // `dio.download` + save to app dir, then
                              // share_plus; see README.
                              showToast(context, tr('download'),
                                  icon: Icons.download_outlined);
                            },
                            child: const IconBox(Icons.download_outlined,
                                size: 34, iconSize: 15),
                          )
                        else
                          GoldChip(tr('preparing')),
                      ]),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
