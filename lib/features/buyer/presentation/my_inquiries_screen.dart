import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/buyer_home_controller.dart';

class MyInquiriesScreen extends StatefulWidget {
  const MyInquiriesScreen({super.key});

  @override
  State<MyInquiriesScreen> createState() => _MyInquiriesScreenState();
}

class _MyInquiriesScreenState extends State<MyInquiriesScreen> {
  final BuyerHomeController _homeController = Get.isRegistered<BuyerHomeController>()
      ? Get.find<BuyerHomeController>()
      : Get.put(BuyerHomeController());

  bool _isLoading = true;
  List<Map<String, dynamic>> _inquiredProperties = [];

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    setState(() => _isLoading = true);
    final ids = await StorageService.instance.getEnquiryIds();
    final allKnown = _homeController.getAllKnownProperties();

    final List<Map<String, dynamic>> matched = [];

    for (final id in ids) {
      if (id.isEmpty) continue;
      Map<String, dynamic>? found;

      for (final map in allKnown) {
        final propId = map['_id']?.toString() ??
            map['propertyId']?.toString() ??
            map['propertyCode']?.toString() ??
            map['id']?.toString() ??
            '';

        if (propId == id) {
          found = map;
          break;
        }
      }

      if (found != null) {
        matched.add(found);
      } else {
        matched.add({
          '_id': id,
          'propertyId': id,
          'title': 'Property Inquiry #$id',
          'locality': 'DigiNiwas Partner Network',
          'city': 'Verified Property',
          'price': 'Price on Request',
          'isPlaceholder': true,
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _inquiredProperties = matched;
      _isLoading = false;
    });
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Price on Request';
    if (price is num) {
      if (price >= 10000000) {
        return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
      } else if (price >= 100000) {
        return '₹${(price / 100000).toStringAsFixed(2)} L';
      } else {
        return '₹${price.toString()}';
      }
    }
    return price.toString();
  }

  Future<void> _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 10) {
      Get.snackbar(
        'Contact Unavailable',
        'Partner contact number is currently not available for this property.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      final formatted = clean.startsWith('91') ? clean : '91$clean';
      final uri = Uri.parse('https://wa.me/$formatted?text=${Uri.encodeComponent('Hi, I am interested in this property on DigiNiwas.')}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppAdaptiveBackButton(color: Color(0xFF0F172A)),
        title: Text(
          'My Inquiries',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          color: const Color(0xFF007A5E),
          onRefresh: _loadInquiries,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF007A5E)),
                )
              : _inquiredProperties.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: AppEmptyState(
                          type: EmptyStateType.search,
                          title: 'No Inquiries Yet',
                          message:
                              'When you connect with a partner or request details for any property, your inquiry status will appear here.',
                          actionLabel: 'Explore Properties',
                          onAction: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            _homeController.changeBottomNavIndex(1); // Explore tab
                          },
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 32.h),
                      itemCount: _inquiredProperties.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) {
                        final prop = _inquiredProperties[index];
                        return _buildInquiryCard(prop);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildInquiryCard(Map<String, dynamic> property) {
    final title = property['title'] ?? property['name'] ?? 'Property';
    final locality = property['locality']?.toString() ?? '';
    final city = property['city']?.toString() ?? '';
    final locationText = [locality, city].where((s) => s.isNotEmpty).join(', ');
    final priceStr = _formatPrice(property['price']);

    String? imageUrl;
    final images = property['images'] ?? property['photos'] ?? property['gallery'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        imageUrl = (first['secure_url'] ??
                first['url'] ??
                first['imageUrl'] ??
                first['image'] ??
                first['path'])
            ?.toString();
      } else if (first is String) {
        imageUrl = first;
      }
    }
    imageUrl ??= property['image']?.toString() ??
        property['imageUrl']?.toString() ??
        property['coverImage']?.toString() ??
        property['thumbnail']?.toString();

    final partnerPhone = property['partner'] is Map
        ? (property['partner'] as Map)['phone']?.toString() ?? ''
        : (property['partnerPhone']?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: ImageCase(
                  url: imageUrl,
                  width: 84.w,
                  height: 84.w,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.apartment_rounded,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: const Color(0xFFA7E8D6), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 11.sp, color: const Color(0xFF007A5E)),
                          SizedBox(width: 4.w),
                          Text(
                            'Inquiry Submitted',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF007A5E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (locationText.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 11.sp, color: const Color(0xFF64748B)),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      priceStr,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF007A5E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(partnerPhone),
                  icon: Icon(Icons.chat_bubble_outline_rounded,
                      color: const Color(0xFF007A5E), size: 14.sp),
                  label: Text(
                    'Chat Partner',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF007A5E),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF007A5E)),
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(
                      AppRoutes.propertyDetails,
                      arguments: {'property': property},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A5E),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'View Property',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5.sp,
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
  }
}
