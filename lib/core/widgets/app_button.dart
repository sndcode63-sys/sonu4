import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Visual style for [AppButton].
enum AppButtonVariant {
  /// Solid, filled CTA — used for the main action on a screen.
  primary,

  /// Outlined, low-emphasis button — used for secondary actions.
  outline,

  /// No background/border, just colored text — used for tertiary/text-only
  /// actions (e.g. "Return to Home").
  text,
}

/// The single reusable button for the whole app.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  /// Text shown on the button (hidden, replaced by a spinner, while
  /// [isLoading] is true).
  final String label;

  /// Tapped when enabled. Pass `null` to show the button in its disabled
  /// state (also automatically disabled while [isLoading] is true).
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  /// Optional trailing icon, shown after [label].
  final IconData? icon;

  /// Shows a small spinner instead of the label/icon and disables taps.
  final bool isLoading;

  /// Stretches to the parent's width. Set to `false` for inline buttons.
  final bool isFullWidth;

  /// Defaults to 50.h.
  final double? height;

  /// Overrides the variant's default background color.
  final Color? backgroundColor;

  /// Overrides the variant's default text/icon color.
  final Color? foregroundColor;

  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Radius ko 14.r set kar diya gaya hai
    final radius = borderRadius ?? 14.r;
    final resolvedHeight = height ?? 50.h;

    final Color bg = backgroundColor ??
        switch (variant) {
          AppButtonVariant.primary => AppColors.primary,
          AppButtonVariant.outline => Colors.transparent,
          AppButtonVariant.text => Colors.transparent,
        };

    final Color fg = foregroundColor ??
        switch (variant) {
          AppButtonVariant.primary => AppColors.white,
          AppButtonVariant.outline => AppColors.primary,
          AppButtonVariant.text => AppColors.textSecondary,
        };

    final Color disabledBg = variant == AppButtonVariant.primary
        ? const Color(0xFFC9D0D6)
        : Colors.transparent;

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: disabledBg,
        foregroundColor: fg,
        disabledForegroundColor: fg.withValues(alpha: 0.6),
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: variant == AppButtonVariant.outline
              ? const BorderSide(color: AppColors.primary, width: 1.4)
              : BorderSide.none,
        ),
      ),
      child: isLoading
          ? SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          if (icon != null) ...[
            SizedBox(width: 6.w),
            Icon(icon, color: fg, size: 18.sp),
          ],
        ],
      ),
    );

    if (!isFullWidth) {
      return SizedBox(height: resolvedHeight, child: button);
    }
    return SizedBox(width: double.infinity, height: resolvedHeight, child: button);
  }
}