// =====================================================================
// SELLER INSIGHTS SCREEN — computed live from SellerController's data:
//   • GET /v1/sellers/:id/properties      -> views/saves per listing
//   • GET /v1/leads/partner/:partnerId    -> enquiries & offers (scoped
//                                            down to this seller, see
//                                            SellerController.loadSellerHome)
//   • GET /v1/visits/partner/:partnerId   -> buyer site-visit activity
//
// There's no single "seller insights" endpoint documented for this
// backend, so every number on this screen is derived from the same live
// API responses Seller Home already fetches — nothing here is hardcoded.
// =====================================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/seller_home_feed_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../controllers/seller_controller.dart';
import 'my_partner.dart';

class SellerInsightsScreen extends StatefulWidget {
  const SellerInsightsScreen({super.key, this.onNavigateTab});

  /// Bottom-nav shell tab switcher (0 Home, 1 Properties, 2 My Partner,
  /// 3 Insights, 4 Profile). When the screen is pushed on its own (no shell
  /// callback) the helpers below fall back to normal route navigation.
  final void Function(int tabIndex)? onNavigateTab;

  @override
  State<SellerInsightsScreen> createState() => _SellerInsightsScreenState();
}

class _SellerInsightsScreenState extends State<SellerInsightsScreen> {
  static const _tag = 'sellerInsightsScreen';

  late final SellerController _controller;
  final RxInt _rangeDays = 30.obs;

