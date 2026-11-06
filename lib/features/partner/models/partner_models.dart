/// Lightweight helpers for DigiNiwas partner API payloads.
/// Backend shapes vary; screens read via typed getters with safe fallbacks.
library;

import '../../../core/constants/api_constants.dart';

int? asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.replaceAll(',', ''));
  return null;
}

double? asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', ''));
  return null;
}

String? asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

class PartnerProfile {
  PartnerProfile(this.raw);
  final Map<String, dynamic> raw;

  String get id =>
      asString(raw['_id']) ?? asString(raw['id']) ?? '';

  String get partnerCode =>
      asString(raw['partnerId']) ?? asString(raw['partnerCode']) ?? '';

  String get name =>
      asString(raw['name']) ?? asString(raw['fullName']) ?? 'Partner';

  String get email => asString(raw['email']) ?? '';

  String get phone => asString(raw['phone']) ?? '';

  String get accountType => asString(raw['accountType']) ?? 'partner';

  bool get isVerified =>
      raw['isVerified'] == true ||
      asString(raw['status'])?.toLowerCase() == 'verified';

  String get city =>
      asString(raw['city']) ??
      asString(asMap(raw['address'])['city']) ??
      asString(asMap(raw['location'])['city']) ??
      '';

  String get state =>
      asString(raw['state']) ??
      asString(asMap(raw['address'])['state']) ??
      '';

  String get operatingAreas {
    final areas = raw['operatingAreas'] ??
        raw['operatingCities'] ??
        raw['serviceAreas'] ??
        raw['locations'];
    if (areas is List) {
      final list = areas.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (list.isNotEmpty) return list.join(', ');
    }
    if (areas is String && areas.isNotEmpty) return areas;
    final c = city;
    return c.isNotEmpty ? c : '';
  }

  String get specialization {
    final spec = raw['specialization'] ??
        raw['specializations'] ??
        raw['propertyTypes'];
    if (spec is List) {
      final list = spec.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (list.isNotEmpty) return list.join(', ');
    }
    if (spec is String && spec.isNotEmpty) return spec;
    return '';
  }

  String get reraNumber =>
      asString(raw['reraNumber']) ??
      asString(raw['reraId']) ??
      asString(raw['reraRegistrationNumber']) ??
      asString(asMap(raw['kyc'])['reraNumber']) ??
      '';

  String get experience {
    final exp = raw['experience'] ?? raw['yearsOfExperience'] ?? raw['expYears'];
    if (exp != null && exp.toString().isNotEmpty) {
      final s = exp.toString();
      return s.toLowerCase().contains('year') ? s : '$s Years';
    }
    return '';
  }

  double get rating =>
      asDouble(raw['rating']) ??
      asDouble(raw['averageRating']) ??
      asDouble(asMap(raw['reputation'])['rating']) ??
      asDouble(asMap(raw['stats'])['rating']) ??
      0.0;

  int get reviewCount =>
      asInt(raw['reviewCount']) ??
      asInt(raw['totalReviews']) ??
      asInt(asMap(raw['stats'])['reviews']) ??
      0;

  int get dealsClosed =>
      asInt(raw['dealsClosed']) ??
      asInt(raw['totalDeals']) ??
      asInt(raw['closedDeals']) ??
      asInt(asMap(raw['stats'])['dealsClosed']) ??
      asInt(asMap(raw['reputation'])['dealsClosed']) ??
      0;

  String get responseTime =>
      asString(raw['responseTime']) ??
      asString(asMap(raw['reputation'])['responseTime']) ??
      '';

  bool get isKycVerified =>
      raw['isKycVerified'] == true ||
      asString(raw['kycStatus'])?.toLowerCase() == 'verified' ||
      asString(asMap(raw['kyc'])['status'])?.toLowerCase() == 'verified' ||
      isVerified;

  bool get isBankVerified =>
      raw['isBankVerified'] == true ||
      asString(raw['bankStatus'])?.toLowerCase() == 'verified' ||
      asString(asMap(raw['bankDetails'])['status'])?.toLowerCase() == 'verified' ||
      raw['bankDetails'] != null;

  bool get isReraVerified =>
      raw['isReraVerified'] == true ||
      asString(raw['reraStatus'])?.toLowerCase() == 'verified' ||
      reraNumber.isNotEmpty;
}

class PartnerCreditWallet {
  PartnerCreditWallet(this.raw);
  final Map<String, dynamic> raw;

  int get balance =>
      asInt(raw['balance']) ??
      asInt(raw['credits']) ??
      asInt(raw['availableBalance']) ??
      0;

