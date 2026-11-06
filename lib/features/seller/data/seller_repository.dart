import '../../partner/models/partner_models.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/constants/api_constants.dart';
import 'property_payload_builder.dart';
import '../models/seller_model.dart';
import '../../buyer/models/buyer_dashboard_model.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/app_logger.dart';

class SellerException implements Exception {
  final String message;
  // Raw error payload from the backend (e.g. { "applicationStatus": "..." }),
  // when the failing response included one. Lets the UI react to specific
  // error shapes (like "application not approved yet") instead of just
  // showing text.
  final Map<String, dynamic>? data;
  SellerException(this.message, {this.data});

  @override
  String toString() => message;
}

class SellerRepository {
  final ApiService _apiService;

  SellerRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  // ===========================================================================
  // 1. SELLER AUTHENTICATION & LOGIN
  // ===========================================================================

  /// Send login OTP to seller email: POST /api/sellers/auth/send-login-otp
  Future<Map<String, dynamic>> sendLoginOtp({required String email}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.sendSellerLoginOtp,
        data: {'email': email},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not send OTP to $email');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Send Seller Login OTP failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to send OTP.'));
    }
  }

  /// Seller Login with OTP: POST /api/sellers/auth/login-with-otp
  Future<Map<String, dynamic>> loginWithOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.sellerLoginWithOtp,
        data: {'email': email, 'otp': otp},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Invalid OTP or login failed.');
      final token = data['token'] ?? (data['data'] is Map ? data['data']['token'] : null);
      if (token != null && token is String && token.isNotEmpty) {
        await SecureStorageService.instance.saveAccessToken(token);
      }
      final sellerData = data['data'];
      if (sellerData is Map) {
        final mongoId = sellerData['_id'] ?? sellerData['id'];
        if (mongoId != null && mongoId is String && mongoId.isNotEmpty) {
          await SecureStorageService.instance.saveSellerMongoId(mongoId);
        }
      }
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Seller Login with OTP failed', e, st);
      throw SellerException(
        _extractMessage(e, fallback: 'Login failed. Please check OTP.'),
        data: _extractErrorData(e),
      );
    }
  }

  /// Seller Login with Password: POST /api/sellers/auth/login
  Future<Map<String, dynamic>> loginWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.sellerLogin,
        data: {'email': email, 'password': password},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Login failed. Please check your credentials.');
      final token = data['token'] ?? (data['data'] is Map ? data['data']['token'] : null);
      if (token != null && token is String && token.isNotEmpty) {
        await SecureStorageService.instance.saveAccessToken(token);
      }
      final sellerData = data['data'];
      if (sellerData is Map) {
        final mongoId = sellerData['_id'] ?? sellerData['id'];
        if (mongoId != null && mongoId is String && mongoId.isNotEmpty) {
          await SecureStorageService.instance.saveSellerMongoId(mongoId);
        }
      }
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Seller Password Login failed', e, st);
      throw SellerException(
        _extractMessage(e, fallback: 'Invalid email or password.'),
        data: _extractErrorData(e),
      );
    }
  }

  /// Change Seller Password: PATCH /api/sellers/auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      dynamic response;
      try {
        response = await _apiService.patch(
          ApiConstants.changeSellerPassword,
          data: {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          },
        );
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404 || dioErr.response?.statusCode == 405) {
          response = await _apiService.put(
            ApiConstants.changeSellerPassword,
            data: {
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            },
          );
        } else {
          rethrow;
        }
      }
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not change password.');
    } on DioException catch (e, st) {
      AppLogger.e('Change Seller Password failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Password update failed.'));
    }
  }

  // ===========================================================================
  // 2. SELLER APPLICATION REGISTRATION (no KYC/ID documents per API guide)
  // ===========================================================================

  /// Create Seller Application: POST /api/v1/sellers/applications/register
  /// Body matches the API guide exactly — plain registration, no KYC/ID
  /// documents are collected or sent.
  Future<SellerApplicationModel> registerSellerApplication({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String country,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final jsonPayload = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'country': country,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await _apiService.post(
        ApiConstants.registerSellerApplication,
        data: jsonPayload,
      );

      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Seller registration failed.');

      final resData = data['data'] is Map ? data['data'] : data;
      return SellerApplicationModel.fromJson(resData);
    } on DioException catch (e, st) {
      AppLogger.e('Register Seller Application failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Seller application registration failed.'));
    }
  }

  /// Verify Seller Email OTP: POST /api/sellers/applications/verify-email
  Future<void> verifySellerEmailOtp({
    required String applicationId,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.verifySellerEmailOtp,
        data: {'applicationId': applicationId, 'otp': otp},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Email OTP verification failed.');
    } on DioException catch (e, st) {
      AppLogger.e('Verify Seller Email OTP failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Invalid Email OTP.'));
    }
  }

  /// Verify Seller Phone via Firebase ID Token or OTP: POST /api/v1/sellers/applications/verify-phone
  /// Body per API Guide: { "applicationId": "...", "idToken": "..." }
  Future<Map<String, dynamic>> verifySellerPhoneOtp({
    required String applicationId,
    String? otp,
    String? idToken,
  }) async {
    try {
      // Raw SMS OTP kabhi backend ko nahi jaata — sirf Firebase idToken (API guide).
      if (idToken == null || idToken.trim().isEmpty) {
        throw SellerException('Phone verification failed. Please verify the SMS OTP again.');
      }
      final payload = <String, dynamic>{
        'applicationId': applicationId,
        'idToken': idToken.trim(),
      };

      final response = await _apiService.post(
        ApiConstants.verifySellerPhoneOtp,
        data: payload,
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Phone verification failed.');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Verify Seller Phone failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Invalid Phone verification.'));
    }
  }

  /// Resend Seller Email OTP: POST /api/sellers/applications/resend-email-otp
  Future<void> resendSellerEmailOtp({required String applicationId}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.resendSellerEmailOtp,
        data: {'applicationId': applicationId},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Resend email OTP failed.');
    } on DioException catch (e, st) {
      AppLogger.e('Resend Seller Email OTP failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to resend email OTP.'));
    }
  }

  /// Resend Seller Phone OTP: POST /api/sellers/applications/resend-phone-otp
  Future<void> resendSellerPhoneOtp({required String applicationId}) async {
    try {
      final response = await _apiService.post(
        ApiConstants.resendSellerPhoneOtp,
        data: {'applicationId': applicationId},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Resend phone OTP failed.');
    } on DioException catch (e, st) {
      AppLogger.e('Resend Seller Phone OTP failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to resend phone OTP.'));
    }
  }

  // ===========================================================================
  // 3. SELLER PROFILE, SUMMARY & PROPERTIES
  // ===========================================================================

  static bool _isValidMongoId(String? s) =>
      s != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(s.trim());

  Future<String> _resolveMongoSellerId(String id) async {
    if (_isValidMongoId(id)) return id.trim();
    try {
      final rawUser = await SecureStorageService.instance.getUserData();
      if (rawUser != null && rawUser.isNotEmpty) {
        final uMap = Map<String, dynamic>.from(jsonDecode(rawUser) as Map);
        for (final k in ['_id', 'id', 'userId']) {
          final v = uMap[k]?.toString();
          if (v != null && _isValidMongoId(v)) return v.trim();
        }
      }
    } catch (_) {}
    return id.trim();
  }

  /// Get Seller Profile by ID: GET /api/v1/sellers/:id
  Future<SellerModel> getSellerById(String id) async {
    try {
      final resolvedId = await _resolveMongoSellerId(id);
      if (!_isValidMongoId(resolvedId)) {
        throw SellerException('Invalid seller ID format: $id');
      }
      final response = await _apiService.get(ApiConstants.getSellerById(resolvedId));
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not fetch seller details.');

      final sellerMap = (data['data'] is Map && data['data']['seller'] != null)
          ? data['data']['seller']
          : (data['data'] ?? data);
      return SellerModel.fromJson(sellerMap);
    } on DioException catch (e, st) {
      AppLogger.e('Get Seller By ID failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to fetch seller profile.'));
    }
  }

  /// Get Seller Summary Stats: GET /api/v1/sellers/:id/summary
  Future<SellerSummaryModel> getSellerSummary(String id) async {
    try {
      final resolvedId = await _resolveMongoSellerId(id);
      if (!_isValidMongoId(resolvedId)) {
        return SellerSummaryModel.fromJson({});
      }
      final response = await _apiService.get(ApiConstants.getSellerSummary(resolvedId));
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not fetch seller summary.');

      final statsMap = data['data'] is Map ? data['data'] : {};
      return SellerSummaryModel.fromJson(statsMap);
    } on DioException catch (e, st) {
      AppLogger.e('Get Seller Summary failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to load seller summary.'));
    }
  }

  /// Get Seller Properties: queries /v1/sellers/:id/properties,
  /// /newproperties/partner/:id, /newproperties/user/:id, etc., and merges locally created properties.
  Future<List<dynamic>> getSellerProperties(String id) async {
    final combined = <dynamic>[];
    final seenIds = <String>{};

    void addProperties(dynamic rawList) {
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            final key = (item['_id'] ?? item['id'] ?? item['propertyId'])?.toString();
            if (key != null && key.isNotEmpty) {
              if (seenIds.add(key)) {
                combined.add(item);
              }
            } else {
              combined.add(item);
            }
          }
        }
      }
    }

    // Collect all candidate IDs for the logged-in user
    final idsToQuery = <String>{};
    if (id.isNotEmpty) idsToQuery.add(id);
    try {
      final rawUser = await SecureStorageService.instance.getUserData();
      if (rawUser != null && rawUser.isNotEmpty) {
        final uMap = Map<String, dynamic>.from(jsonDecode(rawUser) as Map);
        for (final k in ['_id', 'id', 'userId', 'partnerId', 'sellerId']) {
          final v = uMap[k]?.toString();
          if (v != null && v.isNotEmpty) idsToQuery.add(v);
        }
      }
    } catch (_) {}

    // 1. Fetch from /v1/sellers/:id (seller profile endpoint returns data.properties)
    // Only query /v1/sellers for valid 24-char hex MongoDB ObjectIds!
    for (final qId in idsToQuery) {
      if (!_isValidMongoId(qId)) continue;
      try {
        final response = await _apiService.get(ApiConstants.getSellerById(qId));
        final data = _asMap(response.data);
        final d = data['data'];
        if (d is Map && d['properties'] is List) {
          addProperties(d['properties']);
        } else if (data['properties'] is List) {
          addProperties(data['properties']);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          AppLogger.w('Get Seller profile properties (/v1/sellers/$qId) notice: $e');
        }
      } catch (_) {}

      // Also try /v1/sellers/:id/properties if server supports distinct sub-route
      try {
        final response = await _apiService.get(ApiConstants.getSellerProperties(qId));
        final data = _asMap(response.data);
        final raw = data['data'];
        if (raw is List) {
          addProperties(raw);
        } else if (raw is Map) {
          addProperties(raw['properties'] ?? raw['results'] ?? raw['items']);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          AppLogger.w('Get Seller Properties (/v1/sellers/$qId/properties) notice: $e');
        }
      } catch (_) {}
    }

    // 2. Fetch from /newproperties/partner/:id
    for (final qId in idsToQuery) {
      try {
        final response = await _apiService.get('${ApiConstants.newPropertiesByPartner}/$qId');
        final data = _asMap(response.data);
        final raw = data['data'];
        if (raw is List) {
          addProperties(raw);
        } else if (raw is Map) {
          addProperties(raw['properties'] ?? raw['results'] ?? raw['items']);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          AppLogger.w('Get Seller Properties (/newproperties/partner/$qId) notice: $e');
        }
      } catch (_) {}
    }

    // 3. Merge locally created properties so newly submitted listings appear immediately
    try {
      final localCreated = await StorageService.instance.getSellerCreatedProperties();
      for (final lp in localCreated) {
        final key = (lp['_id'] ?? lp['id'] ?? lp['propertyId'])?.toString();
        if (key != null && key.isNotEmpty && !seenIds.contains(key)) {
          seenIds.add(key);
          combined.insert(0, lp);
        }
      }
    } catch (_) {}

    return combined;
  }

  /// Get Seller Single Property Details: GET /api/v1/sellers/:sellerId/properties/:propertyId
  Future<Map<String, dynamic>> getSellerPropertyById({
    required String sellerId,
    required String propertyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.getSellerPropertyById(sellerId, propertyId),
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not fetch property details.');
      AppLogger.i('Seller property $propertyId fetched for seller $sellerId');
      return data['data'] is Map
          ? Map<String, dynamic>.from(data['data'])
          : data;
    } on DioException catch (e, st) {
      AppLogger.e('Get Seller Property By ID failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to load property details.'));
    }
  }

  // ===========================================================================
  // 3b. CREATE PROPERTY — Seller "Add Property" flow
  // ===========================================================================

  /// Creates a new property listing according to DigiNiwas Property CRUD API Documentation:
  /// - Residential Sell: POST /residential-sale
  /// - Commercial Sell:  POST /commercial-sale
  /// - Residential Rent: POST /rental-properties
  /// - Commercial Rent:  POST /commercial-rental-properties
  ///
  /// Upload fields supported in multipart:
  /// - images (up to 25 files)
  /// - video (1 file, max 100 MB)
  /// - floorPlan (1 file)
  /// - reraCertificate (1 file)
  /// - documents (up to 3 files)
  /// - data (JSON-encoded fields payload for controllers parsing req.body.data)
  ///
  /// Falls back gracefully to POST /newproperties if the category-specific endpoint
  /// returns a 404.
  Future<Map<String, dynamic>> createProperty({
    required Map<String, dynamic> fields,
    List<File> images = const [],
    File? floorPlan,
    File? reraCertificate,
    File? video,
    List<File> documents = const [],
  }) async {
    try {
      final structured = PropertyPayloadBuilder.build(fields);

      final rawPurpose = (structured['transactionType'] ?? fields['transactionType'] ?? '').toString().toLowerCase();
      final isRent = rawPurpose.contains('rent');

      final rawCat = (structured['buildingType'] ?? fields['category'] ?? '').toString().toLowerCase();
      final isCommercial = rawCat.contains('commercial');

      final primaryEndpoint = isRent
          ? (isCommercial ? ApiConstants.commercialRent : ApiConstants.residentialRent)
          : (isCommercial ? ApiConstants.commercialSale : ApiConstants.residentialSale);

      Future<FormData> buildFormData() async {
        final formMap = <String, dynamic>{};

        fields.forEach((key, value) {
          if (value == null) return;
          if (value is List) {
            formMap[key] = value.map((e) => e.toString()).toList();
          } else {
            formMap[key] = value.toString();
          }
        });

        // Controller payload support: fully-validated Mongoose document under 'data'
        formMap['data'] = jsonEncode(structured);

        for (final image in images.take(25)) {
          formMap.putIfAbsent('images', () => <MultipartFile>[]);
          (formMap['images'] as List).add(await _toMultipart(image));
        }
        if (floorPlan != null) {
          formMap['floorPlan'] = await _toMultipart(floorPlan);
        }
        if (reraCertificate != null) {
          formMap['reraCertificate'] = await _toMultipart(reraCertificate);
        }
        if (video != null) {
          formMap['video'] = await _toMultipart(video);
        }
        for (final doc in documents.take(3)) {
          formMap.putIfAbsent('documents', () => <MultipartFile>[]);
          (formMap['documents'] as List).add(await _toMultipart(doc));
        }

        return FormData.fromMap(formMap);
      }

      final uploadOptions = Options(
        sendTimeout: const Duration(milliseconds: ApiConstants.uploadTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.uploadTimeout),
      );

      final formData = await buildFormData();

      Response response;
      try {
        response = await _apiService.post(
          primaryEndpoint,
          data: formData,
          options: uploadOptions,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 && primaryEndpoint != ApiConstants.createNewProperty) {
          AppLogger.w('Primary endpoint $primaryEndpoint returned 404, attempting fallback to ${ApiConstants.createNewProperty}');
          final fallbackFormData = await buildFormData();
          response = await _apiService.post(
            ApiConstants.createNewProperty,
            data: fallbackFormData,
            options: uploadOptions,
          );
        } else {
          rethrow;
        }
      }

      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not submit your listing.');

      final resData = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'])
          : (data['property'] is Map
          ? Map<String, dynamic>.from(data['property'])
          : (data.isNotEmpty ? data : <String, dynamic>{}));
      AppLogger.i('Property created successfully via $primaryEndpoint: ${resData['_id'] ?? resData['id'] ?? ''}');
      return resData;
    } on DioException catch (e, st) {
      AppLogger.e('Create Property failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to submit property listing.'));
    }
  }

  /// Delete Property: DELETE with category endpoint or fallback /newproperties/:id/delete
  Future<bool> deleteProperty(String propertyId, {String? categoryEndpoint}) async {
    try {
      final endpoint = categoryEndpoint ?? '/newproperties/$propertyId/delete';
      Response response;
      try {
        response = await _apiService.delete(endpoint);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404 && endpoint != '/newproperties/$propertyId/delete') {
          response = await _apiService.delete('/newproperties/$propertyId/delete');
        } else {
          rethrow;
        }
      }
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not delete property.');
      AppLogger.i('Property $propertyId deleted successfully');
      return true;
    } on DioException catch (e, st) {
      AppLogger.e('Delete Property failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to delete property.'));
    }
  }

  /// Fetches live promotion plans for properties (GET /v1/promotion-plans?targetType=PROPERTY)
  Future<List<PromotionPlanModel>> getPromotionPlans() async {
    try {
      final response = await _apiService.get(
        ApiConstants.promotionPlans,
        queryParameters: {'targetType': 'PROPERTY'},
      );
      final data = _asMap(response.data);
      if (data['success'] == false) return const [];
      final list = data['data'];
      if (list is List) {
        return list.whereType<Map>().map((m) => PromotionPlanModel(Map<String, dynamic>.from(m))).toList();
      }
      return const [];
    } on DioException catch (e, st) {
      AppLogger.e('getPromotionPlans failed', e, st);
      return const [];
    }
  }

  /// Submit boost request to assigned Partner (POST /v1/promotions/seller-request)
  Future<Map<String, dynamic>> submitBoostRequest({
    required String propertyId,
    required String promotionType,
    String? message,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.promotionsSellerRequest,
        data: {
          'propertyId': propertyId,
          'promotionType': promotionType,
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        },
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not submit boost request.');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('submitBoostRequest failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to submit boost request.'));
    }
  }

  /// List submitted boost requests (GET /v1/promotions/seller-requests)
  Future<List<SellerBoostRequestModel>> getSubmittedBoostRequests() async {
    try {
      final response = await _apiService.get(ApiConstants.promotionsSellerRequests);
      final data = _asMap(response.data);
      if (data['success'] == false) return const [];
      final list = data['data'];
      if (list is List) {
        return list.whereType<Map>().map((m) => SellerBoostRequestModel(Map<String, dynamic>.from(m))).toList();
      }
      return const [];
    } on DioException catch (e, st) {
      AppLogger.e('getSubmittedBoostRequests failed', e, st);
      return const [];
    }
  }

  /// Get status of single boost request and Admin outcome (GET /v1/promotions/seller-request/:id)
  Future<Map<String, dynamic>> getBoostRequestById(String id) async {
    try {
      final response = await _apiService.get(ApiConstants.getSellerRequestById(id));
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not load boost request status.');
      return data['data'] is Map ? Map<String, dynamic>.from(data['data']) : data;
    } on DioException catch (e, st) {
      AppLogger.e('getBoostRequestById failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to load boost request status.'));
    }
  }

  /// Boost Property: PATCH /api/newproperties/:id/boost
  Future<Map<String, dynamic>> boostProperty(String propertyId, {String boostType = 'featured', int days = 7}) async {
    try {
      final response = await _apiService.patch(
        '/newproperties/$propertyId/boost',
        data: {'boostType': boostType, 'days': days.toString()},
      );
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not boost property.');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Boost Property failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to boost property.'));
    }
  }

  /// Unboost Property: PATCH /api/newproperties/:id/unboost
  Future<Map<String, dynamic>> unboostProperty(String propertyId) async {
    try {
      final response = await _apiService.patch('/newproperties/$propertyId/unboost');
      final data = _asMap(response.data);
      _throwIfUnsuccessful(data, fallback: 'Could not remove property boost.');
      return data;
    } on DioException catch (e, st) {
      AppLogger.e('Unboost Property failed', e, st);
      throw SellerException(_extractMessage(e, fallback: 'Failed to remove boost.'));
    }
  }

  Future<MultipartFile> _toMultipart(File file) async {
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    return MultipartFile.fromFile(
      file.path,
      filename: file.path.split(Platform.pathSeparator).last,
      contentType: MediaType.parse(mimeType),
    );
  }

  // ===========================================================================
  // 4. SELLER HOME — SUPPORTING DATA (leads & visits for the assigned partner)
  // ===========================================================================

  /// Leads captured against the partner handling this seller's properties:
  /// GET /api/v1/leads/partner/:partnerId
  /// Returns a raw, defensively-parsed list (never throws — Seller Home
  /// treats this as supplementary and should still render without it).
  Future<List<Map<String, dynamic>>> getPartnerLeadsRaw(String partnerId) async {
    final cleanId = partnerId.trim();
    if (cleanId.isEmpty || cleanId.startsWith('{') || cleanId.contains(' ')) {
      return [];
    }
    try {
      final response = await _apiService.get(ApiConstants.sellerPartnerLeads(cleanId));
      return _extractList(response.data, keys: ['leads', 'results', 'items']);
    } on DioException catch (e) {
      AppLogger.w('Get Partner Leads notice for $cleanId: ${e.message}');
      return [];
    }
  }

  /// Visits scheduled with the partner handling this seller's properties:
  /// GET /api/v1/visits/partner/:partnerId
  Future<List<Map<String, dynamic>>> getPartnerVisitsRaw(String partnerId) async {
    final cleanId = partnerId.trim();
    if (cleanId.isEmpty || cleanId.startsWith('{') || cleanId.contains(' ')) {
      return [];
    }
    try {
      final response = await _apiService.get(ApiConstants.sellerPartnerVisits(cleanId));
      return _extractList(response.data, keys: ['visits', 'results', 'items']);
    } on DioException catch (e) {
      AppLogger.w('Get Partner Visits notice for $cleanId: ${e.message}');
      return [];
    }
  }

  /// Get partner profile details by ID
  /// GET /api/v1/partners/:id
  Future<Map<String, dynamic>?> getPartnerByIdRaw(String partnerId) async {
    final cleanId = partnerId.trim();
    if (cleanId.isEmpty || cleanId.startsWith('{') || cleanId.contains(' ')) {
      return null;
    }
    try {
      final response = await _apiService.get('${ApiConstants.partners}/$cleanId');
      final body = _asMap(response.data);
      final data = _asMap(body['data']);
      return data.isEmpty ? body : data;
    } on DioException catch (e) {
      AppLogger.w('Get Partner by ID notice for $cleanId: ${e.message}');
      return null;
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  /// Pulls a `List` out of a response body that may put it at `data`,
  /// `data.<key>` for any of [keys], or at the root — whichever shape the
  /// backend happens to use for a given list endpoint.
  List<Map<String, dynamic>> _extractList(dynamic raw, {required List<String> keys}) {
    dynamic root = raw;
    if (root is Map && root['data'] != null) root = root['data'];

    dynamic list = root;
    if (root is Map) {
      list = null;
      for (final key in keys) {
        if (root[key] is List) {
          list = root[key];
          break;
        }
      }
    }

    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _throwIfUnsuccessful(Map<String, dynamic> data, {required String fallback}) {
    if (data['success'] == false) {
      final message = data['message'];
      throw SellerException(message is String && message.isNotEmpty ? message : fallback);
    }
  }

  String _extractMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return fallback;
  }

  /// Pulls the raw error body (e.g. `{"applicationStatus": "..."}`) off a
  /// failed response so callers can branch on it (login errors include
  /// `applicationStatus` per the API guide).
  Map<String, dynamic>? _extractErrorData(DioException e) {
    final data = e.response?.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
  // ===========================================================================
  // DASHBOARD HEADER & NOTIFICATIONS
  // ===========================================================================

  /// Fetch seller notifications:
  /// Tries candidate endpoints if available, silently handles 404 when server
  /// derives seller notifications from events/properties.
  Future<List<Map<String, dynamic>>> getNotifications({String? sellerId}) async {
    // 1. Try general /notifications endpoint first
    try {
      final res = await _apiService.get(ApiConstants.notifications);
      if (res.data is Map && res.data['success'] == true) {
        return _extractNotificationList(res.data);
      }
      final list = _extractNotificationList(res.data);
      if (list.isNotEmpty) return list;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        AppLogger.w('Seller getNotifications endpoint notice: ${e.message}');
      }
    } catch (_) {}

    return [];
  }

  List<Map<String, dynamic>> _extractNotificationList(dynamic raw) {
    if (raw is! Map) {
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }
    dynamic list = raw['notifications'] ?? raw['data'] ?? raw['items'] ?? raw['list'];
    if (list is Map) {
      list = list['notifications'] ?? list['items'] ?? list['list'] ?? list['data'];
    }
    if (list is List) {
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// GET /api/v1/user/dashboard-header (Buyer-scoped on server)
  Future<BuerDashboardModel?> getDashboardHeader() async {
    try {
      final response = await _apiService.get(ApiConstants.dashboardHeader);
      final data = response.data;
      if (data is Map && data['success'] != false) {
        final innerData = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'])
            : Map<String, dynamic>.from(data);
        return BuerDashboardModel.fromJson(innerData);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        AppLogger.w('Seller dashboard header notice: ${e.message}');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await _apiService.patch(ApiConstants.markNotificationRead(id));
    } catch (e) {
      AppLogger.w('Mark notification as read failed: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _apiService.post(ApiConstants.markAllNotificationsRead);
    } catch (e) {
      AppLogger.w('Mark all notifications as read failed: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _apiService.delete('${ApiConstants.notifications}/$id');
    } catch (e) {
      AppLogger.w('Delete notification failed: $e');
    }
  }
}
