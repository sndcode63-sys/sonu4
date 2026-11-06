import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/seller_home_feed_model.dart';

class SellerPropertyDetailsScreen extends StatelessWidget {
  final SellerPropertyBrief property;

  const SellerPropertyDetailsScreen({super.key, required this.property});

  static const Color _darkGreen = Color(0xFF165A54);
  static const Color _mintBorder = Color(0xFFD5EEE2);
  static const Color _mintBg = Color(0xFFF4FAF7);
  static const Color _navy = Color(0xFF0F2544);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final List<String> images = (property.imageUrl != null && property.imageUrl!.isNotEmpty)
        ? [property.imageUrl!]
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _navy, size: 18.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'View Listing',
          style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: _navy),
        ),
        centerTitle: true,

      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Preview Card Design (Exact Match to AddProperty Review Step)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: _border),
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
                  // Auto-Sliding Image Carousel
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                    child: SizedBox(
                      height: 180.h,
                      width: double.infinity,
                      child: images.isNotEmpty
                          ? _DetailImageCarousel(
                        imageUrls: images,
                        onTapImage: (index) => _showFullScreenImage(context, images, index),
                      )
                          : Container(
                        height: 180.h,
                        width: double.infinity,
                        color: _mintBg,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apartment, color: _darkGreen, size: 40.sp),
                            SizedBox(height: 6.h),
                            Text('No images available', style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _navy),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          property.addressLabel ?? 'Location details not specified',
                          style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          formatPrice(property.price),
                          style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _darkGreen),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            if (property.bhkLabel != null && property.bhkLabel!.isNotEmpty) ...[
                              Icon(Icons.bed_outlined, size: 15.sp, color: _grey),
                              SizedBox(width: 4.w),
                              Text(property.bhkLabel!, style: GoogleFonts.poppins(fontSize: 11.sp, color: _navy)),
                              SizedBox(width: 14.w),
                            ],
                            if (property.area != null && property.area!.isNotEmpty) ...[
                              Icon(Icons.square_foot_rounded, size: 15.sp, color: _grey),
                              SizedBox(width: 4.w),
                              Text(property.area!, style: GoogleFonts.poppins(fontSize: 11.sp, color: _navy)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 📋 Key Details Card (Matching Preview Screen Style)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key Details', style: GoogleFonts.poppins(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _navy)),
                  SizedBox(height: 10.h),
                  _detailRow('Listing Stage', stageLabel(property.stage)),
                  _detailRow('Category', property.category ?? 'Residential'),
                  _detailRow('Photos', '${images.length}'),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 🤝 Assigned Partner Card
            Builder(builder: (context) {
              final hasPartner = property.partnerName != null && property.partnerName!.trim().isNotEmpty;
              return Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _mintBg,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: _mintBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: hasPartner ? _darkGreen : Colors.grey.shade400,
                      backgroundImage: (hasPartner && property.partnerAvatarUrl != null && property.partnerAvatarUrl!.isNotEmpty)
                          ? NetworkImage(property.partnerAvatarUrl!)
                          : null,
                      child: (!hasPartner || property.partnerAvatarUrl == null || property.partnerAvatarUrl!.isEmpty)
                          ? (hasPartner
                              ? Text(property.partnerName!.substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.bold))
                              : const Icon(Icons.person, color: Colors.white))
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned DigiNiwas Partner', style: GoogleFonts.poppins(fontSize: 10.sp, color: _grey)),
                          Text(
                            hasPartner ? property.partnerName! : 'Not assigned yet',
                            style: GoogleFonts.poppins(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _navy),
                          ),
                        ],
                      ),
                    ),
                    if (hasPartner && property.partnerPhone != null && property.partnerPhone!.isNotEmpty)
                      IconButton(
                        onPressed: () => _openWhatsApp(property.partnerPhone, context),
                        icon: const Icon(Icons.chat_bubble_rounded, color: _darkGreen),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(k, style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey)),
          ),
          Text(':  ', style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey)),
          Expanded(
            child: Text(v, style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w500, color: _navy)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _FullScreenGalleryView(imageUrls: imageUrls, initialIndex: initialIndex),
    );
  }

  Future<void> _openWhatsApp(String? phone, BuildContext context) async {
    if (phone == null || phone.trim().isEmpty) {
      AppToast.error(context, "Partner's contact isn't available yet.");
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppToast.error(context, 'Could not open WhatsApp.');
    }
  }
}

/// 🌟 Auto-Sliding Image Carousel Widget
class _DetailImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final ValueChanged<int> onTapImage;

  const _DetailImageCarousel({required this.imageUrls, required this.onTapImage});

  @override
  State<_DetailImageCarousel> createState() => _DetailImageCarouselState();
}

class _DetailImageCarouselState extends State<_DetailImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.imageUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_pageController.hasClients) {
          _currentPage = (_currentPage + 1) % widget.imageUrls.length;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => widget.onTapImage(index),
              child: ImageCase(
                url: widget.imageUrls[index],
                width: double.infinity,
                height: 180.h,
                fit: BoxFit.cover,
                fallbackIcon: Icons.apartment,
              ),
            );
          },
        ),
        // Indicator Dots
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 10.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: isActive ? 16.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

/// 🌟 Zoomable Fullscreen Image Gallery Dialog
class _FullScreenGalleryView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenGalleryView({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenGalleryView> createState() => _FullScreenGalleryViewState();
}

class _FullScreenGalleryViewState extends State<_FullScreenGalleryView> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Photo ${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: ImageCase(
                url: widget.imageUrls[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                fallbackIcon: Icons.apartment,
              ),
            ),
          );
        },
      ),
    );
  }
}