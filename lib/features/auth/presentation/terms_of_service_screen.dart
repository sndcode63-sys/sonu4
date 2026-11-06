import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/app_adaptive_back_button.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DigiNiwas Terms of Service',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Please read these Terms of Service ("Terms") carefully before using the DigiNiwas application. By accessing or using our platform, you agree to be bound by these Terms and our Privacy Policy. If you disagree with any part of the terms, you may not use the platform.',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: const Color(0xFF334155),
                  height: 1.6,
                ),
              ),
              SizedBox(height: 20.h),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              SizedBox(height: 20.h),

              _buildSection(
                number: '1',
                title: 'Platform Scope & Services',
                content:
                'DigiNiwas is a real estate marketplace platform that connects property buyers, sellers, and verified local partners. DigiNiwas facilitates discovery, scheduling visits, inquiry routing, and locality insights. We do not own, sell, or manage properties directly unless explicitly indicated.',
              ),

              _buildSection(
                number: '2',
                title: 'User Accounts & Verification',
                content:
                '• Eligibility: You must be at least 18 years old to create an account.\n'
                    '• Accuracy: You agree to provide accurate, current, and complete details when signing up or scheduling visits.\n'
                    '• Account Security: You are responsible for safeguarding your login credentials and for all activities that occur under your account.',
              ),

              _buildSection(
                number: '3',
                title: 'Property Listings & Information',
                content:
                '• Listing Details: While we work closely with verified partners to ensure listing accuracy, property specifications, prices, photos, and availability are subject to verification and may change.\n'
                    '• Independent Due Diligence: Buyers and tenants are strongly encouraged to physically inspect properties and verify title deeds, approvals, and legal documents prior to executing any financial transactions.',
              ),

              _buildSection(
                number: '4',
                title: 'Inquiries & Scheduled Visits',
                content:
                '• Honest Requests: Inquiries, callback requests, and site visit bookings must be made in good faith with genuine interest.\n'
                    '• Partner Conduct: Verified partners are independent professionals committed to providing timely assistance. Any harassment, unsolicited spam, or abusive behavior will result in immediate account suspension.',
              ),

              _buildSection(
                number: '5',
                title: 'Intellectual Property',
                content:
                'All content, trademarks, UI designs, brand logos, AI algorithms, and software features in the DigiNiwas application are the exclusive property of DigiNiwas Technologies. You may not copy, modify, distribute, or reverse-engineer any portion of the platform without prior written consent.',
              ),

              _buildSection(
                number: '6',
                title: 'Limitation of Liability',
                content:
                'To the maximum extent permitted by applicable law, DigiNiwas and its affiliates shall not be liable for any indirect, incidental, special, or consequential damages resulting from your use of or inability to use the platform, including transactions made between buyers, sellers, and third-party partners.',
              ),

              _buildSection(
                number: '7',
                title: 'Modifications & Termination',
                content:
                'We reserve the right to modify these Terms at any time. Material changes will be updated with a revised date. Continued use of DigiNiwas following any modification constitutes your acceptance of the updated Terms.',
              ),

              _buildSection(
                number: '8',
                title: 'Contact Information',
                content:
                'For questions or legal notices regarding these Terms of Service, please contact us at legal@diginiwas.com or write to our support team.',
              ),

              SizedBox(height: 24.h),
              Center(
                child: Text(
                  '© 2024 DigiNiwas Technologies. All rights reserved.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12.5.sp,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}