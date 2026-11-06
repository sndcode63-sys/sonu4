import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/auth_config.dart';
import '../utils/auth_debug.dart';

/// Friendly error for Firebase phone-auth failures.
class FirebaseOtpException implements Exception {
  FirebaseOtpException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

/// Wraps FirebaseAuth phone verification so the repository only deals with
/// three calls: [sendCode] -> [resendCode] -> [verifyCode] (returns idToken).
class FirebasePhoneAuthService {
  FirebasePhoneAuthService._();
  static final FirebasePhoneAuthService instance = FirebasePhoneAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;
  String? _phone;
  PhoneAuthCredential? _autoCredential; // Android instant/auto verification

  /// Sends the SMS. Completes when Firebase says "code sent" (or fails).
  Future<void> sendCode(String phone, {bool isResend = false}) async {
    final e164 = AuthConfig.e164(phone);
    AuthDebug.log('FIREBASE',
        '${isResend ? 'resendCode' : 'sendCode'} -> $e164 (resendToken=${isResend ? _resendToken : null})');

    if (!isResend) {
      _verificationId = null;
      _resendToken = null;
      _autoCredential = null;
    }
    _phone = phone;

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: isResend ? _resendToken : null,
      verificationCompleted: (PhoneAuthCredential credential) {
        AuthDebug.log('FIREBASE', 'verificationCompleted (auto-verified on device)');
        _autoCredential = credential;
      },
      verificationFailed: (FirebaseAuthException e) {
        AuthDebug.error('FIREBASE', 'verificationFailed code=${e.code}', e.message);
        if (!completer.isCompleted) {
          completer.completeError(
              FirebaseOtpException(_friendly(e), code: e.code));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        AuthDebug.log('FIREBASE',
            'codeSent verificationId=${verificationId.substring(0, 6)}… resendToken=$resendToken');
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        AuthDebug.log('FIREBASE', 'codeAutoRetrievalTimeout (user must type OTP)');
        _verificationId = verificationId;
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 70),
      onTimeout: () => throw FirebaseOtpException(
          'OTP request timed out. Please check your internet and try again.'),
    );
  }

  Future<void> resendCode() async {
    if (_phone == null) {
      throw FirebaseOtpException('Please request an OTP first.');
    }
    return sendCode(_phone!, isResend: true);
  }

  /// Verifies the typed OTP with Firebase and returns a fresh Firebase idToken.
  Future<String> verifyCode(String smsCode) async {
    AuthDebug.log('FIREBASE', 'verifyCode (otp length=${smsCode.length})');

    final PhoneAuthCredential credential = _autoCredential ??
        (() {
          if (_verificationId == null) {
            throw FirebaseOtpException(
                'OTP session expired. Please request a new OTP.');
          }
          return PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: smsCode,
          );
        })();

    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw FirebaseOtpException('Verification failed. Please try again.');
      }
      // Security: jis number pe OTP gaya, wahi number verify hona chahiye.
      // (Auto-verified credential ya purana session kisi aur number ka na ho.)
      final expected = _phone == null ? null : AuthConfig.e164(_phone!);
      final verifiedPhone = user.phoneNumber;
      if (expected != null &&
          verifiedPhone != null &&
          verifiedPhone.isNotEmpty &&
          verifiedPhone != expected) {
        AuthDebug.error('FIREBASE',
            'phone mismatch expected=$expected got=$verifiedPhone', null);
        await signOut();
        throw FirebaseOtpException(
            'Verified number does not match the number you entered. Please try again.');
      }
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseOtpException('Could not get a verification token.');
      }
      AuthDebug.log('FIREBASE',
          'signIn OK uid=${user.uid} phone=${user.phoneNumber} idToken=${idToken.substring(0, 8)}…(${idToken.length} chars)');
      // ⚠️ SIRF TESTING (Postman) KE LIYE — release se pehle yeh block hata do.
      // Poora idToken console me print hoga aur clipboard me copy ho jayega.
      if (kDebugMode) {
        debugPrint('[AUTH][FIREBASE] FULL_ID_TOKEN=$idToken');
        await Clipboard.setData(ClipboardData(text: idToken));
        AuthDebug.log('FIREBASE', 'idToken clipboard me copy ho gaya -> Postman me paste karo');
      }
      _autoCredential = null;
      return idToken;
    } on FirebaseAuthException catch (e) {
      AuthDebug.error('FIREBASE', 'signInWithCredential failed code=${e.code}', e.message);
      throw FirebaseOtpException(_friendly(e), code: e.code);
    }
  }

  /// True jab tak ek OTP session (verificationId) active hai.
  bool get hasActiveSession => _verificationId != null || _autoCredential != null;

  /// Naya number / naya flow shuru karne se pehle purana OTP state saaf karo.
  void reset() {
    _verificationId = null;
    _resendToken = null;
    _phone = null;
    _autoCredential = null;
  }

  /// Firebase session sirf OTP proof ke liye hai — app ka login backend JWT se
  /// chalta hai, isliye Firebase user ko turant sign-out kar dete hain.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AuthDebug.log('FIREBASE', 'signed out of Firebase (backend JWT is the session)');
    } catch (_) {}
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please check the code and try again.';
      case 'session-expired':
      case 'code-expired':
        return 'OTP expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a while and try again.';
      case 'quota-exceeded':
        return 'SMS limit reached for now. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check and retry.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
      case 'invalid-app-credential':
        return 'App is not authorised for phone login (SHA-1/SHA-256 missing in Firebase). [${e.code}]';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled in Firebase Console.';
      default:
        return e.message ?? 'OTP verification failed. [${e.code}]';
    }
  }
}
