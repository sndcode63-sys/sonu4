import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_dotted_border.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../controllers/partner_home_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/account_service.dart';
import '../../../core/widgets/delete_account_dialog.dart';
import 'credit_wallet_screen.dart';
import 'partner_bottom_sheets.dart';

import 'widgets/partner_ui.dart';
class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final c = ensurePartnerHomeController();

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // // Top Bar
            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            //   color: Colors.white,
            //   child: Row(
            //     children: [
            //       Text(
            //         'Partner Profile',
            //         style: TextStyle(
            //           fontSize: 18.sp,
            //           fontWeight: FontWeight.bold,
            //           color: const Color(0xFF0B1B2E),
            //         ),
            //       ),
            //       // IconButton(
            //       //   icon: const Icon(Icons.share_outlined, color: Color(0xFF0B1B2E)),
            //       //   onPressed: () {
            //       //     final pName = c.partnerName.value.isNotEmpty ? c.partnerName.value : 'Partner';
            //       //     final pId = c.partnerId.value;
            //       //     final phone = c.partnerPhone.value;
            //       //     final email = c.partnerEmail.value;
            //       //     final sb = StringBuffer('Verified DigiNiwas Partner Profile\n');
            //       //     sb.writeln('Name: $pName');
            //       //     if (pId.isNotEmpty) sb.writeln('Partner ID: $pId');
            //       //     if (phone.isNotEmpty) sb.writeln('Phone: $phone');
            //       //     if (email.isNotEmpty) sb.writeln('Email: $email');
            //       //     sb.writeln('Direct partner connection via DigiNiwas Real Estate.');
            //       //     SharePlus.instance.share(ShareParams(text: sb.toString(), subject: '$pName - DigiNiwas Partner'));
            //       //   },
            //       // ),
            //     ],
            //   ),
            // ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    c.loadPartnerProfile(),
                    c.loadCredits(),
                    c.loadLeads(),
                    c.loadProperties(),
                    c.loadTasks(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 80.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      Obx(() {
                        final profile = c.partnerProfile.value;
                        final name = c.partnerName.value.isNotEmpty
                            ? c.partnerName.value
                            : (profile?.name.isNotEmpty == true ? profile!.name : 'Partner');
                        final rawId = c.partnerId.value.isNotEmpty
                            ? c.partnerId.value
                            : (profile?.partnerCode.isNotEmpty == true ? profile!.partnerCode : '');
                        final id = rawId.isNotEmpty
                            ? (rawId.length > 8
                                ? 'DN-AG-${rawId.substring(rawId.length - 6).toUpperCase()}'
                                : rawId)
                            : 'DN-AG';
                        final location = (profile?.city.isNotEmpty == true)
                            ? profile!.city
                            : (profile?.operatingAreas.isNotEmpty == true
                                ? profile!.operatingAreas
                                : 'Partner Territory');
                        final isVerified = c.isVerifiedPartner.value;

                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: PartnerColors.line),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: PartnerShadows.card,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showChangeProfilePicSheet(context, c),
                                    child: Stack(
                                      children: [
                                        Builder(builder: (_) {
                                          final pic = c.partnerProfilePic.value;
                                          ImageProvider? img;
                                          if (pic.isNotEmpty) {
                                            if (pic.startsWith('http')) {
                                              img = NetworkImage(pic);
                                            } else {
                                              final f = File(pic);
                                              if (f.existsSync()) {
                                                img = FileImage(f);
                                              }
                                            }
                                          }
                                          return CircleAvatar(
                                            radius: 32.r,
                                            backgroundColor: PartnerColors.brandTint,
                                            backgroundImage: img,
                                            child: img == null
                                                ? Text(
                                                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                                    style: TextStyle(
                                                      fontSize: 24.sp,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF0A5C4A),
                                                    ),
                                                  )
                                                : null,
                                          );
                                        }),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(5.w),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0A5C4A),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: Icon(Icons.camera_alt, color: Colors.white, size: 11.sp),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: PartnerText.title(16.5),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 6.w),
                                            PartnerStatusChip(
                                              label: isVerified ? 'Verified Partner' : 'Registered Partner',
                                              tone: isVerified ? PartnerTone.success : PartnerTone.neutral,
                                              icon: isVerified ? Icons.verified_rounded : Icons.pending_outlined,
                                              dense: true,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          'ID: $id • $location',
                                          style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 6.h),
                                        Row(
                                          children: [
                                            Container(
                                              width: 7.w,
                                              height: 7.w,
                                              decoration: BoxDecoration(
                                                color: isVerified ? const Color(0xFF129B6C) : const Color(0xFFD9961F),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              isVerified ? 'Active • Available for Visits' : 'Application Active',
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                                color: isVerified ? const Color(0xFF129B6C) : const Color(0xFFB7791F),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                     


                      SizedBox(height: 12.h),

                      // Credit Wallet Shortcut Card
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreditWalletScreen()),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: PartnerColors.line),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: PartnerShadows.card,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: PartnerColors.goldSoft,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.account_balance_wallet_rounded,
                                    color: PartnerColors.gold, size: 22.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Credit Wallet',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B1B2E),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Obx(() => Text(
                                          '${c.creditBalance.value} Credits Available',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF0A5C4A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => showTopUpCreditsSheet(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A5C4A),
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '+ Top Up',
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Digital Business Card Shortcut Card
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.partnerDigitalCard),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A0B1B2E),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3EF),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.badge_outlined,
                                    color: const Color(0xFF0A5C4A), size: 22.sp),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'My Digital Business Card',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B1B2E),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Customize & share your verified profile',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFF5B6B7C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A5C4A),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.share_rounded, size: 12.sp, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Share',
                                      style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Profile & Property Boosting Shortcut Card
                      GestureDetector(
                        onTap: () => Get.toNamed(
                          AppRoutes.boostProperty,
                          arguments: {'initialTabIndex': 1},
                        ),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD6E4FF)),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A0B1B2E),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF5FF),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.rocket_launch_rounded,
                                    color: const Color(0xFF2563EB), size: 22.sp),
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
                                            'Boost Profile & Listings',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0B1B2E),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6.r),
                                          ),
                                          child: Text(
                                            'HOT',
                                            style: TextStyle(
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Get 5x more views and priority client inquiries',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFF5B6B7C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, size: 12.sp, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Boost',
                                      style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      // Partner Activity (4 Counters)
                      Text(
                        'Partner Activity',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1B2E),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Obx(() {
                        final dash = c.leadsDashboard.value;
                        final totalLeads = dash?.totalLeads ?? c.leads.length;
                        final totalProps = c.properties.length;
                        final totalVisits = c.visits.length;


                        return Row(
                          children: [
                            _activityCounter(
                              'Leads Handled',
                              '$totalLeads',
                              const Color(0xFF0A5C4A),
                              onTap: () => c.goToTab(1),
                            ),
                            SizedBox(width: 8.w),
                            _activityCounter(
                              'Properties',
                              '$totalProps',
                              const Color(0xFF3B7DD8),
                              onTap: () => c.goToTab(2),
                            ),
                            SizedBox(width: 8.w),
                            _activityCounter(
                              'Site Visits',
                              '$totalVisits',
                              const Color(0xFFD9961F),
                              onTap: () => c.goToTab(3),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        );
                      }),

                      SizedBox(height: 18.h),

                      // Verified Reputation (3 columns)
                      Obx(() {
                        final profile = c.partnerProfile.value;
                        final dash = c.leadsDashboard.value;
                        final responseTime = (profile?.responseTime.isNotEmpty == true)
                            ? profile!.responseTime
                            : '< 15 mins';
                        final verificationRate = c.isVerifiedPartner.value ? '100%' : 'In Progress';
                        final closedDeals = dash?.converted ?? (profile?.dealsClosed ?? 0);

                        return Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A0B1B2E),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Reputation',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B1B2E),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _reputationCol(responseTime, 'Response Time', Icons.timer_outlined),
                                  Container(width: 1, height: 36.h, color: const Color(0xFFE3E8ED)),
                                  _reputationCol(verificationRate, 'Verification', Icons.verified_outlined),
                                  Container(width: 1, height: 36.h, color: const Color(0xFFE3E8ED)),
                                  _reputationCol('$closedDeals Deals', 'Deals Closed', Icons.handshake_outlined),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: 18.h),

                      // Professional Details Card
                      Obx(() {
                        final profile = c.partnerProfile.value;
                        final opAreas = (profile?.operatingAreas.isNotEmpty == true)
                            ? profile!.operatingAreas
                            : (profile?.city.isNotEmpty == true ? profile!.city : 'Assigned Territory');
                        final spec = (profile?.specialization.isNotEmpty == true)
                            ? profile!.specialization
                            : 'Residential & Commercial Deals';
                        final rera = (profile?.reraNumber.isNotEmpty == true)
                            ? profile!.reraNumber
                            : (c.isVerifiedPartner.value ? 'Verified Under Channel Partner' : 'Pending Verification');
                        final exp = (profile?.experience.isNotEmpty == true)
                            ? profile!.experience
                            : 'Registered Channel Partner';

                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A0B1B2E),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Professional Details',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B1B2E),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _detailRow('Operating Areas', opAreas),
                              _detailRow('Specialization', spec),
                              _detailRow('RERA Reg. Number', rera),
                              _detailRow('Experience', exp),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: 18.h),
                      //
                      // // Verification & Account Checklist
                      // Obx(() {
                      //   final profile = c.partnerProfile.value;
                      //   final kycDone = profile?.isKycVerified ?? c.isVerifiedPartner.value;
                      //   final bankDone = profile?.isBankVerified ?? false;
                      //   final phoneDone = c.partnerPhone.value.isNotEmpty;
                      //   final reraDone = profile?.isReraVerified ?? false;
                      //
                      //   return Container(
                      //     padding: EdgeInsets.all(16.w),
                      //     decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(16.r),
                      //       border: Border.all(color: const Color(0xFF0A5C4A).withValues(alpha: 0.35), width: 1.2),
                      //     ),
                      //     child: Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //           'Verification & Trust Checklist',
                      //           style: TextStyle(
                      //             fontSize: 14.sp,
                      //             fontWeight: FontWeight.bold,
                      //             color: const Color(0xFF0B1B2E),
                      //           ),
                      //         ),
                      //         SizedBox(height: 10.h),
                      //         _trustCheck('KYC & Aadhaar / PAN Verification', kycDone),
                      //         _trustCheck('Bank Account for Direct Payouts', bankDone),
                      //         _trustCheck('WhatsApp Business Connected', phoneDone),
                      //         _trustCheck('RERA Agent Certification', reraDone),
                      //       ],
                      //     ),
                      //   );
                      // }),
                      //
                      // SizedBox(height: 18.h),

                      // Account Actions Grouped Card with Dividers (Image 1 style)
                      Obx(() => Column(
                            children: [
                              _buildGroupedMenuCard([
                                if (c.isTeamOwner.value)
                                  _PartnerMenuItem(
                                    title: 'Team Management',
                                    icon: Icons.groups_outlined,
                                    onTap: () => Get.toNamed(AppRoutes.partnerTeam),
                                  ),
                                _PartnerMenuItem(
                                  title: 'Partner Helpdesk & Support',
                                  icon: Icons.headset_mic_outlined,
                                  onTap: () {
                                    AppToast.showInfo('Support: support@diginiwas.com | Mon-Sat 9 AM - 7 PM');
                                  },
                                ),
                                _PartnerMenuItem(
                                  title: 'Deal Success Fee & Credit Guidelines',
                                  icon: Icons.calculate_outlined,
                                  onTap: () => Get.toNamed(AppRoutes.creditGuidelines),
                                ),
                                _PartnerMenuItem(
                                  title: 'Partner Policy & Fee Structure',
                                  icon: Icons.policy_outlined,
                                  onTap: () => Get.toNamed(AppRoutes.creditGuidelines),
                                ),
                              ]),
                              SizedBox(height: 16.h),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => showLogoutConfirmationDialog(
                                    context,
                                    onConfirm: () => c.logout(),
                                  ),
                                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFD64545)),
                                  label: Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD64545),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmDeleteAccount(context, c),
                                  icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFC73A3A)),
                                  label: Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFC73A3A),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFECACA)),
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, PartnerHomeController c) async {
    final deleted = await DeleteAccountDialog.show(
      context,
      roleName: 'Partner / Agent',
      onConfirmDelete: (reason) async {
        await AccountService.instance.deleteAccount(reason: reason);
        await AccountService.instance.clearAllSessionData();
      },
    );

    if (deleted == true) {
      if (Get.isRegistered<PartnerHomeController>()) {
        Get.delete<PartnerHomeController>(force: true);
      }
      Get.offAllNamed(AppRoutes.chooseRole);
      Future.delayed(const Duration(milliseconds: 300), () {
        AppToast.showSuccess('Account deleted successfully.');
      });
    }
  }

  Widget _activityCounter(String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A0B1B2E),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                style: TextStyle(fontSize: 9.5.sp, color: PartnerColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reputationCol(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18.sp, color: const Color(0xFF0A5C4A)),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0B1B2E),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: PartnerColors.textSecondary),
        ),
      ],
    );
  }

  Widget _detailRow(String title, String val) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0B1B2E), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedMenuCard(List<_PartnerMenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: PartnerShadows.card,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? Radius.circular(22.r) : Radius.zero,
                    bottom: isLast ? Radius.circular(22.r) : Radius.zero,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3EF),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(item.icon, color: const Color(0xFF0A5C4A), size: 18.sp),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B1B2E),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 13.sp, color: PartnerColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFF1F3F5),
                  indent: 54.w,
                  endIndent: 16.w,
                ),
            ],
          );
        }),
      ),
    );
  }

  void _showChangeProfilePicSheet(BuildContext context, PartnerHomeController c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Upload a professional headshot for your verified agent badge',
                style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          final picker = ImagePicker();
                          final photo = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (photo != null) {
                            await c.updateProfilePicture(photo.path);
                            AppToast.showSuccess('Profile photo updated successfully.');
                          }
                        } catch (e) {
                          AppToast.showError('Could not access camera: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: AppDottedBorder(
                        radius: 16.r,
                        color: const Color(0xFF0A5C4A),
                        backgroundColor: const Color(0xFFF8FAF9),
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3EF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.camera_alt_rounded, color: Color(0xFF0A5C4A), size: 24.sp),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Take Photo',
                              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                            ),
                            Text('Camera', style: TextStyle(fontSize: 10.5.sp, color: PartnerColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          final picker = ImagePicker();
                          final photo = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (photo != null) {
                            await c.updateProfilePicture(photo.path);
                            AppToast.showSuccess('Profile photo updated successfully.');
                          }
                        } catch (e) {
                          AppToast.showError('Could not access gallery: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: AppDottedBorder(
                        radius: 16.r,
                        color: const Color(0xFF3B7DD8),
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE9F0FB),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.photo_library_rounded, color: Color(0xFF3B7DD8), size: 24.sp),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Choose Gallery',
                              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                            ),
                            Text('PNG, JPG', style: TextStyle(fontSize: 10.5.sp, color: PartnerColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Obx(() {
                if (c.partnerProfilePic.value.isEmpty) return const SizedBox.shrink();
                return ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: const Color(0xFFD64545), size: 20.sp),
                  ),
                  title: Text('Remove Photo', style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFFD64545))),
                  subtitle: Text('Revert back to default avatar initials', style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await c.removeProfilePicture();
                    AppToast.showInfo('Profile photo reverted to default avatar.');
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PartnerMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
