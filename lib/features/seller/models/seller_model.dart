/// Represents a Seller Profile on DigiNiwas platform
class SellerModel {
  final String id;
  final String sellerId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final String accountStatus;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? agencyDetails;
  final String? avatar;

  SellerModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.accountStatus = 'Pending',
    this.location,
    this.agencyDetails,
    this.avatar,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['_id'] ?? json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'Seller',
      isVerified: json['isVerified'] ?? json['verified'] ?? false,
      accountStatus: json['accountStatus'] ?? json['applicationStatus'] ?? 'Pending',
      location: json['location'] is Map ? Map<String, dynamic>.from(json['location']) : null,
      agencyDetails: json['agencyDetails'] is Map ? Map<String, dynamic>.from(json['agencyDetails']) : null,
      avatar: json['avatar'] ?? json['profilePic'] ?? json['photo'] ?? json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sellerId': sellerId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'accountStatus': accountStatus,
      if (location != null) 'location': location,
      if (agencyDetails != null) 'agencyDetails': agencyDetails,
      if (avatar != null) 'avatar': avatar,
    };
  }
}

/// Represents Property Statistics summary for a Seller
class SellerSummaryModel {
  final int totalProperties;
  final int listedProperties;
  final int soldProperties;
  final int pendingProperties;

  SellerSummaryModel({
    this.totalProperties = 0,
    this.listedProperties = 0,
    this.soldProperties = 0,
    this.pendingProperties = 0,
  });

  factory SellerSummaryModel.fromJson(Map<String, dynamic> json) {
    return SellerSummaryModel(
      totalProperties: json['totalProperties'] ?? json['total'] ?? 0,
      listedProperties: json['listedProperties'] ?? json['listed'] ?? 0,
      soldProperties: json['soldProperties'] ?? json['sold'] ?? 0,
      pendingProperties: json['pendingProperties'] ?? json['pending'] ?? 0,
    );
  }
}

/// Represents Seller KYC / Registration Application Response
class SellerApplicationModel {
  final String applicationId;
  final String sellerId;
  final String applicationStatus;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  SellerApplicationModel({
    required this.applicationId,
    required this.sellerId,
    required this.applicationStatus,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  factory SellerApplicationModel.fromJson(Map<String, dynamic> json) {
    return SellerApplicationModel(
      applicationId: json['applicationId'] ?? json['_id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      applicationStatus: json['applicationStatus'] ?? 'Submitted',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
    );
  }
}
