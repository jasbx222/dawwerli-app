import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icons.dart';

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

// Mock feed until the notifications API lands; each opens its screen.
final _items = [
  _Notif(
    AppIcon.zap,
    'عرض جديد!',
    'رياضة الكرادة دزتلك 39,000 د.ع',
    'قبل 2 د',
    unread: true,
    titleIcon: AppIcon.flame,
    route: Routes.offers('r1'),
  ),
  _Notif(
    AppIcon.verified,
    'لكيته! ستايل بغداد شافت رقمك',
    'افتح الواتساب وكمّل',
    'قبل 20 د',
    unread: true,
    route: Routes.chosen('r1'),
  ),
  _Notif(
    AppIcon.pin,
    'وسّعنا طلبك',
    'ساعة كاسيو وصلت لبابل وديالى. تريد ترفع السعر؟',
    'قبل ساعة',
    route: '${Routes.liveRequest('r1')}?preview=widened',
  ),
  _Notif(
    AppIcon.clock,
    'وصلك الغرض؟',
    'عطر عود · اضغط حتى تأكد',
    'أمس',
    route: Routes.orderStatus('o1'),
  ),
  _Notif(
    AppIcon.alert,
    'طلبك انتهى بدون عروض',
    'آيفون 13 · عدّله وانشره مرة ثانية',
    'أمس',
    route: Routes.noOffers('r1'),
  ),
  const _Notif(
    AppIcon.bell,
    'عيد سعيد',
    'عروض العيد على الملابس والهدايا',
    '23/9',
    titleIcon: AppIcon.moon,
  ),
];

/// 26 · «الإشعارات» tab.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 18 + 70 + 24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(title: 'الإشعارات', showBack: false),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: AppCard(
                    insets: const EdgeInsets.symmetric(vertical: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            _Row(
                              n: _items[i],
                              last: i == _items.length - 1,
                              nextUnread:
                                  i + 1 < _items.length && _items[i + 1].unread,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18 + MediaQuery.viewPaddingOf(context).bottom,
            child: AppBottomNav(
              current: NavTab.notifications,
              onTab: (t) => switch (t) {
                NavTab.home => context.go(Routes.home),
                NavTab.requests => context.go(Routes.myRequests),
                NavTab.notifications => null,
                NavTab.account => context.go(Routes.account),
              },
              onPost: () => context.push(Routes.post),
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
