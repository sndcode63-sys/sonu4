import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../controllers/partner_home_controller.dart';

// ================================================================
// PARTNER CARD DATA MODEL WITH COPYWITH
// ================================================================
class PartnerCardData {
  final String name;
  final String firmName;
  final String profilePic;
  final String city;
  final String specialization;
  final bool isVerified;
  final String phone;
  final String whatsapp;
  final String email;
  final String partnerCode;
  final String profileUrl;

  const PartnerCardData({
    required this.name,
    required this.firmName,
    required this.profilePic,
    required this.city,
    required this.specialization,
    required this.isVerified,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.partnerCode,
    required this.profileUrl,
  });

  PartnerCardData copyWith({
    String? name,
    String? firmName,
    String? profilePic,
    String? city,
    String? specialization,
    bool? isVerified,
    String? phone,
    String? whatsapp,
    String? email,
    String? partnerCode,
    String? profileUrl,
  }) {
    return PartnerCardData(
      name: name ?? this.name,
      firmName: firmName ?? this.firmName,
      profilePic: profilePic ?? this.profilePic,
      city: city ?? this.city,
      specialization: specialization ?? this.specialization,
      isVerified: isVerified ?? this.isVerified,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      partnerCode: partnerCode ?? this.partnerCode,
      profileUrl: profileUrl ?? this.profileUrl,
    );
  }

  factory PartnerCardData.fromController(PartnerHomeController c) {
    final p = c.partnerProfile.value;
    final name = c.partnerName.value.trim().isNotEmpty && c.partnerName.value != 'Partner'
        ? c.partnerName.value.trim()
        : (p?.name.isNotEmpty == true ? p!.name : 'Rahul Sharma');

    final firm = p?.operatingAreas.isNotEmpty == true && p!.operatingAreas != p.city
        ? '${name.split(' ').first} Properties'
        : 'Sharma Properties';

    final city = p?.city.isNotEmpty == true
        ? p!.city
        : (p?.operatingAreas.isNotEmpty == true ? p!.operatingAreas : 'Noida, NCR');

    final spec = p?.specialization.isNotEmpty == true
        ? p!.specialization
        : 'Residential & Commercial';

    final partnerCode = c.partnerId.value.isNotEmpty
        ? c.partnerId.value
        : (p?.partnerCode.isNotEmpty == true ? p!.partnerCode : 'DNP-8821');

    final phone = c.partnerPhone.value.isNotEmpty
        ? c.partnerPhone.value
        : (p?.phone.isNotEmpty == true ? p!.phone : '+91 98765 43210');

    final rawWhatsapp = p?.raw['whatsapp']?.toString() ??
        p?.raw['whatsappNumber']?.toString() ??
        p?.raw['whatsApp']?.toString() ??
        '';
    final whatsapp = rawWhatsapp.isNotEmpty ? rawWhatsapp : phone;

    return PartnerCardData(
      name: name,
      firmName: firm,
      profilePic: c.partnerProfilePic.value,
      city: city,
      specialization: spec,
      isVerified: true,
      phone: phone,
      whatsapp: whatsapp,
      email: c.partnerEmail.value,
      partnerCode: partnerCode,
      profileUrl: 'https://diginiwas.com/partner/$partnerCode',
    );
  }
}

// ================================================================
// REUSABLE QR WIDGET
// ================================================================
class PartnerQrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const PartnerQrCodeWidget({
    super.key,
    required this.data,
    this.size = 60,
    this.foregroundColor = const Color(0xFF10222B),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&margin=0&data=${Uri.encodeComponent(data)}';
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: CachedNetworkImage(
          imageUrl: qrUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => Center(
            child: SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF005B48)),
            ),
          ),
          errorWidget: (_, __, ___) => _QrPlaceholderPainterWidget(size: size - 8, color: foregroundColor),
        ),
      ),
    );
  }
}

class _QrPlaceholderPainterWidget extends StatelessWidget {
  final double size;
  final Color color;
  const _QrPlaceholderPainterWidget({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QrMatrixPainter(color: color),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final Color color;
  _QrMatrixPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final s = size.width / 7;
    canvas.drawRect(Rect.fromLTWH(0, 0, s * 2.5, s * 2.5), paint);
    canvas.drawRect(Rect.fromLTWH(s * 0.5, s * 1.5, s * 1.5, s * 1.5), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(s * 0.8, s * 0.8, s * 0.9, s * 0.9), paint);

    canvas.drawRect(Rect.fromLTWH(size.width - s * 2.5, 0, s * 2.5, s * 2.5), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - s * 2.0, s * 0.5, s * 1.5, s * 1.5), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - s * 1.7, s * 0.8, s * 0.9, s * 0.9), paint);

