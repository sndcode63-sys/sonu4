import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:diginiwas/core/widgets/app_toast.dart';
import 'package:diginiwas/features/partner/controllers/partner_home_controller.dart';
import 'package:diginiwas/features/partner/models/partner_models.dart';
import 'package:diginiwas/features/partner/presentation/credit_wallet_screen.dart';
import 'package:diginiwas/features/partner/presentation/partner_bottom_sheets.dart';

import 'widgets/partner_ui.dart';
/// Unified Model for dynamic display (supports both API PromotionPlanModel and safe offline fallback)
class _UiPlanItem {
  final String id;
  final String code;
  final String title;
  final int days;
  final String daysBadge;
  final int costCredits;
  final String priceLabel;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<({IconData icon, String text})> featureTags;

  const _UiPlanItem({
    required this.id,
    required this.code,
    required this.title,
    required this.days,
    required this.daysBadge,
    required this.costCredits,
    required this.priceLabel,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.featureTags,
  });

  factory _UiPlanItem.fromApiModel(PromotionPlanModel m) {
    IconData ic = Icons.rocket_launch_rounded;
    Color icColor = const Color(0xFF12805C);
    Color icBg = const Color(0xFFD3EEDF);

    List<({IconData icon, String text})> tags = [];

    if (m.code.contains('AI')) {
      ic = Icons.auto_awesome_rounded;
      icColor = const Color(0xFFB7791F);
      icBg = const Color(0xFFFEF3C7);
      tags = const [
        (icon: Icons.psychology_rounded, text: 'AI Suggested Properties'),
        (icon: Icons.description_outlined, text: 'Property Stories'),
        (icon: Icons.groups_outlined, text: 'AI matching'),
      ];
    } else if (m.code.contains('PREMIUM') || m.code.contains('PARTNER')) {
      ic = Icons.workspace_premium_rounded;
      icColor = const Color(0xFF2457A6);
      icBg = const Color(0xFFD6E4F8);
      tags = const [
        (icon: Icons.star_rounded, text: 'All AI benefits'),
        (icon: Icons.campaign_rounded, text: '7 days Meta Ads'),
        (icon: Icons.videocam_outlined, text: 'Professional videography'),
        (icon: Icons.event_available_rounded, text: 'Appointment help'),
      ];
    } else if (m.code.contains('PLATINUM')) {
      ic = Icons.diamond_rounded;
      icColor = const Color(0xFF5B57C9);
      icBg = const Color(0xFFE8E6FA);
      tags = const [
        (icon: Icons.workspace_premium_rounded, text: 'All premium benefits'),
        (icon: Icons.bar_chart_rounded, text: 'Custom Meta services'),
        (icon: Icons.shield_outlined, text: 'Priority placement'),
        (icon: Icons.assignment_turned_in_outlined, text: 'Admin approval'),
      ];
    } else {
      tags = const [
        (icon: Icons.star_rounded, text: 'Recommended for You'),
        (icon: Icons.location_on_outlined, text: 'Popular Near Location'),
        (icon: Icons.visibility_outlined, text: 'Higher visibility'),
      ];
    }

    return _UiPlanItem(
      id: m.id,
      code: m.code,
      title: m.name,
      days: m.durationDays,
      daysBadge: '${m.durationDays} Days',
      costCredits: m.credits,
      priceLabel: m.code.contains('PLATINUM') ? '₹1,999 + Custom' : '${m.credits} Credits',
      description: m.description.isNotEmpty
          ? m.description
          : 'High visibility boost to reach more genuine buyers.',
      icon: ic,
      iconColor: icColor,
      iconBg: icBg,
      featureTags: tags,
    );
  }
}

class BoostPropertyScreen extends StatefulWidget {
  final PartnerProperty? property;
  final int initialTabIndex;

  const BoostPropertyScreen({
    super.key,
    this.property,
    this.initialTabIndex = 0,
  });

