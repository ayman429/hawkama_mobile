import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme.dart';
import 'app_backdrop.dart';
import '../../l10n/strings.dart';

/// Floating glass card: lit rim, translucent fill, soft lift. Shared by every content card.
BoxDecoration cardDeco(
  BuildContext context, {
  double radius = 12,
  Color? border,
  Color? fill,
  Gradient? gradient,
}) {
  final dark = context.isDark;
  final c = context.col;
  return BoxDecoration(
    color: gradient == null ? (fill ?? c.card) : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? c.hairline),
    boxShadow: [
      BoxShadow(
        color: dark
            ? Colors.black.withValues(alpha: .45)
            : const Color(0xFF14382E).withValues(alpha: .09),
        blurRadius: dark ? 26 : 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

void showToast(BuildContext context, String message,
    {bool error = false, IconData? icon}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB3402F) : context.col.primaryFill,
      content: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(message, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ]),
    ));
}

// ═══════════════════════ Brand ═══════════════════════

/// Logo badge placeholder for `/logo_icon.png` (mobile.md §3/§8).
class LogoMark extends StatelessWidget {
  final double size, iconSize;
  const LogoMark({super.key, this.size = 34, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.goldSoft,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: c.goldLine),
      ),
      child: Icon(Icons.verified_user, size: iconSize, color: c.ink),
    );
  }
}

// ═══════════════════════ Headers (§2.4) ═══════════════════════

/// `.app-header`: logo + brand + page subtitle (tab-level pages, no back).
class AppTitleHeader extends StatelessWidget {
  final String sub;
  const AppTitleHeader(this.sub, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        const LogoMark(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('brand'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: c.text)),
            Text(sub, style: TextStyle(fontSize: 10, color: c.stone)),
          ]),
        ),
      ]),
    );
  }
}

/// `.bhd`: 34px bordered back button, centered title, balancing spacer.
class BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const BackHeader(this.title, {super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onBack ?? () => Navigator.maybePop(context),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.isDark ? c.hairline : c.line),
            ),
            child: Icon(rtl ? Icons.chevron_right : Icons.chevron_left,
                size: 20, color: c.text),
          ),
        ),
        Expanded(
          child: Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
        ),
        const SizedBox(width: 34),
      ]),
    );
  }
}

/// `.sec-hd`
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.accent)),
          ),
      ]),
    );
  }
}

// ═══════════════════════ Buttons (.btn) ═══════════════════════

enum AppButtonVariant { primary, gold, outline, dangerOutline, ghostOnDark }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final double padV, fontSize;
  final bool loading;
  const AppButton(this.label,
      {super.key,
      this.onTap,
      this.variant = AppButtonVariant.primary,
      this.padV = 11,
      this.fontSize = 12,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    late final Color bg, fg, border;
    switch (variant) {
      case AppButtonVariant.primary:
        bg = c.primaryFill;
        fg = Colors.white;
        border = bg;
        break;
      case AppButtonVariant.gold:
        bg = AppColors.gold;
        fg = AppColors.greenDarker;
        border = bg;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = c.text;
        border = c.text;
        break;
      case AppButtonVariant.dangerOutline:
        bg = Colors.transparent;
        fg = c.danger;
        border = c.danger;
        break;
      case AppButtonVariant.ghostOnDark:
        bg = Colors.transparent;
        fg = Colors.white;
        border = Colors.white.withValues(alpha: .35);
        break;
    }
    return Opacity(
      opacity: onTap == null ? .45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: loading ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fg))
              : Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: fg,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ═══════════════════════ Badges / icons / avatars ═══════════════════════

/// Booking status badge — colors per API guide §7.1.
class StatusBadge extends StatelessWidget {
  final String status; // pending | pending_payment | completed | cancelled
  final String label;
  const StatusBadge(this.status, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final Color bg, fg, border;
    switch (status) {
      case 'pending_payment':
        bg = c.goldSoft;
        fg = c.goldText;
        border = c.goldLine;
        break;
      case 'cancelled':
        bg = c.dangerBg;
        fg = c.danger;
        border = c.dangerLine;
        break;
      case 'pending':
      case 'completed':
      default:
        bg = c.doneBg;
        fg = c.doneText;
        border = c.doneText.withValues(alpha: .25);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

/// Gold-tinted chip (e.g. «قيد الإعداد»).
class GoldChip extends StatelessWidget {
  final String text;
  const GoldChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.goldSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.goldLine),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: c.goldText)),
    );
  }
}

/// `.mi-ic` icon tile (deep green bg, gold-light icon).
class IconBox extends StatelessWidget {
  final IconData icon;
  final double size, iconSize, radius;
  final Color? bg, fg;
  const IconBox(this.icon,
      {super.key,
      this.size = 34,
      this.iconSize = 16,
      this.radius = 10,
      this.bg,
      this.fg});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final c = context.col;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: bg ?? (dark ? c.accentSoft : AppColors.greenDeep),
          borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon,
          size: iconSize,
          color: fg ?? (dark ? c.accent : AppColors.goldLight)),
    );
  }
}

/// `.avatar` — Ø40 deep-green circle with gold initial (or gold variant).
class PersonAvatar extends StatelessWidget {
  final String initial;
  final double size, fontSize;
  final bool gold;
  const PersonAvatar(this.initial,
      {super.key, this.size = 40, this.fontSize = 15, this.gold = false});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final c = context.col;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold
              ? AppColors.gold
              : (dark ? c.accentSoft : AppColors.greenDeep)),
      alignment: Alignment.center,
      child: Text(initial,
          style: TextStyle(
              color: gold
                  ? AppColors.greenDarker
                  : (dark ? c.accent : AppColors.goldLight),
              fontWeight: FontWeight.w800,
              fontSize: fontSize)),
    );
  }
}

