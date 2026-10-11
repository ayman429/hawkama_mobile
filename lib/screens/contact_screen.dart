import 'package:flutter/material.dart';

import '../api/errors.dart';
import '../api/repo.dart';
import '../core/auth_gate.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ok = await ensureLoggedIn(context);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await Repo.sendSupportMessage(_subject.text.trim(), _message.text.trim());
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      showToast(context, tr('sentOK'));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBody(
      children: [
        AppTitleHeader(tr('contactUs')),
        const _ContactItem(
            icon: Icons.phone_outlined,
            value: AppConfig.contactPhone,
            ltr: true,
            labelKey: 'contactPhone'),
        const _ContactItem(
            icon: Icons.mail_outline,
            value: AppConfig.contactEmail,
            ltr: true,
            labelKey: 'contactMail'),
        const _ContactItem(
            icon: Icons.location_on_outlined,
            value: AppConfig.contactAddress,
            labelKey: 'contactBranch'),
        Container(
          decoration: cardDeco(context),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('sendMessage'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.col.text)),
              const SizedBox(height: 8),
              AppField(tr('subject'),
                  controller: _subject, hint: tr('subjectHint')),
              AppField(tr('message'),
                  controller: _message, hint: tr('messageHint'), maxLines: 4),
              AppButton(tr('send'),
                  variant: AppButtonVariant.gold,
                  loading: _busy,
                  onTap: _send),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String value, labelKey;
  final bool ltr;
  const _ContactItem({
    required this.icon,
    required this.value,
    required this.labelKey,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: cardDeco(context, radius: 10),
      child: Row(children: [
        IconBox(icon, size: 30, iconSize: 14, radius: 15),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                textDirection: ltr ? TextDirection.ltr : null,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.text)),
            Text(tr(labelKey),
                style: TextStyle(fontSize: 9, color: c.stone)),
          ],
        ),
      ]),
    );
  }
}
