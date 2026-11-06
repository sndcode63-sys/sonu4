import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'seller_notifications_screen.dart';

import '../models/seller_home_feed_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/shimmer.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../controllers/seller_controller.dart';

/// "My DigiNiwas Partner" screen — fully data-driven from [SellerController]
/// (same `tag: 'sellerHome'` instance the Home tab uses, so there's no
/// duplicate network call: whatever `loadSellerHome()` already fetched is
/// reused here reactively via `Obx`).
///
/// Data sources (all real endpoints, already wired in `SellerRepository`):
///   • GET /v1/sellers/:id/properties        → assigned partner snapshot,
///     onboarding stage, "assigned to N properties" count.
///   • GET /v1/visits/partner/:partnerId     → "Next appointment" notice.
///
/// NOTE — no backend endpoint currently exists for a *per-property*
/// checklist/appointment feed, so the 4-step timeline below is derived from
/// the property's onboarding `stage` (submitted -> partnerReview -> verified
/// -> live) rather than a dedicated checklist API. If/when a real checklist
/// endpoint is added, swap `_buildTimelineSteps` to read it directly.
class MyPartnerScreen extends StatelessWidget {
  const MyPartnerScreen({super.key, this.onNavigateTab});

  /// Lets the parent bottom-nav shell switch tabs (e.g. jump to
  /// "Properties" from "View Checklist"). Optional — screen still works
  /// standalone without it.
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

  /// Green outline used on every card/button of this screen.
  Border get _greenBorder => Border.all(color: AppColors.primary, width: 1.2);

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
                  _buildHeader(controller),
                  SizedBox(height: 20.h),

