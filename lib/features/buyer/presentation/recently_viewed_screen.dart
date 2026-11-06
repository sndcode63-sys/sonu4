import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../controllers/buyer_home_controller.dart';
import '../models/property_model.dart';

class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  final List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  late final BuyerHomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = Get.isRegistered<BuyerHomeController>()
        ? Get.find<BuyerHomeController>()
        : Get.put(BuyerHomeController());
    _loadRecentlyViewed();
  }

  Future<void> _loadRecentlyViewed() async {
    setState(() => _isLoading = true);
    final list = await StorageService.instance.getRecentlyViewedProperties();
    if (mounted) {
      setState(() {
        _properties.clear();
        _properties.addAll(list);
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 18.h),
              Icon(Icons.delete_sweep_outlined, size: 44.sp, color: const Color(0xFFEF4444)),
              SizedBox(height: 12.h),
              Text(
                'Clear Recently Viewed History?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'This will remove all recently viewed properties from your browsing history on this device.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await StorageService.instance.clearRecentlyViewedProperties();
      if (mounted) {
        setState(() {
          _properties.clear();
        });
      }
    }
  }

  List<Map<String, dynamic>> _filteredProperties() {
    if (_selectedFilter == 'All') return _properties;
    if (_selectedFilter == 'Verified') {
      return _properties.where((p) {
        return p['propertyVerificationStatus'] == 'verified' || p['isVerified'] == true;
      }).toList();
    }
    return _properties.where((p) {
      final cat = (p['category'] ?? p['propertyType'] ?? '').toString().toLowerCase();
      return cat.contains(_selectedFilter.toLowerCase());
    }).toList();
  }

  String _formatViewedTime(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredProperties();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: BuyerAppBar(
          centerTitle: false,
          titleWidget: Row(
            children: [
              Text(
                'Recently Viewed',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (_properties.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${_properties.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF007A5E),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (_properties.isNotEmpty)
              TextButton.icon(
                onPressed: _clearHistory,
                icon: Icon(Icons.delete_outline_rounded, size: 16.sp, color: const Color(0xFFEF4444)),
                label: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
          ],
        ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF007A5E),
                  strokeWidth: 2.5,
                ),
              )
          : _properties.isEmpty
              ? AppEmptyState(
                  type: EmptyStateType.visits,
                  title: 'No Recently Viewed Properties',
                  message: 'Properties you explore across the platform will appear here so you can easily revisit them.',
                  actionLabel: 'Explore Properties',
                  onAction: () => Get.back(),
                )
              : Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(
                      child: displayList.isEmpty
                          ? AppEmptyState(
                              type: EmptyStateType.search,
                              title: 'No Matching History',
                              message: 'No recently viewed properties match the "$_selectedFilter" filter.',
                              actionLabel: 'Show All',
                              onAction: () => setState(() => _selectedFilter = 'All'),
                            )
                          : ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                final item = displayList[index];
                                return StaggeredItemEntrance(
                                  index: index,
                                  child: _buildPropertyCard(item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Residential', 'Commercial', 'Plots', 'Verified'];

    return Container(
      height: 46.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return ScaleTap(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF007A5E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? const Color(0xFF007A5E) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> propertyData) {
    final model = PropertyModel.fromDynamic(propertyData);
    final propertyId = model.id;
    final title = model.title;
    final location = model.formattedLocation;
    final priceStr = model.formattedPrice;
    final bhk = model.bhkLabel;
    final sqft = model.areaDisplay;
    final isVerified = model.isVerified;
    final viewedAt = _formatViewedTime(propertyData['viewedAt']);
    final imageUrl = model.primaryImageUrl;

    return ScaleTap(
      onTap: () {
        // Direct tap anywhere on card navigates to Property Details
        Get.toNamed(
          AppRoutes.propertyDetails,
          arguments: {'property': propertyData},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF007A5E).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ImageCase(
                  url: imageUrl,
                  width: double.infinity,
                  height: 160.h,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                ),
                // Verified Badge
                if (isVerified)
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined, size: 11.sp, color: const Color(0xFF007A5E)),
                          SizedBox(width: 3.w),
                          Text(
                            'Verified',
                            style: GoogleFonts.poppins(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF007A5E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Viewed Time Pill
                Positioned(
                  bottom: 10.h,
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 10.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'Viewed $viewedAt',
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Heart Icon
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Obx(() {
                    final isSaved = _homeController.savedPropertiesList.any((s) {
                      final sData = (s is Map && s['propertySnapshot'] != null)
                          ? s['propertySnapshot']
                          : (s is Map && s['property'] != null ? s['property'] : s);
                      final sId = sData['propertyId']?.toString() ?? sData['_id']?.toString() ?? '';
                      return sId == propertyId;
                    });

                    return GestureDetector(
                      onTap: () async {
                        final buyerId = await StorageService.instance.getBuyerId();
                        if (buyerId != null && buyerId.isNotEmpty && propertyId.isNotEmpty) {
                          await _homeController.toggleSaveProperty(buyerId, propertyId);
                        }
                      },
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isSaved ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                            size: 16.sp,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            // Info Body
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF007A5E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12.sp, color: const Color(0xFF64748B)),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          location.isNotEmpty ? location : 'India',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (bhk.isNotEmpty) ...[
                        _buildFeaturePill(Icons.bed_outlined, '$bhk BHK'),
                        SizedBox(width: 8.w),
                      ],
                      if (sqft.isNotEmpty) ...[
                        _buildFeaturePill(Icons.square_foot_rounded, '$sqft sq.ft'),
                        SizedBox(width: 8.w),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF007A5E),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10.sp,
                            color: const Color(0xFF007A5E),
                          ),
                        ],
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

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
