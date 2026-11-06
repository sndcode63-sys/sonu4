/// Central validation rules for buyer / seller / partner auth forms.
///
/// Har validator `String?` return karta hai:
///   - `null`  => value theek hai
///   - `String` => user ko dikhane wala error message
///
/// Ye functions `TextFormField.validator` me seedha use ho sakte hain,
/// aur `AppToast` wale manual flows me `Validators.firstError([...])` se.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$",
  );
  static final RegExp _indianMobile = RegExp(r'^[6-9][0-9]{9}$');
  static final RegExp _nameChars = RegExp(r"^[A-Za-z][A-Za-z .'\-]*$");
  static final RegExp _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final RegExp _aadhaar = RegExp(r'^[2-9][0-9]{11}$');
  static final RegExp _gstin =
  RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  static final RegExp _pin = RegExp(r'^[1-9][0-9]{5}$');

  /// Sirf digits rakhta hai (spaces, +91, dashes hata deta hai).
  static String digitsOnly(String? v) => (v ?? '').replaceAll(RegExp(r'\D'), '');

  /// "+91 98765 43210" / "09876543210" -> "9876543210"
  static String normalizeIndianMobile(String? v) {
    var d = digitsOnly(v);
    if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
    if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
    return d;
  }

  static String? name(String? v, {String label = 'Full name'}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Please enter your $label';
    if (s.length < 3) return '$label must be at least 3 characters';
    if (s.length > 60) return '$label is too long';
    if (!_nameChars.hasMatch(s)) {
      return '$label can contain only letters, spaces, . \' and -';
    }
    return null;
  }

  static String? mobile(String? v) {
    final s = normalizeIndianMobile(v);
    if (s.isEmpty) return 'Please enter your mobile number';
    if (s.length != 10) return 'Mobile number must be exactly 10 digits';
    if (!_indianMobile.hasMatch(s)) {
      return 'Enter a valid Indian mobile number (starts with 6, 7, 8 or 9)';
    }
    // 9999999999 / 6666666666 jaise fake numbers
    if (RegExp(r'^(\d)\1{9}$').hasMatch(s)) return 'Enter a valid mobile number';
    return null;
  }

  static String? email(String? v, {bool required = true}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? 'Please enter your email address' : null;
    if (s.length > 254 || s.contains('..') || !_emailRegex.hasMatch(s)) {
      return 'Enter a valid email address (e.g. name@gmail.com)';
    }
    return null;
  }

  /// Backend rule: minimum 8 characters.
  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Please create a password';
    if (s.length < 8) return 'Password must be at least 8 characters';
    if (s.length > 64) return 'Password is too long (max 64 characters)';
    if (s.contains(' ')) return 'Password cannot contain spaces';
    return null;
  }

  static String? otp(String? v, {int length = 6}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Please enter the $length-digit OTP';
    if (!RegExp(r'^[0-9]+$').hasMatch(s)) return 'OTP must contain only digits';
    if (s.length != length) return 'Please enter the complete $length-digit OTP';
    return null;
  }

  static String? required(String? v, String label) {
    if ((v ?? '').trim().isEmpty) return 'Please enter $label';
    return null;
  }

  static String? address(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Please enter your street address';
    if (s.length < 5) return 'Address is too short';
    return null;
  }

  static String? pinCode(String? v) {
    final s = digitsOnly(v);
    if (s.isEmpty) return 'Please enter your 6-digit PIN code';
    if (!_pin.hasMatch(s)) return 'Enter a valid 6-digit PIN code';
    return null;
  }

  static String? pan(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    if (s.isEmpty) return 'Please enter your PAN number';
    if (!_pan.hasMatch(s)) return 'Enter a valid PAN (e.g. ABCDE1234F)';
    return null;
  }

  static String? aadhaar(String? v) {
    final s = digitsOnly(v);
    if (s.isEmpty) return 'Please enter your Aadhaar number';
    if (s.length != 12) return 'Aadhaar number must be exactly 12 digits';
    if (!_aadhaar.hasMatch(s)) return 'Enter a valid Aadhaar number';
    return null;
  }

  /// Optional field: empty allowed, but agar bhara hai to format sahi hona chahiye.
  static String? gstinOptional(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    if (s.isEmpty) return null;
    if (!_gstin.hasMatch(s)) return 'Enter a valid 15-character GSTIN';
    return null;
  }

  static String? reraOptional(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (s.length < 5) return 'Enter a valid RERA registration number';
    return null;
  }

  /// List ke validators ko order me chalata hai, pehla error return karta hai.
  static String? firstError(Iterable<String? Function()> checks) {
    for (final c in checks) {
      final err = c();
      if (err != null) return err;
    }
    return null;
  }
}
