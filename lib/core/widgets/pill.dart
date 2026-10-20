import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import 'app_icons.dart';

/// `.pill` (12px bold, pad 5/10) with optional custom padding.
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    required this.bg,
    required this.fg,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.icon,
    this.check = false,
  });
  final String label;
  final Color bg;
  final Color fg;
  final EdgeInsets padding;
  final AppIcon? icon;

  /// Trailing check drawn as SVG (replaces the ✓ glyph).
  final bool check;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppSvgIcon(icon!, size: 14, color: fg),
          SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: AppText.lh(12),
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
        if (check)
          AppSvgIcon(AppIcon.check, size: 11, color: fg, strokeWidth: 3),
      ],
    ),
  );
}
