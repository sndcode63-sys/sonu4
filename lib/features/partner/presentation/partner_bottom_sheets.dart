import '../models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/partner_home_controller.dart';
import '../../../core/routes/app_routes.dart';
import 'boost_property_screen.dart';

import 'widgets/partner_ui.dart';
/// Shows the Contact Seller modal bottom sheet.
void showContactSellerSheet(
  BuildContext context, {
  String sellerName = 'Property Contact',
  String phone = '',
  String propertyTitle = 'Property',
  String? reason,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ContactSellerSheet(
      sellerName: sellerName,
      phone: phone,
      propertyTitle: propertyTitle,
      reason: reason,
    ),
  );
}

class _ContactSellerSheet extends StatefulWidget {
  final String sellerName;
  final String phone;
  final String propertyTitle;
  final String? reason;

  const _ContactSellerSheet({
    required this.sellerName,
    required this.phone,
    required this.propertyTitle,
    this.reason,
  });

  @override
  State<_ContactSellerSheet> createState() => _ContactSellerSheetState();
}

class _ContactSellerSheetState extends State<_ContactSellerSheet> {
  String selectedPrompt = 'Confirm site visit date/time';

  final prompts = [
    'Confirm site visit date/time',
    'Request pending documents',
    'Discuss price negotiation',
    'Property photos needed',
    'Follow up on buyer interest',
  ];

