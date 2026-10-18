import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/auth_gate.dart';
import '../../../core/network/result.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../home/cubit/home_cubit.dart';
import '../cubit/reports_cubit.dart';
import '../models/client_report.dart';
import 'report_viewer_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Future<void> _open(BuildContext context, ClientReport report) async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !context.mounted) return;
    final wasUnread = report.unread;
    final result = await context.read<ReportsCubit>().open(report);
    if (!context.mounted) return;
    switch (result) {
      case Err(:final failure):
        if (failure.code == 'BUSY') return;
        showToast(
          context,
          failure.statusCode != null ? failure.message : tr('reportDownloadFailed'),
          error: true,
        );
        return;
      case Success(:final data):
        if (wasUnread) context.read<HomeCubit>().load();
        if (report.isPdf) {
          context.push(
            AppRoutes.reportViewer,
            extra: ReportViewerArgs(path: data.path, title: report.title),
          );
          return;
        }
        final opened = await OpenFilex.open(data.path);
        if (!context.mounted) return;
        if (opened.type == ResultType.done) return;
        if (opened.type == ResultType.noAppToOpen) {
          showToast(context, tr('noAppToOpen'), error: true);
        } else {
          showToast(context, tr('reportOpenFailed'), error: true);
        }
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(data.path)],
            subject: report.title,
            title: report.title,
            sharePositionOrigin:
                box == null ? null : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportsCubit>().state;
    final c = context.col;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.ink,
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
                    _ReportCard(
                      report: report,
                      progress: state.progress[report.id],
                      saved: state.saved.contains(report.id),
                      onTap: report.available ? () => _open(context, report) : null,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ClientReport report;
  final double? progress;
  final bool saved;
  final VoidCallback? onTap;

  const _ReportCard({
    required this.report,
    required this.progress,
    required this.saved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return GestureDetector(
      onTap: progress == null ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
                Row(children: [
                  Flexible(
                    child: Text(
                      report.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  if (report.unread && report.available) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  report.meta,
                  style: TextStyle(fontSize: 9, color: c.stone),
                ),
              ],
            ),
          ),
          if (!report.available)
            GoldChip(tr('preparing'))
          else
            _ReportAction(progress: progress, saved: saved),
        ]),
      ),
    );
  }
}

/// Download → progress ring with percent → open, depending on the file state.
class _ReportAction extends StatelessWidget {
  final double? progress;
  final bool saved;
  const _ReportAction({required this.progress, required this.saved});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final dark = context.isDark;
    const size = 34.0;
    if (progress != null) {
      final value = progress!;
      return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value <= 0 ? null : value,
              strokeWidth: 2.5,
              color: c.accent,
              backgroundColor: c.accentSoft,
            ),
          ),
          Text(
            locNum((value * 100).round()),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
        ]),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(saved),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: saved ? c.accentSoft : (dark ? c.accentSoft : AppColors.greenDeep),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          saved ? Icons.visibility_outlined : Icons.download_outlined,
          size: 16,
          color: saved ? c.accent : (dark ? c.accent : AppColors.goldLight),
        ),
      ),
    );
  }
}
