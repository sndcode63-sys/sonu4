import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Centralized UI decorations, shadows, and borders for DigiNiwas.
abstract class AppDecorations {
  AppDecorations._();

  // Radiuses
  static double get radiusS => 8.r;
  static double get radiusM => 14.r;
  static double get radiusL => 20.r;
  static double get radiusXL => 28.r;

  // Standard Border Radius objects
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);

  // Soft Ambient Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get activeGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ];

  // Common Card Decorations
  static BoxDecoration card({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius ?? borderRadiusM,
        border: border ?? Border.all(color: AppColors.border, width: 1.0),
        boxShadow: cardShadow,
      );

  // Active / Selected Item Decoration
  static BoxDecoration selectedItem({BorderRadius? borderRadius}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? borderRadiusM,
        border: Border.all(color: AppColors.primary, width: 1.8),
        boxShadow: activeGlow,
      );

  // Gradient Background Decoration
  static const BoxDecoration pageGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFD4F1F4),
        Color(0xFFF7FBFD),
        Colors.white,
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );
}
