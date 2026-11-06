import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_dotted_border.dart';
import '../../../core/widgets/app_toast.dart';
import '../../partner/controllers/partner_home_controller.dart';
import '../controllers/seller_controller.dart';
import 'map_picker_screen.dart';

// ============================================================================
// DATA MODELS FOR ADD PROPERTY FLOW
// ============================================================================

class AreaDetailRow {
  final TextEditingController sizeCtrl;
  String unit;
  String type;
  bool isPrimary;

  AreaDetailRow({
    String size = '',
    this.unit = 'Sq. Ft.',
    this.type = 'Built-up Area',
    this.isPrimary = false,
  }) : sizeCtrl = TextEditingController(text: size);

  void dispose() {
    sizeCtrl.dispose();
  }

  Map<String, dynamic> toJson() => {
        'size': sizeCtrl.text.trim(),
        'unit': unit,
        'type': type,
        'isPrimary': isPrimary,
      };
}

class CustomFurnishingItem {
  final String name;
  int quantity;
  CustomFurnishingItem(this.name, this.quantity);

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};
}

// ============================================================================
// MAIN WIDGET: ADD PROPERTY FLOW SCREEN (SELLER & AGENT COMPATIBLE)
// ============================================================================

class AddPropertyFlowScreen extends StatefulWidget {
  const AddPropertyFlowScreen({super.key});

  @override
  State<AddPropertyFlowScreen> createState() => _AddPropertyFlowScreenState();
}

class _AddPropertyFlowScreenState extends State<AddPropertyFlowScreen> {
  // ---- Colors & Theme ------------------------------------------------------
  static const Color _green = Color(0xFF0B7A4B);
  static const Color _greenLight = Color(0xFFEAF7F1);
  static const Color _navy = Color(0xFF0F2544);
  static const Color _grey = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgGrey = Color(0xFFF8FAFC);

  static const int _totalSteps = 6; // 0..5, 6 = success
  int _currentStep = 0;

  late final SellerController _controller;
  final ImagePicker _imagePicker = ImagePicker();

  // Role resolution
  bool _isPartnerFlow = false;
  bool _isEditingActive = false;
  String? _assignedPropertyId;

  // ==========================================================================
  // SECTION 1: PROPERTY CLASSIFICATION
  // ==========================================================================
  String _listingType = 'Sale'; // 'Sale' | 'Rent'
  String _buildingType = 'Residential'; // 'Residential' | 'Commercial'
  String _selectedPropertyType = 'Apartment';

  static const List<String> _residentialTypes = [
    'Apartment',
    'Villa',
    'Plot',
    'Builder Floor',
    'Penthouse',
    'Independent House',
  ];

  static const List<String> _commercialTypes = [
    'Office',
    'Retail / Shop',
    'Showroom',
    'Warehouse',
    'Commercial Land',
  ];

  bool get _isPlot => _selectedPropertyType.toLowerCase().contains('plot') || _selectedPropertyType.toLowerCase().contains('land');
  bool get _isPG => _selectedPropertyType == 'PG';

  // PG Specific Fields
  String _pgAvailableFor = 'All'; // 'Girls' | 'Boys' | 'All'
  static const List<String> _pgAvailableForOptions = ['Girls', 'Boys', 'All'];

  String _pgRoomType = 'Private Room'; // 'Private Room' | 'Twin Sharing' | 'Triple Sharing' | 'Quad Sharing'
  static const List<String> _pgRoomTypeOptions = ['Private Room', 'Twin Sharing', 'Triple Sharing', 'Quad Sharing'];

  String _pgFoodCharges = 'No'; // 'Yes' | 'No'
  static const List<String> _pgFoodChargesOptions = ['Yes', 'No'];

  // ==========================================================================
  // SECTION 2: LOCATION & PROJECT
  // ==========================================================================
  final List<String> _cityOptions = [
    'Ambala', 'Indore', 'Bhopal', 'Ahmedabad', 'Surat', 'Mumbai', 'Pune',
    'Delhi NCR', 'Bengaluru', 'Hyderabad', 'Jaipur', 'Lucknow', 'Chandigarh',
    'Kolkata', 'Chennai', 'Nagpur', 'Vadodara', 'Gurugram', 'Noida',
  ];
  String _city = 'Ambala';
  final TextEditingController _localityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  bool _isGeocoding = false;
  double? _latitude;
  double? _longitude;

  static const List<String> _commonLocalitySuggestions = [
    'Sector 9', 'Sector 14', 'Sector 21', 'DLF Phase 1', 'DLF Phase 2',
    'Green Park', 'Model Town', 'Civil Lines', 'Cyber City', 'Golf Course Road',
    'Hiranandani Estate', 'Whitefield', 'Indiranagar', 'Koramangala',
    'Banjara Hills', 'Jubilee Hills', 'Malviya Nagar', 'Mansarovar',
    'Gomti Nagar', 'Aliganj', 'Super Corridor', 'SG Highway', 'Vesu',
  ];
  List<String> _matchedLocalities = [];

  // ==========================================================================
  // SECTION 3: PRICING & FINANCIALS
  // ==========================================================================
  final TextEditingController _priceCtrl = TextEditingController();
  String _priceBasis = 'All Inclusive'; // 'All Inclusive' | 'Base Price'
  String _priceUnit = '₹'; // '₹' | 'L' | 'Cr'

  // Price Advantages (Multi-select)
  static const List<String> _priceAdvantagesList = [
    'Affordable Price',
    'Urgent Sale',
    'Below Market Value',
    'Negotiable Price',
    'Best Price in Locality',
    'Quick Deal Preferred',
    'Distress Sale',
  ];
  final Set<String> _selectedPriceAdvantages = {};

  // Rental specific
  String _rentalPaymentFrequency = 'Per Month';
  final TextEditingController _maintenanceCtrl = TextEditingController();
  String _maintenanceBasis = 'Per Sq. Ft.';
  static const List<String> _maintenanceBasisOptions = ['Per Sq. Ft.', 'Per Month'];
  bool _maintenanceIncludedInPrice = false;

  // Security Deposit
  static const List<String> _securityDepositOptions = ['Zero Deposit', 'One Month', 'Two Months', 'Other'];
  String _securityDepositType = 'Zero Deposit';
  final TextEditingController _customDepositCtrl = TextEditingController();

  // Availability & Possession
  String _possessionStatus = 'Ready to Move'; // 'Ready to Move' | 'Under Construction'
  static const List<String> _possessionStatuses = ['Ready to Move', 'Under Construction'];

  String _saleTransactionType = 'Resale'; // 'Resale' | 'New Booking'
  static const List<String> _saleTransactionTypes = ['Resale', 'New Booking'];

  String _ownershipType = 'Free Hold'; // 'Free Hold' | 'Leasehold' | 'Power of Attorney'
  static const List<String> _ownershipTypes = ['Free Hold', 'Leasehold', 'Power of Attorney'];

  String _availableFrom = 'Immediately'; // 'Immediately' | 'Later'
  DateTime? _availableDate;

  // Suited For (Rent / PG)
  static const List<String> _suitedForList = ['Students', 'Working Professionals', 'Any'];
  final Set<String> _selectedSuitedFor = {};

  // ==========================================================================
  // SECTION 4: CONFIGURATION, AREA & SPACES
  // ==========================================================================
  String _selectedBhk = '2 BHK';
  static const List<String> _bhkList = [
    'Studio', '1 RK', '1 BHK', '1.5 BHK', '2 BHK', '2.5 BHK',
    '3 BHK', '3.5 BHK', '4 BHK', '5 BHK', '6 BHK', '6+ BHK',
  ];

  String _bathrooms = '2';
  String _balconies = '1';
  String _floor = '1';
  final TextEditingController _totalFloorsCtrl = TextEditingController();

  // Dynamic Area Details
  final List<AreaDetailRow> _areaRows = [];
  static const List<String> _areaUnits = ['Sq. Ft.', 'Sq. Yd.', 'Sq. M.', 'Acre', 'Hectare'];
  static const List<String> _areaTypes = ['Built-up Area', 'Plot Area', 'Carpet Area', 'Super Built-up Area'];

  // Additional Spaces
  static const List<String> _additionalSpacesList = [
    'Prayer Room',
    'Servant Room',
    'Study Room',
    'Extra Room',
    'Basement',
    'Store Room',
    'Private Garden',
    'Private Pool',
    'Terrace',
  ];
  final Set<String> _selectedAdditionalSpaces = {};

  // Furnishing Status & Items
  String _furnishing = 'Semi-Furnished'; // 'Furnished' | 'Semi-Furnished' | 'Unfurnished'
  static const List<String> _furnishingStatuses = ['Furnished', 'Semi-Furnished', 'Unfurnished'];

  static const List<String> _furnishingItemsList = [
    'Water Purifier', 'Fan', 'Fridge', 'Exhaust Fan', 'Dining Table',
    'Geyser', 'Stove', 'Light', 'Curtains', 'Modular Kitchen',
    'TV', 'Chimney', 'AC', 'Bed', 'Wardrobe',
    'Sofa', 'Washing Machine', 'Microwave', 'Home Automation',
    'Smart Card Access', 'Solar Heater', 'Split AC', 'VRV AC',
  ];
  final Map<String, int> _furnishingQuantities = {};
  final List<CustomFurnishingItem> _customFurnishingItems = [];

