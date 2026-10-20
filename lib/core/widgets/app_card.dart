import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.padding = 16,
    this.flat = false,
    this.insets,
  });

  final Widget child;
  final Color? color;
  final double padding;

  /// Overrides [padding] when the design uses asymmetric padding (e.g. `12px 14px`).
  final EdgeInsets? insets;

  /// Flat cards (tinted alerts) have no shadow/ring.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: insets ?? EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: flat
            ? null
            : const [
                BoxShadow(
                  color: Color(0x660B1A3F),
                  offset: Offset(0, 14),
                  blurRadius: 30,
                  spreadRadius: -20,
                ),
                BoxShadow(color: AppColors.cardRing, spreadRadius: 1),
              ],
      ),
      child: child,
    );
  }
}

/// Tinted alert card: bold title + body line (e.g. phone validation errors).
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.body,
    this.leading,
  });

  final String title;
  final String body;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
            fontSize: 14,
          ),
        ),
        Text(
          body,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.5200,
            color: AppColors.dangerText,
          ),
        ),
      ],
    );
    return AppCard(
      flat: true,
      color: AppColors.dangerBg,
      child: leading == null
          ? texts
          : Row(
              children: [
                leading!,
                const SizedBox(width: 12),
                Expanded(child: texts),
              ],
            ),
    );
  }
}
