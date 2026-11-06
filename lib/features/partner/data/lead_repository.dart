import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../features/partner/models/lead_model.dart';
import '../../../core/network/api_service.dart';

class LeadRepository {
  LeadRepository(this._api);

  final ApiService _api;

  Future<LeadModel> createLeadFromProperty({
    required String propertyId,
    String? buyerId,
    String? partnerId,
    required String name,
    required String phone,
    String? email,
    String? message,
    String? source,
    required String contactPreference,
  }) async {
    final Response response = await _api.post(
      ApiConstants.createLeadFromProperty,
      data: {
        'propertyId': propertyId,
        if (buyerId != null && buyerId.isNotEmpty) 'buyerId': buyerId,
        if (partnerId != null && partnerId.isNotEmpty) 'partnerId': partnerId,
        'name': name.trim(),
        'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
        'contactPreference': contactPreference,
        'consentVerified': true,
      },
    );
    return LeadModel.fromJson(_asMap(response.data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Unexpected response shape from ApiService — expected a JSON object.');
  }
}