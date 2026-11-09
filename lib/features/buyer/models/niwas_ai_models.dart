class AiPropertyCard {
  final String id;
  final String title;
  final String? projectName;
  final String? description;
  final String? category;
  final String? transactionType;
  final num? price;
  final String? priceLabel;
  final String? pricePeriod;
  final num? pricePerSqft;
  final bool verified;
  final String? city;
  final String? locality;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? bedrooms;
  final String? bathrooms;
  final num? size;
  final String? sizeUnit;
  final num? carpetArea;
  final String? furnishing;
  final List<String> amenities;
  final List<String> tags;
  final String? image;
  final List<String> images;
  final String? url;

  AiPropertyCard({
    required this.id,
    required this.title,
    this.projectName,
    this.description,
    this.category,
    this.transactionType,
    this.price,
    this.priceLabel,
    this.pricePeriod,
    this.pricePerSqft,
    this.verified = true,
    this.city,
    this.locality,
    this.address,
    this.latitude,
    this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.size,
    this.sizeUnit,
    this.carpetArea,
    this.furnishing,
    this.amenities = const [],
    this.tags = const [],
    this.image,
    this.images = const [],
    this.url,
  });

  factory AiPropertyCard.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    List<String> parseImageList(dynamic val) {
      if (val is List) {
        final List<String> res = [];
        for (final e in val) {
          if (e is String && e.trim().isNotEmpty && e.trim().toLowerCase() != 'null') {
            res.add(e.trim());
          } else if (e is Map) {
            final u = (e['secure_url'] ?? e['url'] ?? e['imageUrl'] ?? e['image'] ?? e['path'])?.toString();
            if (u != null && u.trim().isNotEmpty && u.trim().toLowerCase() != 'null') {
              res.add(u.trim());
            }
          }
        }
        return res;
      }
      return [];
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    num? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val;
      return num.tryParse(val.toString());
    }

    String? parseFurnishing(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        if (val.contains("'status': '") || val.contains('"status": "')) {
          final match = RegExp(r'''['"]status['"]\s*:\s*['"]([^'"]+)['"]''').firstMatch(val);
          if (match != null) return match.group(1);
        }
        return val;
      }
      if (val is Map) {
        return val['status']?.toString();
      }
      return val.toString();
    }

    return AiPropertyCard(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Property',
      projectName: json['project_name']?.toString(),
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      transactionType: json['transaction_type']?.toString(),
      price: parseNum(json['price']),
      priceLabel: json['price_label']?.toString(),
      pricePeriod: json['price_period']?.toString() ?? '',
      pricePerSqft: parseNum(json['price_per_sqft']),
      verified: json['verified'] == true,
      city: json['city']?.toString(),
      locality: json['locality']?.toString(),
      address: json['address']?.toString(),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      bedrooms: json['bedrooms']?.toString(),
      bathrooms: json['bathrooms']?.toString(),
      size: parseNum(json['size']),
      sizeUnit: json['size_unit']?.toString() ?? 'sqft',
      carpetArea: parseNum(json['carpet_area']),
      furnishing: parseFurnishing(json['furnishing']),
      amenities: parseList(json['amenities']),
      tags: parseList(json['tags']),
      image: (json['image'] ?? json['imageUrl'] ?? json['coverImage'])?.toString(),
      images: parseImageList(json['images'] ?? json['photos'] ?? json['gallery']),
      url: json['url']?.toString(),
    );
  }

  String get formattedPrice {
    if (priceLabel != null && priceLabel!.isNotEmpty) {
      return '$priceLabel$pricePeriod';
    }
    if (price != null && price! > 0) {
      if (price! >= 10000000) {
        return '₹${(price! / 10000000).toStringAsFixed(2)} Cr$pricePeriod';
      } else if (price! >= 100000) {
        return '₹${(price! / 100000).toStringAsFixed(2)} L$pricePeriod';
      } else if (price! >= 1000) {
        return '₹${(price! / 1000).toStringAsFixed(0)}K$pricePeriod';
      }
      return '₹$price$pricePeriod';
    }
    return 'Price on Request';
  }

  String get formattedLocation {
    final parts = [locality, city].where((p) => p != null && p.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (address != null && address!.trim().isNotEmpty) return address!;
    return '';
  }
}

class AiSource {
  final String? title;
  final String? url;
  final String? snippet;

  AiSource({this.title, this.url, this.snippet});

  factory AiSource.fromJson(Map<String, dynamic> json) {
    return AiSource(
      title: json['title']?.toString(),
      url: json['url']?.toString(),
      snippet: json['snippet']?.toString(),
    );
  }
}

class AiChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<AiPropertyCard> properties;
  final List<AiSource> sources;
  final DateTime timestamp;
  final bool isError;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.properties = const [],
    this.sources = const [],
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}

class PropertySnapshotData {
  final String propertyId;
  final String title;
  final String? locality;
  final String? city;
  final String? priceLabel;
  final String? transactionType;
  final Map<String, dynamic>? priceComparison;
  final Map<String, dynamic>? rentalYield;
  final Map<String, dynamic>? localityTrend;
  final Map<String, dynamic>? dataConfidence;
  final List<dynamic>? calculation;
  final String? disclaimer;
  final String? updatedOn;
  final num? radiusKm;

  PropertySnapshotData({
    required this.propertyId,
    required this.title,
    this.locality,
    this.city,
    this.priceLabel,
    this.transactionType,
    this.priceComparison,
    this.rentalYield,
    this.localityTrend,
    this.dataConfidence,
    this.calculation,
    this.disclaimer,
    this.updatedOn,
    this.radiusKm,
  });

  factory PropertySnapshotData.fromJson(Map<String, dynamic> json) {
    return PropertySnapshotData(
      propertyId: json['property_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Property Details',
      locality: json['locality']?.toString(),
      city: json['city']?.toString(),
      priceLabel: json['price_label']?.toString(),
      transactionType: json['transaction_type']?.toString(),
      priceComparison: json['price_comparison'] is Map ? Map<String, dynamic>.from(json['price_comparison']) : null,
      rentalYield: json['rental_yield'] is Map ? Map<String, dynamic>.from(json['rental_yield']) : null,
      localityTrend: json['locality_trend'] is Map ? Map<String, dynamic>.from(json['locality_trend']) : null,
      dataConfidence: json['data_confidence'] is Map ? Map<String, dynamic>.from(json['data_confidence']) : null,
      calculation: json['calculation'] is List ? json['calculation'] : null,
      disclaimer: json['disclaimer']?.toString(),
      updatedOn: json['updated_on']?.toString(),
      radiusKm: json['radius_km'] is num ? json['radius_km'] : null,
    );
  }
}