    canvas.drawRect(Rect.fromLTWH(0, size.height - s * 2.5, s * 2.5, s * 2.5), paint);
    canvas.drawRect(Rect.fromLTWH(s * 0.5, size.height - s * 2.0, s * 1.5, s * 1.5), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(s * 0.8, size.height - s * 1.7, s * 0.9, s * 0.9), paint);

    canvas.drawRect(Rect.fromLTWH(s * 3.2, s * 0.5, s * 0.7, s * 0.7), paint);
    canvas.drawRect(Rect.fromLTWH(s * 3.2, s * 2.5, s * 0.7, s * 0.7), paint);
    canvas.drawRect(Rect.fromLTWH(s * 1.0, s * 3.2, s * 0.7, s * 0.7), paint);
    canvas.drawRect(Rect.fromLTWH(s * 3.0, s * 4.0, s * 0.7, s * 0.7), paint);
    canvas.drawRect(Rect.fromLTWH(s * 5.0, s * 3.5, s * 0.7, s * 0.7), paint);
    canvas.drawRect(Rect.fromLTWH(s * 4.5, s * 5.0, s * 0.7, s * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================================================================
// DESIGN 0: CLASSIC EMERALD (Vertical)
// ================================================================
class DigitalCardVertical extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardVertical({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310.w,
      height: 468.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005B48).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 70.h,
              width: 145.w,
              height: 200.h,
              child: ClipPath(
                clipper: _LeftCurveClipper(),
                child: Image.asset(
                  'assets/images/partner/card_building_vertical.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_promote.png', fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              left: 18.w,
              top: 18.h,
              right: 18.w,
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, color: Color(0xFF005B48)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DigiNiwas',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10222B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "India's Smart Property Platform",
                        style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E7076)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18.w,
              top: 72.h,
              right: 120.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF005B48), width: 2),
                        ),
                        child: ClipOval(
                          child: data.profilePic.isNotEmpty
                              ? (data.profilePic.startsWith('http')
                                  ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                  : Image.file(File(data.profilePic), fit: BoxFit.cover))
                              : _buildAvatarFallback(),
                        ),
                      ),
                      Positioned(
                        right: -2.w,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: const Color(0xFF10222B), height: 1.15),
                  ),
                  Text(
                    data.firmName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF5E7076)),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFF99F6E4), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 11.sp, color: const Color(0xFF005B48)),
                        SizedBox(width: 4.w),
                        Text('Verified Partner', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: const Color(0xFF005B48))),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildTag(Icons.location_on_rounded, data.city),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.call_rounded, data.phone),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', iconColor: const Color(0xFF10B981)),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.apartment_rounded, data.specialization),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.shield_rounded, 'Trusted & Verified'),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 145.h,
              child: ClipPath(
                clipper: _TopWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF032B21), Color(0xFF064E3B), Color(0xFF0B5444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(18.w, 32.h, 18.w, 12.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A3C32),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: Text('View Properties >', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PartnerQrCodeWidget(data: data.profileUrl, size: 52.w),
                              SizedBox(height: 3.h),
                              Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5.sp, color: Colors.white70, height: 1.1)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 11.sp, color: const Color(0xFF99F6E4)),
                          SizedBox(width: 4.w),
                          Text('Search, Explore, Decide with Niwas AI.', style: TextStyle(fontSize: 8.5.sp, color: Colors.white60)),
                        ],
                      ),
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

  Widget _buildAvatarFallback() {
    final initials = data.name.trim().isNotEmpty ? data.name[0].toUpperCase() : 'P';
    return Container(
      color: const Color(0xFFE8F7F2),
      child: Center(child: Text(initials, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFF005B48)))),
    );
  }

  Widget _buildTag(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 11.sp, color: iconColor ?? const Color(0xFF005B48)),
        SizedBox(width: 5.w),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, color: const Color(0xFF334155)))),
      ],
    );
  }
}

