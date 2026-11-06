import '../../partner/models/partner_models.dart';
import '../../../core/widgets/app_toast.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/seller_home_feed_model.dart';
import '../models/seller_model.dart';
import '../../buyer/models/buyer_dashboard_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../data/seller_repository.dart';
import '../../partner/controllers/partner_home_controller.dart';

/// GetX Controller for managing Seller Dashboard state & API integrations
class SellerController extends GetxController {
  final SellerRepository _repository;

  SellerController({SellerRepository? repository})
      : _repository = repository ?? SellerRepository();

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    loadSellerAvatar();
    fetchSellerLocation();

    // Subscribe to seller FCM topics
    StorageService.instance.userId.then((uid) {
      NotificationService.instance.syncRoleTopics(
        role: 'seller',
        userId: uid,
      );
    });
  }

  // Observable state variables
  final RxBool isLoading = false.obs;
  final RxBool isSubmittingKYC = false.obs;
  final RxString errorMessage = ''.obs;

  final Rxn<SellerModel> sellerProfile = Rxn<SellerModel>();
  final Rxn<SellerSummaryModel> summaryStats = Rxn<SellerSummaryModel>();
  final RxList<dynamic> sellerProperties = <dynamic>[].obs;
  final Rxn<SellerApplicationModel> currentApplication = Rxn<SellerApplicationModel>();

  // Dynamic Promotion Plans & Submitted Boost Requests
  final RxList<PromotionPlanModel> propertyPromotionPlans = <PromotionPlanModel>[].obs;
  final RxBool promotionPlansLoading = false.obs;

  final RxList<SellerBoostRequestModel> submittedBoostRequests = <SellerBoostRequestModel>[].obs;
  final RxBool boostRequestsLoading = false.obs;

  // ---------------------------------------------------------------------
  // Dashboard Header & Notifications (/api/v1/user/dashboard-header)
  // ---------------------------------------------------------------------
  final Rxn<BuerDashboardModel> dashboardHeader = Rxn<BuerDashboardModel>();
  final RxInt unreadNotificationsCount = 0.obs;
  final RxList<dynamic> notificationsList = <dynamic>[].obs;
  final RxBool notificationsLoading = false.obs;

  // ---------------------------------------------------------------------
  // Profile avatar management & sync
  // ---------------------------------------------------------------------
  final RxString sellerAvatarLocalPath = ''.obs;
  final RxString sellerAvatarNetworkUrl = ''.obs;

  Future<void> loadSellerAvatar() async {
    final local = await StorageService.instance.sellerLocalAvatarPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      sellerAvatarLocalPath.value = local;
    }
    final net = sellerProfile.value?.avatar;
    if (net != null && net.isNotEmpty) {
      sellerAvatarNetworkUrl.value = net;
    }
  }

  Future<void> updateSellerAvatar(String newPath) async {
    sellerAvatarLocalPath.value = newPath;
    await StorageService.instance.saveSellerLocalAvatarPath(newPath);
  }

  // ---------------------------------------------------------------------
  // Seller Location state & GPS capture
  // ---------------------------------------------------------------------
  final RxString sellerLocation = 'Fetching location...'.obs;
  final RxBool isLocationLoading = false.obs;

  Future<void> fetchSellerLocation() async {
    // 1. Check seller profile location
    final locMap = sellerProfile.value?.location;
    if (locMap != null) {
      final city = locMap['city']?.toString() ?? '';
      final locality = locMap['locality']?.toString() ?? '';
      final state = locMap['state']?.toString() ?? '';
      if (locality.isNotEmpty && city.isNotEmpty) {
        sellerLocation.value = '$locality, $city';
        return;
      } else if (city.isNotEmpty) {
        sellerLocation.value = state.isNotEmpty ? '$city, $state' : city;
        return;
      }
    }

    // 2. Check locally stored location
    try {
      final stored = await StorageService.instance.location;
      if (stored != null && stored['city'] != null && stored['city'].toString().isNotEmpty) {
        final city = stored['city'].toString();
        final state = stored['state']?.toString() ?? '';
        sellerLocation.value = state.isNotEmpty ? '$city, $state' : city;
        return;
      }
    } catch (_) {}

    // 3. Try live device location via LocationService
    try {
      isLocationLoading.value = true;
      final result = await LocationService().getCurrentLocation();
      if (result.city.isNotEmpty) {
        sellerLocation.value = result.state.isNotEmpty
            ? '${result.city}, ${result.state}'
            : result.city;
        return;
      }
    } catch (_) {
    } finally {
      isLocationLoading.value = false;
    }

    if (sellerLocation.value == 'Fetching location...') {
      sellerLocation.value = 'Ahmedabad, Gujarat';
    }
  }

  // ---------------------------------------------------------------------
  // Seller Home dashboard state (stat cards, partner card, progress
  // tracker, AI suggestion, recent updates feed).
  // ---------------------------------------------------------------------

  final RxBool isHomeLoading = false.obs;
  final RxString homeError = ''.obs;
  final RxString sellerId = ''.obs;

  final RxList<SellerPropertyBrief> properties = <SellerPropertyBrief>[].obs;
  final Rxn<SellerPropertyBrief> progressProperty = Rxn<SellerPropertyBrief>();

  final RxInt myListingsCount = 0.obs;
  final RxInt partnerReviewCount = 0.obs;
  final RxInt buyerInterestCount = 0.obs;
  final RxInt offersToReviewCount = 0.obs;

  final RxBool aiSuggestionAvailable = false.obs;
  final RxString aiSuggestionBody = ''.obs;

  final RxList<SellerUpdateItem> recentUpdates = <SellerUpdateItem>[].obs;

  // Used by the "My Partner" and "Seller Profile" screens (Site Visits stat
  // card + the onboarding progress card's "Next appointment" notice).
  final RxInt siteVisitsCount = 0.obs;
  final Rxn<DateTime> nextVisitAt = Rxn<DateTime>();

  // Raw leads/visits scoped to this seller's own properties (already
  // filtered down from the assigned partner's full lists inside
  // loadSellerHome). Exposed so screens like Seller Insights can compute
  // their own aggregates (weekly buckets, per-property breakdowns, trend
  // deltas) straight from live data without re-fetching.
  final RxList<Map<String, dynamic>> sellerLeads = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> sellerVisits = <Map<String, dynamic>>[].obs;

  /// Returns the assigned partner name across seller properties or null
  String? get assignedPartnerName {
    if (progressProperty.value?.partnerName?.isNotEmpty == true) {
      return progressProperty.value!.partnerName;
    }
    for (final p in properties) {
      if (p.partnerName != null && p.partnerName!.isNotEmpty) {
        return p.partnerName;
      }
    }
    return null;
  }

  /// Returns the assigned partner phone across seller properties or null
  String? get assignedPartnerPhone {
    if (progressProperty.value?.partnerPhone?.isNotEmpty == true) {
      return progressProperty.value!.partnerPhone;
    }
    for (final p in properties) {
      if (p.partnerPhone != null && p.partnerPhone!.isNotEmpty) {
        return p.partnerPhone;
      }
    }
    return null;
  }

  /// Load complete dashboard data for a given Seller ID
  Future<void> fetchSellerDashboardData(String sellerId) async {
    if (sellerId.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1. Fetch Profile
      try {
        final profile = await _repository.getSellerById(sellerId);
        sellerProfile.value = profile;
        debugPrint('✅ Seller Profile loaded: ${profile.name} (${profile.sellerId})');
      } catch (e) {
        debugPrint('⚠️ Seller Profile fetch notice: $e');
      }

      // 2. Fetch Summary Stats
      try {
        final summary = await _repository.getSellerSummary(sellerId);
        summaryStats.value = summary;
        debugPrint('✅ Seller Summary loaded: Total=${summary.totalProperties}, Listed=${summary.listedProperties}');
      } catch (e) {
        debugPrint('⚠️ Seller Summary fetch notice: $e');
      }

      // 3. Fetch Properties
      try {
        final properties = await _repository.getSellerProperties(sellerId);
        sellerProperties.assignAll(properties);
        debugPrint('✅ Seller Properties loaded: ${properties.length} properties');
      } catch (e) {
        debugPrint('⚠️ Seller Properties fetch notice: $e');
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads everything the Seller Home screen needs, in one call:
  /// profile, stats, properties, and — for whichever partner is handling
  /// the seller's properties — their recent leads & visits (used to derive
  /// "Buyer Interest", "Offers to Review" and the updates feed).
  ///
  /// [silent] keeps the current UI on screen (no full-screen spinner) while
  /// refreshing in the background, e.g. for pull-to-refresh.
  Future<void> loadSellerHome({bool silent = false}) async {
    if (!silent) isHomeLoading.value = true;
    homeError.value = '';

    try {
      final id = await SecureStorageService.instance.getSellerMongoId();
      if (id == null || id.isEmpty) {
        homeError.value = 'Please log in again to load your dashboard.';
        return;
      }
      sellerId.value = id;

      // Load seller notifications
      unawaited(fetchNotifications());

      // Profile — non-fatal if it fails, screen still renders with a
      // generic greeting.
      try {
        sellerProfile.value = await _repository.getSellerById(id);
        loadSellerAvatar();
        fetchSellerLocation();
      } catch (e) {
        debugPrint('⚠️ Seller Home: profile fetch notice: $e');
        loadSellerAvatar();
        fetchSellerLocation();
      }

      // Summary stats — best-effort, "My Listings" also falls back to the
      // property list length below if this fails.
      try {
        summaryStats.value = await _repository.getSellerSummary(id);
      } catch (e) {
        debugPrint('⚠️ Seller Home: summary fetch notice: $e');
      }

      // Properties — drives the stat cards, progress tracker and the
      // assigned-partner card.
      List<SellerPropertyBrief> parsedProperties = [];
      try {
        final raw = await _repository.getSellerProperties(id);
        sellerProperties.assignAll(raw);
        parsedProperties = raw
            .whereType<Map>()
            .map((e) => SellerPropertyBrief.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // If any properties have partnerId but missing partnerName, enrich them
        final partnerIdsToFetch = parsedProperties
            .where((p) => p.partnerId != null && p.partnerId!.isNotEmpty && (p.partnerName == null || p.partnerName!.isEmpty))
            .map((p) => p.partnerId!)
            .toSet();

        if (partnerIdsToFetch.isNotEmpty) {
          final Map<String, Map<String, dynamic>> fetchedPartners = {};
          for (final pid in partnerIdsToFetch) {
            try {
              final pMap = await _repository.getPartnerByIdRaw(pid);
              if (pMap != null && pMap.isNotEmpty) {
                fetchedPartners[pid] = pMap;
              }
            } catch (_) {}
          }

          if (fetchedPartners.isNotEmpty) {
            parsedProperties = parsedProperties.map((p) {
              if (p.partnerId != null && fetchedPartners.containsKey(p.partnerId!)) {
                final pMap = fetchedPartners[p.partnerId!]!;
                return p.copyWith(
                  partnerName: p.partnerName ?? pMap['name']?.toString() ?? pMap['fullName']?.toString() ?? 'DigiNiwas Partner',
                  partnerPhone: p.partnerPhone ?? pMap['phone']?.toString() ?? pMap['mobile']?.toString(),
                  partnerAvatarUrl: p.partnerAvatarUrl ?? pMap['avatar']?.toString() ?? pMap['photo']?.toString(),
                  partnerLocality: p.partnerLocality ?? pMap['city']?.toString() ?? pMap['operatingAreas']?.toString(),
                  partnerVerified: p.partnerVerified || pMap['isVerified'] == true,
                );
              }
              return p;
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Seller Home: properties fetch notice: $e');
      }
      properties.assignAll(parsedProperties);

      final summaryTotal = summaryStats.value?.totalProperties ?? 0;
      myListingsCount.value = parsedProperties.length > summaryTotal
          ? parsedProperties.length
          : summaryTotal;
      partnerReviewCount.value = parsedProperties
          .where((p) =>
              p.stage == SellerPropertyStage.partnerReview ||
              p.stage == SellerPropertyStage.submitted)
          .length;

      // Pick the property to show on the progress tracker: the most
      // recently updated one that hasn't gone live yet, else the most
      // recently updated listing overall.
      final notLive = parsedProperties.where((p) => p.stage != SellerPropertyStage.live).toList()
        ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
      SellerPropertyBrief? focus = notLive.isNotEmpty ? notLive.first : null;
      if (focus == null && parsedProperties.isNotEmpty) {
        final sorted = [...parsedProperties]
          ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
        focus = sorted.first;
      }
      progressProperty.value = focus;

      aiSuggestionAvailable.value = focus?.documentsPending ?? false;
      aiSuggestionBody.value = aiSuggestionAvailable.value
          ? 'Add the ownership document requested by your partner to complete verification.'
          : '';

      // Resolve the partner handling the seller's properties (prefer the
      // one on the focused property, else the first property that has one).
      String? partnerId = focus?.partnerId;
      if (partnerId == null || partnerId.isEmpty) {
        for (final p in parsedProperties) {
          if (p.partnerId != null && p.partnerId!.isNotEmpty) {
            partnerId = p.partnerId;
            break;
          }
        }
      }

      final propertyIds = parsedProperties.map((p) => p.id).where((id) => id.isNotEmpty).toSet();
      List<Map<String, dynamic>> leads = [];
      List<Map<String, dynamic>> visits = [];
      if (partnerId != null && partnerId.isNotEmpty) {
        leads = await _repository.getPartnerLeadsRaw(partnerId);
        visits = await _repository.getPartnerVisitsRaw(partnerId);
      }

      // Scope leads/visits down to this seller's own properties (the
      // partner endpoint returns everything assigned to that partner,
      // which may include other sellers' listings too).
      final myLeads = propertyIds.isEmpty
          ? leads
          : leads.where((l) => propertyIds.contains((l['propertyId'] ?? '').toString())).toList();
      final myVisits = propertyIds.isEmpty
          ? visits
          : visits.where((v) => propertyIds.contains((v['propertyId'] ?? '').toString())).toList();

      buyerInterestCount.value = myLeads.length;
      offersToReviewCount.value = myLeads.where((l) {
        final status = (l['status'] ?? '').toString().toLowerCase();
        return status.contains('offer') || status.contains('negotiat');
      }).length;

      siteVisitsCount.value = myVisits.length;
      sellerLeads.assignAll(myLeads);
      sellerVisits.assignAll(myVisits);

      // Earliest upcoming (not completed/cancelled/rejected) visit across
      // this seller's properties, used for the "Next appointment" notice.
      DateTime? upcoming;
      for (final v in myVisits) {
        final status =
        (v['status'] ?? v['approvalStatus'] ?? '').toString().toLowerCase();
        if (status.contains('cancel') ||
            status.contains('complet') ||
            status.contains('reject')) {
          continue;
        }
        final when = DateTime.tryParse(
          (v['approvedVisitAt'] ?? v['requestedVisitAt'] ?? '').toString(),
        );
        if (when == null) continue;
        if (upcoming == null || when.isBefore(upcoming)) upcoming = when;
      }
      nextVisitAt.value = upcoming;

      recentUpdates.assignAll(_buildRecentUpdates(myLeads, myVisits, parsedProperties));
    } catch (e) {
      homeError.value = 'Could not load your dashboard right now.';
      debugPrint('⚠️ Seller Home: unexpected error: $e');
    } finally {
      isHomeLoading.value = false;
    }
  }

  List<SellerUpdateItem> _buildRecentUpdates(
      List<Map<String, dynamic>> leads,
      List<Map<String, dynamic>> visits,
      List<SellerPropertyBrief> properties,
      ) {
    final items = <SellerUpdateItem>[];

    for (final v in visits) {
      final when = DateTime.tryParse(
        (v['requestedVisitAt'] ?? v['createdAt'] ?? '').toString(),
      ) ??
          DateTime.now();
      final status = (v['status'] ?? '').toString().toLowerCase();
      final who = (v['requestedBy'] is Map ? v['requestedBy']['name'] : null) ??
          (v['buyerSnapshot'] is Map ? v['buyerSnapshot']['name'] : null);
      items.add(SellerUpdateItem(
        kind: SellerUpdateKind.visit,
        title: status.contains('complet')
            ? 'Site visit completed${who != null ? ' with $who' : ''}'
            : 'Site visit requested${who != null ? ' by $who' : ''}',
        timestamp: when,
      ));
    }

    for (final l in leads) {
      final when = DateTime.tryParse((l['createdAt'] ?? '').toString()) ?? DateTime.now();
      final status = (l['status'] ?? '').toString().toLowerCase();
      final isOffer = status.contains('offer') || status.contains('negotiat');
      items.add(SellerUpdateItem(
        kind: isOffer ? SellerUpdateKind.offer : SellerUpdateKind.lead,
        title: isOffer
            ? '1 offer ready for your review'
            : 'New buyer interest${l['name'] != null ? ' from ${l['name']}' : ''}',
        timestamp: when,
      ));
    }

    for (final p in properties) {
      if (p.updatedAt == null) continue;
      items.add(SellerUpdateItem(
        kind: SellerUpdateKind.property,
        title: '${p.title} — ${stageLabel(p.stage)}',
        timestamp: p.updatedAt!,
      ));
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(6).toList();
  }

  /// Send Login OTP to Seller Email
  Future<bool> sendSellerLoginOtp(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _repository.sendLoginOtp(email: email);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify Login OTP and Login Seller
  Future<bool> loginWithOtp(String email, String otp) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _repository.loginWithOtp(email: email, otp: otp);
      if (response['success'] == true && response['data'] != null) {
        sellerProfile.value = SellerModel.fromJson(response['data']);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit Seller Registration Application (no KYC — plain registration
  /// per the API guide: name, email, phone, address, city, state, pinCode,
  /// country, latitude, longitude).
  Future<bool> submitRegistrationApplication({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String country,
    double? latitude,
    double? longitude,
  }) async {
    try {
      isSubmittingKYC.value = true;
      errorMessage.value = '';

      final appResult = await _repository.registerSellerApplication(
        name: name,
        email: email,
        phone: phone,
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
        country: country,
        latitude: latitude,
        longitude: longitude,
      );

      currentApplication.value = appResult;
      AppToast.showSuccess('Registration submitted. Please verify your email.');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isSubmittingKYC.value = false;
    }
  }

  void addOrUpdateLocalProperty(Map<String, dynamic> rawProperty) {
    if (rawProperty.isEmpty) return;
    final pId = (rawProperty['_id'] ?? rawProperty['id'] ?? rawProperty['propertyId'])?.toString();
    if (pId == null || pId.isEmpty) return;

    // 1. Update or insert in sellerProperties
    final existingRawIdx = sellerProperties.indexWhere((p) {
      if (p is Map) {
        final id = (p['_id'] ?? p['id'] ?? p['propertyId'])?.toString();
        return id == pId;
      }
      return false;
    });
    if (existingRawIdx >= 0) {
      sellerProperties[existingRawIdx] = rawProperty;
    } else {
      sellerProperties.insert(0, rawProperty);
    }

    // 2. Update or insert in properties (SellerPropertyBrief)
    final brief = SellerPropertyBrief.fromJson(rawProperty);
    final existingBriefIdx = properties.indexWhere((p) => p.id == brief.id);
    if (existingBriefIdx >= 0) {
      properties[existingBriefIdx] = brief;
    } else {
      properties.insert(0, brief);
    }

    // 3. Update reactive counters
    myListingsCount.value = properties.length;
    partnerReviewCount.value = properties
        .where((p) =>
            p.stage == SellerPropertyStage.partnerReview ||
            p.stage == SellerPropertyStage.submitted)
        .length;
  }

  // ---------------------------------------------------------------------
  // Add Property flow — submits the new listing to POST /api/newproperties.
  // ---------------------------------------------------------------------

  final RxBool isSubmittingProperty = false.obs;
  final RxString submitPropertyError = ''.obs;
  final Rxn<Map<String, dynamic>> submittedProperty = Rxn<Map<String, dynamic>>();

  /// Submits a new property listing on behalf of the logged-in seller.
  /// Returns the created property map on success, null on failure (with
  /// [submitPropertyError] set and a snackbar already shown).
  Future<Map<String, dynamic>?> submitNewProperty({
    required Map<String, dynamic> fields,
    List<File> images = const [],
    File? floorPlan,
    File? reraCertificate,
    File? video,
    List<File> documents = const [],
  }) async {
    try {
      isSubmittingProperty.value = true;
      submitPropertyError.value = '';

      // Attach the logged-in seller or partner's identity as the listing creator
      final currentRoute = Get.currentRoute;
      bool isPartner = currentRoute == AppRoutes.agentAddProperty;
      String creatorRole = 'Seller';
      String? partnerId;
      String? id;

      try {
        final rawUser = await SecureStorageService.instance.getUserData();
        if (rawUser != null && rawUser.isNotEmpty) {
          final userMap = Map<String, dynamic>.from(jsonDecode(rawUser) as Map);
          final roleStr = (userMap['role'] ?? userMap['accountType'] ?? '').toString().toLowerCase();
          if (roleStr == 'partner' || roleStr == 'agent') {
            isPartner = true;
          } else if (roleStr == 'seller') {
            isPartner = false;
          }

          if (isPartner) {
            final pId = (userMap['_id'] ?? userMap['id'] ?? userMap['partnerId'])?.toString();
            id = pId;
            partnerId = pId;
            creatorRole = 'Partner';
          } else {
            creatorRole = 'Seller';
            partnerId = null;
            for (final k in ['_id', 'id', 'userId']) {
              final v = userMap[k]?.toString();
              if (v != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(v.trim())) {
                id = v.trim();
                break;
              }
            }
            id ??= (userMap['_id'] ?? userMap['id'] ?? userMap['userId'] ?? userMap['sellerId'])?.toString();
          }
        }
      } catch (_) {}

      if (!isPartner) {
        if (id == null || id.isEmpty || !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id.trim())) {
          final mId = await SecureStorageService.instance.getSellerMongoId();
          if (mId != null && mId.isNotEmpty) id = mId;
        }
        creatorRole = 'Seller';
        partnerId = null;
      }

      var profile = sellerProfile.value;
      if (creatorRole == 'Seller' && profile == null && id != null && id.isNotEmpty) {
        try {
          profile = await _repository.getSellerById(id);
          sellerProfile.value = profile;
        } catch (e) {
          debugPrint('⚠️ submitNewProperty: could not load seller profile: $e');
        }
      }

      String? sellerCode;
      try {
        final rawUser = await SecureStorageService.instance.getUserData();
        if (rawUser != null && rawUser.isNotEmpty) {
          final uMap = Map<String, dynamic>.from(jsonDecode(rawUser) as Map);
          sellerCode = uMap['sellerId']?.toString();
        }
      } catch (_) {}

      final creatorFields = <String, dynamic>{
        if (id != null && id.isNotEmpty) ...{
          'creatorId': id,
          'userId': id,
          'createdBy': id,
          'ownerId': id,
          if (creatorRole == 'Seller') 'sellerId': (sellerCode != null && sellerCode.isNotEmpty) ? sellerCode : id,
        },
        'creatorRole': creatorRole,
        if (creatorRole == 'Partner' && partnerId != null && partnerId.isNotEmpty) 'partnerId': partnerId,
        if (profile?.name.isNotEmpty ?? false) 'creatorName': profile!.name,
        if (profile?.email.isNotEmpty ?? false) 'creatorEmail': profile!.email,
        if (profile?.phone.isNotEmpty ?? false) 'creatorPhone': profile!.phone,
      };

      final result = await _repository.createProperty(
        fields: {...fields, ...creatorFields},
        images: images,
        floorPlan: floorPlan,
        reraCertificate: reraCertificate,
        video: video,
        documents: documents,
      );

      submittedProperty.value = result;

      // Construct a complete property map merging form fields and server result
      final mergedCreated = <String, dynamic>{
        ...fields,
        ...creatorFields,
        ...result,
        '_id': (result['_id'] ?? result['id'] ?? fields['_id'] ?? 'prop_${DateTime.now().millisecondsSinceEpoch}').toString(),
        'title': (result['title'] ?? result['projectName'] ?? fields['title'] ?? fields['projectName'] ?? 'My Property').toString(),
        'price': result['price'] ?? fields['price'] ?? fields['expectedPrice'],
        'status': (result['status'] ?? result['propertyStatus'] ?? 'Submitted').toString(),
        'createdAt': (result['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
        'updatedAt': (result['updatedAt'] ?? DateTime.now().toIso8601String()).toString(),
      };

      // Immediately cache and update local observable state
      await StorageService.instance.saveSellerCreatedProperty(mergedCreated);
      addOrUpdateLocalProperty(mergedCreated);
      if (Get.isRegistered<SellerController>(tag: 'sellerHome')) {
        Get.find<SellerController>(tag: 'sellerHome').addOrUpdateLocalProperty(mergedCreated);
      }
      if (Get.isRegistered<SellerController>(tag: 'myPropertiesScreen')) {
        Get.find<SellerController>(tag: 'myPropertiesScreen').addOrUpdateLocalProperty(mergedCreated);
      }

      // Auto-reload respective dashboards
      if (creatorRole == 'Seller') {
        await loadSellerHome(silent: true);
        if (Get.isRegistered<SellerController>(tag: 'sellerHome')) {
          await Get.find<SellerController>(tag: 'sellerHome').loadSellerHome(silent: true);
        }
        if (Get.isRegistered<SellerController>(tag: 'myPropertiesScreen')) {
          await Get.find<SellerController>(tag: 'myPropertiesScreen').loadSellerHome(silent: true);
        }
      } else if (creatorRole == 'Partner') {
        if (Get.isRegistered<PartnerHomeController>()) {
          try {
            Get.find<PartnerHomeController>().loadProperties();
          } catch (_) {}
        }
      }

      return result;
    } catch (e) {
      submitPropertyError.value = e.toString();
      return null;
    } finally {
      isSubmittingProperty.value = false;
    }
  }

  /// Delete a seller property: DELETE /api/newproperties/:id/delete
  Future<bool> deleteSellerProperty(String propertyId) async {
    try {
      isLoading.value = true;
      final ok = await _repository.deleteProperty(propertyId);
      if (ok) {
        properties.removeWhere((p) => p.id == propertyId);
        sellerProperties.removeWhere((p) => (p['_id'] ?? p['id']).toString() == propertyId);
        myListingsCount.value = properties.length;
        AppToast.showSuccess('Listing was removed successfully.');
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch live property boost plans (GET /v1/promotion-plans?targetType=PROPERTY)
  Future<void> loadPropertyPromotionPlans() async {
    try {
      promotionPlansLoading.value = true;
      final plans = await _repository.getPromotionPlans();
      propertyPromotionPlans.assignAll(plans);
    } catch (_) {
    } finally {
      promotionPlansLoading.value = false;
    }
  }

  /// Fetch submitted boost requests and track approval status (GET /v1/promotions/seller-requests)
  Future<void> loadSubmittedBoostRequests() async {
    try {
      boostRequestsLoading.value = true;
      final requests = await _repository.getSubmittedBoostRequests();
      submittedBoostRequests.assignAll(requests);
    } catch (_) {
    } finally {
      boostRequestsLoading.value = false;
    }
  }

  /// Submit boost request to assigned partner (POST /v1/promotions/seller-request)
  Future<bool> submitSellerBoostRequest({
    required String propertyId,
    required String promotionType,
    String? message,
  }) async {
    try {
      isLoading.value = true;
      await _repository.submitBoostRequest(
        propertyId: propertyId,
        promotionType: promotionType,
        message: message,
      );
      await loadSubmittedBoostRequests();
      AppToast.showSuccess('Boost request submitted to your assigned partner!');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Boost property
  Future<bool> boostSellerProperty(String propertyId, {String boostType = 'featured', int days = 7}) async {
    try {
      isLoading.value = true;
      await _repository.boostProperty(propertyId, boostType: boostType, days: days);
      await loadSellerHome(silent: true);
      AppToast.showSuccess('Your property is now prioritized for higher visibility.');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Unboost property
  Future<bool> unboostSellerProperty(String propertyId) async {
    try {
      isLoading.value = true;
      await _repository.unboostProperty(propertyId);
      await loadSellerHome(silent: true);
      AppToast.showInfo('Property boost has been paused.');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Change Seller Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      AppToast.showError(errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  // ---------------------------------------------------------------------
  // Notification Actions
  // ---------------------------------------------------------------------
  // ---------------------------------------------------------------------
  // Notification Actions
  // ---------------------------------------------------------------------
  Future<void> loadDashboardHeader() async {
    // Kept for backward compatibility; silently handled if server is seller-role
    try {
      final header = await _repository.getDashboardHeader();
      if (header != null) {
        dashboardHeader.value = header;
      }
    } catch (_) {}
  }

  Future<void> fetchNotifications() async {
    notificationsLoading.value = true;
    try {
      final currentSellerId = sellerId.value.isNotEmpty
          ? sellerId.value
          : (sellerProfile.value?.sellerId ?? sellerProfile.value?.id ?? '');

      List<Map<String, dynamic>> list = [];
      if (currentSellerId.isNotEmpty) {
        list = await _repository.getNotifications(sellerId: currentSellerId);
      }

      // If backend doesn't have a static notification table for sellers (returns empty / 404),
      // we derive real-time notifications directly from live seller property events, visits, and leads!
      if (list.isEmpty) {
        list = await _deriveSellerNotifications();
      }

      final readIds = (await StorageService.instance.getReadNotificationIds()).toSet();
      final clearedIds = (await StorageService.instance.getClearedNotificationIds()).toSet();
      list = list.where((item) {
        final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
        return id.isEmpty || !clearedIds.contains(id);
      }).toList();
      final updatedList = list.map((item) {
        final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
        final isRead = readIds.contains(id) || item['isRead'] == true || item['read'] == true;
        final m = Map<String, dynamic>.from(item);
        m['isRead'] = isRead;
        m['read'] = isRead;
        return m;
      }).toList();

      notificationsList.assignAll(updatedList);
      unreadNotificationsCount.value = updatedList
          .where((item) => item['isRead'] != true && item['read'] != true)
          .length;
      debugPrint('✅ Seller notifications ready: ${updatedList.length} total, unread=${unreadNotificationsCount.value}');

      // 🔔 Fire push notification with sound for new in-app seller notifications
      NotificationService.syncInAppNotificationsToPush(
        notifications: updatedList,
        role: 'seller',
      );
    } catch (e) {
      debugPrint('⚠️ Error fetching seller notifications: $e');
    } finally {
      notificationsLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _deriveSellerNotifications() async {
    final list = <Map<String, dynamic>>[];

    // 1. Visits notifications
    for (final v in sellerVisits) {
      final id = 'visit_${v['_id'] ?? v['id'] ?? v['requestedVisitAt']}';
      final status = (v['status'] ?? v['approvalStatus'] ?? '').toString();
      final buyerName = (v['requestedBy'] is Map ? v['requestedBy']['name'] : null) ??
          (v['buyerSnapshot'] is Map ? v['buyerSnapshot']['name'] : null) ??
          'A prospective buyer';
      final propTitle = v['propertySnapshot']?['title'] ?? v['propertyTitle'] ?? 'your property';
      final when = v['approvedVisitAt'] ?? v['requestedVisitAt'] ?? v['createdAt'];

      String title;
      String body;
      if (status.toLowerCase().contains('complet')) {
        title = 'Site Visit Completed';
        body = 'Visit completed with $buyerName for $propTitle.';
      } else if (status.toLowerCase().contains('approv') || status.toLowerCase().contains('confirm')) {
        title = 'Site Visit Confirmed';
        body = 'Site visit confirmed for $buyerName on $propTitle.';
      } else {
        title = 'Site Visit Requested';
        body = '$buyerName requested a site visit for $propTitle.';
      }

      list.add({
        '_id': id,
        'title': title,
        'body': body,
        'type': 'VISIT',
        'category': 'Visits',
        'createdAt': when?.toString() ?? DateTime.now().toIso8601String(),
        'status': status,
      });
    }

    // 2. Leads & Offers notifications
    for (final l in sellerLeads) {
      final id = 'lead_${l['_id'] ?? l['id'] ?? l['createdAt']}';
      final buyerName = l['name'] ?? l['buyerName'] ?? 'A buyer';
      final status = (l['status'] ?? '').toString().toLowerCase();
      final isOffer = status.contains('offer') || status.contains('negotiat');
      final propTitle = l['propertyTitle'] ?? 'your property';
      final when = l['createdAt'];

      list.add({
        '_id': id,
        'title': isOffer ? 'Offer Ready for Review' : 'New Buyer Inquiry',
        'body': isOffer
            ? 'An offer was submitted by $buyerName for $propTitle.'
            : '$buyerName expressed interest in $propTitle.',
        'type': isOffer ? 'OFFER' : 'LEAD',
        'category': 'Offers',
        'createdAt': when?.toString() ?? DateTime.now().toIso8601String(),
      });
    }

    // 3. Property Stage & Document notifications
    for (final p in properties) {
      if (p.documentsPending) {
        list.add({
          '_id': 'prop_doc_${p.id}',
          'title': 'Documents Required',
          'body': 'Action required: Upload requested documents for ${p.title} to complete verification.',
          'type': 'PROPERTY_DOCS',
          'category': 'Properties',
          'createdAt': p.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }

      if (p.stage == SellerPropertyStage.live) {
        list.add({
          '_id': 'prop_live_${p.id}',
          'title': 'Property is Live',
          'body': '${p.title} is now verified and active on the DigiNiwas marketplace.',
          'type': 'PROPERTY_LIVE',
          'category': 'Properties',
          'createdAt': p.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      } else if (p.stage == SellerPropertyStage.partnerReview) {
        list.add({
          '_id': 'prop_review_${p.id}',
          'title': 'Property Under Partner Review',
          'body': '${p.title} has been assigned to your partner for review and verification.',
          'type': 'PROPERTY_REVIEW',
          'category': 'Properties',
          'createdAt': p.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }

      if (p.partnerName != null && p.partnerName!.isNotEmpty) {
        list.add({
          '_id': 'partner_assign_${p.id}',
          'title': 'Partner Assigned',
          'body': '${p.partnerName} is your dedicated DigiNiwas partner for ${p.title}.',
          'type': 'PARTNER',
          'category': 'Partner',
          'createdAt': p.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }
    }

    // 4. Welcome notification if seller profile is active
    final prof = sellerProfile.value;
    if (prof != null) {
      final welcomeId = prof.id.isNotEmpty ? prof.id : prof.sellerId;
      list.add({
        '_id': 'welcome_seller_$welcomeId',
        'title': 'Welcome to DigiNiwas, ${prof.name}!',
        'body': 'Your seller account is verified. Manage your listings, site visits, and buyer offers seamlessly.',
        'type': 'GENERAL',
        'category': 'General',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      });
    }

    // Sort newest first
    list.sort((a, b) {
      final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });

    return list;
  }

  Future<void> markNotificationAsRead(String id) async {
    for (int i = 0; i < notificationsList.length; i++) {
      final item = notificationsList[i];
      if (item is Map) {
        final itemId = item['_id']?.toString() ?? item['id']?.toString();
        if (itemId == id) {
          final updated = Map<String, dynamic>.from(item);
          updated['isRead'] = true;
          updated['read'] = true;
          notificationsList[i] = updated;
          break;
        }
      }
    }
    if (unreadNotificationsCount.value > 0) {
      unreadNotificationsCount.value--;
    }
    await StorageService.instance.markNotificationIdAsRead(id);
    await _repository.markNotificationAsRead(id);
  }

  Future<void> deleteNotification(String id) async {
    if (id.isEmpty) return;
    notificationsList.removeWhere((item) {
      if (item is Map) {
        final itemId = item['_id']?.toString() ?? item['id']?.toString() ?? item['notificationId']?.toString();
        return itemId == id;
      }
      return false;
    });
    unreadNotificationsCount.value = notificationsList
        .where((item) => item is Map && item['isRead'] != true && item['read'] != true)
        .length;
    await StorageService.instance.addClearedNotificationIds([id]);
    await StorageService.instance.markNotificationIdAsRead(id);
    try {
      if (!id.startsWith('notif_')) {
        await _repository.deleteNotification(id);
      }
    } catch (_) {}
  }

  /// Saari notifications list se hata deta hai. Ids local storage me save
  /// hoti hain, isliye refresh / dobara fetch par wapas nahi aayengi.
  Future<void> clearAllNotifications() async {
    final ids = <String>[];
    for (final n in notificationsList) {
      if (n is Map) {
        final id = n['_id']?.toString() ?? n['id']?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    }
    notificationsList.clear();
    unreadNotificationsCount.value = 0;
    await StorageService.instance.addClearedNotificationIds(ids);
    await StorageService.instance.markAllNotificationIdsAsRead(ids);
    await _repository.markAllNotificationsAsRead();
  }

  Future<void> markAllNotificationsAsRead() async {
    final allIds = <String>[];
    for (int i = 0; i < notificationsList.length; i++) {
      if (notificationsList[i] is Map) {
        final item = notificationsList[i] as Map;
        final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
        if (id.isNotEmpty) allIds.add(id);
        final updated = Map<String, dynamic>.from(item);
        updated['isRead'] = true;
        updated['read'] = true;
        notificationsList[i] = updated;
      }
    }
    unreadNotificationsCount.value = 0;
    await StorageService.instance.markAllNotificationIdsAsRead(allIds);
    await _repository.markAllNotificationsAsRead();
  }
}
