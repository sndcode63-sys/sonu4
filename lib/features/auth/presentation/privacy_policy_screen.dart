import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/app_adaptive_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                'DigiNiwas Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Welcome to DigiNiwas. We are committed to protecting your personal information and your right to privacy. This Privacy Policy describes how we collect, use, store, and protect your information when you use our mobile application and related property services.',
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
                title: 'Information We Collect',
                content:
                'When you register, browse listings, connect with partners, or schedule property visits on DigiNiwas, we may collect the following information:\n\n'
                    '• Personal Details: Name, phone number, email address, and profile photo provided during account setup.\n'
                    '• Property & Search Activity: Search queries, saved properties, recently viewed listings, and property comparison history.\n'
                    '• Communications: Details of inquiries, callback requests, and visit scheduling requests submitted through the app.\n'
                    '• Device & Location Data: Approximate location (city/locality) to show relevant nearby real estate listings and basic device diagnostic metrics.',
              ),

              _buildSection(
                number: '2',
                title: 'How We Use Your Information',
                content:
                'We use the information we collect to:\n\n'
                    '• Connect you with verified DigiNiwas partners and property owners for inquiries and site visits.\n'
                    '• Facilitate property search, filtering, price trends, and locality recommendations.\n'
                    '• Send you real-time notifications regarding visit status, inquiry callbacks, and relevant new property listings.\n'
                    '• Improve platform security, detect fraud, and maintain compliance with applicable digital regulations.',
              ),

              _buildSection(
                number: '3',
                title: 'Information Sharing & Disclosure',
                content:
                'We do not sell your personal data. We only share information in the following limited situations:\n\n'
                    '• Verified Partners & Agents: When you tap "Connect with Partner", "Schedule Visit", or submit an inquiry, your contact details are shared only with the designated verified partner handling that property.\n'
                    '• Service Providers: Trusted infrastructure and notification providers who assist in operating our secure platform.\n'
                    '• Legal Requirements: If required by applicable law, regulation, or legal proceedings.',
              ),

              _buildSection(
                number: '4',
                title: 'Data Security & Retention',
                content:
                'We implement industry-standard encryption, secure storage, and strict access controls to safeguard your data against unauthorized access, alteration, or disclosure. We retain your personal details only as long as necessary to fulfill the purposes outlined in this policy or until you request account deletion.',
              ),

              _buildSection(
                number: '5',
                title: 'Your Privacy Rights',
                content:
                'You have full control over your information:\n\n'
                    '• Access & Update: You can review and update your profile details directly from the Profile screen.\n'
                    '• Delete Account: You may delete your account and associated session data at any time via the "Delete Account" option in your Profile.\n'
                    '• Opt-Out: You can manage notification preferences and revoke location permissions via your device settings.',
              ),

              _buildSection(
                number: '6',
                title: 'Contact Us',
                content:
                'If you have any questions or feedback regarding this Privacy Policy or how your data is handled, please contact our support team at support@diginiwas.com or reach out via our official partner support channel.',
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