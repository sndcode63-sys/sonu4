import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating Pill Search Bar inspired by modern maps and Airbnb/accommodation apps.
/// Features clean pure-white container, borderless design, and soft ambient drop elevation.
class AppPillSearchBar extends StatelessWidget {
  const AppPillSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.title,
    this.subtitle,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.trailing,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.margin,
    this.height,
    this.showBorder = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final String? title;
  final String? subtitle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? (subtitle != null ? 52.h : 48.h);

    return Container(
      margin: margin,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: showBorder ? Border.all(color: const Color(0xFFE5E7EB), width: 1.0) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(30.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20.sp,
                  color: const Color(0xFF374151),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: title != null && title!.isNotEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        )
                      : TextField(
                          controller: controller,
                          focusNode: focusNode,
                          readOnly: readOnly,
                          autofocus: autofocus,
                          onTap: onTap,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          cursorColor: const Color(0xFF0A5C4A),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                ),
                if (controller != null && controller!.text.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller!.clear();
                      onClear?.call();
                      onChanged?.call('');
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                if (trailing != null) ...[
                  SizedBox(width: 6.w),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Top Header inspired by Airbnb (Image 1 style) with back button,
/// centered search pill, and filter/action button.
class AppPillTopHeader extends StatelessWidget {
  const AppPillTopHeader({
    super.key,
    this.searchBar,
    this.onBack,
    this.showBack = true,
    this.onActionTap,
    this.actionIcon = Icons.tune_rounded,
    this.showAction = true,
    this.title,
    this.subtitle,
    this.onTapSearch,
  });

  final Widget? searchBar;
  final VoidCallback? onBack;
  final bool showBack;
  final VoidCallback? onActionTap;
  final IconData actionIcon;
  final bool showAction;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTapSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: searchBar ??
                AppPillSearchBar(
                  readOnly: true,
                  title: title,
                  subtitle: subtitle,
                  hintText: 'Search...',
                  onTap: onTapSearch,
                ),
          ),
          if (showAction) ...[
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  actionIcon,
                  size: 20.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