  Future<void> _notify(String channel) async {
    Navigator.pop(context);
    final cleanPhone = widget.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = Uri.encodeComponent(
      'Hello ${widget.sellerName}, regarding ${widget.propertyTitle}: $selectedPrompt',
    );

    if (cleanPhone.isNotEmpty) {
      try {
        if (channel == 'WhatsApp') {
          final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
          if (await canLaunchUrl(waUri)) {
            await launchUrl(waUri, mode: LaunchMode.externalApplication);
            return;
          }
        } else if (channel == 'Direct Call') {
          final telUri = Uri.parse('tel:$cleanPhone');
          if (await canLaunchUrl(telUri)) {
            await launchUrl(telUri);
            return;
          }
        } else if (channel == 'SMS') {
          final smsUri = Uri.parse('sms:$cleanPhone?body=$msg');
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri);
            return;
          }
        }
      } catch (_) {}
    }

    Get.snackbar(
      channel,
      cleanPhone.isNotEmpty
          ? 'Initiating $channel with ${widget.sellerName} ($cleanPhone)\nTopic: "$selectedPrompt"'
          : 'No direct phone number provided for ${widget.sellerName}.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0B1B2E),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: EdgeInsets.all(12.w),
      borderRadius: 12.r,
      icon: const Icon(Icons.send_rounded, color: Color(0xFF9BE5CF)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact Seller',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Seller Info Card
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE3E8ED)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: const Color(0xFF0A5C4A).withValues(alpha: 0.12),
                    child: Text(
                      widget.sellerName.isNotEmpty ? widget.sellerName[0] : 'S',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A5C4A),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.sellerName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0B1B2E),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F3EF),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Individual',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0A5C4A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          widget.propertyTitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: PartnerColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.phone,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0A5C4A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            // Warning Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: const Color(0xFFB7791F), size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.reason ??
                          'Site visit is pending for this property. Confirm visit date & time with the seller.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF92400E),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            // Quick Message Chips
            Text(
              'Quick Message Topic',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: PartnerColors.ink,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: prompts.map((p) {
                final isSel = selectedPrompt == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => selectedPrompt = p);
                  },
                  labelStyle: TextStyle(
                    fontSize: 11.sp,
                    color: isSel ? Colors.white : PartnerColors.ink,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                  ),
                  selectedColor: const Color(0xFF0A5C4A),
                  backgroundColor: const Color(0xFFEEF2F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF0A5C4A) : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _notify('WhatsApp'),
                    icon: Icon(Icons.chat_bubble_rounded, size: 16.sp, color: Colors.white),
                    label: Text(
                      'WhatsApp',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _notify('Direct Call'),
                    icon: Icon(Icons.phone_rounded, size: 16.sp, color: Colors.white),
                    label: Text(
                      'Direct Call',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A5C4A),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _notify('SMS'),
                icon: Icon(Icons.sms_outlined, size: 16.sp, color: const Color(0xFF0B1B2E)),
                label: Text(
                  'Send SMS Text',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  side: const BorderSide(color: Color(0xFFC9D2DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the Review Documents modal bottom sheet.
/// Explicitly wrapped in a scrollable view as requested ("Yeh sab scroll me hona chahiye").
void showReviewDocumentsSheet(
  BuildContext context, {
  String propertyTitle = 'Property',
  String sellerName = 'Property Owner',
  String phone = '',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ReviewDocumentsSheet(
      propertyTitle: propertyTitle,
      sellerName: sellerName,
      phone: phone,
    ),
  );
}

class _ReviewDocumentsSheet extends StatefulWidget {
  final String propertyTitle;
  final String sellerName;
  final String phone;

  const _ReviewDocumentsSheet({
    required this.propertyTitle,
    required this.sellerName,
    required this.phone,
  });

  @override
  State<_ReviewDocumentsSheet> createState() => _ReviewDocumentsSheetState();
}

class _ReviewDocumentsSheetState extends State<_ReviewDocumentsSheet> {
  final List<Map<String, dynamic>> documents = [
    {
      'title': 'Sale Deed / Title Deed',
      'desc': 'Primary ownership document proving clear title',
      'status': 'Verified',
      'statusColor': const Color(0xFF129B6C),
      'statusBg': const Color(0xFFE6F5EE),
      'icon': Icons.verified_rounded,
      'isUploaded': true,
    },
    {
      'title': 'Encumbrance Certificate (EC)',
      'desc': 'Non-encumbrance proof for the past 15 years',
      'status': 'Pending Review',
      'statusColor': const Color(0xFFD9961F),
      'statusBg': const Color(0xFFFFFBEB),
      'icon': Icons.pending_actions_rounded,
      'isUploaded': true,
    },
    {
      'title': 'Property Tax Receipts',
      'desc': 'Latest paid municipal tax receipt (FY 2024-25)',
      'status': 'Verified',
      'statusColor': const Color(0xFF129B6C),
      'statusBg': const Color(0xFFE6F5EE),
      'icon': Icons.check_circle_rounded,
      'isUploaded': true,
    },
    {
      'title': 'Building Approval Plan',
      'desc': 'Noida Authority sanctioned building blueprint',
      'status': 'Action Needed',
      'statusColor': const Color(0xFFD64545),
      'statusBg': const Color(0xFFFEF2F2),
      'icon': Icons.warning_amber_rounded,
      'isUploaded': false,
    },
    {
      'title': 'Occupancy Certificate (OC)',
      'desc': 'Authority completion & occupancy handover',
      'status': 'Optional',
      'statusColor': const Color(0xFF5B6B7C),
      'statusBg': const Color(0xFFEEF2F5),
      'icon': Icons.info_outline_rounded,
      'isUploaded': false,
    },
    {
      'title': 'Electricity & Water Bills',
      'desc': 'Zero arrears proof on utility meters',
      'status': 'Verified',
      'statusColor': const Color(0xFF129B6C),
      'statusBg': const Color(0xFFE6F5EE),
      'icon': Icons.verified_rounded,
      'isUploaded': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final verifiedCount = documents.where((d) => d['status'] == 'Verified').length;
    final progress = verifiedCount / documents.length;

    return Container(
      height: 0.85.sh,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Header (pinned)
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 8.h),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Documents',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1B2E),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.propertyTitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: PartnerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable content ("Yeh sab scroll me hona chahiye")
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Progress Card
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFE3E8ED)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Verification Progress',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1B2E),
                              ),
                            ),
                            Text(
                              '$verifiedCount of ${documents.length} (${(progress * 100).toInt()}%)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A5C4A),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7.h,
                            backgroundColor: const Color(0xFFE3E8ED),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A5C4A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Documents Checklist
                  Text(
                    'Document Checklist',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B1B2E),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  ...documents.map((doc) {
                    final status = doc['status'] as String;
                    final statusColor = doc['statusColor'] as Color;
                    final statusBg = doc['statusBg'] as Color;
                    final isUploaded = doc['isUploaded'] as bool;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: status == 'Action Needed'
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFE3E8ED),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
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
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  doc['icon'] as IconData,
                                  size: 18.sp,
                                  color: statusColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc['title'] as String,
                                      style: TextStyle(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B1B2E),
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      doc['desc'] as String,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: PartnerColors.textSecondary,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isUploaded)
                                TextButton.icon(
                                  onPressed: () {
                                    Get.snackbar(
                                      'Viewing Document',
                                      'Opening ${doc['title']} preview...',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                                  icon: Icon(Icons.remove_red_eye_outlined, size: 14.sp),
                                  label: Text('View File', style: TextStyle(fontSize: 11.5.sp)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0A5C4A),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              SizedBox(width: 6.w),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    doc['status'] = 'Verified';
                                    doc['statusColor'] = const Color(0xFF129B6C);
                                    doc['statusBg'] = const Color(0xFFE6F5EE);
                                    doc['icon'] = Icons.verified_rounded;
                                    doc['isUploaded'] = true;
                                  });
                                  Get.snackbar(
                                    'Verified',
                                    '${doc['title']} marked as verified',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: const Color(0xFF129B6C),
                                    colorText: Colors.white,
                                  );
                                },
                                icon: Icon(
                                  status == 'Verified' ? Icons.check_rounded : Icons.file_upload_outlined,
                                  size: 13.sp,
                                ),
                                label: Text(
                                  status == 'Verified' ? 'Re-verify' : 'Verify / Upload',
                                  style: TextStyle(fontSize: 11.5.sp),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0A5C4A),
                                  side: const BorderSide(color: Color(0xFF0A5C4A)),
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),

          // Pinned Footer
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE3E8ED))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showContactSellerSheet(
                          context,
                          sellerName: widget.sellerName,
                          phone: widget.phone,
                          propertyTitle: widget.propertyTitle,
                          reason: 'Need missing documents (Building approval, Title deed).',
                        );
                      },
                      icon: Icon(Icons.phone_in_talk_outlined, size: 16.sp, color: const Color(0xFF0A5C4A)),
                      label: Text(
                        'Contact Seller',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0A5C4A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Color(0xFF0A5C4A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Get.snackbar(
                          'Verification Submitted',
                          'Property verification report has been sent to DigiNiwas QC team.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF0A5C4A),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 3),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C4A),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Submit Verification',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the Top Up Credits modal bottom sheet.
void showTopUpCreditsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _TopUpCreditsSheet(),
  );
}

class _TopUpCreditsSheet extends StatefulWidget {
  const _TopUpCreditsSheet();

  @override
  State<_TopUpCreditsSheet> createState() => _TopUpCreditsSheetState();
}

class _TopUpCreditsSheetState extends State<_TopUpCreditsSheet> {
  int selectedPackIndex = 1; // Default to 1000 credits (best value)
  String paymentMethod = 'UPI';

  /// Prefers packs configured on the backend so the charged amount always
  /// matches the server's pricing. Falls back to the static list below.
  List<Map<String, dynamic>> _resolvePacks(PartnerHomeController c) {
    final live = c.creditPacks
        .where((p) => p.priceInr > 0 && p.credits > 0 && !p.isFallback)
        .toList();
    if (live.isEmpty) return _staticPacks;
    return [
      for (final p in live)
        {
          'credits': p.credits,
          'price': p.priceInr,
          'rate': '₹${(p.priceInr / p.credits).toStringAsFixed(2)} / credit',
          'tag': p.label,
          'tagColor': const Color(0xFF0A5C4A),
          'code': p.code,
        },
    ];
  }

  final List<Map<String, dynamic>> _staticPacks = [
    {
      'credits': 500,
      'price': 999,
      'rate': '₹2.00 / credit',
      'tag': 'Standard',
      'tagColor': const Color(0xFF5B6B7C),
    },
    {
      'credits': 1000,
      'price': 1799,
      'rate': '₹1.80 / credit',
      'tag': 'Best Value • 10% Off',
      'tagColor': const Color(0xFF0A5C4A),
    },
    {
      'credits': 3000,
      'price': 4499,
      'rate': '₹1.50 / credit',
      'tag': 'Agency Pro • 25% Off',
      'tagColor': const Color(0xFFD9961F),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final c = ensurePartnerHomeController();
    final packs = _resolvePacks(c);
    if (selectedPackIndex >= packs.length) selectedPackIndex = packs.length - 1;
    final selectedPack = packs[selectedPackIndex];
    // `total` is exactly what Razorpay will charge, so the button text and the
    // amount sent to the create-order API can never drift apart.
    final total = selectedPack['price'] as int;
    final basePrice = (total / 1.18).round();
    final gst = total - basePrice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Up Credits',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1B2E),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Obx(() => Text(
                            'Current Balance: ${c.creditBalance.value} Credits',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF0A5C4A),
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Guidelines & Refund Policy banner
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(AppRoutes.creditGuidelines);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5EE),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFB5E4CC)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16.sp, color: const Color(0xFF12805C)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '100% Refund Policy • How Credits Work & Rate Card',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A5C4A),
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11.sp, color: const Color(0xFF12805C)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              // Select Credit Pack
              Text(
                'Select Credit Pack',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              SizedBox(height: 10.h),

              ...List.generate(packs.length, (idx) {
                final p = packs[idx];
                final isSel = selectedPackIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => selectedPackIndex = idx),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFE8F3EF) : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSel ? const Color(0xFF0A5C4A) : PartnerColors.textTertiary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6.w,
                                runSpacing: 2.h,
                                children: [
                                  Text(
                                    '${p['credits']} Credits',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0B1B2E),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: (p['tagColor'] as Color).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      p['tag'] as String,
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                        color: p['tagColor'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                p['rate'] as String,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: PartnerColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${p['price']}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1B2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 12.h),

              // Payment Method
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _paymentMethodChip('UPI', Icons.account_balance_wallet_outlined),
                  SizedBox(width: 8.w),
                  _paymentMethodChip('Cards', Icons.credit_card_rounded),
                  SizedBox(width: 8.w),
                  _paymentMethodChip('Net Banking', Icons.account_balance_rounded),
                ],
              ),

              SizedBox(height: 16.h),

              // Price Breakdown
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE3E8ED)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary)),
                        Text('₹$basePrice', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GST (18%, included)', style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary)),
                        Text('₹$gst', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E))),
                        Text('₹$total', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0A5C4A))),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                      onPressed: c.purchaseLoading.value
                          ? null
                          : () async {
                              // Razorpay handles the payment; the backend
                              // verifies it and adds the credits. Nothing is
                              // credited here on the client.
                              final ok = await c.buyCreditsWithRazorpay(
                                amountInRupees: total,
                                description:
                                    '${selectedPack['credits']} Credits',
                                productCode: selectedPack['code'] as String?,
                              );
                              if (ok && context.mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C4A),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: c.purchaseLoading.value
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Pay ₹$total • Add ${selectedPack['credits']} Credits',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    )),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _paymentMethodChip(String label, IconData icon) {
    final isSel = paymentMethod == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => paymentMethod = label),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFE8F3EF) : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: isSel ? const Color(0xFF0A5C4A) : PartnerColors.textSecondary),
              SizedBox(height: 3.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? const Color(0xFF0A5C4A) : PartnerColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// ADD CONTACT HISTORY (CALL NOTES) BOTTOM SHEET (POST /api/leads/:id/contact-history)
// =============================================================================

void showAddContactHistorySheet(
  BuildContext context, {
  required PartnerLead lead,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddContactHistorySheet(lead: lead),
  );
}

class _AddContactHistorySheet extends StatefulWidget {
  final PartnerLead lead;
  const _AddContactHistorySheet({required this.lead});

  @override
  State<_AddContactHistorySheet> createState() => _AddContactHistorySheetState();
}

class _AddContactHistorySheetState extends State<_AddContactHistorySheet> {
  final TextEditingController _noteCtrl = TextEditingController();
  String _selectedChannel = 'Phone Call';
  bool _isSaving = false;

  final List<String> _channels = ['Phone Call', 'WhatsApp', 'Site Visit', 'Meeting'];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) {
      Get.snackbar('Notice', 'Please write a note before saving.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    final c = ensurePartnerHomeController();
    await c.addContactHistory(
      widget.lead,
      note: note,
      channel: _selectedChannel,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
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
              Text(
                'Add Call Note / Activity',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            'Client: ${widget.lead.buyerName} • ${widget.lead.phone}',
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
          SizedBox(height: 12.h),
          Text('Channel', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            children: _channels.map((ch) {
              final isSel = _selectedChannel == ch;
              return ChoiceChip(
                label: Text(ch, style: TextStyle(fontSize: 11.5.sp, color: isSel ? Colors.white : PartnerColors.ink)),
                selected: isSel,
                selectedColor: const Color(0xFF0A5C4A),
                backgroundColor: const Color(0xFFEEF2F5),
                onSelected: (val) => setState(() => _selectedChannel = ch),
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),
          Text('Discussion Summary', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Buyer visited location, interested in 3 BHK, budget 85L...',
              hintStyle: TextStyle(fontSize: 12.sp, color: PartnerColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C4A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Activity Note', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CONVERT LEAD DEAL BOTTOM SHEET (PATCH /api/leads/:id/convert)
// =============================================================================

void showConvertLeadSheet(
  BuildContext context, {
  required PartnerLead lead,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ConvertLeadSheet(lead: lead),
  );
}

class _ConvertLeadSheet extends StatefulWidget {
  final PartnerLead lead;
  const _ConvertLeadSheet({required this.lead});

  @override
  State<_ConvertLeadSheet> createState() => _ConvertLeadSheetState();
}

class _ConvertLeadSheetState extends State<_ConvertLeadSheet> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final amtStr = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final amt = num.tryParse(amtStr);
    if (amt == null || amt <= 0) {
      Get.snackbar('Notice', 'Please enter a valid deal amount.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    final c = ensurePartnerHomeController();
    await c.convertLead(
      widget.lead,
      amount: amt,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : 'Deal closed successfully',
    );
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
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
                  Icon(Icons.celebration_rounded, color: const Color(0xFF129B6C), size: 22.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Mark Deal Converted',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            'Client: ${widget.lead.buyerName} • ${widget.lead.propertyTitle}',
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          Text('Deal Closure Value (₹)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 8500000',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF129B6C)),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text('Closing Remarks', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Agreement signed, token amount paid.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF129B6C)),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _convert,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF129B6C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm & Convert Lead', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ALLOCATE LEAD TO SUB-AGENT (PATCH /api/leads/:id/allocate-subpartner)
// =============================================================================

void showAllocateLeadSheet(
  BuildContext context, {
  required PartnerLead lead,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AllocateLeadSheet(lead: lead),
  );
}

class _AllocateLeadSheet extends StatefulWidget {
  final PartnerLead lead;
  const _AllocateLeadSheet({required this.lead});

  @override
  State<_AllocateLeadSheet> createState() => _AllocateLeadSheetState();
}

class _AllocateLeadSheetState extends State<_AllocateLeadSheet> {
  String? _selectedMemberId;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final c = ensurePartnerHomeController();
    final members = c.teamMembers;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
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
              Text(
                'Assign Lead to Sub-Agent',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            'Lead: ${widget.lead.buyerName} • ${widget.lead.propertyTitle}',
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          if (members.isEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text('No verified sub-agents found in your team.', style: TextStyle(color: PartnerColors.textSecondary, fontSize: 13.sp)),
              ),
            ),
          ] else ...[
            Text('Select Team Member', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 8.h),
            ...members.map((m) {
              final id = asString(m['_id']) ?? asString(m['id']) ?? '';
              final name = asString(m['name']) ?? 'Member';
              final role = asString(m['teamRole']) ?? 'Sub-Agent';
              final isSel = _selectedMemberId == id;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Material(
                  color: isSel ? const Color(0xFFE8F3EF) : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMemberId = id),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: const Color(0xFF0B1B2E))),
                                SizedBox(height: 2.h),
                                Text(role, style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF0A5C4A)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),
            Row(
              children: [
                if (widget.lead.isAllocatedToSubAgent)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () async {
                        setState(() => _isSaving = true);
                        await c.removeLeadSubPartnerAllocation(widget.lead);
                        if (mounted) {
                          setState(() => _isSaving = false);
                          Navigator.pop(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      child: Text('Revoke', style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                    ),
                  ),
                if (widget.lead.isAllocatedToSubAgent) SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedMemberId == null || _isSaving ? null : () async {
                      setState(() => _isSaving = true);
                      await c.allocateLeadToSubPartner(widget.lead, subPartnerId: _selectedMemberId!);
                      if (mounted) {
                        setState(() => _isSaving = false);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A5C4A),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Assign Lead', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CREATE MANUAL LEAD BOTTOM SHEET (POST /api/leads)
// =============================================================================

void showCreateManualLeadSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CreateManualLeadSheet(),
  );
}

class _CreateManualLeadSheet extends StatefulWidget {
  const _CreateManualLeadSheet();

  @override
  State<_CreateManualLeadSheet> createState() => _CreateManualLeadSheetState();
}

class _CreateManualLeadSheetState extends State<_CreateManualLeadSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedPropertyId;
  String _selectedPriority = 'Medium';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Notice', 'Please enter lead / client name', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (phone.length < 10) {
      Get.snackbar('Notice', 'Please enter a valid 10-digit mobile number', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final budgetStr = _budgetCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final budgetNum = num.tryParse(budgetStr);

    setState(() => _isSaving = true);
    final c = ensurePartnerHomeController();
    final success = await c.createManualLead(
      name: name,
      phone: phone,
      propertyId: _selectedPropertyId,
      estimatedValue: budgetNum,
      message: _notesCtrl.text.trim(),
      priority: _selectedPriority,
      source: 'Agent Manual App Entry',
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ensurePartnerHomeController();
    final properties = c.properties;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(color: const Color(0xFF0A5C4A).withValues(alpha: 0.3), width: 1.5),
      ),
      child: SingleChildScrollView(
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBEFE0),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded, color: const Color(0xFF0A5C4A), size: 22.sp),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Add Buyer Lead',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text('Client Full Name *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 6.h),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Ramesh Sharma',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text('Phone Number *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 6.h),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. 9876543210',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (properties.isNotEmpty) ...[
              Text('Interested Property (Optional)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
              SizedBox(height: 6.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedPropertyId,
                isExpanded: true,
                hint: const Text('Select property'),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('General / Not specific')),
                  ...properties.map((p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedPropertyId = val),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.home_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
            Text('Estimated Budget (₹)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 6.h),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 6500000',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text('Priority', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 6.h),
            Row(
              children: ['Low', 'Medium', 'High'].map((p) {
                final isSel = _selectedPriority == p;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: isSel,
                    selectedColor: const Color(0xFFCBEFE0),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF0A5C4A) : PartnerColors.ink,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedPriority = p),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 12.h),
            Text('Buyer Requirements / Notes', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 6.h),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Looking for 3 BHK, ready to move in 2 months',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C4A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Create Lead', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// REJECT LEAD BOTTOM SHEET (PATCH /api/leads/:id/reject)
// =============================================================================

void showRejectLeadSheet(
  BuildContext context, {
  required PartnerLead lead,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RejectLeadSheet(lead: lead),
  );
}

class _RejectLeadSheet extends StatefulWidget {
  final PartnerLead lead;
  const _RejectLeadSheet({required this.lead});

  @override
  State<_RejectLeadSheet> createState() => _RejectLeadSheetState();
}

class _RejectLeadSheetState extends State<_RejectLeadSheet> {
  final _reasonCtrl = TextEditingController();
  final List<String> _commonReasons = [
    'Not Interested',
    'Invalid / Wrong Phone',
    'Budget Too Low',
    'Already Purchased',
    'Looking outside territory',
  ];
  String? _selectedReason;
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim().isNotEmpty
        ? _reasonCtrl.text.trim()
        : (_selectedReason ?? '');
    if (reason.isEmpty) {
      Get.snackbar('Notice', 'Please choose or type a reason for rejecting', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    final c = ensurePartnerHomeController();
    await c.rejectLead(widget.lead, reason: reason);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5),
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
                  Icon(Icons.cancel_outlined, color: Colors.red, size: 22.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Reject Lead',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            'Lead: ${widget.lead.buyerName} • ${widget.lead.propertyTitle}',
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          Text('Select Reason', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _commonReasons.map((r) {
              final isSel = _selectedReason == r;
              return ChoiceChip(
                label: Text(r),
                selected: isSel,
                selectedColor: Colors.red.shade50,
                labelStyle: TextStyle(
                  color: isSel ? Colors.red.shade800 : PartnerColors.ink,
                  fontSize: 11.5.sp,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedReason = r;
                    _reasonCtrl.text = r;
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),
          Text('Or Enter Custom Reason', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          TextField(
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Reason for rejection...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm Reject Lead', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CLOSE LEAD BOTTOM SHEET (PATCH /api/leads/:id/close)
// =============================================================================

void showCloseLeadSheet(
  BuildContext context, {
  required PartnerLead lead,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CloseLeadSheet(lead: lead),
  );
}

class _CloseLeadSheet extends StatefulWidget {
  final PartnerLead lead;
  const _CloseLeadSheet({required this.lead});

  @override
  State<_CloseLeadSheet> createState() => _CloseLeadSheetState();
}

class _CloseLeadSheetState extends State<_CloseLeadSheet> {
  final _reasonCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('Notice', 'Please enter a reason for closing this lead', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    final c = ensurePartnerHomeController();
    await c.closeLead(widget.lead, reason: reason);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(color: const Color(0xFF0A5C4A).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Close Lead',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            'Lead: ${widget.lead.buyerName} • ${widget.lead.propertyTitle}',
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          Text('Closure Reason', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          TextField(
            controller: _reasonCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Bought property through another platform, or deferred purchase',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1B2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Close Lead', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOOST PROPERTY BOTTOM SHEET (POST /api/promotions & PATCH /api/newproperties/:id/boost)
// =============================================================================

void showBoostPropertySheet(
  BuildContext context, {
  required PartnerProperty property,
}) {
  Get.to(() => BoostPropertyScreen(property: property));
}

class _BoostPropertySheet extends StatefulWidget {
  final PartnerProperty property;
  const _BoostPropertySheet({required this.property});

  @override
  State<_BoostPropertySheet> createState() => _BoostPropertySheetState();
}

class _BoostPropertySheetState extends State<_BoostPropertySheet> {
  int _selectedOption = 0;
  bool _isBoosting = false;

  final _options = [
    {'title': 'Boost Property', 'days': 7, 'credits': 100, 'type': 'PROPERTY_BOOST', 'badge': '7 Days', 'desc': 'Top search visibility across territory'},
    {'title': 'Featured Property', 'days': 7, 'credits': 100, 'type': 'FEATURED_7_DAYS', 'badge': 'Featured', 'desc': 'Highlighted badge on listing card'},
    {'title': 'Locality Top', 'days': 30, 'credits': 210, 'type': 'LOCALITY_TOP_30_DAYS', 'badge': '30 Days', 'desc': 'Pinned to top of locality for 30 days'},
  ];

  @override
  Widget build(BuildContext context) {
    final c = ensurePartnerHomeController();
    final opt = _options[_selectedOption];
    final cost = opt['credits'] as int;
    final hasEnough = c.creditBalance.value >= cost;

    return Container(
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
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.rocket_launch_rounded, color: const Color(0xFFB7791F), size: 18.sp),
                  ),
                  SizedBox(width: 8.w),
                  Text('Boost Listing', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E))),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          Text(widget.property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5.sp, color: PartnerColors.textSecondary)),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Wallet Balance:', style: TextStyle(fontSize: 12.sp, color: PartnerColors.ink)),
                Text('${c.creditBalance.value} Credits', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0A5C4A))),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Text('Select Boost Plan', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 8.h),
          ...List.generate(_options.length, (idx) {
            final o = _options[idx];
            final isSel = _selectedOption == idx;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Material(
                color: isSel ? const Color(0xFFE8F3EF) : const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: () => setState(() => _selectedOption = idx),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      o['title'] as String,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: const Color(0xFF0B1B2E)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A5C4A).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      o['badge'] as String,
                                      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0A5C4A)),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                o['desc'] as String,
                                style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${o['credits']} Credits',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0A5C4A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 12.h),
          if (!hasEnough)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                'Insufficient credits! Please top-up your wallet first.',
                style: TextStyle(color: Colors.red, fontSize: 11.5.sp, fontWeight: FontWeight.w500),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: !hasEnough || _isBoosting ? null : () async {
                setState(() => _isBoosting = true);
                await c.boostPropertyWithPromotion(
                  propertyId: widget.property.id,
                  promotionType: opt['type'] as String,
                  days: opt['days'] as int,
                );
                if (mounted) {
                  setState(() => _isBoosting = false);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C4A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _isBoosting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Boost Now ($cost Credits)', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DELEGATE PROPERTY BOTTOM SHEET (PATCH /api/team-partners/:ownerId/properties/:id/delegate)
// =============================================================================

void showDelegatePropertySheet(
  BuildContext context, {
  required PartnerProperty property,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DelegatePropertySheet(property: property),
  );
}

class _DelegatePropertySheet extends StatefulWidget {
  final PartnerProperty property;
  const _DelegatePropertySheet({required this.property});

  @override
  State<_DelegatePropertySheet> createState() => _DelegatePropertySheetState();
}

class _DelegatePropertySheetState extends State<_DelegatePropertySheet> {
  String? _selectedMemberId;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final c = ensurePartnerHomeController();
    final members = c.teamMembers;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
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
              Text('Delegate Property to Sub-Agent', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          Text(widget.property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary)),
          SizedBox(height: 14.h),
          if (members.isEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text('No verified sub-agents found in your team.', style: TextStyle(color: PartnerColors.textSecondary, fontSize: 13.sp)),
              ),
            ),
          ] else ...[
            Text('Assign to Sub-Agent', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
            SizedBox(height: 8.h),
            ...members.map((m) {
              final id = asString(m['_id']) ?? asString(m['id']) ?? '';
              final name = asString(m['name']) ?? 'Member';
              final role = asString(m['teamRole']) ?? 'Sub-Agent';
              final isSel = _selectedMemberId == id;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Material(
                  color: isSel ? const Color(0xFFE8F3EF) : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMemberId = id),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: const Color(0xFF0B1B2E))),
                                SizedBox(height: 2.h),
                                Text(role, style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF0A5C4A)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton(
                onPressed: _selectedMemberId == null || _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  await c.delegateProperty(propertyId: widget.property.id, memberId: _selectedMemberId);
                  if (mounted) {
                    setState(() => _isSaving = false);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C4A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirm Delegation', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// UPDATE VISIT STATUS BOTTOM SHEET (PATCH /api/visits/:id/status)
// =============================================================================

void showUpdateVisitStatusSheet(
  BuildContext context, {
  required PartnerVisit visit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UpdateVisitStatusSheet(visit: visit),
  );
}

class _UpdateVisitStatusSheet extends StatefulWidget {
  final PartnerVisit visit;
  const _UpdateVisitStatusSheet({required this.visit});

  @override
  State<_UpdateVisitStatusSheet> createState() => _UpdateVisitStatusSheetState();
}

class _UpdateVisitStatusSheetState extends State<_UpdateVisitStatusSheet> {
  String _selectedStatus = 'Completed';
  final TextEditingController _remarksCtrl = TextEditingController();
  bool _isSaving = false;

  final _statuses = ['Completed', 'Follow-up Planned', 'Rescheduled', 'Cancelled'];

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    setState(() => _isSaving = true);
    final c = ensurePartnerHomeController();
    await c.updateVisitStatus(
      widget.visit,
      _selectedStatus,
      remarks: _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
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
              Text('Update Site Visit Status', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          Text('${widget.visit.propertyTitle} • Buyer: ${widget.visit.buyerName}', style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary)),
          SizedBox(height: 14.h),
          Text('Select Status', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _statuses.map((st) {
              final isSel = _selectedStatus == st;
              return ChoiceChip(
                label: Text(st, style: TextStyle(fontSize: 11.5.sp, color: isSel ? Colors.white : PartnerColors.ink)),
                selected: isSel,
                selectedColor: const Color(0xFF0A5C4A),
                backgroundColor: const Color(0xFFEEF2F5),
                onSelected: (val) => setState(() => _selectedStatus = st),
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),
          Text('Visit Remarks / Feedback', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E))),
          SizedBox(height: 6.h),
          TextField(
            controller: _remarksCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Buyer liked location, asked for negotiation on parking.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C4A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Update Status', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
