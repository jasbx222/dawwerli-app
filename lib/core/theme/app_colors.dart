import 'package:flutter/painting.dart';

/// Ishtar Gate palette (brand §14) + semantic tones used by the approved designs.
abstract final class AppColors {
  /// 40–44 · night mode. Set from `themeModeProvider` (settings only, never the
  /// device theme); the app then rebuilds.
  static bool dark = false;

  /// Card / sheet surface (white by day).
  static Color get surface => dark ? const Color(0xFF101B33) : white;

  /// Body text and foreground icons (navy by day).
  static Color get ink => dark ? const Color(0xFFEEF2FF) : navy;

  /// Brand blue. At night it lifts to a lighter tone so blue text, icons and
  /// buttons keep their contrast on navy surfaces.
  static Color get blue => dark ? blueNight : brandBlue;
  static const brandBlue = Color(0xFF1F4E9C);
  static const blueNight = Color(0xFF4F7BE6);
  static const blueLight = Color(0xFF3B6FE0);
  static const gold = Color(0xFFE8B02E);
  static const goldSoft = Color(0xFFF5C95A);
  static const navy = Color(0xFF0F1E3D);
  static const turquoise = Color(0xFF14B8A6);
  static Color get sand =>
      dark ? const Color(0xFF070E1F) : const Color(0xFFFAF7F0);
  static Color get grey =>
      dark ? const Color(0xFFA7B2CF) : const Color(0xFF5B6478);
  static const white = Color(0xFFFFFFFF);

  static const headerSub = Color(0xFFDCE6FF);
  static const splashFoot = Color(0xFFC9D6F5);
  static Color get blueTint =>
      dark ? const Color(0xFF16264A) : const Color(0xFFE6EEFF);
  static Color get blueRing =>
      dark ? const Color(0xFF24386A) : const Color(0xFFD6E2FF);

  static Color get border =>
      dark ? const Color(0xFF2B3A60) : const Color(0xFFE2DCCD);
  static Color get cardRing =>
      dark ? const Color(0xFF1E2A4A) : const Color(0xFFEDE8DC);
  static Color get dotOff =>
      dark ? const Color(0xFF2B3A60) : const Color(0xFFD6D0C2);

  // Status tones. Night versions are deep tints with light text so pills,
  // notes and banners stay readable on navy instead of glowing.
  static Color get dangerBg =>
      dark ? const Color(0xFF3A1A22) : const Color(0xFFFDE7E4);
  static Color get danger =>
      dark ? const Color(0xFFFF8A7A) : const Color(0xFF9B1C12);
  static Color get dangerText =>
      dark ? const Color(0xFFFFB4A8) : const Color(0xFF7A1A10);
  static Color get warnBg =>
      dark ? const Color(0xFF332812) : const Color(0xFFFBF0D6);
  static Color get warn => dark ? goldSoft : const Color(0xFF7A5300);
  static Color get successBg =>
      dark ? const Color(0xFF0F2E24) : const Color(0xFFE7F7EE);
  static Color get success =>
      dark ? const Color(0xFF5BD69A) : const Color(0xFF0E7A3E);
  static Color get tealBg =>
      dark ? const Color(0xFF0E3330) : const Color(0xFFCCFBF1);
  static Color get teal =>
      dark ? const Color(0xFF5EEAD4) : const Color(0xFF0B6E66);

  /// Solid destructive fill (white text on top) — same in both modes.
  static const dangerFill = Color(0xFFB42318);

  /// Dark chip / navy button fill. Navy itself would vanish on the night
  /// background, so it lifts a step.
  static Color get navyFill => dark ? const Color(0xFF24386A) : navy;

  /// Promoted (ad) card tint.
  static Color get adBg =>
      dark ? const Color(0xFF2A2412) : const Color(0xFFFFF8E8);

  /// Muted slate text on cards (live feed, slots).
  static Color get slate =>
      dark ? const Color(0xFFB6C0DA) : const Color(0xFF475569);

  /// Empty/placeholder strokes (dashed slots).
  static Color get dash =>
      dark ? const Color(0xFF3A4A72) : const Color(0xFFCBD5E1);
  static const whatsapp = Color(0xFF128C4A);
  static Color get disabledBg =>
      dark ? const Color(0xFF1E2A4A) : const Color(0xFFE5E1D6);
  static Color get disabledText =>
      dark ? const Color(0xFF93A0C0) : const Color(0xFF6B6455);
  static const sticker = Color(0xFFFF7A59);
  static const stickerText = Color(0xFF3A0E02);
  static Color get slotBg =>
      dark ? const Color(0xFF16264A) : const Color(0xFFEEF3FF);
  static Color get tabTrack =>
      dark ? const Color(0xFF16264A) : const Color(0xFFEEEAE0);
  static Color get tabText =>
      dark ? const Color(0xFFC9D2EA) : const Color(0xFF4B4537);
  static Color get divider =>
      dark ? const Color(0xFF1E2A4A) : const Color(0xFFF1ECE0);
  static Color get checkOff =>
      dark ? const Color(0xFF5B6A8E) : const Color(0xFF9AA3B5);
  static Color get infoText =>
      dark ? const Color(0xFFC9D6F5) : const Color(0xFF1F3B73);
  static Color get warnText =>
      dark ? const Color(0xFFF5D998) : const Color(0xFF5C3F00);
}
