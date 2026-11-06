import 'package:flutter/material.dart';

class AppColors {
  AppColors._();


  static const Color navy = Color(0xFF062B49);

  static const Color turquoise = Color(0xFF13B99A);

  static const Color green = Color(0xFF007E68);

  static const Color white = Color(0xFFFFFFFF);

  static const Color softBackground = Color(0xFFF8F9FA);

  // ---------------------------------------------------------------------
  // Semantic aliases (map palette -> usage so screens read clearly)
  // ---------------------------------------------------------------------

  /// Primary CTA / accent color (buttons, links, active states).
  static const Color primary = turquoise;

  /// Darker accent used for pressed/disabled/hover states of [primary].
  static const Color primaryDark = green;

  /// Headings and high-emphasis text.
  static const Color textPrimary = navy;

  /// Body / medium-emphasis text.
  static const Color textSecondary = Color(0xFF6C7E93);

  /// Placeholder / low-emphasis text.
  static const Color textPlaceholder = Color(0xFFA8B8CA);

  /// Default input border color.
  static const Color border = Color(0xFFECEFF2);

  /// Scaffold / screen background.
  static const Color background = softBackground;

  /// Card / input field surface color.
  static const Color surface = white;

  /// Error / destructive state.
  static const Color error = Colors.redAccent;
}
