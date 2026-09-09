/// Global application constants for Biddyan.
library;

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  /// Backend REST API base URL.
  ///
  /// Override this for deployed builds with:
  /// `--dart-define=API_BASE_URL=https://example.com/api`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  /// Brand primary emerald/teal color used across all screens.
  static const Color primary = Color(0xFF006A4E);

  /// Warm accent (orange) used for CTAs, banners and warnings.
  static const Color accent = Color(0xFFFF5722);

  /// Light greys used for page backgrounds and card surfaces.
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color mutedText = Color(0xFF6B7280);

  /// Price/package color (golden).
  static const Color golden = Color(0xFFFFB300);

  /// Bengali exam option labels: ক, খ, গ, ঘ.
  static const List<String> bengaliOptionLabels = ['ক', 'খ', 'গ', 'ঘ'];

  /// English correct-option enum letters that map to the Bengali labels.
  static const List<String> optionKeys = ['A', 'B', 'C', 'D'];
}
