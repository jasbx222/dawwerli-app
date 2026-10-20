import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// IBM Plex Sans Arabic for UI (titles Bold, body Regular, numbers SemiBold); Marhey for the logo only.
abstract final class AppText {
  static const family = 'IBMPlexSansArabic';
  static const logoFamily = 'Marhey';

  /// Matches CSS `line-height: normal` of the font (typo ascender+descender = 1.5em).
  static const lineHeight = 1.5;

  static const body = TextStyle(fontFamily: family, height: 1.5000, fontSize: 14, color: AppColors.navy);
  static const title = TextStyle(fontFamily: family, height: 1.5238, fontSize: 21, fontWeight: FontWeight.w700);
  static const big = TextStyle(fontFamily: family, height: 1.5000, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const label = TextStyle(fontFamily: family, height: 1.4615, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const muted = TextStyle(fontFamily: family, height: 1.5200, fontSize: 12.5, color: AppColors.grey);
  static const button = TextStyle(fontFamily: family, height: 1.5000, fontSize: 16, fontWeight: FontWeight.w700);
  static const strong = TextStyle(fontFamily: family, height: 1.5000, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy);
  static const number = TextStyle(
    fontFamily: family,
    height: lineHeight,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Chrome-equivalent `line-height: normal` for IBM Plex Sans Arabic at [size]
  /// (ascent 1.085em and descent .415em, each rounded to whole px).
  static double lh(double size) => ((1.085 * size).roundToDouble() + (.415 * size).roundToDouble()) / size;

  /// Same for Marhey (ascent 1.1em, descent .64em).
  static double logoLh(double size) => ((1.1 * size).roundToDouble() + (.64 * size).roundToDouble()) / size;

  static TextStyle logo(double size) => TextStyle(
        fontFamily: logoFamily,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: logoLh(size),
        fontVariations: const [FontVariation('wght', 700)],
        color: AppColors.white,
      );
}
