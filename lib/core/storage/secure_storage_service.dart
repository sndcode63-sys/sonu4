import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';
  static const _fcmTokenKey = 'fcm_token';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveFcmToken(String token) =>
      _storage.write(key: _fcmTokenKey, value: token);

  Future<String?> getFcmToken() => _storage.read(key: _fcmTokenKey);


  Future<void> saveUserData(String userJson) =>
      _storage.write(key: _userDataKey, value: userJson);

  Future<String?> getUserData() => _storage.read(key: _userDataKey);

  Future<String?> getBuyerId() async {
    final userDataStr = await getUserData();
    if (userDataStr != null && userDataStr.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(userDataStr);
        return data['id']?.toString() ??
            data['buyerId']?.toString() ??
            data['_id']?.toString();
      } catch (_) {}
    }
    return null;
  }

  static const _sellerMongoIdKey = 'seller_mongo_id';

  Future<void> saveSellerMongoId(String id) =>
      _storage.write(key: _sellerMongoIdKey, value: id);

  bool _isValidMongoId(String? s) =>
      s != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(s.trim());

  Future<String?> getSellerMongoId() async {
    final direct = await _storage.read(key: _sellerMongoIdKey);
    if (direct != null && _isValidMongoId(direct)) return direct.trim();
    final userDataStr = await getUserData();
    if (userDataStr != null && userDataStr.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(userDataStr);
        for (final k in ['_id', 'id', 'userId']) {
          final v = data[k]?.toString();
          if (v != null && _isValidMongoId(v)) return v.trim();
        }
        if (direct != null && direct.isNotEmpty) return direct;
        for (final k in ['_id', 'id', 'sellerId', 'userId']) {
          final v = data[k]?.toString();
          if (v != null && v.isNotEmpty) return v;
        }
      } catch (_) {}
    }
    return direct;
  }

  // -------------------------------------------------------------------------
  // Pending seller KYC registration (so the flow survives an app restart).
  // Per the API guide: "Persist data.applicationId. It is required in every
  // registration verification and resend request."
  // -------------------------------------------------------------------------
  static const _pendingApplicationIdKey = 'pending_seller_application_id';
  static const _pendingApplicationStepKey = 'pending_seller_application_step';
  static const _pendingApplicationEmailKey = 'pending_seller_application_email';
  static const _pendingApplicationPhoneKey = 'pending_seller_application_phone';

  /// [step] should be one of: 'VERIFY_EMAIL', 'VERIFY_PHONE'.
  Future<void> savePendingSellerApplication({
    required String applicationId,
    required String step,
    String? email,
    String? phone,
  }) async {
    await _storage.write(key: _pendingApplicationIdKey, value: applicationId);
    await _storage.write(key: _pendingApplicationStepKey, value: step);
    if (email != null) {
      await _storage.write(key: _pendingApplicationEmailKey, value: email);
    }
    if (phone != null) {
      await _storage.write(key: _pendingApplicationPhoneKey, value: phone);
    }
  }

  Future<Map<String, String?>> getPendingSellerApplication() async {
    return {
      'applicationId': await _storage.read(key: _pendingApplicationIdKey),
      'step': await _storage.read(key: _pendingApplicationStepKey),
      'email': await _storage.read(key: _pendingApplicationEmailKey),
      'phone': await _storage.read(key: _pendingApplicationPhoneKey),
    };
  }

  Future<void> clearPendingSellerApplication() async {
    await _storage.delete(key: _pendingApplicationIdKey);
    await _storage.delete(key: _pendingApplicationStepKey);
    await _storage.delete(key: _pendingApplicationEmailKey);
    await _storage.delete(key: _pendingApplicationPhoneKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _sellerMongoIdKey);
    await clearPendingSellerApplication();
  }

  Future<void> deleteAll() => _storage.deleteAll();

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  Future<String?> read({required String key}) => _storage.read(key: key);

  Future<void> delete({required String key}) => _storage.delete(key: key);
}
