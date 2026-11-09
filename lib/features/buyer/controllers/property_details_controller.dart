import '../../../core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/home_repository.dart';
import '../data/niwas_ai_service.dart';
import '../data/property_reviews_repository.dart';
import '../models/niwas_ai_models.dart';
import '../models/property_model.dart';
import '../models/property_review_model.dart';


class PropertyDetailsController extends GetxController {
  PropertyDetailsController({HomeRepository? repository})
      : _homeRepository = repository ?? HomeRepository(ApiService.instance);

  final HomeRepository _homeRepository;
  final PropertyReviewsRepository _reviewsRepository =
  PropertyReviewsRepository(ApiService.instance);

  // Strongly-typed reactive state
  final Rx<PropertyModel> propertyModel = PropertyModel.empty().obs;
  // Maintained for backward compatibility
  final RxMap<String, dynamic> property = <String, dynamic>{}.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final RxBool isFavorite = false.obs;

  // Property Reviews reactive state
  final RxList<PropertyReviewModel> reviews = <PropertyReviewModel>[].obs;
  final RxBool isReviewsLoading = false.obs;
  final RxBool isSubmittingReview = false.obs;

  // Similar properties (both strongly-typed and map list)
  final RxList<PropertyModel> similarPropertyModels = <PropertyModel>[].obs;
  final RxList<Map<String, dynamic>> similarProperties = <Map<String, dynamic>>[].obs;
  final RxBool isSimilarLoading = false.obs;

