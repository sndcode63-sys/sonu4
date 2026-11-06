import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppAdaptiveBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final EdgeInsetsGeometry? margin;

  const AppAdaptiveBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = size ?? 38.w;
    final double iconS = iconSize ?? 18.sp;

    // AppBar ke leading mein properly fit ho isliye Center aur Padding ka use kiya hai
    return Padding(
      padding: margin ?? EdgeInsets.all(8.w), // AppBar ke leading ke liye standard padding
      child: Center(
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed ??
                        () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Get.back();
                      }
                    },
                child: Center(
                  child: Icon(
                    Icons.adaptive.arrow_back,
                    color: color ?? const Color(0xFF0F172A),
                    size: iconS,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// Unified, clean, premium AppBar for all DigiNiwas screens.
class BuyerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool showBottomDivider;

  const BuyerAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF0F172A),
    this.centerTitle = true,
    this.elevation = 0,
    this.bottom,
    this.showBottomDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final shouldShowBack = showBackButton && (canPop || onBackPressed != null);

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: shouldShowBack
          ? AppAdaptiveBackButton(
              onPressed: onBackPressed,
            )
          : null,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? const Color(0xFF0F172A),
                  ),
                )
              : null),
      actions: actions != null
          ? [
              ...actions!,
              SizedBox(width: 8.w),
            ]
          : null,
      bottom: bottom != null || showBottomDivider
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                (bottom?.preferredSize.height ?? 0.0) + (showBottomDivider ? 1.0 : 0.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bottom != null) bottom!,
                  if (showBottomDivider)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight +
            (bottom?.preferredSize.height ?? 0.0) +
            (showBottomDivider ? 1.0 : 0.0),
      );
}
