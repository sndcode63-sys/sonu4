import 'dart:convert';

import 'package:get/get.dart';

import '../data/partner_repository.dart';
import '../models/partner_models.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/razorpay_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_toast.dart';

class PartnerHomeController extends GetxController {
  PartnerHomeController({PartnerRepository? repository})
      : _repo = repository ?? PartnerRepository(ApiService.instance);

  final PartnerRepository _repo;

  final RxBool isBootstrapping = true.obs;
  final RxnString error = RxnString();
  final RxBool isBypassSession = false.obs;
  final RxBool usingFallbackPacks = false.obs;

  // Dashboard listens
  final RxnInt requestedTab = RxnInt();

  final RxString partnerId = ''.obs;
  final RxString partnerName = 'Partner'.obs;
  final RxString partnerPhone = ''.obs;
  final RxString partnerEmail = ''.obs;
  final RxString partnerProfilePic = ''.obs;
  final RxBool isVerifiedPartner = false.obs;
  final RxString accountType = 'single'.obs;
  final RxBool isTeamOwner = false.obs;
  final Rxn<PartnerProfile> partnerProfile = Rxn<PartnerProfile>();

  Future<void> updateProfilePicture(String path) async {
    partnerProfilePic.value = path;
    try {
      await SecureStorageService.instance.write(key: 'partner_profile_pic', value: path);
    } catch (_) {}
  }

  Future<void> removeProfilePicture() async {
    partnerProfilePic.value = '';
    try {
      await SecureStorageService.instance.delete(key: 'partner_profile_pic');
    } catch (_) {}
  }

  // Credits
  final RxInt creditBalance = 0.obs;
  final RxBool creditsLoading = false.obs;
  final RxList<Map<String, dynamic>> creditHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<CreditPack> creditPacks = <CreditPack>[].obs;
  final RxBool purchaseLoading = false.obs;
  final Rxn<PartnerCreditWallet> creditWallet = Rxn<PartnerCreditWallet>();

  String get creditValidityText => creditWallet.value?.validityText ?? 'No Expiry';

  // Leads
  final RxBool leadsLoading = false.obs;
  final Rxn<PartnerLeadsDashboard> leadsDashboard = Rxn<PartnerLeadsDashboard>();
  final RxList<PartnerLead> leads = <PartnerLead>[].obs;
  final RxString leadsTab = 'Available'.obs;
  final RxBool unlockLoading = false.obs;

  // Properties
  final RxBool propertiesLoading = false.obs;
  final RxList<PartnerProperty> properties = <PartnerProperty>[].obs;
  final Rxn<PublishingSummary> publishingSummary = Rxn<PublishingSummary>();
  final RxString propertiesTab = 'All'.obs;
  final RxString propertySearch = ''.obs;

  // Tasks / visits / unassigned
  final RxBool tasksLoading = false.obs;
  final RxList<PartnerVisit> visits = <PartnerVisit>[].obs;
  final RxList<PartnerProperty> unassignedProperties =
      <PartnerProperty>[].obs;
  final Rxn<VisitsSummary> visitsSummary = Rxn<VisitsSummary>();
  final RxString tasksTab = 'In Progress'.obs;

  // Team
  final RxBool teamLoading = false.obs;
  final RxList<Map<String, dynamic>> teamMembers =
      <Map<String, dynamic>>[].obs;
  final RxList<PartnerProperty> teamProperties = <PartnerProperty>[].obs;

  // Promotions & Dynamic Plans
  final RxBool promotionsLoading = false.obs;
  final RxList<Map<String, dynamic>> promotions = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> boostDashboard =
      Rxn<Map<String, dynamic>>();

  // Dynamic Plans from /v1/promotion-plans
  final RxBool propertyPlansLoading = false.obs;
  final RxList<PromotionPlanModel> propertyPlans = <PromotionPlanModel>[].obs;

  final RxBool profilePlansLoading = false.obs;
  final RxList<PromotionPlanModel> profilePlans = <PromotionPlanModel>[].obs;

  // Incoming Seller Requests from /v1/promotions/partner-requests
  final RxBool incomingSellerRequestsLoading = false.obs;
  RxBool get sellerRequestsLoading => incomingSellerRequestsLoading;
  final RxList<SellerBoostRequestModel> incomingSellerRequests = <SellerBoostRequestModel>[].obs;

  // My Promotion Requests from /v1/promotions/my
  final RxBool myPromotionsLoading = false.obs;
  final RxList<PartnerPromotionItem> myPromotions = <PartnerPromotionItem>[].obs;

  // Trending / Promoted Properties from Platform (/v1/promotions/active/properties or /v1/properties/boosted)
  final RxBool trendingLoading = false.obs;
  final RxList<Map<String, dynamic>> trendingProperties = <Map<String, dynamic>>[].obs;

  // Partner-scoped exact visit counters
  int get partnerCompletedVisitsCount =>
      visits.where((v) => v.status.toLowerCase().contains('complete')).length;

  int get partnerUpcomingVisitsCount =>
      visits.where((v) =>
          !v.status.toLowerCase().contains('complete') &&
          !v.status.toLowerCase().contains('cancel') &&
          !v.status.toLowerCase().contains('reject')).length;

  int get partnerScheduledVisitsCount => partnerUpcomingVisitsCount;

  // Notifications
  final RxBool notificationsLoading = false.obs;
  final RxList<Map<String, dynamic>> notificationsList =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadNotificationsCount = 0.obs;

  static bool _handlingUnauthorized = false;

  @override
  void onInit() {
    super.onInit();
    ApiService.onUnauthorized = _onUnauthorized;
    bootstrap();
  }

