import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/loading_block.dart';
import '../data/notifications_provider.dart';

class _Notif {
  const _Notif(
    this.icon,
    this.title,
    this.body,
    this.time, {
    this.unread = false,
    this.titleIcon,
    this.route,
  });
  final AppIcon icon;
  final String title;
  final AppIcon? titleIcon;
  final String body;
  final String time;
  final bool unread;
  final String? route;
}

/// Icon by destination: offers, live request, order, dispute, standing.
AppIcon _iconFor(String route) => switch (route) {
  _ when route.endsWith('/offers') => AppIcon.zap,
  _ when route.endsWith('/live') => AppIcon.pin,
  _ when route.startsWith('/orders/') => AppIcon.clock,
  _ when route.contains('dispute') => AppIcon.flag,
  _ when route.contains('standing') => AppIcon.alert,
  _ when route.startsWith('/products/') => AppIcon.bag,
  _ when route.startsWith('/pages/') => AppIcon.store,
  _ => AppIcon.bell,
};

_Notif _of(AppNotification n) => _Notif(
  _iconFor(n.route),
  n.title,
  n.body,
  agoLabel(n.at),
  unread: !n.read,
  titleIcon: n.route.endsWith('/offers') ? AppIcon.flame : null,
  route: n.route.isEmpty || n.route == Routes.notifications ? null : n.route,
);

/// 26 · «الإشعارات», opened from the home bell.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final items = [
      for (final n in async.value ?? const <AppNotification>[]) _of(n),
    ];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(title: 'الإشعارات'),
                if (async.isLoading && !async.hasValue) const LoadingBlock(),
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: AppCard(
                      insets: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              _Row(
                                n: items[i],
                                last: i == items.length - 1,
                                nextUnread:
                                    i + 1 < items.length && items[i + 1].unread,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.n, required this.last, required this.nextUnread});
  final _Notif n;
  final bool last;
  final bool nextUnread;

  @override
  Widget build(BuildContext context) {
    // Unread rows are full-bleed tinted; read rows keep the 16px-inset divider.
    final divider = !last && !n.unread;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: n.route == null ? null : () => context.push(n.route!),
      child: Container(
        color: n.unread
            ? (AppColors.dark
                  ? const Color(0xFF16264A)
                  : const Color(0xFFF2F6FF))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: !last && (divider || n.unread)
                ? Border(bottom: BorderSide(color: AppColors.divider))
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: n.unread ? AppColors.gold : AppColors.tabTrack,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon(n.icon, color: AppColors.navy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: n.title,
                          children: [
                            if (n.titleIcon != null) ...[
                              const TextSpan(text: ' '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: AppSvgIcon(
                                  n.titleIcon!,
                                  color: AppColors.ink,
                                  size: 15,
                                  strokeWidth: 2.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                        style: AppText.strong,
                      ),
                      Text(n.body, style: AppText.muted),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    n.time,
                    style: AppText.muted.copyWith(fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
