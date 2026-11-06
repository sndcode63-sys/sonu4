import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../controllers/buyer_home_controller.dart';
import '../models/explore_property.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_pill_search_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyerMapItem {
  final String id;
  final String title;
  final String category;
  final String statusOrPrice;
  final double? rating; // Nullable: only displayed if backend actually provides it
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final bool isProperty;
  final Map<String, dynamic>? rawProperty;
  double distanceKm;

  BuyerMapItem({
    required this.id,
    required this.title,
    required this.category,
    required this.statusOrPrice,
    this.rating,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.isProperty = true,
    this.rawProperty,
    this.distanceKm = 0.0,
  });
}

class BuyerMapScreen extends StatefulWidget {
  const BuyerMapScreen({super.key});

  @override
  State<BuyerMapScreen> createState() => _BuyerMapScreenState();
}

class _BuyerMapScreenState extends State<BuyerMapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _searchDebounce;

  // Default coordinate (used only if there is no GPS and no property at all)
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);
  LatLng _currentCenter = _defaultLocation;
  LatLng? _userLocation;
  MapType _currentMapType = MapType.normal;

  // _allItems = EVERY property from the database / feeds.
  // _filteredItems = what is currently shown (all items, or search matches).
  List<BuyerMapItem> _allItems = [];
  List<BuyerMapItem> _filteredItems = [];
  BuyerMapItem? _selectedItem;
  int _selectedIndex = 0;

  final Map<String, BitmapDescriptor> _customIcons = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isSearchingHere = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Immediately pre-seed live or cached user location so map doesn't jump
    if (Get.isRegistered<BuyerHomeController>()) {
      final ctrl = Get.find<BuyerHomeController>();
      if (ctrl.userCoordinates.value != null) {
        _userLocation = ctrl.userCoordinates.value;
        _currentCenter = ctrl.userCoordinates.value!;
      }
    }

    _initializeDataAndMarkers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // refresh the clear (x) button
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _executeSearch();
    });
  }

  // ---------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  bool _validCoord(double? lat, double? lng) {
    return lat != null &&
        lng != null &&
        lat != 0 &&
        lng != 0 &&
        lat.abs() <= 90 &&
        lng.abs() <= 180;
  }

  String _priceLabel(dynamic v) {
    if (v == null) return 'Price on Request';
    num? n;
    if (v is num) {
      n = v;
    } else {
      final cleaned = v.toString().replaceAll(',', '').trim();
      n = double.tryParse(cleaned);
      if (n == null) {
        // Already a formatted string like "₹45 L"
        return cleaned.isEmpty ? 'Price on Request' : cleaned;
      }
    }
    if (n <= 0) return 'Price on Request';
    String trim(double x) => x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    if (n >= 10000000) return '₹${trim(n / 10000000)} Cr';
    if (n >= 100000) return '₹${trim(n / 100000)} L';
    return '₹${n.toStringAsFixed(0)}';
  }

  /// Sorts items by distance from [center] (nearest first). Does NOT remove anything.
  void _updateDistances(LatLng center, List<BuyerMapItem> items) {
    for (final item in items) {
      final d = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        item.latitude,
        item.longitude,
      );
      item.distanceKm = d / 1000.0;
    }
    items.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  /// Shows ALL properties (no radius limit), nearest to [center] first.
  void _filterPropertiesByLocation({required LatLng center}) {
    if (_allItems.isEmpty) {
      _filteredItems = [];
      _selectedItem = null;
      return;
    }

    final sorted = List<BuyerMapItem>.from(_allItems);
    _updateDistances(center, sorted);

    _filteredItems = sorted;
    _selectedItem = sorted.first;
    _selectedIndex = 0;

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  /// Zooms the map so every property marker is visible.
  void _fitAllMarkers() {
    final controller = _mapController;
    if (controller == null || _filteredItems.isEmpty) return;

    if (_filteredItems.length == 1) {
      final i = _filteredItems.first;
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(i.latitude, i.longitude), 14.5));
      return;
    }

    double minLat = _filteredItems.first.latitude;
    double maxLat = minLat;
    double minLng = _filteredItems.first.longitude;
    double maxLng = minLng;
    for (final i in _filteredItems) {
      if (i.latitude < minLat) minLat = i.latitude;
      if (i.latitude > maxLat) maxLat = i.latitude;
      if (i.longitude < minLng) minLng = i.longitude;
      if (i.longitude > maxLng) maxLng = i.longitude;
    }

    try {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
          90,
        ),
      );
    } catch (_) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 6));
    }
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filterPropertiesByLocation(center: _currentCenter);
      });
      await _rebuildMarkers();
      return;
    }

    // 1. Direct search matching property locality, city, address, title, category or price
    final matched = _allItems.where((item) {
      final raw = item.rawProperty;
      final locality = raw?['locality']?.toString().toLowerCase() ?? '';
      final city = raw?['city']?.toString().toLowerCase() ?? '';
      final address = raw?['address']?.toString().toLowerCase() ?? '';
      final title = item.title.toLowerCase();
      final cat = item.category.toLowerCase();
      final price = item.statusOrPrice.toLowerCase();

      return title.contains(query) ||
          cat.contains(query) ||
          price.contains(query) ||
          locality.contains(query) ||
          city.contains(query) ||
          address.contains(query);
    }).toList();

    if (matched.isNotEmpty) {
      _updateDistances(_currentCenter, matched);

      final firstMatch = matched[0];
      final targetLoc = LatLng(firstMatch.latitude, firstMatch.longitude);

      setState(() {
        _filteredItems = matched;
        _selectedItem = firstMatch;
        _selectedIndex = 0;
        _currentCenter = targetLoc;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(targetLoc, 14.5));

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      await _rebuildMarkers();
      return;
    }

    // 2. Geocoding search (a place name that isn't in any property): move there,
    //    but still keep every property on the map, sorted by distance from that place.
    try {
      final locations = await Geocoding().locationFromAddress(query);
      if (locations.isNotEmpty) {
        final target = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() {
          _currentCenter = target;
          _filterPropertiesByLocation(center: target);
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 13.5));
        await _rebuildMarkers();
      } else {
        setState(() {
          _filteredItems = [];
          _selectedItem = null;
        });
        await _rebuildMarkers();
      }
    } catch (_) {
      setState(() {
        _filteredItems = [];
        _selectedItem = null;
      });
      await _rebuildMarkers();
    }
  }

  // ---------------------------------------------------------------------
  // DATA LOADING — every property from the backend (no distance filter)
  // ---------------------------------------------------------------------
  BuyerMapItem? _itemFromFeedProperty(
      dynamic p,
      String fallbackTitle,
      String fallbackCategory,
      String idPrefix,
      int index,
      ) {
    final lat = _toDouble(p.latitude);
    final lng = _toDouble(p.longitude);
    if (!_validCoord(lat, lng)) return null;

    String? img;
    final images = p.images;
    if (images != null && images.isNotEmpty) {
      img = images.first.url;
    }
    if (img == null || img.isEmpty) {
      try {
        final j = p.toJson();
        img = (j['image'] ?? j['imageUrl'] ?? j['coverImage'] ?? j['thumbnail'])?.toString();
      } catch (_) {}
    }

    final priceStr = _priceLabel(p.price);
    final locStr = [p.locality, p.city]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(', ');

    return BuyerMapItem(
      id: (p.propertyId ?? p.id ?? '${idPrefix}_$index').toString(),
      title: (p.title ?? fallbackTitle).toString(),
      category:
      '${p.bedrooms != null ? "${p.bedrooms} BHK " : ""}${p.category ?? fallbackCategory}'.trim(),
      statusOrPrice: locStr.isNotEmpty ? '$priceStr • $locStr' : priceStr,
      rating: null,
      latitude: lat!,
      longitude: lng!,
      imageUrl: img,
      isProperty: true,
      rawProperty: {
        '_id': p.id,
        'propertyId': p.propertyId,
        'title': p.title,
        'price': p.price,
        'locality': p.locality,
        'city': p.city,
        'bedrooms': p.bedrooms,
        'images': images?.map((e) => {'url': e.url}).toList(),
      },
    );
  }

  /// Loads ALL properties from the public properties API.
  Future<void> _loadAllPropertiesFromApi(void Function(BuyerMapItem) addItem) async {
    try {
      final res = await ApiService.instance.get(ApiConstants.getProperties);
      dynamic list = res.data;
      if (list is Map) {
        list = list['properties'] ?? list['data'] ?? list['results'] ?? [];
        if (list is Map) {
          list = list['properties'] ?? list['items'] ?? list['data'] ?? [];
        }
      }
      if (list is! List) return;

      for (final raw in list) {
        if (raw is! Map) continue;

        final loc = raw['location'] is Map ? raw['location'] as Map : null;
        final lat = _toDouble(raw['latitude'] ?? raw['lat'] ?? loc?['latitude'] ?? loc?['lat']);
        final lng = _toDouble(raw['longitude'] ?? raw['lng'] ?? loc?['longitude'] ?? loc?['lng']);
        if (!_validCoord(lat, lng)) continue;

        final locality = (raw['locality'] ?? loc?['locality'])?.toString() ?? '';
        final city = (raw['city'] ?? loc?['city'])?.toString() ?? '';
        final locStr = [locality, city].where((s) => s.isNotEmpty).join(', ');

        final bed = raw['bedrooms'];
        final type = (raw['propertyType'] ?? raw['category'] ?? 'Property').toString();
        final category = (bed != null && bed.toString().isNotEmpty) ? '$bed BHK $type' : type;

        final priceStr = _priceLabel(raw['price'] ?? raw['rent']);

        String? imgUrl;
        final media = raw['media'] ?? raw['images'] ?? raw['photos'] ?? raw['gallery'];
        if (media is List && media.isNotEmpty) {
          final first = media.first;
          if (first is Map) {
            imgUrl = (first['secure_url'] ?? first['url'] ?? first['imageUrl'] ?? first['image'] ?? first['path'])?.toString();
          } else if (first is String) {
            imgUrl = first;
          }
        }
        if (imgUrl == null || imgUrl.isEmpty) {
          imgUrl = (raw['image'] ?? raw['imageUrl'] ?? raw['coverImage'] ?? raw['thumbnail'])?.toString();
        }

        final rawMap = Map<String, dynamic>.from(raw);
        rawMap.putIfAbsent('locality', () => locality);
        rawMap.putIfAbsent('city', () => city);

        addItem(
          BuyerMapItem(
            id: (raw['_id'] ?? raw['propertyId'] ?? 'api_${lat}_$lng').toString(),
            title: (raw['title'] ?? 'Verified Property').toString(),
            category: category,
            statusOrPrice: locStr.isNotEmpty ? '$priceStr • $locStr' : priceStr,
            rating: _toDouble(raw['rating']),
            latitude: lat!,
            longitude: lng!,
            imageUrl: imgUrl,
            isProperty: true,
            rawProperty: rawMap,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _initializeDataAndMarkers() async {
    setState(() => _isLoading = true);

    final List<BuyerMapItem> items = [];
    final Set<String> seenIds = {};

    void addItem(BuyerMapItem item) {
      if (!seenIds.contains(item.id)) {
        seenIds.add(item.id);
        items.add(item);
      }
    }

    // 1. Navigation arguments
    final args = Get.arguments;
    if (args is ExploreNearbyData) {
      _processExploreData(args, addItem);
    } else if (args is Map && args['explore'] is ExploreNearbyData) {
      _processExploreData(args['explore'] as ExploreNearbyData, addItem);
    }

    // 2. BuyerHomeController state
    if (Get.isRegistered<BuyerHomeController>()) {
      final ctrl = Get.find<BuyerHomeController>();

      final explore = ctrl.exploreNearby.value;
      if (explore != null) {
        _processExploreData(explore, addItem);
      }

      final feed = ctrl.homeFeed.value;
      if (feed?.recommendedProperties != null) {
        int i = 0;
        for (final p in feed!.recommendedProperties!) {
          final item = _itemFromFeedProperty(p, 'Verified Property', 'Property', 'prop', i++);
          if (item != null) addItem(item);
        }
      }
      if (feed?.boostedProperties != null) {
        int i = 0;
        for (final p in feed!.boostedProperties!) {
          final item = _itemFromFeedProperty(p, 'Featured Property', 'Featured', 'boosted', i++);
          if (item != null) addItem(item);
        }
      }
    }

    // 3. ALWAYS load every property from the database (merged, duplicates skipped)
    await _loadAllPropertiesFromApi(addItem);

    _allItems = items;

    // 4. User's location: prioritize live GPS / stored coordinates so user's current location is shown
    LatLng? userLocation = _userLocation;

    if (userLocation == null) {
      try {
        final coords = await StorageService.instance.getLastKnownCoordinates();
        if (coords != null && coords.latitude != 0 && coords.longitude != 0) {
          userLocation = LatLng(coords.latitude, coords.longitude);
        }
      } catch (_) {}
    }

    try {
      final loc = await LocationService().getCurrentLocation();
      userLocation = LatLng(loc.latitude, loc.longitude);
      if (Get.isRegistered<BuyerHomeController>()) {
        Get.find<BuyerHomeController>().userCoordinates.value = userLocation;
      }
      StorageService.instance.saveLastKnownCoordinates(
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
    } catch (_) {
      if (userLocation == null) {
        try {
          final perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
            );
            userLocation = LatLng(pos.latitude, pos.longitude);
          }
        } catch (_) {}
      }
    }

    if (userLocation != null) {
      _userLocation = userLocation;
      _currentCenter = userLocation;
    } else if (items.isNotEmpty) {
      _currentCenter = LatLng(items.first.latitude, items.first.longitude);
    }

    // 5. Show ALL properties, nearest to user's location first
    _filterPropertiesByLocation(center: _currentCenter);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Keep camera focused on user's current location (never zoom out to entire India)
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentCenter, 14.5));
    }

    await _rebuildMarkers();
  }

  void _processExploreData(ExploreNearbyData explore, void Function(BuyerMapItem) addItem) {
    if (explore.map?.center?.latitude != null && explore.map?.center?.longitude != null) {
      _currentCenter = LatLng(explore.map!.center!.latitude!, explore.map!.center!.longitude!);
    }

    final prop = explore.property;
    if (prop != null && prop.latitude != null && prop.longitude != null && prop.latitude != 0) {
      addItem(
        BuyerMapItem(
          id: prop.propertyId ?? prop.sId ?? 'explore_property',
          title: prop.title ?? 'Selected Property',
          category: 'Property',
          statusOrPrice: [prop.locality, prop.city].where((s) => s != null && s.isNotEmpty).join(', '),
          rating: null,
          latitude: prop.latitude!,
          longitude: prop.longitude!,
          imageUrl: null,
          isProperty: true,
          rawProperty: {
            '_id': prop.sId,
            'propertyId': prop.propertyId,
            'title': prop.title,
            'locality': prop.locality,
            'city': prop.city,
            'latitude': prop.latitude,
            'longitude': prop.longitude,
          },
        ),
      );
    }

    if (explore.map?.markers != null) {
      for (var m in explore.map!.markers!) {
        if (m.latitude != null && m.longitude != null && m.latitude != 0 && m.longitude != 0) {
          final isProp = m.markerType == 'PROPERTY';
          final distStr = m.distanceKm != null
              ? '${m.distanceKm} km away'
              : (m.distanceMeters != null ? '${m.distanceMeters} m away' : 'Nearby');
          addItem(
            BuyerMapItem(
              id: m.propertyId ?? m.id ?? m.mongoId ?? 'marker_${m.latitude}_${m.longitude}',
              title: m.name ?? 'Nearby Location',
              category: m.category ?? m.markerType ?? 'Nearby Place',
              statusOrPrice: distStr,
              rating: null,
              latitude: m.latitude!,
              longitude: m.longitude!,
              imageUrl: null,
              isProperty: isProp,
              rawProperty: {
                '_id': m.propertyId ?? m.id,
                'propertyId': m.propertyId,
                'title': m.name,
                'latitude': m.latitude,
                'longitude': m.longitude,
                'markerType': m.markerType,
              },
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // MARKERS
  // ---------------------------------------------------------------------
  /// Category-coded price-pill marker (Blue for School, Red for Hospital, Orange for Food, Green for Properties)
  Future<BitmapDescriptor> _getMarkerIcon({
    required String title,
    required String priceText,
    required double? rating,
    required bool isSelected,
    String? markerType,
    bool isProperty = true,
  }) async {
    // Marker shows only the price part (before " • locality, city")
    String label = priceText.split('•').first.trim();
    if (label.isEmpty || label.toLowerCase().contains('request') || label.length > 12) {
      label = title.length > 10 ? '${title.substring(0, 8)}..' : title;
    }

    final String type = (markerType ?? (isProperty ? 'PROPERTY' : 'PLACE')).toUpperCase();
    final key = 'pill-$type-${label.hashCode}-$rating-$isSelected';
    if (_customIcons.containsKey(key)) {
      return _customIcons[key]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 12.5 : 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (rating != null && rating > 0) ...[
            const TextSpan(text: ' '),
            TextSpan(
              text: '★${rating.toStringAsFixed(1)}',
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: isSelected ? 11.0 : 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double padH = isSelected ? 12.0 : 10.0;
    final double pillWidth = (textPainter.width + padH * 2).clamp(58.0, 130.0);
    final double pillHeight = isSelected ? 34.0 : 28.0;
    const double pointerH = 6.0;
    final double totalHeight = pillHeight + pointerH + 8.0;
    final double totalWidth = pillWidth + 8.0;
    final double cx = totalWidth / 2;

    // 1. Soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, pillHeight / 2 + 2), width: pillWidth - 2, height: pillHeight),
        Radius.circular(pillHeight / 2),
      ),
      shadowPaint,
    );

    // 2. Rounded pill
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, pillHeight / 2 + 2), width: pillWidth, height: pillHeight),
      Radius.circular(pillHeight / 2),
    );

    List<Color> gradientColors;
    Color pointerColor;

    if (type.contains('EDU') || type.contains('SCHOOL') || type.contains('COLLEGE')) {
      gradientColors = isSelected
          ? [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)]
          : [const Color(0xFF2563EB), const Color(0xFF3B82F6)];
      pointerColor = isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF3B82F6);
    } else if (type.contains('HEALTH') || type.contains('HOSPITAL') || type.contains('CLINIC')) {
      gradientColors = isSelected
          ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]
          : [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      pointerColor = isSelected ? const Color(0xFFB91C1C) : const Color(0xFFEF4444);
    } else if (type.contains('FOOD') || type.contains('REST') || type.contains('CAFE')) {
      gradientColors = isSelected
          ? [const Color(0xFF78350F), const Color(0xFFB45309)]
          : [const Color(0xFFD97706), const Color(0xFFF59E0B)];
      pointerColor = isSelected ? const Color(0xFFB45309) : const Color(0xFFF59E0B);
    } else {
      gradientColors = isSelected
          ? [const Color(0xFF0F2544), const Color(0xFF1E3A8A)]
          : [const Color(0xFF007A5E), const Color(0xFF00A884)];
      pointerColor = isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF00A884);
    }

    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx - pillWidth / 2, 0),
        Offset(cx + pillWidth / 2, pillHeight),
        gradientColors,
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRRect, bgPaint);

    // 3. Pointer triangle
    final pointerPath = Path();
    pointerPath.moveTo(cx - 5, pillHeight + 2);
    pointerPath.lineTo(cx, pillHeight + pointerH + 2);
    pointerPath.lineTo(cx + 5, pillHeight + 2);
    pointerPath.close();

    final pointerPaint = Paint()
      ..color = pointerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pointerPath, pointerPaint);

    // 4. White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.4;
    canvas.drawRRect(pillRRect, borderPaint);

    // 5. Center text
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, (pillHeight + 4 - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    final icon = BitmapDescriptor.bytes(pngBytes!.buffer.asUint8List());
    _customIcons[key] = icon;
    return icon;
  }

  Future<void> _rebuildMarkers() async {
    final Set<Marker> newMarkers = {};

    for (var item in _filteredItems) {
      final isSelected = _selectedItem?.id == item.id;
      final icon = await _getMarkerIcon(
        title: item.title,
        priceText: item.statusOrPrice,
        rating: item.rating,
        isSelected: isSelected,
        markerType: item.rawProperty?['markerType'] as String?,
        isProperty: item.isProperty,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(item.id),
          position: LatLng(item.latitude, item.longitude),
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          zIndexInt: isSelected ? 2 : 1,
          onTap: () {
            _selectItem(item);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _selectItem(BuyerMapItem item) {
    final index = _filteredItems.indexWhere((i) => i.id == item.id);
    setState(() {
      _selectedItem = item;
      if (index != -1) {
        _selectedIndex = index;
      }
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(item.latitude, item.longitude)),
    );

    if (index != -1 && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }

    _rebuildMarkers();
  }

  void _onPageChanged(int index) {
    if (index >= 0 && index < _filteredItems.length) {
      final item = _filteredItems[index];
      setState(() {
        _selectedItem = item;
        _selectedIndex = index;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(item.latitude, item.longitude)),
      );

      _rebuildMarkers();
    }
  }

  Future<void> _moveToUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentCenter, 13.5));
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      _userLocation = userLatLng;
      _currentCenter = userLatLng;

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14.5));

      // Re-sort by distance from the user (all properties stay on the map)
      setState(() {
        _filterPropertiesByLocation(center: userLatLng);
      });
      await _rebuildMarkers();
    } catch (_) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation ?? _currentCenter, 13.5));
    }
  }

  Future<void> _searchHereAction() async {
    setState(() => _isSearchingHere = true);

    // Re-sort every property by distance from the visible map center
    setState(() {
      _filterPropertiesByLocation(center: _currentCenter);
    });

    if (Get.isRegistered<BuyerHomeController>()) {
      final ctrl = Get.find<BuyerHomeController>();
      try {
        await ctrl.loadExploreNearby();
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isSearchingHere = false);
    }
    await _rebuildMarkers();
  }

  // ---------------------------------------------------------------------
  // STREET VIEW & MAP TYPE HELPERS
  // ---------------------------------------------------------------------
  Future<void> _openStreetView({double? lat, double? lng, String? title}) async {
    final targetLat = lat ?? _selectedItem?.latitude ?? _currentCenter.latitude;
    final targetLng = lng ?? _selectedItem?.longitude ?? _currentCenter.longitude;
    final name = title ?? _selectedItem?.title ?? 'Selected Property';

    // 1. Native Google Street View intent on Android
    final streetViewUri = Uri.parse('google.streetview:cbll=$targetLat,$targetLng');
    // 2. Google Maps Street View 360 pano web URL
    final webPanoUri = Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$targetLat,$targetLng',
    );
    // 3. Fallback coordinates URL
    final webSearchUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$targetLat,$targetLng',
    );

    try {
      if (await canLaunchUrl(streetViewUri)) {
        await launchUrl(streetViewUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webPanoUri)) {
        await launchUrl(webPanoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webSearchUri)) {
        await launchUrl(webSearchUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      Get.snackbar(
        'Street View',
        'Could not open Street View for $name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _showMapTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Map Type & Views',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, size: 20.sp, color: const Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMapTypeOption(
                    title: 'Default',
                    icon: Icons.map_rounded,
                    isSelected: _currentMapType == MapType.normal,
                    onTap: () {
                      setState(() => _currentMapType = MapType.normal);
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildMapTypeOption(
                    title: 'Satellite',
                    icon: Icons.satellite_alt_rounded,
                    isSelected: _currentMapType == MapType.hybrid || _currentMapType == MapType.satellite,
                    onTap: () {
                      setState(() => _currentMapType = MapType.hybrid);
                      Navigator.pop(ctx);
                    },
                  ),
                  _buildMapTypeOption(
                    title: 'Terrain',
                    icon: Icons.terrain_rounded,
                    isSelected: _currentMapType == MapType.terrain,
                    onTap: () {
                      setState(() => _currentMapType = MapType.terrain);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _openStreetView();
                },
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.streetview_rounded, color: Colors.white, size: 20.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Street View (360°)',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              _selectedItem != null
                                  ? 'Panoramic street view for ${_selectedItem!.title}'
                                  : 'Panoramic street view around current map location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: const Color(0xFF92400E)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF8F5) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF007A5E) : const Color(0xFFCBD5E1),
                width: isSelected ? 2.2 : 1.0,
              ),
            ),
            child: Icon(
              icon,
              size: 26.sp,
              color: isSelected ? const Color(0xFF007A5E) : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF007A5E) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? bgColor,
    Color? borderColor,
    bool isActive = false,
  }) {
    final bg = isActive
        ? (iconColor ?? const Color(0xFF007A5E))
        : (bgColor ?? Colors.white);
    final ic = isActive ? Colors.white : (iconColor ?? const Color(0xFF1E293B));

    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
          ),
          child: Icon(icon, color: ic, size: 21.sp),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          bottom: true,
          top: false,
          child: Stack(
            children: [
              // 1. Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentCenter,
                  zoom: 14.5,
                ),
                mapType: _currentMapType,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_userLocation != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_userLocation!, 14.5),
                    );
                  }
                },
                onCameraMove: (pos) {
                  _currentCenter = pos.target;
                },
              ),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF007A5E)),
                ),

              // 2. Top bar: back + search + GPS
              Positioned(
                top: 48.h,
                left: 16.w,
                right: 16.w,
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Get.back();
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 44.w,
                          height: 44.w,
                          child: Icon(
                            Icons.adaptive.arrow_back,
                            color: const Color(0xFF1E293B),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: AppPillSearchBar(
                        controller: _searchController,
                        hintText: 'Search property',
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        onTap: _moveToUserLocation,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 44.w,
                          height: 44.w,
                          child: Icon(
                            Icons.my_location_rounded,
                            color: const Color(0xFFE53935),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Property count chip (left)
              if (!_isLoading)
                Positioned(
                  top: 108.h,
                  left: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A5E),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_filteredItems.length} ${_filteredItems.length == 1 ? 'property' : 'properties'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // 4. "Search this area" pill (center)
              Positioned(
                top: 108.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(24.r),
                    child: InkWell(
                      onTap: _searchHereAction,
                      borderRadius: BorderRadius.circular(24.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSearchingHere) ...[
                              SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ] else ...[
                              Icon(Icons.refresh_rounded, color: const Color(0xFFE53935), size: 16.sp),
                              SizedBox(width: 6.w),
                            ],
                            Text(
                              'Search this area',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Floating Map Action Buttons (right)
              Positioned(
                top: 104.h,
                right: 16.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A. Satellite / Map Type switcher
                    _buildFloatingButton(
                      icon: _currentMapType == MapType.hybrid || _currentMapType == MapType.satellite
                          ? Icons.satellite_alt_rounded
                          : Icons.layers_rounded,
                      isActive: _currentMapType == MapType.hybrid || _currentMapType == MapType.satellite,
                      onTap: _showMapTypeSheet,
                    ),
                    SizedBox(height: 10.h),

                    // B. Street View 360° launcher
                    _buildFloatingButton(
                      icon: Icons.streetview_rounded,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      borderColor: const Color(0xFFFDE68A),
                      onTap: () => _openStreetView(),
                    ),
                    SizedBox(height: 10.h),

                    // C. "Show all properties" (zoom out) button
                    _buildFloatingButton(
                      icon: Icons.zoom_out_map_rounded,
                      iconColor: const Color(0xFF007A5E),
                      onTap: _fitAllMarkers,
                    ),
                    SizedBox(height: 10.h),

                    // D. My Location button
                    _buildFloatingButton(
                      icon: Icons.my_location_rounded,
                      iconColor: const Color(0xFFE53935),
                      onTap: _moveToUserLocation,
                    ),
                  ],
                ),
              ),

              // 6. Bottom property carousel
              Positioned(
                left: 0,
                right: 0,
                bottom: 24.h,
                child: _filteredItems.isNotEmpty
                    ? SizedBox(
                  height: 114.h,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _filteredItems.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildPropertyCard(item, isSelected: index == _selectedIndex);
                    },
                  ),
                )
                    : Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off_rounded, color: const Color(0xFF94A3B8), size: 26.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLoading ? 'Loading properties...' : 'No properties found',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF0F172A),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try a different search.'
                                  : 'Properties with a map location will appear here.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF64748B),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BOTTOM PROPERTY CARD
  // ---------------------------------------------------------------------
  Widget _buildPropertyCard(BuyerMapItem item, {bool isSelected = false}) {
    final active = isSelected || _selectedItem?.id == item.id;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.propertyDetails, arguments: {
          'propertyId': item.id,
          'property': item.rawProperty ??
              {
                '_id': item.id,
                'propertyId': item.id,
                'title': item.title,
                'price': item.statusOrPrice,
                'images': hasImage ? [{'url': item.imageUrl}] : [],
              },
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: active ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
            width: active ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? 0.15 : 0.08),
              blurRadius: active ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: hasImage
                  ? Image.network(
                item.imageUrl!,
                width: 86.w,
                height: 86.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackIcon(item),
              )
                  : _buildFallbackIcon(item),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      if (item.rating != null && item.rating! > 0) ...[
                        Icon(Icons.star_rounded, color: const Color(0xFFFFB800), size: 14.sp),
                        SizedBox(width: 2.w),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text('•', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 11.sp)),
                        SizedBox(width: 4.w),
                      ],
                      Expanded(
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.distanceKm > 0) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8F5),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: const Color(0xFFBCE7DA), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded, size: 10.sp, color: const Color(0xFF007A5E)),
                              SizedBox(width: 3.w),
                              Text(
                                item.distanceKm < 1.0
                                    ? '${(item.distanceKm * 1000).toInt()}m'
                                    : item.distanceKm >= 100
                                    ? '${item.distanceKm.toStringAsFixed(0)}km'
                                    : '${item.distanceKm.toStringAsFixed(1)}km',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF007A5E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.statusOrPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF007A5E),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _openStreetView(
                            lat: item.latitude,
                            lng: item.longitude,
                            title: item.title,
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 6.w),
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.streetview_rounded, size: 13.sp, color: const Color(0xFFD97706)),
                              SizedBox(width: 3.w),
                              Text(
                                'Street View',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A5E),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuyerMapItem item) {
    return Container(
      width: 86.w,
      height: 86.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Icon(
          item.isProperty ? Icons.home_work_rounded : Icons.place_rounded,
          color: const Color(0xFFE53935),
          size: 30.sp,
        ),
      ),
    );
  }
}