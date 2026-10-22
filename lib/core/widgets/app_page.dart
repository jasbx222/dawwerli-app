import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_header.dart';
import 'app_icons.dart';
import 'toast_bar.dart';

/// Pops, or goes to [fallback] when opened as a root.
void popOr(BuildContext c, [String fallback = Routes.home]) =>
    c.canPop() ? c.pop() : c.go(fallback);

/// Standard screen: Ishtar header + scrolling body + optional pinned [bottom]
/// and an optional floating [nav] (tab roots).
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    this.titleIcon,
    this.trailing,
    this.below,
    required this.children,
    this.bottom,
    this.nav,
    this.showBack = true,
    this.onBack,
    this.onRefresh,
  });
  final String title;
  final String? subtitle;
  final Widget? titleIcon;
  final Widget? trailing;
  final Widget? below;
  final List<Widget> children;
  final Widget? bottom;
  final Widget? nav;
  final bool showBack;
  final VoidCallback? onBack;

  /// Pull-to-refresh on the body when set.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    final navRoom = nav == null
        ? AppSpacing.xl
        : AppSize.navOffset + AppSize.navHeight + AppSpacing.xl + inset;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _refreshable(
                  ListView(
                    physics: onRefresh == null
                        ? null
                        : const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: navRoom),
                    children: [
                      AppHeader(
                        title: title,
                        titleIcon: titleIcon,
                        trailing: trailing,
                        below: below,
                        showBack: showBack,
                        subtitle: subtitle == null ? null : Text(subtitle!),
                        onBack: onBack ?? () => popOr(context),
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.sm,
                    AppSpacing.screen,
                    AppSpacing.lg + inset,
                  ),
                  child: bottom,
                ),
            ],
          ),
          if (nav != null)
            Positioned(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              bottom: AppSize.navOffset + inset,
              child: nav!,
            ),
        ],
      ),
    );
  }
}

extension on AppPage {
  Widget _refreshable(Widget list) => onRefresh == null
      ? list
      : RefreshIndicator(
          color: AppColors.blue,
          onRefresh: onRefresh!,
          child: list,
        );
}

/// Screen-edge padding with the usual 14px gap above (`.card` margin).
class Gap extends StatelessWidget {
  const Gap(this.child, {super.key, this.top = 14});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.screen, top, AppSpacing.screen, 0),
    child: child,
  );
}

/// Bold section label between cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
    child: Text(text, style: AppText.strong.copyWith(fontSize: 15)),
  );
}

/// Floating navy toast with a gold check (same look as the home notices).
void showAppToast(
  BuildContext context,
  String text, {
  AppIcon icon = AppIcon.check,
}) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      content: ToastBar(text, icon: icon, iconColor: AppColors.gold),
    ),
  );
