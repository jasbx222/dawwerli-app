import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// "دوّرلي." wordmark in Marhey with the gold dot.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, required this.size, this.color = AppColors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppText.logo(size).copyWith(color: color),
        children: const [
          TextSpan(text: AppStrings.appName),
          TextSpan(text: AppStrings.logoDot, style: TextStyle(color: AppColors.gold)),
        ],
      ),
    );
  }
}

/// App-icon style mark: navy rounded square, gold ring + glow, "د." inside.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: const [
          BoxShadow(color: Color(0x66E8B02E), offset: Offset(0, 20), blurRadius: 60),
          BoxShadow(color: AppColors.gold, spreadRadius: 3),
        ],
      ),
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          style: AppText.logo(size / 3),
          children: const [
            TextSpan(text: AppStrings.logoLetter),
            TextSpan(text: AppStrings.logoDot, style: TextStyle(color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}
