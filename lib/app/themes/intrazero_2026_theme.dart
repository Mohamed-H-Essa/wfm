import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class IntraZero2026Theme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: IntraZeroColors.primaryGradient.colors.first,
        secondary: IntraZeroColors.progressGradient.colors.first,
        surface: IntraZeroColors.surface,
        error: IntraZeroColors.danger,
      ),
      scaffoldBackgroundColor: IntraZeroColors.background,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: IntraZeroColors.surface,
      ),
      textTheme: const TextTheme(
        displayLarge: IntraZeroTypography.h1,
        displayMedium: IntraZeroTypography.h2,
        displaySmall: IntraZeroTypography.h3,
        bodyLarge: IntraZeroTypography.body,
        bodyMedium: IntraZeroTypography.bodySmall,
        bodySmall: IntraZeroTypography.caption,
        labelLarge: IntraZeroTypography.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: IntraZeroColors.borderLight, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: IntraZeroColors.primaryGradient.colors.first,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: IntraZeroColors.primaryGradient.colors.first,
        secondary: IntraZeroColors.progressGradient.colors.first,
        surface: IntraZeroColors.darkSurface,
        error: IntraZeroColors.danger,
      ),
      scaffoldBackgroundColor: IntraZeroColors.darkBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: IntraZeroColors.darkSurface,
      ),
    );
  }
}