// ================================================================
// DESIGN 1: ROYAL DARK LUXURY (Horizontal)
// ================================================================
class DigitalCardHorizontalPremium extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardHorizontalPremium({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330.w,
      height: 216.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF022018), Color(0xFF053E30), Color(0xFF0B5444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF064E3B).withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/partner/card_villa_premium.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_top_partner.png', fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF053E30), const Color(0xFF053E30).withValues(alpha: 0.4), Colors.transparent],
                        stops: const [0.0, 0.35, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              right: 85.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/app_logo.png', width: 18.w, height: 18.w, errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, color: Colors.white, size: 16)),
                        SizedBox(width: 5.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DigiNiwas', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2)),
                            Text("India's Smart Property Platform", style: TextStyle(fontSize: 7.sp, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF99F6E4), width: 1.5)),
                              child: ClipOval(
                                child: data.profilePic.isNotEmpty
                                    ? (data.profilePic.startsWith('http')
                                        ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                        : Image.file(File(data.profilePic), fit: BoxFit.cover))
                                    : Container(color: Colors.white24, child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)))),
                              ),
                            ),
                            Positioned(right: -1, bottom: -1, child: Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 13.sp)),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: const Color(0xFF99F6E4))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDarkTag(Icons.location_on_rounded, data.city),
                        SizedBox(height: 2.h),
                        _buildDarkTag(Icons.call_rounded, data.phone),
                        SizedBox(height: 2.h),
                        _buildDarkTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', iconColor: const Color(0xFF25D366)),
                        SizedBox(height: 2.h),
                        _buildDarkTag(Icons.apartment_rounded, data.specialization),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFF032B21), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: Colors.white30, width: 0.8)),
                      child: Text('View Properties >', style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PartnerQrCodeWidget(data: data.profileUrl, size: 50.w),
                  SizedBox(height: 3.h),
                  Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.sp, color: Colors.white70, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkTag(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 9.sp, color: iconColor ?? const Color(0xFF99F6E4)),
        SizedBox(width: 4.w),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.sp, color: Colors.white70)),
      ],
    );
  }
}

// ================================================================
// DESIGN 2: MODERN CORPORATE MINIMAL (Horizontal)
// ================================================================
class DigitalCardHorizontalMinimal extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardHorizontalMinimal({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330.w,
      height: 216.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: const Color(0xFF005B48).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 130.w,
              child: ClipPath(
                clipper: _LeftCurveClipper(),
                child: Image.asset('assets/images/partner/card_building_minimal.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_promote.png', fit: BoxFit.cover)),
              ),
            ),
            Positioned.fill(
              right: 90.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/images/app_logo.png', width: 18.w, height: 18.w, errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, color: Color(0xFF005B48), size: 16)),
                        SizedBox(width: 5.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DigiNiwas', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: const Color(0xFF10222B), letterSpacing: -0.2)),
                            Text("India's Smart Property Platform", style: TextStyle(fontSize: 7.sp, color: const Color(0xFF5E7076))),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF005B48), width: 1.5)),
                              child: ClipOval(
                                child: data.profilePic.isNotEmpty
                                    ? (data.profilePic.startsWith('http')
                                        ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                        : Image.file(File(data.profilePic), fit: BoxFit.cover))
                                    : Container(color: const Color(0xFFE8F7F2), child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(color: const Color(0xFF005B48), fontSize: 14.sp, fontWeight: FontWeight.bold)))),
                              ),
                            ),
                            Positioned(right: -1, bottom: -1, child: Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 13.sp)),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: const Color(0xFF10222B))),
                              Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: const Color(0xFF5E7076))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLightTag(Icons.location_on_rounded, data.city),
                        SizedBox(height: 2.h),
                        _buildLightTag(Icons.call_rounded, data.phone),
                        SizedBox(height: 2.h),
                        _buildLightTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', iconColor: const Color(0xFF10B981)),
                        SizedBox(height: 2.h),
                        _buildLightTag(Icons.apartment_rounded, data.specialization),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFF005B48), borderRadius: BorderRadius.circular(16.r)),
                      child: Text('View Properties >', style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PartnerQrCodeWidget(data: data.profileUrl, size: 50.w),
                  SizedBox(height: 3.h),
                  Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.sp, color: const Color(0xFF5E7076), height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightTag(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 9.sp, color: iconColor ?? const Color(0xFF005B48)),
        SizedBox(width: 4.w),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.sp, color: const Color(0xFF334155))),
      ],
    );
  }
}

