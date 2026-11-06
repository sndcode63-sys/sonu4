
// class BuyerDashboard {
//   bool? success;
//   String? message;
//   Data? data;
//
//   BuyerDashboard({this.success, this.message, this.data});
//
//   BuyerDashboard.fromJson(Map<String, dynamic> json) {
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

class BuerDashboardModel {
  String? greeting;
  User? user;
  Location? location;
  int? unreadNotificationsCount;
  List<dynamic>? notifications;

  BuerDashboardModel({this.greeting, this.user, this.location, this.unreadNotificationsCount, this.notifications});

  BuerDashboardModel.fromJson(Map<String, dynamic> json) {
    if(json["greeting"] is String) {
      greeting = json["greeting"];
    }
    if(json["user"] is Map) {
      user = json["user"] == null ? null : User.fromJson(json["user"]);
    }
    if(json["location"] is Map) {
      location = json["location"] == null ? null : Location.fromJson(json["location"]);
    }
    final count = json["unreadNotificationsCount"] ?? json["unreadNotificationCount"] ?? json["unreadCount"];
    if (count is num) {
      unreadNotificationsCount = count.toInt();
    } else if (count is String) {
      unreadNotificationsCount = int.tryParse(count);
    }
    if (json["notifications"] is List) {
      notifications = List<dynamic>.from(json["notifications"]);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["greeting"] = greeting;
    if(user != null) {
      data["user"] = user?.toJson();
    }
    if(location != null) {
      data["location"] = location?.toJson();
    }
    data["unreadNotificationsCount"] = unreadNotificationsCount;
    if(notifications != null) {
      data["notifications"] = notifications;
    }
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

class User {
  String? id;
  String? buyerId;
  String? name;
  String? avatar;

  User({this.id, this.buyerId, this.name, this.avatar});

  User.fromJson(Map<String, dynamic> json) {
    if(json["_id"] is String) {
      id = json["_id"];
    }
    if(json["buyerId"] is String) {
      buyerId = json["buyerId"];
    }
    if(json["name"] is String) {
      name = json["name"];
    }
    if(json["avatar"] is String) {
      avatar = json["avatar"];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["_id"] = id;
    data["buyerId"] = buyerId;
    data["name"] = name;
    data["avatar"] = avatar;
    return data;
  }
}