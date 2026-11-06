import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/buyer_dashboard_model.dart';
import '../models/explore_property.dart';
import '../models/home_feed_model.dart';
import '../models/property_boosted.dart';
import '../models/property_category_filter.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../data/home_repository.dart';
import '../models/property_filter_model.dart';
import '../models/property_model.dart';
import '../models/testimonial_model.dart';
import '../models/cms_service_model.dart';
import '../data/services_repository.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/notification_service.dart';

/// GetX controller for the Buyer Home screen and saved properties workflow.
class BuyerHomeController extends GetxController {
  BuyerHomeController({HomeRepository? repository})
      : _homeRepository = repository ?? HomeRepository(ApiService.instance);

  final HomeRepository _homeRepository;
  final ServicesRepository _servicesRepository = ServicesRepository(ApiService.instance);
  final ApiService _apiService = ApiService.instance;


  // ---------------------------------------------------------------------
  // REACTIVE STATE
  // ---------------------------------------------------------------------

  /// Primary home-feed loading flag — drives the full-screen shimmer.
  final RxBool isLoading = true.obs;

  /// Error message for the primary home-feed call (null when there's none).
  final RxnString error = RxnString();

  // Data returned by each API endpoint. `Rxn<T>` = nullable reactive value.
  final Rxn<HomeFeedModel> homeFeed = Rxn<HomeFeedModel>();
  final Rxn<BuerDashboardModel> dashboardHeader = Rxn<BuerDashboardModel>();
  final Rxn<ProperttCategoryFilter> categoryFilterData = Rxn<ProperttCategoryFilter>();
  final Rxn<ExploreNearbyData> exploreNearby = Rxn<ExploreNearbyData>();

  // Saved properties reactive state
  final RxList<dynamic> savedPropertiesList = <dynamic>[].obs;
  final RxBool savedPropertiesLoading = false.obs;
  // Saved property IDs ka track rakhne ke liye set
  final RxSet<String> savedPropertyIds = <String>{}.obs;

  // Independent loading flags — each secondary section loads on its own.
  final RxBool dashboardLoading = true.obs;
  final RxBool categoryFilterLoading = true.obs;
  final RxBool exploreLoading = true.obs;
  final Rxn<PropertyBoosted> boostedPropertiesData = Rxn<PropertyBoosted>();
  final RxBool boostedLoading = false.obs;

  // Active Promoted Properties & Partners from /v1/promotions/active/...
  final RxList<Map<String, dynamic>> activePromotedProperties = <Map<String, dynamic>>[].obs;
  final RxBool activePromotedLoading = false.obs;

  final RxList<Map<String, dynamic>> activePromotedPartners = <Map<String, dynamic>>[].obs;
  final RxBool activePartnersLoading = false.obs;

  // Community Testimonials reactive state
  final RxList<TestimonialModel> testimonials = <TestimonialModel>[].obs;
  final RxBool testimonialsLoading = false.obs;

  // CMS Services & Stories reactive state
  final RxList<CmsServiceModel> cmsServices = <CmsServiceModel>[].obs;
  final RxBool cmsServicesLoading = false.obs;

  // NOTE: boosted / newListings / popularAreas / agents — ye alag APIs se
  // nahi, sirf `/home/feed` (loadHomeFeed -> homeFeed) se aate hain. UI in
  // sections ke liye `isLoading` (home-feed ka loading state) use karti hai.

  /// Search radius (in meters) used for the Explore Nearby map. Changing
  /// this from the full-screen map re-fetches markers at the new radius.
  final RxInt exploreRadius = 3000.obs;

  // Search reactive state
  final RxList<dynamic> searchResultsList = <dynamic>[].obs;
  final RxBool searchLoading = false.obs;

  // Filter reactive state (GET /api/newproperties/filter)
  final RxList<PfPropertyData> filteredResultsList = <PfPropertyData>[].obs;
  final RxBool filterLoading = false.obs;
  final RxBool isFilterApplied = false.obs;
  final Rxn<PfAppliedFilters> currentAppliedFilters = Rxn<PfAppliedFilters>();
  final RxnString filterError = RxnString();

  /// Buyer's first name, shown in the header greeting/avatar initials.
  final RxString buyerName = 'Guest'.obs;

  /// Selected bottom-navigation tab index.
  final RxInt bottomNavIndex = 0.obs;

  /// Currently active category chip (Buy/Rent/Plot/Commercial), or null.
  final RxnString selectedCategoryTab = RxnString();

  /// Real-time or detected user location for the home header.
  final RxString userCurrentLocation = 'Fetching location...'.obs;

