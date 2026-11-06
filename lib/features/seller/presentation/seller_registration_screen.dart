import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/auth_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/firebase_phone_auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../controllers/seller_controller.dart';
import '../data/seller_repository.dart';

/// Seller registration.
///
/// Rules (strictly enforced):
///  1. Form ke saare fields validate hone ke baad hi application create hoti hai.
///  2. Email OTP verify hone ke bina Phone OTP step khulta hi nahi.
///  3. Phone (Firebase SMS) OTP verify hone ke bina registration "complete" nahi hoti
///     aur success screen nahi dikhti.
///  4. OTP sheets back-button / swipe se band nahi hoti; sirf "Verify" ya
///     "Cancel" se. Cancel par application pending rehti hai aur resume ka option milta hai.
class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final SellerController _controller = Get.put(SellerController());
  final SellerRepository _repository = SellerRepository();

  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Indore');
  final _stateController = TextEditingController(text: 'Madhya Pradesh');
  final _pinCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  // ---- Verification state (server application + local gating flags) ----
  String? _applicationId;
  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool _credentialsEmailSent = false;

  String get _phone10 => Validators.normalizeIndianMobile(_phoneController.text);
  String get _email => _emailController.text.trim();

  bool get _fullyVerified =>
      (_applicationId ?? '').isNotEmpty && _emailVerified && _phoneVerified;

  @override
  void initState() {
    super.initState();
    // Agar registration beech me chhoot gayi thi to resume offer karo, warna
    // location maango taaki address auto-fill ho sake.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hadPendingApplication = await _checkForPendingApplication();
      if (!hadPendingApplication && mounted) {
        _useCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Resume pending application
  // ------------------------------------------------------------------

  /// Returns true if an unfinished registration was found (resume dialog shown).
  Future<bool> _checkForPendingApplication() async {
    final pending = await SecureStorageService.instance.getPendingSellerApplication();
    final applicationId = pending['applicationId'];
    final step = pending['step'];
    if (applicationId == null || applicationId.isEmpty || step == null) return false;
    if (!mounted) return false;

    _emailController.text = pending['email'] ?? '';
    final savedPhone = Validators.normalizeIndianMobile(pending['phone']);
    _phoneController.text = savedPhone;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Resume Registration?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15.sp)),
              ),
            ],
          ),
          content: Text(
            'You have an unfinished seller registration for ${pending['email'] ?? 'your account'}. '
                'Email and phone verification are required to complete it. Continue verifying?',
            style: GoogleFonts.poppins(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _clearPending();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _useCurrentLocation();
                }
              },
              child: Text('Start Fresh',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _applicationId = applicationId;
                _emailVerified = step == 'VERIFY_PHONE'; // email pehle hi verify ho chuka
                _phoneVerified = false;
                await _runVerificationFlow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('Continue',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    return true;
  }

  Future<void> _clearPending() async {
    await SecureStorageService.instance.clearPendingSellerApplication();
    FirebasePhoneAuthService.instance.reset();
    _applicationId = null;
    _emailVerified = false;
    _phoneVerified = false;
  }

  // ------------------------------------------------------------------
  // Location
  // ------------------------------------------------------------------

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final location = await LocationService().getCurrentLocation();
      if (!mounted) return;

      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        if (location.address.isNotEmpty) _addressController.text = location.address;
        if (location.city.isNotEmpty) _cityController.text = location.city;
        if (location.state.isNotEmpty) _stateController.text = location.state;
        if (location.country.isNotEmpty) _countryController.text = location.country;
        if (location.pinCode.isNotEmpty) _pinCodeController.text = location.pinCode;
      });

      AppToast.showSuccess(
        'Address fields have been auto-filled. You can still edit them manually.',
      );
    } on LocationException catch (e) {
      AppToast.showError(e.message);
    } catch (e) {
      AppToast.showError('Could not fetch your location. Please enter address manually.');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ------------------------------------------------------------------
  // Step 0: Submit application (creates application, then FORCES verification)
  // ------------------------------------------------------------------

  Future<void> _submitApplication() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      AppToast.showWarning('Please fix the highlighted fields.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Same details ke saath application pehle se bani hui hai? Naya mat banao, verification resume karo.
      final pending = await SecureStorageService.instance.getPendingSellerApplication();
      final pendingId = pending['applicationId'];
      final samePending = pendingId != null &&
          pendingId.isNotEmpty &&
          (pending['email'] ?? '').toLowerCase() == _email.toLowerCase() &&
          Validators.normalizeIndianMobile(pending['phone']) == _phone10;
      if (samePending) {
        _applicationId = pendingId;
        _emailVerified = pending['step'] == 'VERIFY_PHONE';
        _phoneVerified = false;
        if (mounted) setState(() => _isSubmitting = false);
        await _runVerificationFlow();
        return;
      }

      // Duplicate guard: ye number already seller account ke roop me registered to nahi?
      final alreadyRegistered = await Get.find<AuthRepository>()
          .isPhoneRegistered(phone: _phone10, role: 'seller');
      if (alreadyRegistered) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        AppToast.showError(
          'This mobile number is already registered as a seller. Please log in instead.',
        );
        return;
      }

      final appResult = await _repository.registerSellerApplication(
        name: _nameController.text.trim(),
        email: _email.toLowerCase(),
        phone: AuthConfig.e164(_phone10),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: Validators.digitsOnly(_pinCodeController.text),
        country: _countryController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (appResult.applicationId.isEmpty) {
        throw SellerException('Could not create your application. Please try again.');
      }

      _controller.currentApplication.value = appResult;
      _applicationId = appResult.applicationId;
      _emailVerified = false;
      _phoneVerified = false;

      await SecureStorageService.instance.savePendingSellerApplication(
        applicationId: appResult.applicationId,
        step: 'VERIFY_EMAIL',
        email: _email,
        phone: _phone10,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await _runVerificationFlow();
    } on SellerException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(e.message);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError('Registration failed. Please try again.');
    }
  }

  // ------------------------------------------------------------------
  // Mandatory verification pipeline: Email OTP -> Phone OTP -> Done
  // ------------------------------------------------------------------

  Future<void> _runVerificationFlow() async {
    final appId = _applicationId;
    if (appId == null || appId.isEmpty || !mounted) return;

    // ---- Step 1/2: Email OTP (mandatory) ----
    if (!_emailVerified) {
      final ok = await _showOtpSheet(
        _OtpSheet(
          icon: Icons.email_outlined,
          title: 'Verify Email Address',
          stepLabel: 'Step 1 of 2',
          message: 'An OTP has been sent to $_email. Enter it below:',
          hint: 'Enter 6-digit email OTP',
          verifyLabel: 'Verify Email & Next',
          resendLabel: 'Resend Email OTP',
          onVerify: (otp) async {
            try {
              await _repository.verifySellerEmailOtp(applicationId: appId, otp: otp);
            } on SellerException catch (e) {
              // Server already verified maan chuka hai (e.g. pichhli baar response miss hua)
              final m = e.message.toLowerCase();
              if (!(m.contains('already') && m.contains('verif'))) rethrow;
            }
            _emailVerified = true;
            await SecureStorageService.instance.savePendingSellerApplication(
              applicationId: appId,
              step: 'VERIFY_PHONE',
              email: _email,
              phone: _phone10,
            );
          },
          onResend: () => _repository.resendSellerEmailOtp(applicationId: appId),
        ),
      );
      if (!ok) return _onVerificationInterrupted();
    }

    // Hard gate: email verify hue bina phone step kabhi nahi khulega.
    if (!_emailVerified || !mounted) return;

    // ---- Step 2/2: Phone OTP via Firebase (mandatory) ----
    if (!_phoneVerified) {
      String? smsError;
      try {
        await FirebasePhoneAuthService.instance.sendCode(_phone10);
      } on FirebaseOtpException catch (e) {
        smsError = e.message;
      } catch (_) {
        smsError = 'Could not send the SMS. Please tap "Resend SMS OTP".';
      }
      if (!mounted) return;

      final ok = await _showOtpSheet(
        _OtpSheet(
          icon: Icons.phone_android_rounded,
          title: 'Verify Phone Number',
          stepLabel: 'Step 2 of 2 (SMS)',
          message: smsError == null
              ? 'An SMS code has been sent to +91 $_phone10. Enter it to complete registration:'
              : 'We could not send the SMS to +91 $_phone10.',
          warning: smsError,
          hint: 'Enter 6-digit SMS OTP',
          verifyLabel: 'Complete Verification',
          resendLabel: 'Resend SMS OTP',
          startWithCooldown: smsError == null,
          onVerify: (otp) async {
            // 1. Firebase se code verify -> idToken (number match bhi check hota hai)
            final idToken = await FirebasePhoneAuthService.instance.verifyCode(otp);
            // 2. idToken backend ko (raw OTP kabhi nahi)
            final res = await _repository.verifySellerPhoneOtp(
              applicationId: appId,
              idToken: idToken,
            );
            final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : <String, dynamic>{};
            _credentialsEmailSent = data['credentialsEmailSent'] == true;
            _phoneVerified = true;
            await FirebasePhoneAuthService.instance.signOut();
          },
          onResend: () async {
            if (FirebasePhoneAuthService.instance.hasActiveSession) {
              await FirebasePhoneAuthService.instance.resendCode();
            } else {
              await FirebasePhoneAuthService.instance.sendCode(_phone10);
            }
          },
        ),
      );
      if (!ok) return _onVerificationInterrupted();
    }

    // ---- Done: sirf tab jab dono verify ho chuke hon ----
    if (_fullyVerified && mounted) {
      await _clearPending();
      if (!mounted) return;
      _showSuccessDialog(_credentialsEmailSent);
    }
  }

  void _onVerificationInterrupted() {
    if (!mounted) return;
    AppToast.showWarning(
      'Registration is not complete. Verify your email and phone to finish — '
          'tap "Register as Seller" again to resume.',
    );
  }

  /// Non-dismissible OTP sheet. Returns true only when verification succeeded.
  Future<bool> _showOtpSheet(_OtpSheet sheet) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => sheet,
    );
    return res == true;
  }

  void _showSuccessDialog(bool credentialsEmailSent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('Registration Submitted',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          content: Text(
            credentialsEmailSent
                ? 'Your email and phone are verified. Your seller account details have been sent to your registered email address. You can now log in with your mobile number and OTP.'
                : 'Your email and phone are verified. Once your seller account is active you can log in with your mobile number and OTP.',
            style: GoogleFonts.poppins(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showSellerLoginBottomSheet();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('Login with OTP',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Seller Registration',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('1. Personal Information', Icons.person_outline_rounded),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. Rahul Sharma',
                  textCapitalization: TextCapitalization.words,
                  maxLength: 60,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'\-]"))],
                  validator: (v) => Validators.name(v),
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'e.g. rahul@example.com',
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 254,
                  formatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  validator: (v) => Validators.email(v),
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'e.g. 9876543210',
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  prefixText: '+91  ',
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.mobile(v),
                ),
                SizedBox(height: 24.h),

                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 4.h,
                  children: [
                    _buildSectionHeader('2. Address & Location', Icons.location_on_outlined),
                    TextButton.icon(
                      onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                      icon: _isFetchingLocation
                          ? SizedBox(
                        width: 14.w,
                        height: 14.h,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Icon(Icons.my_location_rounded, size: 16.sp, color: AppColors.primary),
                      label: Text(
                        _isFetchingLocation ? 'Locating...' : 'Use Current Location',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Tap "Use Current Location" to auto-fill the fields below, or enter your address manually.',
                  style: GoogleFonts.poppins(fontSize: 10.5.sp, color: AppColors.textSecondary),
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: _addressController,
                  label: 'Street Address',
                  hint: 'e.g. Scheme No 54, Vijay Nagar',
                  maxLength: 200,
                  validator: (v) => Validators.address(v),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'Indore',
                        maxLength: 50,
                        validator: (v) => Validators.required(v, 'city'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        label: 'State',
                        hint: 'Madhya Pradesh',
                        maxLength: 50,
                        validator: (v) => Validators.required(v, 'state'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _pinCodeController,
                        label: 'PIN Code',
                        hint: '452010',
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => Validators.pinCode(v),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTextField(
                        controller: _countryController,
                        label: 'Country',
                        hint: 'India',
                        maxLength: 50,
                        validator: (v) => Validators.required(v, 'country'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By registering as a seller, you agree to our\n',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Get.toNamed(AppRoutes.termsOfService),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Get.toNamed(AppRoutes.privacyPolicy),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5F1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 18.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Registration completes only after you verify your email (OTP) and your mobile number (SMS OTP).',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Register as Seller',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSellerLoginBottomSheet();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Login here',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Seller login OTP-only hai (phone -> OTP), common login screen se.
  void _showSellerLoginBottomSheet() {
    Get.toNamed(
      AppRoutes.registration,
      arguments: {'role': 'Seller', 'loginOnly': true},
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    String? prefixText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return FormField<String>(
      initialValue: controller.text,
      validator: (v) => validator?.call(controller.text),
      builder: (FormFieldState<String> fieldState) {
        if (fieldState.value != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (fieldState.mounted) {
              fieldState.didChange(controller.text);
            }
          });
        }

        final hasError = fieldState.hasError && fieldState.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                border: hasError
                    ? Border.all(color: const Color(0xFFEF4444), width: 1.2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLength: maxLength,
                textCapitalization: textCapitalization,
                inputFormatters: formatters,
                onChanged: (val) {
                  fieldState.didChange(val);
                },
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  counterText: '',
                  prefixText: prefixText,
                  prefixStyle: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: label,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: EdgeInsets.only(left: 18.w, top: 4.h),
                child: Text(
                  fieldState.errorText!,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ======================================================================
// Reusable, non-dismissible OTP bottom sheet (email + phone dono ke liye)
// ======================================================================

class _OtpSheet extends StatefulWidget {
  const _OtpSheet({
    required this.icon,
    required this.title,
    required this.stepLabel,
    required this.message,
    required this.hint,
    required this.verifyLabel,
    required this.resendLabel,
    required this.onVerify,
    required this.onResend,
    this.warning,
    this.startWithCooldown = true,
  });

  final IconData icon;
  final String title;
  final String stepLabel;
  final String message;
  final String hint;
  final String verifyLabel;
  final String resendLabel;
  final String? warning;
  final bool startWithCooldown;

  /// Throw karo agar verification fail ho; success par normal return.
  final Future<void> Function(String otp) onVerify;
  final Future<void> Function() onResend;

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  static const int _cooldownSeconds = 30;

  final _otpController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _error = widget.warning;
    if (widget.startWithCooldown) {
      _cooldown = _cooldownSeconds;
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = _cooldownSeconds);
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  String _messageOf(Object e) {
    if (e is FirebaseOtpException) return e.message;
    final s = e.toString().replaceFirst('Exception: ', '').trim();
    return s.isEmpty ? 'Something went wrong. Please try again.' : s;
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final err = Validators.otp(_otpController.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await widget.onVerify(_otpController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = _messageOf(e);
        _otpController.clear();
      });
    }
  }

  Future<void> _resend() async {
    if (_resending || _cooldown > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      _otpController.clear();
      AppToast.showSuccess('A fresh OTP has been sent.');
      setState(() => _resending = false);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _error = _messageOf(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Back button / swipe se sheet band nahi hogi — sirf Verify ya Cancel se.
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: SingleChildScrollView(
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
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5F1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: AppColors.primary, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: GoogleFonts.poppins(
                                fontSize: 16.sp, fontWeight: FontWeight.w700)),
                        Text(widget.stepLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(widget.message,
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp, color: AppColors.textSecondary)),
              SizedBox(height: 16.h),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 20.sp, fontWeight: FontWeight.w700, letterSpacing: 8),
                onSubmitted: (_) => _verify(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12.sp, letterSpacing: 0, fontWeight: FontWeight.w400),
                  counterText: '',
                  errorText: _error,
                  errorMaxLines: 3,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(widget.verifyLabel,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: (_resending || _cooldown > 0 || _verifying) ? null : _resend,
                    child: Text(
                      _resending
                          ? 'Sending...'
                          : _cooldown > 0
                          ? 'Resend in 00:${_cooldown.toString().padLeft(2, '0')}'
                          : widget.resendLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: _verifying ? null : () => Navigator.of(context).pop(false),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
