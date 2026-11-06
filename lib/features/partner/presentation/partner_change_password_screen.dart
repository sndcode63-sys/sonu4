import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../data/partner_repository.dart';

import 'widgets/partner_ui.dart';
class PartnerChangePasswordScreen extends StatefulWidget {
  const PartnerChangePasswordScreen({super.key});

  @override
  State<PartnerChangePasswordScreen> createState() =>
      _PartnerChangePasswordScreenState();
}

class _PartnerChangePasswordScreenState
    extends State<PartnerChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text != _confirm.text) {
      Get.snackbar('Error', 'New passwords do not match');
      return;
    }
    if (_next.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = Get.find<PartnerRepository>();
      await repo.changePartnerPassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      // Flag is cleared inside repository; ensure session can reach dashboard.
      await repo.clearMustChangePasswordFlag();
      if (Get.isRegistered<PartnerHomeController>()) {
        Get.delete<PartnerHomeController>(force: true);
      }
      Get.put(PartnerHomeController());
      Get.offAllNamed(AppRoutes.partnerDashboard);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final repo = Get.find<PartnerRepository>();
    await repo.clearPartnerSession();
    if (Get.isRegistered<PartnerHomeController>()) {
      Get.delete<PartnerHomeController>(force: true);
    }
    Get.offAllNamed(AppRoutes.partnerLogin);
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
        title: const Text('Change Password'),
        backgroundColor: Colors.white,
        foregroundColor: PartnerColors.ink,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _loading ? null : _signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: PartnerGradients.brand,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: PartnerShadows.brand,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.lock_rounded, color: const Color(0xFFE9C46A), size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure your account',
                          style: PartnerText.title(15, color: Colors.white),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Update your password to continue to the partner dashboard.',
                          style: PartnerText.body(11.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: PartnerColors.line),
                boxShadow: PartnerShadows.card,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _current,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _next,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.key_rounded, size: 20.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: Icon(Icons.check_circle_outline_rounded, size: 20.sp),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PartnerColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
