import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../data/niwas_ai_service.dart';
import '../models/property_model.dart';

class ComparePropertiesScreen extends StatefulWidget {
  final List<dynamic> comparedProperties;

  const ComparePropertiesScreen({
    super.key,
    required this.comparedProperties,
  });

  @override
  State<ComparePropertiesScreen> createState() => _ComparePropertiesScreenState();
}

class _ComparePropertiesScreenState extends State<ComparePropertiesScreen> {
  late List<dynamic> _properties;
  String? _aiComparisonText;
  bool _isAiComparing = false;

  final ScreenshotController _screenshotController = ScreenshotController();

  Map<String, dynamic> _normalizeProperty(dynamic raw) {
    return PropertyModel.fromDynamic(raw).toJson();
  }

  @override
  void initState() {
    super.initState();
    _properties = widget.comparedProperties.map((p) => _normalizeProperty(p)).toList();
    _fetchAiComparison();
  }

  Future<void> _fetchAiComparison() async {
    if (_properties.isEmpty) return;
    setState(() {
      _isAiComparing = true;
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln(
          'Please compare the following ${_properties.length} properties for a prospective home buyer or real estate investor:');
      for (int i = 0; i < _properties.length; i++) {
        final p = _properties[i];
        final title = p['title'] ?? p['name'] ?? 'Property ${i + 1}';
        final locality = p['locality'] ?? p['address'] ?? '';
        final city = p['city'] ?? '';
        final price = p['price']?.toString() ?? p['price_label'] ?? '';
        final bhk = p['bedrooms'] ?? p['bhk'] ?? '2';
        final area = p['area'] ?? p['size'] ?? '1200 sqft';
        final propId = p['propertyCode'] ?? p['propertyId'] ?? p['property_id'] ?? '';

        buffer.writeln(
            '${i + 1}. $title (Code: $propId) in $locality, $city. Price: ₹$price, Configuration: $bhk BHK, Area: $area.');
      }
      buffer.writeln('\nPlease provide a clear 3-point comparative summary:');
      buffer.writeln('1. Price & Value: Which listing gives better value per sqft or fits budget better.');
      buffer.writeln('2. Locality & Amenities: Key locational / lifestyle differences.');
      buffer.writeln('3. Verdict: Clear recommendation on which property suits which buyer persona.');

      final response = await NiwasAiService.instance.sendChatMessage(
        message: buffer.toString(),
      );

      if (response['success'] == true && response['reply'] != null) {
        final reply = response['reply'].toString().trim();
        if (reply.isNotEmpty) {
          setState(() {
            _aiComparisonText = reply;
          });
          return;
        }
      }
      setState(() {
        _aiComparisonText = 'AI comparative insight is currently unavailable for these properties.';
      });
    } catch (_) {
      setState(() {
        _aiComparisonText = 'AI comparative insight is currently unavailable for these properties.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAiComparing = false;
        });
      }
    }
  }

  void _removeProperty(int index) {
    setState(() {
      _properties.removeAt(index);
    });
    if (_properties.isNotEmpty) {
      _fetchAiComparison();
    }
  }

