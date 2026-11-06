import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/account_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/auth_debug.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// GetX controller for authentication.
class AuthController extends GetxController {
  AuthController(this._repository, this._locationService);

  final AuthRepository _repository;
  final LocationService _locationService;

  final Rx<AuthState> state = const AuthState().obs;
  final Rx<LocationResult?> lastKnownLocation = Rx<LocationResult?>(null);

  void _emit(AuthState newState) => state.value = newState;

  /// Check if account exists for phone and role before sending Firebase SMS
  Future<bool> checkPhoneAccount({
    required String phone,
    required String role,
  }) async {
    try {
      final res = await _repository.checkPhoneAccount(phone: phone, role: role);
      if (res['success'] == false || res['accountExists'] == false) {
        return false;
      }
      return true;
    } catch (e) {
      _emit(state.value.copyWith(errorMessage: _messageOf(e)));
      return false;
    }
  }

  /// Registers Buyer account
  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    String? password,
    String role = AuthState.defaultRole,
  }) async {
    _emit(state.value.copyWith(
      status: AuthStatus.loading,
      phone: phone,
      role: role,
      clearError: true,
    ));

    final location = await _captureLocation();

    try {
      // Duplicate guard: already registered number par dobara account nahi banega.
      final alreadyRegistered =
      await _repository.isPhoneRegistered(phone: phone, role: role);
      if (alreadyRegistered) {
        throw AuthException(
            'This mobile number is already registered as $role. Please sign in instead.');
      }

      await _repository.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
        location: location,
      );
      await _repository.sendOtp(phone: phone, role: role, checkAccountFirst: false);
      _emit(state.value.copyWith(status: AuthStatus.otpSent, phone: phone, role: role));
      return true;
    } catch (e) {
      _emit(state.value.copyWith(
        status: AuthStatus.error,
        phone: phone,
        role: role,
        errorMessage: _messageOf(e),
      ));
      return false;
    }
  }

  /// Request login OTP with pre-check
  Future<bool> requestLoginOtp({
    required String phone,
    String role = AuthState.defaultRole,
  }) async {
    _emit(state.value.copyWith(
      status: AuthStatus.loading,
      phone: phone,
      role: role,
      clearError: true,
    ));

    AuthDebug.log('CTRL', 'requestLoginOtp phone=$phone role=$role');
    await _captureLocation();

    try {
      await _repository.sendOtp(
        phone: phone,
        role: role,
        checkAccountFirst: true,
      );
      _emit(state.value.copyWith(status: AuthStatus.otpSent, phone: phone, role: role));
      return true;
    } catch (e) {
      _emit(state.value.copyWith(
        status: AuthStatus.error,
        phone: phone,
        role: role,
        errorMessage: _messageOf(e),
      ));
      return false;
    }
  }

  /// Login with Password (Buyer: phone, Seller/Partner: email)
  Future<bool> loginWithPassword({
    required String identifier,
    required String password,
    String role = AuthState.defaultRole,
  }) async {
    _emit(state.value.copyWith(
      status: AuthStatus.loading,
      role: role,
      clearError: true,
    ));

    try {
      final res = await _repository.loginWithPassword(
        identifier: identifier,
        password: password,
        role: role,
      );
      final data = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : null;
      _emit(state.value.copyWith(status: AuthStatus.verified, userData: data, role: role));
      return true;
    } catch (e) {
      _emit(state.value.copyWith(
        status: AuthStatus.error,
        role: role,
        errorMessage: _messageOf(e),
      ));
      return false;
    }
  }

  /// Resends the OTP
  Future<bool> resendOtp() async {
    final currentPhone = state.value.phone;
    if (currentPhone == null) return false;
    try {
      await _repository.resendOtp(phone: currentPhone, role: state.value.role);
      return true;
    } catch (e) {
      _emit(state.value.copyWith(errorMessage: _messageOf(e)));
      return false;
    }
  }

  /// Verifies OTP and logs in
  Future<bool> verifyOtp(String otp) async {
    final currentPhone = state.value.phone;
    if (currentPhone == null) return false;
    AuthDebug.log('CTRL', 'verifyOtp phone=$currentPhone role=${state.value.role}');
    _emit(state.value.copyWith(status: AuthStatus.loading, clearError: true));

    var location = state.value.location;
    location ??= await _captureLocation();

    try {
      final response = await _repository.loginWithOtp(
        phone: currentPhone,
        otp: otp,
        role: state.value.role,
        location: location,
      );
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : null;
      _emit(state.value.copyWith(status: AuthStatus.verified, userData: data));
      return true;
    } catch (e) {
      _emit(state.value.copyWith(status: AuthStatus.error, errorMessage: _messageOf(e)));
      return false;
    }
  }

  Future<void> logout() async {
    await AccountService.instance.clearAllSessionData();
    _emit(const AuthState());
  }

  void resetState() {
    _emit(const AuthState());
  }

  Future<LocationResult?> captureLocation() => _captureLocation();

  Future<LocationResult?> _captureLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      _emit(state.value.copyWith(location: location, clearLocationError: true));
      lastKnownLocation.value = location;
      unawaited(
        Get.find<StorageService>().saveLastKnownCoordinates(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
      return location;
    } on LocationException catch (e) {
      _emit(state.value.copyWith(locationError: e.message));
      return null;
    } catch (_) {
      _emit(state.value.copyWith(locationError: 'Could not fetch your location.'));
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Forgot / Reset password (Common for Buyer / Seller / Partner)
  // ------------------------------------------------------------------

  /// Step 1: email + role -> backend sends reset OTP to email.
  Future<String?> forgotPassword({
    required String email,
    required String role,
  }) async {
    try {
      await _repository.forgotPassword(email: email, role: role);
      return null;
    } catch (e) {
      return _messageOf(e);
    }
  }

  /// Step 2: email + role + otp + new password.
  Future<String?> resetPassword({
    required String email,
    required String role,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _repository.resetPassword(
        email: email,
        role: role,
        otp: otp,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      return _messageOf(e);
    }
  }

  /// Change password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      return _messageOf(e);
    }
  }

  String _messageOf(Object e) =>
      e is AuthException ? e.message : 'Something went wrong. Please try again.';
}
