import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';
import 'ishtar_pattern.dart';
import 'stripe.dart';

/// Blue Ishtar header (`.top` in the designs): back button, title, subtitle, gold stripe.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.subtitle, this.onBack});

  final String title;
  final Widget? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return IshtarBackground(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.header)),
      gradient: cssRadial(
        rx: 1.2,
        ry: .9,
        at: const Offset(1, 0),
        colors: const [AppColors.blueLight, AppColors.blue, AppColors.navy],
        stops: const [0, .45, 1],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(AppRadius.iconBox),
                        ),
                        alignment: Alignment.center,
                        child: const AppSvgIcon(AppIcon.back, color: AppColors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: AppText.title.copyWith(color: AppColors.white)),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 13, height: 1.4615, color: AppColors.headerSub),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, height: 10, child: GoldStripe()),
        ],
      ),
    );
  }
}

