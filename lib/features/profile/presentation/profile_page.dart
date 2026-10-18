import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_gate.dart';
import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../shell/cubit/shell_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth.user;
    return AnimatedBuilder(
      animation: Listenable.merge([L10n.locale, ThemeState.mode]),
      builder: (context, _) {
        final c = context.col;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: cardDeco(
                      context,
                      radius: 16,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.heroFrom, c.heroTo],
                      ),
                    ),
                    child: Row(children: [
                      PersonAvatar(
                        avatarInitial(user?.name ?? tr('guest')),
                        size: 48,
                        fontSize: 17,
                        gold: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? tr('guest'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  _MenuItem(Icons.edit_outlined, tr('personalData'), () async {
                    final ok = await ensureLoggedIn(context);
                    if (!ok || !context.mounted) return;
                    context.push(AppRoutes.personalData);
                  }),
                  _MenuItem(Icons.location_on_outlined, tr('myAddresses'), () async {
                    final ok = await ensureLoggedIn(context);
                    if (!ok || !context.mounted) return;
                    context.push(AppRoutes.addresses);
                  }),
                  _MenuItem(Icons.credit_card_outlined, tr('paymentMethods'), () async {
                    final ok = await ensureLoggedIn(context);
                    if (!ok || !context.mounted) return;
                    context.push(AppRoutes.paymentMethods);
                  }),
                  _MenuItem(Icons.notifications_outlined, tr('notifsTitle'), () async {
                    final ok = await ensureLoggedIn(context);
                    if (!ok || !context.mounted) return;
                    context.push(AppRoutes.notifications);
                  }),
                  _MenuItem(Icons.chat_bubble_outline, tr('contactUs'), () {
                    context.push(AppRoutes.contact);
                  }),
                  _MenuItem(
                    Icons.translate_outlined,
                    tr('language'),
                    () => _showLangPicker(context),
                    trailing: Text(
                      L10n.isAr ? tr('langAr') : tr('langEn'),
                      style: TextStyle(fontSize: 10, color: c.stone),
                    ),
                  ),
                  _MenuItem(
                    Icons.dark_mode_outlined,
                    tr('theme'),
                    () => _showThemePicker(context),
                  ),
                  if (auth.isAuthed)
                    _MenuItem(
                      Icons.logout,
                      tr('logout'),
                      () => _confirmLogout(context),
                      danger: true,
                    )
                  else
                    _MenuItem(Icons.login, tr('doLogin'), () => ensureLoggedIn(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLangPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('language'), style: amiri(size: 15)),
        children: [
          _option(ctx, tr('langAr'), L10n.isAr, () => L10n.set(const Locale('ar'))),
          _option(ctx, tr('langEn'), !L10n.isAr, () => L10n.set(const Locale('en'))),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('theme'), style: amiri(size: 15)),
        children: [
          _option(
            ctx,
            tr('themeSystem'),
            ThemeState.mode.value == ThemeMode.system,
            () => ThemeState.setMode(ThemeMode.system),
          ),
          _option(
            ctx,
            tr('themeLight'),
            ThemeState.mode.value == ThemeMode.light,
            () => ThemeState.setMode(ThemeMode.light),
          ),
          _option(
            ctx,
            tr('themeDark'),
            ThemeState.mode.value == ThemeMode.dark,
            () => ThemeState.setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext ctx,
    String label,
    bool selected,
    Future<void> Function() pick,
  ) {
    return SimpleDialogOption(
      onPressed: () async {
        await pick();
        if (ctx.mounted) Navigator.pop(ctx);
      },
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
        if (selected) const Icon(Icons.check, size: 16, color: AppColors.gold),
      ]),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final c = context.col;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('logout'), style: amiri(size: 15)),
        content: Text(tr('logoutConfirm'), style: const TextStyle(fontSize: 11)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('logout'), style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthCubit>().signOut();
    if (!context.mounted) return;
    context.read<ShellCubit>().select(0);
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final Widget? trailing;

  const _MenuItem(this.icon, this.label, this.onTap, {this.danger = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final fg = danger ? c.danger : c.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: cardDeco(context),
        child: Row(children: [
          danger ? IconBox(Icons.logout, bg: c.dangerBg, fg: c.danger) : IconBox(icon),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            size: 16,
            color: c.stone,
          ),
        ]),
      ),
    );
  }
}
