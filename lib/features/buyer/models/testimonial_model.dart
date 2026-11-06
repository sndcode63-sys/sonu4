class TestimonialModel {
  final String id;
  final String name;
  final String designation;
  final String review;
  final String? imageUrl;
  final String? videoLink;
  final bool isActive;
  final DateTime? createdAt;

  TestimonialModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.review,
    this.imageUrl,
    this.videoLink,
    this.isActive = true,
    this.createdAt,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    String? img;
    if (json['image'] is Map) {
      img = json['image']['url']?.toString();
    } else if (json['image'] is String) {
      img = json['image']?.toString();
    }

    return TestimonialModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Community Member',
      designation: json['designation']?.toString() ?? 'Home Buyer',
      review: json['review']?.toString() ?? '',
      imageUrl: img,
      videoLink: json['videoLink']?.toString(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'designation': designation,
      'review': review,
      'image': imageUrl != null ? {'url': imageUrl} : null,
      'videoLink': videoLink,
      'isActive': isActive,
    };
  }
}
