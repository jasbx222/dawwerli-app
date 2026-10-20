import 'package:flutter/painting.dart';

/// Ishtar Gate palette (brand §14) + semantic tones used by the approved designs.
abstract final class AppColors {
  /// 40–44 · night mode. Flipped by [nightModeProvider]; the app then rebuilds.
  static bool dark = false;

  /// Card / sheet surface (white by day).
  static Color get surface => dark ? const Color(0xFF101B33) : white;

  /// Body text and foreground icons (navy by day).
  static Color get ink => dark ? const Color(0xFFEEF2FF) : navy;

  static const blue = Color(0xFF1F4E9C);
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

  static const dangerBg = Color(0xFFFDE7E4);
  static const danger = Color(0xFF9B1C12);
  static const dangerText = Color(0xFF7A1A10);
  static const warnBg = Color(0xFFFBF0D6);
  static const warn = Color(0xFF7A5300);
  static const successBg = Color(0xFFE7F7EE);
  static const success = Color(0xFF0E7A3E);
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
  static const warnText = Color(0xFF5C3F00);
}
