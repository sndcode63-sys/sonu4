import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/auth_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dotted_border.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/services/firebase_phone_auth_service.dart';
import '../../seller/presentation/map_picker_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../data/partner_repository.dart';

import 'widgets/partner_ui.dart';
// ================================================================
// DESIGN TOKENS (Matching Onboarding Mockups)
// ================================================================
const Color _kGreen = Color(0xFF0A5C4A);
const Color _kNavy = Color(0xFF0B1B2E);
const Color _kMuted = Color(0xFF5B6B7C);
const Color _kSoftGreen = Color(0xFFE8F3EF);
const Color _kBorder = Color(0xFFE3E8ED);

TextStyle _t(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    TextStyle(
      fontSize: size.sp,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

class PartnerApplicationScreen extends StatefulWidget {
  const PartnerApplicationScreen({super.key});

  @override
  State<PartnerApplicationScreen> createState() =>
      _PartnerApplicationScreenState();
}

class _PartnerApplicationScreenState extends State<PartnerApplicationScreen> {
  // Current Step: 0 = Basic + KYC, 1 = OTP Verification, 2 = Request Submitted
  int _currentStep = 0;

  // Controllers
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _pan = TextEditingController();
  final _aadhaar = TextEditingController();
  final _agencyName = TextEditingController();
  final _rera = TextEditingController();
  final _gst = TextEditingController();
  final _officeAddress = TextEditingController();
  final _pincode = TextEditingController();

  // Mobile OTP Box Controllers
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (_) => FocusNode());

  // Email OTP Box Controllers
  final List<TextEditingController> _emailOtpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _emailOtpFocusNodes =
  List.generate(6, (_) => FocusNode());

  String _accountType = 'Individual'; // Individual / Agency
  String _idProofType = 'Aadhaar Card';
  String _selectedState = 'Haryana';
  final String _selectedCity = 'Ambala';

  bool _loading = false;
  String? _applicationId;

  // Verification gating flags — dono true hue bina "Request Submitted" screen nahi khulegi.
  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool get _fullyVerified =>
      (_applicationId ?? '').isNotEmpty && _emailVerified && _phoneVerified;

  /// `_currentStep` kabhi bhi verification skip karke aage na jaa sake.
  int get _safeStep {
    final hasApp = (_applicationId ?? '').isNotEmpty;
    if (_currentStep >= 3) {
      if (_fullyVerified) return 3;
      if (hasApp && _emailVerified) return 2;
      return hasApp ? 1 : 0;
    }
    if (_currentStep == 2 && !(hasApp && _emailVerified)) return hasApp ? 1 : 0;
    if (_currentStep == 1 && !hasApp) return 0;
    return _currentStep;
  }

  String? _idProofFileLabel;
  String? _idProofBackFileLabel;
  String? _selfieFileLabel;

  // Local file paths for preview
  String? _idProofFrontPath;
  String? _idProofBackPath;
  String? _selfiePath;

  bool _isPickerActive = false;
  bool _isLookingUpPin = false;

  // Complete List of all 28 States and 8 Union Territories of India
  static const List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  // OTP Timer
  int _timerSeconds = 27;
  Timer? _timer;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPendingApplication();
  }

  Future<void> _loadPendingApplication() async {
    final pending =
    await StorageService.instance.getPendingPartnerApplication();
    final id = pending?['applicationId']?.toString();
    if (pending == null || id == null || id.isEmpty) return;
    if (!mounted) return;

    final step = pending['step']?.toString();
    setState(() {
      _applicationId = id;
      if (pending['name'] != null) _name.text = pending['name'].toString();
      if (pending['phone'] != null) {
        _phone.text = Validators.normalizeIndianMobile(pending['phone'].toString());
      }
      if (pending['email'] != null) _email.text = pending['email'].toString();
      _phoneVerified = false;
      if (step == 'VERIFY_PHONE') {
        _emailVerified = true; // email pehle hi verify ho chuka
        _currentStep = 2;
      } else {
        _emailVerified = false;
        _currentStep = 1;
      }
    });

    if (step == 'VERIFY_PHONE') {
      // Resume par Firebase session nahi hota — naya SMS bhejo, warna verify fail hoga.
      final sent = await _sendPhoneSms(showSuccessToast: false);
      if (!mounted) return;
      if (sent) _startTimer(); // fail hua to timer 0 rehta hai => Resend turant available
    } else {
      _startTimer();
    }
    if (mounted) {
      AppToast.showInfo(
        'You have an unfinished application. Complete email and mobile verification to submit it.',
      );
    }
  }

  /// Firebase SMS bhejta hai. Fail hone par timer 0 kar deta hai taaki "Resend" turant mile.
  Future<bool> _sendPhoneSms({bool showSuccessToast = true}) async {
    final phone = Validators.normalizeIndianMobile(_phone.text);
    try {
      await FirebasePhoneAuthService.instance.sendCode(phone);
      if (showSuccessToast && mounted) {
        AppToast.showSuccess('SMS verification code sent to +91 $phone');
      }
      return true;
    } on FirebaseOtpException catch (e) {
      if (mounted) {
        setState(() => _timerSeconds = 0);
        AppToast.showError(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _timerSeconds = 0);
        AppToast.showError('Could not send the SMS. Please tap "Resend SMS OTP".');
      }
    }
    return false;
  }

  /// Pending application (agar hai) ko resume karta hai; warna batata hai ki kuch pending nahi.
  Future<void> _trackApplication() async {
    final pending = await StorageService.instance.getPendingPartnerApplication();
    final id = pending?['applicationId']?.toString();
    if (id == null || id.isEmpty) {
      AppToast.showInfo('No pending application found on this device. Please fill the form below.');
      return;
    }
    await _loadPendingApplication();
  }

  /// Verification beech me chhodne / details badalne par confirm.
  Future<bool> _confirmDiscardApplication() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text('Change details?', style: _t(15, FontWeight.w800, _kNavy)),
        content: Text(
          'Changing your details will discard this application and you will need to '
              'verify your email and mobile number again.',
          style: _t(12.5, FontWeight.w500, _kMuted, h: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep verifying', style: _t(12.5, FontWeight.w700, _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Change details', style: _t(12.5, FontWeight.w800, _kGreen)),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await StorageService.instance.clearPendingPartnerApplication();
    FirebasePhoneAuthService.instance.reset();
    for (final c in [..._otpControllers, ..._emailOtpControllers]) {
      c.clear();
    }
    if (!mounted) return true;
    setState(() {
      _applicationId = null;
      _emailVerified = false;
      _phoneVerified = false;
      _currentStep = 0;
    });
    return true;
  }

  /// System back / AppBar back par verification screens se bahar jaane ka confirm.
  Future<void> _confirmLeaveVerification() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text('Leave verification?', style: _t(15, FontWeight.w800, _kNavy)),
        content: Text(
          'Your application is not submitted until both email and mobile are verified. '
              'You can resume it later from this screen.',
          style: _t(12.5, FontWeight.w500, _kMuted, h: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Stay', style: _t(12.5, FontWeight.w700, _kGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Leave', style: _t(12.5, FontWeight.w700, _kMuted)),
          ),
        ],
      ),
    );
    if (leave == true) Get.back();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        if (mounted) setState(() => _timerSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _pan.dispose();
    _aadhaar.dispose();
    _agencyName.dispose();
    _rera.dispose();
    _gst.dispose();
    _officeAddress.dispose();
    _pincode.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    for (var c in _emailOtpControllers) {
      c.dispose();
    }
    for (var f in _emailOtpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(
      ImageSource source, Function(String name, String path) onPicked) async {
    if (_isPickerActive) return;
    _isPickerActive = true;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file != null) {
        setState(() => onPicked(file.name, file.path));
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    } finally {
      _isPickerActive = false;
    }
  }

  /// Auto-lookup city and state when user enters a 6-digit Indian pincode
  Future<void> _lookupPincode(String pin) async {
    final cleanPin = pin.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanPin.length != 6) return;
    setState(() => _isLookingUpPin = true);
    try {
      final res = await Dio().get('https://api.postalpincode.in/pincode/$cleanPin');
      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final first = (res.data as List)[0];
        if (first['Status'] == 'Success' && first['PostOffice'] is List) {
          final offices = first['PostOffice'] as List;
          if (offices.isNotEmpty) {
            final po = offices[0] as Map;
            final district = po['District']?.toString() ?? '';
            final state = po['State']?.toString() ?? '';
            final area = po['Name']?.toString() ?? '';
            setState(() {
              if (district.isNotEmpty) _city.text = district;
              if (state.isNotEmpty) {
                final match = _indianStates.firstWhere(
                      (s) => s.toLowerCase() == state.toLowerCase(),
                  orElse: () => _selectedState,
                );
                _selectedState = match;
              }
              if (_officeAddress.text.trim().isEmpty && area.isNotEmpty) {
                _officeAddress.text = '$area, $district';
              }
            });
            AppToast.showSuccess('Location auto-detected for PIN $cleanPin: $district, $state');
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLookingUpPin = false);
    }
  }

  /// Open Google Map picker to search or drag-and-drop location
  Future<void> _pickLocationOnMap() async {
    try {
      final LatLng? picked = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MapPickerScreen(),
        ),
      );
      if (picked != null) {
        try {
          final placemarks = await Geocoding().placemarkFromCoordinates(
            picked.latitude,
            picked.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final street = [p.name, p.subLocality, p.thoroughfare]
                .where((s) => s != null && s.trim().isNotEmpty)
                .toSet()
                .join(', ');
            final city = p.locality?.isNotEmpty == true
                ? p.locality!
                : (p.subAdministrativeArea ?? '');
            final state = p.administrativeArea ?? '';
            final pin = p.postalCode ?? '';

            setState(() {
              if (street.isNotEmpty) _officeAddress.text = street;
              if (city.isNotEmpty) _city.text = city;
              if (state.isNotEmpty) {
                final matchedState = _indianStates.firstWhere(
                      (s) => s.toLowerCase() == state.toLowerCase(),
                  orElse: () => _selectedState,
                );
                _selectedState = matchedState;
              }
              if (pin.isNotEmpty) _pincode.text = pin;
            });
            AppToast.showSuccess('Location selected from map!');
            return;
          }
        } catch (_) {}
        AppToast.showSuccess('Coordinates selected: ${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}');
      }
    } catch (e) {
      AppToast.showError('Could not open map: $e');
    }
  }

  String _maskPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return '+91 ${clean.substring(0, 2)}XXXXXX${clean.substring(8)}';
    }
    return '+91 98XXXXXX70';
  }

  String _mapDocType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('aadhaar')) return 'AADHAAR';
    if (lower.contains('pan')) return 'PAN';
    if (lower.contains('passport')) return 'PASSPORT';
    if (lower.contains('voter')) return 'VOTER_ID';
    return 'AADHAAR';
  }

  String _formatDocUrl(String? fileName, String fallback) {
    final name = (fileName != null && fileName.trim().isNotEmpty) ? fileName.trim() : fallback;
    if (name.startsWith('http://') || name.startsWith('https://')) {
      return name;
    }
    return 'https://api.diginiwas.com/uploads/documents/$name';
  }

  Map<String, dynamic> _buildPayload() {
    final docType = _mapDocType(_idProofType);
    final aadhaarVal = _aadhaar.text.trim();
    final panVal = _pan.text.trim().toUpperCase();

    final idFront = _formatDocUrl(_idProofFileLabel, 'id_front.jpg');
    final idBack = _formatDocUrl(_idProofBackFileLabel ?? _idProofFileLabel, 'id_back.jpg');
    final selfieUrl = _formatDocUrl(_selfieFileLabel ?? _idProofFileLabel, 'selfie_front.jpg');

    final List<Map<String, dynamic>> docs = [
      {
        'documentType': docType,
        'numberMasked': docType == 'AADHAAR' ? aadhaarVal : (panVal.isNotEmpty ? panVal : aadhaarVal),
        'frontUrl': idFront,
        'backUrl': idBack,
        'remarks': _idProofFileLabel ?? '',
      },
    ];

    if (docType != 'PAN' && panVal.isNotEmpty) {
      docs.add({
        'documentType': 'PAN',
        'numberMasked': panVal,
        'frontUrl': selfieUrl,
        'backUrl': selfieUrl,
        'remarks': _selfieFileLabel ?? '',
      });
    }

    final cityVal = _city.text.trim().isNotEmpty ? _city.text.trim() : _selectedCity;
    final officeAddr = _officeAddress.text.trim().isNotEmpty ? _officeAddress.text.trim() : cityVal;
    final pinVal = Validators.digitsOnly(_pincode.text);

    return {
      'name': _name.text.trim(),
      'phone': AuthConfig.e164(Validators.normalizeIndianMobile(_phone.text)),
      'email': _email.text.trim().toLowerCase(),
      'accountType': _accountType == 'Agency' ? 'agency' : 'single',
      'business': {
        'businessName': _agencyName.text.trim().isNotEmpty
            ? _agencyName.text.trim()
            : _name.text.trim(),
        'businessType': _accountType == 'Agency' ? 'Company' : 'Individual',
        'gstin': _gst.text.trim().toUpperCase(),
        'officeAddress': officeAddr,
      },
      'location': {
        'address': officeAddr,
        'city': cityVal,
        'state': _selectedState.isNotEmpty ? _selectedState : 'Haryana',
        'country': 'India',
        'pincode': pinVal,
      },
      'rera': {
        'applicable': _rera.text.trim().isNotEmpty,
        'registrationNumber': _rera.text.trim(),
      },
      'identityDocuments': docs,
      'privacyConsent': {
        'accepted': true,
        'privacyNoticeVersion': 'v1',
      },
    };
  }

  Future<void> _sendOtp() async {
    if (_loading) return; // double-tap guard
    FocusScope.of(context).unfocus();

    final name = _name.text.trim();
    final phone = Validators.normalizeIndianMobile(_phone.text);
    final email = _email.text.trim().toLowerCase();

    // 1-3. Basic + Location + KYC (pehla error dikhao)
    final err = Validators.firstError([
          () => Validators.name(name),
          () => Validators.mobile(phone),
          () => Validators.email(email),
          () => Validators.required(_officeAddress.text, 'your Office / Service Address (or use Map)'),
          () => (_officeAddress.text.trim().length < 5) ? 'Office address is too short' : null,
          () => Validators.pinCode(_pincode.text),
          () => Validators.required(_city.text, 'your City / District'),
          () => _selectedState.isEmpty ? 'Please select your State' : null,
          () => Validators.pan(_pan.text),
          () => Validators.aadhaar(_aadhaar.text),
      // 4. Documents
          () => (_idProofFileLabel == null || _idProofFileLabel!.isEmpty) ? 'Please upload ID Proof (Front Side)' : null,
          () => (_idProofBackFileLabel == null || _idProofBackFileLabel!.isEmpty) ? 'Please upload ID Proof (Back Side)' : null,
          () => (_selfieFileLabel == null || _selfieFileLabel!.isEmpty) ? 'Please capture your Live Selfie' : null,
      // 5. Agency
          () => _accountType != 'Agency' ? null : Validators.required(_agencyName.text, 'your Agency / Business Name'),
          () => _accountType != 'Agency' ? null : Validators.gstinOptional(_gst.text),
          () => _accountType != 'Agency' ? null : Validators.reraOptional(_rera.text),
    ]);
    if (err != null) {
      AppToast.showError(err);
      return;
    }

    // Same details ke saath pehle se pending application hai? Naya mat banao — verification resume karo.
    final pending = await StorageService.instance.getPendingPartnerApplication();
    final pendingId = pending?['applicationId']?.toString();
    if (pendingId != null &&
        pendingId.isNotEmpty &&
        (pending!['email']?.toString().toLowerCase() ?? '') == email &&
        Validators.normalizeIndianMobile(pending['phone']?.toString()) == phone) {
      await _loadPendingApplication();
      return;
    }

    // Duplicate guard: ye number already partner ke roop me registered to nahi?
    setState(() => _loading = true);
    try {
      final alreadyRegistered = await Get.find<AuthRepository>()
          .isPhoneRegistered(phone: phone, role: 'partner');
      if (alreadyRegistered) {
        if (mounted) setState(() => _loading = false);
        AppToast.showError(
          'This mobile number is already registered as a partner. Please log in instead.',
        );
        return;
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _loading = false);
      AppToast.showError(e.message);
      return;
    }

    try {
      final repo = Get.find<PartnerRepository>();
      final body = await repo.registerPartnerApplication(_buildPayload());

      final data = body['data'] is Map ? body['data'] as Map : {};
      final appId = (data['applicationId'] ?? data['mongoId'] ?? data['_id'] ?? data['id'] ?? '').toString();
      if (appId.isEmpty) {
        throw PartnerApiException('Could not create your application. Please try again.');
      }

      _applicationId = appId;
      _emailVerified = false;
      _phoneVerified = false;
      await StorageService.instance.savePendingPartnerApplication({
        'applicationId': appId,
        'step': 'VERIFY_EMAIL',
        'name': name,
        'phone': phone,
        'email': email,
      });

      if (!mounted) return;
      setState(() {
        _currentStep = 1; // Move to Email OTP screen (Step 1)
        _loading = false;
      });
      _startTimer();
      AppToast.showSuccess('Application created! 6-digit OTP sent to $email');
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final errorMsg = e is PartnerApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '').trim();
      AppToast.showError(
        errorMsg.isNotEmpty ? errorMsg : 'Could not register partner application. Please try again.',
      );
    }
  }

  // --- Email OTP Handlers ---
  Future<void> _resendEmailOtp() async {
    if (_loading || _timerSeconds > 0) return;
    if ((_applicationId ?? '').isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = Get.find<PartnerRepository>();
      await repo.resendPartnerOtp(_applicationId!, channel: 'email');
      _startTimer();
      if (!mounted) return;
      AppToast.showSuccess('A fresh OTP has been sent to ${_email.text.trim()}');
    } catch (e) {
      if (!mounted) return;
      final msg = e is PartnerApiException ? e.message : 'Could not resend OTP. Please try again.';
      AppToast.showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_loading) return;
    final otp = _emailOtpControllers.map((c) => c.text.trim()).join();
    final otpErr = Validators.otp(otp);
    if (otpErr != null) {
      AppToast.showError(otpErr);
      return;
    }
    final appId = _applicationId;
    if (appId == null || appId.isEmpty) {
      // Application hi nahi bani — verification "skip" nahi ho sakti.
      AppToast.showError('Application not found. Please fill the form again.');
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = Get.find<PartnerRepository>();
      try {
        await repo.verifyPartnerEmail(appId, otp: otp);
      } on PartnerApiException catch (e) {
        // Server already verified maan chuka hai to aage badho.
        final m = e.message.toLowerCase();
        if (!(m.contains('already') && m.contains('verif'))) rethrow;
      }
      _emailVerified = true;

      await StorageService.instance.savePendingPartnerApplication({
        'applicationId': appId,
        'step': 'VERIFY_PHONE',
        'name': _name.text.trim(),
        'phone': Validators.normalizeIndianMobile(_phone.text),
        'email': _email.text.trim(),
      });

      for (final c in _emailOtpControllers) {
        c.clear();
      }
      if (!mounted) return;
      setState(() {
        _currentStep = 2; // Phone step — sirf email verify hone ke baad
        _loading = false;
      });
      _startTimer();

      // Firebase SMS bhejo (fail ho to Resend turant available).
      await _sendPhoneSms();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e is PartnerApiException ? e.message : 'Invalid Email OTP. Please try again.';
      AppToast.showError(msg.isNotEmpty ? msg : 'Invalid Email OTP. Please try again.');
      for (final c in _emailOtpControllers) {
        c.clear();
      }
      if (mounted) _emailOtpFocusNodes.first.requestFocus();
    }
  }

  // --- Mobile OTP Handlers (Firebase) ---
  Future<void> _resendPhoneOtp() async {
    if (_loading || _timerSeconds > 0) return;
    if (!_emailVerified) return;
    setState(() => _loading = true);
    try {
      if (FirebasePhoneAuthService.instance.hasActiveSession) {
        await FirebasePhoneAuthService.instance.resendCode();
      } else {
        await FirebasePhoneAuthService.instance
            .sendCode(Validators.normalizeIndianMobile(_phone.text));
      }
      _startTimer();
      if (!mounted) return;
      AppToast.showSuccess('SMS verification OTP resent to +91 ${Validators.normalizeIndianMobile(_phone.text)}');
    } on FirebaseOtpException catch (e) {
      if (!mounted) return;
      AppToast.showError(e.message);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError('Could not resend the SMS. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyPhoneOtp() async {
    if (_loading) return;

    // Hard gate: email verify nahi hua to phone verify allowed hi nahi.
    final appId = _applicationId;
    if (appId == null || appId.isEmpty || !_emailVerified) {
      AppToast.showError('Please verify your email first.');
      setState(() => _currentStep = (appId == null || appId.isEmpty) ? 0 : 1);
      return;
    }

    final otp = _otpControllers.map((c) => c.text.trim()).join();
    final otpErr = Validators.otp(otp);
    if (otpErr != null) {
      AppToast.showError(otpErr);
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Firebase se SMS OTP verify -> idToken (number match bhi check hota hai)
      final idToken = await FirebasePhoneAuthService.instance.verifyCode(otp);

      // 2. idToken backend ko (raw OTP kabhi nahi)
      final repo = Get.find<PartnerRepository>();
      await repo.verifyPartnerPhone(appId, idToken: idToken);
      _phoneVerified = true;

      await FirebasePhoneAuthService.instance.signOut();
      await StorageService.instance.clearPendingPartnerApplication();

      if (!mounted) return;
      setState(() {
        _currentStep = 3; // Request Submitted — sirf dono verify hone ke baad
        _loading = false;
      });
      AppToast.showSuccess('Mobile number verified successfully!');
    } on FirebaseOtpException catch (e) {
      if (mounted) setState(() => _loading = false);
      AppToast.showError(e.message);
      _clearPhoneOtpBoxes();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e is PartnerApiException ? e.message : 'Phone verification failed. Please try again.';
      AppToast.showError(msg.isNotEmpty ? msg : 'Phone verification failed.');
      _clearPhoneOtpBoxes();
    }
  }

  void _clearPhoneOtpBoxes() {
    for (final c in _otpControllers) {
      c.clear();
    }
    if (mounted) _otpFocusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final step = _safeStep;
    final inVerification = step == 1 || step == 2;

    return PopScope(
      // Verification ke beech system-back se seedha bahar nahi jaa sakte — confirm aata hai.
      canPop: !inVerification,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inVerification) _confirmLeaveVerification();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFCFB),
        appBar: AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _kNavy, size: 20.sp),
            onPressed: () {
              if (inVerification) {
                _confirmLeaveVerification();
              } else {
                Get.back();
              }
            },
          ),
          title: Text(
            'Partner Onboarding',
            style: _t(16, FontWeight.w800, _kNavy),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Top Stepper Bar
              _buildStepperHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  child: switch (step) {
                    0 => _buildStep1BasicAndKyc(),
                    1 => _buildStep2VerifyEmail(),
                    2 => _buildStep3VerifyMobile(),
                    _ => _buildStep4RequestSubmitted(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STEPPER HEADER
  // ================================================================
  Widget _buildStepperHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _safeStep == 0
                ? 'Create your partner account and complete KYC in 3 quick steps.'
                : (_safeStep == 1
                ? 'Verify your registered email address.'
                : (_safeStep == 2
                ? 'Verify your mobile number via SMS OTP.'
                : 'Your onboarding request has been submitted.')),
            style: _t(11.5, FontWeight.w400, _kMuted),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              // Step 1 Circle
              _stepperCircle(1, 'KYC Details', _safeStep >= 0, _safeStep == 0),
              Expanded(
                child: Container(
                  height: 2.h,
                  color: _safeStep >= 1 ? _kGreen : _kBorder,
                ),
              ),
              // Step 2 Circle
              _stepperCircle(2, 'Verify Email', _safeStep >= 1, _safeStep == 1),
              Expanded(
                child: Container(
                  height: 2.h,
                  color: _safeStep >= 2 ? _kGreen : _kBorder,
                ),
              ),
              // Step 3 Circle
              _stepperCircle(3, 'Verify Mobile', _safeStep >= 2, _safeStep == 2),
              if (_safeStep == 3) ...[
                Expanded(
                  child: Container(
                    height: 2.h,
                    color: _kGreen,
                  ),
                ),
                _stepperCircle(4, 'Submitted', true, true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperCircle(int stepNum, String label, bool isDone, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? _kGreen : Colors.white,
            border: Border.all(
              color: isDone ? _kGreen : _kBorder,
              width: 1.8,
            ),
          ),
          child: Center(
            child: (isDone && !isActive)
                ? Icon(Icons.check_rounded, size: 16.sp, color: Colors.white)
                : Text(
              '$stepNum',
              style: _t(12, FontWeight.w800, isDone ? Colors.white : _kMuted),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: _t(10, isActive ? FontWeight.w800 : FontWeight.w500, isActive ? _kNavy : _kMuted),
        ),
      ],
    );
  }

  // ================================================================
  // STEP 1: BASIC DETAILS + KYC
  // ================================================================
  Widget _buildStep1BasicAndKyc() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified Partner Badge Banner
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _kSoftGreen,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFCFE8E0), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verified DigiNiwas Partner Badge', style: _t(12.5, FontWeight.w800, _kNavy)),
                    SizedBox(height: 2.h),
                    Text(
                      'Complete your KYC to get a verified badge, build trust with customers and unlock partner benefits.',
                      style: _t(10.5, FontWeight.w400, _kMuted, h: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Section 1: Basic Details
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(Icons.person_rounded, '1. Basic Details', 'Tell us about yourself.'),
              SizedBox(height: 12.h),
              _labeledInput('Full Name *', _name, 'Your legal name',
                  prefixIcon: Icons.person_outline_rounded,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'\-]"))]),
              Row(
                children: [
                  Expanded(
                    child: _labeledInput('Mobile Number *', _phone, '10-digit mobile number',
                        prefixIcon: Icons.phone_android_rounded,
                        keyboard: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _labeledInput('Email Address *', _email, 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        maxLength: 254,
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))]),
                  ),
                ],
              ),
              Text('Account Type', style: _t(11.5, FontWeight.w700, _kNavy)),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: _accountTypeChip(
                      'Individual',
                      Icons.person_rounded,
                      _accountType == 'Individual',
                          () => setState(() => _accountType = 'Individual'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _accountTypeChip(
                      'Agency',
                      Icons.apartment_rounded,
                      _accountType == 'Agency',
                          () => setState(() => _accountType = 'Agency'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Section 2: Location & Address
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _sectionHeader(
                      Icons.location_on_rounded,
                      '2. Location & Address',
                      'Service area & office address details.',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: _pickLocationOnMap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _kSoftGreen,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location_rounded, size: 14.sp, color: _kGreen),
                          SizedBox(width: 4.w),
                          Text('Map', style: _t(11.5, FontWeight.w800, _kGreen)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _labeledInput(
                'Office / Service Address *',
                _officeAddress,
                'House/Flat/Shop no, Street, Landmark',
                prefixIcon: Icons.home_work_outlined,
              ),
              Row(
                children: [
                  Expanded(
                    child: _labeledInput(
                      'Pincode *',
                      _pincode,
                      '6-digit PIN',
                      prefixIcon: Icons.pin_drop_outlined,
                      keyboard: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        if (val.trim().length == 6) {
                          _lookupPincode(val.trim());
                        }
                      },
                      suffixWidget: _isLookingUpPin
                          ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
                      )
                          : null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _labeledInput(
                      'City / District *',
                      _city,
                      'e.g. Gurugram',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                ],
              ),
              Text('State / UT *', style: _t(11.5, FontWeight.w700, _kNavy)),
              SizedBox(height: 6.h),
              _simpleDropdown(_indianStates, _selectedState, (v) {
                if (v != null) setState(() => _selectedState = v);
              }),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // Section 3: KYC Details
        _cardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(Icons.assignment_rounded, '3. KYC Details', 'Provide your identity details for verification.'),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _labeledInput('PAN Number *', _pan, 'ABCDE1234F',
                        prefixIcon: Icons.badge_outlined,
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          _UpperCaseFormatter(),
                        ]),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _labeledInput('Aadhaar Number *', _aadhaar, 'XXXX-XXXX-XXXX',
                        prefixIcon: Icons.grid_view_rounded,
                        keyboard: TextInputType.number,
                        maxLength: 12,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text('ID Proof Type *', style: _t(11.5, FontWeight.w700, _kNavy)),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: _kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _idProofType,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: _kMuted),
                    style: _t(12.5, FontWeight.w600, _kNavy),
                    items: ['Aadhaar Card', 'PAN Card', 'Passport', 'Voter ID']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _idProofType = v);
                    },
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _imageUploadBox(
                      title: 'ID Proof (Front) *',
                      imagePath: _idProofFrontPath,
                      label: _idProofFileLabel ?? 'Choose Front',
                      sublabel: 'JPG, PNG image',
                      onTap: () => _pickImage(
                        ImageSource.gallery,
                            (n, p) {
                          _idProofFileLabel = n;
                          _idProofFrontPath = p;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _imageUploadBox(
                      title: 'ID Proof (Back) *',
                      imagePath: _idProofBackPath,
                      label: _idProofBackFileLabel ?? 'Choose Back',
                      sublabel: 'JPG, PNG image',
                      onTap: () => _pickImage(
                        ImageSource.gallery,
                            (n, p) {
                          _idProofBackFileLabel = n;
                          _idProofBackPath = p;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text('Live Selfie *', style: _t(11.5, FontWeight.w700, _kNavy)),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: (_selfiePath != null && File(_selfiePath!).existsSync())
                      ? _kSoftGreen.withValues(alpha: 0.35)
                      : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: (_selfiePath != null && File(_selfiePath!).existsSync())
                        ? _kGreen
                        : _kBorder,
                    width: (_selfiePath != null && File(_selfiePath!).existsSync()) ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    if (_selfiePath != null && File(_selfiePath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Image.file(
                          File(_selfiePath!),
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: const BoxDecoration(
                          color: _kSoftGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt_outlined, color: _kGreen, size: 22.sp),
                      ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selfiePath != null && File(_selfiePath!).existsSync()) ...[
                            Row(
                              children: [
                                Text('Selfie Captured!', style: _t(12, FontWeight.w800, _kNavy)),
                                SizedBox(width: 4.w),
                                Icon(Icons.check_circle, color: _kGreen, size: 14.sp),
                              ],
                            ),
                            Text('Face verified & attached.',
                                style: _t(10.5, FontWeight.w500, _kGreen)),
                          ] else ...[
                            Text('Take a live selfie *', style: _t(12, FontWeight.w800, _kNavy)),
                            Text('Ensure your face is clearly visible in good lighting.',
                                style: _t(10.5, FontWeight.w400, _kMuted)),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () => _pickImage(
                        ImageSource.camera,
                            (n, p) {
                          _selfieFileLabel = n;
                          _selfiePath = p;
                        },
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: (_selfiePath != null && File(_selfiePath!).existsSync())
                              ? Colors.white
                              : _kGreen,
                          borderRadius: BorderRadius.circular(8.r),
                          border: (_selfiePath != null && File(_selfiePath!).existsSync())
                              ? Border.all(color: _kGreen)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (_selfiePath != null && File(_selfiePath!).existsSync())
                                  ? Icons.refresh_rounded
                                  : Icons.camera_alt,
                              color: (_selfiePath != null && File(_selfiePath!).existsSync())
                                  ? _kGreen
                                  : Colors.white,
                              size: 13.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              (_selfiePath != null && File(_selfiePath!).existsSync())
                                  ? 'Retake'
                                  : 'Take Selfie',
                              style: _t(
                                11,
                                FontWeight.w800,
                                (_selfiePath != null && File(_selfiePath!).existsSync())
                                    ? _kGreen
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section 4: Agency Details (Shown if Agency selected)
        if (_accountType == 'Agency') ...[
          SizedBox(height: 14.h),
          _cardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(Icons.business_rounded, '4. Agency Details', 'Add your business or agency information.'),
                SizedBox(height: 12.h),
                _labeledInput('Agency / Firm Name *', _agencyName, 'e.g. Sharma Real Estate & Properties',
                    prefixIcon: Icons.apartment_rounded, maxLength: 100),
                Row(
                  children: [
                    Expanded(
                      child: _labeledInput('RERA Number (Optional)', _rera, 'e.g. RERA-HR-2024-001',
                          prefixIcon: Icons.verified_outlined, maxLength: 40),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _labeledInput('GSTIN (Optional)', _gst, '15-character GSTIN',
                          prefixIcon: Icons.receipt_long_outlined,
                          maxLength: 15,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            _UpperCaseFormatter(),
                          ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 20.h),

        // Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: _loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Send OTP', style: _t(14, FontWeight.w800, Colors.white)),
                SizedBox(width: 6.w),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
              ],
            ),
          ),
        ),

        SizedBox(height: 14.h),

        // Footer Links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _trackApplication,
              child: Text('Already applied? Resume Application', style: _t(11.5, FontWeight.w700, _kGreen)),
            ),
            Text('  |  ', style: _t(11.5, FontWeight.w400, _kMuted)),
            GestureDetector(
              onTap: () => Get.offAllNamed(AppRoutes.partnerLogin),
              child: Text('Already approved? Sign in', style: _t(11.5, FontWeight.w700, _kGreen)),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // STEP 2: VERIFY EMAIL ADDRESS (OTP SCREEN)
  // ================================================================
  Widget _buildStep2VerifyEmail() {
    final emailText = _email.text.trim().isNotEmpty ? _email.text.trim() : 'your registered email';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 8.h),

        // Email Illustration Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: _kSoftGreen,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFCFE8E0), width: 1.2),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: _kGreen.withValues(alpha: 0.15), blurRadius: 16),
                      ],
                    ),
                    child: Icon(Icons.mark_email_read_outlined, color: _kGreen, size: 36.sp),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text('OTP', style: _t(10, FontWeight.w900, Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text('Verify Email Address', style: _t(18, FontWeight.w800, _kNavy)),
              SizedBox(height: 4.h),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: _t(12, FontWeight.w400, _kMuted),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit verification OTP sent to \n'),
                    TextSpan(
                      text: emailText,
                      style: _t(12, FontWeight.w800, _kNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // 6 OTP Box Inputs for Email
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44.w,
              height: 52.h,
              child: TextField(
                controller: _emailOtpControllers[i],
                focusNode: _emailOtpFocusNodes[i],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                maxLength: 1,
                style: _t(18, FontWeight.w800, _kNavy),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: _kBorder, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: _kBorder, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: _kGreen, width: 2),
                  ),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    _emailOtpFocusNodes[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _emailOtpFocusNodes[i - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),

        SizedBox(height: 14.h),

        // Timer & Change Email Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _timerSeconds == 0 ? _resendEmailOtp : null,
              child: Text(
                _timerSeconds > 0
                    ? 'Resend OTP in 00:${_timerSeconds.toString().padLeft(2, '0')}'
                    : 'Resend Email OTP',
                style: _t(11.5, FontWeight.w700, _timerSeconds == 0 ? _kGreen : _kMuted),
              ),
            ),
            GestureDetector(
              onTap: _confirmDiscardApplication,
              child: Text('Change Details', style: _t(11.5, FontWeight.w800, _kGreen)),
            ),
          ],
        ),

        SizedBox(height: 22.h),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyEmailOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: _loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Verify Email & Next', style: _t(14, FontWeight.w800, Colors.white)),
                SizedBox(width: 6.w),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
              ],
            ),
          ),
        ),

        SizedBox(height: 10.h),

        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: OutlinedButton(
            onPressed: _loading ? null : _confirmDiscardApplication,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kGreen, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Text('Edit Details', style: _t(13, FontWeight.w800, _kGreen)),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STEP 3: VERIFY MOBILE NUMBER (FIREBASE SMS OTP)
  // ================================================================
  Widget _buildStep3VerifyMobile() {
    final phoneText = _phone.text.trim().isNotEmpty ? _phone.text.trim() : '98XXXXXX70';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 8.h),

        // Phone & Shield Illustration Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: _kSoftGreen,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFCFE8E0), width: 1.2),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: _kGreen.withValues(alpha: 0.15), blurRadius: 16),
                      ],
                    ),
                    child: Icon(Icons.phonelink_ring_rounded, color: _kGreen, size: 36.sp),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text('SMS', style: _t(10, FontWeight.w900, Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text('Verify Mobile Number', style: _t(18, FontWeight.w800, _kNavy)),
              SizedBox(height: 4.h),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: _t(12, FontWeight.w400, _kMuted),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit SMS OTP sent to '),
                    TextSpan(
                      text: _maskPhone(phoneText),
                      style: _t(12, FontWeight.w800, _kNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // 6 OTP Box Inputs for Phone
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44.w,
              height: 52.h,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                maxLength: 1,
                style: _t(18, FontWeight.w800, _kNavy),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: _kBorder, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: _kBorder, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: _kGreen, width: 2),
                  ),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),

        SizedBox(height: 14.h),

        // Timer & Change Number Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _timerSeconds == 0 ? _resendPhoneOtp : null,
              child: Text(
                _timerSeconds > 0
                    ? 'Resend OTP in 00:${_timerSeconds.toString().padLeft(2, '0')}'
                    : 'Resend SMS OTP',
                style: _t(11.5, FontWeight.w700, _timerSeconds == 0 ? _kGreen : _kMuted),
              ),
            ),
            GestureDetector(
              onTap: _confirmDiscardApplication,
              child: Text('Change Number', style: _t(11.5, FontWeight.w800, _kGreen)),
            ),
          ],
        ),

        SizedBox(height: 18.h),

        // Security Lock Info Card
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _kSoftGreen,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_rounded, color: _kGreen, size: 18.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Your phone number is verified using secure Firebase SMS authentication.',
                  style: _t(10.5, FontWeight.w400, _kNavy, h: 1.35),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 22.h),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyPhoneOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: _loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Complete Verification', style: _t(14, FontWeight.w800, Colors.white)),
                SizedBox(width: 6.w),
                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18.sp),
              ],
            ),
          ),
        ),

        SizedBox(height: 20.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: _kGreen, size: 16.sp),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                'After verification, your request will be submitted for review.',
                style: _t(11, FontWeight.w500, _kMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // STEP 4: REQUEST SUBMITTED / STATUS SCREEN
  // ================================================================
  Widget _buildStep4RequestSubmitted() {
    final appId = _applicationId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 8.h),

        // Celebration Top Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: _kSoftGreen,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFCFE8E0), width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 40.sp),
              ),
              SizedBox(height: 16.h),
              Text('Request Submitted', style: _t(20, FontWeight.w800, _kNavy)),
              SizedBox(height: 6.h),
              Text(
                'Your partner onboarding request has been submitted successfully.',
                textAlign: TextAlign.center,
                style: _t(12.5, FontWeight.w600, _kNavy, h: 1.4),
              ),
              SizedBox(height: 4.h),
              Text(
                'Please wait for approval from the DigiNiwas team. We will notify you once your account is reviewed.',
                textAlign: TextAlign.center,
                style: _t(11, FontWeight.w400, _kMuted, h: 1.4),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Application Details Box
        _cardWrapper(
          child: Column(
            children: [
              _detailRow(Icons.description_rounded, 'Application ID', appId, isBoldValue: true),
              const Divider(height: 20, color: _kBorder),
              _detailRow(
                Icons.access_time_filled_rounded,
                'Status',
                'Under Review',
                customValueWidget: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 12.sp, color: const Color(0xFFB7791F)),
                      SizedBox(width: 4.w),
                      Text('Under Review', style: _t(11, FontWeight.w800, const Color(0xFFB7791F))),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20, color: _kBorder),
              _detailRow(Icons.event_note_rounded, 'Expected update', 'Within 24-48 hours', isBoldValue: true),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.partnerDashboard),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, color: Colors.white, size: 18.sp),
                SizedBox(width: 6.w),
                Text('Track Application', style: _t(13.5, FontWeight.w800, Colors.white)),
                SizedBox(width: 6.w),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18.sp),
              ],
            ),
          ),
        ),

        SizedBox(height: 10.h),

        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: OutlinedButton(
            onPressed: () => Get.offAllNamed(AppRoutes.buyerHome),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kGreen, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, color: _kGreen, size: 18.sp),
                SizedBox(width: 6.w),
                Text('Back to Home', style: _t(13, FontWeight.w800, _kGreen)),
              ],
            ),
          ),
        ),

        SizedBox(height: 18.h),

        // Support Contact Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: _kSoftGreen,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.headset_mic_rounded, color: _kGreen, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Need help?', style: _t(12.5, FontWeight.w800, _kNavy)),
                    Text('Our partner support team is here to help you.', style: _t(11, FontWeight.w400, _kMuted)),
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('tel:+918000012345');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      child: Row(
                        children: [
                          Text('Contact Partner Support', style: _t(11.5, FontWeight.w800, _kGreen)),
                          SizedBox(width: 4.w),
                          Icon(Icons.arrow_forward_rounded, color: _kGreen, size: 12.sp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // HELPER WIDGETS
  // ================================================================
  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _kBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: const BoxDecoration(color: _kSoftGreen, shape: BoxShape.circle),
          child: Icon(icon, color: _kGreen, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _t(13.5, FontWeight.w800, _kNavy)),
              Text(subtitle, style: _t(11, FontWeight.w400, _kMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labeledInput(
      String label,
      TextEditingController controller,
      String hint, {
        IconData? prefixIcon,
        Widget? suffixWidget,
        TextInputType keyboard = TextInputType.text,
        ValueChanged<String>? onChanged,
        bool readOnly = false,
        int maxLines = 1,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        TextCapitalization textCapitalization = TextCapitalization.none,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _t(11.5, FontWeight.w700, _kNavy)),
          SizedBox(height: 6.h),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            style: _t(12.5, FontWeight.w600, _kNavy),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: _t(12, FontWeight.w400, PartnerColors.textTertiary),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18.sp, color: _kMuted) : null,
              suffixIcon: suffixWidget != null
                  ? Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: suffixWidget,
              )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: _kGreen, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountTypeChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? _kGreen : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? _kGreen : _kBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : _kMuted, size: 16.sp),
            SizedBox(width: 6.w),
            Text(label, style: _t(12, FontWeight.w800, isSelected ? Colors.white : _kNavy)),
          ],
        ),
      ),
    );
  }

  Widget _imageUploadBox({
    required String title,
    required String? imagePath,
    required String? label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    final bool hasImage =
        imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(11.5, FontWeight.w700, _kNavy),
              ),
            ),
            if (hasImage) ...[
              SizedBox(width: 4.w),
              Icon(Icons.check_circle_rounded, color: _kGreen, size: 14.sp),
            ],
          ],
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: onTap,
          child: hasImage
              ? Container(
                  height: 94.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: PartnerColors.ink,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: _kGreen,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        ),
                        // Bottom semi-transparent bar for tap to change
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, PartnerColors.ink],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.change_circle_outlined, color: Colors.white, size: 12.sp),
                                SizedBox(width: 3.w),
                                Flexible(
                                  child: Text(
                                    'Change',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(10, FontWeight.w700, Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Top-right green checkmark badge
                        Positioned(
                          top: 5.h,
                          right: 5.w,
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: const BoxDecoration(
                              color: _kGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 11.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : AppDottedBorder(
                  radius: 10.r,
                  color: _kGreen,
                  backgroundColor: const Color(0xFFF6F8FA),
                  child: Container(
                    height: 94.h,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: const BoxDecoration(
                            color: _kSoftGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_upload_outlined, color: _kGreen, size: 18.sp),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          label ?? 'Upload',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _t(11, FontWeight.w800, _kGreen),
                        ),
                        Text(
                          sublabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _t(9.5, FontWeight.w400, _kMuted),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _simpleDropdown(List<String> items, String selected, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: _kMuted),
          style: _t(12, FontWeight.w600, _kNavy),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isBoldValue = false, Widget? customValueWidget}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: const BoxDecoration(color: _kSoftGreen, shape: BoxShape.circle),
          child: Icon(icon, color: _kGreen, size: 16.sp),
        ),
        SizedBox(width: 10.w),
        Text(label, style: _t(12, FontWeight.w500, _kMuted)),
        const Spacer(),
        customValueWidget ??
            Text(value, style: _t(12.5, isBoldValue ? FontWeight.w800 : FontWeight.w600, _kNavy)),
      ],
    );
  }
}

/// PAN / GSTIN jaise fields me typing ke saath hi capital letters.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
