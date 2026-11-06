import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/app_pill_search_bar.dart';
import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../features/partner/models/partner_models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_image.dart';
import 'partner_bottom_sheets.dart';
import '../../../core/utils/shimmer.dart';
import 'boost_property_screen.dart';

import 'widgets/partner_ui.dart';
class AgentPropertiesScreen extends StatefulWidget {
  const AgentPropertiesScreen({super.key});

  @override
  State<AgentPropertiesScreen> createState() => _AgentPropertiesScreenState();
}

class _AgentPropertiesScreenState extends State<AgentPropertiesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final c = ensurePartnerHomeController();

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.agentAddProperty),
        backgroundColor: PartnerColors.brand,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          '+ Add Property',
          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final list = c.filteredProperties;
          final totalCount = c.properties.length;
          final liveCount = c.propLiveCount;
          final reviewCount = c.propReviewCount;
          final draftCount = c.propDraftCount;

          return RefreshIndicator(
            onRefresh: c.loadProperties,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 88.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  Text(
                    'Partner Properties',
                    style: PartnerText.title(21),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Manage your assigned & verified seller listings',
                    style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
                  ),

                  SizedBox(height: 14.h),

                  // 4 Top Metrics
                  Row(
                    children: [
                      _metricBox('Total', '$totalCount', const Color(0xFF0A5C4A), const Color(0xFFE8F3EF)),
                      SizedBox(width: 6.w),
                      _metricBox('Live', '$liveCount', const Color(0xFF129B6C), const Color(0xFFE6F5EE)),
                      SizedBox(width: 6.w),
                      _metricBox('In Review', '$reviewCount', const Color(0xFFD9961F), const Color(0xFFFFFBEB)),
                      SizedBox(width: 6.w),
                      _metricBox('Drafts', '$draftCount', const Color(0xFF5B6B7C), const Color(0xFFEEF2F5)),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Search Bar + Add Button
                  Row(
                    children: [
                      Expanded(
                        child: AppPillSearchBar(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          hintText: 'Search properties by location or title...',
                          onChanged: (v) {
                            c.propertySearch.value = v;
                            setState(() {});
                          },
                          onClear: () {
                            c.propertySearch.value = '';
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A5C4A),
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A5C4A).withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.agentAddProperty),
                          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          label: Text(
                            'Add',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: [
                        _tabChip(c, 'All', totalCount),
                        SizedBox(width: 8.w),
                        _tabChip(c, 'Live', liveCount),
                        SizedBox(width: 8.w),
                        _tabChip(c, 'Review', reviewCount),
                        SizedBox(width: 8.w),
                        _tabChip(c, 'Draft', draftCount),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Property Listings
                  if (c.propertiesLoading.value)
                    ShimmerGroup(
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: ShimmerBox(
                              height: 180.h,
                              width: double.infinity,
                              borderRadius: 16.r,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (list.isEmpty)
                    _emptyPropertyState(context)
                  else ...[
                    ...list.map((p) => Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _dynamicPropertyCard(context, c, p),
                    )),
                  ],

                  SizedBox(height: 18.h),

                  // Property Tools Section
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0A0B1B2E),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Property Tools',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1B2E),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            _toolButton(Icons.share_outlined, 'Share Portfolio', () {
                              if (c.properties.isEmpty) {
                                Get.snackbar(
                                  'Portfolio Empty',
                                  'No properties available to share yet. Add listings to build your portfolio.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              final partnerName = c.partnerName.value.isNotEmpty ? c.partnerName.value : 'DigiNiwas Partner';
                              final sb = StringBuffer('🏡 Property Listings Portfolio by $partnerName\n\n');
                              for (final prop in c.properties.take(5)) {
                                sb.writeln('• ${prop.title}');
                                if (prop.priceLabel.isNotEmpty) sb.writeln('  Price: ${prop.priceLabel}');
                                if (prop.address.isNotEmpty) sb.writeln('  Location: ${prop.address}');
                                sb.writeln('  Status: ${prop.status}');
                                sb.writeln();
                              }
                              if (c.properties.length > 5) {
                                sb.writeln('...plus ${c.properties.length - 5} more verified listings.');
                              }
                              sb.writeln('Contact: ${c.partnerPhone.value.isNotEmpty ? c.partnerPhone.value : c.partnerEmail.value}');
                              SharePlus.instance.share(
                                ShareParams(
                                  text: sb.toString(),
                                  subject: '$partnerName - Property Portfolio',
                                ),
                              );
                            }),
                            SizedBox(width: 8.w),
                            _toolButton(Icons.qr_code_2_rounded, 'Share Listing', () {
                              if (c.properties.isEmpty) {
                                Get.snackbar('Notice', 'No properties to share.', snackPosition: SnackPosition.BOTTOM);
                                return;
                              }
                              final p = c.properties.first;
                              SharePlus.instance.share(
                                ShareParams(
                                  text: 'Verified DigiNiwas Listing: ${p.title} (${p.priceLabel})\nExplore details & site visits on DigiNiwas.',
                                  subject: 'Listing: ${p.title}',
                                ),
                              );
                            }),
                            SizedBox(width: 8.w),
                            _toolButton(Icons.file_download_outlined, 'Export CSV', () {
                              if (c.properties.isEmpty) {
                                Get.snackbar('Notice', 'No properties to export.', snackPosition: SnackPosition.BOTTOM);
                                return;
                              }
                              final csv = StringBuffer('ID,Title,Status,Price,City,Address\n');
                              for (final p in c.properties) {
                                csv.writeln('"${p.id}","${p.title}","${p.status}","${p.priceLabel}","${p.city}","${p.address}"');
                              }
                              SharePlus.instance.share(
                                ShareParams(
                                  text: csv.toString(),
                                  subject: 'DigiNiwas_Properties_Export.csv',
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _metricBox(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0x080B1B2E),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                value,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: PartnerColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(PartnerHomeController c, String tab, int count) {
    final isSel = c.propertiesTab.value.toLowerCase() == tab.toLowerCase();
    return GestureDetector(
      onTap: () => c.propertiesTab.value = tab,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSel ? PartnerColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSel ? PartnerColors.brand : PartnerColors.line,
          ),
          boxShadow: isSel
              ? const [BoxShadow(color: Color(0x290A5C4A), blurRadius: 10, offset: Offset(0, 4))]
              : null,
        ),
        child: Text(
          '$tab ($count)',
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? Colors.white : const Color(0xFF0B1B2E),
          ),
        ),
      ),
    );
  }

  Widget _emptyPropertyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
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
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3EF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.apartment_rounded, size: 36.sp, color: const Color(0xFF0A5C4A)),
          ),
          SizedBox(height: 12.h),
          Text(
            'No Properties Found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B1B2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Add your verified seller properties to manage visits, leads and earn brokerage.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.agentAddProperty),
            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: Text(
              '+ Add New Property',
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C4A),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dynamicPropertyCard(BuildContext context, PartnerHomeController c, PartnerProperty p) {
    final isLive = p.status.toLowerCase() == 'live';
    final isReview = p.status.toLowerCase().contains('review');
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    final statusTone = isLive
        ? PartnerTone.success
        : isReview
            ? PartnerTone.warning
            : PartnerTone.neutral;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: PartnerColors.line),
        boxShadow: PartnerShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Media (tap = details) ----------
          InkWell(
            onTap: () {
              if (p.id.isNotEmpty) {
                Get.toNamed(AppRoutes.propertyDetails, arguments: {
                  'propertyId': p.id,
                  'property': p.raw,
                });
              }
            },
            child: Stack(
              children: [
                if (hasImage)
                  ImageCase(
                    url: p.imageUrl,
                    width: double.infinity,
                    height: 160.h,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 130.h,
                    width: double.infinity,
                    color: isReview ? PartnerColors.warningTint : PartnerColors.brandMist,
                    child: Center(
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 42.sp,
                        color: isReview ? PartnerColors.warning : PartnerColors.brand,
                      ),
                    ),
                  ),
                if (hasImage)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.28),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.38),
                            ],
                            stops: const [0, 0.35, 0.6, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: PartnerStatusChip(
                      label: p.status.isEmpty ? 'Draft' : p.status,
                      tone: statusTone,
                      dense: true,
                      icon: isLive
                          ? Icons.check_circle_rounded
                          : isReview
                              ? Icons.hourglass_top_rounded
                              : Icons.edit_note_rounded,
                    ),
                  ),
                ),
                if (p.isBoosted)
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: PartnerColors.gold,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 12.sp, color: Colors.white),
                          SizedBox(width: 2.w),
                          Text(
                            'Boosted',
                            style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasImage && p.priceLabel.isNotEmpty)
                  Positioned(
                    left: 12.w,
                    bottom: 10.h,
                    child: Text(
                      p.priceLabel,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---------- Body ----------
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PartnerText.title(14.5),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14.sp, color: PartnerColors.textTertiary),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        p.address.isEmpty ? p.city : p.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PartnerText.body(11.5),
                      ),
                    ),
                  ],
                ),
                if (!hasImage && p.priceLabel.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    p.priceLabel,
                    style: PartnerText.title(16, color: PartnerColors.brand),
                  ),
                ],
                SizedBox(height: 12.h),
                Divider(height: 1, color: PartnerColors.lineSoft),
                SizedBox(height: 12.h),
                if (isReview) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => showReviewDocumentsSheet(
                            context,
                            propertyTitle: p.title,
                            sellerName: p.sellerName.isNotEmpty ? p.sellerName : 'Property Owner',
                            phone: p.sellerPhone,
                          ),
                          icon: Icon(Icons.fact_check_outlined, size: 15.sp, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PartnerColors.brand,
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          label: Text('Review Docs', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showContactSellerSheet(
                            context,
                            sellerName: p.sellerName.isNotEmpty ? p.sellerName : 'Property Owner',
                            phone: p.sellerPhone.isNotEmpty ? p.sellerPhone : '',
                            propertyTitle: p.title,
                          ),
                          icon: Icon(Icons.call_outlined, size: 15.sp, color: PartnerColors.brand),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            side: BorderSide(color: PartnerColors.brand.withValues(alpha: 0.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          label: Text('Contact Seller', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: PartnerColors.brand)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: p.isBoosted
                              ? () => c.unboostProperty(p)
                              : () => Get.to(() => BoostPropertyScreen(property: p)),
                          icon: Icon(
                            p.isBoosted ? Icons.bolt_rounded : Icons.rocket_launch_rounded,
                            size: 15.sp,
                            color: Colors.white,
                          ),
                          label: Text(
                            p.isBoosted ? 'Boosted' : 'Boost Property',
                            style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.isBoosted ? PartnerColors.gold : PartnerColors.brand,
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(
                          color: PartnerColors.canvas,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: PartnerColors.line),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz_rounded, size: 20.sp, color: PartnerColors.ink),
                          onSelected: (v) {
                            if (v == 'live') {
                              c.updatePropertyStatus(p, 'Live');
                            } else if (v == 'draft') {
                              c.updatePropertyStatus(p, 'Draft');
                            } else if (v == 'delegate') {
                              showDelegatePropertySheet(context, property: p);
                            } else if (v == 'remove_delegation') {
                              c.removePropertyDelegation(propertyId: p.id);
                            } else if (v == 'delete') {
                              c.deleteProperty(p);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'live', child: Text('Set Live')),
                            const PopupMenuItem(value: 'draft', child: Text('Set Draft')),
                            if (c.isTeamOwner.value)
                              const PopupMenuItem(value: 'delegate', child: Text('Delegate to Sub-Agent')),
                            if (c.isTeamOwner.value)
                              const PopupMenuItem(value: 'remove_delegation', child: Text('Remove Delegation')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Property', style: TextStyle(color: PartnerColors.danger)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE3E8ED)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18.sp, color: const Color(0xFF0A5C4A)),
              SizedBox(height: 4.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9.5.sp, color: PartnerColors.ink, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
