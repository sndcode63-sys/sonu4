// =====================================================================
// MY PROPERTIES SCREEN (SELLER) — fully wired to live API data via
// SellerController: GET /v1/sellers/:id, /v1/sellers/:id/properties,
// /v1/leads/partner/:partnerId & /v1/visits/partner/:partnerId (scoped
// down to this seller's own properties, same as Seller Home).
// =====================================================================
import 'package:diginiwas/features/seller/presentation/seller_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/shimmer.dart';
import 'seller_notifications_screen.dart';

import '../models/seller_home_feed_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_pill_search_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../controllers/seller_controller.dart';
import 'my_partner.dart';
import 'my_property_seller.dart';
import 'seller_profile_screen.dart';

enum _ListingStatus { live, draft, sold, review }

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _currentIndex = 0;

  late final SellerController _controller;
  late final List<Widget> _screens;

  /// Tells the Properties tab which filter to open (set by the stat cards).
  final ValueNotifier<String?> _propertiesTabRequest = ValueNotifier<String?>(null);

  // Colors used by the design
  static const Color _navy = Color(0xFF0C233B);
  static const Color _mint = Color(0xFFEAF7F1);
  static const Color _mintBg = Color(0xFFF3FBF7);
  static const Color _mintBorder = Color(0xFFD5EEE2);
  static const Color _green = Color(0xFF0B7A4B);
  static const Color _darkGreen = Color(0xFF005B48);

  // Bottom bar item -> screen index mapping
  static const List<int> _navScreenIndex = [0, 1, 3, 4];

  @override
  void initState() {
    super.initState();
    final initialTab = (Get.arguments is Map && Get.arguments['tab'] != null)
        ? (Get.arguments['tab'] as int)
        : 0;
    _currentIndex = initialTab;
    _controller = Get.isRegistered<SellerController>(tag: 'sellerHome')
        ? Get.find<SellerController>(tag: 'sellerHome')
        : Get.put(SellerController(), tag: 'sellerHome');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadSellerHome();
      }
    });

    _screens = [
      _buildHomeBodyContent(), // 0: Home
      MyPropertiesScreen(tabRequest: _propertiesTabRequest), // 1: Properties
      MyPartnerScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)), // 2
      SellerInsightsScreen(onNavigateTab: _goToTab), // 3: Leads / Insights
      SellerProfileScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)), // 4: Menu
    ];
  }

  @override
  void dispose() {
    _propertiesTabRequest.dispose();
    Get.delete<SellerController>(tag: 'sellerHome');
    super.dispose();
  }

  void _goToTab(int index) => setState(() => _currentIndex = index);

  /// Opens the Properties tab on a given filter ('all'|'draft'|'review'|'live').
  void _openPropertiesFiltered(String tabKey) {
    setState(() => _currentIndex = 1);
    // reset first so the same key twice still notifies the listener
    _propertiesTabRequest.value = null;
    _propertiesTabRequest.value = tabKey;
  }

  // ---------------------------------------------------------------------
  // WHATSAPP ADD PROPERTY BOTTOM SHEET
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

  Widget _buildWhatsAppIllustration() {
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.chat_rounded, color: const Color(0xFF25D366), size: 28.sp),
      ),
    );
  }

  Widget _sheetButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? _green : Colors.white,
          foregroundColor: filled ? Colors.white : _navy,
          elevation: filled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: filled ? BorderSide.none : const BorderSide(color: _mintBorder, width: 1.2),
          ),        ),
        icon: Icon(icon, size: 18.sp),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sheetHeading(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13.5.sp,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
    );
  }

  Widget _sendTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _mintBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(int step, IconData icon, String title, String desc) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _mintBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: _green, size: 16.sp),
              ),
              Text(
                '0$step',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: _green.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepArrow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Center(
        child: Icon(Icons.arrow_forward_ios_rounded, size: 10.sp, color: _green),
      ),
    );
  }

  Future<void> _openListingWhatsApp() async {
    const phone = '919876543210'; // Replace with support/listing WhatsApp number
    final uri = Uri.parse('https://wa.me/$phone?text=Hello%20DigiNiwas,%20I%20want%20to%20list%20my%20property.%20Here%20are%20the%20details:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppToast.error(context, 'Could not open WhatsApp.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Floating bar ke peeche content dikhe, isliye extendBody: true
      extendBody: true,
      body: _screens[_currentIndex],
      // Sirf Home tab par: bottom-right "Explore Property" -> Buyer login
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
      _currentIndex == 0 ? _buildExplorePropertyButton() : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildExplorePropertyButton() {
    return SizedBox(
      width: 140.w,
      height: 36.h,
      child: Material(
        color: const Color(0xFF007A5E).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => Get.toNamed(
            AppRoutes.registration,
            arguments: {'role': 'Buyer', 'loginOnly': true},
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_outlined, size: 15.sp, color: Colors.white),
              SizedBox(width: 6.w),
              Text(
                'Explore Properties',
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // HOME BODY
  // ---------------------------------------------------------------------
  Widget _buildHomeBodyContent() {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final isFirstLoad =
            _controller.isHomeLoading.value && _controller.sellerProfile.value == null;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _controller.loadSellerHome(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // bottom padding badhayi taaki floating bar last card ko na dhake
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 14.h),
                AppPillSearchBar(
                  readOnly: true,
                  hintText: 'Search my properties, status, drafts...',
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                SizedBox(height: 14.h),
                if (isFirstLoad)
                  _buildHomeSkeleton()
                else ...[
                  if (_controller.homeError.value.isNotEmpty) ...[
                    _buildErrorBanner(),
                    SizedBox(height: 14.h),
                  ],
                  _buildGreeting(),
                  SizedBox(height: 14.h),
                  _buildHeroBanner(),
                  SizedBox(height: 16.h),
                  _buildStatRow(),
                  SizedBox(height: 16.h),
                  _buildQuickActions(),
                  SizedBox(height: 24.h),
                  _buildMyPropertiesSection(),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------
  // HEADER: Logo Asset + Notification Bell
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/app_logo_dark.png',
              height: 36.h,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Row(
                children: [
                  Icon(Icons.home_work_rounded, color: _green, size: 34.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'DigiNiwas',
                    style: GoogleFonts.poppins(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Get.to(() => const SellerNotificationsScreen());
            _controller.fetchNotifications();
          },
          child: Obx(() {
            final unread = _controller.unreadNotificationsCount.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _mintBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.notifications_rounded, color: _navy, size: 22.sp),
                ),
                if (unread > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      constraints: BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // GREETING
  // ---------------------------------------------------------------------
  String _greetingWord() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildGreeting() {
    final fullName = (_controller.sellerProfile.value?.name ?? '').trim();
    final first = fullName.isEmpty ? '' : fullName.split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.isEmpty ? '${_greetingWord()} 👋' : '${_greetingWord()}, $first 👋',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: _navy,
            height: 1.2,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          "Here's how your properties are doing today",
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // HERO BANNER: Manage Your Properties + Add New Property
  // ---------------------------------------------------------------------
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C233B), Color(0xFF0B5C4A), Color(0xFF0B7A4B)],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -40.w,
            top: -40.h,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 30.w,
            bottom: -50.h,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 18.w,
            top: 18.h,
            child: Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Icon(Icons.home_work_rounded, color: Colors.white, size: 34.sp),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: const Color(0xFF7CE0D3), size: 13.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'Verified partners',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Manage Your\nProperties',
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 6.h),
                SizedBox(
                  width: 0.62.sw,
                  child: Text(
                    'List, track and grow with verified DigiNiwas partners across your city.',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                ElevatedButton.icon(
                  onPressed: _showAddPropertySheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(0, 40.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  icon: Icon(Icons.add_rounded, color: _green, size: 20.sp),
                  label: Text(
                    'Add New Property',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // STAT ROW: Total / Active / Draft / Partner Review
  // ---------------------------------------------------------------------
  Widget _buildStatRow() {
    final all = _controller.properties;
    int draft = 0, partnerReview = 0, active = 0;
    for (final p in all) {
      switch (p.stage) {
        case SellerPropertyStage.live:
          active++;
          break;
        case SellerPropertyStage.partnerReview:
        case SellerPropertyStage.verified:
          partnerReview++;
          break;
        case SellerPropertyStage.submitted:
          draft++;
          break;
      }
    }
    if (all.isEmpty && _controller.sellerProperties.isNotEmpty) {
      for (final p in _controller.sellerProperties) {
        if (p is! Map) continue;
        final rawSt = (p['status'] ?? '').toString().toLowerCase();
        if (rawSt.contains('live') || rawSt.contains('active')) {
          active++;
        } else if (rawSt.contains('review') || rawSt.contains('progress') || rawSt.contains('verified')) {
          partnerReview++;
        } else {
          draft++;
        }
      }
    }
    final total = _controller.myListingsCount.value > 0
        ? _controller.myListingsCount.value
        : (active + draft + partnerReview);

    return Row(
      children: [
        _statCard(Icons.home_rounded, '$total', 'Total\nProperties', const Color(0xFF0C233B),
            const Color(0xFFE8EEF5), () => _openPropertiesFiltered('all')),
        SizedBox(width: 8.w),
        _statCard(Icons.check_circle_rounded, '$active', 'Active\nListings', const Color(0xFF0B7A4B),
            const Color(0xFFE3F6EC), () => _openPropertiesFiltered('live')),
        SizedBox(width: 8.w),
        _statCard(Icons.edit_note_rounded, '$draft', 'Draft\nListings', const Color(0xFFD97706),
            const Color(0xFFFEF3C7), () => _openPropertiesFiltered('draft')),
        SizedBox(width: 8.w),
        _statCard(Icons.rate_review_rounded, '$partnerReview', 'Partner\nReview', const Color(0xFF7C3AED),
            const Color(0xFFEDE9FE), () => _openPropertiesFiltered('review')),
      ],
    );
  }

  Widget _statCard(IconData icon, String count, String label, Color accent, Color tint, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(10.w, 10.h, 8.w, 10.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
            boxShadow: AppDecorations.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10.r)),
                    child: Icon(icon, color: accent, size: 16.sp),
                  ),
                  Icon(Icons.arrow_outward_rounded, size: 12.sp, color: accent.withValues(alpha: 0.55)),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // QUICK ACTIONS
  // ---------------------------------------------------------------------
  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickAction(Icons.add_home_work_rounded, 'Add\nProperty', _showAddPropertySheet),
        SizedBox(width: 10.w),
        _quickAction(Icons.insights_rounded, 'View\nInsights', () => _goToTab(3)),
        SizedBox(width: 10.w),
        _quickAction(Icons.support_agent_rounded, 'My\nPartner', () => _goToTab(2)),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _mintBorder, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: Colors.white, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MY PROPERTIES list
  // ---------------------------------------------------------------------
  Widget _buildMyPropertiesSection() {
    final raw = _controller.sellerProperties.whereType<Map>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Properties',
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _green,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _navy, size: 20.sp),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (raw.isEmpty)
          _buildNoPropertiesCard()
        else
          for (final p in raw) ...[
            _buildPropertyCard(p),
            SizedBox(height: 12.h),
          ],
      ],
    );
  }

  Widget _buildPropertyCard(Map p) {
    final brief = _briefFor(p);
    final status = _statusOf(p, brief);

    final title = (brief?.title.isNotEmpty ?? false)
        ? brief!.title
        : _firstString(p, ['title', 'propertyTitle', 'name']) ?? 'Untitled property';
    final location = _locationOf(p);
    final priceVal = _firstValue(p, ['price', 'expectedPrice', 'askingPrice', 'amount']) ??
        (p['rent'] is Map ? p['rent']['amount'] : null);
    final price = _formatPrice(priceVal);
    final views = (brief != null && brief.views > 0) ? brief.views : _count(p, ['views', 'viewCount', 'viewsCount']);
    final inquiries = _count(p, ['inquiries', 'inquiryCount', 'inquiriesCount', 'leadsCount', 'leads']);
    final likes = (brief != null && brief.saves > 0) ? brief.saves : _count(p, ['likes', 'likesCount', 'favorites', 'favourites', 'favouritesCount', 'saves']);
    final imageUrl = brief?.imageUrl ?? _firstImage(p);

    final partnerId = (brief?.partnerId?.trim().isNotEmpty ?? false)
        ? brief!.partnerId!.trim()
        : (p['assignedPartner'] is Map
            ? (p['assignedPartner']['partnerId'] ?? p['assignedPartner']['_id'])?.toString()
            : (p['partner'] is Map
                ? (p['partner']['_id'] ?? p['partner']['id'])?.toString()
                : (p['partnerId'] ?? p['assignedPartnerId'] ?? p['agentId'])?.toString()));

    final partnerName = (brief?.partnerName?.trim().isNotEmpty ?? false)
        ? brief!.partnerName!.trim()
        : (p['assignedPartner'] is Map
            ? (p['assignedPartner']['name'] ?? p['assignedPartner']['fullName'])?.toString()
            : (p['partner'] is Map
                ? (p['partner']['name'] ?? p['partner']['fullName'])?.toString()
                : (p['partnerName'] ?? p['agentName'])?.toString()));

    final hasPartner = (partnerName != null && partnerName.trim().isNotEmpty) ||
        (partnerId != null && partnerId.trim().isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            onTap: () => setState(() => _currentIndex = 1),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image left side
                  ImageCase(
                    url: imageUrl,
                    width: 112.w,
                    height: 104.h,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.apartment,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _statusChip(status),
                            Icon(Icons.chevron_right_rounded, color: _navy, size: 22.sp),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13.sp, color: AppColors.textSecondary),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          price,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            _miniStat(Icons.remove_red_eye_outlined, views),
                            _miniDivider(),
                            _miniStat(Icons.chat_bubble_outline_rounded, inquiries),
                            _miniDivider(),
                            _miniStat(Icons.favorite_border_rounded, likes),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, indent: 12.w, endIndent: 12.w, color: _mintBorder),
          _buildPartnerRow(brief, hasPartner, partnerNameOverride: partnerName),
        ],
      ),
    );
  }

  Widget _buildPartnerRow(SellerPropertyBrief? brief, bool hasPartner, {String? partnerNameOverride}) {
    final name = hasPartner
        ? ((partnerNameOverride != null && partnerNameOverride.trim().isNotEmpty)
            ? partnerNameOverride.trim()
            : ((brief?.partnerName?.trim().isNotEmpty ?? false)
                ? brief!.partnerName!.trim()
                : 'DigiNiwas Partner'))
        : 'Not assigned yet';
    final sub = hasPartner
        ? ((brief?.partnerLocality?.isNotEmpty == true)
            ? brief!.partnerLocality!
            : (brief?.partnerVerified == true ? 'Verified Partner' : 'Local property expert'))
        : 'Partner will be matched soon';

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      child: Row(
        children: [
          Stack(
            children: [
              ImageCase(
                url: brief?.partnerAvatarUrl,
                width: 42.w,
                height: 42.h,
                fit: BoxFit.cover,
                fallbackIcon: Icons.person,
                borderRadius: BorderRadius.circular(50.r),
              ),
              if (brief?.partnerOnline == true)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned DigiNiwas Partner',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                    height: 1.2,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _roundAction(
            icon: Icons.call_rounded,
            enabled: hasPartner,
            onTap: () => _callPartner(brief?.partnerPhone),
          ),
          SizedBox(width: 8.w),
          _roundAction(
            icon: Icons.chat_rounded,
            enabled: hasPartner,
            onTap: () => _openWhatsApp(brief?.partnerPhone),
          ),
        ],
      ),
    );
  }

  Widget _roundAction({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 56.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFDDF3E8) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _mintBorder, width: 0.8),
        ),
        child: Icon(icon, color: enabled ? _green : Colors.grey, size: 22.sp),
      ),
    );
  }

  Widget _statusChip(_ListingStatus s) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (s) {
      case _ListingStatus.live:
        label = 'Live';
        bg = const Color(0xFFE3F6EB);
        fg = const Color(0xFF16A34A);
        break;
      case _ListingStatus.draft:
        label = 'Draft';
        bg = const Color(0xFFF1F3F5);
        fg = const Color(0xFF475569);
        break;
      case _ListingStatus.sold:
        label = 'Sold';
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF2563EB);
        break;
      case _ListingStatus.review:
        label = 'In Review';
        bg = const Color(0xFFFFF4E0);
        fg = const Color(0xFFD97706);
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15.sp, color: AppColors.textSecondary),
        SizedBox(width: 4.w),
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: _navy,
          ),
        ),
      ],
    );
  }

  Widget _miniDivider() => Container(
    margin: EdgeInsets.symmetric(horizontal: 9.w),
    width: 1,
    height: 12.h,
    color: _mintBorder,
  );

  // ---------------------------------------------------------------------
  // Empty / error / skeleton states
  // ---------------------------------------------------------------------
  Widget _buildNoPropertiesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _mintBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(Icons.apartment_rounded, size: 32.sp, color: _green),
          SizedBox(height: 10.h),
          Text(
            'No properties yet',
            style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: _navy),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add your first property to get matched with a DigiNiwas Partner.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
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
              _controller.homeError.value,
              style: GoogleFonts.poppins(
                  fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: Colors.redAccent),
            ),
          ),
          TextButton(
            onPressed: () => _controller.loadSellerHome(),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                  fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget.box(width: double.infinity, height: 160.h, borderRadius: 20.r),
        SizedBox(height: 14.h),
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              Expanded(child: ShimmerWidget.box(height: 92.h, borderRadius: 14.r)),
              if (i != 3) SizedBox(width: 8.w),
            ],
          ],
        ),
        SizedBox(height: 22.h),
        ShimmerWidget.box(width: double.infinity, height: 190.h, borderRadius: 16.r),
        SizedBox(height: 12.h),
        ShimmerWidget.box(width: double.infinity, height: 190.h, borderRadius: 16.r),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Data helpers (raw property maps from the API)
  // ---------------------------------------------------------------------
  SellerPropertyBrief? _briefFor(Map p) {
    final id = (p['_id'] ?? p['id'] ?? '').toString();
    if (id.isEmpty) return null;
    for (final b in _controller.properties) {
      if (b.id == id) return b;
    }
    return null;
  }

  _ListingStatus _statusOf(Map p, SellerPropertyBrief? brief) {
    final raw = (p['status'] ?? p['listingStatus'] ?? p['approvalStatus'] ?? '')
        .toString()
        .toLowerCase();
    if (raw.contains('sold')) return _ListingStatus.sold;
    if (raw.contains('draft')) return _ListingStatus.draft;
    if (brief?.stage == SellerPropertyStage.live) return _ListingStatus.live;
    return _ListingStatus.review;
  }

  dynamic _firstValue(Map p, List<String> keys) {
    for (final k in keys) {
      final v = p[k];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  String? _firstString(Map p, List<String> keys) => _firstValue(p, keys)?.toString();

  int _count(Map p, List<String> keys) {
    final v = _firstValue(p, keys);
    if (v is List) return v.length;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String? _firstImage(Map p) {
    final imgs = p['images'] ?? (p['media'] is Map ? p['media']['images'] : null) ?? p['photos'] ?? p['imageUrls'];
    if (imgs is List && imgs.isNotEmpty) {
      final f = imgs.first;
      if (f is Map) return (f['url'] ?? f['secure_url'] ?? f['path'])?.toString();
      return f.toString();
    }
    return _firstString(p, ['image', 'imageUrl', 'thumbnail']);
  }

  String _locationOf(Map p) {
    final loc = p['location'];
    String locality = '', city = '', state = '';
    if (loc is Map) {
      locality = (loc['locality'] ?? loc['sector'] ?? loc['area'] ?? '').toString();
      city = (loc['city'] ?? '').toString();
      state = (loc['state'] ?? '').toString();
    }
    if (locality.isEmpty) locality = (p['locality'] ?? p['sector'] ?? '').toString();
    if (city.isEmpty) city = (p['city'] ?? '').toString();
    if (state.isEmpty) state = (p['state'] ?? '').toString();

    final parts = [locality, city, state].where((e) => e.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    final addr = _firstString(p, ['address', 'fullAddress']);
    return addr ?? 'Location not available';
  }

  String _formatPrice(dynamic v) {
    num? n;
    if (v is num) {
      n = v;
    } else if (v != null) {
      n = double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    }
    if (n == null || n <= 0) return 'Price on request';
    String trim(double x) => x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    if (n >= 10000000) return '₹ ${trim(n / 10000000)} Cr';
    if (n >= 100000) return '₹ ${trim(n / 100000)} Lakh';
    return '₹ ${n.toStringAsFixed(0)}';
  }

  // ---------------------------------------------------------------------
  // Call / WhatsApp
  // ---------------------------------------------------------------------
  Future<void> _callPartner(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      AppToast.error(context, "Partner's phone number isn't available yet.");
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
      AppToast.error(context, "Partner's contact isn't available yet.");
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

  // ---------------------------------------------------------------------
  // FLOATING BOTTOM NAV: Home | Add Property | Insights | Profile
  // ---------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: Container(
          height: 66.h,
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(color: _mintBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
              _navItem(Icons.add_rounded, Icons.add_rounded, 'Add Property', 1),
              _navItem(Icons.insights_rounded, Icons.insights_outlined, 'Insights', 2),
              _navItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData activeIcon, IconData icon, String label, int slot) {
    final screenIndex = _navScreenIndex[slot];
    final isSelected = _currentIndex == screenIndex ||
        (slot == 3 && _currentIndex == 2);
    final color = isSelected ? _green : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = screenIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24.sp),
            SizedBox(height: 2.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}