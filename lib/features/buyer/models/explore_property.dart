// class ExploreNearbyResponse {
//   bool? success;
//   String? message;
//   ExploreNearbyData? data;
//
//   ExploreNearbyResponse({this.success, this.message, this.data});
//
//   ExploreNearbyResponse.fromJson(Map<String, dynamic> json) {
//     success = json['success'];
//     message = json['message'];
//     data = json['data'] != null ? ExploreNearbyData.fromJson(json['data']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['success'] = success;
//     data['message'] = message;
//     if (this.data != null) {
//       data['data'] = this.data!.toJson();
//     }
//     return data;
//   }
// }

class ExploreNearbyData {
  Property? property;
  MapDetails? map;
  int? radiusMeters;
  String? provider;
  String? warning;
  String? distanceNote;
  Amenities? amenities;

  ExploreNearbyData({
    this.property,
    this.map,
    this.radiusMeters,
    this.provider,
    this.warning,
    this.distanceNote,
    this.amenities,
  });

  ExploreNearbyData.fromJson(Map<String, dynamic> json) {
    property = json['property'] != null ? Property.fromJson(json['property']) : null;
    map = json['map'] != null ? MapDetails.fromJson(json['map']) : null;
    radiusMeters = json['radiusMeters'];
    provider = json['provider'];
    warning = json['warning'];
    distanceNote = json['distanceNote'];
    amenities = json['amenities'] != null ? Amenities.fromJson(json['amenities']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (property != null) {
      data['property'] = property!.toJson();
    }
    if (map != null) {
      data['map'] = map!.toJson();
    }
    data['radiusMeters'] = radiusMeters;
    data['provider'] = provider;
    data['warning'] = warning;
    data['distanceNote'] = distanceNote;
    if (amenities != null) {
      data['amenities'] = amenities!.toJson();
    }
    return data;
  }
}

class Property {
  String? sId;
  String? propertyId;
  String? title;
  String? city;
  String? locality;
  double? latitude;
  double? longitude;
  String? icon;
  String? iconEmoji;
  String? mapUrl;

  Property({
    this.sId,
    this.propertyId,
    this.title,
    this.city,
    this.locality,
    this.latitude,
    this.longitude,
    this.icon,
    this.iconEmoji,
    this.mapUrl,
  });

  Property.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    propertyId = json['propertyId'];
    title = json['title'];
    city = json['city'];
    locality = json['locality'];
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    icon = json['icon'];
    iconEmoji = json['iconEmoji'];
    mapUrl = json['mapUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['propertyId'] = propertyId;
    data['title'] = title;
    data['city'] = city;
    data['locality'] = locality;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['icon'] = icon;
    data['iconEmoji'] = iconEmoji;
    data['mapUrl'] = mapUrl;
    return data;
  }
}

class MapDetails {
  CenterCoordinates? center;
  int? zoom;
  int? radiusMeters;
  List<Markers>? markers;
  MarkerLegend? markerLegend;

  MapDetails({
    this.center,
    this.zoom,
    this.radiusMeters,
    this.markers,
    this.markerLegend,
  });

  MapDetails.fromJson(Map<String, dynamic> json) {
    center = json['center'] != null ? CenterCoordinates.fromJson(json['center']) : null;
    zoom = json['zoom'];
    radiusMeters = json['radiusMeters'];
    if (json['markers'] != null) {
      markers = <Markers>[];
      json['markers'].forEach((v) {
        markers!.add(Markers.fromJson(v));
      });
    }
    markerLegend = json['markerLegend'] != null ? MarkerLegend.fromJson(json['markerLegend']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (center != null) {
      data['center'] = center!.toJson();
    }
    data['zoom'] = zoom;
    data['radiusMeters'] = radiusMeters;
    if (markers != null) {
      data['markers'] = markers!.map((v) => v.toJson()).toList();
    }
    if (markerLegend != null) {
      data['markerLegend'] = markerLegend!.toJson();
    }
    return data;
  }
}

class CenterCoordinates {
  double? latitude;
  double? longitude;

  CenterCoordinates({this.latitude, this.longitude});

  CenterCoordinates.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class Markers {
  String? id;
  String? mongoId;
  String? propertyId;
  String? markerType;
  String? category;
  String? type;
  String? name;
  double? latitude;
  double? longitude;
  String? icon;
  String? iconEmoji;
  String? mapUrl;
  String? directionsUrl;
  num? distanceKm;
  num? distanceMeters;

  Markers({
    this.id,
    this.mongoId,
    this.propertyId,
    this.markerType,
    this.category,
    this.type,
    this.name,
    this.latitude,
    this.longitude,
    this.icon,
    this.iconEmoji,
    this.mapUrl,
    this.directionsUrl,
    this.distanceKm,
    this.distanceMeters,
  });

  Markers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mongoId = json['mongoId'];
    propertyId = json['propertyId'];
    markerType = json['markerType'];
    category = json['category'];
    type = json['type'];
    name = json['name'];
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    icon = json['icon'];
    iconEmoji = json['iconEmoji'];
    mapUrl = json['mapUrl'];
    directionsUrl = json['directionsUrl'];
    distanceKm = json['distanceKm'];
    distanceMeters = json['distanceMeters'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mongoId'] = mongoId;
    data['propertyId'] = propertyId;
    data['markerType'] = markerType;
    data['category'] = category;
    data['type'] = type;
    data['name'] = name;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['icon'] = icon;
    data['iconEmoji'] = iconEmoji;
    data['mapUrl'] = mapUrl;
    data['directionsUrl'] = directionsUrl;
    data['distanceKm'] = distanceKm;
    data['distanceMeters'] = distanceMeters;
    return data;
  }
}

class MarkerLegend {
  LegendItem? property;
  LegendItem? education;
  LegendItem? healthcare;
  LegendItem? food;

  MarkerLegend({this.property, this.education, this.healthcare, this.food});

  MarkerLegend.fromJson(Map<String, dynamic> json) {
    property = json['property'] != null ? LegendItem.fromJson(json['property']) : null;
    education = json['education'] != null ? LegendItem.fromJson(json['education']) : null;
    healthcare = json['healthcare'] != null ? LegendItem.fromJson(json['healthcare']) : null;
    food = json['food'] != null ? LegendItem.fromJson(json['food']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (property != null) {
      data['property'] = property!.toJson();
    }
    if (education != null) {
      data['education'] = education!.toJson();
    }
    if (healthcare != null) {
      data['healthcare'] = healthcare!.toJson();
    }
    if (food != null) {
      data['food'] = food!.toJson();
    }
    return data;
  }
}

class LegendItem {
  String? markerType;
  String? icon;
  String? iconEmoji;
  String? label;

  LegendItem({this.markerType, this.icon, this.iconEmoji, this.label});

  LegendItem.fromJson(Map<String, dynamic> json) {
    markerType = json['markerType'];
    icon = json['icon'];
    iconEmoji = json['iconEmoji'];
    label = json['label'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['markerType'] = markerType;
    data['icon'] = icon;
    data['iconEmoji'] = iconEmoji;
    data['label'] = label;
    return data;
  }
}

class Amenities {
  List<dynamic>? education;
  List<dynamic>? healthcare;
  List<dynamic>? food;

  Amenities({this.education, this.healthcare, this.food});

  Amenities.fromJson(Map<String, dynamic> json) {
    education = json['education'] ?? [];
    healthcare = json['healthcare'] ?? [];
    food = json['food'] ?? [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['education'] = education;
    data['healthcare'] = healthcare;
    data['food'] = food;
    return data;
  }
}