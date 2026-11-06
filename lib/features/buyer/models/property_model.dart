import 'package:intl/intl.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/widgets/app_image.dart';

/// Strongly-typed, crash-proof model representing a Property in DigiNiwas.
///
/// Designed to absorb all backend schema variations (different key names,
/// number vs string vs map types, nulls) safely without throwing runtime [TypeError].
class PropertyModel {
  final String id;
  final String propertyCode;
  final String title;
  final String description;
  final String category;
  final String transactionType;
  final String projectName;
  final String developerName;

  // Pricing
  final dynamic rawPrice;
  final double? priceAmount;
  final String priceLabel;
  final String pricePerSqft;
  final String maintenance;
  final String bookingAmount;

  // Location
  final String address;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final dynamic distanceKm;
  final bool? sameCity;

  // Specs
  final dynamic bedrooms;
  final dynamic bathrooms;
  final dynamic balconies;
  final String facing;
  final String furnishing;
  final dynamic floorNo;
  final dynamic totalFloors;
  final dynamic carpetArea;
  final dynamic superBuiltUpArea;
  final String parking;

  // Status & Verification
  final String status;
  final String verificationStatus;
  final bool isVerified;
  final String reraNumber;
  final String reraCertificateUrl;

  // Media
  final List<String> images;
  final String videoUrl;
  final String floorPlanUrl;
  final String panoramaUrl;

  // Meta
  final List<String> amenities;
  final List<String> tags;
  final Map<String, dynamic> rawJson;

  const PropertyModel({
    required this.id,
    required this.propertyCode,
    required this.title,
    required this.description,
    required this.category,
    required this.transactionType,
    required this.projectName,
    required this.developerName,
    required this.rawPrice,
    required this.priceAmount,
    required this.priceLabel,
    required this.pricePerSqft,
    required this.maintenance,
    required this.bookingAmount,
    required this.address,
    required this.locality,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.sameCity,
    required this.bedrooms,
    required this.bathrooms,
    required this.balconies,
    required this.facing,
    required this.furnishing,
    required this.floorNo,
    required this.totalFloors,
    required this.carpetArea,
    required this.superBuiltUpArea,
    required this.parking,
    required this.status,
    required this.verificationStatus,
    required this.isVerified,
    required this.reraNumber,
    required this.reraCertificateUrl,
    required this.images,
    required this.videoUrl,
    required this.floorPlanUrl,
    required this.panoramaUrl,
    required this.amenities,
    required this.tags,
    required this.rawJson,
  });

