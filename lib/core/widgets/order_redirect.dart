import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Replaces the current screen with [route] once (e.g. a chosen offer that is
/// now a store order opens the unified order details instead).
class OrderRedirect extends StatefulWidget {
  const OrderRedirect(this.route, {super.key});
  final String route;

  @override
  State<OrderRedirect> createState() => _OrderRedirectState();
}

class _OrderRedirectState extends State<OrderRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only the top screen redirects (a parent route under it stays put).
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      context.pushReplacement(widget.route);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
  );
}
