import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material themes for both modes. Brand colours stay the same; the night
/// variant moves surfaces to navy and lifts text/blue for contrast.
abstract final class AppTheme {
  static ThemeData get light => build(dark: false);
  static ThemeData get dark => build(dark: true);

  static const _lightBg = Color(0xFFFAF7F0); // cream
  static const _lightInk = AppColors.navy;
  static const _lightMuted = Color(0xFF5B6478);
  static const _lightBorder = Color(0xFFE2DCCD);

  static const _darkBg = Color(0xFF070E1F);
  static const _darkSurface = Color(0xFF101B33);
  static const _darkRaised = Color(0xFF16264A);
  static const _darkInk = Color(0xFFEEF2FF);
  static const _darkMuted = Color(0xFFA7B2CF);
  static const _darkBorder = Color(0xFF2B3A60);

  static ThemeData build({required bool dark}) {
    final bg = dark ? _darkBg : _lightBg;
    final surface = dark ? _darkSurface : AppColors.white;
    final ink = dark ? _darkInk : _lightInk;
    final muted = dark ? _darkMuted : _lightMuted;
    final border = dark ? _darkBorder : _lightBorder;
    final primary = dark ? AppColors.blueNight : AppColors.brandBlue;
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: AppColors.white,
      primaryContainer: dark ? _darkRaised : const Color(0xFFE6EEFF),
      onPrimaryContainer: dark ? _darkInk : AppColors.brandBlue,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      secondaryContainer: dark
          ? const Color(0xFF3A2E10)
          : const Color(0xFFFBF0D6),
      onSecondaryContainer: dark ? AppColors.goldSoft : const Color(0xFF5C3F00),
      tertiary: AppColors.turquoise,
      onTertiary: AppColors.navy,
      error: dark ? const Color(0xFFFF8A7A) : const Color(0xFFB42318),
      onError: dark ? AppColors.navy : AppColors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: dark ? _darkRaised : AppColors.white,
      surfaceContainerHighest: dark ? _darkRaised : const Color(0xFFF1ECE0),
      outline: border,
      outlineVariant: dark ? const Color(0xFF1E2A4A) : const Color(0xFFEDE8DC),
      shadow: Colors.black,
      scrim: const Color(0xFF070E1F),
      inverseSurface: dark ? _darkInk : AppColors.navy,
      onInverseSurface: dark ? AppColors.navy : AppColors.white,
      inversePrimary: dark ? AppColors.brandBlue : AppColors.blueNight,
    );
    final base = dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Every screen opens on the navy/blue header, so status icons stay light.
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: bg,
      systemNavigationBarDividerColor: bg,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      fontFamily: AppText.family,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: dark ? const Color(0xFF1E2A4A) : const Color(0xFFF1ECE0),
      hintColor: muted,
      disabledColor: dark ? const Color(0xFF93A0C0) : const Color(0xFF6B6455),
      textTheme: base
          .apply(fontFamily: AppText.family, bodyColor: ink, displayColor: ink)
          .copyWith(
            bodyMedium: TextStyle(
              height: AppText.lineHeight,
              fontSize: 14,
              color: ink,
            ),
            bodyLarge: TextStyle(
              height: AppText.lineHeight,
              fontSize: 16,
              color: ink,
            ),
          ),
      iconTheme: IconThemeData(color: ink),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: .3),
        selectionHandleColor: primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlay,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppText.family,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppText.family,
          fontSize: 14,
          height: AppText.lineHeight,
          color: ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x8C070E1F),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(fontFamily: AppText.family, color: ink),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? _darkRaised : AppColors.navy,
        contentTextStyle: TextStyle(
          fontFamily: AppText.family,
          color: dark ? _darkInk : AppColors.white,
        ),
        actionTextColor: AppColors.goldSoft,
      ),
      // Only the base `border` here. Setting enabledBorder/focusedBorder in the
      // theme would also draw on fields that opt out with InputBorder.none
      // (e.g. fields inside InputShell), giving a second border inside the box.
      // Material resolves this border's colour per state: outline at rest,
      // primary (2px) when focused, error on errors.
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? AppColors.goldSoft : AppColors.brandBlue,
        linearTrackColor: border,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(surface),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? primary : Colors.transparent,
        ),
        side: BorderSide(color: muted),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: TextStyle(fontFamily: AppText.family, color: ink),
        side: BorderSide(color: border),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: dark ? _darkRaised : AppColors.brandBlue,
        headerForegroundColor: AppColors.white,
      ),
      timePickerTheme: TimePickerThemeData(backgroundColor: surface),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0xFF1E2A4A) : const Color(0xFFF1ECE0),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(textColor: ink, iconColor: ink),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? _darkRaised : AppColors.navy,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontFamily: AppText.family,
          fontSize: 12,
          color: dark ? _darkInk : AppColors.white,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: .5)),
      ),
    );
  }

  /// Status/navigation bar style for the current mode.
  static SystemUiOverlayStyle overlay({required bool dark}) =>
      build(dark: dark).appBarTheme.systemOverlayStyle!;
}
