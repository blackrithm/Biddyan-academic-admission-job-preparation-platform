import 'package:flutter/material.dart';

import 'constants.dart';

/// Global Biddyan brand theme.
///
/// Uses a Bengali-first friendly palette: deep emerald primary, warm orange
/// accent, and light neutral surfaces that keeps MCQ text highly readable on
/// both web (wider canvas) and mobile (smaller canvas).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildLight();

  static ThemeData _buildLight() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primary,
      brightness: Brightness.light,
      surface: AppConstants.surface,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppConstants.background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.surface,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Color(0xFF111827),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppConstants.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primary,
          side: const BorderSide(color: AppConstants.primary, width: 1.4),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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