// ================================================================
// DESIGN 3: MIDNIGHT GOLD EXECUTIVE (Horizontal)
// ================================================================
class DigitalCardMidnightGold extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardMidnightGold({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF59E0B);
    const deepGold = Color(0xFFD97706);

    return Container(
      width: 330.w,
      height: 216.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF090D16), Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: gold.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(color: gold.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 135.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/partner/card_villa_premium.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_top_partner.png', fit: BoxFit.cover)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF111827), const Color(0xFF111827).withValues(alpha: 0.5), Colors.transparent],
                        stops: const [0.0, 0.4, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              right: 85.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: gold, size: 20.sp),
                        SizedBox(width: 5.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DigiNiwas Executive', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900, color: gold, letterSpacing: 0.2)),
                            Text("Exclusive Partner Network", style: TextStyle(fontSize: 7.sp, color: Colors.white60)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 1.5)),
                              child: ClipOval(
                                child: data.profilePic.isNotEmpty
                                    ? (data.profilePic.startsWith('http')
                                        ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                        : Image.file(File(data.profilePic), fit: BoxFit.cover))
                                    : Container(color: Colors.white12, child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(color: gold, fontSize: 14.sp, fontWeight: FontWeight.bold)))),
                              ),
                            ),
                            Positioned(right: -1, bottom: -1, child: Icon(Icons.star_rounded, color: gold, size: 14.sp)),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: gold.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGoldTag(Icons.location_on_rounded, data.city, gold),
                        SizedBox(height: 2.h),
                        _buildGoldTag(Icons.call_rounded, data.phone, gold),
                        SizedBox(height: 2.h),
                        _buildGoldTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', const Color(0xFF25D366)),
                        SizedBox(height: 2.h),
                        _buildGoldTag(Icons.apartment_rounded, data.specialization, gold),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [deepGold, gold]),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text('View Properties >', style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: const Color(0xFF090D16))),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PartnerQrCodeWidget(data: data.profileUrl, size: 50.w, foregroundColor: const Color(0xFF090D16)),
                  SizedBox(height: 3.h),
                  Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.sp, color: Colors.white70, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 9.sp, color: color),
        SizedBox(width: 4.w),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.sp, color: Colors.white70)),
      ],
    );
  }
}

// ================================================================
// DESIGN 4: SAPPHIRE BLUE ELITE (Vertical)
// ================================================================
class DigitalCardSapphireBlue extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardSapphireBlue({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const sapphire = Color(0xFF1E3A8A);
    const electric = Color(0xFF38BDF8);

    return Container(
      width: 310.w,
      height: 468.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(color: sapphire.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 70.h,
              width: 145.w,
              height: 200.h,
              child: ClipPath(
                clipper: _LeftCurveClipper(),
                child: Image.asset('assets/images/partner/card_building_vertical.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_promote.png', fit: BoxFit.cover)),
              ),
            ),
            Positioned(
              left: 18.w,
              top: 18.h,
              right: 18.w,
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8.r)),
                    child: Image.asset('assets/images/app_logo.png', errorBuilder: (_, __, ___) => const Icon(Icons.apartment_rounded, color: sapphire)),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DigiNiwas Elite', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -0.3)),
                      Text("Premium Real Estate Alliance", style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w500, color: sapphire)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18.w,
              top: 72.h,
              right: 120.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sapphire, width: 2)),
                        child: ClipOval(
                          child: data.profilePic.isNotEmpty
                              ? (data.profilePic.startsWith('http')
                                  ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                  : Image.file(File(data.profilePic), fit: BoxFit.cover))
                              : Container(color: const Color(0xFFEFF6FF), child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: sapphire)))),
                        ),
                      ),
                      Positioned(
                        right: -2.w,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(color: electric, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), height: 1.15)),
                  Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: electric, width: 0.8)),
                    child: Text('✓ Verified Elite Partner', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: sapphire)),
                  ),
                  SizedBox(height: 10.h),
                  _buildTag(Icons.location_on_rounded, data.city, sapphire),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.call_rounded, data.phone, sapphire),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', const Color(0xFF25D366)),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.apartment_rounded, data.specialization, sapphire),
                  SizedBox(height: 4.h),
                  _buildTag(Icons.shield_rounded, 'Trusted & Verified', sapphire),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 145.h,
              child: ClipPath(
                clipper: _TopWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A192F), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(18.w, 32.h, 18.w, 12.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: Colors.white24, width: 0.8)),
                            child: Text('View Properties >', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PartnerQrCodeWidget(data: data.profileUrl, size: 52.w),
                              SizedBox(height: 3.h),
                              Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5.sp, color: Colors.white70, height: 1.1)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 11.sp, color: electric),
                          SizedBox(width: 4.w),
                          Text('Search, Explore, Decide with Niwas AI.', style: TextStyle(fontSize: 8.5.sp, color: Colors.white60)),
                        ],
                      ),
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

  Widget _buildTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 5.w),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, color: const Color(0xFF334155)))),
      ],
    );
  }
}

