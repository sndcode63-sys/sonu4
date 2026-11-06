import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/partner_home_controller.dart';
import 'partner_bottom_sheets.dart';
import 'widgets/deal_success_fee_calculator.dart';

import 'widgets/partner_ui.dart';
class CreditGuidelinesScreen extends StatefulWidget {
  const CreditGuidelinesScreen({super.key});

  @override
  State<CreditGuidelinesScreen> createState() => _CreditGuidelinesScreenState();
}

class _CreditGuidelinesScreenState extends State<CreditGuidelinesScreen> {
  // Refund Dialog State
  String _selectedRefundReason = 'Buyer contact unreachable or switched off';

  final List<String> _refundReasons = [
    'Buyer contact unreachable or switched off',
    'Invalid or wrong phone number',
    'Buyer already purchased / rented elsewhere',
    'Did not make this property inquiry (Wrong lead)',
    'Duplicate lead inquiry',
  ];

  void _showRefundDialog(BuildContext context, PartnerHomeController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
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
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Claim 100% Credit Refund',
                      style: TextStyle(
                        fontSize: 17.sp,
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
                SizedBox(height: 6.h),
                Text(
                  'If an unlocked buyer contact was invalid or unreachable, ${(c.leads.isNotEmpty ? c.leads.first.unlockCost : 25)} credits will be auto-refunded to your wallet under DigiNiwas 100% Guarantee.',
                  style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary, height: 1.3),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Select Refund Reason',
                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                ),
                SizedBox(height: 8.h),
                ..._refundReasons.map((r) {
                  final isSel = _selectedRefundReason == r;
                  return GestureDetector(
                    onTap: () => setModalState(() => _selectedRefundReason = r),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFE8F3EF) : const Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 16.sp,
                            color: isSel ? const Color(0xFF0A5C4A) : Colors.grey,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                                color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFF0B1B2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await c.requestCreditRefund(
                        credits: c.leads.isNotEmpty ? c.leads.first.unlockCost : 25,
                        reason: _selectedRefundReason,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A5C4A),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit Refund Request (25 Credits)',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final c = ensurePartnerHomeController();

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      appBar: AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1B2E), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Credit Guidelines & Rules',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B1B2E),
              ),
            ),
            Text(
              'क्रेडिट कैसे काम करता है • DigiNiwas Partner',
              style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF0A5C4A)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            onPressed: () {
              Get.snackbar(
                'DigiNiwas Partner Policy',
                '0% Platform Fee on your own self-sourced listings. Disclosed service fee applies only to assigned properties.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF1F3447),
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Brand Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F3447), Color(0xFF1E3343)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F3447).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3FCFA6).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(Icons.stars_rounded, color: const Color(0xFF3FCFA6), size: 20.sp),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'DIGINIWAS CREDITS',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3FCFA6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Digital भी, Genuine भी',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Grow Your Real Estate Business with Zero Commission',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Credits are the fuel for DigiNiwas Partners. Unlock verified buyers, boost your listings to 3x buyers, and keep 100% of your brokerage fees.',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70, height: 1.35),
                    ),
                    SizedBox(height: 14.h),
                    // Wallet Snapshot Row
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Active Balance', style: TextStyle(fontSize: 10.5.sp, color: Colors.white60)),
                              SizedBox(height: 2.h),
                              Obx(() => Text(
                                    '${c.creditBalance.value} Credits',
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF3FCFA6),
                                    ),
                                  )),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => showTopUpCreditsSheet(context),
                            icon: Icon(Icons.add_rounded, size: 14.sp, color: const Color(0xFF0B1B2E)),
                            label: Text(
                              'Top Up',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1B2E),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3FCFA6),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // SECTION 1: How Credits Work (Rate Card)
              Text(
                'Credit Rate Card • क्रेडिट कैसे खर्च होता है?',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Transparent, fixed credit costs for every action. No surprises.',
                style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary),
              ),
              SizedBox(height: 10.h),

              Obx(() {
                final leadCost = c.leads.isNotEmpty ? c.leads.first.unlockCost : 25;
                final boostPlan = c.propertyPlans.firstWhereOrNull((p) => p.placement.toUpperCase().contains('BOOST') || p.durationDays == 7);
                final boostCost = boostPlan != null && boostPlan.credits > 0 ? boostPlan.credits : 50;
                final boostDays = boostPlan?.durationDays ?? 7;

                final homePlan = c.propertyPlans.firstWhereOrNull((p) => p.placement.toUpperCase().contains('FEATURE') || p.placement.toUpperCase().contains('HOME') || p.durationDays == 14);
                final homeCost = homePlan != null && homePlan.credits > 0 ? homePlan.credits : 100;
                final homeDays = homePlan?.durationDays ?? 14;

                return Column(
                  children: [
                    _rateCardTile(
                      icon: Icons.lock_open_rounded,
                      title: 'Unlock Buyer Lead Contact',
                      cost: '$leadCost Credits',
                      costColor: const Color(0xFF0A5C4A),
                      features: [
                        'Direct Phone Number & WhatsApp connection',
                        'Verified Buyer Budget, Timeline & Preferences',
                        'AI Match Score for your assigned area',
                        '100% Refundable if contact is invalid or fake',
                      ],
                    ),
                    SizedBox(height: 10.h),
                    _rateCardTile(
                      icon: Icons.rocket_launch_rounded,
                      title: 'Boost Property Listing ($boostDays Days)',
                      cost: '$boostCost Credits',
                      costColor: const Color(0xFF3B7DD8),
                      features: [
                        '3x higher visibility in buyer search and recommendations',
                        'Highlighted "Featured" badge on listing thumbnail',
                        'Priority push notifications to active matching buyers',
                        'Active for $boostDays full days with view counter analytics',
                      ],
                    ),
                    SizedBox(height: 10.h),
                    _rateCardTile(
                      icon: Icons.star_rounded,
                      title: 'Feature on Homepage ($homeDays Days)',
                      cost: '$homeCost Credits',
                      costColor: const Color(0xFFD9961F),
                      features: [
                        'Top banner placement on city exploration feed',
                        'Spotlight in weekly buyer newsletter and WhatsApp alert',
                        'Ideal for luxury and high-value developer properties',
                      ],
                    ),
                    SizedBox(height: 10.h),
                    _rateCardTile(
                      icon: Icons.verified_user_rounded,
                      title: 'Verified Partner Site Visit Badge',
                      cost: '35 Credits',
                      costColor: const Color(0xFF129B6C),
                      features: [
                        'Official DigiNiwas "Verified Inspection" badge',
                        'Seller trust score increases, attracting 4x serious inquiries',
                        'Upload inspection photos and building checklist',
                      ],
                    ),
                  ],
                );
              }),

              SizedBox(height: 24.h),

              // SECTION 2: DigiNiwas Deal Success Fee Calculator
              const DealSuccessFeeCalculatorWidget(),

              SizedBox(height: 20.h),

              // SECTION 3: 100% Refund Protection Guarantee
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5EE),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFB5E4CC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_rounded, color: const Color(0xFF12805C), size: 24.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100% Refund Protection Policy',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0A5C4A),
                                ),
                              ),
                              Text(
                                'गलत या अमान्य लीड पर 100% क्रेडिट वापसी',
                                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'DigiNiwas verifies every buyer phone before listing. However, if any unlocked lead turns out to be unreachable, switched off for 48 hours, or was submitted by mistake, your 25 credits are credited back to your wallet instantly.',
                      style: TextStyle(fontSize: 11.5.sp, color: const Color(0xFF0A5C4A), height: 1.35),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRefundDialog(context, c),
                        icon: Icon(Icons.assignment_return_outlined, size: 16.sp, color: const Color(0xFF0A5C4A)),
                        label: Text(
                          'Claim Lead Credit Refund',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A5C4A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF12805C)),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // SECTION 4: Team & Agency Allocation
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE3E8ED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, color: const Color(0xFF0A5C4A), size: 22.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'Agency & Team Credit Pooling',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1B2E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Agency owners can buy high-tier credit packs (e.g. 3,000 or 5,000 credits with up to 25% discounts) and allocate credit quotas to sub-agents directly from Team Management.',
                      style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary, height: 1.35),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        _bulletItem('Centralized billing & invoice'),
                        SizedBox(width: 8.w),
                        _bulletItem('Instant sub-agent distribution'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // SECTION 5: FAQs
              Text(
                'Frequently Asked Questions (FAQ)',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              SizedBox(height: 10.h),

              _faqTile(
                question: 'Do purchased credits expire?',
                answer: 'No. Purchased credits do not expire and remain active in your DigiNiwas Partner Wallet indefinitely.',
              ),
              _faqTile(
                question: 'Does DigiNiwas take a percentage of my deal closure brokerage?',
                answer: 'For your own partner-sourced listings, DigiNiwas charges 0% platform closure fee. For seller-originated properties assigned to you by DigiNiwas, a disclosed partner service/closure fee applies and is shown before you accept the assignment.',
              ),
              _faqTile(
                question: 'How many times can a buyer lead be unlocked?',
                answer: 'A buyer lead is only unlocked for up to 3 verified partners in the designated locality to prevent lead fatigue and maintain high conversion for partners.',
              ),
              _faqTile(
                question: 'How does the credit refund get processed?',
                answer: 'If an unlocked contact is invalid, incorrect, or unreachable, submit a refund request within 48 hours. DigiNiwas reviews the claim and restores the eligible credits back to your wallet.',
              ),

              SizedBox(height: 24.h),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          'Guidelines Downloaded',
                          'Official DigiNiwas Partner Credit Guidelines & Policies PDF saved to downloads.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF0B1B2E),
                          colorText: Colors.white,
                        );
                      },
                      icon: Icon(Icons.download_rounded, size: 16.sp, color: const Color(0xFF0A5C4A)),
                      label: Text(
                        'Download PDF',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0A5C4A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0A5C4A)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => showTopUpCreditsSheet(context),
                      icon: Icon(Icons.add_circle_outline_rounded, size: 16.sp, color: Colors.white),
                      label: Text(
                        'Top Up Credits',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C4A),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rateCardTile({
    required IconData icon,
    required String title,
    required String cost,
    required Color costColor,
    required List<String> features,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE3E8ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: costColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: costColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: costColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  cost,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: costColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13.sp, color: const Color(0xFF129B6C)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.ink, height: 1.25),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F5),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.check, size: 12.sp, color: const Color(0xFF0A5C4A)),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 10.sp, color: const Color(0xFF0B1B2E), fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqTile({required String question, required String answer}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE3E8ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, size: 16.sp, color: const Color(0xFF0A5C4A)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            answer,
            style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }
}
