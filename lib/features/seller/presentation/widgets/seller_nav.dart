import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_sheet.dart';

enum SellerTab { inbox, offers, wallet, account }

/// Page app bar (19, 21, 22): الطلبات · عروضي · [camera FAB] · رصيدي · صفحتي.
class SellerNav extends StatelessWidget {
  const SellerNav(this.current, {super.key});
  final SellerTab current;

  static String route(SellerTab t) => switch (t) {
    SellerTab.inbox => Routes.sellerInbox,
    SellerTab.offers => Routes.sellerOffers,
    SellerTab.wallet => Routes.sellerWallet,
    SellerTab.account => Routes.sellerAccount,
  };

  @override
  Widget build(BuildContext context) => FloatingNav<SellerTab>(
    items: const [
      NavItem(SellerTab.inbox, AppIcon.clipboardList, 'الطلبات'),
      NavItem(SellerTab.offers, AppIcon.message, 'عروضي'),
      NavItem(SellerTab.wallet, AppIcon.wallet, 'رصيدي'),
      NavItem(SellerTab.account, AppIcon.person, 'صفحتي'),
    ],
    current: current,
    fabIcon: AppIcon.cameraFab,
    onTab: (t) => t == current ? null : context.go(route(t)),
    onFab: () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => AppSheet(
        children: [
          AppButton(
            'قدّم عرض',
            onPressed: () {
              Navigator.pop(sheet);
              context.go(Routes.sellerInbox);
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            'أضف إعلان',
            variant: AppButtonVariant.navy,
            onPressed: () {
              Navigator.pop(sheet);
              context.push(Routes.sellerAds);
            },
          ),
        ],
      ),
    ),
  );
}
