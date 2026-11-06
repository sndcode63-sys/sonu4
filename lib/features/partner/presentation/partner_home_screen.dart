import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../features/partner/models/partner_models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/shimmer.dart';
import 'agent_profile.dart';
import 'agent_property.dart';
import 'agent_lead_screen.dart';
import 'credit_wallet_screen.dart';
import 'boost_property_screen.dart';
import 'partner_bottom_sheets.dart';
import 'task_screen.dart';
import '../../../core/widgets/app_pill_search_bar.dart';

import 'widgets/partner_ui.dart';
// ================================================================
// DESIGN TOKENS
// ================================================================
const Color _primaryTeal = Color(0xFF0A5C4A);
const Color _deepNavy = Color(0xFF0B1B2E);
const Color _ink = Color(0xFF0B1B2E);
const Color _muted = Color(0xFF5B6B7C);
const Color _softGreen = Color(0xFFE8F3EF);

TextStyle _t(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    TextStyle(
      fontSize: size.sp,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  int _currentIndex = 0;
  late final PartnerHomeController c;
  Worker? _tabWorker;

  // Banner carousel state
  final PageController _bannerController = PageController();
  int _bannerCurrentIndex = 0;
  Timer? _bannerTimer;

  // Weekly Performance Graph filter
  String _selectedWeekFilter = 'This Week';
  int? _selectedChartDayIndex;

  @override
  void initState() {
    super.initState();
    c = ensurePartnerHomeController();
    _startBannerAutoSlide();
    _tabWorker = ever(c.requestedTab, (int? index) {
      if (index == null || !mounted) return;
      setState(() => _currentIndex = index);
      c.requestedTab.value = null;
    });
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerController.hasClients) return;
      final next = (_bannerCurrentIndex + 1) % 3;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _tabWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: PartnerColors.canvas,
      body: Column(
        children: [
          _buildTopAppBar(context),
          Expanded(child: _buildCurrentTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, topPad + 10.h, 16.w, 12.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: PartnerColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Obx(() {
                  final pic = c.partnerProfilePic.value;
                  final initials = c.partnerName.value.trim().isNotEmpty
                      ? c.partnerName.value.trim().substring(0, 1).toUpperCase()
                      : 'P';
                  ImageProvider? imageProvider;
                  if (pic.isNotEmpty) {
                    if (pic.startsWith('http')) {
                      imageProvider = NetworkImage(pic);
                    } else {
                      imageProvider = FileImage(File(pic));
                    }
                  }
                  return Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: PartnerColors.brand, width: 1.5),
                    ),
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: _softGreen,
                        shape: BoxShape.circle,
                        image: imageProvider != null
                            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageProvider == null
                          ? Center(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryTeal,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          c.partnerName.value.isNotEmpty ? c.partnerName.value : 'DigiNiwas Partner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(14, FontWeight.w800, _deepNavy, ls: -0.2),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 12.sp, color: PartnerColors.success),
                          SizedBox(width: 3.w),
                          Text('Partner Workspace', style: _t(10.5, FontWeight.w600, _muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await Get.toNamed(AppRoutes.partnerNotifications);
                  c.fetchNotifications();
                },
                child: Obx(() {
                  final unread = c.unreadNotificationsCount.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          color: PartnerColors.canvas,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: PartnerColors.line),
                        ),
                        child: Icon(Icons.notifications_none_rounded, size: 20.sp, color: _ink),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -4.w,
                          top: -4.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                            decoration: BoxDecoration(
                              color: PartnerColors.danger,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: TextStyle(
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.partnerDigitalCard),
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: PartnerColors.brandTint,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.qr_code_2_rounded, size: 20.sp, color: _primaryTeal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const AgentLeadsScreen();
      case 2:
        return const AgentPropertiesScreen();
      case 3:
        return const TaskScreen();
      case 4:
        return const AgentProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 80.h),
      child: ShimmerGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 130.h, width: double.infinity, borderRadius: 20.r),
            SizedBox(height: 14.h),
            ShimmerBox(height: 120.h, width: double.infinity, borderRadius: 20.r),
            SizedBox(height: 18.h),
            ShimmerBox(height: 16.h, width: 120.w, borderRadius: 4.r),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 64.h, borderRadius: 16.r)),
                SizedBox(width: 8.w),
                Expanded(child: ShimmerBox(height: 64.h, borderRadius: 16.r)),
                SizedBox(width: 8.w),
                Expanded(child: ShimmerBox(height: 64.h, borderRadius: 16.r)),
              ],
            ),
            SizedBox(height: 18.h),
            ShimmerBox(height: 180.h, width: double.infinity, borderRadius: 18.r),
            SizedBox(height: 18.h),
            ShimmerBox(height: 16.h, width: 140.w, borderRadius: 4.r),
            SizedBox(height: 10.h),
            ShimmerBox(height: 74.h, width: double.infinity, borderRadius: 16.r),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Obx(() {
      if (c.isBootstrapping.value) {
        return _buildHomeSkeleton();
      }
      if (c.error.value != null && c.partnerId.value.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.error.value ?? 'Failed to load', textAlign: TextAlign.center, style: _t(13, FontWeight.w500, _muted)),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: c.refreshAll,
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal),
                  child: Text('Retry', style: _t(13, FontWeight.w700, Colors.white)),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: c.refreshAll,
        color: _primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 80.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Floating Pill Search Bar (Airbnb / Maps floating style)
              AppPillSearchBar(
                readOnly: true,
                hintText: 'Search properties, buyer leads, site visits...',
                onTap: () => setState(() => _currentIndex = 2),
              ),

              SizedBox(height: 14.h),

              // 1. TOP SLIDING BANNER CAROUSEL (Promote Property, Boost Now, Explore Benefits)
              _buildTopBannerCarousel(),

              SizedBox(height: 14.h),

              // 2. DIGICREDITS BALANCE CARD
              _buildCreditBalanceCard(context),

              SizedBox(height: 18.h),

              // 3. QUICK ACTIONS
              _buildQuickActionsSection(context),

              SizedBox(height: 18.h),

              // 4. TOP PRIORITY SCHEDULE
              _buildTopPriorityScheduleSection(),

              SizedBox(height: 22.h),

              // 5. PERFORMANCE ACTIVITY (4 Colored Cards in 2x2 Grid)
              _buildPerformanceActivitySection(context),

              SizedBox(height: 20.h),

              // 6. WEEKLY PERFORMANCE DYNAMIC GRAPH
              _buildWeeklyPerformanceGraphSection(),

              SizedBox(height: 20.h),

              // 7. TODAY'S PRIORITY SCHEDULE TIMELINE
              _buildTodayPriorityScheduleSection(),

              SizedBox(height: 20.h),

              // 8. TRENDING PROPERTIES CAROUSEL
              _buildTrendingPropertiesSection(),

              SizedBox(height: 20.h),

              // 9. VALUE ADDED SERVICES
              _buildValueAddedServicesSection(),

              SizedBox(height: 16.h),

              // 10. SELLER-ASSISTED SERVICES CARD
              _buildSellerAssistedCard(),

              SizedBox(height: 10.h),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------
  // 1. TOP BANNER CAROUSEL SLIDER (3 SLIDES)
  // ---------------------------------------------------------------
  Widget _buildTopBannerCarousel() {
    final slides = [
      {
        'image': 'assets/images/partner/banner_promote.png',
        'fallbackImage': 'assets/images/banner_partner_promote.png',
        'title': 'Promote Your Listed Property',
        'btn': 'Promote Property >',
        'action': 0,
      },
      {
        'image': 'assets/images/partner/banner_boost.png',
        'fallbackImage': 'assets/images/banner_partner_boost.png',
        'title': 'Boost Your Post',
        'btn': 'Boost Now >',
        'action': 1,
      },
      {
        'image': 'assets/images/partner/banner_top_partner.png',
        'fallbackImage': 'assets/images/banner_partner_top_partner.png',
        'title': 'Become a Top Performing Partner',
        'btn': 'Explore Benefits >',
        'action': 2,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 142.h,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _bannerCurrentIndex = i),
            itemBuilder: (context, index) {
              final s = slides[index];
              return GestureDetector(
                onTap: () => _handleBannerAction(s['action'] as int),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: PartnerShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Image.asset(
                      s['image'] as String,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Image.asset(
                        s['fallbackImage'] as String,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF063B30), Color(0xFF0A4F40), Color(0xFF0A5C4A)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              s['title'] as String,
                              style: _t(13.5, FontWeight.w800, Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final isSel = _bannerCurrentIndex == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isSel ? 22.w : 6.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: isSel ? _primaryTeal : const Color(0xFFC9D2DB),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _handleBannerAction(int action) {
    if (action == 0 || action == 1) {
      if (c.properties.isNotEmpty) {
        Get.to(() => BoostPropertyScreen(property: c.properties.first));
      } else {
        setState(() => _currentIndex = 2);
      }
    } else {
      Get.toNamed(AppRoutes.creditGuidelines);
    }
  }

  // ---------------------------------------------------------------
  // 2. DIGICREDITS BALANCE CARD
  // ---------------------------------------------------------------
  Widget _buildCreditBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: PartnerGradients.brand,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: PartnerShadows.brand,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          children: [
            Positioned(
              right: -40.w,
              top: -50.h,
              child: Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 26.w),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: PartnerColors.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(9.r),
                              border: Border.all(color: PartnerColors.gold.withValues(alpha: 0.45)),
                            ),
                            child: Icon(Icons.account_balance_wallet_rounded, size: 15.sp, color: const Color(0xFFE9C46A)),
                          ),
                          SizedBox(width: 8.w),
                          Text('DigiCredits Balance', style: _t(12, FontWeight.w600, Colors.white70)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.creditGuidelines),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: Row(
                            children: [
                              Text('₹1 = 1 Credit', style: _t(10, FontWeight.w700, Colors.white)),
                              SizedBox(width: 4.w),
                              Icon(Icons.info_outline_rounded, size: 11.sp, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Obx(() => Text(
                            _fmt(c.creditBalance.value),
                            style: _t(32, FontWeight.w800, Colors.white, ls: -0.8, h: 1.0),
                          )),
                      SizedBox(width: 8.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text('Credits', style: _t(13.5, FontWeight.w600, Colors.white70)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 12.sp, color: const Color(0xFFE9C46A)),
                      SizedBox(width: 4.w),
                      Obx(() => Text(
                        '${c.creditValidityText} • 100% Refundable',
                        style: _t(10.5, FontWeight.w500, Colors.white60),
                      )),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => showTopUpCreditsSheet(context),
                          icon: Icon(Icons.add_rounded, size: 16.sp, color: _deepNavy),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                          ),
                          label: Text('Top Up Credits', style: _t(12, FontWeight.w800, _deepNavy)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreditWalletScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                          ),
                          child: Text('View Usage', style: _t(12, FontWeight.w800, Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // 3. QUICK ACTIONS
  // ---------------------------------------------------------------
  Widget _buildQuickActionsSection(BuildContext context) {
    return Obx(() {
      final actions = <(IconData, String, VoidCallback)>[
        (
          Icons.add_home_work_rounded,
          'Add\nProperties',
          () => Get.toNamed(AppRoutes.agentAddProperty),
        ),
        (
          Icons.share_rounded,
          'Share\nProperty',
          () => setState(() => _currentIndex = 2),
        ),
        (
          Icons.person_add_alt_1_rounded,
          'Add\nCustomer',
          () => showCreateManualLeadSheet(context),
        ),
        if (c.isTeamOwner.value)
          (
            Icons.groups_rounded,
            'Team\nManagement',
            () => Get.toNamed(AppRoutes.partnerTeam),
          ),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Quick Actions', onViewAll: () => setState(() => _currentIndex = 2)),
          SizedBox(height: 12.h),
          Row(
            children: actions.map((act) {
              return Expanded(
                child: GestureDetector(
                  onTap: act.$3,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: PartnerColors.line),
                      boxShadow: PartnerShadows.card,
                    ),
                    child: Column(
                      children: [
                        PartnerIconChip(icon: act.$1, size: 44, iconSize: 22),
                        SizedBox(height: 8.h),
                        Text(
                          act.$2,
                          textAlign: TextAlign.center,
                          style: _t(10.5, FontWeight.w700, _ink, h: 1.25),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------
  // 4. TOP PRIORITY SCHEDULE
  // ---------------------------------------------------------------
  Widget _buildTopPriorityScheduleSection() {
    return Obx(() {
      final dash = c.leadsDashboard.value;
      final todayLeads = dash?.todayLeads ?? dash?.totalLeads ?? c.leads.length;
      final siteVisits = c.partnerScheduledVisitsCount > 0 ? c.partnerScheduledVisitsCount : c.visits.length;
      final followUps = c.leads.where((l) => l.status.toLowerCase().contains('follow')).length;

      final items = [
        (Icons.person_rounded, const Color(0xFF2457A6), const Color(0xFFE9F0FB), '$todayLeads', "Today's Leads"),
        (Icons.calendar_month_rounded, const Color(0xFF12805C), const Color(0xFFE6F5EE), '$siteVisits', 'Site Visits'),
        (Icons.phone_in_talk_rounded, const Color(0xFF0A7A66), const Color(0xFFF0FDFA), '$followUps', 'Follow Up'),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Top Priority Schedule', onViewAll: () => setState(() => _currentIndex = 3)),
          SizedBox(height: 12.h),
          Row(
            children: items.map((it) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 3),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: PartnerColors.line),
                      boxShadow: PartnerShadows.card,
                    ),
                    child: Row(
                      children: [
                        PartnerIconChip(
                          icon: it.$1,
                          color: it.$2,
                          background: it.$3,
                          size: 32,
                          iconSize: 16,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.$4, style: _t(16, FontWeight.w800, _ink, ls: -0.3, h: 1.1)),
                              SizedBox(height: 2.h),
                              Text(it.$5, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(9.5, FontWeight.w600, _muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  List<double> _sparklineHeights(List<int> counts) {
    final maxVal = counts.fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
    if (maxVal == 0) {
      return const [8.0, 8.0, 8.0];
    }
    return counts.map((cnt) {
      return (8.0 + (cnt / maxVal) * 16.0).clamp(8.0, 24.0);
    }).toList();
  }

  // ---------------------------------------------------------------
  // 5. PERFORMANCE ACTIVITY (4 CARDS)
  // ---------------------------------------------------------------
  Widget _buildPerformanceActivitySection(BuildContext context) {
    return Obx(() {
      final dash = c.leadsDashboard.value;
      final totalLeads = dash?.totalLeads ?? c.leads.length;
      final contacted = dash?.unlocked ?? c.leads.where((l) => l.isUnlocked).length;
      final siteVisits = c.partnerCompletedVisitsCount > 0 ? c.partnerCompletedVisitsCount : c.visits.length;
      final dealsClosed = dash?.converted ?? c.leads.where((l) => l.status.toLowerCase().contains('convert')).length;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day1 = today.subtract(const Duration(days: 2));
      final day2 = today.subtract(const Duration(days: 1));
      final day3 = today;

      final thisWeekStart = today.subtract(const Duration(days: 7));
      final lastWeekStart = today.subtract(const Duration(days: 14));

      // 1. Leads Given real calculations
      final leadsThisWeek = c.leads.where((l) => l.createdAt != null && l.createdAt!.isAfter(thisWeekStart)).length;
      final leadsLastWeek = c.leads.where((l) => l.createdAt != null && l.createdAt!.isAfter(lastWeekStart) && l.createdAt!.isBefore(thisWeekStart)).length;
      final leadsDay1 = c.leads.where((l) => l.createdAt != null && _isSameDay(l.createdAt!, day1)).length;
      final leadsDay2 = c.leads.where((l) => l.createdAt != null && _isSameDay(l.createdAt!, day2)).length;
      final leadsDay3 = c.leads.where((l) => l.createdAt != null && _isSameDay(l.createdAt!, day3)).length;
      final leadsHeights = _sparklineHeights([leadsDay1, leadsDay2, leadsDay3]);

      String? leadsTrend;
      Color? leadsTrendColor;
      if (totalLeads > 0) {
        if (leadsLastWeek > 0) {
          final diff = (((leadsThisWeek - leadsLastWeek) / leadsLastWeek) * 100).round();
          if (diff > 0) {
            leadsTrend = '↑ $diff%';
            leadsTrendColor = const Color(0xFF129B6C);
          } else if (diff < 0) {
            leadsTrend = '↓ ${diff.abs()}%';
            leadsTrendColor = const Color(0xFFE53935);
          } else {
            leadsTrend = '0%';
            leadsTrendColor = const Color(0xFF6B7280);
          }
        } else if (leadsThisWeek > 0) {
          leadsTrend = '+$leadsThisWeek new';
          leadsTrendColor = const Color(0xFF129B6C);
        } else {
          leadsTrend = '0%';
          leadsTrendColor = const Color(0xFF6B7280);
        }
      }

      // 2. Leads Contacted real calculations
      final contactedDay1 = c.leads.where((l) => l.isUnlocked && l.createdAt != null && _isSameDay(l.createdAt!, day1)).length;
      final contactedDay2 = c.leads.where((l) => l.isUnlocked && l.createdAt != null && _isSameDay(l.createdAt!, day2)).length;
      final contactedDay3 = c.leads.where((l) => l.isUnlocked && l.createdAt != null && _isSameDay(l.createdAt!, day3)).length;
      final contactedHeights = _sparklineHeights([contactedDay1, contactedDay2, contactedDay3]);

      String? contactedTrend;
      Color? contactedTrendColor;
      if (totalLeads > 0) {
        final contactRate = ((contacted / totalLeads) * 100).round();
        contactedTrend = '$contactRate%';
        contactedTrendColor = const Color(0xFF5B57C9);
      }

      // 3. Site Visits real calculations
      DateTime? parseVisitDate(PartnerVisit v) {
        return DateTime.tryParse(v.scheduledAt) ?? DateTime.tryParse(v.raw['createdAt']?.toString() ?? '');
      }
      final visitsDay1 = c.visits.where((v) {
        final dt = parseVisitDate(v);
        return dt != null && _isSameDay(dt, day1);
      }).length;
      final visitsDay2 = c.visits.where((v) {
        final dt = parseVisitDate(v);
        return dt != null && _isSameDay(dt, day2);
      }).length;
      final visitsDay3 = c.visits.where((v) {
        final dt = parseVisitDate(v);
        return dt != null && _isSameDay(dt, day3);
      }).length;
      final visitsHeights = _sparklineHeights([visitsDay1, visitsDay2, visitsDay3]);

      String? visitsTrend;
      Color? visitsTrendColor;
      if (c.visits.isNotEmpty) {
        final completed = c.partnerCompletedVisitsCount;
        final completionRate = ((completed / c.visits.length) * 100).round();
        visitsTrend = '$completionRate%';
        visitsTrendColor = const Color(0xFF12805C);
      }

      // 4. Deals Closed real calculations
      final closedDay1 = c.leads.where((l) => l.status.toLowerCase().contains('convert') && l.createdAt != null && _isSameDay(l.createdAt!, day1)).length;
      final closedDay2 = c.leads.where((l) => l.status.toLowerCase().contains('convert') && l.createdAt != null && _isSameDay(l.createdAt!, day2)).length;
      final closedDay3 = c.leads.where((l) => l.status.toLowerCase().contains('convert') && l.createdAt != null && _isSameDay(l.createdAt!, day3)).length;
      final closedHeights = _sparklineHeights([closedDay1, closedDay2, closedDay3]);

      String? dealsTrend;
      Color? dealsTrendColor;
      if (totalLeads > 0) {
        final convRate = ((dealsClosed / totalLeads) * 100).round();
        dealsTrend = '$convRate%';
        dealsTrendColor = const Color(0xFFB7791F);
      }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Performance Activity', onViewAll: () => setState(() => _currentIndex = 1)),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'Leads Given',
                value: '$totalLeads',
                trend: leadsTrend,
                trendColor: leadsTrendColor,
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF2457A6),
                iconBg: const Color(0xFFD6E4F8),
                cardBg: const Color(0xFFF0F7FF),
                cardBorder: const Color(0xFFD6E4F8),
                chartColor: const Color(0xFF93C5FD),
                chartHeights: leadsHeights,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _metricCard(
                title: 'Leads Contacted',
                value: '$contacted',
                trend: contactedTrend,
                trendColor: contactedTrendColor,
                icon: Icons.phone_in_talk_rounded,
                iconColor: const Color(0xFF5B57C9),
                iconBg: const Color(0xFFE8E6FA),
                cardBg: const Color(0xFFFAF5FF),
                cardBorder: const Color(0xFFE8E6FA),
                chartColor: const Color(0xFFC4B5FD),
                chartHeights: contactedHeights,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                title: 'Site Visits',
                value: '$siteVisits',
                trend: visitsTrend,
                trendColor: visitsTrendColor,
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF12805C),
                iconBg: const Color(0xFFDAF1E4),
                cardBg: const Color(0xFFEEF8F2),
                cardBorder: const Color(0xFFDAF1E4),
                chartColor: const Color(0xFFB5E4CC),
                chartHeights: visitsHeights,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _metricCard(
                title: 'Deals Closed',
                value: '$dealsClosed',
                trend: dealsTrend,
                trendColor: dealsTrendColor,
                icon: Icons.handshake_rounded,
                iconColor: const Color(0xFFB7791F),
                iconBg: const Color(0xFFFEF08A),
                cardBg: const Color(0xFFFEFCE8),
                cardBorder: const Color(0xFFFEF08A),
                chartColor: const Color(0xFFFDE047),
                chartHeights: closedHeights,
              ),
            ),
          ],
        ),
      ],
    );
    });
  }

  Widget _metricCard({
    required String title,
    required String value,
    String? trend,
    Color? trendColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color cardBorder,
    required Color chartColor,
    required List<double> chartHeights,
  }) {
    final effectiveTrendColor = trendColor ?? iconColor;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: PartnerColors.line),
        boxShadow: PartnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PartnerIconChip(icon: icon, color: iconColor, background: iconBg, size: 32, iconSize: 17),
              if (trend != null && trend.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: effectiveTrendColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(trend, style: _t(10, FontWeight.w800, effectiveTrendColor)),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(title, style: _t(11, FontWeight.w600, _muted)),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: _t(24, FontWeight.w800, _ink, ls: -0.6, h: 1.0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartHeights.map((h) {
                  return Container(
                    margin: EdgeInsets.only(left: 3.w),
                    width: 4.5.w,
                    height: h.h,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // 6. WEEKLY PERFORMANCE DYNAMIC GRAPH
  // ---------------------------------------------------------------
  Widget _buildWeeklyPerformanceGraphSection() {
    return Obx(() {
      final now = DateTime.now();
      final mondayOffset = (now.weekday - 1) % 7;
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: mondayOffset));
      final weekStart = _selectedWeekFilter == 'Last Week'
          ? monday.subtract(const Duration(days: 7))
          : monday;

      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final List<({String day, int given, int contacted})> weekData = [];

      for (int i = 0; i < 7; i++) {
        final targetDay = weekStart.add(Duration(days: i));
        final dayStr = dayNames[i];

        int givenCount = 0;
        int contactedCount = 0;

        for (final l in c.leads) {
          final dt = l.createdAt?.toLocal();
          if (dt != null && dt.year == targetDay.year && dt.month == targetDay.month && dt.day == targetDay.day) {
            givenCount++;
            if (l.isUnlocked) contactedCount++;
          }
        }

        // If leads exist but have unparseable dates, distribute to today
        if (c.leads.isNotEmpty && givenCount == 0 && targetDay.day == now.day && _selectedWeekFilter == 'This Week') {
          givenCount = c.leads.length;
          contactedCount = c.leads.where((l) => l.isUnlocked).length;
        }

        weekData.add((day: dayStr, given: givenCount, contacted: contactedCount));
      }

      int maxVal = 0;
      for (final w in weekData) {
        if (w.given > maxVal) maxVal = w.given;
        if (w.contacted > maxVal) maxVal = w.contacted;
      }
      final double maxScale = maxVal > 0 ? (maxVal <= 5 ? 5 : (maxVal <= 10 ? 10 : (maxVal <= 20 ? 20 : maxVal.toDouble()))) : 10.0;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: PartnerShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Weekly Performance', style: _t(14.5, FontWeight.w800, _ink)),
                PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _selectedWeekFilter = val),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'This Week', child: Text('This Week')),
                    const PopupMenuItem(value: 'Last Week', child: Text('Last Week')),
                    const PopupMenuItem(value: 'This Month', child: Text('This Month')),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFE3E8ED)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedWeekFilter, style: _t(10.5, FontWeight.w600, const Color(0xFF4B5B6C))),
                        SizedBox(width: 4.w),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14.sp, color: const Color(0xFF4B5B6C)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Legend
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: const Color(0xFF6FD8BD), borderRadius: BorderRadius.circular(2.r)),
                ),
                SizedBox(width: 6.w),
                Text('Leads Given', style: _t(10, FontWeight.w500, _muted)),
                SizedBox(width: 16.w),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: _primaryTeal, borderRadius: BorderRadius.circular(2.r)),
                ),
                SizedBox(width: 6.w),
                Text('Leads Contacted', style: _t(10, FontWeight.w500, _muted)),
              ],
            ),
            SizedBox(height: 16.h),
            // Dynamic Dual-Bar Chart
            SizedBox(
              height: 125.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Y-axis labels
                  SizedBox(
                    width: 22.w,
                    height: 100.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${maxScale.toInt()}', style: _t(9, FontWeight.w500, const Color(0xFF8493A3))),
                        Text('${(maxScale * 0.75).toInt()}', style: _t(9, FontWeight.w500, const Color(0xFF8493A3))),
                        Text('${(maxScale * 0.5).toInt()}', style: _t(9, FontWeight.w500, const Color(0xFF8493A3))),
                        Text('${(maxScale * 0.25).toInt()}', style: _t(9, FontWeight.w500, const Color(0xFF8493A3))),
                        Text('0', style: _t(9, FontWeight.w500, const Color(0xFF8493A3))),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.w),
                  // Chart Bars Area with Horizontal Grid Lines
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 100.h,
                          child: Stack(
                            children: [
                              // 5 Horizontal Grid Lines
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(5, (_) => Container(height: 1, color: const Color(0xFFEEF2F5))),
                              ),
                              // Grouped Bars for Mon - Sun
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(weekData.length, (idx) {
                                  final item = weekData[idx];
                                  final isSelected = _selectedChartDayIndex == idx;

                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedChartDayIndex = isSelected ? null : idx;
                                    }),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Cyan Bar: Leads Given
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 6.5.w,
                                          height: item.given > 0
                                              ? (item.given / maxScale).clamp(0.08, 1.0) * 92.h
                                              : 2.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6FD8BD),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
                                          ),
                                        ),
                                        SizedBox(width: 2.5.w),
                                        // Dark Teal Bar: Leads Contacted
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 6.5.w,
                                          height: item.contacted > 0
                                              ? (item.contacted / maxScale).clamp(0.08, 1.0) * 92.h
                                              : 2.h,
                                          decoration: BoxDecoration(
                                            color: _primaryTeal,
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(3.r)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        // X-axis Day Labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(weekData.length, (idx) {
                            final item = weekData[idx];
                            final isSelected = _selectedChartDayIndex == idx;
                            return Text(
                              item.day,
                              style: _t(
                                9.5,
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                                isSelected ? _primaryTeal : const Color(0xFF5B6B7C),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedChartDayIndex != null) ...[
              SizedBox(height: 8.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${weekData[_selectedChartDayIndex!].day}: ${weekData[_selectedChartDayIndex!].given} Given • ${weekData[_selectedChartDayIndex!].contacted} Contacted',
                    style: _t(10.5, FontWeight.w700, _primaryTeal),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------
  // 7. TODAY'S PRIORITY SCHEDULE (TIMELINE)
  // ---------------------------------------------------------------
  Widget _buildTodayPriorityScheduleSection() {
    return Obx(() {
      final List<Map<String, dynamic>> scheduleItems = [];

      // 1. Real visits from c.visits
      for (final v in c.visits) {
        final statusLower = v.status.toLowerCase();
        final isCompleted = statusLower.contains('complet');
        final isConfirmed = statusLower.contains('confirm') || statusLower.contains('schedul') || statusLower.contains('accept');
        final dotColor = isCompleted
            ? const Color(0xFF129B6C)
            : (isConfirmed ? const Color(0xFF3B7DD8) : const Color(0xFFD9961F));

        final timeStr = v.scheduledAt.isNotEmpty
            ? (v.scheduledAt.length > 10 ? v.scheduledAt.substring(11, 16) : v.scheduledAt)
            : 'Scheduled';

        scheduleItems.add({
          'time1': timeStr,
          'time2': v.propertyCity.isNotEmpty ? v.propertyCity : 'Visit',
          'dotColor': dotColor,
          'title': v.propertyTitle.isNotEmpty ? v.propertyTitle : 'Site Visit: ${v.buyerName}',
          'subtitle': v.buyerName.isNotEmpty ? 'Buyer: ${v.buyerName}' : 'Site Visit Appointment',
          'tags': [
            ('Site Visit', const Color(0xFFE9F0FB), const Color(0xFF2457A6)),
            (v.status.isNotEmpty ? v.status.toUpperCase() : 'SCHEDULED', const Color(0xFFE6F5EE), const Color(0xFF12805C)),
          ],
        });
      }

      // 2. Real follow-ups from c.leads
      for (final l in c.leads.where((l) => l.status.toLowerCase().contains('follow') || l.status.toLowerCase().contains('contact'))) {
        scheduleItems.add({
          'time1': 'Follow Up',
          'time2': l.city.isNotEmpty ? l.city : 'Lead',
          'dotColor': const Color(0xFFD9961F),
          'title': 'Follow Up - ${l.name}',
          'subtitle': 'Budget: ${l.budget.isNotEmpty ? l.budget : "Flexible"} • ${l.location}',
          'tags': [
            ('Follow Up', const Color(0xFFFFFBEB), const Color(0xFFB7791F)),
            (l.propertyType.isNotEmpty ? l.propertyType : 'Active Lead', const Color(0xFFEEF8F2), const Color(0xFF16A34A)),
          ],
        });
      }

      if (scheduleItems.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Today's Priority Schedule", onViewAll: () => setState(() => _currentIndex = 3)),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x080B1B2E),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 34.sp, color: _primaryTeal),
                  SizedBox(height: 8.h),
                  Text('No scheduled tasks for today', style: _t(13, FontWeight.w700, _ink)),
                  SizedBox(height: 4.h),
                  Text(
                    'You are all caught up! New site visits and follow-ups will appear here.',
                    textAlign: TextAlign.center,
                    style: _t(11, FontWeight.w400, _muted),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Today's Priority Schedule", onViewAll: () => setState(() => _currentIndex = 3)),
          SizedBox(height: 12.h),
          ...List.generate(scheduleItems.length, (index) {
            final item = scheduleItems[index];
            final tags = item['tags'] as List<(String, Color, Color)>;

            return GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x080B1B2E),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['time1'] as String, style: _t(11, FontWeight.w700, _ink)),
                        Text(item['time2'] as String, style: _t(10, FontWeight.w500, _muted)),
                      ],
                    ),
                    SizedBox(width: 10.w),
                    // Timeline Dot
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: item['dotColor'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Info & Tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(12.5, FontWeight.w800, _ink)),
                          SizedBox(height: 2.h),
                          Text(item['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(10.5, FontWeight.w400, _muted)),
                          SizedBox(height: 6.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: tags.map((t) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: t.$2,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(t.$1, style: _t(9.5, FontWeight.w600, t.$3)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: const Color(0xFF8493A3), size: 18.sp),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  // ---------------------------------------------------------------
  // 8. TRENDING PROPERTIES CAROUSEL (WITH "VIEW LEADS" BUTTON)
  // ---------------------------------------------------------------
  Widget _buildTrendingPropertiesSection() {
    return Obx(() {
      final List<({String title, String address, String price, String imageUrl})> realList = [];
      if (c.trendingProperties.isNotEmpty) {
        for (final item in c.trendingProperties.take(6)) {
          final title = asString(item['title']) ?? asString(item['name']) ?? 'Property';
          final address = asString(item['address']) ?? asString(item['city']) ?? asString(asMap(item['location'])['city']) ?? '';
          final price = asString(item['price']) ?? asString(item['priceLabel']) ?? '₹ Negotiable';
          final imgUrl = asString(item['imageUrl']) ?? asString(item['image']) ?? asString(item['heroImage']) ?? '';
          realList.add((title: title, address: address, price: price, imageUrl: imgUrl));
        }
      } else if (c.properties.isNotEmpty) {
        for (final p in c.properties.take(6)) {
          final address = p.address.isNotEmpty ? p.address : p.city;
          final price = p.priceLabel.isNotEmpty ? p.priceLabel : '₹ Negotiable';
          final imgUrl = (p.imageUrl != null && p.imageUrl!.isNotEmpty) ? p.imageUrl! : '';
          realList.add((title: p.title, address: address, price: price, imageUrl: imgUrl));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Trending Properties', onViewAll: () => setState(() => _currentIndex = 2)),
          SizedBox(height: 12.h),
          if (realList.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x080B1B2E),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.holiday_village_outlined, size: 34.sp, color: _primaryTeal),
                  SizedBox(height: 8.h),
                  Text('No trending properties yet', style: _t(13, FontWeight.w700, _ink)),
                  SizedBox(height: 4.h),
                  Text(
                    'List your verified properties to start receiving buyer leads.',
                    textAlign: TextAlign.center,
                    style: _t(11, FontWeight.w400, _muted),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.agentAddProperty),
                    icon: const Icon(Icons.add_home_work_rounded, size: 16, color: Colors.white),
                    label: Text('Add Properties', style: _t(12, FontWeight.w700, Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: realList.map((item) {
                  final String title = item.title;
                  final String address = item.address.isNotEmpty ? item.address : '';
                  final String price = item.price.isNotEmpty ? item.price : '₹ Negotiable';
                  final String imgUrl = item.imageUrl;

                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Container(
                      width: 240.w,
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0C0B1B2E),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14.r),
                                child: imgUrl.isNotEmpty
                                    ? Image.network(
                                        imgUrl,
                                        height: 110.h,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 110.h,
                                          color: _softGreen,
                                          child: Icon(Icons.apartment_rounded, color: _primaryTeal, size: 36.sp),
                                        ),
                                      )
                                    : Container(
                                        height: 110.h,
                                        width: double.infinity,
                                        color: _softGreen,
                                        child: Icon(Icons.apartment_rounded, color: _primaryTeal, size: 36.sp),
                                      ),
                              ),
                              Positioned(
                                top: 8.h,
                                left: 8.w,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text('Featured', style: _t(9.5, FontWeight.w800, _primaryTeal)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, FontWeight.w800, _ink)),
                          SizedBox(height: 2.h),
                          Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11, FontWeight.w400, _muted)),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(price, style: _t(14, FontWeight.w800, _primaryTeal)),
                              ElevatedButton(
                                onPressed: () => setState(() => _currentIndex = 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryTeal,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                ),
                                child: Text('View Leads', style: _t(10.5, FontWeight.w800, Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    });
  }

  // ---------------------------------------------------------------
  // 9. VALUE ADDED SERVICES
  // ---------------------------------------------------------------
  Widget _buildValueAddedServicesSection() {
    final services = [
      (Icons.account_balance_rounded, 'Home Loan\nAssistance'),
      (Icons.gavel_rounded, 'Legal &\nDocument'),
      (Icons.fact_check_rounded, 'Inspect\nProperty'),
      (Icons.home_repair_service_rounded, 'Home\nRenovation'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Value Added Services'),
        SizedBox(height: 2.h),
        Text(
          'Promote & grow your real estate business with DigiNiwas partner tools.',
          style: _t(11.5, FontWeight.w400, _muted, h: 1.35),
        ),
        SizedBox(height: 12.h),
        Row(
          children: services.map((s) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x080B1B2E),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: const BoxDecoration(color: _softGreen, shape: BoxShape.circle),
                      child: Icon(s.$1, color: _primaryTeal, size: 20.sp),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      s.$2,
                      textAlign: TextAlign.center,
                      style: _t(10, FontWeight.w600, _ink, h: 1.2),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // 10. SELLER-ASSISTED SERVICES CARD
  // ---------------------------------------------------------------
  Widget _buildSellerAssistedCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: PartnerGradients.ink,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: PartnerShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(Icons.handshake_rounded, color: const Color(0xFFE9C46A), size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seller-assisted Services', style: _t(14, FontWeight.w800, Colors.white, ls: -0.2)),
                SizedBox(height: 4.h),
                Text(
                  'Assist sellers with legal verification, photography, and direct listing management.',
                  style: _t(11.5, FontWeight.w500, Colors.white70, h: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------
  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return PartnerSectionHeader(title: title, onAction: onViewAll);
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: Container(
          height: 66.h,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: PartnerColors.line),
            boxShadow: PartnerShadows.floating,
          ),
          child: Row(
            children: [
              _navItem(icon: Icons.home_rounded, outline: Icons.home_outlined, label: 'Home', index: 0),
              _navItem(icon: Icons.people_alt_rounded, outline: Icons.people_alt_outlined, label: 'Leads', index: 1),
              _navItem(icon: Icons.apartment_rounded, outline: Icons.apartment_outlined, label: 'Properties', index: 2),
              _navItem(icon: Icons.assignment_rounded, outline: Icons.assignment_outlined, label: 'Tasks', index: 3),
              _navItem(icon: Icons.person_rounded, outline: Icons.person_outline_rounded, label: 'Profile', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData outline,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(18.r),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: isSelected ? PartnerColors.brandTint : Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? icon : outline,
                  color: isSelected ? _primaryTeal : PartnerColors.textTertiary,
                  size: 22.sp,
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  maxLines: 1,
                  style: _t(
                    9.5,
                    isSelected ? FontWeight.w800 : FontWeight.w600,
                    isSelected ? _primaryTeal : PartnerColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
