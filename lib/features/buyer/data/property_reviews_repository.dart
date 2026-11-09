import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/property_review_model.dart';

class PropertyReviewsRepository {
  final ApiService _apiService;

  PropertyReviewsRepository(this._apiService);

  /// GET /api/v1/property-reviews/property/:propertyId
  Future<List<PropertyReviewModel>> getPropertyReviews(String propertyId) async {
    if (propertyId.isEmpty) return [];

    final candidateEndpoints = [
      ApiConstants.propertyReviews(propertyId),
      ApiConstants.propertyReviewsLegacy(propertyId),
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final response = await _apiService.get(endpoint);
        final data = response.data;
        if (data is Map && data['success'] != false) {
          final rawList = data['reviews'] ??
              (data['data'] is Map ? data['data']['reviews'] : null) ??
              data['data'];

          if (rawList is List) {
            return rawList
                .whereType<Map<String, dynamic>>()
                .map((j) => PropertyReviewModel.fromJson(j))
                .toList();
          }
        }
      } catch (e) {
        AppLogger.w('Failed to fetch reviews from $endpoint: $e');
      }
    }

    return [];
  }

  /// POST /api/v1/property-reviews
  /// JSON body: { propertyId, rating, remark }
  Future<PropertyReviewModel?> submitReview({
    required String propertyId,
    required num rating,
    required String remark,
  }) async {
    final payload = {
      'propertyId': propertyId,
      'rating': rating,
      'remark': remark.trim(),
    };

    final candidateEndpoints = [
      ApiConstants.submitPropertyReview,
      ApiConstants.submitPropertyReviewLegacy,
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final response = await _apiService.post(endpoint, data: payload);
        final data = response.data;
        if (data is Map && data['success'] != false) {
          final reviewRaw = data['review'] ??
              (data['data'] is Map ? data['data']['review'] : null) ??
              data['data'];

          if (reviewRaw is Map<String, dynamic>) {
            return PropertyReviewModel.fromJson(reviewRaw);
          } else if (reviewRaw is Map) {
            return PropertyReviewModel.fromJson(Map<String, dynamic>.from(reviewRaw));
          }

          // Server did not return the saved review -> treat as not saved,
          // caller re-fetches the real list from the API.
          return null;
        }
      } catch (e) {
        AppLogger.w('Failed to submit review to $endpoint: $e');
      }
    }

    return null;
  }
}
