import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// ================================================================
/// PARTNER DESIGN SYSTEM
/// Sirf partner section ke liye. Buyer / Seller ka theme untouched hai.
///
/// Direction: deep ink-navy + deep emerald, gold sirf "premium" moments
/// (wallet, boost, verified) ke liye. White surfaces, hairline borders,
/// layered soft shadows -> clean, bharosemand, professional look.
/// ================================================================
abstract class PartnerColors {
  PartnerColors._();

  // Core brand
  static const Color ink = Color(0xFF0B1B2E);
  static const Color brand = Color(0xFF0A5C4A);
  static const Color brandDeep = Color(0xFF063B30);
  static const Color brandBright = Color(0xFF14A383);
  static const Color brandTint = Color(0xFFE8F3EF);
  static const Color brandMist = Color(0xFFF2F8F6);

  // Premium accent (use sparingly)
  static const Color gold = Color(0xFFC79A3B);
  static const Color goldDeep = Color(0xFF7A5A14);
  static const Color goldSoft = Color(0xFFFBF3E0);

  // Neutrals
  static const Color canvas = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFECEFF2);
  static const Color lineSoft = Color(0xFFF1F4F7);
  static const Color textSecondary = Color(0xFF5B6B7C);
  static const Color textTertiary = Color(0xFF8493A3);

  // Semantic
  static const Color success = Color(0xFF12805C);
  static const Color successTint = Color(0xFFE6F5EE);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningTint = Color(0xFFFFF6E3);
  static const Color danger = Color(0xFFC73A3A);
  static const Color dangerTint = Color(0xFFFDECEC);
  static const Color info = Color(0xFF2457A6);
  static const Color infoTint = Color(0xFFE9F0FB);
}

abstract class PartnerRadius {
  PartnerRadius._();
  static double get s => 8.r;
  static double get m => 12.r;
  static double get l => 18.r;
  static double get xl => 22.r;
}

abstract class PartnerShadows {
  PartnerShadows._();

  /// Resting card: Airbnb diffused ambient shadow with subtle elevation.
  static List<BoxShadow> get card => [
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

  /// Floating elements (bottom nav, sticky CTAs, floating pill search bar).
  static List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Deep brand surfaces (wallet card, hero).
  static List<BoxShadow> get brand => const [
        BoxShadow(color: Color(0x33063B30), blurRadius: 24, offset: Offset(0, 12)),
      ];
}

abstract class PartnerGradients {
  PartnerGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF063B30), Color(0xFF0A5C4A)],
  );

  static const LinearGradient ink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1B2E), Color(0xFF16304D)],
  );
}

/// Ek hi typeface poore partner section me.
abstract class PartnerText {
  PartnerText._();

  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.plusJakartaSansTextTheme(base).apply(
        bodyColor: PartnerColors.ink,
        displayColor: PartnerColors.ink,
      );

