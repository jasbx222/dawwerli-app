import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/token_store.dart';
import '../../../core/role/app_role.dart';
import '../../seller/data/seller_controller.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/ishtar_pattern.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _hold = Duration(milliseconds: 1800);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, _next);
  }

  /// Signed in → straight to my side of the app; otherwise onboarding.
  Future<void> _next() async {
    if (!ref.read(tokenStoreProvider).signedIn) {
      if (mounted) context.go(Routes.onboarding);
      return;
    }
    final role = ref.read(appRoleProvider);
    var to = role.home;
    if (role == AppRole.seller) {
      try {
        to = sellerEntryRoute(await ref.read(sellerProvider.notifier).refresh());
      } on ApiException {
        to = Routes.offline;
      }
    }
    if (mounted) context.go(to);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IshtarBackground(
        gradient: cssRadial(
          rx: 1,
          ry: .7,
          at: const Offset(.5, .3),
          colors: [AppColors.blueLight, AppColors.blue, AppColors.navy],
          stops: const [0, .5, 1],
        ),
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LogoMark(),
                  const SizedBox(height: 22),
                  const Wordmark(size: 56),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.tagline,
                    style: AppText.body.copyWith(
                      fontSize: 17,
                      height: AppText.lh(17),
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldSoft,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 60,
                child: Text(
                  AppStrings.madeInIraq,
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    height: AppText.lh(12),
                    color: AppColors.splashFoot,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
