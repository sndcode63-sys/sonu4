
// class NearByAgent {
//   bool? success;
//   String? message;
//   Data? data;
//
//   NearByAgent({this.success, this.message, this.data});
//
//   NearByAgent.fromJson(Map<String, dynamic> json) {
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

class NearByAgent {
  Location? location;
  int? count;
  List<Agents>? agents;

  NearByAgent({this.location, this.count, this.agents});

  NearByAgent.fromJson(Map<String, dynamic> json) {
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location.fromJson(json["location"]);
    }
    if(json["count"] is int) {
      count = json["count"];
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
    data["count"] = count;
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
  Promotion? promotion;
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
      promotion = json["promotion"] == null ? null : Promotion.fromJson(json["promotion"]);
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

class Promotion {
  bool? boost;
  bool? featured;
  bool? localityTop;
  List<dynamic>? codes;
  int? score;

  Promotion({this.boost, this.featured, this.localityTop, this.codes, this.score});

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