  static const Color _mintBorder = Color(0xFFD5EEE2);
  static const Color _mintBg = Color(0xFFF4FAF7);

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
  }

  @override
  void dispose() {
    Get.delete<SellerController>(tag: _tag);
    super.dispose();
  }

  // ---- Navigation helpers --------------------------------------------------
  void _goHome() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(0);
    } else {
      Get.back();
    }
  }

  /// Properties tab (views / saves / listing related taps)
  void _goProperties() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(1);
    } else {
      Get.back(); // pushed from Properties screen -> go back to it
    }
  }

  /// My Partner (enquiries / offers / visits are handled by the partner)
  void _goPartner() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(2);
    } else {
      Get.to(() => const MyPartnerScreen());
    }
  }

  Widget _tappable({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }

  DateTime? _dateOf(Map<String, dynamic> item) =>
      DateTime.tryParse((item['createdAt'] ?? item['requestedVisitAt'] ?? '').toString());

  bool _isOffer(Map<String, dynamic> lead) {
    final status = (lead['status'] ?? '').toString().toLowerCase();
    return status.contains('offer') || status.contains('negotiat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final isFirstLoad = _controller.isHomeLoading.value && _controller.properties.isEmpty;
          final rangeDays = _rangeDays.value;
          final now = DateTime.now();
          final rangeStart = now.subtract(Duration(days: rangeDays));
          final prevStart = rangeStart.subtract(Duration(days: rangeDays));

          final leadsInRange = _controller.sellerLeads.where((l) {
            final d = _dateOf(l);
            return d != null && d.isAfter(rangeStart);
          }).toList();
          final leadsPrevRange = _controller.sellerLeads.where((l) {
            final d = _dateOf(l);
            return d != null && d.isAfter(prevStart) && d.isBefore(rangeStart);
          }).toList();
          final visitsInRange = _controller.sellerVisits.where((v) {
            final d = _dateOf(v);
            return d != null && d.isAfter(rangeStart);
          }).toList();

          final enquiries = leadsInRange.length;
          final prevEnquiries = leadsPrevRange.length;
          final offers = leadsInRange.where(_isOffer).length;
          final prevOffers = leadsPrevRange.where(_isOffer).length;

          final properties = _controller.properties;
          final totalViews = properties.fold<int>(0, (sum, p) => sum + p.views);
          final totalSaves = properties.fold<int>(0, (sum, p) => sum + p.saves);
          final hasViewsData = properties.any((p) => p.views > 0);
          final hasSavesData = properties.any((p) => p.saves > 0);

          final weekly = _weeklyBuckets(leadsInRange, visitsInRange, rangeStart, now);
          final topProperty = _topPerformingProperty(properties);
          final topPropertyEnquiries = topProperty == null
              ? 0
              : _controller.sellerLeads.where((l) => (l['propertyId'] ?? '').toString() == topProperty.id).length;

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
                  Text('Seller Insights',
                      style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  SizedBox(height: 2.h),
                  Text('Understand how buyers engage with your listings',
                      style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  SizedBox(height: 14.h),
                  _buildRangeSelector(),
                  SizedBox(height: 16.h),

                  if (isFirstLoad) ...[
                    _buildLoadingBlock(),
                  ] else ...[
                    if (_controller.homeError.value.isNotEmpty) ...[
                      _buildErrorBanner(_controller.homeError.value),
                      SizedBox(height: 12.h),
                    ],

                    // Stat grid
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.remove_red_eye_outlined,
                            label: 'Property Views',
                            onTap: _goProperties,
                            value: '$totalViews',
                            deltaLabel: hasViewsData ? null : 'No view data yet',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _statCard(
                            icon: Icons.bookmark_border_rounded,
                            label: 'Saved by Buyers',
                            onTap: _goProperties,
                            value: '$totalSaves',
                            deltaLabel: hasSavesData ? null : 'No save data yet',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Enquiries',
                            onTap: _goPartner,
                            value: '$enquiries',
                            delta: _deltaPercent(enquiries, prevEnquiries),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _statCard(
                            icon: Icons.local_offer_outlined,
                            label: 'Offers',
                            onTap: _goPartner,
                            value: '$offers',
                            delta: _deltaPercent(offers, prevOffers),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    _buildBuyerActivityCard(weekly),
                    SizedBox(height: 20.h),

                    _buildListingFunnelCard(
                      views: totalViews,
                      saves: totalSaves,
                      enquiries: enquiries,
                      offers: offers,
                    ),
                    SizedBox(height: 20.h),

                    _buildTopListingCard(topProperty, topPropertyEnquiries),
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
  // Header with DigiNiwas Brand Logo
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _goHome,
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: AppColors.textPrimary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          height: 28.h,
          child: Image.asset(
            'assets/images/app_logo_light.png',
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        Obx(() {
          final localPath = _controller.sellerAvatarLocalPath.value;
          final netUrl = _controller.sellerAvatarNetworkUrl.value;
          final hasLocal = localPath.isNotEmpty && File(localPath).existsSync();
          final hasNet = netUrl.isNotEmpty;
          final name = _controller.sellerProfile.value?.name ?? '';

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
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                _initialsOf(name),
                style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _buildRangeSelector() {
    return Obx(() {
      final options = {7: 'Last 7 days', 30: 'Last 30 days', 90: 'Last 90 days'};
      final currentLabel = options[_rangeDays.value] ?? 'Last 30 days';

      return GestureDetector(
        onTap: () => _showRangePickerSheet(options),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: _mintBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 14.sp, color: const Color(0xFF0D9488)),
              SizedBox(width: 6.w),
              Text(
                currentLabel,
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F2544),
                ),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16.sp, color: const Color(0xFF64748B)),
            ],
          ),
        ),
      );
    });
  }

  void _showRangePickerSheet(Map<int, String> options) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: _mintBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Select Time Range',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F2544),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Filter analytics and buyer interactions',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 16.h),
            ...options.entries.map((entry) {
              final isSelected = _rangeDays.value == entry.key;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEAF5F1) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D9488) : _mintBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.date_range_rounded,
                    color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                    size: 20.sp,
                  ),
                  title: Text(
                    entry.value,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0F2544) : const Color(0xFF334155),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: const Color(0xFF0D9488), size: 20.sp)
                      : null,
                  onTap: () {
                    _rangeDays.value = entry.key;
                    Get.back();
                  },
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(child: Text(message, style: GoogleFonts.poppins(fontSize: 11.5.sp, color: Colors.red.shade700))),
        ],
      ),
    );
  }

  Widget _buildLoadingBlock() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80.h),
        child: SizedBox(
          width: 26.w,
          height: 26.w,
          child: const CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Stat card with a real (or explicitly absent) trend indicator.
  // ---------------------------------------------------------------------
  double? _deltaPercent(int current, int previous) {
    if (previous == 0) return current == 0 ? null : 100.0;
    return ((current - previous) / previous) * 100;
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    double? delta,
    String? deltaLabel,
    VoidCallback? onTap,
  }) {
    Widget? trend;
    if (delta != null) {
      final positive = delta >= 0;
      trend = Row(
        children: [
          Icon(positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 11.sp, color: positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          SizedBox(width: 2.w),
          Text(
            '${delta.abs().toStringAsFixed(0)}% vs prev period',
            style: GoogleFonts.poppins(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              color: positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
        ],
      );
    } else if (deltaLabel != null) {
      trend = Text(deltaLabel, style: GoogleFonts.poppins(fontSize: 9.5.sp, color: AppColors.textSecondary));
    }

    final card = Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: _mintBorder, width: 0.8),
            ),
            child: Icon(icon, size: 15.sp, color: AppColors.primary),
          ),
          SizedBox(height: 10.h),
          Text(label.toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3)),
          SizedBox(height: 2.h),
          Text(value, style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 4.h),
          if (trend != null) trend,
        ],
      ),
    );
    return onTap == null ? card : _tappable(onTap: onTap, child: card);
  }

  // ---------------------------------------------------------------------
  // Buyer Activity — weekly buckets built from real lead/visit timestamps.
  // ---------------------------------------------------------------------
  List<_WeekPoint> _weeklyBuckets(
      List<Map<String, dynamic>> leads,
      List<Map<String, dynamic>> visits,
      DateTime rangeStart,
      DateTime now,
      ) {
    const bucketCount = 4;
    final totalMs = now.difference(rangeStart).inMilliseconds;
    final bucketMs = (totalMs / bucketCount).clamp(1, double.infinity);
    final buckets = List.generate(bucketCount, (_) => _WeekPoint(enquiries: 0, visits: 0));

    for (final l in leads) {
      final d = _dateOf(l);
      if (d == null) continue;
      final offset = d.difference(rangeStart).inMilliseconds;
      var idx = (offset / bucketMs).floor();
      if (idx < 0) idx = 0;
      if (idx >= bucketCount) idx = bucketCount - 1;
      buckets[idx].enquiries++;
    }
    for (final v in visits) {
      final d = _dateOf(v);
      if (d == null) continue;
      final offset = d.difference(rangeStart).inMilliseconds;
      var idx = (offset / bucketMs).floor();
      if (idx < 0) idx = 0;
      if (idx >= bucketCount) idx = bucketCount - 1;
      buckets[idx].visits++;
    }
    return buckets;
  }

  Widget _buildBuyerActivityCard(List<_WeekPoint> weekly) {
    final hasAnyActivity = weekly.any((w) => w.enquiries > 0 || w.visits > 0);
    return _tappable(onTap: _goPartner, child: Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.03),
            blurRadius: 8,
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
              Text('Buyer Activity',
                  style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Row(
                children: [
                  _legendDot(AppColors.textPrimary, 'Visits'),
                  SizedBox(width: 10.w),
                  _legendDot(AppColors.primary, 'Enquiries'),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (!hasAnyActivity) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text('No buyer activity in this period yet.',
                    style: GoogleFonts.poppins(fontSize: 11.5.sp, color: AppColors.textSecondary)),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 120.h,
              width: double.infinity,
              child: CustomPaint(
                painter: _ActivityLineChartPainter(
                  seriesA: weekly.map((w) => w.enquiries.toDouble()).toList(),
                  seriesB: weekly.map((w) => w.visits.toDouble()).toList(),
                  colorA: AppColors.primary,
                  colorB: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                weekly.length,
                    (i) => Text('W${i + 1}',
                    style: GoogleFonts.poppins(fontSize: 9.5.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    ));
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7.w, height: 7.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        Text(label, style: GoogleFonts.poppins(fontSize: 9.5.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Listing funnel
  // ---------------------------------------------------------------------
  Widget _buildListingFunnelCard({
    required int views,
    required int saves,
    required int enquiries,
    required int offers,
  }) {
    final maxVal = [views, saves, enquiries, offers, 1].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing Funnel',
              style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 14.h),
          _funnelRow('Views', views, maxVal, AppColors.textPrimary, _goProperties),
          SizedBox(height: 12.h),
          _funnelRow('Saves', saves, maxVal, const Color(0xFF16A34A), _goProperties),
          SizedBox(height: 12.h),
          _funnelRow('Enquiries', enquiries, maxVal, AppColors.primary, _goPartner),
          SizedBox(height: 12.h),
          _funnelRow('Offers', offers, maxVal, const Color(0xFFF59E0B), _goPartner),
        ],
      ),
    );
  }

  Widget _funnelRow(String label, int value, int maxVal, Color color, VoidCallback onTap) {
    final fraction = maxVal == 0 ? 0.0 : (value / maxVal).clamp(0.02, 1.0);
    return _tappable(onTap: onTap, child: Row(
      children: [
        SizedBox(
          width: 62.w,
          child: Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10.h,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: 34.w,
          child: Text('$value',
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
      ],
    ));
  }

  // ---------------------------------------------------------------------
  // Top performing listing
  // ---------------------------------------------------------------------
  SellerPropertyBrief? _topPerformingProperty(List<SellerPropertyBrief> properties) {
    if (properties.isEmpty) return null;
    SellerPropertyBrief? best;
    num bestScore = -1;
    for (final p in properties) {
      final enquiriesForP =
          _controller.sellerLeads.where((l) => (l['propertyId'] ?? '').toString() == p.id).length;
      final num score = p.views + p.saves + enquiriesForP;
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
    return best ?? properties.first;
  }

  Widget _buildTopListingCard(SellerPropertyBrief? p, int enquiries) {
    if (p == null) {
      return _tappable(onTap: _goProperties, child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _mintBorder, width: 1.2),
        ),
        child: Center(
          child: Text('Add a property to see performance insights.',
              style: GoogleFonts.poppins(fontSize: 12.sp, color: AppColors.textSecondary)),
        ),
      ));
    }

    return _tappable(onTap: _goProperties, child: Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Performing Listing',
              style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          SizedBox(height: 12.h),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: ImageCase(url: p.imageUrl, width: double.infinity, height: 130.h, fallbackIcon: Icons.apartment),
              ),
              if (p.stage == SellerPropertyStage.live)
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        SizedBox(width: 4.w),
                        Text('Active',
                            style: GoogleFonts.poppins(fontSize: 9.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(p.title, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          if (p.addressLabel != null) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12.sp, color: AppColors.textSecondary),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(p.addressLabel!,
                      style: GoogleFonts.poppins(fontSize: 11.sp, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _chip(Icons.remove_red_eye_outlined, '${p.views} Views'),
              _chip(Icons.bookmark_border_rounded, '${p.saves} Saves'),
              _chip(Icons.chat_bubble_outline_rounded, '$enquiries Enquiries'),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goProperties,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('View Listing',
                  style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _mintBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _mintBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _WeekPoint {
  int enquiries;
  int visits;
  _WeekPoint({required this.enquiries, required this.visits});
}

/// Minimal dependency-free line chart (no chart package is available in
/// this project) — draws two smoothed-ish polylines for the Buyer
/// Activity card from real weekly bucket counts.
class _ActivityLineChartPainter extends CustomPainter {
  final List<double> seriesA;
  final List<double> seriesB;
  final Color colorA;
  final Color colorB;

  _ActivityLineChartPainter({
    required this.seriesA,
    required this.seriesB,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = [...seriesA, ...seriesB, 1.0].reduce((a, b) => a > b ? a : b);

    void drawSeries(List<double> series, Color color) {
      if (series.length < 2) return;
      final path = Path();
      final dx = size.width / (series.length - 1);
      final points = <Offset>[];
      for (int i = 0; i < series.length; i++) {
        final x = dx * i;
        final y = size.height - (series[i] / maxVal) * (size.height - 8) - 4;
        points.add(Offset(x, y));
      }
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      path.lineTo(points.last.dx, points.last.dy);

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = color;
      for (final pt in points) {
        canvas.drawCircle(pt, 3, dotPaint);
        canvas.drawCircle(pt, 3, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    drawSeries(seriesB, colorB);
    drawSeries(seriesA, colorA);
  }

  @override
  bool shouldRepaint(covariant _ActivityLineChartPainter oldDelegate) {
    return oldDelegate.seriesA != seriesA || oldDelegate.seriesB != seriesB;
  }
}