  Future<void> _shareComparison() async {
    if (_properties.isEmpty) return;

    try {
      final imageUint8List = await _screenshotController.capture(
        delay: const Duration(milliseconds: 300),
        pixelRatio: 2.5,
      );

      if (imageUint8List != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/property_comparison.png').create();
        await imagePath.writeAsBytes(imageUint8List);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Check out this property comparison table on DigiNiwas!\nExplore more properties on: https://diginiwas.com',
          subject: 'Property Comparison Table',
        );
      }
    } catch (e) {
      debugPrint('Error sharing comparison screenshot: $e');
    }
  }

  String _getTitle(dynamic item) => item['title'] ?? item['name'] ?? 'Property';

  String _getLocality(dynamic item) {
    final loc = PropertyModel.fromDynamic(item).formattedLocation;
    return loc.isNotEmpty ? loc : '-';
  }

  String _getPrice(dynamic item) {
    return PropertyModel.fromDynamic(item).formattedPrice;
  }

  String _getBhk(dynamic item) {
    return PropertyModel.fromDynamic(item).bhkLabel;
  }

  String _getArea(dynamic item) {
    final a = PropertyModel.fromDynamic(item).areaDisplay;
    return a.isNotEmpty ? a : '-';
  }

  String _getPossession(dynamic item) {
    return PropertyModel.fromDynamic(item).furnishingLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _properties.isEmpty
            ? _buildEmptyState()
            : Screenshot(
          controller: _screenshotController,
          child: Container(
            color: const Color(0xFFF4F7F6),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyCardsRow(),
                  SizedBox(height: 18.h),
                  _buildComparisonTable(),
                  SizedBox(height: 20.h),
                  _buildAiInsightCard(),
                  SizedBox(height: 20.h),
                  _buildNeedHelpCard(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return BuyerAppBar(
      title: 'Compare Properties',
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF007A5E).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.share_outlined, color: const Color(0xFF005B48), size: 19.sp),
            onPressed: _shareComparison,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCardsRow() {
    if (_properties.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPropertyCardItem(_properties[0], 0)),
          SizedBox(width: 12.w),
          Expanded(child: _buildPropertyCardItem(_properties[1], 1)),
        ],
      );
    } else if (_properties.length == 1) {
      return Center(
        child: SizedBox(
          width: 0.6.sw,
          child: _buildPropertyCardItem(_properties[0], 0),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: List.generate(_properties.length, (index) {
          return Container(
            width: 160.w,
            margin: EdgeInsets.only(right: index == _properties.length - 1 ? 0 : 12.w),
            child: _buildPropertyCardItem(_properties[index], index),
          );
        }),
      ),
    );
  }

  Widget _buildPropertyCardItem(dynamic item, int index) {
    final title = _getTitle(item);
    final locality = _getLocality(item);
    final price = _getPrice(item);

    String? imageUrl;
    final images = item['images'] ?? item['photos'] ?? item['gallery'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first is Map
          ? (images.first['secure_url']?.toString() ??
              images.first['url']?.toString() ??
              images.first['imageUrl']?.toString() ??
              images.first['image']?.toString())
          : images.first?.toString();
    }
    if ((imageUrl == null || imageUrl.isEmpty) && item['image'] is String) {
      imageUrl = item['image'];
    }
    if ((imageUrl == null || imageUrl.isEmpty) && item['imageUrl'] is String) {
      imageUrl = item['imageUrl'];
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFF007A5E).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B48).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(9.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: ImageCase(
                  url: imageUrl,
                  height: 105.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.home_work_rounded,
                ),
              ),
              Positioned(
                top: 6.h,
                right: 6.w,
                child: GestureDetector(
                  onTap: () => _removeProperty(index),
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 12.sp, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 6.h,
                left: 6.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 10.sp, color: const Color(0xFF007A5E)),
                      SizedBox(width: 3.w),
                      Text(
                        'Verified',
                        style: GoogleFonts.poppins(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007A5E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 9.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 11.sp, color: const Color(0xFF007A5E)),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  locality.isNotEmpty ? locality : 'Indore',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF005B48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final bool isTwo = _properties.length == 2;

    final configValues = _properties.map((e) => _getBhk(e)).toList();
    final areaValues = _properties.map((e) => _getArea(e)).toList();
    final possValues = _properties.map((e) => _getPossession(e)).toList();
    final priceValues = _properties.map((e) => _getPrice(e)).toList();
    final localityValues = _properties.map((e) => _getLocality(e)).toList();
    final verifiedValues = _properties.map((e) => 'Verified').toList();

    final tableWidget = Column(
      children: [
        _buildTableRowItem(
          icon: Icons.grid_view_rounded,
          label: 'Configuration',
          values: configValues,
          isTwoColumns: isTwo,
          rowIndex: 0,
        ),
        _buildTableRowItem(
          icon: Icons.crop_square_rounded,
          label: 'Carpet Area',
          values: areaValues,
          isTwoColumns: isTwo,
          rowIndex: 1,
        ),
        _buildTableRowItem(
          icon: Icons.calendar_today_rounded,
          label: 'Possession',
          values: possValues,
          isTwoColumns: isTwo,
          rowIndex: 2,
        ),
        _buildTableRowItem(
          icon: Icons.sell_rounded,
          label: 'Price',
          values: priceValues,
          isPrice: true,
          isTwoColumns: isTwo,
          rowIndex: 3,
        ),
        _buildTableRowItem(
          icon: Icons.location_on_rounded,
          label: 'Locality',
          values: localityValues,
          isTwoColumns: isTwo,
          rowIndex: 4,
        ),
        _buildTableRowItem(
          icon: Icons.verified_rounded,
          label: 'Verification',
          values: verifiedValues,
          isVerified: true,
          isLast: true,
          isTwoColumns: isTwo,
          rowIndex: 5,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFF007A5E).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B48).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isTwo
          ? tableWidget
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: 110.w + (_properties.length * 125.w),
          child: tableWidget,
        ),
      ),
    );
  }

  Widget _buildTableRowItem({
    required IconData icon,
    required String label,
    required List<String> values,
    bool isPrice = false,
    bool isVerified = false,
    bool isLast = false,
    bool isTwoColumns = true,
    required int rowIndex,
  }) {
    final bool isEven = rowIndex % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFFAFCFB) : Colors.white,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: const Color(0xFF007A5E).withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 110.w,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 13.h),
                child: Row(
                  children: [
                    Icon(icon, size: 14.sp, color: const Color(0xFF007A5E)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, color: const Color(0xFF007A5E).withValues(alpha: 0.08)),
            if (isTwoColumns)
              ...List.generate(values.length, (i) {
                return Expanded(
                  child: Row(
                    children: [
                      if (i > 0) Container(width: 1, color: const Color(0xFF007A5E).withValues(alpha: 0.08)),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 13.h),
                            child: _buildCellValue(values[i], isPrice: isPrice, isVerified: isVerified),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              ...List.generate(values.length, (i) {
                return Row(
                  children: [
                    if (i > 0) Container(width: 1, color: const Color(0xFF007A5E).withValues(alpha: 0.08)),
                    SizedBox(
                      width: 125.w,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 13.h),
                          child: _buildCellValue(values[i], isPrice: isPrice, isVerified: isVerified),
                        ),
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
  Widget _buildCellValue(String text, {bool isPrice = false, bool isVerified = false}) {
    if (isVerified) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13.sp, color: const Color(0xFF007A5E)),
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF007A5E),
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: isPrice ? 12.5.sp : 11.sp,
        fontWeight: isPrice ? FontWeight.w800 : FontWeight.w600,
        color: isPrice ? const Color(0xFF005B48) : const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F4F1), Color(0xFFF2F9F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFF007A5E).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B48).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007A5E), Color(0xFF005B48)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF005B48).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Niwas AI Insight',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF005B48),
                          ),
                        ),
                        if (!_isAiComparing)
                          GestureDetector(
                            onTap: _fetchAiComparison,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A5E).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.refresh_rounded, size: 16.sp, color: const Color(0xFF005B48)),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    if (_isAiComparing)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14.w,
                              height: 14.w,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF005B48)),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Evaluating properties with Niwas AI...',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: const Color(0xFF005B48),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        _aiComparisonText ?? 'Evaluating properties with Niwas AI...',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(color: const Color(0xFF007A5E).withValues(alpha: 0.15), thickness: 1),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 12.sp, color: const Color(0xFF64748B)),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'Use this guidance alongside official property documents & site inspection.',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFF007A5E).withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B48).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFF007A5E).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded, color: const Color(0xFF005B48), size: 24.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            'Need local expert help?',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Connect with a verified DigiNiwas partner for layout verification, price negotiation & site visits.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10.5.sp,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                String? partnerPhone;
                for (final p in _properties) {
                  final phone = (p['partner'] is Map ? (p['partner'] as Map)['phone'] : null) ??
                      p['partnerPhone'] ??
                      p['contactNumber'];
                  if (phone != null && phone.toString().trim().isNotEmpty) {
                    partnerPhone = phone.toString().trim();
                    break;
                  }
                }
                if (partnerPhone != null && partnerPhone.isNotEmpty) {
                  final uri = Uri.parse('tel:$partnerPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                } else {
                  Get.snackbar(
                    'Partner Support',
                    'Partner contact details will be shared once you request a site visit.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005B48),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Connect with DigiNiwas Partner',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(Icons.arrow_forward_rounded, size: 14.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      type: EmptyStateType.property,
      title: 'No Properties To Compare',
      message: 'Select two or more properties from your saved wishlist or listings to compare features, price, and localities side by side.',
      actionLabel: 'Browse Saved Properties',
      onAction: () => Get.back(),
    );
  }
}