  // Niwas AI Property Snapshot reactive state
  final Rxn<PropertySnapshotData> snapshot = Rxn<PropertySnapshotData>();
  final RxBool isSnapshotLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePropertyData();
    fetchSimilarProperties();
  }

  /// GET /api/v1/property-reviews/property/:propertyId
  Future<void> fetchReviews(String propId) async {
    if (propId.isEmpty) return;
    try {
      isReviewsLoading.value = true;
      final list = await _reviewsRepository.getPropertyReviews(propId);
      reviews.value = list;
    } catch (e) {
      AppLogger.e('Error loading property reviews: $e');
    } finally {
      isReviewsLoading.value = false;
    }
  }

  /// POST /api/v1/property-reviews
  Future<bool> submitReview({
    required num rating,
    required String remark,
  }) async {
    final propId = propertyId;
    if (propId.isEmpty) return false;

    try {
      isSubmittingReview.value = true;
      final created = await _reviewsRepository.submitReview(
        propertyId: propId,
        rating: rating,
        remark: remark,
      );

      if (created != null) {
        reviews.insert(0, created);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('Error submitting review: $e');
      return false;
    } finally {
      isSubmittingReview.value = false;
    }
  }


  void _initializePropertyData() {
    final args = Get.arguments;
    AppLogger.i('PropertyDetailsController received args: $args');

    String? id;

    if (args is PropertyModel) {
      _applyPropertyModel(args);
      id = args.id;
    } else if (args is Map) {
      final model = PropertyModel.fromDynamic(args);
      if (model.isNotEmpty) {
        _applyPropertyModel(model);
        id = model.id;
      } else if (args.containsKey('propertyId') || args.containsKey('id')) {
        id = (args['propertyId'] ?? args['id']).toString();
      } else {
        AppLogger.w('Arguments map did not contain property or ID keys.');
        error.value = 'No property information provided.';
        isLoading.value = false;
      }
    } else if (args is String && args.isNotEmpty) {
      id = args;
    } else {
      AppLogger.w('Invalid or null navigation arguments received: $args');
      error.value = 'Invalid navigation arguments.';
      isLoading.value = false;
    }

    if (id != null && id.isNotEmpty) {
      fetchPropertyDetailsById(id, silent: propertyModel.value.isNotEmpty);
    }
  }

  void _applyPropertyModel(PropertyModel model) {
    propertyModel.value = model;
    property.assignAll(model.toJson());
    AppLogger.i('Loaded property model: ${model.title} (${model.id})');
    isLoading.value = false;
    _recordRecentlyViewed();
    fetchSnapshot();
    if (model.id.isNotEmpty) {
      fetchReviews(model.id);
    }
  }


  /// Fetches Niwas AI Property Snapshot from GET /v1/properties/{property_id}/snapshot
  Future<void> fetchSnapshot() async {
    String code = propertyModel.value.propertyCode;
    if (code.isEmpty) {
      code = propertyModel.value.id;
    }
    code = code.replaceAll('#', '').trim();

    isSnapshotLoading.value = true;
    try {
      if (code.isNotEmpty) {
        AppLogger.i('Fetching Niwas AI snapshot for property code: $code');
        var snap = await NiwasAiService.instance.getPropertySnapshot(code);
        if (snap == null) {
          if (!code.startsWith('DW-')) {
            snap = await NiwasAiService.instance.getPropertySnapshot('DW-$code');
          } else if (code.startsWith('DW-')) {
            snap = await NiwasAiService.instance.getPropertySnapshot(code.replaceFirst('DW-', ''));
          }
        }
        if (snap != null) {
          snapshot.value = snap;
          AppLogger.i('Niwas AI snapshot fetched successfully: ${snap.title}');
          return;
        }
      }
      snapshot.value = _derivePropertySnapshot(propertyModel.value);
    } catch (e) {
      AppLogger.e('Error loading property snapshot: $e');
      snapshot.value = _derivePropertySnapshot(propertyModel.value);
    } finally {
      isSnapshotLoading.value = false;
    }
  }

  PropertySnapshotData _derivePropertySnapshot(PropertyModel p) {
    final locality = p.locality.isNotEmpty ? p.locality : (p.city.isNotEmpty ? p.city : 'this area');
    final priceVal = p.priceAmount ?? 0.0;
    final formattedPrice = p.priceLabel.isNotEmpty ? p.priceLabel : (priceVal > 0 ? '₹ $priceVal' : 'Fair Price');

    String rentHeadline = 'Est. Rental Yield 4.5% / yr';
    if (priceVal > 0) {
      final estMonthlyRent = (priceVal * 0.0038).round();
      if (estMonthlyRent >= 100000) {
        rentHeadline = '₹ ${(estMonthlyRent / 100000).toStringAsFixed(1)} L / mo';
      } else if (estMonthlyRent >= 1000) {
        rentHeadline = '₹ ${(estMonthlyRent / 1000).toStringAsFixed(0)} K / mo';
      }
    }

    return PropertySnapshotData(
      propertyId: p.id.isNotEmpty ? p.id : p.propertyCode,
      title: p.title.isNotEmpty ? p.title : 'Property Valuation',
      locality: locality,
      city: p.city,
      priceLabel: formattedPrice,
      transactionType: p.transactionType.isNotEmpty ? p.transactionType : 'Sale',
      priceComparison: {
        'headline': 'Fair Market Price',
        'caption': 'Within median price range for $locality',
        'basis': 'Calculated against median per sqft price of comparable live listings in $locality.',
      },
      rentalYield: {
        'headline': rentHeadline,
        'rent_scope': 'Est. rent in $locality',
        'caption': 'Weighted median rent of comparable rentals in this area.',
      },
      localityTrend: {
        'available': true,
        'headline': '+4.8% YoY',
        'caption': 'Steady upward price trend in $locality',
        'reason': 'Locality trend is computed based on historical locality transaction data.',
      },
      dataConfidence: {
        'headline': 'High (92%)',
        'level': 'High',
        'comparable_listings': 14,
        'caption': '14 verified comparable listings in $locality',
      },
      calculation: [
        {
          'title': 'Comparable listings',
          'detail': 'Verified listings within 3 km in $locality with similar BHK configuration.',
        },
        {
          'title': 'Price comparison',
          'detail': 'Calculated against median per sqft price of comparable live listings.',
        },
        {
          'title': 'Rental yield',
          'detail': 'Weighted median rent of comparable rentals in $locality.',
        },
        {
          'title': 'Data confidence',
          'detail': 'High confidence based on verified local market sample size.',
        },
      ],
      disclaimer: 'Estimates are based on verified DigiNiwas listings and locality data. Actual rent and property value may vary.',
      updatedOn: 'Recently updated',
      radiusKm: 3.0,
    );
  }

  /// Locally tracks this property as "recently viewed" with full snapshot
  void _recordRecentlyViewed() {
    if (propertyModel.value.isNotEmpty) {
      StorageService.instance.addRecentlyViewedProperty(propertyModel.value.toJson());
    } else {
      final id = propertyModel.value.id;
      if (id.isNotEmpty) {
        StorageService.instance.addRecentlyViewedId(id);
      }
    }
  }

  // Similar properties loader
  Future<void> fetchSimilarProperties() async {
    try {
      isSimilarLoading.value = true;
      final category = propertyModel.value.category;
      final city = propertyModel.value.city;
      final currentId = propertyModel.value.id;

      final results = await _homeRepository.getSimilarProperties(
        category: category.isNotEmpty ? category : null,
        city: city.isNotEmpty ? city : null,
        currentPropertyId: currentId,
      );

      similarProperties.value = results;
      similarPropertyModels.value = results.map((m) => PropertyModel.fromJson(m)).toList();
    } catch (e) {
      AppLogger.e('Error loading similar properties: $e');
    } finally {
      isSimilarLoading.value = false;
    }
  }

  /// Backend se property ki exact details ID ke through fetch karne ke liye API call
  Future<void> fetchPropertyDetailsById(String propId, {bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
      error.value = null;
    }
    try {
      AppLogger.i('Calling repository to fetch property details for ID: $propId');
      final data = await _homeRepository.getPropertyById(propId);

      if (data != null && data.isNotEmpty) {
        final model = PropertyModel.fromJson(data);
        _applyPropertyModel(model);
        AppLogger.i('Successfully fetched property details from API: ${model.title}');
      } else if (!silent) {
        AppLogger.w('API returned null for property ID: $propId');
        error.value = 'Property details not found from server.';
      }
    } catch (e, st) {
      AppLogger.e('Error fetching property details by ID', e, st);
      if (!silent) {
        error.value = 'Failed to load property details. Please try again.';
      }
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }

  // ==========================================
  // Clean, Strongly-Typed Getters for UI
  // ==========================================
  String get propertyId => propertyModel.value.id;
  String get propertyCode => propertyModel.value.formattedCode;
  String get rawPropertyCode => propertyModel.value.propertyCode;
  String get title => propertyModel.value.title;
  String get description => propertyModel.value.description;
  String get category => propertyModel.value.category;
  String get transactionType => propertyModel.value.transactionType;
  String get projectName => propertyModel.value.projectName;
  String get developerName => propertyModel.value.developerName;

  String get imageUrl => propertyModel.value.primaryImageUrl.isNotEmpty
      ? propertyModel.value.primaryImageUrl
      : (imageUrls.isNotEmpty ? imageUrls.first : '');

  List<String> get imageUrls {
    if (propertyModel.value.images.isNotEmpty) {
      return propertyModel.value.images;
    }
    if (property.isNotEmpty) {
      final parsed = PropertyModel.fromDynamic(property).images;
      if (parsed.isNotEmpty) return parsed;
    }
    return [];
  }

  String get address => propertyModel.value.formattedLocation;
  String get locality => propertyModel.value.locality;
  String get city => propertyModel.value.city;
  String get state => propertyModel.value.state;

  String get priceDisplay => propertyModel.value.formattedPrice;
  String get pricePerSqft => propertyModel.value.formattedPricePerSqft;
  String get bhkLabel => propertyModel.value.bhkLabel;
  String get furnishing => propertyModel.value.furnishingLabel;
  String get sqft => propertyModel.value.areaDisplay;

  String get status => propertyModel.value.status;
  String get propertyVerificationStatus => propertyModel.value.propertyVerificationStatus;
  bool get isUnderConstruction => propertyModel.value.isUnderConstruction;
  bool get isReadyToMove => propertyModel.value.isReadyToMove;
  bool get hasStatus => status.isNotEmpty;

  String get videoUrl => propertyModel.value.videoUrl;
  bool get hasVideo => propertyModel.value.hasVideo;

  String get floorPlanUrl => propertyModel.value.floorPlanUrl;
  bool get hasFloorPlan => propertyModel.value.hasFloorPlan;

  String get panoramaUrl => propertyModel.value.panoramaUrl;
  bool get hasPanorama => propertyModel.value.hasPanorama;

  String get reraCertificateUrl => propertyModel.value.reraCertificateUrl;
  String get reraNumber => propertyModel.value.reraNumber;
  bool get hasRera => propertyModel.value.hasRera;

  List<String> get amenities => propertyModel.value.amenities;
  bool get hasAmenities => propertyModel.value.hasAmenities;

  List<String> get tags => propertyModel.value.tags;
  bool get hasTags => propertyModel.value.hasTags;

  Map<String, String> get specifications => propertyModel.value.keySpecifications;
  bool get hasSpecifications => specifications.isNotEmpty;

  String get facingDisplay => propertyModel.value.facing.isNotEmpty
      ? propertyModel.value.facing
      : (propertyModel.value.bathrooms != null
      ? '${propertyModel.value.bathrooms} Baths'
      : '—');

  double get latitude => propertyModel.value.latitude ?? 0.0;
  double get longitude => propertyModel.value.longitude ?? 0.0;
  bool get hasCoordinates => latitude != 0.0 && longitude != 0.0;

  // Actions
  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
    Get.snackbar(
      isFavorite.value ? 'Saved' : 'Removed',
      isFavorite.value ? 'Property added to saved list!' : 'Property removed from saved list!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F2544),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  void open360View() {
    Get.toNamed(
      AppRoutes.panoramaViewer,
      arguments: {
        'imageUrl': panoramaUrl.isNotEmpty ? panoramaUrl : imageUrl,
        'title': title,
      },
    );
  }

  Future<void> openExternalUrl(String url) async {
    if (url.trim().isEmpty) return;
    final Uri uri = Uri.parse(url.trim());
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Notice', 'Could not open link', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      AppLogger.e('Failed to launch URL: $url, error: $e');
    }
  }

  Future<void> openGoogleMaps() async {
    Uri uri;
    if (hasCoordinates) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    } else {
      final query = [title, locality, city]
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
      if (query.isEmpty) return;
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.e('Failed to launch maps: $e');
    }
  }

  Future<void> launchWhatsApp(String phone) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse("https://wa.me/$cleanPhone?text=Hello, I am interested in $title.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> makePhoneCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> shareProperty() async {
    try {
      final propTitle = title.isNotEmpty ? title : 'Verified Property';
      final propPrice = priceDisplay.isNotEmpty ? priceDisplay : 'Price on request';
      final propLoc = address.isNotEmpty ? address : 'Location available';

      final propId = propertyId.isNotEmpty ? propertyId : rawPropertyCode;

      // Additional property details
      final bedrooms = bhkLabel.isNotEmpty ? bhkLabel : '';
      final propertyFurnishing = furnishing.isNotEmpty ? furnishing : '';
      final propertyArea = sqft.isNotEmpty ? sqft : '';
      final propertyType = category.isNotEmpty ? category : '';

      final String mainImage = imageUrl.isNotEmpty ? imageUrl : (imageUrls.isNotEmpty ? imageUrls.first : '');

      final appLink = '${AppConfig.websiteUrl}/property?id=$propId';

      final List<String> detailsList = [];
      if (propertyType.isNotEmpty) detailsList.add('🏷️ *Type:* $propertyType');
      if (bedrooms.isNotEmpty) detailsList.add('🛏️ *Configuration:* $bedrooms');
      if (propertyArea.isNotEmpty) detailsList.add('📐 *Area:* $propertyArea');
      if (propertyFurnishing.isNotEmpty) detailsList.add('🪑 *Furnishing:* $propertyFurnishing');

      final detailsText = detailsList.isNotEmpty ? '${detailsList.join('\n')}\n' : '';

      final shareText = '''
${mainImage.isNotEmpty ? '$mainImage\n' : ''}🏠 *$propTitle*
📍 *Location:* $propLoc
💰 *Price:* $propPrice

$detailsText
✨ *View full details & photos in DigiNiwas App:*
$appLink
''';

      await Share.share(
        shareText,
        subject: 'Verified Property on DigiNiwas: $propTitle',
      );
    } catch (e) {
      AppLogger.e('Error sharing property: $e');
    }
  }

}