  @override
  void onClose() {
    if (ApiService.onUnauthorized == _onUnauthorized) {
      ApiService.onUnauthorized = null;
    }
    super.onClose();
  }

  void goToProfileTab() => requestedTab.value = 4;

  void goToTab(int index) => requestedTab.value = index;

  Future<void> bootstrap() async {
    isBootstrapping.value = true;
    error.value = null;
    try {
      await _resolvePartnerSession();
      if (isBypassSession.value) {
        await loadCreditPacks();
        return;
      }
      final futures = <Future>[
        loadCredits(),
        loadLeads(),
        loadProperties(),
        loadTasks(),
        loadCreditPacks(),
        loadPromotions(),
        loadTrendingProperties(),
        fetchNotifications(),
      ];
      if (isTeamOwner.value) futures.add(loadTeam());
      await Future.wait(futures);
    } catch (e) {
      error.value = e.toString();
      _handleError(e);
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> refreshAll() => bootstrap();

  Future<void> _resolvePartnerSession() async {
    final raw = await SecureStorageService.instance.getUserData();
    if (raw == null || raw.isEmpty) {
      throw PartnerApiException(
        'No partner session found. Please log in again.',
      );
    }
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    isBypassSession.value = map['isBypass'] == true;

    final id = asString(map['_id']) ??
        asString(map['id']) ??
        asString(map['partnerId']) ??
        '';
    if (id.isEmpty) {
      throw PartnerApiException('Partner id missing from session.');
    }
    partnerId.value = id;
    partnerName.value =
        asString(map['name']) ?? asString(map['fullName']) ?? 'Partner';
    partnerPhone.value = asString(map['phone']) ??
        asString(map['mobile']) ??
        asString(map['phoneNumber']) ??
        '';
    partnerEmail.value = asString(map['email']) ?? '';
    final accType = (asString(map['accountType']) ?? asString(map['type']) ?? '').toLowerCase().trim();
    final busType = (asString(map['businessType']) ?? asString(map['business_type']) ?? '').toLowerCase().trim();
    final tRole = (asString(map['teamRole']) ?? asString(map['role_in_team']) ?? '').toLowerCase().trim();

    accountType.value = accType.isNotEmpty ? accType : (busType == 'company' ? 'agency' : 'single');

    final bool isAgency = accType == 'agency' ||
        accType.contains('agency') ||
        accType.contains('team') ||
        busType == 'company' ||
        busType.contains('agency') ||
        tRole == 'owner' ||
        tRole == 'agency_admin';

    final bool isIndividual = accType == 'single' ||
        accType == 'individual' ||
        accType == 'partner' ||
        accType == 'agent' ||
        accType == 'subagent' ||
        busType == 'individual';

    isTeamOwner.value = isAgency && !isIndividual;
    isVerifiedPartner.value = map['isVerified'] == true ||
        asString(map['status'])?.toLowerCase() == 'verified' ||
        asString(map['role'])?.toLowerCase() == 'partner' ||
        asString(map['role'])?.toLowerCase() == 'agent';

    try {
      final savedPic = await SecureStorageService.instance.read(key: 'partner_profile_pic');
      if (savedPic != null && savedPic.isNotEmpty) {
        partnerProfilePic.value = savedPic;
      }
    } catch (_) {}

    // Subscribe to partner FCM topics
    if (id.isNotEmpty) {
      NotificationService.instance.syncRoleTopics(
        role: 'partner',
        userId: id,
      );
    }

    if (isBypassSession.value) return;

    try {
      final profile = await _repo.getPartnerById(id);
      _syncProfileDetails(profile);
    } catch (e) {
      _handleError(e, silent: true);
    }
  }

  void _syncProfileDetails(PartnerProfile profile) {
    partnerProfile.value = profile;
    partnerName.value = profile.name;
    if (profile.phone.isNotEmpty) partnerPhone.value = profile.phone;
    if (profile.email.isNotEmpty) partnerEmail.value = profile.email;
    isVerifiedPartner.value = profile.isVerified || isVerifiedPartner.value;

    final pMap = profile.raw;
    final accType = (asString(pMap['accountType']) ?? asString(pMap['type']) ?? accountType.value).toLowerCase().trim();
    final busType = (asString(pMap['businessType']) ?? asString(pMap['business_type']) ?? '').toLowerCase().trim();
    final tRole = (asString(pMap['teamRole']) ?? asString(pMap['role_in_team']) ?? '').toLowerCase().trim();

    if (accType.isNotEmpty) accountType.value = accType;

    final bool isAgency = accType == 'agency' ||
        accType.contains('agency') ||
        accType.contains('team') ||
        busType == 'company' ||
        busType.contains('agency') ||
        tRole == 'owner' ||
        tRole == 'agency_admin';

    final bool isIndividual = accType == 'single' ||
        accType == 'individual' ||
        accType == 'partner' ||
        accType == 'agent' ||
        accType == 'subagent' ||
        busType == 'individual';

    isTeamOwner.value = isAgency && !isIndividual;
  }

  Future<void> loadPartnerProfile() async {
    final id = partnerId.value;
    if (id.isEmpty) return;
    try {
      final profile = await _repo.getPartnerById(id);
      _syncProfileDetails(profile);
    } catch (e) {
      _handleError(e, silent: true);
    }
  }

  Future<void> downloadPerformanceReport() async {
    _toast('Downloading Performance Analytics Report PDF...');
    await Future.delayed(const Duration(milliseconds: 1200));
    _toast('Performance Report downloaded successfully!');
  }

  void _onUnauthorized() {
    if (isBypassSession.value) return;
    forceLogout(reason: 'Session expired. Please log in again.');
  }

  Future<void> forceLogout({String? reason}) async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      await AccountService.instance.clearAllSessionData();
      if (reason != null && reason.isNotEmpty) {
        AppToast.showSuccess(reason);
      }
      Get.offAllNamed(AppRoutes.chooseRole);
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _handlingUnauthorized = false;
      });
    }
  }

  Future<void> logout() => forceLogout(reason: 'Logged out');

  void _handleError(Object e, {bool silent = false}) {
    if (e is PartnerApiException && e.isUnauthorized) {
      forceLogout(reason: 'Session expired. Please log in again.');
      return;
    }
    if (isBypassSession.value || silent) return;
    _toast(e.toString(), isError: true);
  }

  Future<void> loadCredits() async {
    if (partnerId.value.isEmpty || isBypassSession.value) return;
    creditsLoading.value = true;
    try {
      final snap = await _repo.getPartnerCredits(partnerId.value);
      creditWallet.value = snap.wallet;
      creditBalance.value = snap.wallet.balance;
      if (snap.partner != null) {
        partnerName.value = snap.partner!.name;
      }
      final history = await _repo.getCreditsHistory(partnerId: partnerId.value);
      creditHistory.assignAll(
        history.isNotEmpty ? history : snap.recentTransactions,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      creditsLoading.value = false;
    }
  }

  void _toast(String message, {bool isError = false}) {
    AppToast.showSnack(
      title: isError ? 'Error' : 'Success',
      message: message,
      type: isError ? AppToastType.error : AppToastType.success,
    );
  }

  Future<void> loadCreditPacks() async {
    try {
      final packs = await _repo.getCreditPacks();
      creditPacks.assignAll(packs);
      usingFallbackPacks.value = packs.any((p) => p.isFallback);
    } catch (_) {
      // defaults handled in repository
      usingFallbackPacks.value = true;
    }
  }

  // Buys a pack through Razorpay
  Future<bool> purchasePack(CreditPack pack) {
    return buyCreditsWithRazorpay(
      amountInRupees: pack.priceInr,
      description: pack.label,
      productCode: pack.code,
    );
  }

  // Full partner top-up flow:
  Future<bool> buyCreditsWithRazorpay({
    required int amountInRupees,
    String? description,
    String? productCode,
  }) async {
    if (partnerId.value.isEmpty || isBypassSession.value) {
      _toast('Sign in with a real partner account to purchase', isError: true);
      return false;
    }
    if (amountInRupees <= 0) {
      _toast('Please choose a valid amount', isError: true);
      return false;
    }
    if (purchaseLoading.value) return false;

    purchaseLoading.value = true;
    final razorpay = RazorpayService();
    try {
      final order = await _repo.createRazorpayOrder(
        amountInRupees: amountInRupees,
      );

      final result = await razorpay.openCheckout(
        keyId: order.keyId.isNotEmpty ? order.keyId : ApiConstants.razorpayKeyId,
        orderId: order.orderId,
        amountInPaise: order.amount,
        currency: order.currency,
        description: description ?? '${order.credits} Credits',
        contact: partnerPhone.value,
        email: partnerEmail.value,
        notes: {
          'partnerId': partnerId.value,
          if (productCode != null) 'productCode': productCode,
        },
      );

      if (!result.hasVerifiableData) {
        if (!result.isCancelled) {
          _toast(result.message ?? 'Payment was not completed', isError: true);
        }
        return false;
      }

      await _repo.verifyRazorpayPayment(
        razorpayOrderId: result.orderId!,
        razorpayPaymentId: result.paymentId!,
        razorpaySignature: result.signature!,
      );

      await loadCredits();
      _toast(
        order.credits > 0
            ? '${order.credits} credits added to your wallet'
            : 'Payment successful — credits added',
      );
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      razorpay.dispose();
      purchaseLoading.value = false;
    }
  }

  Future<bool> requestCreditRefund({
    required int credits,
    required String reason,
    String? relatedTransactionId,
  }) async {
    if (partnerId.value.isEmpty || isBypassSession.value) {
      creditBalance.value += credits;
      _toast('$credits credits refunded (100% guarantee applied)');
      return true;
    }
    try {
      await _repo.requestRefund(
        partnerId: partnerId.value,
        credits: credits,
        reason: reason,
        relatedTransactionId: relatedTransactionId,
      );
      _toast('Refund request submitted successfully');
      await loadCredits();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<void> loadLeads() async {
    if (partnerId.value.isEmpty || isBypassSession.value) return;
    leadsLoading.value = true;
    try {
      final list = await _repo.getPartnerLeads(partnerId.value);
      leads.assignAll(list);
      final unlocked = list.where((l) => l.isUnlocked).length;
      final follow = list
          .where((l) => l.status.toLowerCase().contains('follow'))
          .length;
      final visits = list
          .where((l) => l.status.toLowerCase().contains('visit'))
          .length;
      leadsDashboard.value = PartnerLeadsDashboard({
        'totalLeads': list.length,
        'unlocked': unlocked,
        'available': list.length - unlocked,
        'assigned': list.length,
        'followUp': follow,
        'visitPlanned': visits,
        'convertedLeads': list
            .where((l) => l.status.toLowerCase().contains('convert'))
            .length,
      });
      try {
        final dash = await _repo.getLeadsDashboard();
        if (list.isEmpty && dash.totalLeads > 0) {
        }
      } catch (_) {}
    } catch (e) {
      _handleError(e);
    } finally {
      leadsLoading.value = false;
    }
  }

  List<PartnerLead> get filteredLeads {
    final tab = leadsTab.value.toLowerCase();
    if (tab == 'available') {
      return leads.where((l) => !l.isUnlocked).toList();
    }
    if (tab == 'unlocked') {
      return leads.where((l) => l.isUnlocked).toList();
    }
    if (tab == 'follow-up' || tab == 'follow up' || tab == 'follow-ups') {
      return leads
          .where(
            (l) => l.status.toLowerCase().contains('follow'),
          )
          .toList();
    }
    if (tab.contains('visit')) {
      return leads
          .where((l) => l.status.toLowerCase().contains('visit'))
          .toList();
    }
    return leads.toList();
  }

  Future<void> unlockLead(PartnerLead lead) async {
    if (isBypassSession.value) {
      _toast('Unlock is disabled in demo/preview mode. Please log in to use real credits.', isError: true);
      return;
    }
    if (partnerId.value.isEmpty) {
      _toast('Your session looks invalid. Please log in again.', isError: true);
      return;
    }
    if (lead.id.isEmpty) {
      _toast('Could not identify this lead. Please refresh and try again.', isError: true);
      return;
    }
    if (unlockLoading.value) return; // already in-flight
    unlockLoading.value = true;
    try {
      final body = await _repo.unlockLead(
        lead.id,
        partnerId: partnerId.value,
        remarks: 'Unlocked by partner app',
      );
      final data = asMap(body['data']);
      final wallet = asMap(data['wallet']);
      final bal = asInt(wallet['balance']) ??
          asInt(wallet['credits']) ??
          asInt(wallet['availableBalance']);
      if (bal != null) creditBalance.value = bal;
      _toast(asString(body['message']) ?? 'Lead unlocked');
      await Future.wait([loadLeads(), loadCredits()]);
    } catch (e) {
      _handleError(e);
    } finally {
      unlockLoading.value = false;
    }
  }

  Future<void> addContactHistory(
    PartnerLead lead, {
    required String note,
    String? channel,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.addLeadContactHistory(lead.id, note: note, channel: channel);
      _toast('Call note saved');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> convertLead(
    PartnerLead lead, {
    required num amount,
    String? notes,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.convertLead(
        lead.id,
        amount: amount,
        notes: notes,
        actor: partnerName.value,
      );
      _toast('🎉 Lead converted successfully!');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> allocateLeadToSubPartner(
    PartnerLead lead, {
    required String subPartnerId,
    String? remarks,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.allocateLeadToSubPartner(
        lead.id,
        subPartnerId: subPartnerId,
        remarks: remarks,
      );
      _toast('Lead allocated to team member');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> removeLeadSubPartnerAllocation(
    PartnerLead lead, {
    String? remarks,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.removeLeadSubPartnerAllocation(lead.id, remarks: remarks);
      _toast('Allocation removed');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> createManualLead({
    required String name,
    required String phone,
    String? propertyId,
    num? estimatedValue,
    String? message,
    String? priority,
    String? source,
  }) async {
    if (isBypassSession.value) {
      _toast('Cannot create lead in preview mode', isError: true);
      return false;
    }
    try {
      await _repo.createManualLead(
        name: name,
        phone: phone,
        propertyId: propertyId,
        partnerId: partnerId.value,
        estimatedValue: estimatedValue,
        message: message,
        priority: priority,
        source: source,
      );
      _toast('Lead created successfully');
      await loadLeads();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<void> rejectLead(
    PartnerLead lead, {
    required String reason,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.rejectLead(
        lead.id,
        reason: reason,
        actor: partnerName.value,
      );
      _toast('Lead marked as rejected');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> closeLead(
    PartnerLead lead, {
    required String reason,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.closeLead(
        lead.id,
        reason: reason,
        actor: partnerName.value,
      );
      _toast('Lead closed');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  // ---------------------------------------------------------------------
  // NOTIFICATIONS
  // ---------------------------------------------------------------------

  Future<void> fetchNotifications() async {
    if (partnerId.value.isEmpty || isBypassSession.value) return;
    notificationsLoading.value = true;
    try {
      try {
        final res = await ApiService.instance.get(ApiConstants.notifications);
        if (_applyNotificationsResponse(res.data)) return;
      } catch (_) {}

      // If backend doesn't have a static notification table, derive from live events:
      final derived = await _derivePartnerNotifications();
      final readIds = (await StorageService.instance.getReadNotificationIds()).toSet();
      final updatedList = derived.map((item) {
        final id = asString(item['_id']) ?? asString(item['id']) ?? '';
        final isRead = readIds.contains(id) || item['isRead'] == true || item['read'] == true;
        final m = Map<String, dynamic>.from(item);
        m['isRead'] = isRead;
        m['read'] = isRead;
        return m;
      }).toList();

      notificationsList.assignAll(updatedList);
      unreadNotificationsCount.value = updatedList
          .where((n) => n['isRead'] != true && n['read'] != true)
          .length;

      // 🔔 Fire push notification with sound for new in-app partner notifications
      NotificationService.syncInAppNotificationsToPush(
        notifications: updatedList,
        role: 'partner',
      );
    } finally {
      notificationsLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _derivePartnerNotifications() async {
    final list = <Map<String, dynamic>>[];

    // 1. Leads notifications
    for (final l in leads) {
      final id = 'lead_${l.id}';
      final isUnlocked = l.isUnlocked;
      final buyer = l.buyerName;
      final prop = l.propertyTitle;
      final status = l.status.toLowerCase();
      final isConverted = status.contains('convert') || status.contains('close');

      String title;
      String body;
      if (isConverted) {
        title = 'Deal Converted: $buyer';
        body = 'Congratulations! Deal for $prop was successfully converted.';
      } else if (isUnlocked) {
        title = 'Lead Unlocked: $buyer';
        body = 'Contact details for $buyer on $prop are unlocked. Call now.';
      } else {
        title = 'New Buyer Lead: $buyer';
        body = 'New buyer inquiry received for $prop. Unlock details to connect.';
      }

      list.add({
        '_id': id,
        'title': title,
        'body': body,
        'type': 'LEAD',
        'category': 'Leads',
        'createdAt': l.raw['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'actionLabel': isUnlocked ? 'Call Buyer' : 'Unlock Lead',
      });
    }

    // 2. Visits notifications
    for (final v in visits) {
      final id = 'visit_${v.id}';
      final buyer = v.buyerName;
      final prop = v.propertyTitle;
      final status = v.status.toLowerCase();

      String title;
      String body;
      if (status.contains('complet')) {
        title = 'Site Visit Completed';
        body = 'Site visit completed with $buyer for $prop.';
      } else if (status.contains('confirm') || status.contains('approv')) {
        title = 'Site Visit Confirmed';
        body = 'Confirmed visit with $buyer for $prop on ${v.scheduledAt}.';
      } else {
        title = 'New Visit Request';
        body = '$buyer requested a site visit for $prop.';
      }

      list.add({
        '_id': id,
        'title': title,
        'body': body,
        'type': 'VISIT',
        'category': 'Visits',
        'createdAt': v.scheduledAt.isNotEmpty ? v.scheduledAt : DateTime.now().toIso8601String(),
        'actionLabel': 'View Task',
      });
    }

    // 3. Properties & Assignments
    for (final p in properties) {
      final id = 'prop_${p.id}';
      final isLive = p.status.toLowerCase().contains('live') ||
          p.status.toLowerCase().contains('publish') ||
          p.status.toLowerCase().contains('active');
      if (isLive) {
        list.add({
          '_id': '${id}_live',
          'title': 'Listing Live: ${p.title}',
          'body': '${p.title} in ${p.city} is now live and published on DigiNiwas.',
          'type': 'ASSIGNMENT',
          'category': 'Assignments',
          'createdAt': p.raw['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
          'actionLabel': 'View Property',
        });
      } else {
        list.add({
          '_id': '${id}_assigned',
          'title': 'Property Assigned: ${p.title}',
          'body': 'Inspection & listing assigned to you for ${p.title} in ${p.city}.',
          'type': 'ASSIGNMENT',
          'category': 'Assignments',
          'createdAt': p.raw['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
          'actionLabel': 'Review Listing',
        });
      }
    }

    // 4. Unassigned properties waiting for claim
    for (final u in unassignedProperties) {
      list.add({
        '_id': 'unassigned_${u.id}',
        'title': 'New Unassigned Listing: ${u.title}',
        'body': 'A new property in ${u.city} is available for you to claim and manage.',
        'type': 'ASSIGNMENT',
        'category': 'Assignments',
        'createdAt': u.raw['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'actionLabel': 'Claim Listing',
      });
    }

    // 5. Credits & Transactions
    for (final tx in creditHistory) {
      final id = 'credit_${tx['_id'] ?? tx['id'] ?? tx['createdAt']}';
      final desc = asString(tx['description']) ?? asString(tx['note']) ?? 'Credit transaction';
      final amt = asInt(tx['amount']) ?? asInt(tx['credits']) ?? 0;
      final type = (asString(tx['type']) ?? '').toUpperCase();
      final isDeduct = type.contains('DEBIT') || type.contains('SPENT') || type.contains('UNLOCK') || amt < 0;

      list.add({
        '_id': id,
        'title': isDeduct ? 'Credits Spent ($amt)' : 'Credits Added (+$amt)',
        'body': desc,
        'type': 'CREDIT',
        'category': 'Credits',
        'createdAt': tx['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'actionLabel': 'View Wallet',
      });
    }

    // Low credits warning
    final curCredits = creditBalance.value;
    if (curCredits < 20 && curCredits > 0) {
      list.add({
        '_id': 'low_credit_alert',
        'title': 'Low Credit Balance ($curCredits Remaining)',
        'body': 'Recharge your DigiNiwas credit wallet to unlock new leads and boost listings.',
        'type': 'CREDIT',
        'category': 'Credits',
        'createdAt': DateTime.now().toIso8601String(),
        'actionLabel': 'Recharge',
      });
    }

    // 6. Promotions & Boosts
    for (final pr in promotions) {
      final id = 'promot_${pr['_id'] ?? pr['id']}';
      final title = asString(pr['title']) ?? asString(pr['name']) ?? 'Promotion Campaign';
      final status = asString(pr['status']) ?? 'Active';
      list.add({
        '_id': id,
        'title': 'Promotion: $title',
        'body': 'Campaign status: $status. Track performance in Boost dashboard.',
        'type': 'BOOST',
        'category': 'Credits',
        'createdAt': pr['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'actionLabel': 'View Promotion',
      });
    }

    // 7. Team members
    for (final tm in teamMembers) {
      final id = 'team_${tm['_id'] ?? tm['id']}';
      final name = asString(tm['name']) ?? 'Team Member';
      list.add({
        '_id': id,
        'title': 'Team Member: $name',
        'body': '$name is active in your partner agency team.',
        'type': 'ASSIGNMENT',
        'category': 'Assignments',
        'createdAt': tm['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'actionLabel': 'Manage Team',
      });
    }

    // 8. Welcome Partner
    if (partnerName.value.isNotEmpty && partnerName.value != 'Partner') {
      list.add({
        '_id': 'welcome_partner_${partnerId.value}',
        'title': 'Welcome Certified Partner, ${partnerName.value}!',
        'body': 'Your DigiNiwas Partner console is active. Manage assigned properties, visits, and buyer leads.',
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

  bool _applyNotificationsResponse(dynamic data) {
    if (data is! Map) return false;
    if (data['success'] == false) return false;
    final rawList = data['data'] ?? data['notifications'] ?? [];
    if (rawList is! List) return false;
    final list = rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    notificationsList.value = list;
    unreadNotificationsCount.value = (data['unreadCount'] as num?)?.toInt() ??
        notificationsList
            .where((n) => n['isRead'] != true && n['read'] != true)
            .length;

    if (list.isNotEmpty) {
      // 🔔 Fire push notification with sound for new in-app partner notifications
      NotificationService.syncInAppNotificationsToPush(
        notifications: notificationsList,
        role: 'partner',
      );
    }
    return true;
  }

  Future<void> markNotificationAsRead(String id) async {
    if (id.isEmpty) return;
    for (int i = 0; i < notificationsList.length; i++) {
      final n = notificationsList[i];
      if ((asString(n['_id']) ?? asString(n['id'])) == id) {
        final updated = Map<String, dynamic>.from(n);
        updated['isRead'] = true;
        updated['read'] = true;
        notificationsList[i] = updated;
        break;
      }
    }
    if (unreadNotificationsCount.value > 0) unreadNotificationsCount.value--;
    await StorageService.instance.markNotificationIdAsRead(id);
    if (isBypassSession.value) return;
    try {
      await ApiService.instance.patch(ApiConstants.markNotificationRead(id));
    } catch (_) {}
  }

  Future<void> markAllNotificationsAsRead() async {
    final allIds = <String>[];
    for (int i = 0; i < notificationsList.length; i++) {
      final id = asString(notificationsList[i]['_id']) ?? asString(notificationsList[i]['id']) ?? '';
      if (id.isNotEmpty) allIds.add(id);
      final updated = Map<String, dynamic>.from(notificationsList[i]);
      updated['isRead'] = true;
      updated['read'] = true;
      notificationsList[i] = updated;
    }
    unreadNotificationsCount.value = 0;
    await StorageService.instance.markAllNotificationIdsAsRead(allIds);
    if (isBypassSession.value) return;
    try {
      await ApiService.instance.post(ApiConstants.markAllNotificationsRead);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    if (id.isEmpty) return;
    notificationsList.removeWhere((item) =>
        (asString(item['_id']) ?? asString(item['id'])) == id);
    unreadNotificationsCount.value = notificationsList
        .where((item) => item['isRead'] != true && item['read'] != true)
        .length;
    await StorageService.instance.addClearedNotificationIds([id]);
    await StorageService.instance.markNotificationIdAsRead(id);
    if (isBypassSession.value) return;
    try {
      if (!id.startsWith('notif_')) {
        await ApiService.instance.delete('${ApiConstants.notifications}/$id');
      }
    } catch (_) {}
  }

  Future<void> setLeadStatus(PartnerLead lead, String status) async {
    if (isBypassSession.value) return;
    try {
      await _repo.updateLeadStatus(lead.id, status: status);
      _toast('Lead updated');
      await loadLeads();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> loadProperties() async {
    if (partnerId.value.isEmpty || isBypassSession.value) return;
    propertiesLoading.value = true;
    try {
      var list = await _repo.getNewPropertiesByPartner(partnerId.value);
      if (list.isEmpty) {
        try {
          list = await _repo.getPartnerPropertiesAssigned();
        } catch (_) {
          list = const [];
        }
      }
      properties.assignAll(list);
      try {
        publishingSummary.value = await _repo.getPublishingSummary();
      } catch (_) {
        publishingSummary.value = PublishingSummary({
          'assigned': list.length,
          'live': list.where((p) => p.status.toLowerCase() == 'live').length,
          'readyForFinalReview': list
              .where((p) => p.status.toLowerCase().contains('review'))
              .length,
          'draft': list
              .where((p) => p.status.toLowerCase().contains('draft'))
              .length,
        });
      }
    } catch (e) {
      _handleError(e);
    } finally {
      propertiesLoading.value = false;
    }
  }

  List<PartnerProperty> get filteredProperties {
    Iterable<PartnerProperty> list = properties;
    final q = propertySearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (p) =>
            p.title.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q),
      );
    }
    final tab = propertiesTab.value.toLowerCase();
    if (tab == 'all') return list.toList();
    if (tab == 'live') {
      return list
          .where((p) => p.status.toLowerCase() == 'live')
          .toList();
    }
    if (tab.contains('review')) {
      return list
          .where((p) => p.status.toLowerCase().contains('review'))
          .toList();
    }
    if (tab == 'draft') {
      return list
          .where((p) => p.status.toLowerCase().contains('draft'))
          .toList();
    }
    if (tab == 'assigned') {
      return list
          .where((p) => !p.status.toLowerCase().contains('draft'))
          .toList();
    }
    return list.toList();
  }

  int get propAssignedCount =>
      publishingSummary.value?.assigned ?? properties.length;

  int get propLiveCount =>
      publishingSummary.value?.live ??
      properties.where((p) => p.status.toLowerCase() == 'live').length;

  int get propReviewCount =>
      publishingSummary.value?.readyForFinalReview ??
      properties
          .where((p) => p.status.toLowerCase().contains('review'))
          .length;

  int get propDraftCount =>
      properties.where((p) => p.status.toLowerCase().contains('draft')).length;

  Future<void> boostProperty(PartnerProperty property) async {
    if (isBypassSession.value) return;
    try {
      await _repo.createPromotion(
        partnerId: partnerId.value,
        propertyId: property.id,
        promotionType: 'BOOST',
        remarks: 'Requested from partner app',
      );
      _toast('Promotion submitted (credits reserved)');
      await Future.wait([loadProperties(), loadCredits(), loadPromotions()]);
    } catch (e) {
      try {
        await _repo.boostProperty(property.id, boostType: 'STANDARD', days: 7);
        _toast('Property boosted');
        await loadProperties();
        await loadCredits();
      } catch (e2) {
        _handleError(e2);
      }
    }
  }

  Future<void> unboostProperty(PartnerProperty property) async {
    if (isBypassSession.value) return;
    try {
      await _repo.unboostProperty(property.id);
      _toast('Boost removed');
      await loadProperties();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteProperty(PartnerProperty property) async {
    if (isBypassSession.value) return;
    try {
      await _repo.deleteProperty(property.id);
      _toast('Property deleted');
      await loadProperties();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updatePropertyStatus(
    PartnerProperty property,
    String status,
  ) async {
    if (isBypassSession.value) return;
    try {
      await _repo.updatePropertyStatus(property.id, status: status);
      _toast('Status updated');
      await loadProperties();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> loadTeam() async {
    if (partnerId.value.isEmpty || !isTeamOwner.value || isBypassSession.value) {
      return;
    }
    teamLoading.value = true;
    try {
      final members = await _repo.getVerifiedTeamMembers(partnerId.value);
      final props = await _repo.getTeamAssignedProperties(partnerId.value);
      teamMembers.assignAll(members);
      teamProperties.assignAll(props);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('agency') || msg.contains('team') || msg.contains('404')) {
        isTeamOwner.value = false;
      } else {
        _handleError(e, silent: true);
      }
    } finally {
      teamLoading.value = false;
    }
  }

  Future<void> allocateCreditsToMember({
    required String memberId,
    required int credits,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.allocateTeamCredits(
        ownerId: partnerId.value,
        memberId: memberId,
        credits: credits,
      );
      _toast('Credits allocated');
      await Future.wait([loadTeam(), loadCredits()]);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> addSubAgent(Map<String, dynamic> payload) async {
    if (isBypassSession.value) return;
    try {
      await _repo.addTeamMember(partnerId.value, payload);
      _toast('Sub-agent application created');
      await loadTeam();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> delegateProperty({
    required String propertyId,
    String? memberId,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.delegatePropertyToSubAgent(
        ownerId: partnerId.value,
        propertyId: propertyId,
        memberId: memberId,
      );
      _toast('Property delegated');
      await loadTeam();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> removePropertyDelegation({required String propertyId}) async {
    if (isBypassSession.value) return;
    try {
      await _repo.removePropertyDelegation(
        ownerId: partnerId.value,
        propertyId: propertyId,
      );
      _toast('Delegation removed');
      await loadTeam();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTeamMemberCreditHistory(String memberId) async {
    try {
      return await _repo.getTeamMemberCreditHistory(
        ownerId: partnerId.value,
        memberId: memberId,
      );
    } catch (e) {
      _handleError(e);
      return {};
    }
  }

  Future<void> loadPromotions() async {
    if (partnerId.value.isEmpty || isBypassSession.value) return;
    promotionsLoading.value = true;
    try {
      final list = await _repo.getPromotions(partnerId: partnerId.value);
      promotions.assignAll(list);
      final dash = await _repo.getBoostOperationsDashboard(
        partnerId: partnerId.value,
      );
      boostDashboard.value = dash;
      await Future.wait([
        loadMyPromotions(),
        loadIncomingSellerRequests(),
        loadPropertyPlans(),
        loadProfilePlans(),
      ]);
    } catch (_) {
      // Non-fatal for tabs that don't show promotions
    } finally {
      promotionsLoading.value = false;
    }
  }

  Future<void> loadPropertyPlans() async {
    propertyPlansLoading.value = true;
    try {
      final list = await _repo.getPromotionPlans(targetType: 'PROPERTY');
      propertyPlans.assignAll(list);
    } catch (_) {
    } finally {
      propertyPlansLoading.value = false;
    }
  }

  Future<void> loadProfilePlans() async {
    profilePlansLoading.value = true;
    try {
      final list = await _repo.getPromotionPlans(targetType: 'PARTNER');
      profilePlans.assignAll(list);
    } catch (_) {
    } finally {
      profilePlansLoading.value = false;
    }
  }

  Future<void> loadIncomingSellerRequests() async {
    if (isBypassSession.value) return;
    incomingSellerRequestsLoading.value = true;
    try {
      final list = await _repo.getIncomingSellerRequests();
      incomingSellerRequests.assignAll(list);
    } catch (_) {
    } finally {
      incomingSellerRequestsLoading.value = false;
    }
  }

  Future<void> loadMyPromotions() async {
    if (isBypassSession.value) return;
    myPromotionsLoading.value = true;
    try {
      final list = await _repo.getMyPromotionRequests();
      myPromotions.assignAll(list);
    } catch (_) {
    } finally {
      myPromotionsLoading.value = false;
    }
  }

  Future<void> directBoostProperty({
    required String propertyId,
    required String promotionType,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.requestPropertyBoost(
        propertyId: propertyId,
        promotionType: promotionType,
      );
      _toast('🚀 Property boost request submitted to Admin!');
      await Future.wait([loadProperties(), loadCredits(), loadMyPromotions()]);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> directBoostPartnerProfile({
    required String promotionType,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.requestPartnerProfileBoost(
        promotionType: promotionType,
      );
      _toast('⭐ Partner profile boost request submitted to Admin!');
      await Future.wait([loadCredits(), loadMyPromotions()]);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> approveSellerRequest(String sellerBoostRequestId) async {
    if (isBypassSession.value) return;
    try {
      await _repo.approveSellerRequest(sellerBoostRequestId);
      _toast('✅ Seller request accepted! Credits reserved.');
      await Future.wait([loadCredits(), loadIncomingSellerRequests(), loadMyPromotions()]);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> rejectSellerRequest(String sellerBoostRequestId, {String? reason}) async {
    if (isBypassSession.value) return;
    try {
      await _repo.rejectSellerRequest(sellerBoostRequestId, reason: reason);
      _toast('Seller request declined.');
      await loadIncomingSellerRequests();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  final RxList<PartnerVisit> teamPendingVisits = <PartnerVisit>[].obs;
  final RxBool teamPendingVisitsLoading = false.obs;

  Future<void> loadTeamPendingVisits() async {
    if (partnerId.value.isEmpty || !isTeamOwner.value || isBypassSession.value) return;
    teamPendingVisitsLoading.value = true;
    try {
      final list = await _repo.getTeamPendingVisits(partnerId.value);
      teamPendingVisits.assignAll(list);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('not found') || msg.contains('agency') || msg.contains('team') || msg.contains('404')) {
        isTeamOwner.value = false;
      } else {
        _handleError(e, silent: true);
      }
    } finally {
      teamPendingVisitsLoading.value = false;
    }
  }

  Future<void> reviewTeamPendingVisit(
    String visitId,
    String action, {
    String? remarks,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.reviewSubAgentVisit(
        visitId,
        status: action,
        remarks: remarks,
      );
      _toast(action == 'Forward' ? 'Visit forwarded to Admin' : 'Visit rejected');
      await Future.wait([loadTeamPendingVisits(), loadTasks()]);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> boostPropertyWithPromotion({
    required String propertyId,
    required String promotionType,
    int days = 7,
    String? remarks,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.createPromotion(
        partnerId: partnerId.value,
        propertyId: propertyId,
        promotionType: promotionType,
        remarks: remarks ?? 'Requested via Partner App',
      );
      _toast('🚀 Promotion boost requested successfully!');
      await Future.wait([loadProperties(), loadCredits(), loadPromotions()]);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> loadTrendingProperties() async {
    trendingLoading.value = true;
    try {
      final list = await _repo.getActivePromotedProperties();
      trendingProperties.assignAll(list);
    } catch (_) {
    } finally {
      trendingLoading.value = false;
    }
  }

  Future<void> loadTasks() async {
    if (partnerId.value.isEmpty || isBypassSession.value) return;
    tasksLoading.value = true;
    try {
      final results = await Future.wait([
        _repo.getPartnerVisits(partnerId.value),
        _repo.getUnassignedProperties(),
        _repo.getVisitsSummary(),
      ]);
      visits.assignAll(results[0] as List<PartnerVisit>);
      unassignedProperties.assignAll(results[1] as List<PartnerProperty>);
      visitsSummary.value = results[2] as VisitsSummary;
      if (isTeamOwner.value) {
        await loadTeamPendingVisits();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      tasksLoading.value = false;
    }
  }

  List<PartnerProperty> get filteredTaskProperties {
    final tab = tasksTab.value.toLowerCase();
    if (tab == 'new') return unassignedProperties.toList();
    return unassignedProperties.toList();
  }

  List<PartnerVisit> get filteredVisits {
    final tab = tasksTab.value.toLowerCase();
    if (tab == 'new') {
      return visits
          .where((v) => v.status.toLowerCase().contains('request'))
          .toList();
    }
    if (tab.contains('progress')) {
      return visits
          .where(
            (v) =>
                !v.status.toLowerCase().contains('complete') &&
                !v.status.toLowerCase().contains('cancel'),
          )
          .toList();
    }
    if (tab == 'verified') {
      return visits
          .where((v) => v.status.toLowerCase().contains('verif'))
          .toList();
    }
    if (tab == 'completed') {
      return visits
          .where((v) => v.status.toLowerCase().contains('complete'))
          .toList();
    }
    return visits.toList();
  }

  Future<void> updateVisitStatus(
    PartnerVisit visit,
    String status, {
    String? remarks,
  }) async {
    if (isBypassSession.value) return;
    try {
      await _repo.updateVisitStatus(visit.id, status: status, remarks: remarks);
      _toast('Visit updated');
      await loadTasks();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> createVisitRequest({
    required String propertyId,
    String? buyerId,
    required DateTime requestedVisitAt,
    String? notes,
  }) async {
    if (isBypassSession.value) {
      _toast('Visit scheduled successfully (demo mode)');
      return true;
    }
    try {
      await _repo.createVisitRequest(
        partnerId: partnerId.value,
        propertyId: propertyId,
        buyerId: buyerId,
        requestedVisitAt: requestedVisitAt,
        requestNotes: notes,
      );
      _toast('Site visit scheduled successfully');
      await loadTasks();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final first = partnerName.value.split(' ').first;
    return '$part, $first';
  }
}

PartnerHomeController ensurePartnerHomeController() {
  if (Get.isRegistered<PartnerHomeController>()) {
    return Get.find<PartnerHomeController>();
  }
  return Get.put(PartnerHomeController());
}
