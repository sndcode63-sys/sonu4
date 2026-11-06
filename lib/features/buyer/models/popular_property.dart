
// class PopularProperty {
//   bool? success;
//   String? message;
//   Data? data;
//
//   PopularProperty({this.success, this.message, this.data});
//
//   PopularProperty.fromJson(Map<String, dynamic> json) {
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

class PopularProperty {
  String? title;
  Location? location;
  List<Areas>? areas;

  PopularProperty({this.title, this.location, this.areas});

  PopularProperty.fromJson(Map<String, dynamic> json) {
    if(json["title"] is String) {
      title = json["title"];
    }
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location.fromJson(json["location"]);
    }
    if(json["areas"] is List) {
      areas = json["areas"] == null ? null : (json["areas"] as List).map((e) => Areas.fromJson(e)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["title"] = title;
    if(location != null) {
      data["location"] = location?.toJson();
    }
    if(areas != null) {
      data["areas"] = areas?.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class Areas {
  String? city;
  String? locality;
  int? propertyCount;
  int? promotedCount;
  String? sampleImage;
  List<Properties>? properties;

  Areas({this.city, this.locality, this.propertyCount, this.promotedCount, this.sampleImage, this.properties});

  Areas.fromJson(Map<String, dynamic> json) {
    if(json["city"] is String) {
      city = json["city"];
    }
    if(json["locality"] is String) {
      locality = json["locality"];
    }
    if(json["propertyCount"] is int) {
      propertyCount = json["propertyCount"];
    }
    if(json["promotedCount"] is int) {
      promotedCount = json["promotedCount"];
    }
    if(json["sampleImage"] is String) {
      sampleImage = json["sampleImage"];
    }
    if(json["properties"] is List) {
      properties = json["properties"] == null ? null : (json["properties"] as List).map((e) => Properties.fromJson(e)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["city"] = city;
    data["locality"] = locality;
    data["propertyCount"] = propertyCount;
    data["promotedCount"] = promotedCount;
    data["sampleImage"] = sampleImage;
    if(properties != null) {
      data["properties"] = properties?.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class Properties {
  String? mongoId;
  String? id;
  String? propertyId;
  String? title;
  int? price;
  String? image;

  Properties({this.mongoId, this.id, this.propertyId, this.title, this.price, this.image});

  Properties.fromJson(Map<String, dynamic> json) {
    if(json["mongoId"] is String) {
      mongoId = json["mongoId"];
    }
    if(json["_id"] is String) {
      id = json["_id"];
    }
    if(json["propertyId"] is String) {
      propertyId = json["propertyId"];
    }
    if(json["title"] is String) {
      title = json["title"];
    }
    if(json["price"] is int) {
      price = json["price"];
    }
    if(json["image"] is String) {
      image = json["image"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["mongoId"] = mongoId;
    data["_id"] = id;
    data["propertyId"] = propertyId;
    data["title"] = title;
    data["price"] = price;
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