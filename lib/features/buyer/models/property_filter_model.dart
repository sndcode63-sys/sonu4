import '../../../core/widgets/app_image.dart';

/// Response model for GET /newproperties/filter
class PropertyFilterModel {
  bool? success;
  String? message;
  int? count;
  int? total;
  PfPagination? pagination;
  PfAppliedFilters? appliedFilters;
  List<PfPropertyData>? data;
  List<PfPropertyData>? properties;

  PropertyFilterModel(
      {this.success,
        this.message,
        this.count,
        this.total,
        this.pagination,
        this.appliedFilters,
        this.data,
        this.properties});

  PropertyFilterModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    count = json['count'];
    total = json['total'];
    pagination = json['pagination'] != null
        ? PfPagination.fromJson(json['pagination'])
        : null;
    appliedFilters = json['appliedFilters'] != null
        ? PfAppliedFilters.fromJson(json['appliedFilters'])
        : null;
    if (json['data'] != null) {
      data = <PfPropertyData>[];
      json['data'].forEach((v) {
        data!.add(PfPropertyData.fromJson(v));
      });
    }
    if (json['properties'] != null) {
      properties = <PfPropertyData>[];
      json['properties'].forEach((v) {
        properties!.add(PfPropertyData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    map['count'] = count;
    map['total'] = total;
    if (pagination != null) map['pagination'] = pagination!.toJson();
    if (appliedFilters != null) map['appliedFilters'] = appliedFilters!.toJson();
    if (data != null) map['data'] = data!.map((v) => v.toJson()).toList();
    if (properties != null) map['properties'] = properties!.map((v) => v.toJson()).toList();
    return map;
  }
}

class PfPagination {
  int? currentPage;
  int? totalPages;
  int? limit;

  PfPagination({this.currentPage, this.totalPages, this.limit});

  PfPagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    totalPages = json['totalPages'];
    limit = json['limit'];
  }

  Map<String, dynamic> toJson() => {
    'currentPage': currentPage,
    'totalPages': totalPages,
    'limit': limit,
  };
}

class PfAppliedFilters {
  String? status;
  String? propertyVerificationStatus;
  String? city;
  String? category;
  String? transactionType;
  num? minPrice;
  num? maxPrice;

  PfAppliedFilters(
      {this.status,
        this.propertyVerificationStatus,
        this.city,
        this.category,
        this.transactionType,
        this.minPrice,
        this.maxPrice});

  PfAppliedFilters.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    propertyVerificationStatus = json['propertyVerificationStatus'];
    city = json['city'];
    category = json['category'];
    transactionType = json['transactionType'];
    minPrice = json['minPrice'];
    maxPrice = json['maxPrice'];
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'propertyVerificationStatus': propertyVerificationStatus,
    'city': city,
    'category': category,
    'transactionType': transactionType,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
  };
}

class PfPropertyData {
  String? sId;
  String? propertyId;
  String? title;
  String? transactionType;
  String? category;
  String? status;
  String? propertyVerificationStatus;
  int? propertySize;
  String? sizeUnit;
  int? price;
  String? projectName;
  String? developerName;
  String? description;
  String? city;
  String? locality;
  String? pinCode;
  String? address;
  double? latitude;
  double? longitude;
  int? maintenance;
  int? bookingAmount;
  bool? negotiable;
  int? superBuiltupArea;
  int? carpetArea;
  String? bedrooms;
  String? bathrooms;
  String? balconies;
  String? parking;
  int? floorNo;
  int? totalFloors;
  String? facing;
  String? furnishing;
  List<String>? amenities;
  List<PfImage>? images;
  String? floorPlan;
  String? reraCertificate;
  String? videoLink;
  String? video;
  List<String>? tags;
  PfAddedBy? addedBy;
  PfAssignedPartner? assignedPartner;
  List<PfStatusHistory>? statusHistory;
  String? createdAt;
  String? updatedAt;
  int? pricePerSqft;

  /// Local-only UI state for the compare checkbox — not part of the API
  /// response, mutated in place so the compare selection survives rebuilds.
  bool isCompared = false;

