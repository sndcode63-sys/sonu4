import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/auth_controller.dart';
import 'otp.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;

  /// Seller / Partner accounts are created through their dedicated multi-step
  /// application flows (with address / KYC), so for them this screen focuses on Sign In.
  final bool loginOnly;

  const RegistrationScreen({super.key, required this.role, this.loginOnly = false});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthController _authController = Get.find<AuthController>();

  // Text Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoginMode = true; // Sign In vs Sign Up
  bool _isFormValid = false;
  bool _isSubmitting = false;

  bool get _hasStartedTyping =>
      _phoneController.text.isNotEmpty ||
          _nameController.text.isNotEmpty ||
          _emailController.text.isNotEmpty;

  bool get _isBuyer => widget.role.trim().toLowerCase() == 'buyer';
  bool get _isSeller => widget.role.trim().toLowerCase() == 'seller';

  @override
  void initState() {
    super.initState();
    // For Seller & Partner, default to login mode
    if (!_isBuyer) {
      _isLoginMode = true;
    }
  }

  /// Pehla validation error (ya null). Button enable/disable aur submit dono yahi use karte hain.
  String? _firstError() {
    final phoneErr = Validators.mobile(_phoneController.text);
    if (_isLoginMode) {
      return phoneErr;
    }
    // Buyer Sign Up: Name + Phone + Optional Email
    return Validators.firstError([
          () => Validators.name(_nameController.text),
          () => phoneErr,
          () => Validators.email(_emailController.text, required: false),
    ]);
  }

  void _validateForm() {
    final isValid = _firstError() == null;
    setState(() => _isFormValid = isValid); // hint text bhi refresh ho
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;

    final err = _firstError();
    if (err != null) {
      _showError(err);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final phone = Validators.normalizeIndianMobile(_phoneController.text);
    final email = _emailController.text.trim();

    if (_isLoginMode) {
      // 100% Phone + OTP Login (with pre-check account exists)
      final success = await _authController.requestLoginOtp(
        phone: phone,
        role: widget.role,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        AppToast.success(context, 'OTP sent to +91 $phone');
        Get.toNamed(
          AppRoutes.otp,
          arguments: {
            'phoneNumber': phone,
            'mode': OtpFlowMode.login,
            'role': widget.role,
          },
        );
      } else {
        final err = _authController.state.value.errorMessage ?? 'Could not send OTP. Please try again.';
        _showError(err);
      }
    } else {
      // Buyer Registration (no password field needed)
      final success = await _authController.register(
        name: _nameController.text.trim(),
        phone: phone,
        email: email.isNotEmpty ? email : null,
        role: widget.role,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        AppToast.success(context, 'OTP sent to +91 $phone');
        Get.toNamed(
          AppRoutes.otp,
          arguments: {
            'phoneNumber': phone,
            'mode': OtpFlowMode.register,
            'role': widget.role,
          },
        );
      } else {
        final err = _authController.state.value.errorMessage ?? 'Registration failed. Please try again.';
        _showError(err);
      }
    }
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD4F1F4),
                Color(0xFFF7FBFD),
                Colors.white,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DigiNiwasLogo(),
                    SizedBox(height: 16.h),

                    // Tab Switcher between Sign In & Sign Up (Only for Buyer; Seller & Partner use application forms)
                    if (_isBuyer && !widget.loginOnly)
                      Container(
                        height: 44.h,
                        margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EFF3),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isLoginMode) {
                                    setState(() {
                                      _isLoginMode = true;
                                      _validateForm();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isLoginMode ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: _isLoginMode
                                        ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _isLoginMode ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_isLoginMode) {
                                    setState(() {
                                      _isLoginMode = false;
                                      _validateForm();
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isLoginMode ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: !_isLoginMode
                                        ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: !_isLoginMode ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header
                    Text(
                      _isLoginMode ? 'Welcome Back' : 'Create an Account',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _isLoginMode
                          ? 'Enter your mobile number to sign in via OTP'
                          : "India's Trusted Digital Property Platform",
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Continuing as Badge + Switch Role
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: AppColors.softBackground,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'Continuing as ${widget.role}',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () => Get.offAllNamed(AppRoutes.chooseRole),
                          child: Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),



                    // Form Fields
                    // 1. Phone Field (Used for Phone OTP Login & Buyer Signup)
                    if (true) ...[
                      _buildInputPill(
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) => _validateForm(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Enter Mobile Number',
                              hintStyle: TextStyle(
                                fontSize: 13.5.sp,
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
                              contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 18.w, right: 10.w),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Container(width: 1.2, height: 16.h, color: const Color(0xFFECEFF2)),
                                  ],
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Buyer Sign Up Fields: Name, Email (optional)
                    if (!_isLoginMode) ...[
                      SizedBox(height: 14.h),
                      _buildInputPill(
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 60,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'\-]"))],
                            onChanged: (value) => _validateForm(),
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Full Name',
                              hintStyle: TextStyle(fontSize: 13.5.sp, color: AppColors.textPlaceholder),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _buildInputPill(
                        child: SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                            onChanged: (value) => _validateForm(),
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Email Address (Optional)',
                              hintStyle: TextStyle(fontSize: 13.5.sp, color: AppColors.textPlaceholder),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // Inline hint: button kyun disabled hai
                    if (!_isFormValid && _hasStartedTyping)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Text(
                          _firstError() ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),

                    // Primary Action Button
                    AppButton(
                      label: _isLoginMode ? 'Continue with OTP' : 'Create Account',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _isFormValid ? _handleContinue : null,
                    ),
                    SizedBox(height: 22.h),

                    // Terms & Policy
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(AppRoutes.termsOfService),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(AppRoutes.privacyPolicy),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Navigation to Seller / Partner signup flows
                    if (!_isBuyer) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSeller ? 'New Seller?' : 'New Partner?',
                                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _isSeller ? 'Register with address & verification' : 'Complete partner application & KYC',
                                  style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              onPressed: () => Get.toNamed(
                                _isSeller ? AppRoutes.sellerRegistration : AppRoutes.partnerApply,
                              ),
                              child: Text(
                                _isSeller ? 'Register' : 'Apply Now',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Buyer mode: Switch between Login and Registration Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLoginMode ? "New to DigiNiwas? " : 'Already registered? ',
                            style: TextStyle(fontSize: 13.5.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _validateForm();
                              });
                            },
                            child: Text(
                              _isLoginMode ? 'Create Account' : 'Sign In',
                              style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputPill({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DigiNiwasLogo extends StatelessWidget {
  final double? height;

  const DigiNiwasLogo({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png',
      height: height ?? 85.h,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_rounded, size: 44.sp, color: AppColors.primary),
          SizedBox(height: 4.h),
          Text(
            'DIGINIWAS',
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