                  Text(
                    'My DigiNiwas Partner',
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Your local expert for verification, buyers and offers',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  if (isFirstLoad) ...[
                    _buildSkeleton(),
                  ] else ...[
                    if (controller.homeError.value.isNotEmpty) ...[
                      _buildErrorBanner(context, controller),
                      SizedBox(height: 16.h),
                    ],

                    _buildPartnerProfileCard(context, controller),
                    SizedBox(height: 16.h),

                    _buildTrustBadgesRow(controller),
                    SizedBox(height: 16.h),

                    if (controller.progressProperty.value != null) ...[
                      _buildPropertyProgressCard(context, controller),
                      SizedBox(height: 16.h),
                    ] else if (controller.properties.isEmpty) ...[
                      _buildNoPropertiesCard(),
                      SizedBox(height: 16.h),
                    ],

                    _buildAllPartnersSection(context, controller),

                    _buildPartnerHandlesCard(),
                    SizedBox(height: 16.h),

                    _buildPrivacyPromiseBox(),
                    SizedBox(height: 16.h),

                    _buildNeedHelpCard(context),
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
  // Header
  // ===========================================================================

  Widget _buildHeader(SellerController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => onNavigateTab?.call(4),
              child: Obx(() {
                final localPath = controller.sellerAvatarLocalPath.value;
                final netUrl = controller.sellerAvatarNetworkUrl.value;
                final hasLocal = localPath.isNotEmpty && File(localPath).existsSync();
                final hasNet = netUrl.isNotEmpty;
                final name = controller.sellerProfile.value?.name ?? '';

                if (hasLocal) {
                  return Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.file(
                        File(localPath),
                        width: 32.w,
                        height: 32.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }

                if (hasNet) {
                  return Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: ClipOval(
                      child: ImageCase(
                        url: netUrl,
                        width: 32.w,
                        height: 32.h,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.person,
                      ),
                    ),
                  );
                }

                return Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initialsOf(name),
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(width: 8.w),
            Text(
              'DigiNiwas',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Get.to(() => const SellerNotificationsScreen()),
          child: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textSecondary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 20.sp),
          ),
        ),
      ],
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  // ===========================================================================
  // Error banner + Skeleton
  // ===========================================================================

  Widget _buildErrorBanner(BuildContext context, SellerController controller) {
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
        ShimmerWidget.box(width: double.infinity, height: 190.h, borderRadius: 20.r),
        SizedBox(height: 16.h),
        ShimmerWidget.box(width: double.infinity, height: 70.h, borderRadius: 16.r),
        SizedBox(height: 16.h),
        ShimmerWidget.box(width: double.infinity, height: 260.h, borderRadius: 20.r),
        SizedBox(height: 16.h),
        ShimmerWidget.box(width: double.infinity, height: 130.h, borderRadius: 20.r),
      ],
    );
  }

  // ===========================================================================
  // Partner Profile Card
  // ===========================================================================

  Widget _buildPartnerProfileCard(BuildContext context, SellerController controller) {
    final property = controller.progressProperty.value;
    final hasPartner = property?.partnerId != null && property!.partnerId!.isNotEmpty;

    final partnerName = property?.partnerName ?? 'Not assigned yet';
    final isOnline = property?.partnerOnline == true;
    final isVerified = property?.partnerVerified ?? false;
    final locality = property?.partnerLocality;

    // "Assigned to N of your properties" - count this seller's properties
    // handled by the same partner.
    final assignedCount = hasPartner
        ? controller.properties.where((p) => p.partnerId == property.partnerId).length
        : 0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: _greenBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  ImageCase(
                    url: property?.partnerAvatarUrl,
                    width: 55.w,
                    height: 55.h,
                    fallbackIcon: Icons.person,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 2.h,
                      right: 2.w,
                      child: Container(
                        width: 12.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (isVerified)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5F1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 12.sp, color: AppColors.primary),
                            SizedBox(width: 4.w),
                            Text(
                              'Verified DigiNiwas Partner',
                              style: GoogleFonts.poppins(fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 4.h),
                    if (locality != null && locality.isNotEmpty)
                      Text(
                        'Location: $locality',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      hasPartner
                          ? 'Assigned to $assignedCount of your properties'
                          : 'You will be matched with a partner once your property is submitted.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasPartner ? () => _openWhatsApp(context, property.partnerPhone) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16.sp),
                  label: Text(
                    'Chat',
                    style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasPartner ? () => _callPartner(context, property.partnerPhone) : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.phone_outlined, color: hasPartner ? AppColors.primary : Colors.grey, size: 16.sp),
                  label: Text(
                    'Call',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: hasPartner ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _callPartner(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      AppToast.error(context, "Partner's phone number isn't available yet.");
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      AppToast.error(context, 'Could not open the dialer.');
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      AppToast.error(context, "Partner's contact isn't available yet.");
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppToast.error(context, 'Could not open WhatsApp.');
    }
  }

  // ===========================================================================
  // Trust Badges Row
  // ===========================================================================

  Widget _buildTrustBadgesRow(SellerController controller) {
    final property = controller.progressProperty.value;
    final isVerified = property?.partnerVerified ?? false;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF7),
        borderRadius: BorderRadius.circular(16.r),
        border: _greenBorder,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustBadgeItem(
            isVerified ? Icons.verified_user_rounded : Icons.verified_user_outlined,
            'Identity Verified',
          ),
          Container(height: 24.h, width: 1, color: Colors.grey.shade300),
          _buildTrustBadgeItem(Icons.star_outline_rounded, 'Local Expert'),
          Container(height: 24.h, width: 1, color: Colors.grey.shade300),
          _buildTrustBadgeItem(Icons.support_agent_outlined, 'DigiNiwas\nSupport'),
        ],
      ),
    );
  }

  Widget _buildTrustBadgeItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.primary),
        SizedBox(width: 6.w),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Property Onboarding Progress Card
  //
  // NOTE: No dedicated checklist endpoint exists yet, so the 4 steps below
  // are derived from `SellerPropertyBrief.stage` (submitted -> partnerReview
  // -> verified -> live) and `documentsPending`, both already parsed from
  // GET /v1/sellers/:id/properties.
  // ===========================================================================

  Widget _buildPropertyProgressCard(BuildContext context, SellerController controller) {
    final property = controller.progressProperty.value!;
    final stage = property.stage;
    final documentsChecked = !property.documentsPending || stage.index >= SellerPropertyStage.verified.index;
    final visitDone = stage.index >= SellerPropertyStage.verified.index;
    final listingLive = stage == SellerPropertyStage.live;
    final visitCurrent = stage == SellerPropertyStage.partnerReview;

    final nextVisit = controller.nextVisitAt.value;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: _greenBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageCase(
                url: property.imageUrl,
                width: 48.w,
                height: 48.h,
                fallbackIcon: Icons.apartment,
                borderRadius: BorderRadius.circular(10.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Onboarding Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: 16.h),

          _buildTimelineStep(title: 'Details received', isCompleted: true, isLast: false),
          _buildTimelineStep(title: 'Documents checked', isCompleted: documentsChecked, isLast: false),
          _buildTimelineStep(title: 'Property visit', isCompleted: visitDone, isCurrent: visitCurrent, isLast: false),
          _buildTimelineStep(title: 'Listing goes live', isCompleted: listingLive, isLast: true),

          SizedBox(height: 14.h),

          if (nextVisit != null)
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF7),
                borderRadius: BorderRadius.circular(12.r),
                border: _greenBorder,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Next appointment: Property visit - ${formatVisitDateTime(nextVisit)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (nextVisit != null) SizedBox(height: 16.h),

          OutlinedButton(
            onPressed: () => onNavigateTab?.call(1),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.2),
              minimumSize: Size(double.infinity, 44.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(
              'View Checklist',
              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: () {
              final phone = property.partnerPhone;
              if (phone == null || phone.trim().isEmpty) {
                AppToast.error(context, "Partner's phone number isn't available yet.");
                return;
              }
              _openWhatsApp(context, phone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C233B),
              elevation: 0,
              side: const BorderSide(color: AppColors.primary, width: 1.2),
              minimumSize: Size(double.infinity, 44.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(
              'Reschedule through Partner',
              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    bool isCompleted = false,
    bool isCurrent = false,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary
                    : isCurrent
                    ? Colors.white
                    : Colors.grey.shade300,
                border: Border.all(
                  color: isCompleted || isCurrent ? AppColors.primary : Colors.grey.shade300,
                  width: isCurrent ? 3 : 1,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                  : isCurrent
                  ? Center(
                child: Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 24.h,
                color: isCompleted ? AppColors.primary : Colors.grey.shade300,
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: isCurrent || isCompleted ? FontWeight.w700 : FontWeight.w500,
              color: isCompleted || isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // All Partners — every distinct partner assigned across the seller's
  // properties. Tap a partner to expand and see full details.
  // ===========================================================================

  Widget _buildAllPartnersSection(BuildContext context, SellerController controller) {
    final byPartner = <String, List<SellerPropertyBrief>>{};
    for (final p in controller.properties) {
      final id = p.partnerId;
      if (id == null || id.isEmpty) continue;
      byPartner.putIfAbsent(id, () => []).add(p);
    }
    if (byPartner.isEmpty) return const SizedBox.shrink();

    final partners = byPartner.entries
        .map((e) => _PartnerInfo(partnerId: e.key, properties: e.value))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: _AllPartnersSection(
        partners: partners,
        onChat: (phone) => _openWhatsApp(context, phone),
        onCall: (phone) => _callPartner(context, phone),
      ),
    );
  }

  // Empty state when the seller hasn't added any property yet.
  Widget _buildNoPropertiesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: _greenBorder,
      ),
      child: Column(
        children: [
          Icon(Icons.apartment_rounded, size: 32.sp, color: AppColors.primary),
          SizedBox(height: 10.h),
          Text(
            'No properties yet',
            style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add your first property to get matched with a DigiNiwas Partner.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () => onNavigateTab?.call(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'Add Property',
              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // What Your Partner Handles Card (static - informational, no API needed)
  // ===========================================================================

  Widget _buildPartnerHandlesCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: _greenBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What your partner\nhandles',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildCheckItem('Property verification'),
                SizedBox(height: 6.h),
                _buildCheckItem('Buyer enquiries'),
                SizedBox(height: 6.h),
                _buildCheckItem('Site visits'),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Icon(Icons.home_work_rounded, color: AppColors.primary, size: 40.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16.sp),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Privacy Promise Box (static - informational, no API needed)
  Widget _buildPrivacyPromiseBox() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F1),
        borderRadius: BorderRadius.circular(16.r),
        border: _greenBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy comes first',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your contact details are never shared directly with buyers. All communication is routed securely.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Need Help with Partner Link - no dedicated support endpoint yet, so
  // this surfaces a toast rather than a dead tap target.
  Widget _buildNeedHelpCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text('DigiNiwas Support', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            content: Text(
              'Need help with your assigned partner or listing?\n\nEmail: info@diginiwas.com\nWebsite: www.diginiwas.com',
              style: GoogleFonts.poppins(fontSize: 13.sp, color: const Color(0xFF475569)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: _greenBorder,
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Need help with your partner?',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// All Partners widgets
// =============================================================================

class _PartnerInfo {
  _PartnerInfo({required this.partnerId, required this.properties});

  final String partnerId;
  final List<SellerPropertyBrief> properties;

  SellerPropertyBrief get first => properties.first;

  /// Best available value across this partner's properties.
  String? _pick(String? Function(SellerPropertyBrief p) get) {
    for (final p in properties) {
      final v = get(p);
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  String get name => _pick((p) => p.partnerName) ?? 'DigiNiwas Partner';
  String? get phone => _pick((p) => p.partnerPhone);
  String? get avatar => _pick((p) => p.partnerAvatarUrl);
  String? get locality => _pick((p) => p.partnerLocality);
  bool get verified => properties.any((p) => p.partnerVerified);
  bool get online => properties.any((p) => p.partnerOnline == true);
}

String _stageLabel(SellerPropertyStage s) {
  switch (s) {
    case SellerPropertyStage.submitted:
      return 'Submitted';
    case SellerPropertyStage.partnerReview:
      return 'Partner review';
    case SellerPropertyStage.verified:
      return 'Verified';
    case SellerPropertyStage.live:
      return 'Live';
  }
}

class _AllPartnersSection extends StatefulWidget {
  const _AllPartnersSection({
    required this.partners,
    required this.onChat,
    required this.onCall,
  });

  final List<_PartnerInfo> partners;
  final void Function(String? phone) onChat;
  final void Function(String? phone) onCall;

  @override
  State<_AllPartnersSection> createState() => _AllPartnersSectionState();
}

class _AllPartnersSectionState extends State<_AllPartnersSection> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Partners',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Tap a partner to see full details',
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 12.h),
        for (final partner in widget.partners) ...[
          _buildPartnerTile(partner),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Widget _buildPartnerTile(_PartnerInfo partner) {
    final expanded = _expandedId == partner.partnerId;
    final count = partner.properties.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFFF4FAF7) : AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.primary, width: expanded ? 2 : 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: expanded ? 0.10 : 0.05),
            blurRadius: expanded ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: () => setState(() => _expandedId = expanded ? null : partner.partnerId),
            child: Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ImageCase(
                        url: partner.avatar,
                        width: 46.w,
                        height: 46.h,
                        fallbackIcon: Icons.person,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      if (partner.online)
                        Positioned(
                          bottom: 1.h,
                          right: 1.w,
                          child: Container(
                            width: 11.w,
                            height: 11.h,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                partner.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (partner.verified) ...[
                              SizedBox(width: 4.w),
                              Icon(Icons.verified_rounded, size: 14.sp, color: AppColors.primary),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '$count ${count == 1 ? 'property' : 'properties'} assigned',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 24.sp),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildDetails(partner),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(_PartnerInfo partner) {
    final phone = partner.phone;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.25)),
          SizedBox(height: 12.h),
          _detailRow(Icons.badge_outlined, 'Status',
              partner.verified ? 'Verified DigiNiwas Partner' : 'Verification pending'),
          _detailRow(Icons.circle, 'Availability', partner.online ? 'Online now' : 'Offline',
              iconColor: partner.online ? Colors.green : Colors.grey, iconSize: 10),
          _detailRow(Icons.location_on_outlined, 'Location', partner.locality ?? 'Not available'),
          _detailRow(Icons.phone_outlined, 'Phone', hasPhone ? phone : 'Not available yet'),
          SizedBox(height: 4.h),
          Text(
            'Assigned properties',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          for (final p in partner.properties) _propertyRow(p),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasPhone ? () => widget.onChat(phone) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 15.sp),
                  label: Text('Chat',
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasPhone ? () => widget.onCall(phone) : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.phone_outlined,
                      color: hasPhone ? AppColors.primary : Colors.grey, size: 15.sp),
                  label: Text('Call',
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: hasPhone ? AppColors.primary : Colors.grey)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? iconColor, double? iconSize}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Icon(icon, size: (iconSize ?? 16).sp, color: iconColor ?? AppColors.primary),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 82.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyRow(SellerPropertyBrief p) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ImageCase(
            url: p.imageUrl,
            width: 38.w,
            height: 38.h,
            fallbackIcon: Icons.apartment,
            borderRadius: BorderRadius.circular(8.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (p.addressLabel != null)
                  Text(
                    p.addressLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              _stageLabel(p.stage),
              style: GoogleFonts.poppins(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
