import '../../../core/network/api_service.dart';
import 'home_repository.dart';

/// Which "View All" section was tapped on the buyer home screen. Each value
/// maps to exactly one dedicated backend endpoint (see [ViewAllRepository])
/// — tapping "View All" on one section only ever calls that section's own
/// API, never mixes in another section's data.
enum ViewAllSection { boosted, newListings, popularAreas }

/// Single place that owns every "View All" API call. The View All screen
/// just says *which* section was opened (via [ViewAllSection]) and this
/// class does the right GET request + response normalization — the screen
/// doesn't need to know which endpoint or model class is behind each
/// section.
///
/// Endpoints used:
/// - [ViewAllSection.boosted]      -> GET /v1/properties/boosted
/// - [ViewAllSection.newListings]  -> GET /v1/properties/new-listings
/// - [ViewAllSection.popularAreas] -> GET /v1/locations/popular
class ViewAllRepository {
  ViewAllRepository({HomeRepository? repository}) : _repository = repository ?? HomeRepository(ApiService.instance);

  final HomeRepository _repository;

  /// Single entry point the View All screen calls — routes to the right
  /// API for [section] and returns an already-normalized list.
  Future<List<Map<String, dynamic>>> fetchProperties(ViewAllSection section) {
    switch (section) {
      case ViewAllSection.boosted:
        return _fetchBoosted();
      case ViewAllSection.newListings:
        return _fetchNewListings();
      case ViewAllSection.popularAreas:
        return _fetchPopularAreas();
    }
  }

  /// GET /v1/properties/boosted
  Future<List<Map<String, dynamic>>> _fetchBoosted() async {
    final result = await _repository.getBoostedPropertiesList();
    return _mapPropertyLikeList(result.properties ?? []);
  }

  /// GET /v1/properties/new-listings
  Future<List<Map<String, dynamic>>> _fetchNewListings() async {
    final result = await _repository.getNewListingsList();
    return _mapPropertyLikeList(result.properties ?? []);
  }

  /// GET /v1/locations/popular
  Future<List<Map<String, dynamic>>> _fetchPopularAreas() async {
    final result = await _repository.getPopularLocations();
    final areas = result.areas ?? [];
    return areas.map<Map<String, dynamic>>((a) {
      return {
        'locality': a.locality,
        'image': a.sampleImage,
        'propertyCount': a.propertyCount,
        'city': a.city ?? '',
      };
    }).toList();
  }

  /// Normalizes any property-like list (boosted / new listings) into plain
  /// maps so the View All screen's card widget doesn't need to know about
  /// the different model classes each endpoint returns.
  List<Map<String, dynamic>> _mapPropertyLikeList(List items) {
    return items.map<Map<String, dynamic>>((p) {
      final imgs = <String>[];
      if (p.images != null) {
        for (var img in p.images) {
          if (img.url != null) imgs.add(img.url as String);
        }
      }
      return {
        'title': p.title,
        'locality': p.locality,
        'city': p.city,
        'bedrooms': p.bedrooms,
        'furnishing': p.furnishing,
        'price': p.price,
        'images': imgs,
        'json': p.toJson(),
      };
    }).toList();
  }
}
