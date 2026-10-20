import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// IBM Plex Sans Arabic for UI (titles Bold, body Regular, numbers SemiBold); Marhey for the logo only.
abstract final class AppText {
  static const family = 'IBMPlexSansArabic';
  static const logoFamily = 'Marhey';

  /// Matches CSS `line-height: normal` of the font (typo ascender+descender = 1.5em).
  static const lineHeight = 1.5;

  static const body = TextStyle(fontFamily: family, height: lineHeight, fontSize: 14, color: AppColors.navy);
  static const title = TextStyle(fontFamily: family, height: lineHeight, fontSize: 21, fontWeight: FontWeight.w700);
  static const big = TextStyle(fontFamily: family, height: lineHeight, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const label = TextStyle(fontFamily: family, height: lineHeight, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const muted = TextStyle(fontFamily: family, height: lineHeight, fontSize: 12.5, color: AppColors.grey);
  static const button = TextStyle(fontFamily: family, height: lineHeight, fontSize: 16, fontWeight: FontWeight.w700);
  static const strong = TextStyle(fontFamily: family, height: lineHeight, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const number = TextStyle(
    fontFamily: family,
    height: lineHeight,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle logo(double size) => TextStyle(
        fontFamily: logoFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.74,
        fontVariations: const [FontVariation('wght', 700)],
        color: AppColors.white,
      );
}