  static TextStyle title(double size, {Color color = PartnerColors.ink}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size.sp,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle body(double size,
          {Color color = PartnerColors.textSecondary,
          FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        height: 1.4,
      );
}

/// Partner screens ko is theme me wrap kiya jata hai taaki
/// fonts, sheets, dialogs, snackbars sab ek jaise dikhein.
class PartnerTheme extends StatelessWidget {
  const PartnerTheme({super.key, required this.child});

  final Widget child;

  static ThemeData of(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      textTheme: PartnerText.textTheme(base.textTheme),
      primaryTextTheme: PartnerText.textTheme(base.primaryTextTheme),
      scaffoldBackgroundColor: PartnerColors.canvas,
      colorScheme: base.colorScheme.copyWith(
        primary: PartnerColors.brand,
        onPrimary: Colors.white,
        secondary: PartnerColors.brandBright,
        surface: PartnerColors.surface,
        onSurface: PartnerColors.ink,
        error: PartnerColors.danger,
      ),
      dividerTheme: const DividerThemeData(
        color: PartnerColors.lineSoft,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: PartnerColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: PartnerColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: PartnerColors.line,
        centerTitle: false,
        iconTheme: const IconThemeData(color: PartnerColors.ink),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: PartnerColors.ink,
          letterSpacing: -0.2,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: PartnerColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: PartnerColors.surface,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PartnerColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PartnerColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: PartnerColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: PartnerColors.line),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PartnerColors.brand,
        linearTrackColor: PartnerColors.lineSoft,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PartnerColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: PartnerColors.textTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: PartnerColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: PartnerColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: PartnerColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: PartnerColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: PartnerColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PartnerColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PartnerColors.brand,
          side: const BorderSide(color: PartnerColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PartnerColors.brand,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: of(context), child: child);
  }
}

// ================================================================
// SHARED WIDGETS
// ================================================================

/// Standard partner card: white surface, hairline border, layered shadow.
class PartnerCard extends StatelessWidget {
  const PartnerCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.radius,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;
  final Color? borderColor;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? 16.r);
    final box = Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: color ?? PartnerColors.surface,
        borderRadius: r,
        border: Border.all(color: borderColor ?? PartnerColors.line),
        boxShadow: shadow ? PartnerShadows.card : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: box,
      ),
    );
  }
}

/// Section title with optional "See all" action.
class PartnerSectionHeader extends StatelessWidget {
  const PartnerSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel = 'See all',
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: PartnerColors.brand,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PartnerText.title(15)),
              if (subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(subtitle!, style: PartnerText.body(11)),
                ),
            ],
          ),
        ),
        if (onAction != null)
          InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: onAction,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: PartnerText.body(
                      12,
                      color: PartnerColors.brand,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16.sp,
                    color: PartnerColors.brand,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded-square icon chip used in cards, lists and quick actions.
class PartnerIconChip extends StatelessWidget {
  const PartnerIconChip({
    super.key,
    required this.icon,
    this.color = PartnerColors.brand,
    this.background = PartnerColors.brandTint,
    this.size = 40,
    this.iconSize,
    this.circle = false,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double? iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular((size * 0.3).r),
      ),
      child: Icon(icon, color: color, size: (iconSize ?? size * 0.5).sp),
    );
  }
}

enum PartnerTone { brand, success, warning, danger, info, neutral, gold }

/// Small status pill (Verified, Pending, Follow up...).
class PartnerStatusChip extends StatelessWidget {
  const PartnerStatusChip({
    super.key,
    required this.label,
    this.tone = PartnerTone.brand,
    this.icon,
    this.dense = false,
  });

  final String label;
  final PartnerTone tone;
  final IconData? icon;
  final bool dense;

  (Color fg, Color bg) get _colors {
    switch (tone) {
      case PartnerTone.success:
        return (PartnerColors.success, PartnerColors.successTint);
      case PartnerTone.warning:
        return (PartnerColors.warning, PartnerColors.warningTint);
      case PartnerTone.danger:
        return (PartnerColors.danger, PartnerColors.dangerTint);
      case PartnerTone.info:
        return (PartnerColors.info, PartnerColors.infoTint);
      case PartnerTone.neutral:
        return (PartnerColors.textSecondary, PartnerColors.lineSoft);
      case PartnerTone.gold:
        return (PartnerColors.goldDeep, PartnerColors.goldSoft);
      case PartnerTone.brand:
        return (PartnerColors.brand, PartnerColors.brandTint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7.w : 9.w,
        vertical: dense ? 2.h : 3.h,
      ),
      decoration: BoxDecoration(
        color: c.$2,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: c.$1),
            SizedBox(width: 3.w),
          ],
          Text(
            label,
            style: PartnerText.body(
              dense ? 9.5 : 10.5,
              color: c.$1,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Verified / trusted badge for partner identity.
class PartnerVerifiedBadge extends StatelessWidget {
  const PartnerVerifiedBadge({super.key, this.label = 'Verified Partner'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PartnerStatusChip(
      label: label,
      tone: PartnerTone.success,
      icon: Icons.verified_rounded,
    );
  }
}
