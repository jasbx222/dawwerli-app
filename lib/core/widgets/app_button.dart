import 'package:flutter/material.dart';

import 'exact_line.dart';

import '../theme/app_colors.dart';
import 'app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, navy, ghost, whatsapp, danger, disabled }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.compact = false,
    this.icon,
  });

  /// Leading SVG icon (8px gap), e.g. the lock on «احظر».
  final AppIcon? icon;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Compact = the smaller in-card button (padding 11, 14.5px).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadows) = switch (variant) {
      AppButtonVariant.primary => (
        AppColors.gold,
        AppColors.navy,
        [
          BoxShadow(
            color: const Color(0x99E8B33A),
            offset: const Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -10,
          ),
        ],
      ),
      AppButtonVariant.navy => (AppColors.navy, AppColors.white, <BoxShadow>[]),
      AppButtonVariant.ghost => (
        AppColors.white,
        AppColors.blue,
        [const BoxShadow(color: AppColors.blueRing, spreadRadius: 1.5)],
      ),
      AppButtonVariant.whatsapp => (
        AppColors.whatsapp,
        AppColors.white,
        <BoxShadow>[],
      ),
      AppButtonVariant.danger => (
        const Color(0xFFB42318),
        AppColors.white,
        <BoxShadow>[],
      ),
      AppButtonVariant.disabled => (
        AppColors.disabledBg,
        AppColors.disabledText,
        <BoxShadow>[],
      ),
    };
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: variant == AppButtonVariant.disabled ? null : onPressed,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 11 : 15),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppSvgIcon(icon!, color: fg, size: 18),
                const SizedBox(width: 8),
              ],
              ExactLine(
                fontSize: compact ? 14.5 : 16,
                child: Text(
                  label,
                  style: AppText.button.copyWith(
                    color: fg,
                    fontSize: compact ? 14.5 : 16,
                    height: AppText.lh(compact ? 14.5 : 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
