
import '../../../core/widgets/app_image.dart';

class PropertyNewListing {
  Location? location;
  int? count;
  List<Properties>? properties;

  PropertyNewListing({this.location, this.count, this.properties});

  PropertyNewListing.fromJson(Map<String, dynamic> json) {
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location.fromJson(json["location"]);
    }
    if(json["count"] is int) {
      count = json["count"];
    }
    if(json["properties"] is List) {
      properties = json["properties"] == null ? null : (json["properties"] as List).map((e) => Properties.fromJson(e)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if(location != null) {
      data["location"] = location?.toJson();
    }
    data["count"] = count;
    if(properties != null) {
      data["properties"] = properties?.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class Properties {
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
  String? listedAgo;

  Properties({this.id, this.propertyId, this.title, this.transactionType, this.category, this.price, this.pricePerSqft, this.city, this.locality, this.address, this.latitude, this.longitude, this.bedrooms, this.bathrooms, this.furnishing, this.images, this.createdAt, this.promotion, this.distanceKm, this.sameCity, this.listedAgo});

  Properties.fromJson(Map<String, dynamic> json) {
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
          .where((img) => img.url != null && img.url!.isNotEmpty)
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
      // Try secure_url first (Cloudinary), then url, then other variants
      final raw = json["secure_url"] ??
          json["url"] ??
          json["imageUrl"] ??
          json["image"] ??
          json["path"];
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