  /// Factory that safely unwraps nested property objects e.g.:
  /// - `{"property": {...}}`
  /// - `{"propertySnapshot": {...}}`
  /// - `{"data": {...}}`
  /// or direct JSON map.
  factory PropertyModel.fromDynamic(dynamic raw) {
    if (raw is PropertyModel) return raw;
    if (raw is! Map) return PropertyModel.empty();

    Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    final rootId = map['_id'] ?? map['id'] ?? map['propertyId'] ?? map['propertyCode'];

    if (map['propertySnapshot'] is Map) {
      final snap = Map<String, dynamic>.from(map['propertySnapshot']);
      if (map['property'] is Map) {
        snap.addAll(Map<String, dynamic>.from(map['property']));
      }
      if ((snap['_id'] == null || snap['_id'].toString().isEmpty) && rootId != null) {
        snap['_id'] = rootId;
      }
      return PropertyModel.fromJson(snap);
    }
    if (map['property'] is Map) {
      final prop = Map<String, dynamic>.from(map['property']);
      if ((prop['_id'] == null || prop['_id'].toString().isEmpty) && rootId != null) {
        prop['_id'] = rootId;
      }
      return PropertyModel.fromJson(prop);
    }
    if (map['data'] is Map && (map['data']['_id'] != null || map['data']['title'] != null || map['data']['name'] != null)) {
      final dataMap = Map<String, dynamic>.from(map['data']);
      if ((dataMap['_id'] == null || dataMap['_id'].toString().isEmpty) && rootId != null) {
        dataMap['_id'] = rootId;
      }
      return PropertyModel.fromJson(dataMap);
    }

    return PropertyModel.fromJson(map);
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // 1. ID
    final id = _firstNonEmptyString(json, ['_id', 'id', 'propertyId', 'mongoId']);

    // 2. Property Code
    String code = _firstNonEmptyString(json, ['propertyCode', 'property_code', 'propertyId', 'id']);
    code = code.replaceAll('#', '').trim();

    // 3. Title & Basic Info
    final title = _firstNonEmptyString(json, ['title', 'name', 'propertyName', 'projectName']);
    final description = _firstNonEmptyString(json, ['description', 'about', 'details']);
    final category = _firstNonEmptyString(json, ['category', 'propertyType', 'type']);
    final transactionType = _firstNonEmptyString(json, ['transactionType', 'transaction_type', 'for', 'purpose']);
    final projectName = _firstNonEmptyString(json, ['projectName', 'project_name', 'project']);
    final developerName = _firstNonEmptyString(json, ['developerName', 'developer_name', 'developer', 'builderName']);

    // 4. Pricing
    final rawPrice = json['price'];
    double? priceAmount;
    if (rawPrice is num) {
      priceAmount = rawPrice.toDouble();
    } else if (rawPrice is String) {
      priceAmount = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), ''));
    } else if (rawPrice is Map) {
      final p = rawPrice['amount'] ?? rawPrice['price'] ?? rawPrice['value'];
      if (p is num) priceAmount = p.toDouble();
    }
    final priceLabel = _firstNonEmptyString(json, ['priceLabel', 'price_label', 'priceString']);
    final pricePerSqft = _firstNonEmptyString(json, ['pricePerSqft', 'price_per_sqft', 'priceSqft']);
    final maintenance = _firstNonEmptyString(json, ['maintenance', 'maintenanceCharge', 'maintenance_charge']);
    final bookingAmount = _firstNonEmptyString(json, ['bookingAmount', 'booking_amount', 'tokenAmount']);

    // 5. Location
    final address = _firstNonEmptyString(json, ['address', 'fullAddress', 'locationName']);
    final locality = _firstNonEmptyString(json, ['locality', 'subLocality', 'area']);
    final city = _firstNonEmptyString(json, ['city']);
    final state = _firstNonEmptyString(json, ['state']);
    final pincode = _firstNonEmptyString(json, ['pincode', 'postalCode', 'zipCode']);

    final lat = _parseDouble(json, ['latitude', 'lat', 'latLocation']);
    final lng = _parseDouble(json, ['longitude', 'lng', 'lon', 'lngLocation']);
    final distanceKm = json['distanceKm'];
    final sameCity = json['sameCity'] as bool?;

    // 6. Specs
    final bedrooms = json['bedrooms'] ?? json['bhk'];
    final bathrooms = json['bathrooms'] ?? json['baths'];
    final balconies = json['balconies'] ?? json['balcony'];
    final facing = _firstNonEmptyString(json, ['facing', 'direction']);
    final furnishing = _firstNonEmptyString(json, ['furnishing', 'furnishStatus', 'statusFurnishing']);
    final floorNo = json['floorNo'] ?? json['floor'] ?? json['floorNumber'];
    final totalFloors = json['totalFloors'] ?? json['total_floors'] ?? json['floors'];
    final carpetArea = json['carpetArea'] ?? json['carpet_area'];
    final superBuiltUpArea = json['superBuiltUpArea'] ??
        json['superBuiltupArea'] ??
        json['super_built_up_area'] ??
        json['sqft'] ??
        json['area'];
    final parking = _firstNonEmptyString(json, ['parking', 'parkingSlots', 'carParking']);

    // 7. Status & Verification
    String status = _firstNonEmptyString(json, [
      'possessionStatus',
      'status',
      'constructionStatus',
      'propertyStatus',
    ]);
    if (status.isEmpty || status.toLowerCase() == 'null') {
      status = 'Ready to Move';
    }

    final verificationStatus = _firstNonEmptyString(json, [
      'propertyVerificationStatus',
      'verificationStatus',
      'verifyStatus',
    ]);
    final isVerified = json['isVerified'] == true ||
        verificationStatus.toLowerCase() == 'verified' ||
        json['verified'] == true;

    final reraNumber = _firstNonEmptyString(json, ['reraNumber', 'rera_number', 'reraId', 'rera_id', 'reraCode']);
    final reraCertificateUrl = _firstNonEmptyString(json, [
      'reraCertificate',
      'rera_certificate',
      'reraCert',
      'reraDoc',
      'reraCertificateUrl',
    ]);

    // 8. Media
    final images = _parseImages(json);
    final videoUrl = _firstNonEmptyString(json, ['video', 'videoUrl', 'video_url', 'videoLink', 'videolink', 'video_link']);
    final floorPlanUrl = _firstNonEmptyString(json, ['floorPlan', 'floor_plan', 'floorPlanUrl', 'floorplan', 'floorPlanImage']);
    final panoramaUrl = _firstNonEmptyString(json, ['panorama_action', 'panorama_image', 'panoramaUrl', 'virtualTour']);

    // 9. Meta
    final amenities = _parseStringList(json['amenities']);
    final tags = _parseStringList(json['tags']);

    return PropertyModel(
      id: id,
      propertyCode: code,
      title: title.isNotEmpty ? title : 'Property',
      description: description,
      category: category,
      transactionType: transactionType,
      projectName: projectName,
      developerName: developerName,
      rawPrice: rawPrice,
      priceAmount: priceAmount,
      priceLabel: priceLabel,
      pricePerSqft: pricePerSqft,
      maintenance: maintenance,
      bookingAmount: bookingAmount,
      address: address,
      locality: locality,
      city: city,
      state: state,
      pincode: pincode,
      latitude: lat,
      longitude: lng,
      distanceKm: distanceKm,
      sameCity: sameCity,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      balconies: balconies,
      facing: facing,
      furnishing: furnishing,
      floorNo: floorNo,
      totalFloors: totalFloors,
      carpetArea: carpetArea,
      superBuiltUpArea: superBuiltUpArea,
      parking: parking,
      status: status,
      verificationStatus: verificationStatus,
      isVerified: isVerified,
      reraNumber: reraNumber,
      reraCertificateUrl: reraCertificateUrl,
      images: images,
      videoUrl: videoUrl,
      floorPlanUrl: floorPlanUrl,
      panoramaUrl: panoramaUrl,
      amenities: amenities,
      tags: tags,
      rawJson: json,
    );
  }

  factory PropertyModel.empty() {
    return const PropertyModel(
      id: '',
      propertyCode: '',
      title: '',
      description: '',
      category: '',
      transactionType: '',
      projectName: '',
      developerName: '',
      rawPrice: null,
      priceAmount: null,
      priceLabel: '',
      pricePerSqft: '',
      maintenance: '',
      bookingAmount: '',
      address: '',
      locality: '',
      city: '',
      state: '',
      pincode: '',
      latitude: null,
      longitude: null,
      distanceKm: null,
      sameCity: null,
      bedrooms: null,
      bathrooms: null,
      balconies: null,
      facing: '',
      furnishing: '',
      floorNo: null,
      totalFloors: null,
      carpetArea: null,
      superBuiltUpArea: null,
      parking: '',
      status: 'Ready to Move',
      verificationStatus: '',
      isVerified: false,
      reraNumber: '',
      reraCertificateUrl: '',
      images: [],
      videoUrl: '',
      floorPlanUrl: '',
      panoramaUrl: '',
      amenities: [],
      tags: [],
      rawJson: {},
    );
  }

  // ==========================================
  // Clean UI Getters (No manual ?? '' needed!)
  // ==========================================

  bool get isEmpty => id.isEmpty && title.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Formatted Price string e.g. "₹ 45.0 L" or "Price on Request"
  String get formattedPrice {
    if (rawPrice != null) return formatPrice(rawPrice);
    if (priceLabel.isNotEmpty) return priceLabel;
    return 'Price on Request';
  }

  /// Full clean display location e.g. "Vijay Nagar, Indore"
  String get formattedLocation {
    final parts = [locality, city, state].where((e) => e.isNotEmpty && e.toLowerCase() != 'null').toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (address.isNotEmpty) return address;
    return formatPropertyLocation(
      locality: locality,
      city: city,
      address: address,
      distanceKm: distanceKm,
      sameCity: sameCity,
    );
  }

  /// Clean BHK string e.g. "3 BHK" or "Commercial" or "Residential"
  String get bhkLabel {
    return formatBedrooms(bedrooms, category: category, bathrooms: bathrooms);
  }

  /// Clean Furnishing status
  String get furnishingLabel {
    return formatFurnishing(furnishing.isNotEmpty ? furnishing : status);
  }

  /// Clean Sqft / Area string e.g. "1450 sq.ft"
  String get areaDisplay {
    final area = superBuiltUpArea ?? carpetArea;
    if (area != null && area.toString().trim() != '0' && area.toString().trim().isNotEmpty) {
      final str = area.toString().trim();
      return str.contains('sq') ? str : '$str sq.ft';
    }
    return '';
  }

  /// Formatted price per sqft e.g. "₹ 4,500 / sq.ft"
  String get formattedPricePerSqft {
    if (pricePerSqft.isEmpty || pricePerSqft == '0') return '';
    String cleaned = pricePerSqft
        .replaceAll(RegExp(r'[₹/]|sq\.?ft|per', caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty || cleaned == '0') return '';
    final numVal = num.tryParse(cleaned.replaceAll(',', ''));
    if (numVal != null && numVal > 0) {
      cleaned = NumberFormat('#,##,###').format(numVal);
    }
    return '₹ $cleaned / sq.ft';
  }

  /// First image URL or placeholder
  String get primaryImageUrl {
    if (images.isNotEmpty) return images.first;
    return '';
  }

  /// Code with '#' prefix for badges: e.g. "#DW-1024"
  String get formattedCode {
    if (propertyCode.isNotEmpty) return '#$propertyCode';
    if (id.isNotEmpty) return '#$id';
    return '';
  }

  bool get hasVideo => videoUrl.isNotEmpty;
  bool get hasFloorPlan => floorPlanUrl.isNotEmpty;
  bool get hasPanorama => panoramaUrl.isNotEmpty;
  bool get hasRera => reraNumber.isNotEmpty || reraCertificateUrl.isNotEmpty;
  bool get hasAmenities => amenities.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;

  bool get isUnderConstruction {
    final s = status.toLowerCase();
    return s.contains('under') || s.contains('construction') || s.contains('upcoming');
  }

    bool get isReadyToMove => !isUnderConstruction;

  /// Clean Property Verification Status (e.g. "Verified")
  String get propertyVerificationStatus {
    if (verificationStatus.isNotEmpty && verificationStatus.toLowerCase() != 'null') {
      if (verificationStatus.toLowerCase() == 'verified') return 'Verified';
      return verificationStatus;
    }
    return isVerified ? 'Verified' : '';
  }

  /// Structured specifications map ready for UI display without null/empty clutter
  Map<String, String> get keySpecifications {
    final Map<String, String> specs = {};

    void addIfValid(String label, dynamic value, [String? suffix]) {
      if (value == null) return;
      final str = value.toString().trim();
      if (str.isNotEmpty && str.toLowerCase() != 'null' && str != '0') {
        specs[label] = suffix != null ? '$str $suffix' : str;
      }
    }

    addIfValid('Status', status);
    addIfValid('Project', projectName);
    addIfValid('Developer', developerName);
    addIfValid('Carpet Area', carpetArea, 'sq.ft');
    addIfValid('Super Built-up', superBuiltUpArea, 'sq.ft');
    addIfValid('Bedrooms', bedrooms);
    addIfValid('Bathrooms', bathrooms);
    addIfValid('Balconies', balconies);
    addIfValid('Facing', facing);
    addIfValid('Furnishing', furnishing);
    addIfValid('Parking', parking);

    if (floorNo != null && totalFloors != null && totalFloors.toString() != '0') {
      specs['Floor'] = '$floorNo of $totalFloors';
    } else if (floorNo != null && floorNo.toString() != '0') {
      specs['Floor'] = '$floorNo';
    }

    if (maintenance.isNotEmpty && maintenance != '0') {
      specs['Maintenance'] = '₹ $maintenance / mo';
    }
    if (bookingAmount.isNotEmpty && bookingAmount != '0') {
      specs['Booking Amount'] = '₹ $bookingAmount';
    }
    if (pricePerSqft.isNotEmpty && pricePerSqft != '0') {
      specs['Price / Sq.Ft'] = '₹ $pricePerSqft';
    }

    return specs;
  }

  /// Converts this model back to `Map<String, dynamic>` for storage or backwards compatibility
  Map<String, dynamic> toJson() {
    if (rawJson.isNotEmpty) return Map<String, dynamic>.from(rawJson);
    return {
      '_id': id,
      'id': id,
      'propertyId': id,
      'propertyCode': propertyCode,
      'title': title,
      'description': description,
      'category': category,
      'transactionType': transactionType,
      'projectName': projectName,
      'developerName': developerName,
      'price': rawPrice ?? priceAmount,
      'priceLabel': priceLabel,
      'pricePerSqft': pricePerSqft,
      'address': address,
      'locality': locality,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'balconies': balconies,
      'facing': facing,
      'furnishing': furnishing,
      'status': status,
      'isVerified': isVerified,
      'images': images,
      'video': videoUrl,
      'floorPlan': floorPlanUrl,
      'amenities': amenities,
      'tags': tags,
    };
  }

  // ==========================================
  // Safe Internal Parsers
  // ==========================================

  static String _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final val = json[key];
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty && str.toLowerCase() != 'null') {
          return str;
        }
      }
    }
    return '';
  }

  static double? _parseDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final val = json[key];
      if (val is num && val != 0) return val.toDouble();
      if (val is String && val.isNotEmpty && val != '0') {
        final parsed = double.tryParse(val);
        if (parsed != null && parsed != 0) return parsed;
      }
    }
    return null;
  }

  static String? _cleanUrl(dynamic val) {
    if (val == null) return null;
    return ImageCase.sanitizeUrl(val.toString());
  }

  static List<String> _parseImages(Map<String, dynamic> json) {
    final List<String> result = [];

    // Check multiple possible image keys from backend, including media object
    dynamic rawImages = json['images'];
    if (rawImages is! List || rawImages.isEmpty) {
      if (json['media'] is Map) {
        final media = json['media'] as Map;
        rawImages = media['images'] ?? media['photos'];
      }
    }
    if (rawImages is! List || rawImages.isEmpty) {
      rawImages = json['photos'] ?? json['gallery'];
    }

    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is String) {
          final clean = _cleanUrl(item);
          if (clean != null) result.add(clean);
        } else if (item is Map) {
          // Try all common URL keys — Cloudinary uses 'secure_url', others use 'url'
          final url = item['secure_url'] ??
              item['url'] ??
              item['imageUrl'] ??
              item['image'] ??
              item['path'] ??
              item['src'];
          final clean = _cleanUrl(url);
          if (clean != null) result.add(clean);
        }
      }
    }

    // Fallback: single image from various possible keys
    if (result.isEmpty) {
      for (final key in [
        'image', 'imageUrl', 'coverImage', 'thumbnail',
        'photo', 'cover', 'featuredImage', 'mainImage',
      ]) {
        final clean = _cleanUrl(json[key]);
        if (clean != null) {
          result.add(clean);
          break;
        }
      }
    }


    return result;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
        .toList();
  }
}
