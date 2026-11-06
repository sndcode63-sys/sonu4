import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/partner_home_controller.dart';
import '../../../core/routes/app_routes.dart';
import 'partner_bottom_sheets.dart';
import 'widgets/deal_success_fee_calculator.dart';

import 'widgets/partner_ui.dart';
class CreditWalletScreen extends StatefulWidget {
  const CreditWalletScreen({super.key});

  @override
  State<CreditWalletScreen> createState() => _CreditWalletScreenState();
}

class _CreditWalletScreenState extends State<CreditWalletScreen> {
  bool _isCalculatorExpanded = true;

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
        title: Text(
          'Credit Wallet',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0B1B2E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Color(0xFF0A5C4A)),
            tooltip: 'Deal Success Fee Calculator',
            onPressed: () => _openDealSuccessFeeCalculator(context),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF0A5C4A)),
            tooltip: 'Credit Guidelines',
            onPressed: () => Get.toNamed(AppRoutes.creditGuidelines),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0B1B2E)),
            onPressed: () => c.loadCredits(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await c.loadCredits();
            await c.loadCreditPacks();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Balance Card
                Obx(() {
                  final bal = c.creditBalance.value;
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: PartnerGradients.brand,
                      borderRadius: BorderRadius.circular(22.r),
                      boxShadow: PartnerShadows.brand,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Credits',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9C46A).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined, color: const Color(0xFFE9C46A), size: 12.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Protected',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE9C46A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(Icons.stars_rounded, color: const Color(0xFFE9C46A), size: 30.sp),
                            SizedBox(width: 8.w),
                            Text(
                              '$bal',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Credits',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Estimated Value: ₹$bal (₹1 = 1 Credit) • ${c.creditValidityText}',
                          style: TextStyle(fontSize: 11.5.sp, color: Colors.white60),
                        ),
                        SizedBox(height: 18.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showTopUpCreditsSheet(context),
                            icon: Icon(Icons.add_circle_outline_rounded, size: 16.sp, color: const Color(0xFF0B1B2E)),
                            label: Text(
                              'Top Up Credits',
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1B2E),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 20.h),

                // Guarantee Banner (Tappable)
                InkWell(
                  onTap: () {
                    Get.defaultDialog(
                      title: '100% Lead Refund Guarantee',
                      titleStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1B2E),
                      ),
                      middleText:
                          'DigiNiwas ensures 100% genuine buyer leads.\n\nIf any contact number you unlock is invalid, unreachable for 48 hours, or fake, tap "Report Issue" in your Leads tab to get your credits refunded instantly back into your wallet balance.',
                      middleTextStyle: TextStyle(fontSize: 12.5.sp, color: PartnerColors.ink, height: 1.4),
                      textConfirm: 'Got it',
                      confirmTextColor: Colors.white,
                      buttonColor: const Color(0xFF0A5C4A),
                      onConfirm: () => Get.back(),
                      radius: 14.r,
                    );
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F5EE),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x06000000),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: const Color(0xFF12805C), size: 20.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            '100% Refund Policy: If a buyer lead contact is invalid or fake, credits are auto-refunded to your wallet.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF0A5C4A),
                              height: 1.3,
                            ),
                          ),
                        ),
                        Icon(Icons.info_outline_rounded, size: 16.sp, color: const Color(0xFF12805C)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Credit Guidelines & Rules Shortcut Card
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.creditGuidelines),
                  child: Container(
                    padding: EdgeInsets.all(14.w),
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
                        BoxShadow(
                          color: const Color(0x04000000),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F3447).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.menu_book_rounded, color: const Color(0xFF1F3447), size: 22.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Credit Guidelines & Rules',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0B1B2E),
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
                                      '0% Cut',
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF12805C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'क्रेडिट कैसे काम करता है • रेट कार्ड, सक्सेस फीस व रिफंड',
                                style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: const Color(0xFF1F3447)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Interactive Deal Success Fee Calculator Card
                Container(
                  decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x0D0B1B2E),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: const Color(0x04000000),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isCalculatorExpanded = !_isCalculatorExpanded;
                          });
                        },
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18.r),
                          bottom: _isCalculatorExpanded ? Radius.zero : Radius.circular(18.r),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B1B2E), Color(0xFF0A5C4A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18.r),
                              bottom: _isCalculatorExpanded ? Radius.zero : Radius.circular(18.r),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.calculate_rounded, color: Colors.white, size: 22.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Deal Success Fee Calculator',
                                          style: TextStyle(
                                            fontSize: 13.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF129B6C),
                                            borderRadius: BorderRadius.circular(6.r),
                                          ),
                                          child: Text(
                                            '0.18% - 0.25%',
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      'Instant live fee & net take-home calculation',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _isCalculatorExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isCalculatorExpanded)
                        Padding(
                          padding: EdgeInsets.all(14.w),
                          child: const DealSuccessFeeCalculatorWidget(isStandaloneCard: false),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 22.h),

                // What Credits Are Used For
                Text(
                  'What Credits Are Used For',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
                SizedBox(height: 10.h),

                _useCaseTile(
                  icon: Icons.lock_open_rounded,
                  title: 'Unlock Buyer Lead Contact',
                  desc: 'Get direct phone & WhatsApp for verified buyers',
                  cost: '25 Credits',
                  color: const Color(0xFF0A5C4A),
                ),
                _useCaseTile(
                  icon: Icons.rocket_launch_rounded,
                  title: 'Boost Property Listing (7 Days)',
                  desc: '3x more buyer views in search & recommendations',
                  cost: '50 Credits',
                  color: const Color(0xFF3B7DD8),
                ),
                _useCaseTile(
                  icon: Icons.star_rounded,
                  title: 'Feature Listing on Home Page',
                  desc: 'Top banner placement for high-ticket properties',
                  cost: '100 Credits',
                  color: const Color(0xFFD9961F),
                ),
                _useCaseTile(
                  icon: Icons.task_alt_rounded,
                  title: 'Verified Partner Site Visit Badge',
                  desc: 'Earn DigiNiwas trust badge for seller listings',
                  cost: '35 Credits',
                  color: const Color(0xFF129B6C),
                ),

                SizedBox(height: 22.h),

                // Top Up Packs Quick Buy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Credit Packs',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1B2E),
                      ),
                    ),
                    TextButton(
                      onPressed: () => showTopUpCreditsSheet(context),
                      child: Text(
                        'View All',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0A5C4A)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),

                Row(
                  children: [
                    _packCard(
                      context,
                      credits: '500',
                      price: '₹999',
                      badge: 'Starter',
                      badgeColor: const Color(0xFF5B6B7C),
                    ),
                    SizedBox(width: 8.w),
                    _packCard(
                      context,
                      credits: '1,000',
                      price: '₹1,799',
                      badge: 'Best Value',
                      badgeColor: const Color(0xFF0A5C4A),
                      isPopular: true,
                    ),
                    SizedBox(width: 8.w),
                    _packCard(
                      context,
                      credits: '3,000',
                      price: '₹4,499',
                      badge: 'Pro',
                      badgeColor: const Color(0xFFD9961F),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Transaction History
                Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
                SizedBox(height: 10.h),

                Obx(() {
                  final list = c.creditHistory;
                  if (list.isEmpty) {
                    return _emptyTransactionList();
                  }
                  return Column(
                    children: list.map((item) {
                      final amount = item['credits'] ?? item['amount'] ?? 0;
                      final isPlus = amount.toString().startsWith('+') || (amount is num && amount > 0);
                      final title = item['description'] ?? item['title'] ?? 'Credit Transaction';
                      final date = item['date'] ?? item['createdAt'] ?? 'Recent';

                      return InkWell(
                        onTap: () {
                          Get.bottomSheet(
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2.r),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20.r,
                                        backgroundColor: isPlus ? const Color(0xFFE6F5EE) : const Color(0xFFFEF2F2),
                                        child: Icon(
                                          isPlus ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          size: 18.sp,
                                          color: isPlus ? const Color(0xFF129B6C) : const Color(0xFFD64545),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title.toString(),
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0B1B2E),
                                              ),
                                            ),
                                            Text(
                                              date.toString(),
                                              style: TextStyle(fontSize: 12.sp, color: PartnerColors.textTertiary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Credits Impact', style: TextStyle(fontSize: 13.sp, color: PartnerColors.textSecondary)),
                                        Text(
                                          '${isPlus ? '+' : ''}$amount Credits',
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isPlus ? const Color(0xFF129B6C) : const Color(0xFFD64545),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Get.back(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0A5C4A),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                      child: const Text('Close', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x080B1B2E),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18.r,
                                backgroundColor: isPlus ? const Color(0xFFE6F5EE) : const Color(0xFFFEF2F2),
                                child: Icon(
                                  isPlus ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  size: 16.sp,
                                  color: isPlus ? const Color(0xFF129B6C) : const Color(0xFFD64545),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.toString(),
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0B1B2E),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      date.toString(),
                                      style: TextStyle(fontSize: 11.sp, color: PartnerColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isPlus ? '+' : ''}$amount Credits',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isPlus ? const Color(0xFF129B6C) : const Color(0xFFD64545),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyTransactionList() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x060B1B2E),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 36.sp, color: PartnerColors.textTertiary),
          SizedBox(height: 8.h),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B1B2E),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your credit purchases and lead unlock history will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _useCaseTile({
    required IconData icon,
    required String title,
    required String desc,
    required String cost,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x060B1B2E),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B1B2E),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3EF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              cost,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A5C4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packCard(
    BuildContext context, {
    required String credits,
    required String price,
    required String badge,
    required Color badgeColor,
    bool isPopular = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => showTopUpCreditsSheet(context),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isPopular ? const Color(0xFFEEF8F2) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: isPopular ? const Color(0x180A5C4A) : const Color(0x080B1B2E),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                credits,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              Text(
                'Credits',
                style: TextStyle(fontSize: 10.sp, color: PartnerColors.textSecondary),
              ),
              SizedBox(height: 4.h),
              Text(
                price,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A5C4A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDealSuccessFeeCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deal Success Fee Calculator',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1B2E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                      color: PartnerColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  child: const DealSuccessFeeCalculatorWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
