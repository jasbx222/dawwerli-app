import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'app_icons.dart';

/// `.li` settings row: icon, label (+ optional sub), value, chevron or [trailing].
class SettingsRow extends StatelessWidget {
  const SettingsRow(
    this.icon,
    this.label, {
    super.key,
    this.value = '',
    this.sub,
    this.onTap,
    this.trailing,
    this.danger = false,
  });
  final AppIcon? icon;
  final String label;
  final String value;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          if (icon != null) ...[
            AppSvgIcon(
              icon!,
              color: danger ? AppColors.dangerFill : AppColors.blue,
              size: AppSize.rowIcon,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: danger ? AppColors.danger : AppColors.ink,
                  ),
                ),
                if (sub != null)
                  Text(sub!, style: AppText.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          if (value.isNotEmpty) ...[
            Text(value, style: AppText.muted),
            const SizedBox(width: AppSpacing.md),
          ],
          trailing ??
              AppSvgIcon(
                AppIcon.chevronLeft,
                color: AppColors.checkOff,
                size: AppSize.chevron,
              ),
        ],
      ),
    ),
  );
}

/// White card of rows separated by hairlines (28 groups, 48 toggles).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup(this.rows, {super.key, this.margin = true});
  final List<Widget> rows;
  final bool margin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin
        ? const EdgeInsets.fromLTRB(16, 14, 16, 0)
        : EdgeInsets.zero,
    child: AppCard(
      insets: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: i == rows.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
              child: rows[i],
            ),
        ],
      ),
    ),
  );
}
