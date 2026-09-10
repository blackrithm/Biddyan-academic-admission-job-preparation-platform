import 'package:flutter/material.dart';

import 'constants.dart';

/// Global Biddyan brand theme.
///
/// Uses a deep teal brand, warm white surfaces, and vivid red actions inspired
/// by the reference learning-platform visual.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildLight();

  static ThemeData _buildLight() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primary,
      brightness: Brightness.light,
      surface: AppConstants.surface,
      surfaceTint: AppConstants.primary,
    ).copyWith(
      primary: AppConstants.primary,
      secondary: AppConstants.accent,
      error: AppConstants.accent,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppConstants.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppConstants.primary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: AppConstants.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppConstants.primary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: Color(0xFF24383A), height: 1.45),
        bodyMedium: TextStyle(color: AppConstants.mutedText, height: 1.4),
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.surface,
        foregroundColor: AppConstants.primary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: AppConstants.primary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppConstants.surface,
        elevation: 2,
        shadowColor: Color(0x22000000),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppConstants.surface,
        elevation: 2,
        indicatorColor: const Color(0x1F00343A),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(color: AppConstants.primary, fontWeight: FontWeight.w600),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: AppConstants.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primary,
          side: const BorderSide(color: AppConstants.primary, width: 1.4),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppConstants.primary,
            width: 1.6,
          ),
        ),
        labelStyle: const TextStyle(color: AppConstants.mutedText),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.background,
        labelStyle: const TextStyle(color: Color(0xFF111827)),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppConstants.surface,
        selectedIconTheme: IconThemeData(color: AppConstants.primary),
        unselectedIconTheme: IconThemeData(color: AppConstants.mutedText),
        selectedLabelTextStyle: TextStyle(
          color: AppConstants.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppConstants.mutedText,
          fontSize: 13,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.primary,
        linearTrackColor: Color(0xFFE2E8F0),
      ),
    );
  }
}