  int get totalPurchased => asInt(raw['totalPurchased']) ?? 0;

  int get totalSpent => asInt(raw['totalSpent']) ?? 0;

  DateTime? get validTill {
    final v = raw['validTill'] ?? raw['validUntil'] ?? raw['expiryDate'] ?? raw['expiresAt'];
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  String get validityText {
    final dt = validTill;
    if (dt != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return 'Valid till ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
    final rawText = asString(raw['validity']) ?? asString(raw['validTillText']);
    if (rawText != null && rawText.isNotEmpty) {
      return rawText;
    }
    return 'No Expiry';
  }
}

class PartnerCreditsSnapshot {
  PartnerCreditsSnapshot({
    required this.wallet,
    this.partner,
    this.recentTransactions = const [],
    this.raw = const {},
  });

  final PartnerCreditWallet wallet;
  final PartnerProfile? partner;
  final List<Map<String, dynamic>> recentTransactions;
  final Map<String, dynamic> raw;

  factory PartnerCreditsSnapshot.fromResponse(Map<String, dynamic> body) {
    final data = asMap(body['data'] ?? body);
    final walletMap = asMap(
      data['wallet'] ??
          data['creditWallet'] ??
          asMap(data['partner'])['creditWallet'] ??
          data,
    );
    final partnerMap = asMap(data['partner']);
    final tx = asMapList(
      data['recentTransactions'] ?? data['transactions'] ?? body['data'],
    );
    return PartnerCreditsSnapshot(
      wallet: PartnerCreditWallet(walletMap),
      partner: partnerMap.isEmpty ? null : PartnerProfile(partnerMap),
      recentTransactions: tx,
      raw: data,
    );
  }
}

class PartnerLeadsDashboard {
  PartnerLeadsDashboard(this.raw);
  final Map<String, dynamic> raw;

  factory PartnerLeadsDashboard.fromResponse(Map<String, dynamic> body) {
    final dash = asMap(body['dashboard'] ?? body['data'] ?? body);
    return PartnerLeadsDashboard(dash);
  }

  int get totalLeads => asInt(raw['totalLeads']) ?? asInt(raw['total']) ?? 0;

  int get unlocked => asInt(raw['unlocked']) ?? 0;

  int get available =>
      asInt(raw['available']) ??
      asInt(raw['unassigned']) ??
      (totalLeads - unlocked).clamp(0, totalLeads);

  int get assigned => asInt(raw['assigned']) ?? 0;

  int get followUp =>
      asInt(raw['followUp']) ?? asInt(raw['follow_up']) ?? 0;

  int get visitPlanned =>
      asInt(raw['visitPlanned']) ??
      asInt(raw['visitsPlanned']) ??
      asInt(raw['visit_planned']) ??
      0;

  int get converted => asInt(raw['convertedLeads']) ?? 0;

  int get todayLeads => asInt(raw['todayLeads']) ?? asInt(raw['today']) ?? totalLeads;
}

class PartnerLead {
  PartnerLead(this.raw);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';

  String get buyerName =>
      asString(raw['buyerName']) ??
      asString(asMap(raw['buyer'])['name']) ??
      asString(raw['name']) ??
      'Buyer';

  String get name => buyerName;

  DateTime? get createdAt {
    final v = raw['createdAt'] ?? raw['created_at'] ?? raw['timestamp'];
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  String get city => location;

  String get phone =>
      asString(raw['phone']) ??
      asString(asMap(raw['buyer'])['phone']) ??
      asString(raw['maskedPhone']) ??
      '';

  String get status => asString(raw['status']) ?? 'Available';

  String get propertyTitle =>
      asString(raw['propertyTitle']) ??
      asString(asMap(raw['property'])['title']) ??
      asString(asMap(raw['property'])['name']) ??
      'Property';

  String get propertyType =>
      asString(raw['propertyType']) ??
      asString(asMap(raw['property'])['type']) ??
      asString(asMap(raw['property'])['propertyType']) ??
      propertyTitle;

  String get location =>
      asString(raw['location']) ??
      asString(raw['city']) ??
      asString(asMap(raw['property'])['city']) ??
      asString(asMap(raw['buyer'])['city']) ??
      '';

  bool get isUnlocked =>
      raw['isUnlockedByPartner'] == true ||
      raw['isUnlocked'] == true ||
      asString(raw['unlockStatus'])?.toLowerCase() == 'unlocked' ||
      asString(raw['status'])?.toLowerCase().contains('viewed') == true;

  int get unlockCost =>
      asInt(raw['unlockCost']) ??
      asInt(raw['creditCost']) ??
      asInt(asMap(raw['unlockCredit'])['creditsCharged']) ??
      25;

  String get budget {
    final direct = asString(raw['budget']) ?? asString(raw['budgetRange']);
    if (direct != null && direct.isNotEmpty) return direct;
    final value = asInt(raw['estimatedValue']) ??
        asInt(asMap(raw['property'])['price']);
    if (value == null || value <= 0) return '';
    return '₹$value';
  }

  String? get assignedPartnerMongoId =>
      asString(asMap(raw['assignedPartner'])['partnerMongoId']) ??
      asString(asMap(raw['assignedPartner'])['_id']);

  String? get buyerId =>
      asString(raw['buyerId']) ??
      asString(asMap(raw['buyer'])['_id']) ??
      asString(asMap(raw['buyer'])['id']) ??
      asString(raw['buyer']);

  String? get propertyId =>
      asString(raw['propertyId']) ??
      asString(asMap(raw['property'])['_id']) ??
      asString(asMap(raw['property'])['id']) ??
      asString(raw['property']);

  bool get isAllocatedToSubAgent {
    final sub = raw['subPartnerAllocation'] ?? raw['subPartner'] ?? raw['allocatedSubPartner'];
    if (sub != null) {
      if (sub is Map) return sub['subPartnerId'] != null || sub['id'] != null || sub['_id'] != null;
      if (sub is String) return sub.isNotEmpty;
    }
    return raw['isAllocatedToSubPartner'] == true;
  }

  String? get subPartnerId {
    final sub = raw['subPartnerAllocation'] ?? raw['subPartner'] ?? raw['allocatedSubPartner'];
    if (sub is Map) {
      return asString(sub['subPartnerId']) ?? asString(sub['_id']) ?? asString(sub['id']);
    }
    if (sub is String) return sub;
    return null;
  }
}

class PartnerProperty {
  PartnerProperty(this.raw);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';

  String get title =>
      asString(raw['title']) ??
      asString(raw['propertyTitle']) ??
      asString(raw['name']) ??
      'Property';

  String get status =>
      asString(raw['status']) ??
      asString(raw['listingStatus']) ??
      'Draft';

  bool get isLive =>
      status.toLowerCase().contains('live') ||
      status.toLowerCase().contains('active') ||
      raw['isLive'] == true;

  String get city =>
      asString(raw['city']) ??
      asString(asMap(raw['location'])['city']) ??
      '';

  String get address =>
      asString(raw['address']) ??
      asString(asMap(raw['location'])['address']) ??
      city;

  String? get imageUrl {
    final images = raw['images'] ?? raw['photos'] ?? raw['media'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String) return first;
      if (first is Map) {
        return asString(first['url']) ?? asString(first['path']);
      }
    }
    return asString(raw['coverImage']) ??
        asString(raw['thumbnail']) ??
        asString(asMap(raw['propertySnapshot'])['image']);
  }

  String get priceLabel {
    final price = raw['price'] ?? raw['expectedPrice'] ?? raw['amount'];
    if (price == null) return '';
    return '₹$price';
  }

  bool get isBoosted =>
      raw['isBoosted'] == true || raw['boosted'] == true;

  String get sellerName =>
      asString(raw['sellerName']) ??
      asString(asMap(raw['seller'])['name']) ??
      asString(asMap(raw['seller'])['fullName']) ??
      asString(asMap(raw['owner'])['name']) ??
      asString(raw['contactPerson']) ??
      '';

  String get sellerPhone =>
      asString(raw['sellerPhone']) ??
      asString(asMap(raw['seller'])['phone']) ??
      asString(asMap(raw['seller'])['mobile']) ??
      asString(asMap(raw['owner'])['phone']) ??
      asString(raw['contactNumber']) ??
      '';
}

class PartnerVisit {
  PartnerVisit(this.raw);
  factory PartnerVisit.fromJson(Map<String, dynamic> json) => PartnerVisit(json);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';

  String get status => asString(raw['status']) ?? 'Requested';

  Map<String, dynamic> get _propertyMap {
    final nested = asMap(raw['propertyId']);
    if (nested.isNotEmpty) return nested;
    final snap = asMap(raw['propertySnapshot']);
    if (snap.isNotEmpty) return snap;
    return asMap(raw['property']);
  }

  Map<String, dynamic> get _buyerMap {
    final snap = asMap(raw['buyerSnapshot']);
    if (snap.isNotEmpty) return snap;
    return asMap(raw['buyer']);
  }

  String get propertyTitle =>
      asString(raw['propertyTitle']) ??
      asString(_propertyMap['title']) ??
      asString(asMap(raw['propertySnapshot'])['title']) ??
      'Property visit';

  String get buyerName =>
      asString(raw['buyerName']) ??
      asString(_buyerMap['name']) ??
      'Buyer';

  String get propertyCity =>
      asString(_propertyMap['city']) ??
      asString(asMap(_propertyMap['location'])['city']) ??
      asString(raw['city']) ??
      '';

  String get visitDate => scheduledAt;

  String get scheduledAt =>
      asString(raw['scheduledAt']) ??
      asString(raw['requestedVisitAt']) ??
      asString(raw['approvedVisitAt']) ??
      asString(raw['visitDate']) ??
      asString(raw['preferredDate']) ??
      '';
}

class PublishingSummary {
  PublishingSummary(this.raw);
  final Map<String, dynamic> raw;

  factory PublishingSummary.fromResponse(Map<String, dynamic> body) {
    return PublishingSummary(asMap(body['data'] ?? body));
  }

  int get live => asInt(raw['live']) ?? 0;

  int get readyForFinalReview => asInt(raw['readyForFinalReview']) ?? 0;

  int get totalVerified => asInt(raw['totalVerified']) ?? 0;

  int get draft => asInt(raw['draft']) ?? 0;

  int get assigned => asInt(raw['assigned']) ?? totalVerified;
}

class VisitsSummary {
  VisitsSummary(this.raw);
  final Map<String, dynamic> raw;

  factory VisitsSummary.fromResponse(Map<String, dynamic> body) {
    return VisitsSummary(asMap(body['data'] ?? body));
  }

  int get total => asInt(raw['total']) ?? 0;

  int get requested => asInt(raw['requested']) ?? 0;

  int get upcoming => asInt(raw['upcoming']) ?? 0;

  int get completed => asInt(raw['completed']) ?? 0;

  int get followUp => asInt(raw['followUp']) ?? 0;

  int get pendingApproval => asInt(raw['pendingApproval']) ?? 0;
}

class CreditPack {
  const CreditPack({
    required this.code,
    required this.label,
    required this.credits,
    required this.priceInr,
    this.isFallback = false,
  });

  final String code;
  final String label;
  final int credits;
  final int priceInr;
  final bool isFallback;

  factory CreditPack.fromMap(Map<String, dynamic> m) {
    return CreditPack(
      code: asString(m['code']) ?? asString(m['productCode']) ?? 'pack',
      label: asString(m['label']) ?? asString(m['name']) ?? 'Credits',
      credits: asInt(m['credits']) ?? asInt(m['quantity']) ?? 0,
      priceInr: asInt(m['price']) ??
          asInt(m['priceInr']) ??
          asInt(m['amount']) ??
          0,
    );
  }
}

/// Order returned by POST /api/v1/credits/purchase/order.
///
/// The backend decides how many credits an amount buys — the app only
/// sends `amountInRupees` and renders whatever comes back.
class RazorpayOrder {
  const RazorpayOrder({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.amountInRupees,
    required this.currency,
    required this.credits,
    required this.status,
  });

  /// Razorpay public key (rzp_test_xxx / rzp_live_xxx). Never the secret.
  final String keyId;

  /// Razorpay order id (order_xxxxx).
  final String orderId;

  /// Amount in the smallest currency unit (paise) — what Checkout expects.
  final int amount;

  /// Same amount in rupees, for display only.
  final int amountInRupees;
  final String currency;

  /// Credits the backend will grant once the payment is verified.
  final int credits;
  final String status;

  bool get isValid => keyId.isNotEmpty && orderId.isNotEmpty && amount > 0;

  factory RazorpayOrder.fromMap(Map<String, dynamic> m) {
    final amountPaise = asInt(m['amount']);
    final rupees = asInt(m['amountInRupees']) ??
        (amountPaise != null ? (amountPaise / 100).round() : 0);
    final rawKey = asString(m['keyId']) ?? asString(m['key_id']);
    return RazorpayOrder(
      keyId: (rawKey != null && rawKey.trim().isNotEmpty)
          ? rawKey.trim()
          : ApiConstants.razorpayKeyId,
      orderId: asString(m['orderId']) ?? asString(m['order_id']) ?? '',
      amount: amountPaise ?? (rupees * 100),
      amountInRupees: rupees,
      currency: asString(m['currency']) ?? 'INR',
      credits: asInt(m['credits']) ?? 0,
      status: asString(m['status']) ?? 'CREATED',
    );
  }

  /// Handles both `{ success, data: {...} }` and a bare order object.
  factory RazorpayOrder.fromResponse(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map) return RazorpayOrder.fromMap(asMap(data));
    return RazorpayOrder.fromMap(body);
  }
}

/// Extracts list payloads from varied DigiNiwas envelope shapes.
List<Map<String, dynamic>> extractDataList(Map<String, dynamic> body) {
  final data = body['data'];
  if (data is List) return asMapList(data);
  if (data is Map) {
    final nested = asMapList(
      data['items'] ??
          data['leads'] ??
          data['properties'] ??
          data['visits'] ??
          data['results'] ??
          data['data'] ??
          data['members'] ??
          data['transactions'] ??
          data['history'],
    );
    if (nested.isNotEmpty) return nested;
  }
  for (final key in [
    'leads',
    'properties',
    'visits',
    'items',
    'results',
    'members',
  ]) {
    final list = asMapList(body[key]);
    if (list.isNotEmpty) return list;
  }
  return const [];
}


// =============================================================================
// PROMOTION & BOOST MODELS (Role-Based Handoff)
// =============================================================================

class PromotionPlanModel {
  PromotionPlanModel(this.raw);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';
  String get code => asString(raw['code']) ?? '';
  String get name => asString(raw['name']) ?? 'Promotion Plan';
  String get targetType => asString(raw['targetType']) ?? 'PROPERTY';
  String get placement => asString(raw['placement']) ?? 'BOOST';
  int get credits => asInt(raw['credits']) ?? 0;
  int get durationDays => asInt(raw['durationDays']) ?? 7;
  String get description => asString(raw['description']) ?? '';
  bool get isActive => raw['isActive'] != false;

