import "package:flutter/material.dart";
import "colors.dart";
import "typography.dart";

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.primarySurface,
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.title,
        headlineMedium: AppTypography.section,
        titleLarge: AppTypography.cardTitle,
        bodyLarge: AppTypography.body,
        bodySmall: AppTypography.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
