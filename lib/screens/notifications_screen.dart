import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/repo.dart';
import '../core/auth_gate.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<ClientNotif>? _notifs;

  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthStore.instance.isAuthed) {
      setState(() => _notifs = const []);
      return;
    }
    try {
      final list = await Repo.notifications();
      if (mounted) setState(() => _notifs = list);
    } catch (_) {
      if (mounted) setState(() => _notifs = const []);
    }
  }

  Future<void> _markAll() async {
    await Repo.markAllNotifsRead();
    setState(() {
      _notifs = [
        for (final n in _notifs ?? const <ClientNotif>[])
          ClientNotif(
              id: n.id,
              title: n.title,
              body: n.body,
              timeLabel: n.timeLabel,
              type: n.type,
              unread: false),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final hasUnread = _notifs?.any((n) => n.unread) ?? false;
    return ScreenBody(
      children: [
        AppTitleHeader(tr('notifsTitle')),
        if (hasUnread)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _markAll,
              child: Text(tr('markAllRead'),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenMid)),
            ),
          ),
        if (!AuthStore.instance.isAuthed)
          EmptyState(Icons.lock_outline, tr('loginToContinue'),
              cta: tr('doLogin'),
              onCta: () async {
                final ok = await ensureLoggedIn(context);
                if (ok && mounted) _load();
              })
        else if (_notifs == null)
          const SkeletonRows()
        else if (_notifs!.isEmpty)
          EmptyState(Icons.notifications_outlined, tr('emptyNotifs'))
        else
          for (final n in _notifs!) _NotifRow(n, c: c),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  final ClientNotif n;
  final AppColors c;
  const _NotifRow(this.n, {required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Repo.markNotifRead(n.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            if (n.unread) Container(width: 3, color: AppColors.gold),
            if (n.unread) const SizedBox(width: 9),
            IconBox(n.icon, size: 32, iconSize: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (n.unread)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.gold),
                      ),
                    Flexible(
                      child: Text(n.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: c.text)),
                    ),
                    const Spacer(),
                    Text(n.timeLabel,
                        style: TextStyle(fontSize: 8.5, color: c.stone)),
                  ]),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: TextStyle(
                          fontSize: 9.5, color: c.stone, height: 1.6)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
