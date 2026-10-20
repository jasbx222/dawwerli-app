import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppText.family,
    scaffoldBackgroundColor: AppColors.sand,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.gold,
      surface: AppColors.sand,
    ),
    textTheme: Typography.material2021().black
        .apply(fontFamily: AppText.family)
        .copyWith(
          bodyMedium: const TextStyle(
            height: AppText.lineHeight,
            fontSize: 14,
            color: AppColors.navy,
          ),
          bodyLarge: const TextStyle(
            height: AppText.lineHeight,
            fontSize: 16,
            color: AppColors.navy,
          ),
        ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.blue,
    ),
  );
}
