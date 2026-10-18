import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth_gate.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/notifications_cubit.dart';
import '../models/client_notif.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    final c = context.col;
    return ScreenBody(
      children: [
        AppTitleHeader(tr('notifsTitle')),
        if (state.hasUnread)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => context.read<NotificationsCubit>().markAllRead(),
              child: Text(
                tr('markAllRead'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
              ),
            ),
          ),
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
          EmptyState(Icons.notifications_outlined, tr('emptyNotifs'))
        else
          for (final item in state.items) _NotifRow(item, c: c),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  final ClientNotif item;
  final AppColors c;
  const _NotifRow(this.item, {required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NotificationsCubit>().markRead(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: cardDeco(context),
        child: IntrinsicHeight(
          child: Row(children: [
            if (item.unread) Container(width: 3, color: AppColors.gold),
            if (item.unread) const SizedBox(width: 9),
            IconBox(item.icon, size: 32, iconSize: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (item.unread)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        item.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.timeLabel,
                      style: TextStyle(fontSize: 8.5, color: c.stone),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: TextStyle(fontSize: 9.5, color: c.stone, height: 1.6),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
