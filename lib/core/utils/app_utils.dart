String formatPrice(dynamic priceValue) {
  if (priceValue == null) return 'N/A';

  // If price is passed as a Map: {"amount": 20000000, "unit": "Total Price"}
  if (priceValue is Map) {
    final amount = priceValue['amount'] ?? priceValue['price'] ?? priceValue['value'];
    if (amount == null) return 'Price on Request';
    priceValue = amount;
  }

  // Agar price pehle se string hai aur usme 'L' ya '₹' hai toh waise hi return kar do
  String priceStr = priceValue.toString().trim();
  if (priceStr.isEmpty || priceStr == 'null') return 'N/A';
  if (priceStr.contains('L') || priceStr.contains('Cr') || priceStr.contains('₹')) {
    return priceStr;
  }

  // Number mein convert karke Lakh / Crore mein format karna
  double? price = double.tryParse(priceStr);
  if (price == null) return priceStr;
  if (price <= 0) return 'Price on Request';

  if (price >= 10000000) {
    double cr = price / 10000000;
    return '₹ ${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)} Cr';
  } else if (price >= 100000) {
    double lakh = price / 100000;
    return '₹ ${lakh % 1 == 0 ? lakh.toInt() : lakh.toStringAsFixed(1)} L';
  } else if (price >= 1000) {
    double thousand = price / 1000;
    return '₹ ${thousand % 1 == 0 ? thousand.toInt() : thousand.toStringAsFixed(1)} K';
  }

  return '₹ ${price % 1 == 0 ? price.toInt() : price.toStringAsFixed(0)}';
}

String formatPropertyLocation({
  String? locality,
  String? city,
  String? address,
  dynamic distanceKm,
  bool? sameCity,
  String fallback = 'Prime Location',
}) {
  final hasLoc = locality != null && locality.trim().isNotEmpty && locality.trim() != 'null';
  final hasCity = city != null && city.trim().isNotEmpty && city.trim() != 'null';

  if (hasLoc && hasCity) {
    if (locality.trim().toLowerCase() == city.trim().toLowerCase()) {
      return city.trim();
    }
    return '${locality.trim()}, ${city.trim()}';
  } else if (hasLoc) {
    return locality.trim();
  } else if (hasCity) {
    return city.trim();
  }

  if (address != null && address.trim().isNotEmpty && address.trim() != 'null') {
    return address.trim();
  }

  if (distanceKm != null) {
    final d = num.tryParse(distanceKm.toString());
    if (d != null) {
      return '${d.toStringAsFixed(1)} km away';
    }
  }

  if (sameCity == true) {
    return 'Nearby';
  }

  return fallback;
}

String formatBedrooms(dynamic bedrooms, {String? category, dynamic bathrooms}) {
  final cat = category?.toString().trim();
  if (cat != null && (cat.toLowerCase().contains('commercial') || cat.toLowerCase().contains('office') || cat.toLowerCase().contains('shop'))) {
    return 'Commercial';
  }
  if (cat != null && (cat.toLowerCase().contains('plot') || cat.toLowerCase().contains('land'))) {
    return 'Plot / Land';
  }

  final bStr = bedrooms?.toString().trim();
  if (bStr != null && bStr.isNotEmpty && bStr != 'null' && bStr != '0') {
    return '$bStr BHK';
  }

  final bathStr = bathrooms?.toString().trim();
  if (bathStr != null && bathStr.isNotEmpty && bathStr != 'null' && bathStr != '0') {
    return '$bathStr Bath';
  }

  if (cat != null && cat.isNotEmpty && cat != 'null') {
    return cat;
  }

  return 'Residential';
}

String formatFurnishing(dynamic furnishing, {String fallback = 'Ready to Move'}) {
  if (furnishing == null) return fallback;
  if (furnishing is Map) {
    final status = furnishing['status'] ?? furnishing['name'];
    if (status != null && status.toString().trim().isNotEmpty && status.toString() != 'null') {
      return status.toString().trim();
    }
  }
  final str = furnishing.toString().trim();
  if (str.isEmpty || str == 'null') return fallback;
  return str;
}

