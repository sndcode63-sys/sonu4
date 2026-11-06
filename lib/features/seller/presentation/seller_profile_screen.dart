import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/account_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/shimmer.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_dotted_border.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/delete_account_dialog.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../controllers/seller_controller.dart';
import '../../auth/application/auth_controller.dart';



class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key, this.onNavigateTab});

  /// Lets the parent bottom-nav shell switch tabs (e.g. "My Properties &
  /// Drafts" -> Properties tab, "Assigned Partner Details" -> Partner tab).
  final void Function(int tabIndex)? onNavigateTab;

  SellerController get _controller {
    if (Get.isRegistered<SellerController>(tag: 'sellerHome')) {
      return Get.find<SellerController>(tag: 'sellerHome');
    }
    if (Get.isRegistered<SellerController>()) {
      return Get.find<SellerController>();
    }
    return Get.put(SellerController(), tag: 'sellerHome');
  }

  static const Color _mintBorder = Color(0xFFD5EEE2);

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final isFirstLoad = controller.isHomeLoading.value &&
              controller.sellerProfile.value == null &&
              controller.properties.isEmpty;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadSellerHome(silent: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Manage your seller account, assigned partners & documents',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  if (isFirstLoad) ...[
                    _buildSkeleton(),
                  ] else ...[
                    if (controller.homeError.value.isNotEmpty) ...[
                      _buildErrorBanner(controller),
                      SizedBox(height: 16.h),
                    ],

                    _buildProfileCard(context, controller),
                    SizedBox(height: 16.h),

                    _buildAssignedPartnerCard(controller),
                    SizedBox(height: 16.h),

                    _buildStatsGrid(controller),
                    SizedBox(height: 20.h),

                    // Grouped Menu Card with Dividers (Image 1 style)
                    _buildGroupedMenuCard([
                      _SellerMenuItem(
                        icon: Icons.apartment_rounded,
                        title: 'My Properties & Drafts',
                        onTap: () => onNavigateTab?.call(1),
                      ),
                      _SellerMenuItem(
                        icon: Icons.people_outline_rounded,
                        title: 'Assigned Partner Details',
                        onTap: () => onNavigateTab?.call(2),
                      ),
                      _SellerMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              title: Text('DigiNiwas Support', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                              content: Text(
                                'For assistance, property queries, or verification help:\n\nEmail: info@diginiwas.com\nWebsite: www.diginiwas.com',
                                style: GoogleFonts.poppins(fontSize: 13.sp, color: const Color(0xFF475569)),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                      ),
                      _SellerMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => Get.toNamed(AppRoutes.termsOfService),
                      ),
                      _SellerMenuItem(
                        icon: Icons.shield_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                      ),
                    ]),
                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.buyerHome),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C233B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                        ),
                        child: Text(
                          'Switch to Buyer Mode',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Center(
                      child: TextButton(
                        onPressed: () => _confirmLogout(context),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _confirmDeleteAccount(context),
                        icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFDC2626)),
                        label: Text(
                          'Delete Account',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 110.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // Error banner + Skeleton
  // ===========================================================================

  Widget _buildErrorBanner(SellerController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              controller.homeError.value,
              style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () => controller.loadSellerHome(),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget.box(width: double.infinity, height: 260.h, borderRadius: 20.r),
        SizedBox(height: 16.h),
        ShimmerWidget.box(width: double.infinity, height: 170.h, borderRadius: 20.r),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: ShimmerWidget.box(height: 90.h, borderRadius: 16.r)),
            SizedBox(width: 12.w),
            Expanded(child: ShimmerWidget.box(height: 90.h, borderRadius: 16.r)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: ShimmerWidget.box(height: 90.h, borderRadius: 16.r)),
            SizedBox(width: 12.w),
            Expanded(child: ShimmerWidget.box(height: 90.h, borderRadius: 16.r)),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // Profile Details Card
  // ===========================================================================

  Widget _buildProfileCard(BuildContext context, SellerController controller) {
    final profile = controller.sellerProfile.value;
    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'DigiNiwas Seller';
    final email = profile?.email ?? '';
    final phone = profile?.phone ?? '';
    final isVerified = profile?.isVerified ?? false;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showPhotoPickerSheet(context, controller),
            child: Stack(
              children: [
                Obx(() {
                  final localPath = controller.sellerAvatarLocalPath.value;
                  final netUrl = controller.sellerAvatarNetworkUrl.value;
                  final hasLocal = localPath.isNotEmpty && File(localPath).existsSync();
                  final hasNet = netUrl.isNotEmpty;

                  if (hasLocal) {
                    return Container(
                      width: 72.w,
                      height: 72.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.file(
                          File(localPath),
                          width: 72.w,
                          height: 72.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }

                  if (hasNet) {
                    return Container(
                      width: 72.w,
                      height: 72.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: ImageCase(
                          url: netUrl,
                          width: 72.w,
                          height: 72.h,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.person,
                        ),
                      ),
                    );
                  }

                  return Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initialsOf(name),
                        style: GoogleFonts.poppins(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _mintBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                  size: 12.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 4.w),
                Text(
                  isVerified ? 'Verified Property Owner' : 'Verification Pending',
                  style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          if (email.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline_rounded, size: 14.sp, color: AppColors.textSecondary),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          if (phone.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_android_rounded, size: 14.sp, color: AppColors.textSecondary),
                SizedBox(width: 6.w),
                Text(
                  phone,
                  style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  // ===========================================================================
  // Assigned Partner Card
  // ===========================================================================

  Widget _buildAssignedPartnerCard(SellerController controller) {
    final property = controller.progressProperty.value;
    final hasPartner = property?.partnerId != null && property!.partnerId!.isNotEmpty;
    final partnerName = property?.partnerName ?? 'Not assigned yet';
    final isVerified = property?.partnerVerified ?? false;
    final locality = property?.partnerLocality;

    final assignedCount = hasPartner
        ? controller.properties.where((p) => p.partnerId == property.partnerId).length
        : 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onNavigateTab?.call(2),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
          boxShadow: AppDecorations.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Partner',
                  style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Icon(Icons.handshake_outlined, size: 18.sp, color: AppColors.primary),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                ImageCase(
                  url: property?.partnerAvatarUrl,
                  width: 44.w,
                  height: 44.h,
                  fallbackIcon: Icons.person,
                  borderRadius: BorderRadius.circular(50.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      if (isVerified)
                        Row(
                          children: [
                            Icon(Icons.verified, size: 11.sp, color: AppColors.primary),
                            SizedBox(width: 4.w),
                            Text(
                              'Verified Partner',
                              style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (hasPartner)
                  InkWell(
                    onTap: () => _callPartner(property.partnerPhone),
                    borderRadius: BorderRadius.circular(50.r),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _mintBorder),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                      ),
                      child: Icon(Icons.phone_outlined, size: 18.sp, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              hasPartner
                  ? 'Managing $assignedCount of your properties${locality != null && locality.isNotEmpty ? ' in $locality' : ''}'
                  : 'You will be matched with a partner once your property is submitted.',
              style: GoogleFonts.poppins(fontSize: 11.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            if (hasPartner) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: _mintBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: property.partnerOnline == true ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      property.partnerOnline == true ? 'Active & Coordinating' : 'Coordinating your listing',
                      style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _callPartner(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ===========================================================================
  // 4 Statistics Grid
  // ===========================================================================

  Widget _buildStatsGrid(SellerController controller) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _buildStatTile('Total Listed', '${controller.myListingsCount.value}', Icons.apartment_rounded, () => onNavigateTab?.call(1)),
        _buildStatTile('Total Inquiries', '${controller.buyerInterestCount.value}', Icons.chat_bubble_outline_rounded, () => onNavigateTab?.call(3)),
        _buildStatTile('Site Visits', '${controller.siteVisitsCount.value}', Icons.directions_walk_rounded, () => onNavigateTab?.call(3)),
        _buildStatTile('Active Offers', '${controller.offersToReviewCount.value}', Icons.local_offer_outlined, () => onNavigateTab?.call(3)),
      ],
    );
  }

  Widget _buildStatTile(String label, String count, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
          boxShadow: AppDecorations.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5F1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFECEFF2), width: 0.8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16.sp),
                ),
              ],
            ),
            Text(
              count,
              style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Reusable Menu Item
  // ===========================================================================

  Widget _buildGroupedMenuCard(List<_SellerMenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? Radius.circular(22.r) : Radius.zero,
                  bottom: isLast ? Radius.circular(22.r) : Radius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5F1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(item.icon, color: AppColors.primary, size: 20.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFF1F3F5),
                  indent: 56.w,
                  endIndent: 16.w,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // Log Out
  // ===========================================================================

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !context.mounted) return;

    await Get.find<AuthController>().logout();

    if (!context.mounted) return;
    AppToast.success(context, 'Logged out successfully');
    Get.offAllNamed(AppRoutes.chooseRole);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final deleted = await DeleteAccountDialog.show(
      context,
      roleName: 'Seller',
      onConfirmDelete: (reason) async {
        await AccountService.instance.deleteAccount(reason: reason);
        await AccountService.instance.clearAllSessionData();
      },
    );

    if (deleted == true) {
      Get.offAllNamed(AppRoutes.chooseRole);
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar(
          'Account Deleted',
          'Account deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F172A),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      });
    }
  }

  void _showPhotoPickerSheet(BuildContext context, SellerController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Change Profile Photo',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Choose a photo from your gallery or take a new one',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (image != null) {
                          await controller.updateSellerAvatar(image.path);
                          if (context.mounted) {
                            AppToast.success(context, 'Profile photo updated successfully!');
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: AppDottedBorder(
                        radius: 16.r,
                        color: AppColors.primary,
                        backgroundColor: const Color(0xFFF8FAF9),
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAF5F1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24.sp),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Take Photo',
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                            ),
                            Text('Camera', style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (image != null) {
                          await controller.updateSellerAvatar(image.path);
                          if (context.mounted) {
                            AppToast.success(context, 'Profile photo updated successfully!');
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: AppDottedBorder(
                        radius: 16.r,
                        color: const Color(0xFF173554),
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8EEF5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.photo_library_rounded, color: Color(0xFF173554), size: 24.sp),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Choose Gallery',
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                            ),
                            Text('PNG, JPG', style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}

class _SellerMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SellerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}