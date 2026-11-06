import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auth_debug.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/auth_controller.dart';
import 'registration_screen.dart' show DigiNiwasLogo;

/// Common Forgot / Reset password screen for Buyer, Seller and Partner
/// Per DigiNiwas Auth API Guide:
/// POST /api/v1/auth/forgot-password { "email": "...", "role": "buyer"|"seller"|"partner" }
/// POST /api/v1/auth/reset-password  { "email": "...", "role": "...", "otp": "...", "newPassword": "..." }
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialRole;
  const ForgotPasswordScreen({super.key, this.initialRole});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _auth = Get.find<AuthController>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  late String _selectedRole;
  bool _otpStep = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final argsRole = Get.arguments is Map ? Get.arguments['role']?.toString() : null;
    _selectedRole = widget.initialRole ?? argsRole ?? 'Buyer';
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      AppToast.error(context, 'Enter a valid registered email address.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final error = await _auth.forgotPassword(email: email, role: _selectedRole);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    AppToast.success(context, 'Password reset OTP sent to $email');
    setState(() => _otpStep = true);
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    final otp = _otp.text.trim();
    final pass = _newPass.text;
    if (otp.length != 6) {
      AppToast.error(context, 'Enter the complete 6-digit OTP.');
      return;
    }
    if (pass.length < 8) {
      AppToast.error(context, 'Password must be at least 8 characters.');
      return;
    }
    if (pass != _confirmPass.text) {
      AppToast.error(context, 'Passwords do not match.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final error = await _auth.resetPassword(
      email: email,
      role: _selectedRole,
      otp: otp,
      newPassword: pass,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    AuthDebug.log('FORGOT', 'password reset done -> back to login');
    AppToast.success(context, 'Password reset successfully. You can now login with your new password.');
    Get.offAllNamed(AppRoutes.chooseRole);
  }

  Widget _pill(Widget child) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
    ),
    child: child,
  );

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPlaceholder,
    ),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    suffixIcon: suffix,
    counterText: '',
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  const DigiNiwasLogo(),
                  SizedBox(height: 18.h),
                  Text(
                    _otpStep
                        ? 'Enter the 6-digit OTP sent to your email and set a new password.'
                        : 'Enter your registered email to receive a password reset OTP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Role Selector
                  if (!_otpStep) ...[
                    Container(
                      height: 40.h,
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFF3),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: ['Buyer', 'Seller', 'Partner'].map((role) {
                          final isSel = _selectedRole.toLowerCase() == role.toLowerCase();
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = role),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],

                  // Email Field
                  _pill(Row(children: [
                    Icon(Icons.mail_outline_rounded, size: 20.sp, color: AppColors.textSecondary),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _email,
                        enabled: !_otpStep,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        decoration: _dec('Registered Email Address'),
                      ),
                    ),
                  ])),

                  if (_otpStep) ...[
                    SizedBox(height: 22.h),
                    Text(
                      'Enter 6-Digit Email OTP',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 8.h),
                    Pinput(
                      length: 6,
                      controller: _otp,
                      defaultPinTheme: PinTheme(
                        width: 46.w,
                        height: 52.h,
                        textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    _pill(Row(children: [
                      Icon(Icons.lock_outline_rounded, size: 19.sp, color: AppColors.textSecondary),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: _newPass,
                          obscureText: _obscure,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                          decoration: _dec(
                            'New password (min 8 chars)',
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 19.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ])),
                    SizedBox(height: 14.h),
                    _pill(Row(children: [
                      Icon(Icons.lock_reset_rounded, size: 19.sp, color: AppColors.textSecondary),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: _confirmPass,
                          obscureText: _obscure,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                          decoration: _dec('Confirm new password'),
                        ),
                      ),
                    ])),
                  ],
                  SizedBox(height: 26.h),
                  AppButton(
                    label: _otpStep ? 'Reset Password' : 'Send Reset OTP',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _loading,
                    onPressed: _loading ? null : (_otpStep ? _reset : _sendOtp),
                  ),
                  if (_otpStep) ...[
                    SizedBox(height: 14.h),
                    GestureDetector(
                      onTap: _loading ? null : _sendOtp,
                      child: Text(
                        'Resend OTP to Email',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
