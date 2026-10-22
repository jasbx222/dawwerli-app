import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_icons.dart';

enum NavTab { home, requests, pages, account }

/// One tab of a [FloatingNav].
class NavItem<T> {
  const NavItem(this.value, this.icon, this.label);
  final T value;
  final AppIcon icon;
  final String label;
}

/// Floating bottom bar with the gold FAB in the middle (customer and page apps).
class FloatingNav<T> extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.items,
    required this.current,
    required this.onTab,
    this.onFab,
    this.fabIcon = AppIcon.plus,
  });

  /// Four items with the FAB between the 2nd and 3rd, or any number of
  /// evenly spaced items when [onFab] is null.
  final List<NavItem<T>> items;
  final T current;
  final ValueChanged<T> onTab;
  final VoidCallback? onFab;
  final AppIcon fabIcon;

  @override
  Widget build(BuildContext context) {
    Widget item(NavItem<T> t) {
      final on = t.value == current;
      final c = on ? AppColors.blue : AppColors.grey;
      return GestureDetector(
        onTap: () => onTab(t.value),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(t.icon, color: c, size: 22),
            const SizedBox(height: 3),
            Text(
              t.label,
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
      height: AppSize.navHeight,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .92),
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
      child: onFab == null
          ? Row(children: [for (final t in items) Expanded(child: item(t))])
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                item(items[0]),
                item(items[1]),
                Transform.translate(
                  offset: const Offset(0, -17),
                  child: GestureDetector(
                    onTap: onFab,
                    child: Container(
                      width: AppSize.fab,
                      height: AppSize.fab,
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
                      child: AppSvgIcon(
                        fabIcon,
                        color: AppColors.ink,
                        size: 26,
                        strokeWidth: 2.6,
                      ),
                    ),
                  ),
                ),
                item(items[2]),
                item(items[3]),
              ],
            ),
    );
  }
}

/// Customer app bar (06, 25, 26, 28).
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
  Widget build(BuildContext context) => FloatingNav<NavTab>(
    items: const [
      NavItem(NavTab.home, AppIcon.home, AppStrings.navHome),
      NavItem(NavTab.requests, AppIcon.clipboard, AppStrings.navRequests),
      NavItem(NavTab.pages, AppIcon.store, AppStrings.navPages),
      NavItem(NavTab.account, AppIcon.user, AppStrings.navAccount),
    ],
    current: current,
    onTab: onTab,
    onFab: onPost,
  );
}
