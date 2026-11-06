import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard AppBar for DigiNiwas screens with smooth back button and action slots.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? Padding(
              padding: EdgeInsets.all(8.w),
              child: InkWell(
                onTap: onBackPressed ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Get.back();
                      }
                    },
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Icon(
                    Icons.adaptive.arrow_back,
                    size: 18.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.headingSmall,
      ),
      actions: actions != null
          ? [
              ...actions!,
              SizedBox(width: 8.w),
            ]
          : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
