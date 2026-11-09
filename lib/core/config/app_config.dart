/// Single source for app-level contact / link / endpoint values that are NOT
/// served by an API yet. Nothing here is fake data: an empty value means
/// "not configured" and the matching UI is hidden instead of showing a
/// placeholder.
///
/// When the backend exposes an app-config endpoint, populate [AppConfig.update]
/// from that response and every screen picks the values up automatically.
class AppConfig {
  AppConfig._();

  static String supportEmail = 'support@diginiwas.com';

  /// Digits with country code, e.g. '919876543210'. Empty -> call tile hidden.
  static String supportPhone = '';
  static String supportHours = '';

  static String websiteUrl = 'https://diginiwas.com';

  /// Empty -> that social icon is hidden.
  static String instagramUrl = '';
  static String facebookUrl = '';
  static String linkedinUrl = '';
  static String socialHandle = '';

  /// Service-lead admin inbox. Empty -> lead is sent to backend only.
  static String adminLeadEmail = '';

  /// Niwas AI backend.
  static String niwasAiBaseUrl = 'http://187.127.140.51:8585';

  static bool get hasSupportPhone => supportPhone.trim().isNotEmpty;
  static bool get hasSocial =>
      instagramUrl.isNotEmpty || facebookUrl.isNotEmpty || linkedinUrl.isNotEmpty;

  /// Call with the JSON from a backend config endpoint (when available).
  static void update(Map<String, dynamic> json) {
    String s(String k, String current) {
      final v = json[k]?.toString().trim();
      return (v == null || v.isEmpty) ? current : v;
    }

    supportEmail = s('supportEmail', supportEmail);
    supportPhone = s('supportPhone', supportPhone);
    supportHours = s('supportHours', supportHours);
    websiteUrl = s('websiteUrl', websiteUrl);
    instagramUrl = s('instagramUrl', instagramUrl);
    facebookUrl = s('facebookUrl', facebookUrl);
    linkedinUrl = s('linkedinUrl', linkedinUrl);
    socialHandle = s('socialHandle', socialHandle);
    adminLeadEmail = s('adminLeadEmail', adminLeadEmail);
    niwasAiBaseUrl = s('niwasAiBaseUrl', niwasAiBaseUrl);
  }
}
