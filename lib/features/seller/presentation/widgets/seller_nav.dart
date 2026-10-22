import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_icons.dart';

enum SellerTab { home, orders, offers, wallet, account }

/// Page app bar: الهوم · طلباتي · عروضي · رصيدي · صفحتي.
class SellerNav extends StatelessWidget {
  const SellerNav(this.current, {super.key});
  final SellerTab current;

  static String route(SellerTab t) => switch (t) {
    SellerTab.home => Routes.sellerHome,
    SellerTab.orders => Routes.sellerOrders,
    SellerTab.offers => Routes.sellerOffers,
    SellerTab.wallet => Routes.sellerWallet,
    SellerTab.account => Routes.sellerAccount,
  };

  @override
  Widget build(BuildContext context) => FloatingNav<SellerTab>(
    items: const [
      NavItem(SellerTab.home, AppIcon.home, 'الهوم'),
      NavItem(SellerTab.orders, AppIcon.bag, 'طلباتي'),
      NavItem(SellerTab.offers, AppIcon.message, 'عروضي'),
      NavItem(SellerTab.wallet, AppIcon.wallet, 'رصيدي'),
      NavItem(SellerTab.account, AppIcon.person, 'صفحتي'),
    ],
    current: current,
    onTab: (t) => t == current ? null : context.go(route(t)),
  );
}
