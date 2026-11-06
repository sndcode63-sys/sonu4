/// Builds a fully-validated Mongoose-compatible JSON payload for DigiNiwas property CRUD APIs:
/// - Residential Rent: POST /rental-properties
/// - Commercial Rent: POST /commercial-rental-properties
/// - Residential Sell: POST /residential-sale
/// - Commercial Sell: POST /commercial-sale
class PropertyPayloadBuilder {
  PropertyPayloadBuilder._();

  static Map<String, dynamic> build(Map<String, dynamic> rawFields) {
    final rawPurpose = (rawFields['transactionType'] ?? rawFields['purpose'] ?? rawFields['type'] ?? '').toString().toLowerCase();
    final isRent = rawPurpose.contains('rent');

    final rawCat = (rawFields['category'] ?? rawFields['propertyCategory'] ?? rawFields['buildingType'] ?? '').toString().toLowerCase();
    final isCommercial = rawCat.contains('commercial');

    final buildingType = isCommercial ? 'Commercial' : 'Residential';

    // Category enum per DigiNiwas contract:
    // Residential Rent: "Rent"
    // Commercial Rent: "Commercial"
    // Residential Sell: "Sell"
    // Commercial Sell: "Sell"
    final String categoryEnum = isRent ? (isCommercial ? 'Commercial' : 'Rent') : 'Sell';
    final String listingType = isRent ? 'Rent' : 'Sell';
    final String transactionType = isRent ? 'Rent' : 'Resale';

    // Property Type
    String propertyType = (rawFields['propertyType'] ?? 'Apartment').toString().trim();
    if (isCommercial) {
      final ptLower = propertyType.toLowerCase();
      if (ptLower.contains('shop')) {
        propertyType = 'Shop';
      } else if (ptLower.contains('showroom')) {
        propertyType = 'Showroom';
      } else if (ptLower.contains('warehouse')) {
        propertyType = 'Warehouse';
      } else if (ptLower.contains('plot') || ptLower.contains('land')) {
        propertyType = 'Land';
      } else if (ptLower.contains('co-working') || ptLower.contains('coworking')) {
        propertyType = 'Co-working Space';
      } else if (ptLower.contains('industrial')) {
        propertyType = 'Industrial Plot';
      } else {
        propertyType = 'Office Space';
      }
    } else {
      final ptLower = propertyType.toLowerCase();
      if (ptLower.contains('villa')) {
        propertyType = 'Villa';
      } else if (ptLower.contains('builder')) {
        propertyType = 'Builder Floor';
      } else if (ptLower.contains('penthouse')) {
        propertyType = 'Penthouse';
      } else if (ptLower.contains('house')) {
        propertyType = 'Independent House';
      } else if (ptLower.contains('plot') || ptLower.contains('land')) {
        propertyType = 'Plot';
      } else {
        propertyType = 'Apartment';
      }
    }

    // BHK (required for Residential models)
    String rawBhk = (rawFields['bedrooms'] ?? rawFields['bhk'] ?? '').toString().trim();
    String bhk = '2 BHK';
    if (rawBhk.isNotEmpty) {
      if (rawBhk.toUpperCase().contains('BHK') || rawBhk.toUpperCase().contains('RK') || rawBhk.toUpperCase().contains('STUDIO')) {
        bhk = rawBhk;
      } else {
        final numOnly = rawBhk.replaceAll(RegExp(r'[^0-9]'), '');
        bhk = numOnly.isNotEmpty ? '$numOnly BHK' : '2 BHK';
      }
    } else {
      bhk = '1 BHK';
    }

    // Area Details
    final areaVal = double.tryParse(rawFields['propertySize']?.toString() ?? '') ??
        double.tryParse(rawFields['carpetArea']?.toString() ?? '') ??
        double.tryParse(rawFields['superBuiltupArea']?.toString() ?? '') ??
        100.0;
    final rawUnit = (rawFields['sizeUnit'] ?? 'sqft').toString().toLowerCase();
    String unitName = 'Sq. Ft.';
    if (rawUnit.contains('yd') || rawUnit.contains('yard')) {
      unitName = 'Sq. Yard';
    } else if (rawUnit.contains('m') || rawUnit.contains('meter')) {
      unitName = 'Sq. Meter';
    } else if (rawUnit.contains('acre')) {
      unitName = 'Acre';
    } else if (rawUnit.contains('hect')) {
      unitName = 'Hectare';
    }

    final rawAreaType = (rawFields['areaType'] ?? 'Built-up Area').toString();
    final areaType = rawAreaType.isNotEmpty ? rawAreaType : 'Built-up Area';

    final areaDetails = [
      {
        'value': areaVal > 0 ? areaVal : 100.0,
        'type': areaType,
        'unit': unitName,
        'display': true,
      }
    ];

    // Location
    final city = (rawFields['city'] ?? 'Indore').toString().trim();
    final locality = (rawFields['locality'] ?? 'City Center').toString().trim();
    final address = (rawFields['address'] ?? '$locality, $city').toString().trim();
    final pinCode = (rawFields['pinCode'] ?? rawFields['pincode'] ?? '452001').toString().trim();
    final state = (rawFields['state'] ?? 'Madhya Pradesh').toString().trim();
    final lat = double.tryParse(rawFields['latitude']?.toString() ?? '');
    final lng = double.tryParse(rawFields['longitude']?.toString() ?? '');

    final location = <String, dynamic>{
      'city': city.isNotEmpty ? city : 'Indore',
      'state': state.isNotEmpty ? state : 'Madhya Pradesh',
      'country': 'India',
      'locality': locality.isNotEmpty ? locality : (city.isNotEmpty ? city : 'City Center'),
      'society': (rawFields['projectName'] ?? rawFields['society'] ?? '').toString().trim(),
      'address': address.isNotEmpty ? address : '$locality, $city',
      'pinCode': pinCode.isNotEmpty ? pinCode : '452001',
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
      'isLocationConfirmed': true,
    };

    // Price / Rent
    final priceAmount = double.tryParse(rawFields['price']?.toString() ?? '') ??
        double.tryParse(rawFields['rent']?.toString() ?? '') ??
        10000.0;
    final effectivePrice = priceAmount > 0 ? priceAmount : 10000.0;

    final rentObj = {
      'amount': effectivePrice,
      'frequency': 'Per Month',
      'negotiable': true,
    };

    final pricePerSqFt = (areaVal > 0 && effectivePrice > 0) ? (effectivePrice / areaVal).roundToDouble() : 1000.0;
    final priceObj = {
      'amount': effectivePrice,
      'unit': rawFields['pricingModel']?.toString() == 'Price Per Sq. Ft.' ? 'Price Per Sq. Ft.' : 'Total Price',
      'pricePerSqFt': pricePerSqFt,
      'negotiable': true,
    };

    final securityDepositObj = {
      'type': 'Two Months',
      'amount': effectivePrice * 2,
      'description': '',
    };

    final maintenanceObj = {
      'amount': double.tryParse(rawFields['maintenanceAmount']?.toString() ?? '') ?? 0.0,
      'frequency': (rawFields['maintenancePeriod'] ?? 'Monthly').toString(),
      'includedInRent': true,
    };

    // Availability
    final isLater = rawFields['availability']?.toString().toLowerCase() == 'later';
    final availabilityObj = {
      'availableFrom': isLater ? 'Later' : 'Immediately',
      'availableDate': isLater ? (rawFields['availableDate']?.toString()) : null,
    };

    // Furnishing: Furnished | Semi-Furnished | Unfurnished
    String rawFurnishing = '';
    dynamic rawFurnishingItemsInput;

    if (rawFields['furnishing'] is Map) {
      final fMap = rawFields['furnishing'] as Map;
      rawFurnishing = (fMap['status'] ?? fMap['furnishingStatus'] ?? '').toString();
      rawFurnishingItemsInput = fMap['items'];
    } else {
      rawFurnishing = (rawFields['furnishing'] ?? rawFields['furnishingStatus'] ?? 'Unfurnished').toString();
    }

    String furnishingStatus = 'Unfurnished';
    final lowerFurnish = rawFurnishing.toLowerCase();
    if (lowerFurnish.contains('semi')) {
      furnishingStatus = 'Semi-Furnished';
    } else if (lowerFurnish.contains('unfurnished')) {
      furnishingStatus = 'Unfurnished';
    } else if (lowerFurnish.contains('furnish')) {
      furnishingStatus = 'Furnished';
    } else {
      furnishingStatus = 'Unfurnished';
    }

    final List<Map<String, dynamic>> furnishingItems = [];

    void addCleanItem(dynamic rawItem, [int defaultQty = 1]) {
      if (rawItem == null) return;
      String name = '';
      int quantity = defaultQty;

      if (rawItem is Map) {
        name = (rawItem['name'] ?? rawItem['title'] ?? rawItem['item'] ?? '').toString().trim();
        quantity = int.tryParse(rawItem['quantity']?.toString() ?? rawItem['qty']?.toString() ?? '') ?? defaultQty;
      } else {
        name = rawItem.toString().trim();
      }

      if (name.isEmpty) return;

      // Extract trailing quantity if name is formatted like "Split AC (1)" or "Geyser (2)"
      final match = RegExp(r'^(.*?)(?:\s*\(\s*(\d+)\s*\))?$').firstMatch(name);
      if (match != null) {
        final cleanName = match.group(1)?.trim() ?? name;
        final parenQty = match.group(2) != null ? int.tryParse(match.group(2)!) : null;
        if (cleanName.isNotEmpty) {
          name = cleanName;
          if (parenQty != null && parenQty > 0) {
            quantity = parenQty;
          }
        }
      }

      if (name.isNotEmpty && quantity > 0) {
        final existingIdx = furnishingItems.indexWhere((it) => it['name'].toString().toLowerCase() == name.toLowerCase());
        if (existingIdx >= 0) {
          furnishingItems[existingIdx]['quantity'] = (furnishingItems[existingIdx]['quantity'] as int) + quantity;
        } else {
          furnishingItems.add({
            'name': name,
            'quantity': quantity,
          });
        }
      }
    }

    if (furnishingStatus != 'Unfurnished') {
      final explicitItems = rawFields['furnishingItems'] ?? rawFurnishingItemsInput;

      if (explicitItems is List && explicitItems.isNotEmpty) {
        for (final item in explicitItems) {
          addCleanItem(item);
        }
      } else if (explicitItems is Map && explicitItems.isNotEmpty) {
        explicitItems.forEach((k, v) {
          final qty = int.tryParse(v?.toString() ?? '') ?? 0;
          if (qty > 0) {
            addCleanItem(k.toString(), qty);
          }
        });
      } else if (rawFields['furnishingQuantities'] is Map) {
        (rawFields['furnishingQuantities'] as Map).forEach((k, v) {
          final qty = int.tryParse(v?.toString() ?? '') ?? 0;
          if (qty > 0) {
            addCleanItem(k.toString(), qty);
          }
        });
      }

      if (furnishingItems.isEmpty) {
        final rawInventory = rawFields['furnishingInventory'];
        if (rawInventory is String && rawInventory.isNotEmpty) {
          for (final item in rawInventory.split(',')) {
            final trimmed = item.trim();
            if (trimmed.isNotEmpty) {
              addCleanItem(trimmed);
            }
          }
        } else if (rawInventory is List) {
          for (final item in rawInventory) {
            addCleanItem(item);
          }
        }
      }
    }

    final furnishingObj = {
      'status': furnishingStatus,
      'count': furnishingItems.length,
      'items': furnishingItems,
    };

    // Specifications
    int bathrooms = int.tryParse(rawFields['bathrooms']?.toString().replaceAll('+', '') ?? '') ?? 1;
    if (bathrooms <= 0) bathrooms = 1;
    int balconies = int.tryParse(rawFields['balconies']?.toString().replaceAll('+', '') ?? '') ?? 0;
    int floor = int.tryParse(rawFields['floor']?.toString() ?? '') ?? 1;
    if (floor <= 0) floor = 1;
    int totalFloors = int.tryParse(rawFields['totalFloors']?.toString() ?? '') ?? 1;
    if (totalFloors < floor) totalFloors = floor;

    final facing = (rawFields['facingDirection'] ?? rawFields['facing'] ?? 'North').toString();
    final view = (rawFields['viewProfile'] ?? rawFields['view'] ?? 'Park View').toString();
    final flooring = (rawFields['flooringType'] ?? rawFields['flooring'] ?? 'Vitrified Tiles').toString();

    final waterSources = <String>[];
    final rawWater = rawFields['waterSupply'] ?? rawFields['waterSources'];
    if (rawWater is String && rawWater.isNotEmpty) {
      waterSources.addAll(rawWater.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    } else if (rawWater is List) {
      waterSources.addAll(rawWater.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
    }
    if (waterSources.isEmpty) waterSources.add('Municipal Supply');

    final specificationsObj = {
      'bathrooms': bathrooms,
      'coveredParking': rawFields['parking']?.toString().toLowerCase().contains('none') == true ? 0 : 1,
      'openParking': 0,
      'powerBackup': true,
      'waterSources': waterSources,
      'liftAvailable': true,
      'locationAdvantages': <String>[],
      'balconies': balconies,
      'facing': facing,
      'view': view,
      'flooring': flooring,
      'connectingRoadWidth': {'value': 30, 'unit': 'Feet'},
      'totalFloorCount': totalFloors,
      'propertyFloor': floor,
      'towerBlock': '',
      'unitNo': '',
      'keepUnitNoPrivate': false,
    };

    // Amenities: array of valid Mongoose enum strings
    final List<String> cleanAmenities = [];
    final rawAmenities = rawFields['amenities'];
    List<String> userAmenityList = [];
    if (rawAmenities is String && rawAmenities.isNotEmpty) {
      userAmenityList = rawAmenities.split(',').map((e) => e.trim()).toList();
    } else if (rawAmenities is List) {
      userAmenityList = rawAmenities.map((e) => e.toString().trim()).toList();
    }

    for (final userA in userAmenityList) {
      final lower = userA.toLowerCase();
      if (lower.contains('security') || lower.contains('cctv')) {
        cleanAmenities.add('24 x 7 Security');
      } else if (lower.contains('lift') || lower.contains('elevator')) {
        cleanAmenities.add('High Speed Elevators');
      } else if (lower.contains('pool') && !isCommercial) {
        cleanAmenities.add('Swimming Pool');
      } else if (lower.contains('gym')) {
        cleanAmenities.add('Gymnasium');
      } else if ((lower.contains('park') || lower.contains('garden') || lower.contains('landscape')) && !isCommercial) {
        cleanAmenities.add('Central Park');
      } else if (lower.contains('club') && !isCommercial) {
        cleanAmenities.add('Club House');
      } else if (lower.contains('power') || lower.contains('backup')) {
        cleanAmenities.add('Power Backup');
      } else if (lower.contains('parking')) {
        cleanAmenities.add('Reserved Parking');
      } else if (lower.contains('fire')) {
        cleanAmenities.add('Fire Fighting System');
      } else if (lower.contains('gated') && !isCommercial) {
        cleanAmenities.add('Gated Community');
      } else if (lower.contains('pet') && !isCommercial) {
        cleanAmenities.add('Pet Friendly');
      } else if (lower.contains('smart') && !isCommercial) {
        cleanAmenities.add('Smart Home');
      }
    }
    if (cleanAmenities.isEmpty) {
      cleanAmenities.add('24 x 7 Security');
    }
    final uniqueAmenities = cleanAmenities.toSet().toList();

    // Descriptions & Titles
    String title = (rawFields['title'] ?? '').toString().trim();
    if (title.isEmpty) title = '$bhk $propertyType in $locality';

    String oneLineDesc = (rawFields['oneLineDescription'] ?? '').toString().trim();
    if (oneLineDesc.isEmpty) {
      oneLineDesc = '$bhk $propertyType for $listingType in $locality, $city';
    }

    String description = (rawFields['description'] ?? '').toString().trim();
    if (description.isEmpty) {
      description = '$bhk $propertyType for $listingType in $locality, $city. Prime property with modern amenities.';
    }
    if (description.length < 25) {
      description = '$description - Verified property listing on DigiNiwas platform.';
    }

    final possessionStatus = rawFields['possessionStatus']?.toString().toLowerCase().contains('under') == true
        ? 'Under Construction'
        : 'Ready To Move';

    String ageOfProp = (rawFields['ageOfProperty'] ?? '0-1').toString();
    if (ageOfProp.contains('New') || ageOfProp.contains('Never')) {
      ageOfProp = 'Never Occupied';
    } else if (ageOfProp.contains('10+')) {
      ageOfProp = '10+';
    } else if (ageOfProp.contains('8-10')) {
      ageOfProp = '8-10';
    } else if (ageOfProp.contains('5-7')) {
      ageOfProp = '5-7';
    } else if (ageOfProp.contains('2-4')) {
      ageOfProp = '2-4';
    } else if (ageOfProp.contains('0-1')) {
      ageOfProp = '0-1';
    } else {
      ageOfProp = '0-1';
    }

    String ownership = (rawFields['ownershipTitle'] ?? rawFields['ownershipType'] ?? 'Free Hold').toString();
    if (ownership.toLowerCase().contains('lease')) {
      ownership = 'Leasehold';
    } else if (ownership.toLowerCase().contains('attorney') || ownership.toLowerCase().contains('power')) {
      ownership = 'Power of Attorney';
    } else {
      ownership = 'Free Hold';
    }

    final structured = <String, dynamic>{
      'title': title,
      'category': categoryEnum,
      'listingType': listingType,
      'transactionType': transactionType,
      'buildingType': buildingType,
      'propertyType': propertyType,
      'status': 'Submitted',
      'location': location,
      if (isRent) 'rent': rentObj else 'price': priceObj,
      if (isRent) 'securityDeposit': securityDepositObj,
      if (isRent) 'maintenance': maintenanceObj,
      if (!isCommercial) 'bhk': bhk,
      'areaDetails': areaDetails,
      'availability': availabilityObj,
      'furnishing': furnishingObj,
      'specifications': specificationsObj,
      'amenities': uniqueAmenities,
      if (rawFields['propertyHighlights'] is List && (rawFields['propertyHighlights'] as List).isNotEmpty)
        'propertyHighlights': (rawFields['propertyHighlights'] as List)
            .map((e) => e.toString().trim())
            .where((h) => !(isCommercial && h.toLowerCase().contains('smart')))
            .where((h) => h.isNotEmpty)
            .toList(),
      'oneLineDescription': oneLineDesc,
      'description': description,
      'possessionStatus': possessionStatus,
      'ageOfProperty': ageOfProp,
      'ownershipType': ownership,
      if (rawFields['userId'] != null) 'userId': rawFields['userId'],
      if (rawFields['sellerId'] != null) 'sellerId': rawFields['sellerId'],
      if (rawFields['ownerId'] != null) 'ownerId': rawFields['ownerId'],
      if (rawFields['createdBy'] != null) 'createdBy': rawFields['createdBy'],
      if (rawFields['creatorId'] != null) 'creatorId': rawFields['creatorId'],
      if (rawFields['creatorRole'] != null) 'creatorRole': rawFields['creatorRole'],
      if (rawFields['partnerId'] != null) 'partnerId': rawFields['partnerId'],
      if (rawFields['creatorName'] != null) 'creatorName': rawFields['creatorName'],
      if (rawFields['creatorEmail'] != null) 'creatorEmail': rawFields['creatorEmail'],
      if (rawFields['creatorPhone'] != null) 'creatorPhone': rawFields['creatorPhone'],
    };

    return structured;
  }
}
