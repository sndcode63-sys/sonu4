
// class HomeFeed {
//   bool? success;
//   String? message;
//   Data? data;
//
//   HomeFeed({this.success, this.message, this.data});
//
//   HomeFeed.fromJson(Map<String, dynamic> json) {
//     if(json["success"] is bool) {
//       success = json["success"];
//     }
//     if(json["message"] is String) {
//       message = json["message"];
//     }
//     if(json["data"] is Map) {
//       data = json["data"] == null ? null : Data.fromJson(json["data"]);
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> _data = <String, dynamic>{};
//     _data["success"] = success;
//     _data["message"] = message;
//     if(data != null) {
//       _data["data"] = data?.toJson();
//     }
//     return _data;
//   }
// }

import '../../../core/widgets/app_image.dart';

class HomeFeedModel {
  Location? location;
  List<Banners>? banners;
  List<RecommendedProperties>? recommendedProperties;
  List<RecommendedProperties>? boostedProperties;
  List<NewListings>? newListings;
  List<PopularAreas>? popularAreas;
  List<Agents>? agents;

  HomeFeedModel({this.location, this.banners, this.recommendedProperties, this.boostedProperties, this.newListings, this.popularAreas, this.agents});

  HomeFeedModel.fromJson(Map<String, dynamic> json) {
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location.fromJson(json["location"]);
    }
    if(json["banners"] is List) {
      banners = json["banners"] == null ? null : (json["banners"] as List).map((e) => Banners.fromJson(e)).toList();
    }
    if(json["recommendedProperties"] is List) {
      recommendedProperties = json["recommendedProperties"] == null ? null : (json["recommendedProperties"] as List).map((e) => RecommendedProperties.fromJson(e)).toList();
    }
    if(json["boostedProperties"] is List) {
      boostedProperties = (json["boostedProperties"] as List)
          .whereType<Map>()
          .map((e) => RecommendedProperties.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if(json["newListings"] is List) {
      newListings = json["newListings"] == null ? null : (json["newListings"] as List).map((e) => NewListings.fromJson(e)).toList();
    }
    if(json["popularAreas"] is List) {
      popularAreas = json["popularAreas"] == null ? null : (json["popularAreas"] as List).map((e) => PopularAreas.fromJson(e)).toList();
    }
    if(json["agents"] is List) {
      agents = json["agents"] == null ? null : (json["agents"] as List).map((e) => Agents.fromJson(e)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if(location != null) {
      data["location"] = location?.toJson();
    }
    if(banners != null) {
      data["banners"] = banners?.map((e) => e.toJson()).toList();
    }
    if(recommendedProperties != null) {
      data["recommendedProperties"] = recommendedProperties?.map((e) => e.toJson()).toList();
    }
    if(boostedProperties != null) {
      data["boostedProperties"] = boostedProperties;
    }
    if(newListings != null) {
      data["newListings"] = newListings?.map((e) => e.toJson()).toList();
    }
    if(popularAreas != null) {
      data["popularAreas"] = popularAreas?.map((e) => e.toJson()).toList();
    }
    if(agents != null) {
      data["agents"] = agents?.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class Agents {
  String? id;
  String? partnerId;
  String? name;
  String? avatar;
  String? phone;
  String? email;
  String? accountType;
  String? role;
  Business? business;
  Rera? rera;
  Location1? location;
  bool? isVerified;
  Promotion2? promotion;
  dynamic distanceKm;
  bool? sameCity;
  bool? serviceLocalityMatch;
  Contact? contact;

  Agents({this.id, this.partnerId, this.name, this.avatar, this.phone, this.email, this.accountType, this.role, this.business, this.rera, this.location, this.isVerified, this.promotion, this.distanceKm, this.sameCity, this.serviceLocalityMatch, this.contact});

  Agents.fromJson(Map<String, dynamic> json) {
    if(json["_id"] is String) {
      id = json["_id"];
    }
    if(json["partnerId"] is String) {
      partnerId = json["partnerId"];
    }
    if(json["name"] is String) {
      name = json["name"];
    }
    if(json["avatar"] is String) {
      avatar = json["avatar"];
    }
    if(json["phone"] is String) {
      phone = json["phone"];
    }
    if(json["email"] is String) {
      email = json["email"];
    }
    if(json["accountType"] is String) {
      accountType = json["accountType"];
    }
    if(json["role"] is String) {
      role = json["role"];
    }
    if(json["business"] is Map) {
      business = json["business"] == null ? null : Business.fromJson(json["business"]);
    }
    if(json["rera"] is Map) {
      rera = json["rera"] == null ? null : Rera.fromJson(json["rera"]);
    }
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location1.fromJson(json["location"]);
    }
    if(json["isVerified"] is bool) {
      isVerified = json["isVerified"];
    }
    if(json["promotion"] is Map) {
      promotion = json["promotion"] == null ? null : Promotion2.fromJson(json["promotion"]);
    }
    distanceKm = json["distanceKm"];
    if(json["sameCity"] is bool) {
      sameCity = json["sameCity"];
    }
    if(json["serviceLocalityMatch"] is bool) {
      serviceLocalityMatch = json["serviceLocalityMatch"];
    }
    if(json["contact"] is Map) {
      contact = json["contact"] == null ? null : Contact.fromJson(json["contact"]);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["_id"] = id;
    data["partnerId"] = partnerId;
    data["name"] = name;
    data["avatar"] = avatar;
    data["phone"] = phone;
    data["email"] = email;
    data["accountType"] = accountType;
    data["role"] = role;
    if(business != null) {
      data["business"] = business?.toJson();
    }
    if(rera != null) {
      data["rera"] = rera?.toJson();
    }
    if(location != null) {
      data["location"] = location?.toJson();
    }
    data["isVerified"] = isVerified;
    if(promotion != null) {
      data["promotion"] = promotion?.toJson();
    }
    data["distanceKm"] = distanceKm;
    data["sameCity"] = sameCity;
    data["serviceLocalityMatch"] = serviceLocalityMatch;
    if(contact != null) {
      data["contact"] = contact?.toJson();
    }
    return data;
  }
}

class Contact {
  bool? canCall;
  bool? canChat;
  String? phone;
  String? partnerMongoId;

  Contact({this.canCall, this.canChat, this.phone, this.partnerMongoId});

  Contact.fromJson(Map<String, dynamic> json) {
    if(json["canCall"] is bool) {
      canCall = json["canCall"];
    }
    if(json["canChat"] is bool) {
      canChat = json["canChat"];
    }
    if(json["phone"] is String) {
      phone = json["phone"];
    }
    if(json["partnerMongoId"] is String) {
      partnerMongoId = json["partnerMongoId"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["canCall"] = canCall;
    data["canChat"] = canChat;
    data["phone"] = phone;
    data["partnerMongoId"] = partnerMongoId;
    return data;
  }
}

class Promotion2 {
  bool? boost;
  bool? featured;
  bool? localityTop;
  List<dynamic>? codes;
  int? score;

  Promotion2({this.boost, this.featured, this.localityTop, this.codes, this.score});

  Promotion2.fromJson(Map<String, dynamic> json) {
    if(json["boost"] is bool) {
      boost = json["boost"];
    }
    if(json["featured"] is bool) {
      featured = json["featured"];
    }
    if(json["localityTop"] is bool) {
      localityTop = json["localityTop"];
    }
    if(json["codes"] is List) {
      codes = json["codes"] ?? [];
    }
    if(json["score"] is int) {
      score = json["score"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["boost"] = boost;
    data["featured"] = featured;
    data["localityTop"] = localityTop;
    if(codes != null) {
      data["codes"] = codes;
    }
    data["score"] = score;
    return data;
  }
}

class Location1 {
  String? city;
  String? state;
  String? country;
  String? address;
  List<dynamic>? serviceLocalities;
  Coordinates? coordinates;

  Location1({this.city, this.state, this.country, this.address, this.serviceLocalities, this.coordinates});

  Location1.fromJson(Map<String, dynamic> json) {
    if(json["city"] is String) {
      city = json["city"];
    }
    if(json["state"] is String) {
      state = json["state"];
    }
    if(json["country"] is String) {
      country = json["country"];
    }
    if(json["address"] is String) {
      address = json["address"];
    }
    if(json["serviceLocalities"] is List) {
      serviceLocalities = json["serviceLocalities"] ?? [];
    }
    if(json["coordinates"] is Map) {
      coordinates = json["coordinates"] == null ? null : Coordinates.fromJson(json["coordinates"]);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["city"] = city;
    data["state"] = state;
    data["country"] = country;
    data["address"] = address;
    if(serviceLocalities != null) {
      data["serviceLocalities"] = serviceLocalities;
    }
    if(coordinates != null) {
      data["coordinates"] = coordinates?.toJson();
    }
    return data;
  }
}

class Coordinates {
  String? type;
  List<int>? coordinates;

  Coordinates({this.type, this.coordinates});

  Coordinates.fromJson(Map<String, dynamic> json) {
    if(json["type"] is String) {
      type = json["type"];
    }
    if(json["coordinates"] is List) {
      coordinates = json["coordinates"] == null ? null : List<int>.from(json["coordinates"]);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["type"] = type;
    if(coordinates != null) {
      data["coordinates"] = coordinates;
    }
    return data;
  }
}

class Rera {
  bool? applicable;
  String? state;
  String? verificationStatus;
  String? registrationNumber;
  String? certificateUrl;
  dynamic expiryDate;

  Rera({this.applicable, this.state, this.verificationStatus, this.registrationNumber, this.certificateUrl, this.expiryDate});

  Rera.fromJson(Map<String, dynamic> json) {
    if(json["applicable"] is bool) {
      applicable = json["applicable"];
    }
    if(json["state"] is String) {
      state = json["state"];
    }
    if(json["verificationStatus"] is String) {
      verificationStatus = json["verificationStatus"];
    }
    if(json["registrationNumber"] is String) {
      registrationNumber = json["registrationNumber"];
    }
    if(json["certificateUrl"] is String) {
      certificateUrl = json["certificateUrl"];
    }
    expiryDate = json["expiryDate"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["applicable"] = applicable;
    data["state"] = state;
    data["verificationStatus"] = verificationStatus;
    data["registrationNumber"] = registrationNumber;
    data["certificateUrl"] = certificateUrl;
    data["expiryDate"] = expiryDate;
    return data;
  }
}

class Business {
  String? businessName;
  String? businessType;
  String? gstin;
  String? registrationNumber;
  String? officeAddress;

  Business({this.businessName, this.businessType, this.gstin, this.registrationNumber, this.officeAddress});

  Business.fromJson(Map<String, dynamic> json) {
    if(json["businessName"] is String) {
      businessName = json["businessName"];
    }
    if(json["businessType"] is String) {
      businessType = json["businessType"];
    }
    if(json["gstin"] is String) {
      gstin = json["gstin"];
    }
    if(json["registrationNumber"] is String) {
      registrationNumber = json["registrationNumber"];
    }
    if(json["officeAddress"] is String) {
      officeAddress = json["officeAddress"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["businessName"] = businessName;
    data["businessType"] = businessType;
    data["gstin"] = gstin;
    data["registrationNumber"] = registrationNumber;
    data["officeAddress"] = officeAddress;
    return data;
  }
}

class PopularAreas {
  String? city;
  String? locality;
  int? propertyCount;
  String? image;

  PopularAreas({this.city, this.locality, this.propertyCount, this.image});

  PopularAreas.fromJson(Map<String, dynamic> json) {
    if(json["city"] is String) {
      city = json["city"];
    }
    if(json["locality"] is String) {
      locality = json["locality"];
    }
    if(json["propertyCount"] is int) {
      propertyCount = json["propertyCount"];
    }
    final rawImg = json["image"] ?? json["imageUrl"] ?? json["url"] ?? json["coverImage"] ?? json["thumbnail"] ?? json["photo"];
    if (rawImg is String && rawImg.trim().isNotEmpty && rawImg.trim().toLowerCase() != 'null') {
      image = ImageCase.sanitizeUrl(rawImg.trim());
    } else if (rawImg is Map) {
      image = ImageCase.sanitizeUrl((rawImg["url"] ?? rawImg["secure_url"] ?? rawImg["image"])?.toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["city"] = city;
    data["locality"] = locality;
    data["propertyCount"] = propertyCount;
    data["image"] = image;
    return data;
  }
}

class NewListings {
  String? id;
  String? propertyId;
  String? title;
  String? transactionType;
  String? category;
  int? price;
  int? pricePerSqft;
  String? city;
  String? locality;
  String? address;
  double? latitude;
  double? longitude;
  String? bedrooms;
  String? bathrooms;
  String? furnishing;
  List<Images1>? images;
  String? createdAt;
  Promotion1? promotion;
  dynamic distanceKm;
  bool? sameCity;
  String? listedAgo;

  NewListings({this.id, this.propertyId, this.title, this.transactionType, this.category, this.price, this.pricePerSqft, this.city, this.locality, this.address, this.latitude, this.longitude, this.bedrooms, this.bathrooms, this.furnishing, this.images, this.createdAt, this.promotion, this.distanceKm, this.sameCity, this.listedAgo});

  NewListings.fromJson(Map<String, dynamic> json) {
    if(json["_id"] is String) {
      id = json["_id"];
    }
    if(json["propertyId"] is String) {
      propertyId = json["propertyId"];
    }
    if(json["title"] is String) {
      title = json["title"];
    }
    if(json["transactionType"] is String) {
      transactionType = json["transactionType"];
    }
    if(json["category"] is String) {
      category = json["category"];
    }

    // Flexible Price Parsing
    if (json["price"] is num) {
      price = (json["price"] as num).toInt();
    } else if (json["price"] is Map) {
      final pMap = json["price"] as Map;
      final amt = pMap["amount"] ?? pMap["price"] ?? pMap["value"];
      if (amt is num) {
        price = amt.toInt();
      } else if (amt != null) {
        price = int.tryParse(amt.toString());
      }
      final perSq = pMap["pricePerSqFt"] ?? pMap["pricePerSqft"];
      if (perSq is num) {
        pricePerSqft = perSq.toInt();
      } else if (perSq != null) {
        pricePerSqft = int.tryParse(perSq.toString());
      }
    } else if (json["price"] != null) {
      price = int.tryParse(json["price"].toString());
    }

    if (json["pricePerSqft"] is num) {
      pricePerSqft = (json["pricePerSqft"] as num).toInt();
    } else if (json["pricePerSqFt"] is num) {
      pricePerSqft = (json["pricePerSqFt"] as num).toInt();
    }

    if(json["city"] is String) {
      city = json["city"];
    }
    if(json["locality"] is String) {
      locality = json["locality"];
    }
    if(json["address"] is String) {
      address = json["address"];
    }
    if (json["location"] is Map) {
      final loc = json["location"] as Map;
      city ??= loc["city"]?.toString();
      locality ??= loc["locality"]?.toString();
      address ??= loc["address"]?.toString();
      if (latitude == null && loc["latitude"] is num) {
        latitude = (loc["latitude"] as num).toDouble();
      }
      if (longitude == null && loc["longitude"] is num) {
        longitude = (loc["longitude"] as num).toDouble();
      }
    }

    if(json["latitude"] is num) {
      latitude = (json["latitude"] as num).toDouble();
    } else if (json["latitude"] != null) {
      latitude = double.tryParse(json["latitude"].toString());
    }
    if(json["longitude"] is num) {
      longitude = (json["longitude"] as num).toDouble();
    } else if (json["longitude"] != null) {
      longitude = double.tryParse(json["longitude"].toString());
    }

    if(json["bedrooms"] != null) {
      bedrooms = json["bedrooms"].toString();
    }
    if(json["bathrooms"] != null) {
      bathrooms = json["bathrooms"].toString();
    }
    if(json["furnishing"] is String) {
      furnishing = json["furnishing"];
    } else if (json["furnishing"] is Map) {
      final fMap = json["furnishing"] as Map;
      furnishing = fMap["status"]?.toString() ?? fMap["name"]?.toString();
    }

    dynamic rawImages = json["images"];
    if (rawImages is! List || rawImages.isEmpty) {
      if (json["media"] is Map) {
        final media = json["media"] as Map;
        rawImages = media["images"] ?? media["photos"];
      }
    }
    if (rawImages is! List || rawImages.isEmpty) {
      rawImages = json["photos"] ?? json["gallery"];
    }

    if (rawImages is List && rawImages.isNotEmpty) {
      images = rawImages
          .map((e) => Images1.fromJson(e))
          .where((e) => e.url != null && e.url!.isNotEmpty)
          .toList();
    } else {
      final single = json["image"] ?? json["imageUrl"] ?? json["coverImage"] ?? json["thumbnail"] ?? json["photo"];
      if (single != null && single.toString().trim().isNotEmpty && single.toString().trim().toLowerCase() != 'null') {
        images = [Images1(url: ImageCase.sanitizeUrl(single.toString().trim()))];
      }
    }

    images ??= [];
    if(json["createdAt"] is String) {
      createdAt = json["createdAt"];
    }
    if(json["promotion"] is Map) {
      promotion = json["promotion"] == null ? null : Promotion1.fromJson(json["promotion"]);
    }
    distanceKm = json["distanceKm"];
    if(json["sameCity"] is bool) {
      sameCity = json["sameCity"];
    }
    if(json["listedAgo"] is String) {
      listedAgo = json["listedAgo"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["_id"] = id;
    data["propertyId"] = propertyId;
    data["title"] = title;
    data["transactionType"] = transactionType;
    data["category"] = category;
    data["price"] = price;
    data["pricePerSqft"] = pricePerSqft;
    data["city"] = city;
    data["locality"] = locality;
    data["address"] = address;
    data["latitude"] = latitude;
    data["longitude"] = longitude;
    data["bedrooms"] = bedrooms;
    data["bathrooms"] = bathrooms;
    data["furnishing"] = furnishing;
    if(images != null) {
      data["images"] = images?.map((e) => e.toJson()).toList();
    }
    data["createdAt"] = createdAt;
    if(promotion != null) {
      data["promotion"] = promotion?.toJson();
    }
    data["distanceKm"] = distanceKm;
    data["sameCity"] = sameCity;
    data["listedAgo"] = listedAgo;
    return data;
  }
}

class Promotion1 {
  bool? boost;
  bool? featured;
  bool? localityTop;
  bool? sponsored;
  int? score;

  Promotion1({this.boost, this.featured, this.localityTop, this.sponsored, this.score});

  Promotion1.fromJson(Map<String, dynamic> json) {
    if(json["boost"] is bool) {
      boost = json["boost"];
    }
    if(json["featured"] is bool) {
      featured = json["featured"];
    }
    if(json["localityTop"] is bool) {
      localityTop = json["localityTop"];
    }
    if(json["sponsored"] is bool) {
      sponsored = json["sponsored"];
    }
    if(json["score"] is int) {
      score = json["score"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["boost"] = boost;
    data["featured"] = featured;
    data["localityTop"] = localityTop;
    data["sponsored"] = sponsored;
    data["score"] = score;
    return data;
  }
}

class Images1 {
  String? url;
  String? publicId;
  String? id;

  Images1({this.url, this.publicId, this.id});

  Images1.fromJson(dynamic json) {
    if (json is String) {
      url = ImageCase.sanitizeUrl(json.trim());
      return;
    }
    if (json is Map) {
      final raw = json["url"] ?? json["secure_url"] ?? json["image"] ?? json["imageUrl"] ?? json["path"];
      if (raw != null) url = ImageCase.sanitizeUrl(raw.toString().trim());
      publicId = (json["public_id"] ?? json["publicId"])?.toString();
      id = (json["_id"] ?? json["id"])?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["url"] = url;
    data["public_id"] = publicId;
    data["_id"] = id;
    return data;
  }
}

class RecommendedProperties {
  String? id;
  String? propertyId;
  String? title;
  String? transactionType;
  String? category;
  int? price;
  int? pricePerSqft;
  String? city;
  String? locality;
  String? address;
  double? latitude;
  double? longitude;
  String? bedrooms;
  String? bathrooms;
  String? furnishing;
  List<Images>? images;
  String? createdAt;
  Promotion? promotion;
  dynamic distanceKm;
  bool? sameCity;
  String? videoUrl; // optional property video (story)

  RecommendedProperties({this.id, this.propertyId, this.title, this.transactionType, this.category, this.price, this.pricePerSqft, this.city, this.locality, this.address, this.latitude, this.longitude, this.bedrooms, this.bathrooms, this.furnishing, this.images, this.createdAt, this.promotion, this.distanceKm, this.sameCity});

  RecommendedProperties.fromJson(Map<String, dynamic> json) {
    if(json["_id"] is String) {
      id = json["_id"];
    }
    if(json["propertyId"] is String) {
      propertyId = json["propertyId"];
    }
    if(json["title"] is String) {
      title = json["title"];
    }
    if(json["transactionType"] is String) {
      transactionType = json["transactionType"];
    }
    if(json["category"] is String) {
      category = json["category"];
    }

    // Flexible Price Parsing
    if (json["price"] is num) {
      price = (json["price"] as num).toInt();
    } else if (json["price"] is Map) {
      final pMap = json["price"] as Map;
      final amt = pMap["amount"] ?? pMap["price"] ?? pMap["value"];
      if (amt is num) {
        price = amt.toInt();
      } else if (amt != null) {
        price = int.tryParse(amt.toString());
      }
      final perSq = pMap["pricePerSqFt"] ?? pMap["pricePerSqft"];
      if (perSq is num) {
        pricePerSqft = perSq.toInt();
      } else if (perSq != null) {
        pricePerSqft = int.tryParse(perSq.toString());
      }
    } else if (json["price"] != null) {
      price = int.tryParse(json["price"].toString());
    }

    if (json["pricePerSqft"] is num) {
      pricePerSqft = (json["pricePerSqft"] as num).toInt();
    } else if (json["pricePerSqFt"] is num) {
      pricePerSqft = (json["pricePerSqFt"] as num).toInt();
    }

    if(json["city"] is String) {
      city = json["city"];
    }
    if(json["locality"] is String) {
      locality = json["locality"];
    }
    if(json["address"] is String) {
      address = json["address"];
    }
    if (json["location"] is Map) {
      final loc = json["location"] as Map;
      city ??= loc["city"]?.toString();
      locality ??= loc["locality"]?.toString();
      address ??= loc["address"]?.toString();
      if (latitude == null && loc["latitude"] is num) {
        latitude = (loc["latitude"] as num).toDouble();
      }
      if (longitude == null && loc["longitude"] is num) {
        longitude = (loc["longitude"] as num).toDouble();
      }
    }

    if(json["latitude"] is num) {
      latitude = (json["latitude"] as num).toDouble();
    } else if (json["latitude"] != null) {
      latitude = double.tryParse(json["latitude"].toString());
    }
    if(json["longitude"] is num) {
      longitude = (json["longitude"] as num).toDouble();
    } else if (json["longitude"] != null) {
      longitude = double.tryParse(json["longitude"].toString());
    }

    if(json["bedrooms"] != null) {
      bedrooms = json["bedrooms"].toString();
    }
    if(json["bathrooms"] != null) {
      bathrooms = json["bathrooms"].toString();
    }
    if(json["furnishing"] is String) {
      furnishing = json["furnishing"];
    } else if (json["furnishing"] is Map) {
      final fMap = json["furnishing"] as Map;
      furnishing = fMap["status"]?.toString() ?? fMap["name"]?.toString();
    }

    dynamic rawImages = json["images"];
    if (rawImages is! List || rawImages.isEmpty) {
      if (json["media"] is Map) {
        final media = json["media"] as Map;
        rawImages = media["images"] ?? media["photos"];
      }
    }
    if (rawImages is! List || rawImages.isEmpty) {
      rawImages = json["photos"] ?? json["gallery"];
    }

    if (rawImages is List && rawImages.isNotEmpty) {
      images = rawImages
          .map((e) => Images.fromJson(e))
          .where((e) => e.url != null && e.url!.isNotEmpty)
          .toList();
    } else {
      final single = json["image"] ?? json["imageUrl"] ?? json["coverImage"] ?? json["thumbnail"] ?? json["photo"];
      if (single != null && single.toString().trim().isNotEmpty && single.toString().trim().toLowerCase() != 'null') {
        images = [Images(url: ImageCase.sanitizeUrl(single.toString().trim()))];
      }
    }

    images ??= [];
    if(json["createdAt"] is String) {
      createdAt = json["createdAt"];
    }
    if(json["promotion"] is Map) {
      promotion = json["promotion"] == null ? null : Promotion.fromJson(json["promotion"]);
    }
    distanceKm = json["distanceKm"];
    if(json["sameCity"] is bool) {
      sameCity = json["sameCity"];
    }
    videoUrl = _pickVideoUrl(json);
  }

  /// Tolerant video url reader: videoUrl / video / videos[0].url
  static String? _pickVideoUrl(Map<String, dynamic> json) {
    final v = json["videoUrl"] ?? json["video"];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is Map && v["url"] is String) return v["url"];
    final vs = json["videos"];
    if (vs is List && vs.isNotEmpty) {
      final f = vs.first;
      if (f is String && f.trim().isNotEmpty) return f.trim();
      if (f is Map && f["url"] is String) return f["url"];
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["_id"] = id;
    data["propertyId"] = propertyId;
    data["title"] = title;
    data["transactionType"] = transactionType;
    data["category"] = category;
    data["price"] = price;
    data["pricePerSqft"] = pricePerSqft;
    data["city"] = city;
    data["locality"] = locality;
    data["address"] = address;
    data["latitude"] = latitude;
    data["longitude"] = longitude;
    data["bedrooms"] = bedrooms;
    data["bathrooms"] = bathrooms;
    data["furnishing"] = furnishing;
    if(images != null) {
      data["images"] = images?.map((e) => e.toJson()).toList();
    }
    data["createdAt"] = createdAt;
    if(promotion != null) {
      data["promotion"] = promotion?.toJson();
    }
    data["distanceKm"] = distanceKm;
    data["sameCity"] = sameCity;
    data["videoUrl"] = videoUrl;
    return data;
  }
}

class Promotion {
  bool? boost;
  bool? featured;
  bool? localityTop;
  bool? sponsored;
  int? score;

  Promotion({this.boost, this.featured, this.localityTop, this.sponsored, this.score});

  Promotion.fromJson(Map<String, dynamic> json) {
    if(json["boost"] is bool) {
      boost = json["boost"];
    }
    if(json["featured"] is bool) {
      featured = json["featured"];
    }
    if(json["localityTop"] is bool) {
      localityTop = json["localityTop"];
    }
    if(json["sponsored"] is bool) {
      sponsored = json["sponsored"];
    }
    if(json["score"] is int) {
      score = json["score"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["boost"] = boost;
    data["featured"] = featured;
    data["localityTop"] = localityTop;
    data["sponsored"] = sponsored;
    data["score"] = score;
    return data;
  }
}

class Images {
  String? url;
  String? publicId;
  String? id;

  Images({this.url, this.publicId, this.id});

  Images.fromJson(dynamic json) {
    if (json is String) {
      url = ImageCase.sanitizeUrl(json.trim());
      return;
    }
    if (json is Map) {
      final raw = json["url"] ?? json["secure_url"] ?? json["image"] ?? json["imageUrl"] ?? json["path"];
      if (raw != null) url = ImageCase.sanitizeUrl(raw.toString().trim());
      publicId = (json["public_id"] ?? json["publicId"])?.toString();
      id = (json["_id"] ?? json["id"])?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["url"] = url;
    data["public_id"] = publicId;
    data["_id"] = id;
    return data;
  }
}

class Banners {
  String? type;
  String? image;

  Banners({this.type, this.image});

  Banners.fromJson(Map<String, dynamic> json) {
    if(json["type"] is String) {
      type = json["type"];
    }
    final rawImg = json["image"] ?? json["imageUrl"] ?? json["url"] ?? json["banner"];
    if (rawImg is String && rawImg.trim().isNotEmpty && rawImg.trim().toLowerCase() != 'null') {
      image = ImageCase.sanitizeUrl(rawImg.trim());
    } else if (rawImg is Map) {
      image = ImageCase.sanitizeUrl((rawImg["url"] ?? rawImg["secure_url"])?.toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["type"] = type;
    data["image"] = image;
    return data;
  }
}

class Location {
  String? source;
  dynamic latitude;
  dynamic longitude;
  String? city;
  String? state;
  String? country;
  String? address;

  Location({this.source, this.latitude, this.longitude, this.city, this.state, this.country, this.address});

  Location.fromJson(Map<String, dynamic> json) {
    if(json["source"] is String) {
      source = json["source"];
    }
    latitude = json["latitude"];
    longitude = json["longitude"];
    if(json["city"] is String) {
      city = json["city"];
    }
    if(json["state"] is String) {
      state = json["state"];
    }
    if(json["country"] is String) {
      country = json["country"];
    }
    if(json["address"] is String) {
      address = json["address"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["source"] = source;
    data["latitude"] = latitude;
    data["longitude"] = longitude;
    data["city"] = city;
    data["state"] = state;
    data["country"] = country;
    data["address"] = address;
    return data;
  }
}