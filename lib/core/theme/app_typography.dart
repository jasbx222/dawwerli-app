import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// IBM Plex Sans Arabic for UI (titles Bold, body Regular, numbers SemiBold); Marhey for the logo only.
abstract final class AppText {
  static const family = 'IBMPlexSansArabic';
  static const logoFamily = 'Marhey';

  /// Matches CSS `line-height: normal` of the font (typo ascender+descender = 1.5em).
  static const lineHeight = 1.5;

  static TextStyle get body => TextStyle(
    fontFamily: family,
    height: 1.496032,
    fontSize: 14,
    color: AppColors.ink,
  );
  static TextStyle get title => TextStyle(
    fontFamily: family,
    height: 1.496032,
    fontSize: 21,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get big => TextStyle(
    fontFamily: family,
    height: 1.493687,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static TextStyle get label => TextStyle(
    fontFamily: family,
    height: 1.500000,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static TextStyle get muted => TextStyle(
    fontFamily: family,
    height: 1.502222,
    fontSize: 12.5,
    color: AppColors.grey,
  );
  static TextStyle get button => TextStyle(
    fontFamily: family,
    height: 1.489583,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static TextStyle get strong => TextStyle(
    fontFamily: family,
    height: 1.496032,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static TextStyle get number => TextStyle(
    fontFamily: family,
    height: lineHeight,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Device pixel ratio the approved designs were rendered at (1080px / 390pt).
  static const designDpr = 1080 / 390;

  /// Chrome-equivalent `line-height: normal` for IBM Plex Sans Arabic at [size]:
  /// ascent 1.085em and descent .415em, each rounded to whole *device* pixels
  /// at [designDpr] (e.g. 13px → 19.5, not 19). Hardcoded `height:` literals in
  /// const styles use the same values.
  static double lh(double size) =>
      ((1.085 * size * designDpr).roundToDouble() +
          (.415 * size * designDpr).roundToDouble()) /
      designDpr /
      size;

  /// Same for Marhey (ascent 1.1em, descent .64em).
  static double logoLh(double size) =>
      ((1.1 * size * designDpr).roundToDouble() +
          (.64 * size * designDpr).roundToDouble()) /
      designDpr /
      size;

  static TextStyle logo(double size) => TextStyle(
    fontFamily: logoFamily,
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: logoLh(size),
    fontVariations: const [FontVariation('wght', 700)],
    color: AppColors.white,
  );
}
