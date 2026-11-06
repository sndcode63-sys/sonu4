class PropertyReviewModel {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final num rating;
  final String remark;
  final DateTime? createdAt;

  const PropertyReviewModel({
    required this.id,
    required this.propertyId,
    this.userId = '',
    this.userName = 'Verified Buyer',
    this.userAvatar,
    this.rating = 5,
    this.remark = '',
    this.createdAt,
  });

  factory PropertyReviewModel.fromJson(Map<String, dynamic> json) {
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    String propId = json['propertyId']?.toString() ?? '';
    String uId = '';
    String uName = 'Verified Buyer';
    String? uAvatar;

    if (json['user'] is Map) {
      final u = json['user'] as Map<String, dynamic>;
      uId = u['_id']?.toString() ?? u['id']?.toString() ?? '';
      uName = u['name']?.toString() ?? uName;
      uAvatar = u['avatar']?.toString() ?? u['profileImage']?.toString();
    } else if (json['userId'] is Map) {
      final u = json['userId'] as Map<String, dynamic>;
      uId = u['_id']?.toString() ?? u['id']?.toString() ?? '';
      uName = u['name']?.toString() ?? uName;
      uAvatar = u['avatar']?.toString();
    } else {
      uId = json['userId']?.toString() ?? '';
      uName = json['userName']?.toString() ?? json['name']?.toString() ?? uName;
      uAvatar = json['userAvatar']?.toString();
    }

    num r = 5;
    if (json['rating'] is num) {
      r = json['rating'];
    } else if (json['rating'] != null) {
      r = num.tryParse(json['rating'].toString()) ?? 5;
    }

    DateTime? date;
    if (json['createdAt'] != null) {
      try {
        date = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    return PropertyReviewModel(
      id: id,
      propertyId: propId,
      userId: uId,
      userName: uName,
      userAvatar: uAvatar,
      rating: r,
      remark: json['remark']?.toString() ?? json['comment']?.toString() ?? '',
      createdAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'remark': remark,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
