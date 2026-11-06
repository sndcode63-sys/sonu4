import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';

import '../../../features/partner/models/request_visit_model.dart';
import '../../../features/partner/models/visit_status.dart';
import '../../../core/network/api_service.dart';

class VisitRepository {
  VisitRepository(this._api);

  final ApiService _api;

  /// POST {ApiConstants.baseUrl}{ApiConstants.requestVisit}
  /// i.e. https://backend-diginiwas.onrender.com/api/visits/request
  ///
  /// [requestedVisitAt] is sent as an ISO-8601 string; adjust
  /// `.toIso8601String()` if your backend expects a different format.
  Future<RequestVisitModel> requestVisit({
    required String propertyId,
    required String buyerId,
    required String partnerId,
    required DateTime requestedVisitAt,
    String? requestNotes,
    String requestSource = 'app',
  }) async {
    final Response response = await _api.post(
      ApiConstants.requestVisit,
      data: {
        'propertyId': propertyId,
        'buyerId': buyerId,
        'partnerId': partnerId,
        'requestedVisitAt': requestedVisitAt.toIso8601String(),
        'requestSource': requestSource,
        if (requestNotes != null && requestNotes.trim().isNotEmpty)
          'requestNotes': requestNotes.trim(),
      },
    );
    return RequestVisitModel.fromJson(_asMap(response.data));
  }

  /// GET {ApiConstants.baseUrl}{ApiConstants.getVisitById(visitId)}
  /// i.e. https://backend-diginiwas.onrender.com/api/visits/<visitId>
  Future<VisitStatusModel> getVisitById(String visitId) async {
    final Response response = await _api.get(ApiConstants.getVisitById(visitId));

    return VisitStatusModel.fromJson(_asMap(response.data));
  }

  /// Normalizes Dio's decoded `response.data` into a Map<String, dynamic>
  /// so the model parsers always get the right shape (Dio already decodes
  /// JSON bodies for you — this just guards against odd shapes/String bodies).
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Unexpected response shape from ApiService — expected a JSON object.');
  }
}