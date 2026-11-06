import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Centralized typographic scale for DigiNiwas.
///
/// Ensures consistent font sizes, weights, and letter spacings throughout the app.
abstract class AppTextStyles {
  AppTextStyles._();

  /// Large display titles (e.g. Splash, prominent welcome banners).
  static TextStyle displayLarge = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Screen headline (e.g. "Choose Your Role", "Explore Properties").
  static TextStyle headingLarge = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Section headers (e.g. "Popular Properties", "Nearby Agents").
  static TextStyle headingMedium = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Card titles, dialog headers.
  static TextStyle headingSmall = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Subtitle or secondary emphasis headings.
  static TextStyle subtitle = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Standard body text.
  static TextStyle bodyMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Secondary/muted body text.
  static TextStyle bodySmall = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Button labels.
  static TextStyle button = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  /// Badges, chips, metadata tags.
  static TextStyle badge = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Input label / form captions.
  static TextStyle caption = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
