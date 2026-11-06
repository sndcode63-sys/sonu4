
// class PropertyCateforyFiter {
//   bool? success;
//   String? message;
//   Data? data;
//
//   PropertyCateforyFiter({this.success, this.message, this.data});
//
//   PropertyCateforyFiter.fromJson(Map<String, dynamic> json) {
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

class ProperttCategoryFilter {
  Location? location;
  List<String>? tabs;
  List<Categories>? categories;
  Selected? selected;
  List<Properties>? properties;

  ProperttCategoryFilter({this.location, this.tabs, this.categories, this.selected, this.properties});

  ProperttCategoryFilter.fromJson(Map<String, dynamic> json) {
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location.fromJson(json["location"]);
    }
    if(json["tabs"] is List) {
      tabs = json["tabs"] == null ? null : List<String>.from(json["tabs"]);
    }
    if(json["categories"] is List) {
      categories = json["categories"] == null ? null : (json["categories"] as List).map((e) => Categories.fromJson(e)).toList();
    }
    if(json["selected"] is Map) {
      selected = json["selected"] == null ? null : Selected.fromJson(json["selected"]);
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
    if(tabs != null) {
      data["tabs"] = tabs;
    }
    if(categories != null) {
      data["categories"] = categories?.map((e) => e.toJson()).toList();
    }
    if(selected != null) {
      data["selected"] = selected?.toJson();
    }
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

  Properties({this.id, this.propertyId, this.title, this.transactionType, this.category, this.price, this.pricePerSqft, this.city, this.locality, this.address, this.latitude, this.longitude, this.bedrooms, this.bathrooms, this.furnishing, this.images, this.createdAt, this.promotion, this.distanceKm, this.sameCity});

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

    if (json["images"] is List && (json["images"] as List).isNotEmpty) {
      images = (json["images"] as List)
          .map((e) => Images.fromJson(e))
          .where((e) => e.url != null && e.url!.isNotEmpty)
          .toList();
    } else if (json["photos"] is List && (json["photos"] as List).isNotEmpty) {
      images = (json["photos"] as List)
          .map((e) => Images.fromJson(e))
          .where((e) => e.url != null && e.url!.isNotEmpty)
          .toList();
    } else {
      final single = json["image"] ?? json["imageUrl"] ?? json["coverImage"] ?? json["thumbnail"];
      if (single != null && single.toString().trim().isNotEmpty && single.toString().trim().toLowerCase() != 'null') {
        images = [Images(url: single.toString().trim())];
      }
    }
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
      url = json.trim();
      return;
    }
    if (json is Map) {
      final raw = json["url"] ?? json["secure_url"] ?? json["image"] ?? json["imageUrl"] ?? json["path"];
      if (raw != null) url = raw.toString().trim();
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

class Selected {
  dynamic tab;
  dynamic category;

  Selected({this.tab, this.category});

  Selected.fromJson(Map<String, dynamic> json) {
    tab = json["tab"];
    category = json["category"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["tab"] = tab;
    data["category"] = category;
    return data;
  }
}

class Categories {
  String? name;
  int? count;

  Categories({this.name, this.count});

  Categories.fromJson(Map<String, dynamic> json) {
    if(json["name"] is String) {
      name = json["name"];
    }
    if(json["count"] is int) {
      count = json["count"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["name"] = name;
    data["count"] = count;
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