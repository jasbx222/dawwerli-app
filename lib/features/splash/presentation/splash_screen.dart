import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/ishtar_pattern.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoAdvance = true});

  final bool autoAdvance;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoAdvance) {
      _timer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) context.go(Routes.onboarding);
      });
    }
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
          colors: const [AppColors.blueLight, AppColors.blue, AppColors.navy],
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
                    style: AppText.body.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.goldSoft),
                  ),
                ],
              ),
              Positioned(
                bottom: 60,
                child: Text(AppStrings.madeInIraq, style: AppText.body.copyWith(fontSize: 12, color: AppColors.splashFoot)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