/// `.radio` trailing dot on `.pick` rows.
class RadioDot extends StatelessWidget {
  final bool selected;
  const RadioDot(this.selected, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? AppColors.gold : c.line, width: 2),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.gold))
          : null,
    );
  }
}

// ═══════════════════════ Forms (.field / .tabs) ═══════════════════════

class AppField extends StatelessWidget {
  final String label;
  final String? hint, errorText;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  const AppField(this.label,
      {super.key,
      this.hint,
      this.errorText,
      this.obscure = false,
      this.controller,
      this.keyboardType,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final ltr = keyboardType == TextInputType.emailAddress ||
        keyboardType == TextInputType.phone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.isDark ? c.stone : AppColors.greenMid)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textDirection: ltr ? TextDirection.ltr : null,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 11, color: c.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11, color: c.stone),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.line)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.accent)),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!,
                style: TextStyle(fontSize: 9, color: c.danger)),
          ),
      ]),
    );
  }
}

// ═══════════════════════ Wizard steps (.steps) ═══════════════════════

class WizardSteps extends StatelessWidget {
  final int active;
  const WizardSteps(this.active, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final labels = [
      tr('stepService'),
      tr('stepConsultant'),
      tr('stepSlot'),
      tr('stepConfirm')
    ];
    final children = <Widget>[];
    for (var i = 0; i < 4; i++) {
      final on = i <= active;
      if (i > 0) {
        children.add(Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.only(top: 12, left: 4, right: 4),
            color: on ? c.ink : c.line,
          ),
        ));
      }
      children.add(Column(children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? c.primaryFill : c.surface,
            border: Border.all(
                color: on ? c.primaryFill : c.line, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(locNum(i + 1),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: on
                      ? (context.isDark ? Colors.white : AppColors.goldLight)
                      : c.stone)),
        ),
        const SizedBox(height: 4),
        Text(labels[i],
            style: TextStyle(
                fontSize: 8,
                fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                color: on ? c.ink : c.stone)),
      ]));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

// ═══════════════════════ States (mobile.md §6) ═══════════════════════

/// Logo animation loading widget - replaces SkeletonPulse for data loading states
class LogoLoadingWidget extends StatelessWidget {
  final double? size;
  const LogoLoadingWidget({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height/1.5,
      child: Center(
        child: Image.asset(
          'assets/animation/logo_animation.gif',
          width:  50,
          height:  50,
          fit: BoxFit.contain,
        ),
        // OLD: Lottie.asset(
        //   'assets/animation/logo_animation.json',
        //   width:  200,
        //   height:  200,
        //   fit: BoxFit.contain,
        // ),
      ),
    );
  }
}


/// Inner loading bars use the same pale green as the app wash.
Color _skeletonBone(BuildContext context, double t) {
  final dark = context.isDark;
  final from = dark ? const Color(0xFF1F2725) : const Color(0xFFE7F4EE);
  final to = dark ? const Color(0xFF2B3734) : const Color(0xFFC5E3D6);
  return Color.lerp(from, to, t)!;
}

/// Soft pulse shared by loading placeholders.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _SkeletonTick(
        t: Curves.easeInOut.transform(_controller.value),
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class _SkeletonTick extends InheritedWidget {
  final double t;
  const _SkeletonTick({required this.t, required super.child});

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_SkeletonTick>()?.t ?? 1;
  }

  @override
  bool updateShouldNotify(_SkeletonTick oldWidget) => t != oldWidget.t;
}

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  final EdgeInsetsGeometry? margin;
  const SkeletonBox({
    super.key,
    this.height = 58,
    this.width,
    this.radius = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final t = _SkeletonTick.of(context);
    final bar = _skeletonBone(context, t);
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.isDark ? c.hairline : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _bar(bar, 1),
          if (height >= 52) ...[
            const SizedBox(height: 8),
            _bar(bar, .62),
          ],
          if (height >= 100) ...[
            const SizedBox(height: 8),
            _bar(bar, .4),
          ],
        ],
      ),
    );
  }

  Widget _bar(Color color, double factor) {
    return FractionallySizedBox(
      widthFactor: factor,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Fills its parent with a pulsing bone. Used inside tight cells such as calendar days.
class SkeletonFill extends StatelessWidget {
  final double radius;
  const SkeletonFill({super.key, this.radius = 9});

  @override
  Widget build(BuildContext context) {
    final t = _SkeletonTick.of(context);
    final color = _skeletonBone(context, t);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton rows mirroring list cards.
class SkeletonRows extends StatelessWidget {
  final int count;
  final double height;
  const SkeletonRows({super.key, this.count = 4, this.height = 58});

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(size: 120);
    // OLD: return SkeletonPulse(
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.stretch,
    //     children: [
    //       for (var i = 0; i < count; i++)
    //         SkeletonBox(
    //           height: height,
    //           margin: const EdgeInsets.only(bottom: 10),
    //         ),
    //     ],
    //   ),
    // );
  }
}

/// Empty state: center icon + muted line + optional CTA.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? cta;
  final VoidCallback? onCta;
  const EmptyState(this.icon, this.message, {super.key, this.cta, this.onCta});

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(icon, size: 40, color: c.stone.withValues(alpha: .6)),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(fontSize: 11, color: c.stone)),
          if (cta != null) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: AppButton(cta!, onTap: onCta),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Standard body for pushed sub-screens.
class ScreenBody extends StatelessWidget {
  final List<Widget> children;
  final double bottomPad;
  const ScreenBody({super.key, required this.children, this.bottomPad = 32});

  @override
  Widget build(BuildContext context) => AppScaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children),
          ),
        ),
      );
}
