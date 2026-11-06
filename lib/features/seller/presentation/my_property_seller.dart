import 'dart:io';
import 'package:diginiwas/features/seller/presentation/seller_insights.dart';
import 'package:diginiwas/features/seller/presentation/seller_view_listing.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'seller_notifications_screen.dart';

import '../models/seller_home_feed_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_pill_search_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../controllers/seller_controller.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key, this.tabRequest});

  /// Optional: lets a parent (e.g. Seller Home stat cards) ask this screen to
  /// switch to a tab key: 'all' | 'draft' | 'review' | 'live'.
  final ValueListenable<String?>? tabRequest;

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  static const _tag = 'myPropertiesScreen';

  // DigiNiwas listing WhatsApp number (91 = India country code)
  static const String _listingWhatsAppNumber = '919785322270';

  late final SellerController _controller;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedTabKey = 'all'.obs;
  final Rxn<Map<String, dynamic>> _localDraft = Rxn<Map<String, dynamic>>();

  static const Color _mintBorder = Color(0xFFD5EEE2);
  static const Color _mintBg = Color(0xFFF4FAF7);
  static const Color _darkGreen = Color(0xFF165A54);

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SellerController>(tag: _tag)
        ? Get.find<SellerController>(tag: _tag)
        : Get.put(SellerController(), tag: _tag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadSellerHome();
      }
    });
    _searchController.addListener(() => _searchQuery.value = _searchController.text.trim());
    widget.tabRequest?.addListener(_onTabRequest);
    _onTabRequest();
    _loadLocalDraft();
  }

  @override
  void didUpdateWidget(covariant MyPropertiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabRequest != widget.tabRequest) {
      oldWidget.tabRequest?.removeListener(_onTabRequest);
      widget.tabRequest?.addListener(_onTabRequest);
      _onTabRequest();
    }
  }

  Future<void> _loadLocalDraft() async {
    try {
      final draft = await StorageService.instance.getPropertyDraft();
      _localDraft.value = draft;
    } catch (_) {}
  }

  void _onTabRequest() {
    final key = widget.tabRequest?.value;
    if (key == null) return;
    _selectedTabKey.value = key;
    if (_searchController.text.isNotEmpty) _searchController.clear();
  }

  @override
  void dispose() {
    widget.tabRequest?.removeListener(_onTabRequest);
    _searchController.dispose();
    Get.delete<SellerController>(tag: _tag);
    super.dispose();
  }

  // Buckets the live property stage into one of the 3 status chips shown
  // on screen — Draft / Partner Review / Live (Verified rides along with
  // Partner Review since it's still pre-live).
  String _bucketOf(SellerPropertyBrief p) {
    switch (p.stage) {
      case SellerPropertyStage.live:
        return 'live';
      case SellerPropertyStage.partnerReview:
      case SellerPropertyStage.verified:
        return 'review';
      case SellerPropertyStage.submitted:
        return 'draft';
    }
  }

  List<SellerPropertyBrief> _filtered(List<SellerPropertyBrief> all) {
    var list = all;
    final tab = _selectedTabKey.value;
    if (tab != 'all') {
      list = list.where((p) => _bucketOf(p) == tab).toList();
    }
    final q = _searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
      p.title.toLowerCase().contains(q) ||
          (p.addressLabel ?? '').toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final isFirstLoad =
              _controller.isHomeLoading.value && _controller.properties.isEmpty;
          final all = _controller.properties;
          final hasLocalDraft = _localDraft.value != null;
          final draftCount = all.where((p) => _bucketOf(p) == 'draft').length + (hasLocalDraft ? 1 : 0);
          final reviewCount = all.where((p) => _bucketOf(p) == 'review').length;
          final liveCount = all.where((p) => _bucketOf(p) == 'live').length;
          final totalCount = all.length + (hasLocalDraft ? 1 : 0);
          final visible = _filtered(all);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _controller.loadSellerHome(silent: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 20.h),
                  Text(
                    'My Properties',
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Track listings through your DigiNiwas Partner',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  if (_controller.homeError.value.isNotEmpty) ...[
                    _buildErrorBanner(_controller.homeError.value),
                    SizedBox(height: 12.h),
                  ],

                  // Floating Pill Search Bar (matching modern Airbnb floating search bar)
                  AppPillSearchBar(
                    controller: _searchController,
                    hintText: 'Search my properties...',
                    onChanged: (val) => setState(() {}),
                    onClear: () => setState(() => _searchController.clear()),
                  ),
                  SizedBox(height: 12.h),

                  // Filter square button + Expanded Add Property button
                  Row(
                    children: [
                      Container(
                        height: 44.h,
                        width: 44.w,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: _mintBorder, width: 1.2),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune_rounded, size: 18.sp, color: AppColors.textPrimary),
                          tooltip: 'Filter & Insights',
                          onPressed: () => Get.to(() => const SellerInsightsScreen()),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: SizedBox(
                          height: 44.h,
                          child: ElevatedButton.icon(
                            // CHANGED: ab seedha form nahi, WhatsApp / Manual sheet khulti hai
                            onPressed: _showAddPropertySheet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            icon: Icon(Icons.add, color: Colors.white, size: 18.sp),
                            label: Text(
                              'Add Property',
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Tabs — counts computed live from the fetched property list.
                  SizedBox(
                    height: 36.h,
                    child: Builder(builder: (context) {
                      final tabs = <MapEntry<String, String>>[
                        MapEntry('all', 'All $totalCount'),
                        MapEntry('draft', 'Draft $draftCount'),
                        MapEntry('review', 'Partner Review $reviewCount'),
                        MapEntry('live', 'Live $liveCount'),
                      ];
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: tabs.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final entry = tabs[index];
                          final isSelected = _selectedTabKey.value == entry.key;
                          return GestureDetector(
                            onTap: () => _selectedTabKey.value = entry.key,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF7CE0D3) : Colors.white,
                                borderRadius: BorderRadius.circular(18.r),
                                border: isSelected ? null : Border.all(color: _mintBorder, width: 1.2),
                              ),
                              child: Text(
                                entry.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5.sp,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF0F2544) : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16.h),

                  if (_selectedTabKey.value == 'all' || _selectedTabKey.value == 'draft')
                    _buildLocalDraftBanner(),

                  if (isFirstLoad) ...[
                    _buildSkeletonCard(),
                    SizedBox(height: 16.h),
                    _buildSkeletonCard(),
                  ] else if (visible.isEmpty) ...[
                    _buildEmptyState(all.isEmpty),
                  ] else ...[
                    for (int i = 0; i < visible.length; i++) ...[
                      _buildPropertyCard(visible[i]),
                      if (i != visible.length - 1) SizedBox(height: 16.h),
                    ],
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

  // ---------------------------------------------------------------------
  // Add Property — WhatsApp / Manual bottom sheet
  // ---------------------------------------------------------------------
  void _showAddPropertySheet() {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.92),
        decoration: BoxDecoration(
          color: _mintBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          border: Border.all(color: _mintBorder, width: 1.2),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: _mintBorder,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),

                // ---------- Header ----------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send your details\non WhatsApp',
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F2544),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Just share your property details, photos and location on WhatsApp. DigiNiwas will help you create your listing quickly.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _buildWhatsAppIllustration(),
                  ],
                ),
                SizedBox(height: 16.h),

                // ---------- Buttons ----------
                _sheetButton(
                  label: 'Continue on WhatsApp',
                  icon: Icons.chat_rounded,
                  filled: true,
                  onTap: () async {
                    Get.back();
                    await _openListingWhatsApp();
                  },
                ),
                SizedBox(height: 10.h),
                _sheetButton(
                  label: 'Add Manually Instead',
                  icon: Icons.edit_outlined,
                  filled: false,
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.addProperty);
                  },
                ),
                SizedBox(height: 20.h),

                // ---------- What to send ----------
                _sheetHeading('What to send'),
                SizedBox(height: 10.h),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _sendTile(
                          Icons.apartment_rounded,
                          'Property type',
                          'Residential, Commercial, Plot etc.',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _sendTile(
                          Icons.location_on_outlined,
                          'Location',
                          'Area, landmark or full address',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _sendTile(
                          Icons.currency_rupee_rounded,
                          'Price or rent',
                          'Expected price or monthly rent',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _sendTile(
                          Icons.photo_library_outlined,
                          'Photos & videos',
                          'Clear photos and videos of your property',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // ---------- How it works ----------
                _sheetHeading('How it works'),
                SizedBox(height: 10.h),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _stepCard(1, Icons.near_me_outlined,
                            'Send details', 'Share your property details on WhatsApp'),
                      ),
                      _stepArrow(),
                      Expanded(
                        child: _stepCard(2, Icons.photo_library_outlined,
                            'Share photos', 'Send clear photos and videos'),
                      ),
                      _stepArrow(),
                      Expanded(
                        child: _stepCard(3, Icons.description_outlined,
                            'Get your listing ready', 'Our team will create your listing quickly'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // ---------- Footer note ----------
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F4EB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: _mintBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified_user_outlined,
                            size: 18.sp, color: _darkGreen),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Fast and easy onboarding. A DigiNiwas team member or assigned partner will help prepare your property listing.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _sheetHeading(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 15.sp,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0F2544),
    ),
  );

  Widget _sheetButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? Colors.white : AppColors.textPrimary;
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? _darkGreen : Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: _mintBorder, width: 1.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: filled ? Colors.white : _darkGreen, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: fg, size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _sendTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F0),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _mintBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19.sp, color: _darkGreen),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F2544),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(int number, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _mintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _darkGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 26.w,
                height: 26.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF6F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14.sp, color: _darkGreen),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10.5.sp,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F2544),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 8.5.sp,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepArrow() => SizedBox(
    width: 14.w,
    child: Center(
      child: Icon(Icons.chevron_right_rounded,
          size: 16.sp, color: _darkGreen.withValues(alpha: 0.6)),
    ),
  );

  Widget _buildWhatsAppIllustration() {
    return SizedBox(
      width: 104.w,
      height: 92.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // house
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 72.w,
              height: 54.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCDEBDD),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.home_rounded,
                  size: 36.sp, color: const Color(0xFF8FCBB1)),
            ),
          ),
          // WhatsApp-style chat bubble
          Positioned(
            top: 0,
            left: 2.w,
            child: SizedBox(
              width: 62.w,
              height: 62.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.chat_bubble_rounded,
                      size: 62.w, color: const Color(0xFF25D366)),
                  Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Icon(Icons.call_rounded,
                        size: 26.sp, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openListingWhatsApp() async {
    final message = Uri.encodeComponent(
      'Hi DigiNiwas, I want to list my property. Here are my details:\n\n'
          'Property type:\nLocation:\nPrice:\nBHK / Area:\n\n(Photos attached)',
    );
    final uri = Uri.parse('https://wa.me/$_listingWhatsAppNumber?text=$message');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) AppToast.error(context, 'Could not open WhatsApp.');
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not open WhatsApp.');
    }
  }

  // ---------------------------------------------------------------------
  // Header with DigiNiwas Brand Logo
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 28.h,
              child: Image.asset(
                'assets/images/app_logo_light.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Get.to(() => const SellerNotificationsScreen()),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _mintBorder, width: 0.8),
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
            SizedBox(width: 10.w),
            Obx(() {
              final localPath = _controller.sellerAvatarLocalPath.value;
              final netUrl = _controller.sellerAvatarNetworkUrl.value;
              final hasLocal = localPath.isNotEmpty && File(localPath).existsSync();
              final hasNet = netUrl.isNotEmpty;
              final name = _controller.sellerProfile.value?.name ?? '';

              if (hasLocal) {
                return Container(
                  width: 34.w,
                  height: 34.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: ClipOval(
                    child: Image.file(
                      File(localPath),
                      width: 34.w,
                      height: 34.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }

              if (hasNet) {
                return Container(
                  width: 34.w,
                  height: 34.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: ClipOval(
                    child: ImageCase(
                      url: netUrl,
                      width: 34.w,
                      height: 34.h,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                );
              }

              return Container(
                width: 34.w,
                height: 34.h,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    _initialsOf(name),
                    style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(message, style: GoogleFonts.poppins(fontSize: 11.5.sp, color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noPropertiesAtAll) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _mintBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.apartment_rounded, size: 40.sp, color: Colors.grey.shade400),
          SizedBox(height: 12.h),
          Text(
            noPropertiesAtAll ? 'No properties yet' : 'No properties in this filter',
            style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            noPropertiesAtAll
                ? 'Tap "Add Property" to list your first property.'
                : 'Try a different tab or clear your search.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 240.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _mintBorder, width: 1.2),
      ),
      child: Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Property cards — one variant per live stage.
  // ---------------------------------------------------------------------
  Widget _buildPropertyCard(SellerPropertyBrief p) {
    switch (_bucketOf(p)) {
      case 'live':
        return _buildLiveCard(p);
      case 'review':
        return _buildPartnerReviewCard(p);
      default:
        return _buildDraftCard(p);
    }
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: child,
    );
  }

  Widget _cardImage(SellerPropertyBrief p, {required Widget badge}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          child: ImageCase(
            url: p.imageUrl,
            width: double.infinity,
            height: 140.h,
            fit: BoxFit.cover,
            fallbackIcon: Icons.apartment,
          ),
        ),
        Positioned(top: 12.h, left: 12.w, child: badge),
        Positioned(
          top: 8.h,
          right: 8.w,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white, size: 18.sp),
              padding: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              onSelected: (val) {
                if (val == 'delete') {
                  _confirmDeleteProperty(p);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: const Color(0xFFEF4444), size: 18.sp),
                      SizedBox(width: 8.w),
                      Text('Delete Listing', style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteProperty(SellerPropertyBrief p) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Listing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16.sp, color: const Color(0xFF0F2544))),
        content: Text('Are you sure you want to delete "${p.title}"? This listing will be removed from DigiNiwas.',
            style: GoogleFonts.poppins(fontSize: 12.5.sp, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _controller.deleteSellerProperty(p.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _priceTitleRow(SellerPropertyBrief p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            p.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          formatPrice(p.price),
          style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  String _specsLine(SellerPropertyBrief p) {
    final parts = <String>[];
    if (p.bhkLabel != null) parts.add(p.bhkLabel!);
    if (p.area != null) parts.add(p.area!);
    if (parts.isEmpty && p.category != null) parts.add(p.category!);
    return parts.isEmpty ? 'Details pending' : parts.join(' • ');
  }

  // Partner Review (also covers "Verified" pre-live stage).
  Widget _buildPartnerReviewCard(SellerPropertyBrief p) {
    final isVerifiedStage = p.stage == SellerPropertyStage.verified;
    final hasPartner = (p.partnerName != null && p.partnerName!.trim().isNotEmpty) ||
        (p.partnerId != null && p.partnerId!.trim().isNotEmpty);
    final partnerName = hasPartner
        ? (p.partnerName?.trim().isNotEmpty == true ? p.partnerName!.trim() : 'DigiNiwas Partner')
        : 'Not assigned yet';
    Map<String, dynamic>? visit;
    for (final v in _controller.sellerVisits) {
      if ((v['propertyId'] ?? '').toString() == p.id) {
        visit = v;
        break;
      }
    }
    final visitAt = visit != null
        ? DateTime.tryParse((visit['approvedVisitAt'] ?? visit['requestedVisitAt'] ?? '').toString())
        : null;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardImage(
            p,
            badge: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: const Color(0xFF1B0C3B), borderRadius: BorderRadius.circular(6.r)),
              child: Text(
                'Partner Review',
                style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priceTitleRow(p),
                SizedBox(height: 2.h),
                Text(_specsLine(p),
                    style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: _mintBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: _mintBorder, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14.r,
                            backgroundColor: hasPartner ? AppColors.textPrimary : Colors.grey.shade400,
                            backgroundImage: (hasPartner && p.partnerAvatarUrl != null && p.partnerAvatarUrl!.isNotEmpty)
                                ? NetworkImage(p.partnerAvatarUrl!)
                                : null,
                            child: (!hasPartner || p.partnerAvatarUrl == null || p.partnerAvatarUrl!.isEmpty)
                                ? (hasPartner
                                    ? Text(_initialsOf(partnerName),
                                        style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold))
                                    : const Icon(Icons.person, size: 16, color: Colors.white))
                                : null,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(partnerName,
                                    style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Icon(hasPartner ? Icons.check_circle : Icons.schedule_rounded,
                                        size: 10.sp, color: hasPartner ? _darkGreen : Colors.orange),
                                    SizedBox(width: 3.w),
                                    Text(
                                      hasPartner ? 'Verified Partner' : 'Assignment pending',
                                      style: GoogleFonts.poppins(fontSize: 9.5.sp,
                                          color: hasPartner ? _darkGreen : Colors.orange, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (hasPartner && p.partnerPhone != null && p.partnerPhone!.isNotEmpty)
                            GestureDetector(
                              onTap: () => _openWhatsApp(p.partnerPhone),
                              child: Icon(Icons.chat_bubble_outline_rounded, size: 18.sp, color: _darkGreen),
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      // 3-step timeline with connecting lines
                      _buildPartnerTimeline(isVerifiedStage: isVerifiedStage),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFC),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: _mintBorder, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 13.sp, color: const Color(0xFF2563EB)),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                visitAt != null
                                    ? 'Site visit scheduled: ${formatVisitDateTime(visitAt)}'
                                    : 'Site visit scheduled: 9 Aug, 11:00 AM',
                                style: GoogleFonts.poppins(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showProgressSheet(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F1F3),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('View Progress',
                            style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (hasPartner && p.partnerPhone != null && p.partnerPhone!.isNotEmpty)
                            ? () => _callPartner(p.partnerPhone)
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: (hasPartner && p.partnerPhone != null && p.partnerPhone!.isNotEmpty)
                                  ? _darkGreen
                                  : Colors.grey.shade400,
                              width: 1.2),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(
                            hasPartner ? 'Contact Partner' : 'Not assigned yet',
                            style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: (hasPartner && p.partnerPhone != null && p.partnerPhone!.isNotEmpty)
                                    ? _darkGreen
                                    : Colors.grey)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerTimeline({required bool isVerifiedStage}) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 16.w),
            _timelineStepIcon(isDone: true, isCurrent: false),
            Expanded(child: Container(height: 2.h, color: _darkGreen)),
            _timelineStepIcon(isDone: false, isCurrent: true),
            Expanded(child: Container(height: 2.h, color: Colors.grey.shade300)),
            _timelineStepIcon(isDone: false, isCurrent: false),
            SizedBox(width: 16.w),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 70.w,
              child: Text(
                'Details\nchecked',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            SizedBox(
              width: 80.w,
              child: Text(
                'Site\nverification',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w700, color: _darkGreen),
              ),
            ),
            SizedBox(
              width: 70.w,
              child: Text(
                'Listing\napproval',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timelineStepIcon({required bool isDone, required bool isCurrent}) {
    if (isDone) {
      return Container(
        width: 18.w,
        height: 18.h,
        decoration: const BoxDecoration(
          color: _darkGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 11.sp, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 18.w,
        height: 18.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _darkGreen, width: 2),
        ),
        child: Center(
          child: Container(
            width: 7.w,
            height: 7.h,
            decoration: const BoxDecoration(
              color: _darkGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 18.w,
      height: 18.h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
    );
  }

  // Live listing card
  Widget _buildLiveCard(SellerPropertyBrief p) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardImage(
            p,
            badge: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(6.r)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6.w, height: 6.h, decoration: const BoxDecoration(color: _darkGreen, shape: BoxShape.circle)),
                  SizedBox(width: 4.w),
                  Text(
                    '• Live • Partner Managed',
                    style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: _darkGreen),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priceTitleRow(p),
                SizedBox(height: 2.h),
                Text(_specsLine(p),
                    style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),

                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child:
                      ElevatedButton(
                        onPressed: () => Get.to(() => SellerPropertyDetailsScreen(property: p)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0F1F3),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('View Listing',
                            style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _askPartnerToPromote(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkGreen,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('Ask Partner to Promote',
                            style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCompletionPercentage(SellerPropertyBrief p) {
    int score = 0;
    int total = 7;

    if (p.title.isNotEmpty && !p.title.toLowerCase().contains('untitled')) score++;
    if (p.price != null && p.price! > 0) score++;
    if ((p.locality != null && p.locality!.isNotEmpty) || (p.city != null && p.city!.isNotEmpty)) score++;
    if (p.area != null && p.area!.isNotEmpty) score++;
    if (p.bedrooms != null && p.bedrooms!.isNotEmpty) score++;
    if (p.imageUrl != null && p.imageUrl!.isNotEmpty) score++;
    if (!p.documentsPending) score++;

    final percent = ((score / total) * 100).round();
    return percent.clamp(20, 100);
  }

  Widget _buildLocalDraftBanner() {
    final draft = _localDraft.value;
    if (draft == null) return const SizedBox.shrink();

    final title = (draft['title'] ?? '').toString();
    final displayTitle = title.isNotEmpty ? title : 'Draft Listing In Progress';
    final step = (draft['currentStep'] as num?)?.toInt() ?? 0;
    final percent = (((step + 1) / 7) * 100).round().clamp(15, 95);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _mintBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFFD5EEE2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.edit_note_rounded, color: _darkGreen, size: 26.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Step ${step + 1} of 7',
                        style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    SizedBox(
                      width: 70.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: percent / 100.0,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(_darkGreen),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$percent% complete',
                      style: GoogleFonts.poppins(fontSize: 10.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () async {
                    await Get.toNamed(AppRoutes.addProperty);
                    _loadLocalDraft();
                  },
                  child: Text(
                    'Resume Listing >',
                    style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: _darkGreen),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade500, size: 20.sp),
            tooltip: 'Discard Draft',
            onPressed: () async {
              await StorageService.instance.clearPropertyDraft();
              _localDraft.value = null;
              if (mounted) AppToast.info(context, 'Draft listing discarded.');
            },
          ),
        ],
      ),
    );
  }

  // Draft / submitted card
  Widget _buildDraftCard(SellerPropertyBrief p) {
    final completion = _calculateCompletionPercentage(p);
    final progressValue = completion / 100.0;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(color: AppColors.textSecondary.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: ImageCase(url: p.imageUrl, width: 50.w, height: 50.h, fallbackIcon: Icons.image_outlined),
            )
                : Icon(Icons.image_outlined, size: 24.sp, color: Colors.grey.shade600),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title.isNotEmpty ? p.title : 'Sunset Villa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    SizedBox(
                      width: 70.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(_darkGreen),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$completion% complete',
                      style: GoogleFonts.poppins(fontSize: 10.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.addProperty),
                  child: Text(
                    'Continue Listing >',
                    style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: _darkGreen),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38.w,
            height: 38.h,
            decoration: BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white, size: 18.sp),
              padding: EdgeInsets.zero,
              onPressed: () => Get.toNamed(AppRoutes.addProperty),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------
  void _showProgressSheet(SellerPropertyBrief p) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: _mintBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 6.h),
            Text(stageLabel(p.stage),
                style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
            SizedBox(height: 10.h),
            Text(p.statusNote, style: GoogleFonts.poppins(fontSize: 12.sp, color: AppColors.textSecondary, height: 1.4)),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Future<void> _askPartnerToPromote(SellerPropertyBrief p) async {
    final msgCtrl = TextEditingController(
      text: 'Hi ' + (p.partnerName ?? 'Partner') + ', please help promote/boost my listing "' + p.title + '" for quick sale.',
    );
    String selectedType = 'PROPERTY_BOOST';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF059669)),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Ask Partner to Boost',
                          style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F2544)),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your assigned Partner (' + (p.partnerName ?? 'Partner') + ') will review and reserve credits to boost your listing.',
                  style: GoogleFonts.poppins(fontSize: 11.5.sp, color: const Color(0xFF64748B)),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Promotion Type',
                  style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F2544)),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    ChoiceChip(
                      label: const Text('Standard Boost (7 Days)'),
                      selected: selectedType == 'PROPERTY_BOOST',
                      onSelected: (val) => setSheetState(() => selectedType = 'PROPERTY_BOOST'),
                      selectedColor: const Color(0xFFD1FAE5),
                    ),
                    ChoiceChip(
                      label: const Text('AI Promotion (15 Days)'),
                      selected: selectedType == 'AI_PROMOTION',
                      onSelected: (val) => setSheetState(() => selectedType = 'AI_PROMOTION'),
                      selectedColor: const Color(0xFFFEF3C7),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Message for Partner',
                  style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F2544)),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: msgCtrl,
                  maxLines: 2,
                  style: GoogleFonts.poppins(fontSize: 12.sp),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    contentPadding: EdgeInsets.all(10.w),
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _controller.submitSellerBoostRequest(
                        propertyId: p.id,
                        promotionType: selectedType,
                        message: msgCtrl.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit In-App Boost Request',
                      style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                if (p.partnerPhone != null && p.partnerPhone!.trim().isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final digits = p.partnerPhone!.replaceAll(RegExp(r'[^0-9+]'), '');
                        final message = Uri.encodeComponent(msgCtrl.text);
                        final uri = Uri.parse('https://wa.me/' + digits + '?text=' + message);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                      label: Text(
                        'Or Chat on WhatsApp',
                        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0F2544)),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callPartner(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) AppToast.error(context, "Partner's phone number isn't available yet.");
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      AppToast.error(context, 'Could not open the dialer.');
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) AppToast.error(context, "Partner's contact isn't available yet.");
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppToast.error(context, 'Could not open WhatsApp.');
    }
  }
}