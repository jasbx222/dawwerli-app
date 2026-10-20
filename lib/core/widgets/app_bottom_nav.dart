import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'app_icons.dart';

enum NavTab { home, requests, notifications, account }

/// Floating bottom bar with the gold "post" FAB in the middle.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onTab,
    required this.onPost,
  });

  final NavTab current;
  final ValueChanged<NavTab> onTab;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    Widget item(NavTab t, AppIcon icon, String label) {
      final on = t == current;
      final c = on ? AppColors.blue : AppColors.grey;
      return GestureDetector(
        onTap: () => onTab(t),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(icon, color: c, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.510101,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400F172A),
            offset: Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(NavTab.home, AppIcon.home, AppStrings.navHome),
          item(NavTab.requests, AppIcon.clipboard, AppStrings.navRequests),
          Transform.translate(
            offset: const Offset(0, -17),
            child: GestureDetector(
              onTap: onPost,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB3E8B33A),
                      offset: Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(
                  AppIcon.plus,
                  color: AppColors.navy,
                  size: 26,
                  strokeWidth: 2.6,
                ),
              ),
            ),
          ),
          item(NavTab.notifications, AppIcon.bell, AppStrings.navNotifications),
          item(NavTab.account, AppIcon.user, AppStrings.navAccount),
        ],
      ),
    );
  }
}
