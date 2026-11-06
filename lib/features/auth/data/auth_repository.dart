import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/config/auth_config.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/firebase_phone_auth_service.dart';
import '../../../core/utils/auth_debug.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/validators.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._apiService, this._storage);

  final ApiService _apiService;
  final SecureStorageService _storage;

  static const String defaultRole = 'Buyer';


  Future<Map<String, dynamic>> checkPhoneAccount({
    required String phone,
    required String role,
  }) async {
    final e164Phone = AuthConfig.e164(phone);
    final normalizedRole = AuthConfig.roleForApi(role);
    final body = {
      'phone': e164Phone,
      'role': normalizedRole,
    };
    AuthDebug.log('API', 'POST ${ApiConstants.checkPhoneAccount} body=$body (Public)');
    try {
      final response = await _apiService.post(
        ApiConstants.checkPhoneAccount,
        data: body,
        options: Options(extra: {'skipAuth': true}),
      );
      final data = _asMap(response.data);
      AuthDebug.log('API', '<- check-account: $data');

      // Account hai lekin login allowed nahi (pending / blocked / suspended...)
      // to SMS bhejne se pehle hi saaf message do.
      if (data['accountExists'] == false) {
        throw AuthException('No $role account found with mobile $phone. Please sign up first.');
      }
      if (data['canLogin'] == false) {
        throw AuthException(_loginBlockedMessage(data, role));
      }
      return data;
    } on AuthException {
      rethrow;
    } on DioException catch (e, st) {
      AuthDebug.error('API', 'check-account returned ${e.response?.statusCode}', e, st);
      final code = e.response?.statusCode;
      if (code == 404) {
        throw AuthException('No $role account found with mobile $phone. Please sign up first.');
      }
      throw AuthException(_extractMessage(e, fallback: 'Account check failed. Please try again.'));
    }
  }

  /// Registration se pehle duplicate check.
  /// true  => is role ke saath ye phone already registered hai
  /// false => registered nahi hai (404 / accountExists=false)
  /// Network error par exception throw hota hai (silently pass nahi karta).
  Future<bool> isPhoneRegistered({
    required String phone,
    required String role,
  }) async {
    final body = {
      'phone': AuthConfig.e164(phone),
      'role': AuthConfig.roleForApi(role),
    };
    try {
      final response = await _apiService.post(
        ApiConstants.checkPhoneAccount,
        data: body,
        options: Options(extra: {'skipAuth': true}),
      );
      final data = _asMap(response.data);
      return data['accountExists'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      throw AuthException(_extractMessage(e, fallback: 'Could not verify your number. Please try again.'));
    }
  }

  String _loginBlockedMessage(Map<String, dynamic> data, String role) {
    final msg = data['message'];
    final status = '${data['accountStatus'] ?? ''}'.toUpperCase();
    if (status.contains('PENDING') || status.contains('VERIFICATION')) {
      return 'Your $role application is still under verification. You can log in once it is approved.';
    }
    if (status.contains('REJECT')) {
      return 'Your $role application was not approved. Please contact support.';
    }
    if (status.contains('BLOCK') || status.contains('SUSPEND') || status.contains('INACTIVE')) {
      return 'Your account is not active. Please contact support.';
    }
    if (msg is String && msg.trim().isNotEmpty) return msg;
    return 'This account cannot log in right now. Please contact support.';
  }

  /// Register buyer: POST /api/v1/auths/register
  /// Body: { name, email, phone, password, role: "buyer" }
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    String? password,
    String role = defaultRole,
    LocationResult? location,
  }) async {
    final cleanPhone = Validators.normalizeIndianMobile(phone);
    final e164Phone = AuthConfig.e164(cleanPhone);
    final pass = (password != null && password.trim().isNotEmpty)
        ? password.trim()
        : _generatePassword(phone);

    final payload = {
      'name': name.trim(),
      'phone': e164Phone,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'password': pass,
      'role': AuthConfig.roleForApi(role),
      if (location != null) 'location': location.toLocationPayload(),
    };

    try {
      dynamic response;
      try {
        response = await _apiService.post(ApiConstants.register, data: payload);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await _apiService.post(ApiConstants.registerLegacy, data: payload);
        } else {
          rethrow;
        }
      }
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Registration failed. Please try again.');
      AppLogger.i('Registration successful for $phone');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Registration failed for $phone', e, st);
      throw AuthException(_extractMessage(e, fallback: 'Registration failed. Please try again.'));
    }
  }

  /// Sends the login/registration OTP.
  ///  - In login mode: optionally checks account existence first.
  ///  - Firebase mode: sends SMS via Firebase Phone Auth SDK.
  Future<void> sendOtp({
    required String phone,
    String role = defaultRole,
    bool checkAccountFirst = false,
  }) async {
    if (checkAccountFirst) {
      await checkPhoneAccount(phone: phone, role: role);
    }

    if (AuthConfig.useFirebaseFor(role)) {
      AuthDebug.log('OTP', 'role=$role -> FIREBASE flow for ${AuthConfig.e164(phone)}');
      try {
        await FirebasePhoneAuthService.instance.sendCode(phone);
        return;
      } on FirebaseOtpException catch (e) {
        throw AuthException(e.message);
      } catch (e, st) {
        AuthDebug.error('OTP', 'Firebase sendCode crashed', e, st);
        throw AuthException('Could not send OTP. Please try again.');
      }
    }
    AuthDebug.log('OTP', 'role=$role -> BACKEND flow');
    await _backendOtpCall(ApiConstants.loginOtpSend, phone: phone, role: role,
        fallback: 'Could not send OTP. Please try again.');
  }

  /// Resends the OTP (Firebase: uses forceResendingToken).
  Future<void> resendOtp({required String phone, String role = defaultRole}) async {
    if (AuthConfig.useFirebaseFor(role)) {
      try {
        await FirebasePhoneAuthService.instance.resendCode();
        return;
      } on FirebaseOtpException catch (e) {
        throw AuthException(e.message);
      } catch (e, st) {
        AuthDebug.error('OTP', 'Firebase resendCode crashed', e, st);
        throw AuthException('Could not resend OTP. Please try again.');
      }
    }
    await _backendOtpCall(ApiConstants.loginOtpResend, phone: phone, role: role,
        fallback: 'Could not resend OTP. Please try again.');
  }

  Future<void> _backendOtpCall(String path,
      {required String phone, required String role, required String fallback}) async {
    final body = {'phone': phone, 'role': AuthConfig.roleForApi(role)};
    AuthDebug.log('API', 'POST $path body=${AuthDebug.mask(body)}');
    try {
      final response = await _apiService.post(path, data: body);
      AuthDebug.log('API', '<- ${response.statusCode} ${response.data}');
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: fallback);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        try {
          final fallbackResponse = await _apiService.post(ApiConstants.sendOtp, data: body);
          final data = _asMap(fallbackResponse.data);
          _throwIfUnsuccessful(data, fallback: fallback);
          return;
        } catch (_) {}
      }
      AuthDebug.error('API', 'POST $path failed status=${e.response?.statusCode}', e, st);
      throw AuthException(_extractMessage(e, fallback: fallback));
    }
  }

  /// Verifies the OTP and logs the user in, saving token + profile.
  ///  - Firebase mode: Firebase verifies OTP -> sends idToken + role to
  ///    POST /api/v1/auths/firebase-phone-login -> JWT token.
  Future<Map<String, dynamic>> loginWithOtp({
    required String phone,
    required String otp,
    String role = defaultRole,
    LocationResult? location,
  }) async {
    final bool viaFirebase = AuthConfig.useFirebaseFor(role);
    if (viaFirebase) {
      final String idToken;
      try {
        idToken = await FirebasePhoneAuthService.instance.verifyCode(otp);
      } on FirebaseOtpException catch (e) {
        throw AuthException(e.message);
      } catch (e, st) {
        AuthDebug.error('OTP', 'Firebase verifyCode crashed', e, st);
        throw AuthException('Invalid or expired OTP. Please try again.');
      }

      final body = {
        'idToken': idToken,
        'role': AuthConfig.roleForApi(role),
      };

      AuthDebug.log('API', 'POST ${ApiConstants.firebaseLogin} body=${AuthDebug.mask(body)}');
      try {
        dynamic response;
        try {
          response = await _apiService.post(ApiConstants.firebaseLogin, data: body);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            response = await _apiService.post(ApiConstants.firebaseLoginLegacy, data: body);
          } else {
            rethrow;
          }
        }
        final data = _asMap(response.data);
        _throwIfUnsuccessful(data, fallback: 'Invalid or expired OTP. Please try again.');
        await _persistSession(data, role: role);
        await FirebasePhoneAuthService.instance.signOut();
        AppLogger.i('Firebase OTP login successful for $phone as $role');
        return data;
      } on DioException catch (e, st) {
        AuthDebug.error('API', 'POST ${ApiConstants.firebaseLogin} failed status=${e.response?.statusCode}', e, st);
        throw AuthException(_extractMessage(e, fallback: 'Invalid or expired OTP. Please try again.'));
      }
    } else {
      const path = ApiConstants.loginOtpVerify;
      final body = {
        'phone': phone,
        'otp': otp,
        'role': AuthConfig.roleForApi(role),
        if (location != null) 'location': location.toLocationPayload(),
      };
      try {
        final response = await _apiService.post(path, data: body);
        final data = _asMap(response.data);
        _throwIfUnsuccessful(data, fallback: 'Invalid or expired OTP. Please try again.');
        await _persistSession(data, role: role);
        return data;
      } on DioException catch (e, st) {
        AuthDebug.error('API', 'POST $path failed status=${e.response?.statusCode}', e, st);
        throw AuthException(_extractMessage(e, fallback: 'Invalid or expired OTP. Please try again.'));
      }
    }
  }

  /// Password Login:
  /// - Buyer: POST /api/v1/auths/login-password { phone, password, role: "buyer" }
  /// - Seller: POST /api/v1/sellers/auth/login { email, password }
  /// - Partner: POST /api/v1/partner-auth/login { email, password }
  Future<Map<String, dynamic>> loginWithPassword({
    required String identifier,
    required String password,
    String role = defaultRole,
  }) async {
    final normalizedRole = AuthConfig.roleForApi(role);
    final String path;
    final Map<String, dynamic> body;

    if (normalizedRole == 'seller') {
      path = ApiConstants.sellerLogin;
      body = {'email': identifier.trim(), 'password': password};
    } else if (normalizedRole == 'partner' || normalizedRole == 'agent') {
      path = ApiConstants.partnerLogin;
      body = {'email': identifier.trim(), 'password': password};
    } else {
      path = ApiConstants.loginPassword;
      body = {
        'phone': AuthConfig.e164(identifier),
        'password': password,
        'role': 'buyer',
      };
    }

    AuthDebug.log('API', 'POST $path body=${AuthDebug.mask(body)}');
    try {
      dynamic response;
      try {
        response = await _apiService.post(path, data: body);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 && path == ApiConstants.loginPassword) {
          response = await _apiService.post(ApiConstants.loginPasswordLegacy, data: body);
        } else if (e.response?.statusCode == 404 && path == ApiConstants.partnerLogin) {
          response = await _apiService.post(ApiConstants.partnerLoginLegacy, data: body);
        } else {
          rethrow;
        }
      }
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Login failed. Please check your credentials.');
      await _persistSession(data, role: role);
      AppLogger.i('Password login successful for $identifier as $role');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Password login failed for $identifier', e, st);
      throw AuthException(_extractMessage(e, fallback: 'Login failed. Please check your credentials.'));
    }
  }

  /// Forgot password: POST /api/v1/auth/forgot-password
  /// Body: { "email": "...", "role": "buyer" | "seller" | "partner" }
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String role,
  }) async {
    final body = {
      'email': email.trim(),
      'role': AuthConfig.roleForApi(role),
    };
    AuthDebug.log('API', 'POST ${ApiConstants.forgotPassword} body=$body');
    try {
      final response = await _apiService.post(ApiConstants.forgotPassword, data: body);
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not send password reset OTP.');
      return data;
    } on DioException catch (e, st) {
      AuthDebug.error('API', 'forgot-password failed status=${e.response?.statusCode}', e, st);
      throw AuthException(_extractMessage(e, fallback: 'Could not send password reset OTP.'));
    }
  }

  /// Reset password: POST /api/v1/auth/reset-password
  /// Body: { "email": "...", "role": "...", "otp": "...", "newPassword": "..." }
  Future<void> resetPassword({
    required String email,
    required String role,
    required String otp,
    required String newPassword,
  }) async {
    final body = {
      'email': email.trim(),
      'role': AuthConfig.roleForApi(role),
      'otp': otp.trim(),
      'newPassword': newPassword,
    };
    AuthDebug.log('API', 'POST ${ApiConstants.resetPassword} body=${AuthDebug.mask(body)}');
    try {
      final response = await _apiService.post(ApiConstants.resetPassword, data: body);
      _throwIfUnsuccessful(_asMap(response.data), fallback: 'Could not reset password.');
    } on DioException catch (e, st) {
      AuthDebug.error('API', 'reset-password failed status=${e.response?.statusCode}', e, st);
      throw AuthException(_extractMessage(e, fallback: 'Could not reset password.'));
    }
  }

  /// Change password: PATCH /api/v1/auth/change-password
  /// Authenticated endpoint: Send Authorization: Bearer <JWT_TOKEN>
  /// Body: { "currentPassword": "...", "newPassword": "..." }
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    AuthDebug.log('API', 'PATCH ${ApiConstants.changePassword} body=${AuthDebug.mask(body)}');
    try {
      final response = await _apiService.patch(ApiConstants.changePassword, data: body);
      _throwIfUnsuccessful(_asMap(response.data), fallback: 'Could not change password.');
    } on DioException catch (e, st) {
      AuthDebug.error('API', 'change-password failed status=${e.response?.statusCode}', e, st);
      throw AuthException(_extractMessage(e, fallback: 'Could not change password.'));
    }
  }

  Future<Map<String, dynamic>?> getStoredSession() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) return null;
    final raw = await _storage.getUserData();
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    await StorageService.instance.clearSession();
  }

  Future<void> _persistSession(Map<String, dynamic> response, {String? role}) async {
    final token = response['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.saveAccessToken(token);
    }
    final user = response['data'];
    if (user is Map) {
      final map = Map<String, dynamic>.from(user);
      if (role != null && (map['role'] == null || '${map['role']}'.isEmpty)) {
        map['role'] = AuthConfig.roleForApi(role);
      }
      await _storage.saveUserData(jsonEncode(map));
      await StorageService.instance.saveSession(
        token: token ?? '',
        data: map,
      );
      final savedRole = '${map['role'] ?? role ?? ''}'.toLowerCase();
      if (savedRole == 'seller') {
        String? mongoId;
        for (final k in ['_id', 'id', 'userId']) {
          final v = map[k]?.toString();
          if (v != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(v.trim())) {
            mongoId = v.trim();
            break;
          }
        }
        mongoId ??= map['_id']?.toString() ?? map['id']?.toString() ?? map['sellerId']?.toString();
        if (mongoId != null && mongoId.isNotEmpty) {
          await _storage.saveSellerMongoId(mongoId);
          AuthDebug.log('API', 'seller mongoId saved: $mongoId');
        }
      }
      AuthDebug.log('API', 'session role=$savedRole');
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  void _throwIfUnsuccessful(Map<String, dynamic> data, {required String fallback}) {
    if (data['success'] == false) {
      final message = data['message'];
      throw AuthException(message is String && message.isNotEmpty ? message : fallback);
    }
  }

  String _generatePassword(String phone) {
    final rand = Random.secure();
    final suffix = List.generate(8, (_) => rand.nextInt(10)).join();
    return 'Dn#$phone#$suffix';
  }

  String _extractMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Server took too long to respond. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to the server. Please check your internet connection.';
    }
    return fallback;
  }
}