  // Notifications reactive state
  final RxList<dynamic> notificationsList = <dynamic>[].obs;
  final RxInt unreadNotificationsCount = 0.obs;
  final RxBool notificationsLoading = false.obs;

  // User Profile Avatar reactive state (synced across Home and Profile screens)
  final RxString userAvatarLocalPath = ''.obs;
  final RxString userAvatarNetworkUrl = ''.obs;

  /// User coordinates for map & distance calculations
  final Rxn<LatLng> userCoordinates = Rxn<LatLng>();

  /// Map type for home screen map view (Normal / Satellite)
  final Rx<MapType> homeMapType = MapType.normal.obs;

  void toggleHomeMapType() {
    homeMapType.value = homeMapType.value == MapType.normal
        ? MapType.hybrid
        : MapType.normal;
  }

  /// True once the device GPS gave us a real city. After that, stale profile
  /// locations from the backend (e.g. old Maharashtra address) must NOT override it.
  bool _gpsLocationResolved = false;
  bool _fetchingLocation = false;

  // ---------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    // ⚡ Instant Cache Hydration: Render immediately without showing loaders
    _loadCachedHomeFeed();
    _loadBuyerNameAndSavedProperties();
    fetchUserLocation();
    loadUserAvatar();
    fetchNotifications();

    // Subscribe to buyer FCM topics
    StorageService.instance.userId.then((uid) {
      NotificationService.instance.syncRoleTopics(
        role: 'buyer',
        userId: uid,
      );
    });

