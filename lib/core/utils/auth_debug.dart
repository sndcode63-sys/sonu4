import 'package:flutter/foundation.dart';

import '../config/auth_config.dart';

/// Tagged console prints for the auth flow.
///
/// Console me `[AUTH]` search karo — har step (Firebase OTP, backend call,
/// forgot/reset password) yahan print hota hai, sensitive cheezein masked.
///
/// Example output:
///   [AUTH][FIREBASE] sendCode -> +919876543210
///   [AUTH][API] POST /v1/auths/firebase-login body={idToken: eyJh…(1043 chars), role: buyer}
///   [AUTH][API] <- 200 {success: true, ...}
class AuthDebug {
  AuthDebug._();

  static void log(String tag, String message) {
    if (!kDebugMode || !AuthConfig.debugPrints) return;
    debugPrint('[AUTH][$tag] $message');
  }

  static void error(String tag, String message, [Object? error, StackTrace? st]) {
    if (!kDebugMode || !AuthConfig.debugPrints) return;
    debugPrint('[AUTH][$tag] ❌ $message');
    if (error != null) debugPrint('[AUTH][$tag]    cause: $error');
    if (st != null) debugPrint('[AUTH][$tag]    stack: ${st.toString().split('\n').take(4).join(' | ')}');
  }

  /// Masks OTP / password / token values so logs are safe to share.
  static Map<String, dynamic> mask(Map<String, dynamic> data) {
    const secret = {
      'otp', 'password', 'newPassword', 'confirmPassword',
      'idToken', 'token', 'resetToken',
    };
    return data.map((k, v) {
      if (secret.contains(k) && v is String) {
        final shown = (k == 'otp' || k.toLowerCase().contains('password'))
            ? '***'
            : '${v.substring(0, v.length < 8 ? v.length : 8)}…(${v.length} chars)';
        return MapEntry(k, shown);
      }
      return MapEntry(k, v);
    });
  }
}
