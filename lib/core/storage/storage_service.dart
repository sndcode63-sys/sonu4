import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight app-preferences store (non-sensitive data only — tokens
/// live in [SecureStorageService]). Backed by `shared_preferences`.
///
/// Matches this login/register response shape:
/// {
///   success: true,
///   token: "...",
///   data: {
///     id, sellerId, partnerId, name, phone, role, partnerType, location
///   }
/// }
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // -----------------------------------------------------------------
  // SAVE — call this right after a successful login-otp / login-password
  // / register response. Pass the `data` map from the API response.
  // -----------------------------------------------------------------
  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.token, token);
    await _writeOrRemove(prefs, StorageKeys.userId, data['id']?.toString());
    // buyer flow me userId == buyerId
    await _writeOrRemove(prefs, StorageKeys.buyerId, data['id']?.toString());
    await _writeOrRemove(prefs, StorageKeys.sellerId, data['sellerId']?.toString());
    await _writeOrRemove(prefs, StorageKeys.partnerId, data['partnerId']?.toString());
    await _writeOrRemove(prefs, StorageKeys.name, data['name']?.toString());
    await _writeOrRemove(prefs, StorageKeys.phone, data['phone']?.toString());
    await _writeOrRemove(prefs, StorageKeys.role, data['role']?.toString());
    await _writeOrRemove(prefs, StorageKeys.partnerType, data['partnerType']?.toString());
    if (data['location'] != null) {
      await prefs.setString(StorageKeys.location, jsonEncode(data['location']));
    }
    await prefs.setBool(StorageKeys.isLoggedIn, true);
  }

  Future<String?> getBuyerId() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.buyerId) ?? prefs.getString(StorageKeys.userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.userId);
  }

  /// Persists the last device GPS fix (captured on login/registration via
  /// [LocationService]) so the rest of the app — e.g. "properties near
  /// me" — can reuse it without asking for permission again every time.
  Future<void> saveLastKnownCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await _prefs;
    await prefs.setDouble(StorageKeys.lastLat, latitude);
    await prefs.setDouble(StorageKeys.lastLng, longitude);
  }

  Future<({double latitude, double longitude})?> getLastKnownCoordinates() async {
    final prefs = await _prefs;
    final lat = prefs.getDouble(StorageKeys.lastLat);
    final lng = prefs.getDouble(StorageKeys.lastLng);
    if (lat == null || lng == null) return null;
    return (latitude: lat, longitude: lng);
  }

  Future<Map<String, dynamic>?> getPendingPartnerApplication() async {
    final prefs = await _prefs;
    final raw = prefs.getString(StorageKeys.pendingPartnerApplication);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }


  // -----------------------------------------------------------------
  // VISIT TRACKING — locally remembers which visit IDs belong to this
  // device/user so ScheduledVisitsScreen can look up their live status
  // one by one (no "list my visits" endpoint was provided).
  // -----------------------------------------------------------------
  Future<void> addVisitId(String visitId) async {
    if (visitId.isEmpty) return;
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.visitIds) ?? <String>[];
    if (!list.contains(visitId)) {
      list.insert(0, visitId); // newest first
      await prefs.setStringList(StorageKeys.visitIds, list);
    }
  }

  Future<List<String>> getVisitIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(StorageKeys.visitIds) ?? <String>[];
  }

  Future<void> removeVisitId(String visitId) async {
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.visitIds) ?? <String>[];
    list.remove(visitId);
    await prefs.setStringList(StorageKeys.visitIds, list);
  }

  // -----------------------------------------------------------------
  // RECENTLY VIEWED PROPERTIES — no "recently viewed" API exists yet, so
  // this tracks property IDs locally (newest first, capped) purely from
  // in-app navigation. Call [addRecentlyViewedId] from Property Details
  // onInit; read it back for the Profile screen's "Recently Viewed" stat.
  // -----------------------------------------------------------------
  static const int _recentlyViewedCap = 50;

  Future<void> addRecentlyViewedId(String propertyId) async {
    if (propertyId.isEmpty) return;
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.recentlyViewedIds) ?? <String>[];
    list.remove(propertyId); // move to front if already present
    list.insert(0, propertyId);
    if (list.length > _recentlyViewedCap) list.removeRange(_recentlyViewedCap, list.length);
    await prefs.setStringList(StorageKeys.recentlyViewedIds, list);
  }

  Future<List<String>> getRecentlyViewedIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(StorageKeys.recentlyViewedIds) ?? <String>[];
  }

  Future<void> addRecentlyViewedProperty(Map<String, dynamic> propertyData) async {
    try {
      final id = propertyData['_id']?.toString() ??
          propertyData['propertyId']?.toString() ??
          propertyData['id']?.toString() ??
          '';
      if (id.isNotEmpty) {
        await addRecentlyViewedId(id);
      }

      final prefs = await _prefs;
      final rawList = prefs.getStringList(StorageKeys.recentlyViewedProperties) ?? <String>[];
      final List<Map<String, dynamic>> list = [];

      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final existingId = decoded['_id']?.toString() ??
                decoded['propertyId']?.toString() ??
                decoded['id']?.toString() ??
                '';
            if (id.isEmpty || existingId != id) {
              list.add(decoded);
            }
          }
        } catch (_) {}
      }

      // Stamp with viewedAt timestamp
      final toSave = Map<String, dynamic>.from(propertyData);
      toSave['viewedAt'] = DateTime.now().toIso8601String();
      list.insert(0, toSave);

      if (list.length > _recentlyViewedCap) {
        list.removeRange(_recentlyViewedCap, list.length);
      }

      final encodedList = list.map((m) => jsonEncode(m)).toList();
      await prefs.setStringList(StorageKeys.recentlyViewedProperties, encodedList);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getRecentlyViewedProperties() async {
    try {
      final prefs = await _prefs;
      final rawList = prefs.getStringList(StorageKeys.recentlyViewedProperties) ?? <String>[];
      final List<Map<String, dynamic>> list = [];

      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            list.add(decoded);
          }
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearRecentlyViewedProperties() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.recentlyViewedProperties);
    await prefs.remove(StorageKeys.recentlyViewedIds);
  }

  // -----------------------------------------------------------------
  // MY ENQUIRIES — same idea: no "my leads/enquiries" list endpoint
  // exists yet, so this counts leads the buyer has generated in-app
  // (see LeadController.createLeadFromProperty success handlers).
  // -----------------------------------------------------------------
  Future<void> addEnquiryPropertyId(String propertyId) async {
    if (propertyId.isEmpty) return;
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.enquiryIds) ?? <String>[];
    if (!list.contains(propertyId)) {
      list.insert(0, propertyId);
      await prefs.setStringList(StorageKeys.enquiryIds, list);
    }
  }

  Future<List<String>> getEnquiryIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(StorageKeys.enquiryIds) ?? <String>[];
  }

  // -----------------------------------------------------------------
  // LOCAL PROFILE AVATAR — there is no "update profile photo" backend
  // endpoint in this codebase yet, so a picked photo is persisted here
  // (local file path) and shown with priority over the network avatar
  // until a real upload endpoint exists to sync it server-side.
  // -----------------------------------------------------------------
  Future<void> saveLocalAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.localAvatarPath, path);
  }

  Future<String?> get localAvatarPath async => (await _prefs).getString(StorageKeys.localAvatarPath);

  Future<void> saveSellerLocalAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.sellerLocalAvatarPath, path);
  }

  Future<String?> get sellerLocalAvatarPath async => (await _prefs).getString(StorageKeys.sellerLocalAvatarPath);

  // -----------------------------------------------------------------
  // READ helpers
  // -----------------------------------------------------------------
  Future<String?> get token async => (await _prefs).getString(StorageKeys.token);
  Future<String?> get userId async => (await _prefs).getString(StorageKeys.userId);
  Future<String?> get buyerId async => (await _prefs).getString(StorageKeys.buyerId);
  Future<String?> get sellerId async => (await _prefs).getString(StorageKeys.sellerId);
  Future<String?> get partnerId async => (await _prefs).getString(StorageKeys.partnerId);
  Future<String?> get name async => (await _prefs).getString(StorageKeys.name);
  Future<String?> get phone async => (await _prefs).getString(StorageKeys.phone);
  Future<String?> get role async => (await _prefs).getString(StorageKeys.role);
  Future<String?> get partnerType async => (await _prefs).getString(StorageKeys.partnerType);
  Future<bool> get isLoggedIn async => (await _prefs).getBool(StorageKeys.isLoggedIn) ?? false;
  Future<Map<String, dynamic>?> get location async {
    final prefs = await _prefs;
    final raw = prefs.getString(StorageKeys.location);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------------
  // CLEAR — call this on logout
  // -----------------------------------------------------------------
  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.token);
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.buyerId);
    await prefs.remove(StorageKeys.sellerId);
    await prefs.remove(StorageKeys.partnerId);
    await prefs.remove(StorageKeys.name);
    await prefs.remove(StorageKeys.phone);
    await prefs.remove(StorageKeys.role);
    await prefs.remove(StorageKeys.partnerType);
    await prefs.remove(StorageKeys.location);
    await prefs.remove(StorageKeys.cachedHomeFeed);
    await prefs.setBool(StorageKeys.isLoggedIn, false);
    // Deliberately keep lastLat/lastLng — still useful as a default
    // map center even after logout.
    // Deliberately keep visitIds too — visit history isn't tied to the
    // active session in this app's flows.
  }

  // -----------------------------------------------------------------
  // HOME FEED CACHE — instant render without loader when revisiting/app closed
  // -----------------------------------------------------------------
  Future<void> saveCachedHomeFeed(String jsonStr) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.cachedHomeFeed, jsonStr);
  }

  Future<Map<String, dynamic>?> getCachedHomeFeed() async {
    final prefs = await _prefs;
    final raw = prefs.getString(StorageKeys.cachedHomeFeed);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeOrRemove(SharedPreferences prefs, String key, String? value) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  /// Pending partner KYC (before login). Used to resume OTP after 409.
  Future<void> savePendingPartnerApplication(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(
      StorageKeys.pendingPartnerApplication,
      jsonEncode(data),
    );
  }
  Future<void> clearPendingPartnerApplication() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.pendingPartnerApplication);
  }

  // -----------------------------------------------------------------
  // NOTIFICATION READ TRACKING
  // -----------------------------------------------------------------
  Future<List<String>> getReadNotificationIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(StorageKeys.readNotificationIds) ?? <String>[];
  }

  Future<void> markNotificationIdAsRead(String id) async {
    if (id.isEmpty) return;
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.readNotificationIds) ?? <String>[];
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(StorageKeys.readNotificationIds, list);
    }
  }

  // Cleared (deleted from UI) notification ids - dobara list me nahi aayenge
  Future<List<String>> getClearedNotificationIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(StorageKeys.clearedNotificationIds) ?? <String>[];
  }

  Future<void> addClearedNotificationIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await _prefs;
    final set = (prefs.getStringList(StorageKeys.clearedNotificationIds) ?? <String>[]).toSet();
    set.addAll(ids);
    await prefs.setStringList(StorageKeys.clearedNotificationIds, set.toList());
  }

  Future<void> markAllNotificationIdsAsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await _prefs;
    final list = (prefs.getStringList(StorageKeys.readNotificationIds) ?? <String>[]).toSet();
    list.addAll(ids);
    await prefs.setStringList(StorageKeys.readNotificationIds, list.toList());
  }

  Future<bool> isPushNotificationShown(String id) async {
    if (id.isEmpty) return true;
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.pushedNotificationIds) ?? <String>[];
    return list.contains(id);
  }

  Future<void> markPushNotificationShown(String id) async {
    if (id.isEmpty) return;
    final prefs = await _prefs;
    final list = prefs.getStringList(StorageKeys.pushedNotificationIds) ?? <String>[];
    if (!list.contains(id)) {
      list.add(id);
      if (list.length > 250) {
        list.removeRange(0, list.length - 250);
      }
      await prefs.setStringList(StorageKeys.pushedNotificationIds, list);
    }
  }

  // -----------------------------------------------------------------
  // NIWAS AI CHAT SESSIONS & HISTORY
  // -----------------------------------------------------------------
  static const String _keyAiSessions = 'saved_ai_sessions';

  Future<void> saveAiSession({required String sessionId, required String title}) async {
    if (sessionId.trim().isEmpty) return;
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyAiSessions) ?? [];
    final list = raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();

    list.removeWhere((item) => item['id'] == sessionId);
    list.insert(0, {
      'id': sessionId,
      'title': title.trim().isEmpty ? 'Niwas AI Chat' : title.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final trimmed = list.take(30).map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_keyAiSessions, trimmed);
  }

  Future<List<Map<String, dynamic>>> getSavedAiSessions() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyAiSessions) ?? [];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> removeAiSession(String sessionId) async {
    if (sessionId.trim().isEmpty) return;
    final prefs = await _prefs;
    final raw = prefs.getStringList(_keyAiSessions) ?? [];
    final list = raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    list.removeWhere((item) => item['id'] == sessionId);
    await prefs.setStringList(_keyAiSessions, list.map((m) => jsonEncode(m)).toList());
  }

  // -----------------------------------------------------------------
  // PROPERTY DRAFT (Save & Continue draft persistence)
  // -----------------------------------------------------------------
  Future<void> savePropertyDraft(Map<String, dynamic> draftData) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.propertyDraft, jsonEncode(draftData));
  }

  Future<Map<String, dynamic>?> getPropertyDraft() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(StorageKeys.propertyDraft);
      if (raw != null && raw.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearPropertyDraft() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.propertyDraft);
  }

  // -----------------------------------------------------------------
  // SELLER CREATED PROPERTIES (persisted locally so newly added listings appear immediately)
  // -----------------------------------------------------------------
  Future<void> saveSellerCreatedProperty(Map<String, dynamic> propertyData) async {
    try {
      final pId = (propertyData['_id'] ?? propertyData['id'] ?? propertyData['propertyId'])?.toString();
      if (pId == null || pId.isEmpty) return;
      final prefs = await _prefs;
      final raw = prefs.getString(StorageKeys.sellerCreatedProperties);
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw) as List;
        } catch (_) {}
      }
      list.removeWhere((item) {
        if (item is Map) {
          final id = (item['_id'] ?? item['id'] ?? item['propertyId'])?.toString();
          return id == pId;
        }
        return false;
      });
      list.insert(0, propertyData);
      if (list.length > 50) list.removeRange(50, list.length);
      await prefs.setString(StorageKeys.sellerCreatedProperties, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getSellerCreatedProperties() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(StorageKeys.sellerCreatedProperties);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}