// ================================================================
// DESIGN 5: SUNSET AMBER PRESTIGE (Horizontal)
// ================================================================
class DigitalCardSunsetAmber extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardSunsetAmber({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    const orange = Color(0xFFFB923C);

    return Container(
      width: 330.w,
      height: 216.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1005), Color(0xFF5A2508), Color(0xFF854D0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFB45309).withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 135.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/partner/card_villa_premium.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_top_partner.png', fit: BoxFit.cover)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF5A2508), const Color(0xFF5A2508).withValues(alpha: 0.4), Colors.transparent],
                        stops: const [0.0, 0.4, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              right: 85.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.villa_rounded, color: orange, size: 20.sp),
                        SizedBox(width: 5.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DigiNiwas Prestige', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text("Luxury Estates & Living", style: TextStyle(fontSize: 7.sp, color: orange)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: orange, width: 1.5)),
                          child: ClipOval(
                            child: data.profilePic.isNotEmpty
                                ? (data.profilePic.startsWith('http')
                                    ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                    : Image.file(File(data.profilePic), fit: BoxFit.cover))
                                : Container(color: Colors.white24, child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(color: orange, fontSize: 14.sp, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmberTag(Icons.location_on_rounded, data.city, orange),
                        SizedBox(height: 2.h),
                        _buildAmberTag(Icons.call_rounded, data.phone, orange),
                        SizedBox(height: 2.h),
                        _buildAmberTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', const Color(0xFF25D366)),
                        SizedBox(height: 2.h),
                        _buildAmberTag(Icons.apartment_rounded, data.specialization, orange),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFF2A1005), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: orange, width: 0.8)),
                      child: Text('View Properties >', style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: amber)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PartnerQrCodeWidget(data: data.profileUrl, size: 50.w),
                  SizedBox(height: 3.h),
                  Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.sp, color: Colors.white70, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmberTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 9.sp, color: color),
        SizedBox(width: 4.w),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.sp, color: Colors.white70)),
      ],
    );
  }
}

// ================================================================
// DESIGN 6: SLATE TITANIUM MINIMALIST (Horizontal)
// ================================================================
class DigitalCardSlateTitanium extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardSlateTitanium({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF2DD4BF);

    return Container(
      width: 330.w,
      height: 216.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF3F3F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 135.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/partner/card_building_minimal.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_promote.png', fit: BoxFit.cover)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF27272A), const Color(0xFF27272A).withValues(alpha: 0.4), Colors.transparent],
                        stops: const [0.0, 0.4, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              right: 85.w,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 18.w, height: 18.w, decoration: BoxDecoration(color: neon, borderRadius: BorderRadius.circular(4.r)), child: const Icon(Icons.bolt_rounded, size: 14, color: Colors.black)),
                        SizedBox(width: 5.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DigiNiwas Prime', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text("Next-Gen Advisory", style: TextStyle(fontSize: 7.sp, color: neon)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: neon, width: 1.5)),
                          child: ClipOval(
                            child: data.profilePic.isNotEmpty
                                ? (data.profilePic.startsWith('http')
                                    ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                    : Image.file(File(data.profilePic), fit: BoxFit.cover))
                                : Container(color: Colors.white24, child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(color: neon, fontSize: 14.sp, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSlateTag(Icons.location_on_rounded, data.city, neon),
                        SizedBox(height: 2.h),
                        _buildSlateTag(Icons.call_rounded, data.phone, neon),
                        SizedBox(height: 2.h),
                        _buildSlateTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', const Color(0xFF25D366)),
                        SizedBox(height: 2.h),
                        _buildSlateTag(Icons.apartment_rounded, data.specialization, neon),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: neon, width: 0.8)),
                      child: Text('View Properties >', style: TextStyle(fontSize: 8.5.sp, fontWeight: FontWeight.w800, color: neon)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PartnerQrCodeWidget(data: data.profileUrl, size: 50.w),
                  SizedBox(height: 3.h),
                  Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.sp, color: Colors.white70, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlateTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 9.sp, color: color),
        SizedBox(width: 4.w),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.sp, color: Colors.white70)),
      ],
    );
  }
}

