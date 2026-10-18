import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';

/// Arguments for the in-app report viewer route.
class ReportViewerArgs {
  final String path;
  final String title;
  const ReportViewerArgs({required this.path, required this.title});
}

class ReportViewerPage extends StatefulWidget {
  final ReportViewerArgs args;
  const ReportViewerPage({super.key, required this.args});

  @override
  State<ReportViewerPage> createState() => _ReportViewerPageState();
}

class _ReportViewerPageState extends State<ReportViewerPage> {
  int? _page;
  int? _pages;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(widget.args.path, mimeType: 'application/pdf')],
        subject: widget.args.title,
        title: widget.args.title,
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final dark = context.isDark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              _RoundButton(
                icon: rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(children: [
                  Text(
                    widget.args.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  if (_pages != null)
                    Text(
                      '${locNum(_pages!)} ${tr('pagesUnit')}',
                      style: TextStyle(fontSize: 11, color: c.stone),
                    ),
                ]),
              ),
              const SizedBox(width: 10),
              Builder(
                builder: (btnContext) => _RoundButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _share(btnContext),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Stack(children: [
              PdfViewer.file(
                widget.args.path,
                params: PdfViewerParams(
                  margin: 14,
                  backgroundColor:
                      dark ? const Color(0xFF0B0F0E) : const Color(0xFFEEF2F0),
                  pageDropShadow: BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? .5 : .12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  onViewerReady: (document, controller) {
                    if (!mounted) return;
                    setState(() {
                      _pages = document.pages.length;
                      _page = controller.pageNumber ?? 1;
                    });
                  },
                  onPageChanged: (page) {
                    if (mounted && page != null) setState(() => _page = page);
                  },
                  loadingBannerBuilder: (context, downloaded, total) => Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                  ),
                  errorBannerBuilder: (context, error, stack, ref) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(Icons.error_outline_rounded, tr('reportOpenFailed')),
                    ),
                  ),
                ),
              ),
              if (_page != null && _pages != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${locNum(_page!)} / ${locNum(_pages!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.card,
            shape: BoxShape.circle,
            border: Border.all(color: context.isDark ? c.hairline : c.line),
          ),
          child: Icon(icon, size: 20, color: c.text),
        ),
      ),
    );
  }
}
