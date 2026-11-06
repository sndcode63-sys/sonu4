import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/seller_controller.dart';

class SellerChangePasswordScreen extends StatefulWidget {
  const SellerChangePasswordScreen({super.key});

  @override
  State<SellerChangePasswordScreen> createState() => _SellerChangePasswordScreenState();
}

class _SellerChangePasswordScreenState extends State<SellerChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final SellerController _controller = Get.isRegistered<SellerController>()
      ? Get.find<SellerController>()
      : Get.put(SellerController());

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isMandatory = false;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is Map && Get.arguments['isMandatory'] == true) {
      _isMandatory = true;
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();

    final success = await _controller.changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Your password has been changed successfully.',
        backgroundColor: const Color(0xFFEAF5F1),
        colorText: AppColors.primary,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.r),
      );
      // Navigate to seller home
      Get.offAllNamed(AppRoutes.sellerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isMandatory
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.sp),
                onPressed: () => Navigator.of(context).pop(),
              ),
        automaticallyImplyLeading: !_isMandatory,
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Header
                Center(
                  child: Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5F1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 36.sp),
                  ),
                ),
                SizedBox(height: 16.h),

                // Mandatory Warning Banner if needed
                if (_isMandatory) ...[
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E6),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFFFD580)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: const Color(0xFFD97706), size: 22.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security Notice',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                'You logged in with a temporary password. Please set a new permanent password to secure your account.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5.sp,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                Text(
                  'Set New Credentials',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Choose a strong password containing letters, numbers, and symbols.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 20.h),

                // Current Password Field
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: _isMandatory ? 'Temporary / Current Password' : 'Current Password',
                  hint: 'Enter current password',
                  obscureText: _obscureCurrent,
                  onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // New Password Field
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'Enter new password (min. 6 characters)',
                  obscureText: _obscureNew,
                  onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter new password';
                    }
                    if (val.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (val.trim() == _currentPasswordController.text.trim()) {
                      return 'New password must be different from current password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Confirm New Password Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  obscureText: _obscureConfirm,
                  onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (val.trim() != _newPasswordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 28.h),

                // Submit Button
                Obx(() {
                  final isLoading = _controller.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Update Password',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),

                if (_isMandatory) ...[
                  SizedBox(height: 16.h),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Allow user to proceed to home anyway if they wish
                        Get.offAllNamed(AppRoutes.sellerHome);
                      },
                      child: Text(
                        'Remind me later',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 13.sp, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 12.sp, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 20.sp, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20.sp,
                color: AppColors.textSecondary,
              ),
              onPressed: onToggleVisibility,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