  // ==========================================================================
  // SECTION 5: MEDIA & HIGHLIGHTS
  // ==========================================================================
  final List<File> _photos = [];
  File? _video;
  String? _videoName;

  // Documents (PDF & Image upload)
  final List<File> _documents = [];

  // Amenities (Category-specific enums)
  static const List<String> _residentialAmenities = [
    'Lift',
    'Power backup',
    'Security',
    'CCTV',
    'Gated community',
    'Gym',
    'Swimming pool',
    'Garden / Landscape',
    'Visitor parking',
    'EV charging',
  ];

  static const List<String> _commercialAmenities = [
    'Lift',
    'Power backup',
    'Security',
    'CCTV',
    'Gym',
    'Visitor parking',
    'EV charging',
  ];

  List<String> get _currentDefaultAmenities =>
      _buildingType == 'Commercial' ? _commercialAmenities : _residentialAmenities;

  final Set<String> _selectedAmenities = {};
  final TextEditingController _customAmenityCtrl = TextEditingController();

  // Indian States & UTs
  static const List<String> _indianStates = [
    'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam',
    'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
    'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh',
    'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
    'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  int _previewImageIndex = 0;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _reraCtrl = TextEditingController();
  bool _agreeTerms = true;
  Map<String, dynamic>? _createdProperty;

  // ==========================================================================
  // INIT & DISPOSE
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SellerController>()
        ? Get.find<SellerController>()
        : Get.put(SellerController());

    // Initialize first default area row
    _areaRows.add(AreaDetailRow(unit: 'Sq. Ft.', type: 'Built-up Area', isPrimary: true));

    // Initialize furnishing quantities to 0
    for (final item in _furnishingItemsList) {
      _furnishingQuantities[item] = 0;
    }

    _localityCtrl.addListener(_onLocalityChanged);

    _resolveFlowRoleAndArguments();
    _checkForExistingDraft();
  }