    // Background call for fresh data update without UI flicker
    Future.microtask(() {
      loadHomeFeed();
      loadAllApiSections();
    });
  }

  /// Instant offline / cached data loader — eliminates full-screen shimmers on revisit
  Future<void> _loadCachedHomeFeed() async {
    try {
      final cached = await StorageService.instance.getCachedHomeFeed();
      if (cached != null) {
        homeFeed.value = HomeFeedModel.fromJson(cached);
        isLoading.value = false;
        dashboardLoading.value = false;
        categoryFilterLoading.value = false;
        exploreLoading.value = false;
      }
    } catch (_) {}
  }

  /// Returns all cached and loaded properties from home feed, filters, boosted, and saved lists
  List<Map<String, dynamic>> getAllKnownProperties() {
    final List<Map<String, dynamic>> allProps = [];
    final Set<String> seenIds = {};

    void addProp(dynamic item) {
      if (item == null) return;
      Map<String, dynamic>? map;
      if (item is PfPropertyData) {
        map = {
          '_id': item.sId,
          'propertyId': item.propertyId,
          'title': item.title,
          'name': item.title,
          'locality': item.locality,
          'address': item.address,
          'city': item.city,
          'price': item.price,
          'bedrooms': item.bedrooms,
          'furnishing': item.furnishing,
          'area': item.superBuiltupArea != null ? '${item.superBuiltupArea} sqft' : null,
          'images': item.images?.map((img) => {'url': img.url}).toList(),
          'isCompared': item.isCompared,
        };
      } else if (item is Map<String, dynamic>) {
        map = item;
      } else if (item is Map) {
        map = Map<String, dynamic>.from(item);
      } else {
        try {
          final m = PropertyModel.fromDynamic(item);
          if (m.isNotEmpty) map = m.toJson();
        } catch (_) {}
      }

      if (map != null) {
        final id = (map['_id'] ?? map['id'] ?? map['propertyId'] ?? map['propertyCode'] ?? '').toString();
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          allProps.add(map);
        } else if (id.isEmpty) {
          allProps.add(map);
        }
      }
    }

    // 1. From filteredResultsList
    for (final p in filteredResultsList) {
      addProp(p);
    }
    // 2. From homeFeed
    final hf = homeFeed.value;
    if (hf != null) {
      for (final p in hf.recommendedProperties ?? []) {
        addProp(p.toJson());
      }
      for (final p in hf.boostedProperties ?? []) {
        addProp(p.toJson());
      }
      for (final p in hf.newListings ?? []) {
        addProp(p.toJson());
      }
    }
    // 3. From boosted
    final bp = boostedPropertiesData.value?.properties;
    if (bp != null) {
      for (final p in bp) {
        addProp(p.toJson());
      }
    }
    // 4. From saved
    for (final p in savedPropertiesList) {
      addProp(p);
    }

    return allProps;
  }

  /// GET /properties/search/list?keyword=value
  Future<void> searchProperties(String keyword) async {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      searchResultsList.clear();
      searchLoading.value = false;
      return;
    }

    // 1. INSTANT LOCAL FILTER (Fast instant response when typing 2+ chars)
    final allKnown = getAllKnownProperties();
    final localMatches = allKnown.where((prop) {
      final title = (prop['title'] ?? prop['name'] ?? prop['propertyName'] ?? '').toString().toLowerCase();
      final locality = (prop['locality'] ?? prop['subLocality'] ?? '').toString().toLowerCase();
      final city = (prop['city'] ?? '').toString().toLowerCase();
      final address = (prop['address'] ?? prop['fullAddress'] ?? '').toString().toLowerCase();
      final category = (prop['category'] ?? prop['propertyType'] ?? '').toString().toLowerCase();
      final desc = (prop['description'] ?? '').toString().toLowerCase();
      final code = (prop['propertyCode'] ?? prop['propertyId'] ?? '').toString().toLowerCase();

      return title.contains(q) ||
          locality.contains(q) ||
          city.contains(q) ||
          address.contains(q) ||
          category.contains(q) ||
          desc.contains(q) ||
          code.contains(q);
    }).toList();

    // Show local matches instantly
    if (localMatches.isNotEmpty) {
      searchResultsList.value = localMatches;
    }

    // 2. Query backend API in parallel and merge
    searchLoading.value = searchResultsList.isEmpty;
    try {
      final response = await _apiService.get(
        ApiConstants.searchProperties,
        queryParameters: {'keyword': keyword},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final apiList = (data['data'] ?? data['properties'] ?? []) as List<dynamic>;
        if (apiList.isNotEmpty) {
          final Set<String> seenIds = {};
          final List<dynamic> merged = [];
          for (final item in apiList) {
            final id = item is Map ? (item['_id'] ?? item['id'] ?? item['propertyId'])?.toString() : null;
            if (id != null && id.isNotEmpty) seenIds.add(id);
            merged.add(item);
          }
          for (final item in localMatches) {
            final id = (item['_id'] ?? item['id'] ?? item['propertyId'])?.toString();
            if (id != null && id.isNotEmpty && !seenIds.contains(id)) {
              seenIds.add(id);
              merged.add(item);
            }
          }
          searchResultsList.value = merged;
        } else if (localMatches.isNotEmpty) {
          searchResultsList.value = localMatches;
        } else {
          searchResultsList.clear();
        }
      } else if (localMatches.isNotEmpty) {
        searchResultsList.value = localMatches;
      } else {
        searchResultsList.clear();
      }
    } catch (_) {
      if (localMatches.isNotEmpty) {
        searchResultsList.value = localMatches;
      } else {
        searchResultsList.clear();
      }
    } finally {
      searchLoading.value = false;
    }
  }

  /// GET /api/newproperties/filter
  Future<void> applyPropertyFilters({
    String? city,
    String? category,
    String? transactionType,
    String? status,
    String? propertyVerificationStatus,
    num? minPrice,
    num? maxPrice,
  }) async {
    filterLoading.value = true;
    filterError.value = null;
    try {
      final result = await _homeRepository.getNewPropertiesFilter(
        city: city,
        category: category,
        transactionType: transactionType,
        status: status,
        propertyVerificationStatus: propertyVerificationStatus,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      filteredResultsList.value = result.data ?? result.properties ?? [];
      currentAppliedFilters.value = result.appliedFilters;
      isFilterApplied.value = true;
    } on HomeFeedException catch (e) {
      filteredResultsList.clear();
      filterError.value = e.message;
    } catch (_) {
      filteredResultsList.clear();
      filterError.value = 'Could not apply filters. Try again.';
    } finally {
      filterLoading.value = false;
    }
  }

  /// Clears active filters and returns the screen to its default state.
  void clearPropertyFilters() {
    filteredResultsList.clear();
    currentAppliedFilters.value = null;
    isFilterApplied.value = false;
    filterError.value = null;
  }

  Future<void> _loadBuyerNameAndSavedProperties() async {
    await _loadBuyerName();

    // Buyer ID fetch karke saved properties load karo
    String? buyerId = await StorageService.instance.buyerId;
    if (buyerId == null || buyerId.isEmpty) {
      buyerId = await StorageService.instance.userId;
    }
    if (buyerId == null || buyerId.isEmpty) {
      final raw = await SecureStorageService.instance.getUserData();
      if (raw != null && raw.isNotEmpty) {
        try {
          final user = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          buyerId = user['id']?.toString() ?? user['_id']?.toString() ?? user['buyerId']?.toString();
        } catch (_) {}
      }
    }
    if (buyerId != null && buyerId.isNotEmpty) {
      await fetchSavedProperties(buyerId);
    }
  }

  /// Fetches the user's current city/state from header, feed, local storage,
  /// or live device GPS via [LocationService].
  Future<void> fetchUserLocation() async {
    if (_fetchingLocation) return;
    _fetchingLocation = true;
    try {
      await _fetchUserLocationInternal();
    } finally {
      _fetchingLocation = false;
    }
  }

  Future<void> _fetchUserLocationInternal() async {
    // 1. Try live GPS capture via LocationService for accurate coordinates & location
    try {
      final locResult = await LocationService().getCurrentLocation();
      userCoordinates.value = LatLng(locResult.latitude, locResult.longitude);
      try {
        await StorageService.instance.saveLastKnownCoordinates(
          latitude: locResult.latitude,
          longitude: locResult.longitude,
        );
      } catch (_) {}
      if (locResult.city.isNotEmpty) {
        _gpsLocationResolved = true;
        userCurrentLocation.value = locResult.state.isNotEmpty
            ? '${locResult.city}, ${locResult.state}'
            : locResult.city;
        return;
      }
    } catch (_) {}

    // 2. Last known device coordinates (device truth beats stale backend profile location)
    try {
      final coords = await StorageService.instance.getLastKnownCoordinates();
      if (coords != null) {
        userCoordinates.value = LatLng(coords.latitude, coords.longitude);
        final placemarks = await Geocoding().placemarkFromCoordinates(coords.latitude, coords.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = p.locality ?? p.subAdministrativeArea ?? '';
          final state = p.administrativeArea ?? '';
          if (city.isNotEmpty) {
            _gpsLocationResolved = true;
            userCurrentLocation.value = state.isNotEmpty ? '$city, $state' : city;
            return;
          }
        }
      }
    } catch (_) {}

    // 3. Check if dashboardHeader has city
    final headerCity = dashboardHeader.value?.location?.city;
    if (headerCity != null && headerCity.isNotEmpty) {
      final state = dashboardHeader.value?.location?.state ?? '';
      userCurrentLocation.value = state.isNotEmpty ? '$headerCity, $state' : headerCity;
      return;
    }

    // 3. Check if homeFeed has city
    final feedCity = homeFeed.value?.location?.city;
    if (feedCity != null && feedCity.isNotEmpty) {
      final state = homeFeed.value?.location?.state ?? '';
      userCurrentLocation.value = state.isNotEmpty ? '$feedCity, $state' : feedCity;
      return;
    }

    // 4. Check locally persisted location
    try {
      final loc = await StorageService.instance.location;
      if (loc != null && loc['city'] != null && loc['city'].toString().isNotEmpty) {
        final city = loc['city'].toString();
        final state = loc['state']?.toString() ?? '';
        userCurrentLocation.value = state.isNotEmpty ? '$city, $state' : city;
        return;
      }
    } catch (_) {}

    // 6. Default fallback if still unresolved
    if (userCurrentLocation.value == 'Fetching location...') {
      userCurrentLocation.value = 'India';
    }
  }

  // ---------------------------------------------------------------------
  // LOADERS
  // ---------------------------------------------------------------------

  /// Reads the cached user object from secure storage just to get a name
  /// to show immediately, before the dashboard-header API responds.
  Future<void> _loadBuyerName() async {
    final raw = await SecureStorageService.instance.getUserData();
    if (raw == null || raw.isEmpty) return;
    try {
      final user = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final name = (user['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        buyerName.value = name.split(' ').first;
      }
    } catch (_) {
      // Ignore malformed cached user data — fall back to "Guest".
    }
  }

  /// 1. GET /api/v1/home/feed — the primary/blocking call for this screen.
  Future<void> loadHomeFeed() async {
    if (homeFeed.value == null) {
      isLoading.value = true;
    }
    error.value = null;
    try {
      double? lat;
      double? lng;
      String? city;
      try {
        final locResult = await LocationService().getCurrentLocation();
        lat = locResult.latitude;
        lng = locResult.longitude;
        city = locResult.city;
        userCoordinates.value = LatLng(lat, lng);
      } catch (_) {}

      final feed = await _homeRepository.getHomeFeed(
        latitude: lat,
        longitude: lng,
        city: city,
      );
      homeFeed.value = feed;
      isLoading.value = false;

      // Save to local cache for instant zero-shimmer render on reopen
      try {
        await StorageService.instance.saveCachedHomeFeed(jsonEncode(feed.toJson()));
      } catch (_) {}
      if (!_gpsLocationResolved &&
          (userCurrentLocation.value == 'Fetching location...' || userCurrentLocation.value == 'India')) {
        final loc = feed.location;
        if (loc?.city != null && loc!.city!.isNotEmpty) {
          userCurrentLocation.value = loc.state?.isNotEmpty == true ? '${loc.city}, ${loc.state}' : loc.city!;
        }
      }
      if (userCoordinates.value == null && feed.location?.latitude != null && feed.location?.longitude != null) {
        final dLat = (feed.location!.latitude as num).toDouble();
        final dLng = (feed.location!.longitude as num).toDouble();
        if (dLat != 0.0 && dLng != 0.0) {
          userCoordinates.value = LatLng(dLat, dLng);
        }
      }
      loadExploreNearby();
    } on HomeFeedException catch (e) {
      error.value = e.message;
      isLoading.value = false;
    } catch (_) {
      error.value = 'Something went wrong while loading the home feed.';
      isLoading.value = false;
    }
  }

  /// Kicks off remaining secondary API calls independently (in parallel).
  /// Boosted / new-listings / popular-areas / nearby-agents ab is function
  /// se call nahi hote — woh sab `homeFeed` (loadHomeFeed) se hi milte hain,
  /// taaki UI aur terminal ka data hamesha same/single-source rahe.
  void loadAllApiSections() {
    loadDashboardHeader();
    loadCategoryFilter();
    loadBoostedProperties();
    loadActivePromotions();
    loadTestimonials();
    loadCmsServices();
  }

  /// GET /api/v1/promotions/active/properties and /active/partners
  Future<void> loadActivePromotions() async {
    activePromotedLoading.value = true;
    activePartnersLoading.value = true;
    try {
      final futures = await Future.wait([
        _homeRepository.getActivePromotedProperties(),
        _homeRepository.getActivePromotedPartners(),
      ]);
      activePromotedProperties.assignAll(futures[0]);
      activePromotedPartners.assignAll(futures[1]);
    } catch (_) {
    } finally {
      activePromotedLoading.value = false;
      activePartnersLoading.value = false;
    }
  }

  /// GET /api/v1/cms/services/public
  Future<void> loadCmsServices() async {
    cmsServicesLoading.value = true;
    try {
      final list = await _servicesRepository.getPublicServices();
      cmsServices.value = list;
    } catch (_) {
      cmsServices.value = [];
    } finally {
      cmsServicesLoading.value = false;
    }
  }

  /// Submit Service Inquiry / Booking Lead to Admin
  Future<bool> submitServiceLead({
    required String name,
    required String phone,
    required String serviceName,
    required String actionType,
    String? email,
    String? notes,
  }) async {
    return await _servicesRepository.submitServiceLead(
      name: name,
      phone: phone,
      serviceName: serviceName,
      actionType: actionType,
      email: email,
      notes: notes,
    );
  }


  /// GET /api/v1/cms/testimonials
  Future<void> loadTestimonials() async {
    testimonialsLoading.value = true;
    try {
      final list = await _homeRepository.getTestimonials();
      testimonials.value = list;
    } catch (_) {
      testimonials.value = [];
    } finally {
      testimonialsLoading.value = false;
    }
  }

  /// 5. GET /api/v1/properties/boosted
  Future<void> loadBoostedProperties() async {
    boostedLoading.value = true;
    try {
      final res = await _homeRepository.getBoostedPropertiesList();
      boostedPropertiesData.value = res;
    } catch (_) {
      // Gracefully fall back to homeFeed if separate call is empty
    } finally {
      boostedLoading.value = false;
    }
  }

  /// 2. GET /api/v1/user/dashboard-header
  Future<void> loadDashboardHeader() async {
    dashboardLoading.value = true;
    try {
      final header = await _homeRepository.getDashboardHeader();
      dashboardHeader.value = header;
      dashboardLoading.value = false;
      if (!_gpsLocationResolved &&
          header.location?.city != null &&
          header.location!.city!.isNotEmpty) {
        final loc = header.location!;
        userCurrentLocation.value = loc.state?.isNotEmpty == true ? '${loc.city}, ${loc.state}' : loc.city!;
      }
      if (header.user?.name != null && header.user!.name!.isNotEmpty) {
        buyerName.value = header.user!.name!.split(' ').first;
      }
      final clearedIds = (await StorageService.instance.getClearedNotificationIds()).toSet();
      if (header.notifications != null) {
        final visible = header.notifications!.where((n) {
          final id = n is Map ? n['_id']?.toString() : null;
          return id == null || !clearedIds.contains(id);
        }).toList();
        notificationsList.value = visible;
        if (clearedIds.isNotEmpty) {
          unreadNotificationsCount.value = visible
              .where((n) => n is Map && n['isRead'] != true && n['read'] != true)
              .length;
        }
      }
      if (header.unreadNotificationsCount != null && clearedIds.isEmpty) {
        unreadNotificationsCount.value = header.unreadNotificationsCount!;
      }
      if (header.user?.avatar != null && header.user!.avatar!.isNotEmpty) {
        userAvatarNetworkUrl.value = header.user!.avatar!;
      }
    } catch (_) {
      dashboardLoading.value = false;
    }
  }

  /// 4. GET /api/v1/properties/categories
  Future<void> loadCategoryFilter({String? tab}) async {
    categoryFilterLoading.value = true;
    selectedCategoryTab.value = tab;
    try {
      categoryFilterData.value = await _homeRepository.getPropertyCategoryFilter(tab: tab);
      categoryFilterLoading.value = false;
    } catch (_) {
      categoryFilterLoading.value = false;
    }
  }

  void clearCategoryFilter() {
    selectedCategoryTab.value = null;
  }

  /// 8. GET /api/v1/properties/explore-nearby?propertyId=...&radius=...
  /// Pass [radius] (meters) to change the search radius — used by the
  /// full-screen Explore Map's radius chips. Defaults to [exploreRadius].
  Future<void> loadExploreNearby({String? propertyId, int? radius}) async {
    final targetId = propertyId ??
        homeFeed.value?.recommendedProperties?.firstOrNull?.propertyId ??
        homeFeed.value?.recommendedProperties?.firstOrNull?.id ??
        homeFeed.value?.boostedProperties?.firstOrNull?.propertyId ??
        homeFeed.value?.boostedProperties?.firstOrNull?.id;

    if (targetId == null || targetId.isEmpty) {
      exploreLoading.value = false;
      return;
    }
    if (radius != null) {
      exploreRadius.value = radius;
    }
    exploreLoading.value = true;
    try {
      exploreNearby.value = await _homeRepository.getExploreNearby(
        propertyId: targetId,
        radius: exploreRadius.value,
      );
      exploreLoading.value = false;

      // Print debug logs
      await debugCheckExploreNearby();
    } catch (_) {
      exploreLoading.value = false;
    }
  }
  /// Change the search radius (meters) on the full-screen Explore Map and
  /// re-fetch nearby markers for the currently loaded property.
  Future<void> changeExploreRadius(int radiusMeters) async {
    if (exploreRadius.value == radiusMeters && exploreNearby.value != null) return;
    await loadExploreNearby(radius: radiusMeters);
  }

  // ---------------------------------------------------------------------
  // SAVED PROPERTIES & WISHLIST API INTEGRATIONS
  // ---------------------------------------------------------------------

  /// GET /api/saved-properties/buyer/:buyerId
  Future<void> fetchSavedProperties(String buyerId) async {
    savedPropertiesLoading.value = true;
    try {
      final endpoint = ApiConstants.getBuyerSavedProperties(buyerId);
      final response = await _apiService.get(endpoint);

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final list = data['data'] ?? [];
        savedPropertiesList.value = list;

        savedPropertyIds.clear();
        for (var item in list) {
          final p = item is Map ? item : null;
          if (p == null) continue;
          final propObj = p['property'] is Map ? p['property'] : null;
          final snapObj = p['propertySnapshot'] is Map ? p['propertySnapshot'] : null;

          final candidateIds = [
            propObj?['_id']?.toString(),
            propObj?['id']?.toString(),
            propObj?['propertyId']?.toString(),
            propObj?['propertyCode']?.toString(),
            snapObj?['propertyId']?.toString(),
            snapObj?['_id']?.toString(),
            snapObj?['id']?.toString(),
            snapObj?['propertyCode']?.toString(),
            p['propertyId']?.toString(),
            p['propertyCode']?.toString(),
            p['_id']?.toString(),
            p['id']?.toString(),
          ];

          for (final cid in candidateIds) {
            if (cid != null && cid.isNotEmpty) {
              savedPropertyIds.add(cid);
            }
          }
        }
      }
    } catch (_) {
      savedPropertiesList.clear();
      savedPropertyIds.clear();
    } finally {
      savedPropertiesLoading.value = false;
    }
  }

  /// Toggle save / remove property with instant optimistic UI update
  Future<void> toggleSaveProperty(String buyerId, String propertyId) async {
    final isAlreadySaved = savedPropertyIds.contains(propertyId);

    // 1. OPTIMISTIC UI UPDATE (Makhan jaisa fast)
    if (isAlreadySaved) {
      savedPropertyIds.remove(propertyId);
      savedPropertiesList.removeWhere((item) {
        final pData = (item is Map && item['propertySnapshot'] != null)
            ? item['propertySnapshot']
            : (item is Map && item['property'] != null ? item['property'] : item);
        final pId = pData['propertyId']?.toString() ?? pData['_id']?.toString() ?? item['propertyId']?.toString() ?? '';
        return pId == propertyId;
      });
    } else {
      savedPropertyIds.add(propertyId);
    }

    // 2. Background API Call
    if (isAlreadySaved) {
      try {
        final response = await _apiService.delete(
          ApiConstants.removeSavedProperty(buyerId, propertyId),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          Get.snackbar(
            'Removed',
            'Property removed from saved items.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE53935),
            colorText: Colors.white,
            duration: const Duration(seconds: 1),
          );
        }
      } catch (_) {
        await fetchSavedProperties(buyerId);
      }
    } else {
      try {
        final response = await _apiService.post(
          ApiConstants.saveProperty,
          data: {'buyerId': buyerId, 'propertyId': propertyId},
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          Get.snackbar(
            'Success',
            'Property saved successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF007A5E),
            colorText: Colors.white,
            duration: const Duration(seconds: 1),
          );
        }
        await fetchSavedProperties(buyerId);
      } catch (_) {
        await fetchSavedProperties(buyerId);
      }
    }
  }

  Future<void> savePropertyCall(String buyerId, String propertyId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.saveProperty,
        data: {
          'buyerId': buyerId,
          'propertyId': propertyId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Success',
          'Property saved successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF007A5E),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
        await fetchSavedProperties(buyerId);
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not save property.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> removeSavedPropertyCall(String buyerId, String propertyId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.removeSavedProperty(buyerId, propertyId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Removed',
          'Property removed from saved items.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
        await fetchSavedProperties(buyerId);
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not remove saved property.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 🧪 Explore Nearby API data ko console par debug / check karne ke liye test method
  Future<void> debugCheckExploreNearby() async {
    debugPrint('EXPLORE_DEBUG: -----------------------------------------');
    debugPrint('EXPLORE_DEBUG: exploreLoading value -> ${exploreLoading.value}');

    final explore = exploreNearby.value;
    if (explore == null) {
      debugPrint('EXPLORE_DEBUG: exploreNearby data is currently NULL or empty.');
    } else {
      debugPrint('EXPLORE_DEBUG: Property Title -> ${explore.property?.title}');
      debugPrint('EXPLORE_DEBUG: Map Center Lat -> ${explore.map?.center?.latitude}');
      debugPrint('EXPLORE_DEBUG: Map Center Lng -> ${explore.map?.center?.longitude}');

      final markers = explore.map?.markers ?? [];
      debugPrint('EXPLORE_DEBUG: Total Markers found -> ${markers.length}');

      for (int i = 0; i < markers.length; i++) {
        final m = markers[i];
        debugPrint('EXPLORE_DEBUG: Marker [$i] -> Name: ${m.name}, Type: ${m.markerType}, Lat: ${m.latitude}, Lng: ${m.longitude}');
      }
    }
    debugPrint('EXPLORE_DEBUG: -----------------------------------------');
  }

  /// Pull-to-refresh: reloads the primary feed, then every secondary section.
  Future<void> refreshAll() async {
    fetchUserLocation();
    loadUserAvatar();
    fetchNotifications();
    await loadHomeFeed();
    loadAllApiSections();
    String? buyerId = await StorageService.instance.buyerId;
    if (buyerId == null || buyerId.isEmpty) {
      buyerId = await StorageService.instance.userId;
    }
    if (buyerId != null && buyerId.isNotEmpty) {
      await fetchSavedProperties(buyerId);
    }
  }

  // ---------------------------------------------------------------------
  // NOTIFICATIONS API INTEGRATIONS
  // ---------------------------------------------------------------------

  Future<void> fetchNotifications() async {
    notificationsLoading.value = true;
    try {
      // Refresh dashboard-header (as per PDF Page 4, Section 3: /api/v1/user/dashboard-header)
      await loadDashboardHeader();
      final dashNotifs = dashboardHeader.value?.notifications ?? [];
      final readIds = (await StorageService.instance.getReadNotificationIds()).toSet();
      final clearedIds = (await StorageService.instance.getClearedNotificationIds()).toSet();

      final List<Map<String, dynamic>> combinedList = [];

      if (dashNotifs.isNotEmpty) {
        for (final item in dashNotifs) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['_id']?.toString() ?? '';
            if (id.isNotEmpty && clearedIds.contains(id)) continue;
            if (id.isNotEmpty && readIds.contains(id)) {
              map['isRead'] = true;
              map['read'] = true;
            }
            combinedList.add(map);
          }
        }
      }

      // Cleared notifications (fallback wale bhi) filter karo
      combinedList.removeWhere((m) => clearedIds.contains(m['_id']?.toString()));

      notificationsList.value = combinedList;
      unreadNotificationsCount.value = combinedList
          .where((item) => item['isRead'] != true && item['read'] != true)
          .length;

      // 🔔 Fire push notification with sound for new in-app notifications
      NotificationService.syncInAppNotificationsToPush(
        notifications: combinedList,
        role: 'buyer',
      );
    } catch (e) {
      debugPrint("Error fetching notifications via dashboard-header: $e");
    } finally {
      notificationsLoading.value = false;
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    await StorageService.instance.markNotificationIdAsRead(id);
    for (int i = 0; i < notificationsList.length; i++) {
      if (notificationsList[i] is Map && notificationsList[i]['_id']?.toString() == id) {
        final updated = Map<String, dynamic>.from(notificationsList[i] as Map);
        updated['isRead'] = true;
        updated['read'] = true;
        notificationsList[i] = updated;
        break;
      }
    }
    unreadNotificationsCount.value = notificationsList
        .where((item) => item is Map && item['isRead'] != true && item['read'] != true)
        .length;
    try {
      if (!id.startsWith('notif_')) {
        await _apiService.patch(ApiConstants.markNotificationRead(id));
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    if (id.isEmpty) return;
    notificationsList.removeWhere((item) =>
        item is Map && (item['_id']?.toString() == id || item['id']?.toString() == id));
    unreadNotificationsCount.value = notificationsList
        .where((item) => item is Map && item['isRead'] != true && item['read'] != true)
        .length;
    await StorageService.instance.addClearedNotificationIds([id]);
    await StorageService.instance.markNotificationIdAsRead(id);
    try {
      if (!id.startsWith('notif_')) {
        await _apiService.delete('${ApiConstants.notifications}/$id');
      }
    } catch (_) {}
  }

  /// Saari notifications list se hata deta hai (local clear, refresh par wapas nahi aayengi)
  Future<void> clearAllNotifications() async {
    final ids = <String>[];
    for (final n in notificationsList) {
      if (n is Map) {
        final id = n['_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    notificationsList.clear();
    unreadNotificationsCount.value = 0;
    await StorageService.instance.addClearedNotificationIds(ids);
    await StorageService.instance.markAllNotificationIdsAsRead(ids);
    try {
      await _apiService.post(ApiConstants.markAllNotificationsRead);
    } catch (_) {}
  }

  Future<void> markAllNotificationsAsRead() async {
    final ids = <String>[];
    for (int i = 0; i < notificationsList.length; i++) {
      if (notificationsList[i] is Map) {
        final id = notificationsList[i]['_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
        final updated = Map<String, dynamic>.from(notificationsList[i] as Map);
        updated['isRead'] = true;
        updated['read'] = true;
        notificationsList[i] = updated;
      }
    }
    unreadNotificationsCount.value = 0;
    await StorageService.instance.markAllNotificationIdsAsRead(ids);
    try {
      await _apiService.post(ApiConstants.markAllNotificationsRead);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // PROFILE AVATAR MANAGEMENT & SYNC
  // ---------------------------------------------------------------------

  Future<void> loadUserAvatar() async {
    final local = await StorageService.instance.localAvatarPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      userAvatarLocalPath.value = local;
    }
    final net = dashboardHeader.value?.user?.avatar;
    if (net != null && net.isNotEmpty) {
      userAvatarNetworkUrl.value = net;
    }
  }

  Future<void> updateProfileAvatar(String newPath) async {
    userAvatarLocalPath.value = newPath;
    await StorageService.instance.saveLocalAvatarPath(newPath);
  }

  // ---------------------------------------------------------------------
  // UI ACTIONS
  // ---------------------------------------------------------------------

  void changeBottomNavIndex(int index) {
    bottomNavIndex.value = index;
  }

  void onCategoryChipTap(String label) {
    if (selectedCategoryTab.value == label) {
      clearCategoryFilter();
    } else {
      loadCategoryFilter(tab: label);
    }
  }

  // ---------------------------------------------------------------------
  // PURE HELPERS
  // ---------------------------------------------------------------------

  String greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}