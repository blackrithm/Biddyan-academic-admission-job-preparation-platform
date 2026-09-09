/// Global application constants for Biddyan.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  /// Backend REST API base URL.
  ///
  /// Web build served by Nginx uses a relative path (`/api`) so that it is
  /// reverse-proxied to the Node.js container. Mobile builds use the
  /// absolute localhost URL of the Docker Compose backend.
  static String get apiBaseUrl {
    const configured = String.fromEnvironment('BIDDYAN_API_URL');
    if (configured.isNotEmpty) return configured;

    // `flutter run -d chrome` serves the app from a dev port, not through the
    // production reverse proxy, so point local web development at the API.
    if (kIsWeb &&
        (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') &&
        Uri.base.port != 80 &&
        Uri.base.port != 443) {
      return 'http://localhost:5000/api';
    }
    return '/api';
  }

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