  @override
  State<BoostPropertyScreen> createState() => _BoostPropertyScreenState();
}

class _BoostPropertyScreenState extends State<BoostPropertyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPropertyPlanIndex = 1; // Default AI Promotion as shown in user image
  int _selectedProfilePlanIndex = 0;
  PartnerProperty? _selectedProperty;
  bool _isSubmitting = false;
  bool _isAccordionExpanded = true;

  // Exact 4 Plans matching user screenshot
  final List<_UiPlanItem> _fallbackPropertyPlans = const [
    _UiPlanItem(
      id: 'plan_std',
      code: 'STANDARD_BOOST',
      title: 'Standard Boosting',
      days: 7,
      daysBadge: '7 Days',
      costCredits: 99,
      priceLabel: '99 Credits',
      description: 'Get more views and enquiries for your property listing.',
      icon: Icons.rocket_launch_rounded,
      iconColor: Color(0xFF12805C),
      iconBg: Color(0xFFD3EEDF),
      featureTags: [
        (icon: Icons.star_rounded, text: 'Recommended for You'),
        (icon: Icons.location_on_outlined, text: 'Popular Near Location'),
        (icon: Icons.visibility_outlined, text: 'Higher visibility'),
      ],
    ),
    _UiPlanItem(
      id: 'plan_ai',
      code: 'AI_PROMOTION',
      title: 'AI Promotion',
      days: 15,
      daysBadge: '15 Days',
      costCredits: 249,
      priceLabel: '249 Credits',
      description: 'Get AI-powered visibility and reach more genuine buyers.',
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFFB7791F),
      iconBg: Color(0xFFFEF3C7),
      featureTags: [
        (icon: Icons.psychology_rounded, text: 'AI Suggested Properties'),
        (icon: Icons.description_outlined, text: 'Property Stories'),
        (icon: Icons.groups_outlined, text: 'AI matching'),
      ],
    ),
    _UiPlanItem(
      id: 'plan_prem',
      code: 'PREMIUM_PROMOTION',
      title: 'Premium Property Promotion',
      days: 15,
      daysBadge: '15 Days',
      costCredits: 999,
      priceLabel: '999 Credits',
      description: 'Maximum exposure with marketing and professional support.',
      icon: Icons.workspace_premium_rounded,
      iconColor: Color(0xFF2457A6),
      iconBg: Color(0xFFD6E4F8),
      featureTags: [
        (icon: Icons.star_rounded, text: 'All AI benefits'),
        (icon: Icons.campaign_rounded, text: '7 days Meta Ads'),
        (icon: Icons.videocam_outlined, text: 'Professional videography'),
        (icon: Icons.event_available_rounded, text: 'Appointment help'),
      ],
    ),
    _UiPlanItem(
      id: 'plan_plat',
      code: 'PLATINUM_PROMOTION',
      title: 'Platinum Property Promotion',
      days: 15,
      daysBadge: '15 Days',
      costCredits: 1999,
      priceLabel: '₹1,999 + Custom',
      description: 'Complete marketing solution with custom support.',
      icon: Icons.diamond_rounded,
      iconColor: Color(0xFF5B57C9),
      iconBg: Color(0xFFE8E6FA),
      featureTags: [
        (icon: Icons.workspace_premium_rounded, text: 'All premium benefits'),
        (icon: Icons.bar_chart_rounded, text: 'Custom Meta services'),
        (icon: Icons.shield_outlined, text: 'Priority placement'),
        (icon: Icons.assignment_turned_in_outlined, text: 'Admin approval'),
      ],
    ),
  ];

  // Offline fallback plans for Profile
  final List<_UiPlanItem> _fallbackProfilePlans = const [
    _UiPlanItem(
      id: 'prof_std',
      code: 'PARTNER_BOOST',
      title: 'Top Partner Spotlight',
      days: 15,
      daysBadge: '15 Days',
      costCredits: 299,
      priceLabel: '299 Credits',
      description: 'Feature your Partner profile at the top of partner directory & search.',
      icon: Icons.stars_rounded,
      iconColor: Color(0xFFB7791F),
      iconBg: Color(0xFFFEF3C7),
      featureTags: [
        (icon: Icons.verified_rounded, text: 'Top Partner Badge'),
        (icon: Icons.search_rounded, text: 'High search placement'),
        (icon: Icons.phone_in_talk_rounded, text: 'Direct buyer contact'),
      ],
    ),
    _UiPlanItem(
      id: 'prof_prem',
      code: 'PARTNER_PRO_BOOST',
      title: 'Elite Territory Partner',
      days: 30,
      daysBadge: '30 Days',
      costCredits: 599,
      priceLabel: '599 Credits',
      description: 'Exclusive territory branding across the entire city locality.',
      icon: Icons.workspace_premium_rounded,
      iconColor: Color(0xFF12805C),
      iconBg: Color(0xFFD3EEDF),
      featureTags: [
        (icon: Icons.location_city_rounded, text: 'Locality Exclusive placement'),
        (icon: Icons.route_rounded, text: 'Dedicated lead routing'),
        (icon: Icons.verified_user_rounded, text: '30 Days active badge'),
      ],
    ),
  ];

  PartnerHomeController get _controller => ensurePartnerHomeController();

  static const Color _navy = Color(0xFF0B1B2E);
  static const Color _teal = Color(0xFF0A4F40);
  static const Color _mintText = Color(0xFF12805C);

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.property ??
        (_controller.properties.isNotEmpty ? _controller.properties.first : null);

    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadPropertyPlans();
      _controller.loadProfilePlans();
      _controller.loadIncomingSellerRequests();
      _controller.loadMyPromotions();
      _controller.loadCredits();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_UiPlanItem> _getEffectivePropertyPlans() {
    if (_controller.propertyPlans.isNotEmpty) {
      return _controller.propertyPlans.map(_UiPlanItem.fromApiModel).toList();
    }
    return _fallbackPropertyPlans;
  }

  List<_UiPlanItem> _getEffectiveProfilePlans() {
    if (_controller.profilePlans.isNotEmpty) {
      return _controller.profilePlans.map(_UiPlanItem.fromApiModel).toList();
    }
    return _fallbackProfilePlans;
  }

  Future<void> _handlePropertyBoostSubmit() async {
    final plans = _getEffectivePropertyPlans();
    if (plans.isEmpty) return;
    final plan = plans[_selectedPropertyPlanIndex.clamp(0, plans.length - 1)];

    if (_selectedProperty == null) {
      AppToast.showError('Please select a property to boost.');
      return;
    }

    final balance = _controller.creditBalance.value;
    if (balance < plan.costCredits) {
      _showInsufficientCreditsSheet(plan);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _controller.directBoostProperty(
        propertyId: _selectedProperty!.id,
        promotionType: plan.code,
      );
      if (mounted) {
        _showSuccessDialog(
          title: 'Boost Request Submitted!',
          message:
              'Your request for "${_selectedProperty!.title}" has been sent to Admin. ${plan.costCredits} credits are reserved and promotion will go live upon review.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError('Could not submit boost request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleProfileBoostSubmit() async {
    final plans = _getEffectiveProfilePlans();
    if (plans.isEmpty) return;
    final plan = plans[_selectedProfilePlanIndex.clamp(0, plans.length - 1)];

    final balance = _controller.creditBalance.value;
    if (balance < plan.costCredits) {
      _showInsufficientCreditsSheet(plan);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _controller.directBoostPartnerProfile(
        promotionType: plan.code,
      );
      if (mounted) {
        _showSuccessDialog(
          title: 'Profile Boost Submitted!',
          message:
              'Your Partner Profile boost request has been submitted to Admin! ${plan.costCredits} credits are reserved and your Top Partner badge will go live upon review.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError('Could not submit profile boost: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showInsufficientCreditsSheet(_UiPlanItem plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
        decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
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
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_wallet_outlined,
                          color: const Color(0xFFC73A3A), size: 20.sp),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Insufficient Balance',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'You need ${plan.costCredits} credits for ${plan.title}. Your current wallet balance is ${_controller.creditBalance.value} credits.',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: const Color(0xFF5B6B7C),
                height: 1.4,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showTopUpCreditsSheet(context);
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Top Up Credits Now',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12805C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF12805C), size: 28),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _navy),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 12.5.sp, color: const Color(0xFF4B5B6C), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(3); // Switch to My Campaigns tab
            },
            style: ElevatedButton.styleFrom(backgroundColor: _teal),
            child: const Text('View Campaigns', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(115.h),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: _navy,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Boost Property',
                            style: GoogleFonts.poppins(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: _navy,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Increase visibility for your property and attract more genuine buyer enquiries.',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: const Color(0xFF5B6B7C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 38.w), // Balance back button
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _teal,
                unselectedLabelColor: const Color(0xFF5B6B7C),
                labelStyle: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500),
                indicatorColor: _teal,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(text: '🚀 Property Boost'),
                  const Tab(text: '⭐ Profile Boost'),
                  Tab(
                    child: Obx(() {
                      final count = _controller.incomingSellerRequests.length;
                      return Row(
                        children: [
                          const Text('📥 Seller Requests'),
                          if (count > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC73A3A),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                  ),
                  const Tab(text: '📊 My Campaigns'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPropertyBoostTab(),
          _buildProfileBoostTab(),
          _buildSellerRequestsTab(),
          _buildMyCampaignsTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PROPERTY BOOST TAB (MATCHING USER SCREENSHOT)
  // ===========================================================================
  Widget _buildPropertyBoostTab() {
    final plans = _getEffectivePropertyPlans();
    final selectedPlan = plans[_selectedPropertyPlanIndex.clamp(0, plans.length - 1)];

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _controller.loadPropertyPlans(),
            _controller.loadCredits(),
            _controller.loadProperties(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Property Card
              _buildPropertySummaryCard(),

              SizedBox(height: 12.h),

              // 2. Available Wallet Balance Card
              _buildWalletBalanceCard(),

              SizedBox(height: 18.h),

              // 3. Choose a Property Boost Plan Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Choose a Property Boost Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 16.sp, color: _mintText),
                      SizedBox(width: 4.w),
                      SizedBox(
                        width: 140.w,
                        child: Text(
                          'Get more visibility, more enquiries, and sell your property faster.',
                          maxLines: 2,
                          style: GoogleFonts.poppins(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5B6B7C),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // 4. Boost Plans
              ...List.generate(
                plans.length,
                (i) => _buildPlanCard(
                  plans[i],
                  isSelected: _selectedPropertyPlanIndex == i,
                  onTap: () => setState(() => _selectedPropertyPlanIndex = i),
                ),
              ),

              SizedBox(height: 16.h),

              // 5. What's included in each plan? Accordion Matrix
              _buildFeatureComparisonAccordion(),

              SizedBox(height: 90.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomContinueBar(
        title: 'Continue with ${selectedPlan.title} (${selectedPlan.priceLabel})',
        isSubmitting: _isSubmitting,
        onPressed: _isSubmitting ? null : _handlePropertyBoostSubmit,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Property Summary Card (matching screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildPropertySummaryCard() {
    final title = _selectedProperty?.title ?? '3 BHK House, Model Town';
    final location = _selectedProperty?.city.isNotEmpty == true
        ? _selectedProperty!.city
        : (_selectedProperty?.address.isNotEmpty == true ? _selectedProperty!.address : 'Ambala, Haryana');
    final imgUrl = _selectedProperty?.imageUrl ?? '';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Property Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 72.w,
              height: 68.w,
              child: imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _propertyImagePlaceholder(),
                    )
                  : _propertyImagePlaceholder(),
            ),
          ),
          SizedBox(width: 10.w),
          // Property Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                    if (_controller.properties.length > 1)
                      InkWell(
                        onTap: _showPropertyPickerSheet,
                        child: Icon(Icons.swap_horiz_rounded, size: 18.sp, color: _mintText),
                      ),
                  ],
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F5EE),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_outlined, size: 10.sp, color: _mintText),
                          SizedBox(width: 3.w),
                          Text(
                            'Active Listing',
                            style: GoogleFonts.poppins(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: _mintText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 11.sp, color: const Color(0xFF5B6B7C)),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF5B6B7C),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Views & Enquiries stats
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 13.sp, color: const Color(0xFF0A7A66)),
                      SizedBox(width: 3.w),
                      Text('2,348', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: _navy)),
                    ],
                  ),
                  Text('Property Views', style: GoogleFonts.poppins(fontSize: 8.5.sp, color: const Color(0xFF5B6B7C))),
                ],
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 13.sp, color: const Color(0xFF0A7A66)),
                      SizedBox(width: 3.w),
                      Text('176', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: _navy)),
                    ],
                  ),
                  Text('Enquiries', style: GoogleFonts.poppins(fontSize: 8.5.sp, color: const Color(0xFF5B6B7C))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _propertyImagePlaceholder() {
    return Container(
      color: const Color(0xFFE3E8ED),
      child: Center(
        child: Icon(Icons.apartment_rounded, color: const Color(0xFF8493A3), size: 28.sp),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Available Wallet Balance Card (matching screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildWalletBalanceCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: _mintText, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'Available Wallet Balance',
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5B6C),
            ),
          ),
          const Spacer(),
          Obx(
            () => Text(
              '${_controller.creditBalance.value} Credits',
              style: GoogleFonts.poppins(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.bold,
                color: _mintText,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          InkWell(
            onTap: () => showTopUpCreditsSheet(context),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: _mintText, width: 1.1),
              ),
              child: Text(
                '+ Add Credits',
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.bold,
                  color: _mintText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Plan Card (matching screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildPlanCard(_UiPlanItem plan, {required bool isSelected, required VoidCallback onTap}) {
    // When selected: warm amber background + border as in screenshot for AI Promotion
    final bgColor = isSelected ? const Color(0xFFFFFDF5) : Colors.white;
    final borderColor = isSelected ? const Color(0xFFFDE68A) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFFD9961F).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio Button
                Container(
                  width: 20.w,
                  height: 20.w,
                  margin: EdgeInsets.only(top: 4.h, right: 10.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF12805C) : const Color(0xFF8493A3),
                      width: isSelected ? 6.w : 1.5,
                    ),
                    color: Colors.white,
                  ),
                ),
                // Icon circle
                Container(
                  width: 38.w,
                  height: 38.w,
                  margin: EdgeInsets.only(right: 10.w),
                  decoration: BoxDecoration(
                    color: plan.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(plan.icon, color: plan.iconColor, size: 20.sp),
                  ),
                ),
                // Title, Duration badge & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F5EE),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              plan.daysBadge,
                              style: GoogleFonts.poppins(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: _mintText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        plan.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF5B6B7C),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Price
                Text(
                  plan.priceLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ],
            ),
            if (plan.featureTags.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.only(left: 30.w),
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: plan.featureTags.map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tag.icon, size: 11.5.sp, color: _mintText),
                          SizedBox(width: 4.w),
                          Text(
                            tag.text,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF33475B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. "What's included in each plan?" Accordion & Comparison Matrix
  // ---------------------------------------------------------------------------
  Widget _buildFeatureComparisonAccordion() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with expand/collapse chevron (circled in user screenshot)
          InkWell(
            onTap: () => setState(() => _isAccordionExpanded = !_isAccordionExpanded),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F5EE),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(Icons.format_list_bulleted_rounded, color: _mintText, size: 16.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      "What's included in each plan?",
                      style: GoogleFonts.poppins(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAccordionExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: _navy,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isAccordionExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEF2F5)),
            // Comparison Matrix Table matching user screenshot
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      children: [
                        _tableHeaderCell('Features', width: 140.w),
                        _tablePlanHeaderCell('Standard', '7 Days', Icons.rocket_launch_rounded, const Color(0xFF12805C)),
                        _tablePlanHeaderCell('AI Promotion', '15 Days', Icons.auto_awesome_rounded, const Color(0xFFB7791F)),
                        _tablePlanHeaderCell('Premium', '15 Days', Icons.workspace_premium_rounded, const Color(0xFF2457A6)),
                        _tablePlanHeaderCell('Platinum', '15 Days', Icons.diamond_rounded, const Color(0xFF5B57C9)),
                      ],
                    ),
                    // Rows
                    _tableRow(Icons.star_rounded, 'Recommended for You', [true, true, true, true]),
                    _tableRow(Icons.location_on_outlined, 'Popular Near Your Location', [true, true, true, true]),
                    _tableRow(Icons.psychology_rounded, 'Niwas AI Suggested Properties', [false, true, true, true]),
                    _tableRow(Icons.description_outlined, 'Property Stories', [false, true, true, true]),
                    _tableRow(Icons.campaign_rounded, '7 Days Meta Ads', [false, false, true, true]),
                    _tableRow(Icons.videocam_outlined, 'Professional Videography', [false, false, true, true]),
                    _tableRow(Icons.event_available_rounded, 'Appointment / Site Visit Help', [false, false, true, true]),
                    _tableRow(Icons.shield_outlined, 'Priority Placement', [false, false, false, true]),
                    _tableRow(Icons.settings_outlined, 'Custom Meta Services', [false, false, false, true]),
                    _tableRow(Icons.assignment_turned_in_outlined, 'Admin Approval Required', [false, false, false, true]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 12.h),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14.sp, color: const Color(0xFF12805C)),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'You will only receive the benefits included in your selected plan.',
                      style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF5B6B7C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String title, {required double width}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: _navy),
      ),
    );
  }

  Widget _tablePlanHeaderCell(String name, String days, IconData icon, Color color) {
    return Container(
      width: 78.w,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(height: 2.h),
          Text(name, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.bold, color: _navy)),
          Text(days, style: GoogleFonts.poppins(fontSize: 8.sp, color: const Color(0xFF5B6B7C))),
        ],
      ),
    );
  }

  TableRow _tableRow(IconData icon, String title, List<bool> statuses) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          child: Row(
            children: [
              Icon(icon, size: 11.5.sp, color: const Color(0xFF5B6B7C)),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 9.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF33475B)),
                ),
              ),
            ],
          ),
        ),
        ...statuses.map((hasIt) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 7.h),
            child: Center(
              child: hasIt
                  ? Icon(Icons.check_rounded, size: 14.sp, color: const Color(0xFF12805C))
                  : Text('—', style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFFC9D2DB))),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Bottom Sticky Bar (matching screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildBottomContinueBar({
    required String title,
    required bool isSubmitting,
    required VoidCallback? onPressed,
  }) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              disabledBackgroundColor: _teal.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18.sp),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OTHER TABS (PROFILE, SELLER REQUESTS, CAMPAIGNS) - POLISHED WHITE THEME
  // ===========================================================================
  Widget _buildProfileBoostTab() {
    final plans = _getEffectiveProfilePlans();
    final selectedPlan = plans[_selectedProfilePlanIndex.clamp(0, plans.length - 1)];
    final partner = _controller.partnerProfile.value;

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _controller.loadProfilePlans(),
            _controller.loadCredits(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1B2E), Color(0xFF0A5C4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1B2E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26.r,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person_rounded, size: 30.sp, color: Colors.white),
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
                                      partner?.name ?? 'Partner Profile',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD9961F),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                                        SizedBox(width: 2.w),
                                        Text('TOP PARTNER', style: GoogleFonts.poppins(fontSize: 8.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                partner?.phone.isNotEmpty == true ? partner!.phone : 'Verified Real Estate Advisor',
                                style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              _buildWalletBalanceCard(),
              SizedBox(height: 16.h),
              Text(
                'Choose a Profile Promotion Plan',
                style: GoogleFonts.poppins(fontSize: 14.5.sp, fontWeight: FontWeight.bold, color: _navy),
              ),
              SizedBox(height: 10.h),
              ...List.generate(
                plans.length,
                (i) => _buildPlanCard(
                  plans[i],
                  isSelected: _selectedProfilePlanIndex == i,
                  onTap: () => setState(() => _selectedProfilePlanIndex = i),
                ),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomContinueBar(
        title: 'Boost Profile (${selectedPlan.priceLabel})',
        isSubmitting: _isSubmitting,
        onPressed: _isSubmitting ? null : _handleProfileBoostSubmit,
      ),
    );
  }

  Widget _buildSellerRequestsTab() {
    return Obx(() {
      final list = _controller.incomingSellerRequests;
      if (_controller.sellerRequestsLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _teal));
      }
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 48.sp, color: const Color(0xFF8493A3)),
                SizedBox(height: 12.h),
                Text('No Seller Requests Yet', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: _navy)),
                SizedBox(height: 6.h),
                Text('When property sellers request promotion assistance, they will appear here.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF5B6B7C))),
              ],
            ),
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, idx) => _buildSellerRequestCard(list[idx]),
      );
    });
  }

  Widget _buildSellerRequestCard(SellerBoostRequestModel req) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  width: 50.w,
                  height: 50.w,
                  child: req.propertyImage.isNotEmpty
                      ? Image.network(req.propertyImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _propertyImagePlaceholder())
                      : _propertyImagePlaceholder(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.propertyTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: _navy)),
                    if (req.propertyLocation.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(req.propertyLocation, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.sp, color: const Color(0xFF5B6B7C))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyCampaignsTab() {
    return Obx(() {
      final list = _controller.myPromotions;
      if (_controller.myPromotionsLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _teal));
      }
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, size: 48.sp, color: const Color(0xFF8493A3)),
                SizedBox(height: 12.h),
                Text('No Active Campaigns', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: _navy)),
                SizedBox(height: 6.h),
                Text('Boost your properties to track your campaign performances here.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF5B6B7C))),
              ],
            ),
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, idx) => _buildCampaignCard(list[idx]),
      );
    });
  }

  Widget _buildCampaignCard(PartnerPromotionItem item) {
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusColor = const Color(0xFFB45309);
    String statusLabel = 'PENDING REVIEW';

    if (item.isActive) {
      statusBg = const Color(0xFFD3EEDF);
      statusColor = const Color(0xFF047857);
      statusLabel = 'ACTIVE';
    } else if (item.isRejected) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFB91C1C);
      statusLabel = 'REJECTED';
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.promotionType, style: GoogleFonts.poppins(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: _navy)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6.r)),
                child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text('${item.credits} Credits Reserved', style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: _teal)),
        ],
      ),
    );
  }

  void _showPropertyPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Property to Boost', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: _navy)),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView.separated(
                itemCount: _controller.properties.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final prop = _controller.properties[idx];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: SizedBox(
                        width: 45.w,
                        height: 45.w,
                        child: prop.imageUrl != null && prop.imageUrl!.isNotEmpty
                            ? Image.network(prop.imageUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.apartment_rounded),
                      ),
                    ),
                    title: Text(prop.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                    subtitle: Text(prop.city.isNotEmpty ? prop.city : prop.priceLabel, style: GoogleFonts.poppins(fontSize: 11.sp)),
                    onTap: () {
                      setState(() => _selectedProperty = prop);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