class StorageKeys {
  StorageKeys._();

  static const String token = 'auth_token';
  static const String userId = 'user_id';
  static const String buyerId = 'buyer_id';
  static const String sellerId = 'seller_id';
  static const String partnerId = 'partner_id';
  static const String name = 'user_name';
  static const String phone = 'user_phone';
  static const String role = 'user_role';
  static const String partnerType = 'partner_type';
  static const String location = 'user_location';
  static const String isLoggedIn = 'is_logged_in';
  static const String lastLat = 'last_lat';
  static const String lastLng = 'last_lng';
  static const String visitIds = 'visit_ids';
  static const String recentlyViewedIds = 'recently_viewed_property_ids';
  static const String recentlyViewedProperties = 'recently_viewed_properties_data';
  static const String enquiryIds = 'enquiry_property_ids';
  static const String localAvatarPath = 'local_avatar_path';
  static const String sellerLocalAvatarPath = 'seller_local_avatar_path';
  static const String pendingPartnerApplication = 'pending_partner_application';
  static const String readNotificationIds = 'read_notification_ids';
  static const String clearedNotificationIds = 'cleared_notification_ids';
  static const String pushedNotificationIds = 'pushed_notification_ids';
  static const String cachedHomeFeed = 'cached_home_feed_json';
  static const String propertyDraft = 'saved_property_draft_json';
  static const String sellerCreatedProperties = 'seller_created_properties_json';
}