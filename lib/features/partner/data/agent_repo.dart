import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';

/// GET /v1/agents/nearby
/// "Returns verified agents ranked by location/service-locality/promotion
/// logic." — used to resolve a `partnerId` for a property when the
/// property payload itself doesn't carry one directly.
class AgentRepository {
  AgentRepository(this._api);

  final ApiService _api;

  /// Returns a flexible list of raw agent maps (shape not fully known —
  /// this parses several common response envelopes defensively). Each
  /// map is expected to carry an `_id` or `id` you can use as partnerId.
  Future<List<Map<String, dynamic>>> getNearbyAgents({
    double? lat,
    double? lng,
    String? city,
  }) async {
    final Response response = await _api.get(
      ApiConstants.nearbyAgents,
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (city != null && city.isNotEmpty) 'city': city,
      },
    );

    final data = response.data;
    dynamic list;

    // Real response shape (confirmed from logs):
    // { success, message, data: { location, count, agents: [...] } }
    // Unwrap the "data" envelope first, THEN look for the actual list —
    // the old code grabbed data['data'] itself (a Map) before ever
    // checking 'agents', so it always returned an empty list.
    dynamic root = data;
    if (root is Map && root['data'] is Map) {
      root = root['data'];
    }

    if (root is Map) {
      list = root['agents'] ?? root['data'] ?? root['results'] ?? root['partners'];
    } else if (root is List) {
      list = root;
    }

    if (list is! List) return [];

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Convenience: returns just the best-ranked agent's id (first in the
  /// list, since the endpoint already returns them "ranked"), or null.
  Future<String?> getBestNearbyPartnerId({
    double? lat,
    double? lng,
    String? city,
  }) async {
    try {
      final agents = await getNearbyAgents(lat: lat, lng: lng, city: city);
      if (agents.isEmpty) return null;
      final first = agents.first;
      return first['_id']?.toString() ?? first['id']?.toString() ?? first['partnerId']?.toString();
    } catch (_) {
      return null;
    }
  }
}