  @override
  void dispose() {
    _localityCtrl.removeListener(_onLocalityChanged);
    _localityCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _stateCtrl.dispose();
    _landmarkCtrl.dispose();
    _priceCtrl.dispose();
    _maintenanceCtrl.dispose();
    _customDepositCtrl.dispose();
    _totalFloorsCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _reraCtrl.dispose();
    _customAmenityCtrl.dispose();
    for (final row in _areaRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _onLocalityChanged() {
    final query = _localityCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      if (_matchedLocalities.isNotEmpty) setState(() => _matchedLocalities = []);
      return;
    }
    final matches = _commonLocalitySuggestions
        .where((loc) => loc.toLowerCase().contains(query))
        .take(5)
        .toList();
    setState(() => _matchedLocalities = matches);
  }

  Future<void> _resolveFlowRoleAndArguments() async {
    final route = Get.currentRoute;
    if (route == AppRoutes.agentAddProperty) {
      if (mounted) setState(() => _isPartnerFlow = true);
    } else if (route == AppRoutes.addProperty) {
      if (mounted) setState(() => _isPartnerFlow = false);
    }

    try {
      final raw = await SecureStorageService.instance.getUserData();
      if (raw != null && raw.isNotEmpty) {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final role = (map['role'] ?? map['accountType'] ?? '').toString().toLowerCase();
        if (mounted) {
          setState(() {
            _isPartnerFlow = (role == 'partner' || role == 'agent');
          });
        }
      }
    } catch (_) {}

    final args = Get.arguments;
    if (args is Map) {
      if (args['assignedPropertyId'] != null) {
        _assignedPropertyId = args['assignedPropertyId'].toString();
      }
      if (args['status'] == 'Active' || args['isEditing'] == true || args['isActive'] == true) {
        _isEditingActive = true;
      }
      if (args['title'] != null && args['title'].toString().isNotEmpty) {
        _titleCtrl.text = args['title'].toString();
      }
      if (args['city'] != null && args['city'].toString().isNotEmpty) {
        _city = args['city'].toString();
      }
      if (args['locality'] != null && args['locality'].toString().isNotEmpty) {
        _localityCtrl.text = args['locality'].toString();
      }
    }
  }

  // ==========================================================================
  // ACTIVE LISTING RESTRICTION RULE
  // ==========================================================================
  void _checkActiveEditRestriction(VoidCallback onAllowed) {
    if (_isEditingActive) {
      _showActiveListingRestrictionDialog();
    } else {
      onAllowed();
    }
  }

  void _showActiveListingRestrictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
              child: Icon(Icons.lock_rounded, color: Colors.amber.shade900, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Active Listing Rule',
                style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w700, color: _navy),
              ),
            ),
          ],
        ),
        content: Text(
          'Listing Type and Building Type cannot be changed for an active listing.',
          style: GoogleFonts.poppins(fontSize: 12.5.sp, color: _navy.withValues(alpha: 0.85), height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              'Continue Editing',
              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isEditingActive = false;
                _assignedPropertyId = null;
                _titleCtrl.clear();
                _priceCtrl.clear();
                _photos.clear();
                _video = null;
              });
              AppToast.showInfo('Started fresh new property listing.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              'Add New Property',
              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // COMPLETION PERCENTAGE CALCULATION
  // ==========================================================================
  int get _completionPercentage {
    int total = 10;
    int filled = 0;

    if (_listingType.isNotEmpty && _buildingType.isNotEmpty && _selectedPropertyType.isNotEmpty) filled++;
    if (_city.trim().isNotEmpty) filled++;
    if (_localityCtrl.text.trim().isNotEmpty) filled++;
    if (_addressCtrl.text.trim().isNotEmpty || _pincodeCtrl.text.trim().isNotEmpty) filled++;
    final p = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (p > 0) filled++;
    if (_areaRows.isNotEmpty && (double.tryParse(_areaRows.first.sizeCtrl.text.trim()) ?? 0) > 0) filled++;
    if (_isPlot || _selectedBhk.isNotEmpty) filled++;
    if (_isPlot || _furnishing.isNotEmpty) filled++;
    if (_photos.isNotEmpty) filled++;
    if (_listingType == 'Sale') {
      if (_possessionStatus.isNotEmpty && _ownershipType.isNotEmpty) filled++;
    } else {
      if (_securityDepositType.isNotEmpty) filled++;
    }

    return ((filled / total) * 100).round().clamp(0, 100);
  }

  // ==========================================================================
  // DRAFT PERSISTENCE
  // ==========================================================================
  Future<void> _saveDraft({bool showToast = false}) async {
    try {
      final draft = {
        'currentStep': _currentStep,
        'listingType': _listingType,
        'buildingType': _buildingType,
        'selectedPropertyType': _selectedPropertyType,
        'pgAvailableFor': _pgAvailableFor,
        'pgRoomType': _pgRoomType,
        'pgFoodCharges': _pgFoodCharges,
        'city': _city,
        'locality': _localityCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'landmark': _landmarkCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'priceBasis': _priceBasis,
        'priceUnit': _priceUnit,
        'priceAdvantages': _selectedPriceAdvantages.toList(),
        'rentalPaymentFrequency': _rentalPaymentFrequency,
        'maintenance': _maintenanceCtrl.text.trim(),
        'maintenanceBasis': _maintenanceBasis,
        'maintenanceIncludedInPrice': _maintenanceIncludedInPrice,
        'securityDepositType': _securityDepositType,
        'customDeposit': _customDepositCtrl.text.trim(),
        'possessionStatus': _possessionStatus,
        'saleTransactionType': _saleTransactionType,
        'ownershipType': _ownershipType,
        'availableFrom': _availableFrom,
        'availableDate': _availableDate?.toIso8601String(),
        'suitedFor': _selectedSuitedFor.toList(),
        'bhk': _selectedBhk,
        'bathrooms': _bathrooms,
        'balconies': _balconies,
        'floor': _floor,
        'totalFloors': _totalFloorsCtrl.text.trim(),
        'areaRows': _areaRows.map((r) => r.toJson()).toList(),
        'additionalSpaces': _selectedAdditionalSpaces.toList(),
        'amenities': _selectedAmenities.toList(),
        'furnishing': _furnishing,
        'furnishingQuantities': _furnishingQuantities,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'reraNumber': _reraCtrl.text.trim(),
      };
      await StorageService.instance.savePropertyDraft(draft);
      if (showToast && mounted) AppToast.showSuccess('Property draft saved successfully.');
    } catch (_) {}
  }

  Future<void> _checkForExistingDraft() async {
    final draft = await StorageService.instance.getPropertyDraft();
    if (draft == null || !mounted) return;

    final title = (draft['title'] ?? '').toString();
    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: EdgeInsets.all(20.r),
          child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: const BoxDecoration(color: _greenLight, shape: BoxShape.circle),
                    child: Icon(Icons.restore_page_rounded, color: _green, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Restore Saved Draft?',
                            style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _navy)),
                        Text(
                          title.isNotEmpty
                              ? 'Resume "$title"'
                              : 'You have an unsaved draft from your previous session.',
                          style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await StorageService.instance.clearPropertyDraft();
                        Get.back();
                        if (mounted) AppToast.showInfo('Draft discarded.');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('Discard',
                          style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _grey)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _restoreDraft(draft);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('Resume Draft',
                          style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    isDismissible: true,
  );
}

  void _restoreDraft(Map<String, dynamic> draft) {
    setState(() {
      _currentStep = (draft['currentStep'] as int? ?? 0).clamp(0, _totalSteps - 1);
      _listingType = draft['listingType']?.toString() ?? 'Sale';
      _buildingType = draft['buildingType']?.toString() ?? 'Residential';
      _selectedPropertyType = draft['selectedPropertyType']?.toString() ?? 'Apartment';
      _pgAvailableFor = draft['pgAvailableFor']?.toString() ?? 'All';
      _pgRoomType = draft['pgRoomType']?.toString() ?? 'Private Room';
      _pgFoodCharges = draft['pgFoodCharges']?.toString() ?? 'No';

      _city = draft['city']?.toString() ?? _city;
      _localityCtrl.text = draft['locality']?.toString() ?? '';
      _addressCtrl.text = draft['address']?.toString() ?? '';
      _pincodeCtrl.text = draft['pincode']?.toString() ?? '';
      _stateCtrl.text = draft['state']?.toString() ?? '';
      _landmarkCtrl.text = draft['landmark']?.toString() ?? '';

      _priceCtrl.text = draft['price']?.toString() ?? '';
      _priceBasis = draft['priceBasis']?.toString() ?? 'All Inclusive';
      _priceUnit = draft['priceUnit']?.toString() ?? '₹';
      if (draft['priceAdvantages'] is List) {
        _selectedPriceAdvantages.clear();
        _selectedPriceAdvantages.addAll(List<String>.from(draft['priceAdvantages'] as List));
      }

      _rentalPaymentFrequency = draft['rentalPaymentFrequency']?.toString() ?? 'Per Month';
      _maintenanceCtrl.text = draft['maintenance']?.toString() ?? '';
      _maintenanceBasis = draft['maintenanceBasis']?.toString() ?? 'Per Sq. Ft.';
      _maintenanceIncludedInPrice = draft['maintenanceIncludedInPrice'] as bool? ?? false;
      _securityDepositType = draft['securityDepositType']?.toString() ?? 'Zero Deposit';
      _customDepositCtrl.text = draft['customDeposit']?.toString() ?? '';

      _possessionStatus = draft['possessionStatus']?.toString() ?? 'Ready to Move';
      _saleTransactionType = draft['saleTransactionType']?.toString() ?? 'Resale';
      _ownershipType = draft['ownershipType']?.toString() ?? 'Free Hold';
      _availableFrom = draft['availableFrom']?.toString() ?? 'Immediately';
      if (draft['availableDate'] != null) {
        _availableDate = DateTime.tryParse(draft['availableDate'].toString());
      }
      if (draft['suitedFor'] is List) {
        _selectedSuitedFor.clear();
        _selectedSuitedFor.addAll(List<String>.from(draft['suitedFor'] as List));
      }

      _selectedBhk = draft['bhk']?.toString() ?? '2 BHK';
      _bathrooms = draft['bathrooms']?.toString() ?? '2';
      _balconies = draft['balconies']?.toString() ?? '1';
      _floor = draft['floor']?.toString() ?? '1';
      _totalFloorsCtrl.text = draft['totalFloors']?.toString() ?? '';

      if (draft['additionalSpaces'] is List) {
        _selectedAdditionalSpaces.clear();
        _selectedAdditionalSpaces.addAll(List<String>.from(draft['additionalSpaces'] as List));
      }
      if (draft['amenities'] is List) {
        _selectedAmenities.clear();
        _selectedAmenities.addAll(List<String>.from(draft['amenities'] as List));
      }
      _furnishing = draft['furnishing']?.toString() ?? 'Semi-Furnished';
      if (draft['furnishingQuantities'] is Map) {
        final fMap = draft['furnishingQuantities'] as Map;
        fMap.forEach((k, v) {
          _furnishingQuantities[k.toString()] = int.tryParse(v.toString()) ?? 0;
        });
      }

      _titleCtrl.text = draft['title']?.toString() ?? '';
      _descCtrl.text = draft['description']?.toString() ?? '';
      _reraCtrl.text = draft['reraNumber']?.toString() ?? '';
    });
    AppToast.showSuccess('Draft restored successfully!');
  }

  // ==========================================================================
  // NAVIGATION & SUBMIT
  // ==========================================================================
  void _onNext() {
    FocusScope.of(context).unfocus();
    switch (_currentStep) {
      case 0:
        if (_selectedPropertyType.isEmpty) {
          AppToast.showError('Please select a property type.');
          return;
        }
        break;
      case 1:
        if (_city.trim().isEmpty) {
          AppToast.showError('Please select or enter the property city.');
          return;
        }
        if (_localityCtrl.text.trim().isEmpty) {
          AppToast.showError('Please enter locality / society.');
          return;
        }
        break;
      case 2:
        final p = double.tryParse(_priceCtrl.text.trim()) ?? 0;
        if (p <= 0) {
          AppToast.showError(_listingType == 'Sale' ? 'Please enter a valid property price.' : 'Please enter rent amount.');
          return;
        }
        if (_listingType == 'Rent' && _securityDepositType == 'Other') {
          final cd = double.tryParse(_customDepositCtrl.text.trim()) ?? 0;
          if (cd <= 0) {
            AppToast.showError('Please enter custom security deposit amount.');
            return;
          }
        }
        if (_listingType == 'Rent' && _availableFrom == 'Later' && _availableDate == null) {
          AppToast.showError('Please select the availability date.');
          return;
        }
        break;
      case 3:
        if (!_isPlot && _selectedBhk.isEmpty) {
          AppToast.showError('Please choose BHK configuration.');
          return;
        }
        if (_areaRows.isEmpty || (double.tryParse(_areaRows.first.sizeCtrl.text.trim()) ?? 0) <= 0) {
          AppToast.showError('Please enter valid area size.');
          return;
        }
        break;
      case 4:
        if (_photos.isEmpty) {
          AppToast.showError('Minimum one property image is required.');
          return;
        }
        if (_documents.isEmpty) {
          AppToast.showError('Please upload at least 1 property document (PDF or Image) for verification.');
          return;
        }
        break;
    }

    _saveDraft(showToast: false);
    setState(() => _currentStep++);
  }

  Future<void> _submitListing() async {
    if (_photos.isEmpty) {
      AppToast.showError('At least one property image is required before submitting.');
      return;
    }
    if (_documents.isEmpty) {
      AppToast.showError('Please upload at least 1 property document (PDF or Image) for verification.');
      return;
    }
    if (!_agreeTerms) {
      AppToast.showWarning('Please accept the Terms & Conditions to submit listing.');
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final primaryAreaRow = _areaRows.firstWhere((r) => r.isPrimary, orElse: () => _areaRows.first);
    final areaVal = double.tryParse(primaryAreaRow.sizeCtrl.text.trim()) ?? 0.0;

    // Compile furnishing items summary
    final activeFurnishings = <String>[];
    final structuredFurnishingItems = <Map<String, dynamic>>[];
    _furnishingQuantities.forEach((item, qty) {
      if (qty > 0) {
        activeFurnishings.add('$item ($qty)');
        structuredFurnishingItems.add({'name': item.trim(), 'quantity': qty});
      }
    });
    for (final c in _customFurnishingItems) {
      if (c.quantity > 0) {
        activeFurnishings.add('${c.name} (${c.quantity})');
        structuredFurnishingItems.add({'name': c.name.trim(), 'quantity': c.quantity});
      }
    }

    final autoTitle = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : (!_isPlot
            ? '$_selectedBhk $_selectedPropertyType for $_listingType in ${_localityCtrl.text.trim()}, $_city'
            : '$_selectedPropertyType for $_listingType in ${_localityCtrl.text.trim()}, $_city');

    final fields = <String, dynamic>{
      'title': autoTitle,
      'transactionType': _listingType,
      'purpose': _listingType,
      'category': _buildingType,
      'propertyCategory': _buildingType,
      'propertyType': _selectedPropertyType,
      'status': 'Submitted',
      'price': price,
      'priceBasis': _priceBasis,
      if (_selectedPriceAdvantages.isNotEmpty) 'priceAdvantages': _selectedPriceAdvantages.join(', '),
      if (_listingType == 'Rent') ...{
        'rent': price,
        'rentalPaymentFrequency': _rentalPaymentFrequency,
        'maintenance': double.tryParse(_maintenanceCtrl.text.trim()) ?? 0,
        'maintenanceBasis': _maintenanceBasis,
        'maintenanceIncluded': _maintenanceIncludedInPrice,
        'securityDepositType': _securityDepositType,
        'securityDeposit': _calculateSecurityDeposit(),
        'availableFrom': _availableFrom,
        if (_availableDate != null) 'availableDate': _availableDate!.toIso8601String(),
        if (_selectedSuitedFor.isNotEmpty) 'suitedFor': _selectedSuitedFor.join(', '),
      },
      if (_isPG) ...{
        'availableFor': _pgAvailableFor,
        'roomType': _pgRoomType,
        'foodChargesIncluded': _pgFoodCharges == 'Yes',
      },
      'city': _city,
      'locality': _localityCtrl.text.trim(),
      'societyName': _localityCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'pinCode': _pincodeCtrl.text.trim(),
      if (_stateCtrl.text.trim().isNotEmpty) 'state': _stateCtrl.text.trim(),
      if (_landmarkCtrl.text.trim().isNotEmpty) 'landmark': _landmarkCtrl.text.trim(),
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
      'propertySize': areaVal,
      'sizeUnit': primaryAreaRow.unit == 'Sq. Yd.' ? 'sqyd' : (primaryAreaRow.unit == 'Sq. M.' ? 'sqm' : 'sqft'),
      'areaType': primaryAreaRow.type,
      'superBuiltupArea': areaVal,
      'carpetArea': areaVal,
      if (!_isPlot) ...{
        'bhk': _selectedBhk,
        'bedrooms': _selectedBhk.replaceAll(RegExp(r'[^0-9]'), '').isEmpty ? '1' : _selectedBhk.replaceAll(RegExp(r'[^0-9]'), ''),
        'bathrooms': _bathrooms,
        'balconies': _balconies,
        'floor': _floor,
        if (_totalFloorsCtrl.text.trim().isNotEmpty) 'totalFloors': _totalFloorsCtrl.text.trim(),
        'furnishing': _furnishing,
        if (structuredFurnishingItems.isNotEmpty) 'furnishingItems': structuredFurnishingItems,
        if (activeFurnishings.isNotEmpty) 'furnishingInventory': activeFurnishings.join(', '),
        if (_selectedAdditionalSpaces.isNotEmpty) 'additionalSpaces': _selectedAdditionalSpaces.join(', '),
        if (_selectedAmenities.isNotEmpty) 'amenities': _selectedAmenities.toList(),
      },
      if (_isPlot && _selectedAmenities.isNotEmpty) 'amenities': _selectedAmenities.toList(),
      if (_listingType == 'Sale') ...{
        'possessionStatus': _possessionStatus,
        'saleTransactionType': _saleTransactionType,
        'ownershipTitle': _ownershipType,
      },
      'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : autoTitle,
      if (_reraCtrl.text.trim().isNotEmpty) 'reraNumber': _reraCtrl.text.trim(),
      if (_assignedPropertyId != null) 'assignedPropertyId': _assignedPropertyId,
    };

    final result = await _controller.submitNewProperty(
      fields: fields,
      images: _photos,
      video: _video,
      documents: _documents,
    );

    if (!mounted) return;

    if (result != null) {
      await StorageService.instance.clearPropertyDraft();

      if (_isPartnerFlow) {
        if (Get.isRegistered<PartnerHomeController>()) {
          Get.find<PartnerHomeController>().loadProperties();
        }
      } else {
        if (Get.isRegistered<SellerController>(tag: 'sellerHome')) {
          Get.find<SellerController>(tag: 'sellerHome').loadSellerHome(silent: true);
        }
        if (Get.isRegistered<SellerController>(tag: 'myPropertiesScreen')) {
          Get.find<SellerController>(tag: 'myPropertiesScreen').loadSellerHome(silent: true);
        }
      }

      setState(() {
        _createdProperty = result;
        _currentStep = _totalSteps;
      });

      AppToast.showSuccess('Property listing submitted successfully!');
    } else {
      final err = _controller.submitPropertyError.value;
      AppToast.showError(err.isNotEmpty ? err : 'Submission failed. Please check your connection and try again.');
    }
  }

  double _calculateSecurityDeposit() {
    final rent = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (_securityDepositType == 'Zero Deposit') return 0;
    if (_securityDepositType == 'One Month') return rent;
    if (_securityDepositType == 'Two Months') return rent * 2;
    return double.tryParse(_customDepositCtrl.text.trim()) ?? 0;
  }

  void _navigateToProperties() {
    if (_isPartnerFlow) {
      if (Get.isRegistered<PartnerHomeController>()) {
        Get.find<PartnerHomeController>().loadProperties();
        Get.find<PartnerHomeController>().goToTab(2);
      }
      Get.offAllNamed(AppRoutes.partnerDashboard);
    } else {
      if (Get.isRegistered<SellerController>(tag: 'sellerHome')) {
        Get.find<SellerController>(tag: 'sellerHome').loadSellerHome(silent: true);
      }
      if (Get.isRegistered<SellerController>(tag: 'myPropertiesScreen')) {
        Get.find<SellerController>(tag: 'myPropertiesScreen').loadSellerHome(silent: true);
      }
      Get.offAllNamed(AppRoutes.sellerHome, arguments: {'tab': 1});
    }
  }

  final Geocoding _geocoding = Geocoding();

  // ==========================================================================
  // GEOCODING PINCODE & MAP PICKER HELPERS
  // ==========================================================================
  Future<void> _geocodePincode(String pin) async {
    if (pin.length != 6) return;
    setState(() => _isGeocoding = true);
    try {
      final locs = await _geocoding.locationFromAddress('$pin, India');
      if (locs.isNotEmpty) {
        final loc = locs.first;
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        final marks = await _geocoding.placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (marks.isNotEmpty && mounted) {
          final p = marks.first;
          setState(() {
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
              _stateCtrl.text = p.administrativeArea!;
            }
            final cityName = p.locality?.isNotEmpty == true
                ? p.locality!
                : (p.subAdministrativeArea?.isNotEmpty == true ? p.subAdministrativeArea! : null);
            if (cityName != null) {
              if (!_cityOptions.contains(cityName)) {
                _cityOptions.insert(0, cityName);
              }
              _city = cityName;
            }
            if (p.subLocality?.isNotEmpty == true) {
              _localityCtrl.text = p.subLocality!;
            } else if (p.locality?.isNotEmpty == true && _localityCtrl.text.isEmpty) {
              _localityCtrl.text = p.locality!;
            }
            final addressParts = [p.name, p.street, p.subLocality, p.locality]
                .where((e) => e != null && e.isNotEmpty)
                .toSet()
                .toList();
            if (addressParts.isNotEmpty && _addressCtrl.text.isEmpty) {
              _addressCtrl.text = addressParts.join(', ');
            }
          });
          AppToast.showSuccess('State, City & Address auto-filled from PIN Code!');
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _showStatePicker() {
    String searchQuery = '';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = _indianStates
              .where((s) => s.toLowerCase().contains(searchQuery.toLowerCase().trim()))
              .toList();
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: BoxConstraints(maxHeight: 0.75.sh),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select State / Union Territory',
                      style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: _navy),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _border),
                  ),
                  child: TextField(
                    autofocus: true,
                    style: GoogleFonts.poppins(fontSize: 13.sp, color: _navy),
                    decoration: InputDecoration(
                      hintText: 'Search State or UT...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12.sp, color: _grey),
                      prefixIcon: Icon(Icons.search_rounded, color: _green, size: 20.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    ),
                    onChanged: (val) {
                      setModalState(() => searchQuery = val);
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('No states found', style: GoogleFonts.poppins(fontSize: 12.sp, color: _grey)),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, idx) {
                            final st = filtered[idx];
                            final isSel = _stateCtrl.text.trim().toLowerCase() == st.toLowerCase();
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                              title: Text(
                                st,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? _green : _navy,
                                ),
                              ),
                              trailing: isSel ? Icon(Icons.check_circle_rounded, color: _green, size: 18.sp) : null,
                              onTap: () {
                                setState(() {
                                  _stateCtrl.text = st;
                                });
                                Get.back();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
    isScrollControlled: true,
  );
}

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            if (f.path != null) {
              _documents.add(File(f.path!));
            }
          }
        });
        AppToast.showSuccess('${result.files.length} document(s) uploaded successfully.');
      }
    } catch (_) {
      AppToast.showError('Could not open file picker for documents.');
    }
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    if (_currentStep == _totalSteps) return _buildSuccessScreen();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentStep > 0) {
          await _saveDraft(showToast: false);
          if (mounted) setState(() => _currentStep--);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: _navy, size: 18.sp),
            onPressed: () async {
              if (_currentStep > 0) {
                await _saveDraft(showToast: false);
                if (mounted) setState(() => _currentStep--);
              } else {
                Get.back();
              }
            },
          ),
          title: Text(
            _isPartnerFlow ? 'Agent Property Listing' : 'Add Property',
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _navy),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _saveDraft(showToast: true),
              icon: Icon(Icons.bookmark_outline_rounded, size: 16.sp, color: _green),
              label: Text(
                'Save Draft',
                style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green),
              ),
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderProgress(),
                SizedBox(height: 18.h),
                _buildStepContent(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  // ==========================================================================
  // PROGRESS & STEP HEADER
  // ==========================================================================
  static const List<String> _stepNames = [
    'Property Type',
    'Location & Society',
    'Price & Terms',
    'Config & Area',
    'Media & Photos',
    'Review & Submit',
  ];

  Widget _buildHeaderProgress() {
    final stepTitle = _stepNames[_currentStep];
    final pct = _completionPercentage;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps: $stepTitle',
                style: GoogleFonts.poppins(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: _navy),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$pct% Completed',
                  style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _green),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 6.h,
              backgroundColor: _border,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PropertyType();
      case 1:
        return _buildStep2Location();
      case 2:
        return _buildStep3Price();
      case 3:
        return _buildStep4ConfigAndArea();
      case 4:
        return _buildStep5Media();
      default:
        return _buildStep6Review();
    }
  }

  // ==========================================================================
  // STEP 1: PROPERTY TYPE
  // ==========================================================================
  Widget _buildStep1PropertyType() {
    final isRent = _listingType == 'Rent';
    final isResidential = _buildingType == 'Residential';

    final propTypes = isResidential
        ? [..._residentialTypes, if (isRent) 'PG']
        : _commercialTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Listing & Property Type'),
        _subtitle('Specify whether you are selling or renting, and pick property category.'),
        SizedBox(height: 16.h),

        // 1. Listing Type (Sale / Rent)
        _sectionLabel('1. Listing Type'),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _choiceButton(
                label: 'Sale',
                icon: Icons.sell_outlined,
                isSelected: _listingType == 'Sale',
                onTap: () => _checkActiveEditRestriction(() {
                  setState(() {
                    _listingType = 'Sale';
                    if (_selectedPropertyType == 'PG') _selectedPropertyType = 'Apartment';
                  });
                }),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _choiceButton(
                label: 'Rent',
                icon: Icons.vpn_key_outlined,
                isSelected: _listingType == 'Rent',
                onTap: () => _checkActiveEditRestriction(() {
                  setState(() => _listingType = 'Rent');
                }),
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // 2. Building Type (Residential / Commercial)
        _sectionLabel('2. Building Type'),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _choiceButton(
                label: 'Residential',
                icon: Icons.home_work_outlined,
                isSelected: _buildingType == 'Residential',
                onTap: () => _checkActiveEditRestriction(() {
                  setState(() {
                    _buildingType = 'Residential';
                    _selectedPropertyType = 'Apartment';
                  });
                }),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _choiceButton(
                label: 'Commercial',
                icon: Icons.business_outlined,
                isSelected: _buildingType == 'Commercial',
                onTap: () => _checkActiveEditRestriction(() {
                  setState(() {
                    _buildingType = 'Commercial';
                    _selectedPropertyType = 'Office';
                    _selectedAmenities.removeWhere((a) => !_commercialAmenities.contains(a));
                  });
                }),
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),

        // 3. Property Type
        _sectionLabel(isResidential ? '3. Residential Property Type' : '3. Commercial Property Type'),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: propTypes.map((type) {
            final isSel = _selectedPropertyType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSel,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedPropertyType = type;
                    // Auto-adjust area row for plot
                    if (_isPlot && _areaRows.isNotEmpty) {
                      _areaRows.first.type = 'Plot Area';
                    }
                  });
                }
              },
              labelStyle: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                color: isSel ? _green : _navy,
              ),
              selectedColor: _greenLight,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
                side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            );
          }).toList(),
        ),

        // If PG under Rent is selected -> show PG specific options
        if (_isPG && isRent) ...[
          SizedBox(height: 22.h),
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: _greenLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hotel_rounded, color: _green, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text('PG Details & Facilities',
                        style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _navy)),
                  ],
                ),
                SizedBox(height: 12.h),

                _label('Available For:'),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: _pgAvailableForOptions.map((opt) {
                    final sel = _pgAvailableFor == opt;
                    return ChoiceChip(
                      label: Text(opt),
                      selected: sel,
                      onSelected: (_) => setState(() => _pgAvailableFor = opt),
                      selectedColor: _green,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _navy,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),

                _label('Room Type:'),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: _pgRoomTypeOptions.map((opt) {
                    final sel = _pgRoomType == opt;
                    return ChoiceChip(
                      label: Text(opt),
                      selected: sel,
                      onSelected: (_) => setState(() => _pgRoomType = opt),
                      selectedColor: _green,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _navy,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),

                _label('Food Charges Included:'),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: _pgFoodChargesOptions.map((opt) {
                    final sel = _pgFoodCharges == opt;
                    return ChoiceChip(
                      label: Text(opt),
                      selected: sel,
                      onSelected: (_) => setState(() => _pgFoodCharges = opt),
                      selectedColor: _green,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _navy,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================================
  // STEP 2: LOCATION & PROJECT
  // ==========================================================================
  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Location & Project'),
        _subtitle('Set state, city, locality / society and address of the property.'),
        SizedBox(height: 16.h),

        // Searchable State Dropdown Picker
        _label('State / Union Territory', required: true),
        SizedBox(height: 6.h),
        InkWell(
          onTap: _showStatePicker,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _stateCtrl.text.trim().isNotEmpty
                        ? _stateCtrl.text.trim()
                        : 'Select State / Union Territory',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: _stateCtrl.text.trim().isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: _stateCtrl.text.trim().isNotEmpty ? _navy : _grey,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: _navy, size: 24.sp),
              ],
            ),
          ),
        ),
        SizedBox(height: 14.h),

        // City Search / Dropdown
        _label('City', required: true),
        SizedBox(height: 6.h),
        _dropdown(
          value: _city,
          items: _cityOptions,
          onChanged: (v) => setState(() => _city = v),
        ),
        SizedBox(height: 14.h),

        // Locality / Society Search with auto-suggestions
        _label('Locality / Society', required: true),
        SizedBox(height: 6.h),
        _textField(
          controller: _localityCtrl,
          hint: 'Search locality or society (e.g. Sector 9, DLF Phase 1)',
          prefixIcon: Icons.search_rounded,
        ),
        if (_matchedLocalities.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: _matchedLocalities.map((loc) {
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on_outlined, color: _green, size: 18.sp),
                  title: Text(loc, style: GoogleFonts.poppins(fontSize: 12.sp, color: _navy)),
                  onTap: () {
                    setState(() {
                      _localityCtrl.text = loc;
                      _matchedLocalities = [];
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
        SizedBox(height: 14.h),

        // Pincode with Auto-Geocoding
        _label('Pincode (6 Digits)'),
        SizedBox(height: 6.h),
        _textField(
          controller: _pincodeCtrl,
          hint: 'e.g. 134003',
          keyboardType: TextInputType.number,
          maxLength: 6,
          suffix: _isGeocoding
              ? Padding(
                  padding: EdgeInsets.all(12.r),
                  child: SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: _green),
                  ),
                )
              : null,
          onChanged: (v) {
            if (v.trim().length == 6) _geocodePincode(v.trim());
          },
        ),
        SizedBox(height: 10.h),

        // Street Address
        _label('Full Street Address'),
        SizedBox(height: 6.h),
        _textField(
          controller: _addressCtrl,
          hint: 'House/Flat No, Tower, Building, Road name',
          maxLines: 2,
        ),
        SizedBox(height: 14.h),

        // Landmark
        _label('Landmark (Optional)'),
        SizedBox(height: 6.h),
        _textField(
          controller: _landmarkCtrl,
          hint: 'Near Metro Station, Opposite City Park, etc.',
        ),
        SizedBox(height: 14.h),

        // Map Picker Button with Auto Reverse Geocoding
        OutlinedButton.icon(
          onPressed: () async {
            final LatLng? picked = await Get.to<LatLng>(() => MapPickerScreen(
                  initial: _latitude != null && _longitude != null
                      ? LatLng(_latitude!, _longitude!)
                      : const LatLng(30.3753, 76.7821),
                ));
            if (picked != null) {
              setState(() {
                _latitude = picked.latitude;
                _longitude = picked.longitude;
              });
              AppToast.showSuccess('Map pin selected. Auto-filling address...');
              try {
                final marks = await _geocoding.placemarkFromCoordinates(picked.latitude, picked.longitude);
                if (marks.isNotEmpty && mounted) {
                  final p = marks.first;
                  setState(() {
                    if (p.postalCode?.isNotEmpty == true) {
                      _pincodeCtrl.text = p.postalCode!;
                    }
                    if (p.administrativeArea?.isNotEmpty == true) {
                      _stateCtrl.text = p.administrativeArea!;
                    }
                    final cName = p.locality?.isNotEmpty == true
                        ? p.locality!
                        : (p.subAdministrativeArea?.isNotEmpty == true ? p.subAdministrativeArea! : null);
                    if (cName != null) {
                      if (!_cityOptions.contains(cName)) {
                        _cityOptions.insert(0, cName);
                      }
                      _city = cName;
                    }
                    if (p.subLocality?.isNotEmpty == true) {
                      _localityCtrl.text = p.subLocality!;
                    } else if (p.locality?.isNotEmpty == true && _localityCtrl.text.isEmpty) {
                      _localityCtrl.text = p.locality!;
                    }
                    final parts = [p.name, p.street, p.subLocality, p.locality]
                        .where((e) => e != null && e.isNotEmpty)
                        .toSet()
                        .toList();
                    if (parts.isNotEmpty) {
                      _addressCtrl.text = parts.join(', ');
                    }
                  });
                  AppToast.showSuccess('Address auto-filled from Map location!');
                }
              } catch (_) {}
            }
          },
          icon: Icon(Icons.map_rounded, color: _green, size: 18.sp),
          label: Text(
            _latitude != null ? 'Pin Set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}' : 'Select Exact Pin on Map',
            style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _green),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // STEP 3: PRICE & FINANCIAL DETAILS
  // ==========================================================================
  Widget _buildStep3Price() {
    final isSale = _listingType == 'Sale';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(isSale ? 'Sale Price & Advantages' : 'Rental Price & Terms'),
        _subtitle(isSale
            ? 'Set sale price, price advantages, possession and ownership.'
            : 'Set monthly rent, maintenance, security deposit and availability.'),
        SizedBox(height: 16.h),

        // 1. Property Price / Rent
        _label(isSale ? 'Property Price (₹)' : 'Monthly Rent (₹)', required: true),
        SizedBox(height: 6.h),
        _textField(
          controller: _priceCtrl,
          hint: isSale ? 'e.g. 7500000' : 'e.g. 25000',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.currency_rupee_rounded,
          onChanged: (_) => setState(() {}),
        ),
        if (_priceCtrl.text.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            _formatPricePreview(double.tryParse(_priceCtrl.text.trim()) ?? 0),
            style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: _green),
          ),
        ],
        SizedBox(height: 16.h),

        // If SALE -> All Inclusive / Base Price
        if (isSale) ...[
          _label('Price Basis:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: ['All Inclusive', 'Base Price'].map((basis) {
              final isSel = _priceBasis == basis;
              return ChoiceChip(
                label: Text(basis),
                selected: isSel,
                onSelected: (_) => setState(() => _priceBasis = basis),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 18.h),

          // Price Advantages (Select / Deselect)
          _label('Price Advantages (Select applicable):'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _priceAdvantagesList.map((tag) {
              final isSel = _selectedPriceAdvantages.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSel,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedPriceAdvantages.add(tag);
                    } else {
                      _selectedPriceAdvantages.remove(tag);
                    }
                  });
                },
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.4 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 18.h),

          // Possession Status
          _label('Possession Status:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 10.w,
            children: _possessionStatuses.map((ps) {
              final isSel = _possessionStatus == ps;
              return ChoiceChip(
                label: Text(ps),
                selected: isSel,
                onSelected: (_) => setState(() => _possessionStatus = ps),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 18.h),

          // Transaction Type (Resale / New Booking)
          _label('Transaction Type:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 10.w,
            children: _saleTransactionTypes.map((tx) {
              final isSel = _saleTransactionType == tx;
              return ChoiceChip(
                label: Text(tx),
                selected: isSel,
                onSelected: (_) => setState(() => _saleTransactionType = tx),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 18.h),

          // Ownership Type
          _label('Ownership Type:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 10.w,
            children: _ownershipTypes.map((own) {
              final isSel = _ownershipType == own;
              return ChoiceChip(
                label: Text(own),
                selected: isSel,
                onSelected: (_) => setState(() => _ownershipType = own),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
        ],

        // If RENT -> Rent Terms
        if (!isSale) ...[
          // Payment Frequency
          _label('Payment Frequency:'),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _bgGrey,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(Icons.event_repeat_rounded, color: _green, size: 18.sp),
                SizedBox(width: 8.w),
                Text('Per Month', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _navy)),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Maintenance
          _label('Maintenance:'),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _textField(
                  controller: _maintenanceCtrl,
                  hint: 'Amount (e.g. 2000)',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: _dropdown(
                  value: _maintenanceBasis,
                  items: _maintenanceBasisOptions,
                  onChanged: (v) => setState(() => _maintenanceBasis = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _maintenanceIncludedInPrice,
            onChanged: (val) => setState(() => _maintenanceIncludedInPrice = val ?? false),
            title: Text(
              'Maintenance included in rent price',
              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500, color: _navy),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: _green,
          ),
          SizedBox(height: 14.h),

          // Security Deposit
          _label('Security Deposit:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: _securityDepositOptions.map((opt) {
              final isSel = _securityDepositType == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: isSel,
                onSelected: (_) => setState(() => _securityDepositType = opt),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          if (_securityDepositType == 'Other') ...[
            SizedBox(height: 10.h),
            _textField(
              controller: _customDepositCtrl,
              hint: 'Enter custom deposit amount (₹)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.currency_rupee_rounded,
            ),
          ],
          SizedBox(height: 16.h),

          // Available From
          _label('Available From:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: ['Immediately', 'Later'].map((af) {
              final isSel = _availableFrom == af;
              return ChoiceChip(
                label: Text(af),
                selected: isSel,
                onSelected: (_) => setState(() => _availableFrom = af),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          if (_availableFrom == 'Later') ...[
            SizedBox(height: 10.h),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _availableDate ?? now.add(const Duration(days: 7)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _availableDate = picked);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: _green, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      _availableDate != null
                          ? '${_availableDate!.day}/${_availableDate!.month}/${_availableDate!.year}'
                          : 'Select Available Date',
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: _navy),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 16.h),

          // Suited For (Students, Working Professionals, Any)
          _label('Suited For:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: _suitedForList.map((st) {
              final isSel = _selectedSuitedFor.contains(st);
              return FilterChip(
                label: Text(st),
                selected: isSel,
                onSelected: (val) {
                  setState(() {
                    if (st == 'Any') {
                      _selectedSuitedFor.clear();
                      if (val) _selectedSuitedFor.add('Any');
                    } else {
                      _selectedSuitedFor.remove('Any');
                      if (val) {
                        _selectedPriceAdvantages; // no-op
                        _selectedSuitedFor.add(st);
                      } else {
                        _selectedSuitedFor.remove(st);
                      }
                    }
                  });
                },
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.4 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ==========================================================================
  // STEP 4: CONFIGURATION, AREA & SPACES
  // ==========================================================================
  Widget _buildStep4ConfigAndArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Space & Configuration'),
        _subtitle(_isPlot ? 'Set plot area and dimensions.' : 'Specify BHK, area sizes, additional rooms & furnishings.'),
        SizedBox(height: 16.h),

        // BHK Configuration (HIDDEN IF PLOT)
        if (!_isPlot) ...[
          _label('BHK Configuration', required: true),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _bhkList.map((bhk) {
              final isSel = _selectedBhk == bhk;
              return ChoiceChip(
                label: Text(bhk),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedBhk = bhk),
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 18.h),

          // Bathrooms & Balconies
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Bathrooms'),
                    SizedBox(height: 6.h),
                    _dropdown(
                      value: _bathrooms,
                      items: ['1', '2', '3', '4', '5+'],
                      onChanged: (v) => setState(() => _bathrooms = v),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Balconies'),
                    SizedBox(height: 6.h),
                    _dropdown(
                      value: _balconies,
                      items: ['0', '1', '2', '3', '4+'],
                      onChanged: (v) => setState(() => _balconies = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
        ],

        // Area Details (Dynamic Multiple Rows)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _label('Area Details', required: true)),
            SizedBox(width: 8.w),
            Text(
              'Select primary area for display',
              style: GoogleFonts.poppins(fontSize: 10.5.sp, color: _grey),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ..._areaRows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: row.isPrimary ? _greenLight.withValues(alpha: 0.3) : _bgGrey,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: row.isPrimary ? _green : _border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _textField(
                        controller: row.sizeCtrl,
                        hint: 'Size (e.g. 1450)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 2,
                      child: _dropdown(
                        value: row.unit,
                        items: _areaUnits,
                        onChanged: (v) => setState(() => row.unit = v),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        value: row.type,
                        items: _isPlot ? ['Plot Area', 'Carpet Area'] : _areaTypes,
                        onChanged: (v) => setState(() => row.type = v),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    InkWell(
                      onTap: () {
                        setState(() {
                          for (final r in _areaRows) {
                            r.isPrimary = false;
                          }
                          row.isPrimary = true;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            row.isPrimary ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: row.isPrimary ? _green : _grey,
                            size: 18.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Display',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5.sp,
                              fontWeight: row.isPrimary ? FontWeight.w700 : FontWeight.w500,
                              color: row.isPrimary ? _green : _navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_areaRows.length > 1) ...[
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20.sp),
                        onPressed: () {
                          setState(() {
                            row.dispose();
                            _areaRows.removeAt(idx);
                            if (_areaRows.isNotEmpty && !_areaRows.any((r) => r.isPrimary)) {
                              _areaRows.first.isPrimary = true;
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),

        // Add More Area Types button
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _areaRows.add(AreaDetailRow(
                unit: 'Sq. Ft.',
                type: _isPlot ? 'Plot Area' : 'Carpet Area',
                isPrimary: false,
              ));
            });
          },
          icon: Icon(Icons.add_rounded, color: _green, size: 18.sp),
          label: Text(
            'Add More Area Types',
            style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _green),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
        SizedBox(height: 20.h),

        // Additional Space Options (HIDDEN IF PLOT)
        if (!_isPlot) ...[
          _label('Additional Space Options (Select applicable):'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _additionalSpacesList.map((space) {
              final isSel = _selectedAdditionalSpaces.contains(space);
              return FilterChip(
                label: Text(space),
                selected: isSel,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedAdditionalSpaces.add(space);
                    } else {
                      _selectedAdditionalSpaces.remove(space);
                    }
                  });
                },
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.4 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),

          // Furnishing Status
          _label('Furnishing Status:'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _furnishingStatuses.map((st) {
              final isSel = _furnishing == st;
              return ChoiceChip(
                label: Text(st),
                selected: isSel,
                onSelected: (_) {
                  setState(() => _furnishing = st);
                  if (st == 'Unfurnished') {
                    // Clear previously selected furnishing items
                    _furnishingQuantities.updateAll((key, val) => 0);
                    _customFurnishingItems.clear();
                  } else {
                    _openFurnishingDetailsPanel();
                  }
                },
                selectedColor: _greenLight,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: isSel ? _green : _border, width: isSel ? 1.5 : 1),
                ),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSel ? _green : _navy,
                ),
              );
            }).toList(),
          ),

          if (_furnishing != 'Unfurnished') ...[
            SizedBox(height: 12.h),
            InkWell(
              onTap: _openFurnishingDetailsPanel,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: _greenLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: _green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chair_outlined, color: _green, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Furnishing Details (${_furnishingQuantities.values.where((q) => q > 0).length + _customFurnishingItems.length} items configured)',
                        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green),
                      ),
                    ),
                    Text('Edit Items', style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: _navy)),
                  ],
                ),
              ),
            ),
          ],
        ],

        // Amenities & Features Section (Default selectable + Custom typing)
        SizedBox(height: 20.h),
        _label('Amenities & Features'),
        SizedBox(height: 4.h),
        Text(
          'Select amenities available or type custom ones below.',
          style: GoogleFonts.poppins(fontSize: 11.5.sp, color: _grey),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _currentDefaultAmenities.map((amenity) {
            final isSel = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSel,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _greenLight,
              checkmarkColor: _green,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                color: isSel ? _green : _navy,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: BorderSide(color: isSel ? _green : _border),
              ),
            );
          }).toList(),
        ),
        if (_selectedAmenities.difference(_currentDefaultAmenities.toSet()).isNotEmpty) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedAmenities.difference(_currentDefaultAmenities.toSet()).map((custom) {
              return Chip(
                label: Text(custom),
                backgroundColor: _greenLight,
                labelStyle: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green),
                deleteIcon: Icon(Icons.close, size: 14.sp, color: _green),
                onDeleted: () => setState(() => _selectedAmenities.remove(custom)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r), side: const BorderSide(color: _green)),
              );
            }).toList(),
          ),
        ],
        SizedBox(height: 12.h),
        // Custom Amenity Add Field
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: _customAmenityCtrl,
                hint: 'Type custom amenity (e.g. EV Charging, Club)',
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: () {
                final txt = _customAmenityCtrl.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _selectedAmenities.add(txt);
                    _customAmenityCtrl.clear();
                  });
                  AppToast.showSuccess('Amenity added.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('+ Add', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================================
  // FURNISHING DETAILS MODAL PANEL
  // ==========================================================================
  void _openFurnishingDetailsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Furnishing Details',
                        style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _navy),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Select items and configure quantities:',
                    style: GoogleFonts.poppins(fontSize: 11.5.sp, color: _grey),
                  ),
                  SizedBox(height: 12.h),

                  // Scrollable Items list
                  Expanded(
                    child: ListView(
                      children: [
                        ..._furnishingItemsList.map((item) {
                          final qty = _furnishingQuantities[item] ?? 0;
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: qty > 0 ? _greenLight.withValues(alpha: 0.4) : _bgGrey,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: qty > 0 ? _green : _border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5.sp,
                                    fontWeight: qty > 0 ? FontWeight.w600 : FontWeight.w500,
                                    color: _navy,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: qty > 0 ? _green : _grey,
                                      onPressed: qty > 0
                                          ? () {
                                              setModalState(() => _furnishingQuantities[item] = qty - 1);
                                              setState(() {});
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '$qty',
                                      style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _navy),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: _green,
                                      onPressed: () {
                                        setModalState(() => _furnishingQuantities[item] = qty + 1);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        // Custom Items Added
                        ..._customFurnishingItems.map((cItem) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: _greenLight.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: _green),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  cItem.name,
                                  style: GoogleFonts.poppins(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: _navy),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: _green,
                                      onPressed: () {
                                        setModalState(() {
                                          if (cItem.quantity > 1) {
                                            cItem.quantity--;
                                          } else {
                                            _customFurnishingItems.remove(cItem);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    ),
                                    Text('${cItem.quantity}',
                                        style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _navy)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: _green,
                                      onPressed: () {
                                        setModalState(() => cItem.quantity++);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        // Add More Custom Item
                        TextButton.icon(
                          onPressed: () => _showAddCustomItemDialog(setModalState),
                          icon: Icon(Icons.add_rounded, color: _green, size: 18.sp),
                          label: Text(
                            '+ Add More Furnishing Item',
                            style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons: Reset All and Save
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _furnishingQuantities.updateAll((key, val) => 0);
                              _customFurnishingItems.clear();
                            });
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text('Reset All',
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.red)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {});
                            AppToast.showSuccess('Furnishing items saved.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text('Save Furnishing',
                              style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCustomItemDialog(StateSetter setModalState) {
    final nameCtrl = TextEditingController();
    int qty = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          title: Text('Add Custom Item', style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _navy)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Item Name (e.g. Study Table)'),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quantity:', style: GoogleFonts.poppins(fontSize: 12.sp, color: _navy)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: qty > 1 ? () => setDialogState(() => qty--) : null,
                      ),
                      Text('$qty', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setDialogState(() => qty++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: _grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  setModalState(() {
                    _customFurnishingItems.add(CustomFurnishingItem(name, qty));
                  });
                  setState(() {});
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              child: Text('Add', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // STEP 5: MEDIA & HIGHLIGHTS
  // ==========================================================================
  Widget _buildStep5Media() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Media & Highlights'),
        _subtitle('Upload property photos (minimum 1 required) and walkthrough video.'),
        SizedBox(height: 16.h),

        // Photo Upload Box (Dotted Border)
        _label('Property Photos (At least 1 required)', required: true),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(16.r),
          child: AppDottedBorder(
            radius: 16.r,
            color: _green,
            backgroundColor: _greenLight.withValues(alpha: 0.25),
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: _green, size: 36.sp),
                  SizedBox(height: 8.h),
                  Text('Click to Upload Images', style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: _green)),
                  Text('JPG, PNG supported • First photo is cover', style: GoogleFonts.poppins(fontSize: 10.5.sp, color: _grey)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Photos Preview List
        if (_photos.isNotEmpty) ...[
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: _photos.asMap().entries.map((entry) {
              final idx = entry.key;
              final file = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                    ),
                  ),
                  if (idx == 0)
                    Positioned(
                      bottom: 4.h,
                      left: 4.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4.r)),
                        child: Text('Cover', style: GoogleFonts.poppins(fontSize: 8.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    top: 4.h,
                    right: 4.w,
                    child: InkWell(
                      onTap: () => setState(() => _photos.removeAt(idx)),
                      child: Container(
                        padding: EdgeInsets.all(3.r),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
        ],

        // Video Upload Box (Dotted Border)
        _label('Walkthrough Video (Optional)'),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _pickVideo,
          borderRadius: BorderRadius.circular(16.r),
          child: AppDottedBorder(
            radius: 16.r,
            color: const Color(0xFF94A3B8),
            backgroundColor: _bgGrey,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.video_library_outlined, color: _navy, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _videoName ?? 'Upload Video Walkthrough',
                          style: GoogleFonts.poppins(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: _navy),
                        ),
                        Text('MP4, MOV up to 70 MB', style: GoogleFonts.poppins(fontSize: 10.5.sp, color: _grey)),
                      ],
                    ),
                  ),
                  if (_video != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() {
                        _video = null;
                        _videoName = null;
                      }),
                    )
                  else
                    Text('Browse', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),

        // Property Documents (Mandatory * - PDF & Image)
        _label('Property Documents (Registry / Sale Deed / Tax Receipt) *', required: true),
        SizedBox(height: 4.h),
        Text(
          'Upload at least 1 document (PDF or Image) for verification. You can add multiple documents.',
          style: GoogleFonts.poppins(fontSize: 11.sp, color: _grey),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _pickDocuments,
          borderRadius: BorderRadius.circular(16.r),
          child: AppDottedBorder(
            radius: 16.r,
            color: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEDF5FF),
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.upload_file_rounded, color: const Color(0xFF2563EB), size: 24.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Property Documents',
                          style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                        ),
                        Text('PDF, JPG, PNG supported • At least 1 mandatory', style: GoogleFonts.poppins(fontSize: 10.5.sp, color: _grey)),
                      ],
                    ),
                  ),
                  Text('Browse', style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                ],
              ),
            ),
          ),
        ),
        if (_documents.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Column(
            children: _documents.asMap().entries.map((entry) {
              final idx = entry.key;
              final doc = entry.value;
              final fileName = doc.path.split(Platform.pathSeparator).last;
              final isPdf = fileName.toLowerCase().endsWith('.pdf');
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: isPdf ? const Color(0xFFFFEBEE) : const Color(0xFFEAF7F1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                        color: isPdf ? Colors.red.shade700 : _green,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _navy)),
                          Text(isPdf ? 'PDF Document' : 'Image Document', style: GoogleFonts.poppins(fontSize: 10.sp, color: _grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20.sp),
                      onPressed: () => setState(() => _documents.removeAt(idx)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 4.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _pickDocuments,
              icon: Icon(Icons.add_rounded, size: 16.sp, color: const Color(0xFF2563EB)),
              label: Text('+ Add Another Document', style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
            ),
          ),
        ],
        SizedBox(height: 18.h),

        // Optional Property Highlights
        _label('Property Title (Optional custom title)'),
        SizedBox(height: 6.h),
        _textField(
          controller: _titleCtrl,
          hint: 'e.g. Sun-facing Luxury 3 BHK with Private Terrace',
        ),
        SizedBox(height: 14.h),

        _label('Description / Highlights'),
        SizedBox(height: 6.h),
        _textField(
          controller: _descCtrl,
          hint: 'Highlight key features, connectivity, nearby schools, parks...',
          maxLines: 3,
        ),
        SizedBox(height: 14.h),

        _label('RERA Registration Number (If applicable)'),
        SizedBox(height: 6.h),
        _textField(
          controller: _reraCtrl,
          hint: 'e.g. HRERA-PKL-01-2023',
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked.isNotEmpty) {
        setState(() {
          for (final xf in picked) {
            _photos.add(File(xf.path));
          }
        });
      }
    } catch (_) {
      AppToast.showError('Could not open image picker.');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null) {
        final f = File(result.files.single.path!);
        final size = await f.length();
        if (size > 70 * 1024 * 1024) {
          AppToast.showError('Video file exceeds 70 MB limit.');
          return;
        }
        setState(() {
          _video = f;
          _videoName = result.files.single.name;
        });
      }
    } catch (_) {}
  }

  // ==========================================================================
  // STEP 6: REVIEW & SUBMIT
  // ==========================================================================
  Widget _buildStep6Review() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final primaryArea = _areaRows.firstWhere((r) => r.isPrimary, orElse: () => _areaRows.first);
    final areaValStr = primaryArea.sizeCtrl.text.trim().isNotEmpty ? primaryArea.sizeCtrl.text.trim() : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Review Listing Details'),
        _subtitle('Verify your property listing photos, specs, amenities and documents.'),
        SizedBox(height: 16.h),

        // 1. Photos Carousel / Image Slider (Airbnb Style)
        if (_photos.isNotEmpty) ...[
          Container(
            height: 220.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: _photos.length,
                    onPageChanged: (idx) => setState(() => _previewImageIndex = idx),
                    itemBuilder: (ctx, idx) {
                      return Image.file(
                        _photos[idx],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  // Gradient Overlay at bottom for dots
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 50.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top Left Badge: Guest Favourite / Verified
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: const Color(0xFFD9961F), size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'Featured Listing',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F2544),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top Right Badge: Image Counter
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${_previewImageIndex + 1} / ${_photos.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bottom Center: Dots Indicator
                  if (_photos.length > 1)
                    Positioned(
                      bottom: 10.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_photos.length, (i) {
                          final isSel = _previewImageIndex == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                            width: isSel ? 16.w : 6.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 2. 4-Column Specs Card (Matching Property Card Design)
        Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Bed
              _specItem(
                icon: Icons.hotel_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: !_isPlot ? _selectedBhk : 'Plot',
                subtitle: 'Bedrooms',
              ),
              Container(width: 1, height: 36.h, color: const Color(0xFFF1F5F9)),
              // Bath
              _specItem(
                icon: Icons.shower_rounded,
                iconColor: const Color(0xFF06B6D4),
                title: !_isPlot ? _bathrooms : '-',
                subtitle: 'Bathrooms',
              ),
              Container(width: 1, height: 36.h, color: const Color(0xFFF1F5F9)),
              // Area
              _specItem(
                icon: Icons.square_foot_rounded,
                iconColor: const Color(0xFF64748B),
                title: areaValStr,
                subtitle: primaryArea.unit,
              ),
              Container(width: 1, height: 36.h, color: const Color(0xFFF1F5F9)),
              // Furnishing
              _specItem(
                icon: Icons.weekend_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: !_isPlot ? (_furnishing.contains('-') ? _furnishing.split('-').first : _furnishing) : 'Clear',
                subtitle: 'Furnished',
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // 3. Main Details & Pricing Card
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(8.r)),
                    child: Text('$_listingType • $_buildingType',
                        style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: _green)),
                  ),
                  Text(_selectedPropertyType,
                      style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _navy)),
                ],
              ),
              SizedBox(height: 12.h),

              Text(
                _titleCtrl.text.trim().isNotEmpty
                    ? _titleCtrl.text.trim()
                    : '$_selectedBhk $_selectedPropertyType in ${_localityCtrl.text.trim()}',
                style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _navy),
              ),
              SizedBox(height: 6.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_rounded, size: 15.sp, color: _green),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      '${_addressCtrl.text.trim().isNotEmpty ? '${_addressCtrl.text.trim()}, ' : ''}${_localityCtrl.text.trim()}, $_city${_stateCtrl.text.trim().isNotEmpty ? ', ${_stateCtrl.text.trim()}' : ''}${_pincodeCtrl.text.trim().isNotEmpty ? ' - ${_pincodeCtrl.text.trim()}' : ''}',
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: _grey, height: 1.3),
                    ),
                  ),
                ],
              ),
              Divider(height: 24.h, color: _border),

              _reviewRow('Price / Rent:', _formatPricePreview(price)),
              if (_listingType == 'Sale') _reviewRow('Price Basis:', _priceBasis),
              if (_selectedPriceAdvantages.isNotEmpty)
                _reviewRow('Advantages:', _selectedPriceAdvantages.join(', ')),
              _reviewRow('Area:', '$areaValStr ${primaryArea.unit} (${primaryArea.type})'),
              if (!_isPlot) ...[
                _reviewRow('Configuration:', _selectedBhk),
                _reviewRow('Furnishing:', _furnishing),
                if (_selectedAdditionalSpaces.isNotEmpty)
                  _reviewRow('Additional Spaces:', _selectedAdditionalSpaces.join(', ')),
              ],
              if (_listingType == 'Rent') ...[
                _reviewRow('Security Deposit:', _securityDepositType),
                _reviewRow('Available From:', _availableFrom),
              ],
              _reviewRow('Photos Uploaded:', '${_photos.length} photo(s)'),
              if (_video != null) _reviewRow('Video Walkthrough:', 'Included (1 video)'),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // 4. Amenities Preview Section
        if (_selectedAmenities.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: _green, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Amenities & Features (${_selectedAmenities.length})',
                      style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _navy),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _selectedAmenities.map((amenity) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: _greenLight,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: _green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: _green, size: 13.sp),
                          SizedBox(width: 5.w),
                          Text(
                            amenity,
                            style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: _green),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 5. Uploaded Documents Preview Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: const Color(0xFF2563EB), size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Uploaded Documents (${_documents.length})',
                    style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _navy),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              if (_documents.isEmpty)
                Text('No documents uploaded yet.', style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.red))
              else
                Column(
                  children: _documents.map((doc) {
                    final fileName = doc.path.split(Platform.pathSeparator).last;
                    final isPdf = fileName.toLowerCase().endsWith('.pdf');
                    return Container(
                      margin: EdgeInsets.only(bottom: 6.h),
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            color: isPdf ? Colors.red.shade700 : _green,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: _navy),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text('Attached', style: GoogleFonts.poppins(fontSize: 9.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // Terms and conditions checkbox
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _agreeTerms,
          onChanged: (val) => setState(() => _agreeTerms = val ?? true),
          title: Text(
            'I confirm that all information provided is accurate and authentic as per DigiNiwas terms.',
            style: GoogleFonts.poppins(fontSize: 11.5.sp, color: _navy),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _green,
        ),
      ],
    );
  }

  Widget _specItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22.sp),
        SizedBox(height: 5.h),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10.5.sp,
            color: _grey,
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.w,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: _grey)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _navy)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SUCCESS VIEW
  // ==========================================================================
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: const BoxDecoration(color: _greenLight, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: _green, size: 60.sp),
              ),
              SizedBox(height: 20.h),
              Text(
                'Listing Submitted!',
                style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.w700, color: _navy),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your property has been successfully submitted and is under verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13.sp, color: _grey, height: 1.4),
              ),
              if (_createdProperty != null && (_createdProperty!['title'] != null || _createdProperty!['_id'] != null)) ...[
                SizedBox(height: 8.h),
                Text(
                  (_createdProperty!['title'] ?? _createdProperty!['_id']).toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _navy),
                ),
              ],
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _navigateToProperties,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text(
                    'View My Listings',
                    style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM BAR
  // ==========================================================================
  Widget _buildBottomBar() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48.h,
                child: OutlinedButton.icon(
                  onPressed: () => _saveDraft(showToast: true),
                  icon: Icon(Icons.bookmark_border_rounded, size: 16.sp, color: _green),
                  label: Text('Save Draft',
                      style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _green)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _green, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 3,
              child: isLast
                  ? Obx(() {
                      final loading = _controller.isSubmittingProperty.value;
                      return SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submitListing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: loading
                              ? SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Submit Listing',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      );
                    })
                  : SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Next',
                                style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                            SizedBox(width: 6.w),
                            Icon(Icons.arrow_forward_rounded, size: 16.sp, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SHARED UI HELPERS & COMPONENTS
  // ==========================================================================
  Widget _title(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _navy));
  }

  Widget _subtitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 11.5.sp, color: _grey, height: 1.35)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _navy));
  }

  Widget _label(String text, {bool required = false}) {
    if (!required) {
      return Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _navy),
      );
    }
    return Text.rich(
      TextSpan(
        text: text,
        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _navy),
        children: [
          const TextSpan(text: ' '),
          TextSpan(
            text: '*',
            style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? _greenLight : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? _green : _border, width: isSelected ? 1.8 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _green : _grey, size: 22.sp),
            SizedBox(height: 6.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _green : _navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 12.5.sp, color: _navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _grey, size: 18.sp) : null,
        suffixIcon: suffix,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: _green, width: 1.5)),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _navy, size: 20.sp),
          style: GoogleFonts.poppins(fontSize: 12.sp, color: _navy),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  String _formatPricePreview(double price) {
    if (price <= 0) return '₹ 0';
    if (price >= 10000000) {
      return '₹ ${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹ ${(price / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return '₹ ${price.toStringAsFixed(0)}';
    }
  }
}
