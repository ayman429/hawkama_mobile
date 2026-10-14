import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth_gate.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/reports_cubit.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportsCubit>().state;
    final c = context.col;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.greenDeep,
          onRefresh: () => context.read<ReportsCubit>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTitleHeader(tr('reportsTitle')),
                if (state.status == ListStatus.guest)
                  EmptyState(
                    Icons.lock_outline,
                    tr('loginToContinue'),
                    cta: tr('doLogin'),
                    onCta: () => ensureLoggedIn(context),
                  )
                else if (state.status == ListStatus.loading)
                  const SkeletonRows()
                else if (state.items.isEmpty)
                  EmptyState(Icons.description_outlined, tr('emptyReports'))
                else
                  for (final report in state.items)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: cardDeco(context),
                      child: Row(children: [
                        const IconBox(Icons.description_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                report.meta,
                                style: TextStyle(fontSize: 9, color: c.stone),
                              ),
                            ],
                          ),
                        ),
                        if (report.available)
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final ok = await ensureLoggedIn(context);
                              if (!ok || !context.mounted) return;
                              showToast(
                                context,
                                tr('download'),
                                icon: Icons.download_outlined,
                              );
                            },
                            child: const IconBox(
                              Icons.download_outlined,
                              size: 34,
                              iconSize: 15,
                            ),
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
