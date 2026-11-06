/// Central switchboard for the login / OTP flow.
///
/// Sab kuch ek jagah se control hota hai taaki backend ke saath mismatch
/// hone par code hunt na karna pade.
class AuthConfig {
  AuthConfig._();

  /// Master switch for the Firebase phone-login flow.
  static const bool firebaseEnabled = true;

  /// Roles that log in through Firebase (POST /auths/firebase-phone-login).
  /// Teeno roles ab OTP-only (Firebase) login use karte hain.
  /// NOTE: Firebase PDF me sirf Buyer ka example hai — backend seller/partner
  /// role ko bhi /auths/firebase-phone-login par support kare, warna role-mismatch error aayega.
  /// Kisi role ko PDF OTP (/auths/login-otp/*) par rakhna ho to use yahan se hata do.
  static const Set<String> firebaseRoles = {'buyer', 'seller', 'partner'};

  static bool useFirebaseFor(String role) =>
      firebaseEnabled && firebaseRoles.contains(role.trim().toLowerCase());

  /// Firebase ko phone number E.164 format me chahiye.
  static const String countryCode = '+91';

  /// PDF me role lowercase hai ("buyer" / "seller" / "partner").
  /// Agar backend purana "Buyer" format maange to isse false karo.
  static const bool lowercaseRole = true;

  /// Console prints on/off (sirf debug builds me chalte hain).
  static const bool debugPrints = true;

  static String roleForApi(String role) =>
      lowercaseRole ? role.trim().toLowerCase() : role;

  static String e164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    return '$countryCode$digits';
  }
}