// ================================================================
// DESIGN 7: ROYAL IVORY & FOREST GREEN (Vertical)
// ================================================================
class DigitalCardRoyalIvory extends StatelessWidget {
  final PartnerCardData data;
  const DigitalCardRoyalIvory({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF064E3B);
    const gold = Color(0xFFD97706);

    return Container(
      width: 310.w,
      height: 468.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFE2D9C5), width: 1.5),
        boxShadow: [
          BoxShadow(color: forest.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 70.h,
              width: 145.w,
              height: 200.h,
              child: ClipPath(
                clipper: _LeftCurveClipper(),
                child: Image.asset('assets/images/partner/card_building_vertical.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/partner/banner_promote.png', fit: BoxFit.cover)),
              ),
            ),
            Positioned(
              left: 18.w,
              top: 18.h,
              right: 18.w,
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8.r)),
                    child: const Icon(Icons.castle_rounded, color: forest, size: 20),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DigiNiwas Aristocrat', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: forest, letterSpacing: -0.2)),
                      Text("Heritage & Luxury Property Advisory", style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w600, color: gold)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18.w,
              top: 72.h,
              right: 120.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: forest, width: 2)),
                        child: ClipOval(
                          child: data.profilePic.isNotEmpty
                              ? (data.profilePic.startsWith('http')
                                  ? CachedNetworkImage(imageUrl: data.profilePic, fit: BoxFit.cover)
                                  : Image.file(File(data.profilePic), fit: BoxFit.cover))
                              : Container(color: const Color(0xFFFEF3C7), child: Center(child: Text(data.name.isNotEmpty ? data.name[0] : 'P', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: forest)))),
                        ),
                      ),
                      Positioned(
                        right: -2.w,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                          child: Icon(Icons.star_rounded, color: Colors.white, size: 12.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: forest, height: 1.15)),
                  Text(data.firmName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: gold)),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: gold, width: 0.8)),
                    child: Text('★ Certified Royal Partner', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: forest)),
                  ),
                  SizedBox(height: 10.h),
                  _buildIvoryTag(Icons.location_on_rounded, data.city, forest),
                  SizedBox(height: 4.h),
                  _buildIvoryTag(Icons.call_rounded, data.phone, forest),
                  SizedBox(height: 4.h),
                  _buildIvoryTag(Icons.chat_rounded, 'WA: ${data.whatsapp}', const Color(0xFF25D366)),
                  SizedBox(height: 4.h),
                  _buildIvoryTag(Icons.apartment_rounded, data.specialization, forest),
                  SizedBox(height: 4.h),
                  _buildIvoryTag(Icons.verified_user_rounded, 'Trusted & Certified Partner', forest),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 145.h,
              child: ClipPath(
                clipper: _TopWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF042F2C), Color(0xFF064E3B), Color(0xFF0D634C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(18.w, 32.h, 18.w, 12.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                            decoration: BoxDecoration(color: const Color(0xFF042F2C), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: gold, width: 0.8)),
                            child: Text('View Properties >', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: gold)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PartnerQrCodeWidget(data: data.profileUrl, size: 52.w),
                              SizedBox(height: 3.h),
                              Text('Scan to view\nmy profile', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5.sp, color: Colors.white70, height: 1.1)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 11.sp, color: gold),
                          SizedBox(width: 4.w),
                          Text('Search, Explore, Decide with Niwas AI.', style: TextStyle(fontSize: 8.5.sp, color: Colors.white60)),
                        ],
                      ),
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

  Widget _buildIvoryTag(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 5.w),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)))),
      ],
    );
  }
}

// ================================================================
// CENTRAL CARD RENDERER (SELECTS 1 OF THE 8 DESIGNS)
// ================================================================
class DigitalCardRenderer extends StatelessWidget {
  final PartnerCardData data;
  final int designIndex;

  const DigitalCardRenderer({super.key, required this.data, required this.designIndex});

  @override
  Widget build(BuildContext context) {
    switch (designIndex) {
      case 1:
        return DigitalCardHorizontalPremium(data: data);
      case 2:
        return DigitalCardHorizontalMinimal(data: data);
      case 3:
        return DigitalCardMidnightGold(data: data);
      case 4:
        return DigitalCardSapphireBlue(data: data);
      case 5:
        return DigitalCardSunsetAmber(data: data);
      case 6:
        return DigitalCardSlateTitanium(data: data);
      case 7:
        return DigitalCardRoyalIvory(data: data);
      case 0:
      default:
        return DigitalCardVertical(data: data);
    }
  }
}

// ================================================================
// CUSTOM CLIPPERS
// ================================================================
class _LeftCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width * 0.25, 0);
    path.quadraticBezierTo(0, size.height * 0.5, size.width * 0.25, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.22);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.55, size.height * 0.12);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.24, size.width, size.height * 0.15);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
