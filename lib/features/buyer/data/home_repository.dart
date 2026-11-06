import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/buyer_dashboard_model.dart';
import '../models/explore_property.dart';
import '../models/home_feed_model.dart';
import '../../../features/partner/models/near_by_agent.dart';
import '../models/popular_property.dart';
import '../models/property_category_filter.dart';
import '../models/property_boosted.dart';
import '../models/property_filter_model.dart';
import '../models/property_new_listing.dart';
import '../models/testimonial_model.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/app_logger.dart';

class HomeFeedException implements Exception {
  HomeFeedException(this.message);
  final String message;

  @override
  String toString() => message;
}

class HomeRepository {
  HomeRepository(this._apiService);

  final ApiService _apiService;

  /// GET /api/v1/home/feed
  Future<HomeFeedModel> getHomeFeed({
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.homeFeed,
        queryParameters: {
          if (latitude != null) 'lat': latitude,
          if (longitude != null) 'lng': longitude,
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        final message = data is Map ? data['message'] : null;
        throw HomeFeedException(
          message is String && message.isNotEmpty ? message : 'Could not load home feed.',
        );
      }
      AppLogger.i('Home feed loaded');
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return HomeFeedModel.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('Home feed request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }


  /// GET /properties/filter ( ya /properties ) - Similar properties fetch karne ke liye
  Future<List<Map<String, dynamic>>> getSimilarProperties({
    String? category,
    String? city,
    String? currentPropertyId,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.filterProperties,
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final list = data['data'] ?? data['properties'] ?? [];
        if (list is List) {
          return list
              .map((e) => Map<String, dynamic>.from(e))
              .where((p) => (p['_id']?.toString() ?? p['propertyId']?.toString()) != currentPropertyId)
              .toList();
        }
      }
      return [];
    } on DioException catch (e, st) {
      AppLogger.e('Similar properties request failed', e, st);
      return [];
    }
  }

  /// GET /api/newproperties/filter
  Future<PropertyFilterModel> getNewPropertiesFilter({
    String? city,
    String? category,
    String? transactionType,
    String? status,
    String? propertyVerificationStatus,
    num? minPrice,
    num? maxPrice,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.newPropertiesFilter,
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (category != null && category.isNotEmpty) 'category': category,
          if (transactionType != null && transactionType.isNotEmpty)
            'transactionType': transactionType,
          if (status != null && status.isNotEmpty) 'status': status,
          if (propertyVerificationStatus != null && propertyVerificationStatus.isNotEmpty)
            'propertyVerificationStatus': propertyVerificationStatus,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(
          _messageOrFallback(data, 'Could not load filtered properties.'),
        );
      }
      return PropertyFilterModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e, st) {
      AppLogger.e('New properties filter request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /api/v1/user/dashboard-header
  Future<BuerDashboardModel> getDashboardHeader() async {
    try {
      final response = await _apiService.get(ApiConstants.dashboardHeader);
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load dashboard header.'));
      }
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return BuerDashboardModel.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('Dashboard header request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /api/v1/locations/popular
  Future<PopularProperty> getPopularLocations() async {
    try {
      final response = await _apiService.get(ApiConstants.popularLocations);
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load popular locations.'));
      }
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return PopularProperty.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('Popular locations request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /api/v1/properties/categories
  Future<ProperttCategoryFilter> getPropertyCategoryFilter({
    String? tab,
    String? category,
    double? lat,
    double? lng,
    String? city,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.propertyCategories,
        queryParameters: {
          if (tab != null && tab.isNotEmpty) 'tab': tab,
          if (category != null && category.isNotEmpty) 'category': category,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load categories.'));
      }
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return ProperttCategoryFilter.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('Property categories request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /api/v1/promotions/active/properties?page=1&limit=20
  Future<List<Map<String, dynamic>>> getActivePromotedProperties({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        ApiConstants.promotionsActiveProperties,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final inner = data['data'];
        if (inner is List) {
          return inner.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }
        if (inner is Map && inner['items'] is List) {
          return (inner['items'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }
      }
      return const [];
    } on DioException catch (e, st) {
      AppLogger.e('Active promoted properties failed', e, st);
      return const [];
    }
  }

  /// GET /api/v1/promotions/active/partners?page=1&limit=20
  Future<List<Map<String, dynamic>>> getActivePromotedPartners({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        ApiConstants.promotionsActivePartners,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final inner = data['data'];
        if (inner is List) {
          return inner.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }
        if (inner is Map && inner['items'] is List) {
          return (inner['items'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        }
      }
      return const [];
    } on DioException catch (e, st) {
      AppLogger.e('Active promoted partners failed', e, st);
      return const [];
    }
  }

  /// GET /api/v1/properties/boosted
  Future<PropertyBoosted> getBoostedPropertiesList() async {
    try {
      final response = await _apiService.get(ApiConstants.boostedProperties);
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load boosted properties.'));
      }
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return PropertyBoosted.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('Boosted properties request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /api/v1/properties/new-listings
  Future<PropertyNewListing> getNewListingsList() async {
    try {
      final response = await _apiService.get(ApiConstants.newListings);
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load new listings.'));
      }
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return PropertyNewListing.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('New listings request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /api/v1/agents/nearby
  Future<NearByAgent> getNearbyAgentsList() async {
    try {
      final response = await _apiService.get(ApiConstants.nearbyAgents);
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load nearby agents.'));
      }
      final innerData = data['data'] is Map ? Map<String, dynamic>.from(data['data']) : Map<String, dynamic>.from(data);
      return NearByAgent.fromJson(innerData);
    } on DioException catch (e, st) {
      AppLogger.e('Nearby agents request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  Future<ExploreNearbyData> getExploreNearby({
    required String propertyId,
    int? radius,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.exploreNearby,
        queryParameters: {
          'propertyId': propertyId,
          if (radius != null) 'radius': radius,
        },
      );
      final data = response.data;
      if (data is! Map || data['success'] == false) {
        throw HomeFeedException(_messageOrFallback(data, 'Could not load nearby places.'));
      }
      return ExploreNearbyData.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e, st) {
      AppLogger.e('Explore nearby request failed', e, st);
      throw HomeFeedException(_extractMessage(e));
    }
  }

  /// GET /properties/:id (Fetch single property details by ID with candidate fallback)
  Future<Map<String, dynamic>?> getPropertyById(String propertyId) async {
    final candidateEndpoints = [
      '${ApiConstants.getPropertyById}/$propertyId',
      '/newproperties/$propertyId',
      '/v1/properties/$propertyId',
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final response = await _apiService.get(endpoint);
        final data = response.data;

        if (data is Map) {
          if (data['success'] != false) {
            if (data.containsKey('data') && data['data'] is Map) {
              return Map<String, dynamic>.from(data['data']);
            }
            if (data.containsKey('property') && data['property'] is Map) {
              return Map<String, dynamic>.from(data['property']);
            }
            return Map<String, dynamic>.from(data);
          }
        }
      } catch (e) {
        AppLogger.w('Endpoint $endpoint failed for propertyId: $propertyId, attempting next candidate...');
      }
    }
    return null;
  }

  /// GET /api/v1/cms/testimonials
  Future<List<TestimonialModel>> getTestimonials() async {
    for (final endpoint in [ApiConstants.testimonials, ApiConstants.testimonialsLegacy]) {
      try {
        final response = await _apiService.get(endpoint);
        final data = response.data;
        if (data is Map && data['success'] != false) {
          final list = data['testimonials'] ?? data['data'];
          if (list is List) {
            final parsed = list
                .whereType<Map<String, dynamic>>()
                .map((j) => TestimonialModel.fromJson(j))
                .where((t) => t.isActive)
                .toList();
            if (parsed.isNotEmpty) return parsed;
          }
        }
      } catch (e) {
        AppLogger.w('Testimonials request failed on $endpoint: $e');
      }
    }
    return [];
  }

  String _messageOrFallback(dynamic data, String fallback) {
    final message = data is Map ? data['message'] : null;
    return message is String && message.isNotEmpty ? message : fallback;
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (e.response?.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Server is taking longer than usual to respond. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to the server. Please check your internet connection.';
    }
    return 'Could not load data. Please try again.';
  }
}