  PfPropertyData({
    this.sId,
    this.propertyId,
    this.title,
    this.transactionType,
    this.category,
    this.status,
    this.propertyVerificationStatus,
    this.propertySize,
    this.sizeUnit,
    this.price,
    this.projectName,
    this.developerName,
    this.description,
    this.city,
    this.locality,
    this.pinCode,
    this.address,
    this.latitude,
    this.longitude,
    this.maintenance,
    this.bookingAmount,
    this.negotiable,
    this.superBuiltupArea,
    this.carpetArea,
    this.bedrooms,
    this.bathrooms,
    this.balconies,
    this.parking,
    this.floorNo,
    this.totalFloors,
    this.facing,
    this.furnishing,
    this.amenities,
    this.images,
    this.floorPlan,
    this.reraCertificate,
    this.videoLink,
    this.video,
    this.tags,
    this.addedBy,
    this.assignedPartner,
    this.statusHistory,
    this.createdAt,
    this.updatedAt,
    this.pricePerSqft,
  });

  PfPropertyData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    propertyId = json['propertyId'];
    title = json['title'];
    transactionType = json['transactionType'];
    category = json['category'];
    status = json['status'];
    propertyVerificationStatus = json['propertyVerificationStatus'];
    propertySize = json['propertySize'];
    sizeUnit = json['sizeUnit'];
    price = json['price'];
    projectName = json['projectName'];
    developerName = json['developerName'];
    description = json['description'];
    city = json['city'];
    locality = json['locality'];
    pinCode = json['pinCode'];
    address = json['address'];
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
    maintenance = json['maintenance'];
    bookingAmount = json['bookingAmount'];
    negotiable = json['negotiable'];
    superBuiltupArea = json['superBuiltupArea'];
    carpetArea = json['carpetArea'];
    bedrooms = json['bedrooms']?.toString();
    bathrooms = json['bathrooms']?.toString();
    balconies = json['balconies']?.toString();
    parking = json['parking']?.toString();
    floorNo = json['floorNo'];
    totalFloors = json['totalFloors'];
    facing = json['facing'];
    furnishing = json['furnishing'];
    amenities = json['amenities'] != null ? List<String>.from(json['amenities']) : null;
    dynamic rawImgs = json['images'];
    if (rawImgs is! List || rawImgs.isEmpty) {
      if (json['media'] is Map) {
        final media = json['media'] as Map;
        rawImgs = media['images'] ?? media['photos'];
      }
    }
    if (rawImgs is! List || rawImgs.isEmpty) {
      rawImgs = json['photos'] ?? json['gallery'];
    }

