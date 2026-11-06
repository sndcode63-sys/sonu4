import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Modernized pill-shaped text input field for DigiNiwas.
///
/// Matches the design from the registration and login flows with
/// fully rounded pill borders, crisp surface colors, and soft ambient elevation.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.fillColor,
    this.borderRadius,
    this.hasShadow = true,
    this.autofocus = false,
    this.contentPadding,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? prefix;
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? suffixText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final Color? fillColor;
  final double? borderRadius;
  final bool hasShadow;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 26.r;

    Widget? resolvedSuffix = suffix ?? suffixIcon;
    if (resolvedSuffix == null && suffixText != null) {
      resolvedSuffix = Padding(
        padding: EdgeInsets.only(right: 18.w),
        child: Text(
          suffixText!,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: EdgeInsets.only(left: 6.w, bottom: 6.h),
            child: Text(
              labelText!,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: fillColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: AppColors.textSecondary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            autofocus: autofocus,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPlaceholder,
              ),
              prefixIcon: prefixIcon,
              prefix: prefix,
              suffixIcon: resolvedSuffix,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              fillColor: Colors.transparent,
              filled: true,
              counterText: '',
              isDense: true,
              contentPadding: contentPadding ??
                  EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: AppColors.error, width: 1.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dedicated pill-shaped Phone input with `+91 ▾ |` prefix
/// matching the exact design from the DigiNiwas Welcome screen.
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.controller,
    this.onChanged,
    this.autofocus = false,
    this.hintText = 'Mobile Number',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_outlined,
            size: 18.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 8.w),
          Text(
            '+91',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 8.w),
          Container(
            width: 1.2,
            height: 18.h,
            color: const Color(0xFFCBD5E1),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              autofocus: autofocus,
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPlaceholder,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
