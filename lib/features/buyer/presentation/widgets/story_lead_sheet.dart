import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../controllers/buyer_home_controller.dart';

const Color _kGreen = Color(0xFF007A5E);

/// Enquiry bottom sheet (Name + Mobile). Pre-fills from the logged-in user.
/// [onSubmit] sends the lead; a success dialog is shown afterwards.
Future<void> showStoryEnquirySheet(
    BuildContext context, {
      required String heading,
      required String subjectName,
      required Future<void> Function(String name, String phone) onSubmit,
    }) async {
  String name0 = '';
  String phone0 = '';
  try {
    name0 = (await StorageService.instance.name)?.trim() ?? '';
    phone0 = (await StorageService.instance.phone)?.trim() ?? '';
    if (name0.isEmpty || phone0.isEmpty) {
      final raw = await SecureStorageService.instance.getUserData();
      if (raw != null && raw.isNotEmpty) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          if (name0.isEmpty && m['name'] != null) name0 = m['name'].toString().trim();
          if (phone0.isEmpty && m['phone'] != null) phone0 = m['phone'].toString().trim();
        } catch (_) {}
      }
      if (name0.isEmpty && Get.isRegistered<BuyerHomeController>()) {
        final u = Get.find<BuyerHomeController>().dashboardHeader.value?.user;
        if (u?.name != null) name0 = u!.name!;
      }
    }
  } catch (_) {}

  if (!context.mounted) return;

  final nameC = TextEditingController(text: name0);
  final phoneC = TextEditingController(text: phone0);
  final formKey = GlobalKey<FormState>();
  bool submitting = false;
  String? submittedName;

  InputDecoration deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey),
    prefixIcon: Icon(icon, color: _kGreen),
    filled: true,
    fillColor: const Color(0xFFF7F9FA),
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: _kGreen, width: 1.5),
    ),
  );

  Widget label(String t) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(t,
        style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF173247))),
  );

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(heading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173247))),
              Text('Our verified advisor will call you to assist.',
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp, color: Colors.grey.shade600)),
              SizedBox(height: 18.h),
              label('Your Name'),
              TextFormField(
                controller: nameC,
                decoration: deco('Enter your full name', Icons.person_outline_rounded),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
              ),
              SizedBox(height: 14.h),
              label('Mobile Number'),
              TextFormField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: deco('Enter 10-digit mobile number', Icons.phone_outlined),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please enter a valid 10-digit phone number'
                    : null,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    setModal(() => submitting = true);
                    final n = nameC.text.trim();
                    try {
                      await onSubmit(n, phoneC.text.trim());
                      submittedName = n;
                    } finally {
                      submitting = false;
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: submitting
                      ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text('Submit Request',
                          style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  nameC.dispose();
  phoneC.dispose();

  if (submittedName != null) {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: _kGreen, size: 38),
              ),
              SizedBox(height: 16.h),
              Text('Request Submitted!',
                  style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173247))),
              SizedBox(height: 8.h),
              Text(
                'Thank you $submittedName. Your enquiry for "$subjectName" has been received. Our team will contact you shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13.sp, color: Colors.grey.shade700, height: 1.4),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Great, thanks!',
                      style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