    if (rawImgs is List) {
      images = <PfImage>[];
      for (final v in rawImgs) {
        if (v is Map<String, dynamic>) {
          images!.add(PfImage.fromJson(v));
        } else if (v is Map) {
          images!.add(PfImage.fromJson(Map<String, dynamic>.from(v)));
        } else if (v is String && v.trim().isNotEmpty && v.trim().toLowerCase() != 'null') {
          images!.add(PfImage(url: ImageCase.sanitizeUrl(v.trim())));
        }
      }
    }
    if (images == null || images!.isEmpty) {
      final single = json['image'] ?? json['imageUrl'] ?? json['coverImage'] ?? json['thumbnail'] ?? json['photo'];
      if (single != null && single.toString().trim().isNotEmpty && single.toString().toLowerCase() != 'null') {
        images = [PfImage(url: ImageCase.sanitizeUrl(single.toString().trim()))];
      }
    }
    images ??= [];
    floorPlan = json['floorPlan'];
    reraCertificate = json['reraCertificate'];
    videoLink = json['videoLink'];
    video = json['video'];
    tags = json['tags'] != null ? List<String>.from(json['tags']) : null;
    addedBy = json['addedBy'] != null ? PfAddedBy.fromJson(json['addedBy']) : null;
    assignedPartner = json['assignedPartner'] != null
        ? PfAssignedPartner.fromJson(json['assignedPartner'])
        : null;
    if (json['statusHistory'] != null) {
      statusHistory = <PfStatusHistory>[];
      json['statusHistory'].forEach((v) {
        statusHistory!.add(PfStatusHistory.fromJson(v));
      });
    }
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    pricePerSqft = json['pricePerSqft'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = sId;
    map['propertyId'] = propertyId;
    map['title'] = title;
    map['transactionType'] = transactionType;
    map['category'] = category;
    map['status'] = status;
    map['propertyVerificationStatus'] = propertyVerificationStatus;
    map['propertySize'] = propertySize;
    map['sizeUnit'] = sizeUnit;
    map['price'] = price;
    map['projectName'] = projectName;
    map['developerName'] = developerName;
    map['description'] = description;
    map['city'] = city;
    map['locality'] = locality;
    map['pinCode'] = pinCode;
    map['address'] = address;
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['maintenance'] = maintenance;
    map['bookingAmount'] = bookingAmount;
    map['negotiable'] = negotiable;
    map['superBuiltupArea'] = superBuiltupArea;
    map['carpetArea'] = carpetArea;
    map['bedrooms'] = bedrooms;
    map['bathrooms'] = bathrooms;
    map['balconies'] = balconies;
    map['parking'] = parking;
    map['floorNo'] = floorNo;
    map['totalFloors'] = totalFloors;
    map['facing'] = facing;
    map['furnishing'] = furnishing;
    map['amenities'] = amenities;
    if (images != null) map['images'] = images!.map((v) => v.toJson()).toList();
    map['floorPlan'] = floorPlan;
    map['reraCertificate'] = reraCertificate;
    map['videoLink'] = videoLink;
    map['video'] = video;
    map['tags'] = tags;
    if (addedBy != null) map['addedBy'] = addedBy!.toJson();
    if (assignedPartner != null) map['assignedPartner'] = assignedPartner!.toJson();
    if (statusHistory != null) {
      map['statusHistory'] = statusHistory!.map((v) => v.toJson()).toList();
    }
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['pricePerSqft'] = pricePerSqft;
    return map;
  }
}

class PfImage {
  String? url;
  String? publicId;
  String? sId;

  PfImage({this.url, this.publicId, this.sId});

  PfImage.fromJson(Map<String, dynamic> json) {
    url = ImageCase.sanitizeUrl((json['secure_url'] ?? json['url'] ?? json['imageUrl'] ?? json['image'] ?? json['path'])?.toString());
    publicId = (json['public_id'] ?? json['publicId'])?.toString();
    sId = (json['_id'] ?? json['id'])?.toString();
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'public_id': publicId,
    '_id': sId,
  };
}

class PfAddedBy {
  String? userId;
  String? sellerId;
  String? partnerId;
  String? role;
  String? name;
  String? email;
  String? phone;

  PfAddedBy(
      {this.userId,
        this.sellerId,
        this.partnerId,
        this.role,
        this.name,
        this.email,
        this.phone});

  PfAddedBy.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    sellerId = json['sellerId'];
    partnerId = json['partnerId'];
    role = json['role'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sellerId': sellerId,
    'partnerId': partnerId,
    'role': role,
    'name': name,
    'email': email,
    'phone': phone,
  };
}

class PfAssignedPartner {
  String? partnerCode;
  String? name;
  String? email;
  String? phone;
  String? partnerType;
  String? assignedAt;
  String? verificationStatus;

  PfAssignedPartner(
      {this.partnerCode,
        this.name,
        this.email,
        this.phone,
        this.partnerType,
        this.assignedAt,
        this.verificationStatus});

  PfAssignedPartner.fromJson(Map<String, dynamic> json) {
    partnerCode = json['partnerCode'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    partnerType = json['partnerType'];
    assignedAt = json['assignedAt'];
    verificationStatus = json['verificationStatus'];
  }

  Map<String, dynamic> toJson() => {
    'partnerCode': partnerCode,
    'name': name,
    'email': email,
    'phone': phone,
    'partnerType': partnerType,
    'assignedAt': assignedAt,
    'verificationStatus': verificationStatus,
  };
}

class PfStatusHistory {
  String? status;
  String? remarks;
  String? sId;
  String? updatedAt;

  PfStatusHistory({this.status, this.remarks, this.sId, this.updatedAt});

  PfStatusHistory.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    remarks = json['remarks'];
    sId = json['_id'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'remarks': remarks,
    '_id': sId,
    'updatedAt': updatedAt,
  };
}