  List<String> get features {
    final f = raw['features'];
    if (f is List) {
      return f.map((e) {
        if (e is Map) return asString(e['name']) ?? asString(e['key']) ?? '';
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  factory PromotionPlanModel.fromMap(Map<String, dynamic> map) => PromotionPlanModel(map);
}

class SellerBoostRequestModel {
  SellerBoostRequestModel(this.raw);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';
  String get propertyId => asString(raw['propertyId']) ?? asString(asMap(raw['property'])['_id']) ?? '';
  String get propertyTitle => asString(asMap(raw['property'])['title']) ?? asString(raw['propertyTitle']) ?? 'Property';
  String get propertyLocation => asString(asMap(raw['property'])['location']) ?? asString(raw['propertyLocation']) ?? '';
  String get propertyPrice => asString(asMap(raw['property'])['price']) ?? asString(raw['propertyPrice']) ?? '';
  String get propertyImage {
    final prop = asMap(raw['property']);
    final photos = prop['photos'] ?? prop['images'];
    if (photos is List && photos.isNotEmpty) {
      return asString(photos.first) ?? '';
    }
    return asString(raw['propertyImage']) ?? '';
  }

  String get sellerId => asString(raw['sellerId']) ?? asString(asMap(raw['seller'])['_id']) ?? '';
  String get sellerName => asString(asMap(raw['seller'])['name']) ?? asString(raw['sellerName']) ?? 'Seller';
  String get sellerPhone => asString(asMap(raw['seller'])['phone']) ?? asString(raw['sellerPhone']) ?? '';
  String get promotionType => asString(raw['promotionType']) ?? 'PROPERTY_BOOST';
  String get message => asString(raw['message']) ?? '';
  String get status => asString(raw['status']) ?? 'Pending';
  String get createdAt => asString(raw['createdAt']) ?? '';

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory SellerBoostRequestModel.fromMap(Map<String, dynamic> map) => SellerBoostRequestModel(map);
}

class PartnerPromotionItem {
  PartnerPromotionItem(this.raw);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';
  String get promotionType => asString(raw['promotionType']) ?? 'BOOST';
  String get targetType => asString(raw['targetType']) ?? (raw['propertyId'] != null ? 'PROPERTY' : 'PARTNER');
  String get propertyId => asString(raw['propertyId']) ?? '';
  String get status => asString(raw['status']) ?? 'Pending';
  int get credits => asInt(raw['credits']) ?? 0;
  int get durationDays => asInt(raw['durationDays']) ?? 0;
  String get createdAt => asString(raw['createdAt']) ?? '';
  String get expiresAt => asString(raw['expiresAt']) ?? '';
  String get remarks => asString(raw['remarks']) ?? '';
  String get rejectionReason => asString(raw['rejectionReason']) ?? asString(raw['reason']) ?? '';

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isActive => status.toLowerCase() == 'approved' || status.toLowerCase() == 'active';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isExpired => status.toLowerCase() == 'expired';

  factory PartnerPromotionItem.fromMap(Map<String, dynamic> map) => PartnerPromotionItem(map);
}
