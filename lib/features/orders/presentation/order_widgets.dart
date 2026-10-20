import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';

/// Icons only used in this group (24×24, stroke 2).
enum OrderIcon {
  box('<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5M12 13v8"/>'),
  alert('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>'),
  ok('<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.5 2.5L16 9.5"/>');

  const OrderIcon(this.body);
  final String body;

  Widget of(Color c, double size) {
    final hex =
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return SvgPicture.string(
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
    );
  }
}

WidgetSpan svgSpan(Widget w) =>
    WidgetSpan(alignment: PlaceholderAlignment.middle, child: w);

/// `.btn` with an inline trailing icon (e.g. «إي، استلمت ✓»).
class LabelIconButton extends StatelessWidget {
  const LabelIconButton({
    super.key,
    required this.label,
    this.icon,
    required this.bg,
    required this.fg,
    this.shadow = false,
    this.onPressed,
  });
  final String label;
  final AppIcon? icon;
  final Color bg;
  final Color fg;
  final bool shadow;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x99E8B33A),
                    offset: Offset(0, 12),
                    blurRadius: 24,
                    spreadRadius: -10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppText.button.copyWith(color: fg, height: AppText.lh(16)),
            ),
            if (icon != null) ...[
              const SizedBox(width: 6),
              AppSvgIcon(icon!, size: 16, color: fg, strokeWidth: 2.6),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Ghost `.btn` at 14px (side-by-side answers on 15).
class SmallGhostButton extends StatelessWidget {
  const SmallGhostButton(this.label, {super.key, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: EdgeInsets.all(15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: [BoxShadow(color: AppColors.blueRing, spreadRadius: 1.5)],
      ),
      child: Text(
        label,
        style: AppText.button.copyWith(
          fontSize: 14,
          height: AppText.lh(14),
          color: AppColors.blue,
        ),
      ),
    ),
  );
}
