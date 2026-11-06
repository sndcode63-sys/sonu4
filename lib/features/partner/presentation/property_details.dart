import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../core/network/api_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/location_service.dart';
import '../data/partner_repository.dart';

import 'widgets/partner_ui.dart';
// ==========================================
// COLORS & THEME
// ==========================================
const Color kPrimaryTeal = Color(0xFF0A5C4A);
const Color kLightTealBg = Color(0xFFE8F3EF);
const Color kDarkNavy = Color(0xFF0B1B2E);
const Color kGreyText = Color(0xFF8493A3);
const Color kBorderGrey = Color(0xFFE3E8ED);
const Color kScaffoldBg = Color(0xFFF4F6F8);

// ==========================================
// 1. MODELS
// ==========================================
class UploadedPhoto {
  final String label;
  final bool isCover;
  final String? imagePath;
  UploadedPhoto({required this.label, this.isCover = false, this.imagePath});
}

class UploadedDocument {
  String status;
  String? fileName;
  String? fileSize;
  String? filePath;
  UploadedDocument({this.status = 'empty', this.fileName, this.fileSize, this.filePath});
}

class PropertySubmissionModel {
  String transactionType; // 'Sell' | 'Rent'
  String buildingType; // 'Residential' | 'Commercial'
  String propertyType;
  String title;
  double price;
  double rent;
  double securityDeposit;
  double maintenanceAmount;
  String maintenancePeriod; // 'Monthly' | 'Quarterly' | 'Yearly' | 'One-Time'
  String configuration;
  double carpetArea;
  double superBuiltupArea;
  String areaUnit; // 'sq.ft' | 'sq.yard' | 'sq.m'
  int bedrooms;
  int bathrooms;
  int balconies;
  int floorNo;
  int totalFloors;
  String ageOfProperty;
  String facing;
  String possessionStatus;
  String furnishingStatus;
  Map<String, int> furnishingItems;
  List<String> amenities;
  String reraNumber;
  bool isLegalOwner;

  String city;
  String locality;
  String societyName;
  String streetAddress;
  String pincode;
  String landmark;
  LatLng pinLocation;

  List<UploadedPhoto> photos;
  UploadedDocument titleDeed;
  UploadedDocument taxReceipt;
  UploadedDocument occupancyCertificate;
  UploadedDocument floorPlan;
  UploadedDocument reraCertificate;

  bool isAgreedToTerms;
  int qualityScore;

  PropertySubmissionModel({
    this.transactionType = 'Sell',
    this.buildingType = 'Residential',
    this.propertyType = 'Apartment',
    this.title = '',
    this.price = 0.0,
    this.rent = 0.0,
    this.securityDeposit = 0.0,
    this.maintenanceAmount = 0.0,
    this.maintenancePeriod = 'Monthly',
    this.configuration = '3 BHK',
    this.carpetArea = 0.0,
    this.superBuiltupArea = 0.0,
    this.areaUnit = 'sq.ft',
    this.bedrooms = 3,
    this.bathrooms = 2,
    this.balconies = 1,
    this.floorNo = 1,
    this.totalFloors = 4,
    this.ageOfProperty = 'New Construction',
    this.facing = 'East',
    this.possessionStatus = 'Ready to Move',
    this.furnishingStatus = 'Semi-Furnished',
    Map<String, int>? furnishingItems,
    List<String>? amenities,
    this.reraNumber = '',
    this.isLegalOwner = false,
    this.city = '',
    this.locality = '',
    this.societyName = '',
    this.streetAddress = '',
    this.pincode = '',
    this.landmark = '',
    LatLng? pinLocation,
    List<UploadedPhoto>? photos,
    UploadedDocument? titleDeed,
    UploadedDocument? taxReceipt,
    UploadedDocument? occupancyCertificate,
    UploadedDocument? floorPlan,
    UploadedDocument? reraCertificate,
    this.isAgreedToTerms = false,
    this.qualityScore = 0,
  })  : furnishingItems = furnishingItems ?? {
          'Ceiling Fan': 3,
          'Air Conditioner': 2,
          'LED Lights': 6,
          'Bed': 2,
          'Modular Kitchen': 1,
        },
        amenities = amenities ?? [
          'Lift',
          '24x7 Security',
          'Power Backup',
          'Car Parking',
          'Gymnasium',
        ],
        pinLocation = pinLocation ?? const LatLng(23.0338, 72.4607),
        photos = photos ??
            [
              UploadedPhoto(label: 'Living Room', isCover: true),
              UploadedPhoto(label: 'Kitchen'),
              UploadedPhoto(label: 'Bedroom'),
            ],
        titleDeed = titleDeed ?? UploadedDocument(),
        taxReceipt = taxReceipt ?? UploadedDocument(),
        occupancyCertificate = occupancyCertificate ?? UploadedDocument(),
        floorPlan = floorPlan ?? UploadedDocument(),
        reraCertificate = reraCertificate ?? UploadedDocument();

  PropertySubmissionModel copyWith({
    String? transactionType,
    String? buildingType,
    String? propertyType,
    String? title,
    double? price,
    double? rent,
    double? securityDeposit,
    double? maintenanceAmount,
    String? maintenancePeriod,
    String? configuration,
    double? carpetArea,
    double? superBuiltupArea,
    String? areaUnit,
    int? bedrooms,
    int? bathrooms,
    int? balconies,
    int? floorNo,
    int? totalFloors,
    String? ageOfProperty,
    String? facing,
    String? possessionStatus,
    String? furnishingStatus,
    Map<String, int>? furnishingItems,
    List<String>? amenities,
    String? reraNumber,
    bool? isLegalOwner,
    String? city,
    String? locality,
    String? societyName,
    String? streetAddress,
    String? pincode,
    String? landmark,
    LatLng? pinLocation,
    List<UploadedPhoto>? photos,
    UploadedDocument? titleDeed,
    UploadedDocument? taxReceipt,
    UploadedDocument? occupancyCertificate,
    UploadedDocument? floorPlan,
    UploadedDocument? reraCertificate,
    bool? isAgreedToTerms,
    int? qualityScore,
  }) {
    return PropertySubmissionModel(
      transactionType: transactionType ?? this.transactionType,
      buildingType: buildingType ?? this.buildingType,
      propertyType: propertyType ?? this.propertyType,
      title: title ?? this.title,
      price: price ?? this.price,
      rent: rent ?? this.rent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      maintenanceAmount: maintenanceAmount ?? this.maintenanceAmount,
      maintenancePeriod: maintenancePeriod ?? this.maintenancePeriod,
      configuration: configuration ?? this.configuration,
      carpetArea: carpetArea ?? this.carpetArea,
      superBuiltupArea: superBuiltupArea ?? this.superBuiltupArea,
      areaUnit: areaUnit ?? this.areaUnit,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      floorNo: floorNo ?? this.floorNo,
      totalFloors: totalFloors ?? this.totalFloors,
      ageOfProperty: ageOfProperty ?? this.ageOfProperty,
      facing: facing ?? this.facing,
      possessionStatus: possessionStatus ?? this.possessionStatus,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      furnishingItems: furnishingItems ?? this.furnishingItems,
      amenities: amenities ?? this.amenities,
      reraNumber: reraNumber ?? this.reraNumber,
      isLegalOwner: isLegalOwner ?? this.isLegalOwner,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      societyName: societyName ?? this.societyName,
      streetAddress: streetAddress ?? this.streetAddress,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      pinLocation: pinLocation ?? this.pinLocation,
      photos: photos ?? this.photos,
      titleDeed: titleDeed ?? this.titleDeed,
      taxReceipt: taxReceipt ?? this.taxReceipt,
      occupancyCertificate: occupancyCertificate ?? this.occupancyCertificate,
      floorPlan: floorPlan ?? this.floorPlan,
      reraCertificate: reraCertificate ?? this.reraCertificate,
      isAgreedToTerms: isAgreedToTerms ?? this.isAgreedToTerms,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }
}

// ==========================================
// 2. VIEWMODEL
// ==========================================
class AgentAddPropertyViewModel extends ChangeNotifier {
  PropertySubmissionModel _model = PropertySubmissionModel();
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  PropertySubmissionModel get model => _model;
  int get currentStep => _currentStep;

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void updateField({
    String? transactionType,
    String? buildingType,
    String? propertyType,
    String? title,
    double? price,
    double? rent,
    double? securityDeposit,
    double? maintenanceAmount,
    String? maintenancePeriod,
    String? configuration,
    double? carpetArea,
    double? superBuiltupArea,
    String? areaUnit,
    int? bedrooms,
    int? bathrooms,
    int? balconies,
    int? floorNo,
    int? totalFloors,
    String? ageOfProperty,
    String? facing,
    String? possessionStatus,
    String? furnishingStatus,
    Map<String, int>? furnishingItems,
    List<String>? amenities,
    String? reraNumber,
    bool? isLegalOwner,
    String? city,
    String? locality,
    String? societyName,
    String? streetAddress,
    String? pincode,
    String? landmark,
    LatLng? pinLocation,
    bool? isAgreedToTerms,
  }) {
    _model = _model.copyWith(
      transactionType: transactionType,
      buildingType: buildingType,
      propertyType: propertyType,
      title: title,
      price: price,
      rent: rent,
      securityDeposit: securityDeposit,
      maintenanceAmount: maintenanceAmount,
      maintenancePeriod: maintenancePeriod,
      configuration: configuration,
      carpetArea: carpetArea,
      superBuiltupArea: superBuiltupArea,
      areaUnit: areaUnit,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      balconies: balconies,
      floorNo: floorNo,
      totalFloors: totalFloors,
      ageOfProperty: ageOfProperty,
      facing: facing,
      possessionStatus: possessionStatus,
      furnishingStatus: furnishingStatus,
      furnishingItems: furnishingItems,
      amenities: amenities,
      reraNumber: reraNumber,
      isLegalOwner: isLegalOwner,
      city: city,
      locality: locality,
      societyName: societyName,
      streetAddress: streetAddress,
      pincode: pincode,
      landmark: landmark,
      pinLocation: pinLocation,
      isAgreedToTerms: isAgreedToTerms,
    );
    notifyListeners();
  }

  void toggleAmenity(String amenity) {
    final current = List<String>.from(_model.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    _model = _model.copyWith(amenities: current);
    notifyListeners();
  }

  void updateFurnishingItem(String item, int delta) {
    final current = Map<String, int>.from(_model.furnishingItems);
    final count = (current[item] ?? 0) + delta;
    if (count <= 0) {
      current.remove(item);
    } else {
      current[item] = count;
    }
    _model = _model.copyWith(furnishingItems: current);
    notifyListeners();
  }

  Future<void> pickAndAddPhoto({bool fromCamera = false, String label = 'Property View'}) async {
    final XFile? image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final updated = List<UploadedPhoto>.from(_model.photos)
        ..add(UploadedPhoto(label: label, imagePath: image.path));
      _model = _model.copyWith(photos: updated);
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    final updated = List<UploadedPhoto>.from(_model.photos)..removeAt(index);
    _model = _model.copyWith(photos: updated);
    notifyListeners();
  }

  Future<void> uploadDocumentDynamic(String key) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final doc = UploadedDocument(
        status: 'uploaded',
        fileName: file.name,
        fileSize: '1.5 MB',
        filePath: file.path,
      );
      if (key == 'titleDeed') {
        _model = _model.copyWith(titleDeed: doc);
      } else if (key == 'taxReceipt') {
        _model = _model.copyWith(taxReceipt: doc);
      } else if (key == 'occupancy') {
        _model = _model.copyWith(occupancyCertificate: doc);
      } else if (key == 'floorPlan') {
        _model = _model.copyWith(floorPlan: doc);
      } else if (key == 'reraCertificate') {
        _model = _model.copyWith(reraCertificate: doc);
      }
      notifyListeners();
    }
  }

  void removeDocument(String key) {
    final doc = UploadedDocument();
    if (key == 'titleDeed') _model = _model.copyWith(titleDeed: doc);
    if (key == 'taxReceipt') _model = _model.copyWith(taxReceipt: doc);
    if (key == 'occupancy') _model = _model.copyWith(occupancyCertificate: doc);
    if (key == 'floorPlan') _model = _model.copyWith(floorPlan: doc);
    if (key == 'reraCertificate') _model = _model.copyWith(reraCertificate: doc);
    notifyListeners();
  }
}

// ==========================================
// 3. MAIN CONTAINER VIEW SCREEN
// ==========================================
class AgentAddPropertyFlowScreen extends StatefulWidget {
  const AgentAddPropertyFlowScreen({super.key});

  @override
  State<AgentAddPropertyFlowScreen> createState() => _AgentAddPropertyFlowScreenState();
}

class _AgentAddPropertyFlowScreenState extends State<AgentAddPropertyFlowScreen> {
  late final AgentAddPropertyViewModel _viewModel;
  late final PageController _pageController;
  GoogleMapController? _googleMapController;
  bool _submitting = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    ensurePartnerHomeController();
    _viewModel = AgentAddPropertyViewModel();
    _pageController = PageController();
    _viewModel.addListener(_onViewModelChanged);
    final args = Get.arguments;
    if (args is Map) {
      final title = args['title']?.toString();
      final city = args['city']?.toString();
      _viewModel.updateField(
        title: (title != null && title.isNotEmpty) ? title : null,
        city: (city != null && city.isNotEmpty) ? city : null,
      );
    }
  }

  void _onViewModelChanged() {
    if (_pageController.hasClients && _pageController.page?.round() != _viewModel.currentStep) {
      _pageController.animateToPage(
        _viewModel.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {}); // 👈 Fixed here (added parentheses)
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _pageController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_viewModel.currentStep < 5) _viewModel.setStep(_viewModel.currentStep + 1);
  }

  void _prevStep() {
    if (_viewModel.currentStep > 0) _viewModel.setStep(_viewModel.currentStep - 1);
  }

  int _bedroomsFrom(String configuration) {
    final match = RegExp(r'(\d+)').firstMatch(configuration);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _mapTransactionType(String uiValue) {
    switch (uiValue.trim().toLowerCase()) {
      case 'sell':
      case 'sale':
        return 'Sale';
      case 'rent':
      case 'lease':
        return 'Rent';
      default:
        return 'Sale';
    }
  }

  String _mapCategory(String propertyType) {
    switch (propertyType.trim().toLowerCase()) {
      case 'commercial':
      case 'office':
      case 'shop':
        return 'Commercial';
      default:
        return 'Residential';
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final service = Get.isRegistered<LocationService>()
          ? Get.find<LocationService>()
          : LocationService();
      final result = await service.getCurrentLocation();
      final point = LatLng(result.latitude, result.longitude);
      _viewModel.updateField(pinLocation: point);
      try {
        _googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 16)),
        );
      } catch (_) {}
      Get.snackbar(
        'Location',
        'Pin updated to your current location',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Location',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submitListing() async {
    if (_submitting) return;
    final m = _viewModel.model;
    if (m.city.trim().isEmpty) {
      Get.snackbar('Error', 'Select a city on the Location step.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (m.carpetArea <= 0) {
      Get.snackbar(
        'Error',
        'Enter a valid carpet area (property size) on the Details step.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final isRent = m.transactionType == 'Rent';
    final effectivePrice = isRent ? (m.rent > 0 ? m.rent : m.price) : m.price;
    if (effectivePrice <= 0) {
      Get.snackbar(
        'Error',
        isRent ? 'Enter a valid monthly rent on the Details step.' : 'Enter a valid property price on the Details step.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final partnerId = Get.isRegistered<PartnerHomeController>()
          ? Get.find<PartnerHomeController>().partnerId.value
          : '';
      final repo = Get.isRegistered<PartnerRepository>()
          ? Get.find<PartnerRepository>()
          : PartnerRepository(ApiService.instance);
      final bedrooms = m.bedrooms > 0 ? m.bedrooms : _bedroomsFrom(m.configuration);
      final apiTransactionType = _mapTransactionType(m.transactionType);
      final apiCategory = _mapCategory(m.buildingType);

      final contractData = {
        'intent': m.transactionType,
        'buildingType': m.buildingType,
        'propertyType': m.propertyType,
        'title': m.title.isEmpty ? '${m.propertyType} in ${m.city}' : m.title,
        'pricing': {
          'expectedPrice': !isRent ? m.price : 0,
          'monthlyRent': isRent ? effectivePrice : 0,
          'securityDeposit': isRent ? m.securityDeposit : 0,
          'maintenanceAmount': m.maintenanceAmount,
          'maintenancePeriod': m.maintenancePeriod,
        },
        'specifications': {
          'configuration': m.configuration,
          'carpetArea': m.carpetArea,
          'superBuiltupArea': m.superBuiltupArea > 0 ? m.superBuiltupArea : m.carpetArea,
          'areaUnit': m.areaUnit,
          'bedrooms': bedrooms,
          'bathrooms': m.bathrooms,
          'balconies': m.balconies,
          'floorNo': m.floorNo,
          'totalFloors': m.totalFloors,
          'facing': m.facing,
          'ageOfProperty': m.ageOfProperty,
          'possessionStatus': m.possessionStatus,
          'reraNumber': m.reraNumber,
        },
        'furnishing': {
          'status': m.furnishingStatus,
          'items': m.furnishingItems.entries
              .where((e) => e.value > 0)
              .map((e) => {'name': e.key, 'quantity': e.value})
              .toList(),
        },
        'amenities': m.amenities,
        'location': {
          'city': m.city,
          'locality': m.locality,
          'society': m.societyName,
          'streetAddress': m.streetAddress,
          'pincode': m.pincode,
          'landmark': m.landmark,
          'latitude': m.pinLocation.latitude,
          'longitude': m.pinLocation.longitude,
        },
      };

      final docPaths = [
        if (m.titleDeed.filePath != null && m.titleDeed.filePath!.isNotEmpty) m.titleDeed.filePath!,
        if (m.taxReceipt.filePath != null && m.taxReceipt.filePath!.isNotEmpty) m.taxReceipt.filePath!,
        if (m.occupancyCertificate.filePath != null && m.occupancyCertificate.filePath!.isNotEmpty) m.occupancyCertificate.filePath!,
      ];

      await repo.createNewProperty(
        {
          if (partnerId.isNotEmpty) 'partnerId': partnerId,
          'title': m.title.isEmpty ? '${m.propertyType} in ${m.city}' : m.title,
          'transactionType': apiTransactionType,
          'category': apiCategory,
          'propertyType': m.propertyType,
          'price': effectivePrice,
          'rent': isRent ? effectivePrice : 0,
          'securityDeposit': isRent ? m.securityDeposit : 0,
          'maintenanceAmount': m.maintenanceAmount,
          'maintenancePeriod': m.maintenancePeriod,
          'configuration': m.configuration,
          'propertySize': m.carpetArea,
          'sizeUnit': m.areaUnit,
          'carpetArea': m.carpetArea,
          'superBuiltupArea': m.superBuiltupArea > 0 ? m.superBuiltupArea : m.carpetArea,
          'bedrooms': bedrooms,
          'bathrooms': m.bathrooms,
          'balconies': m.balconies,
          'floorNo': m.floorNo,
          'totalFloors': m.totalFloors,
          'facing': m.facing,
          'ageOfProperty': m.ageOfProperty,
          'possessionStatus': m.possessionStatus,
          'buildingType': m.buildingType,
          'furnishingStatus': m.furnishingStatus,
          'furnishing': {
            'status': m.furnishingStatus,
            'items': m.furnishingItems.entries
                .where((e) => e.value > 0)
                .map((e) => {'name': e.key, 'quantity': e.value})
                .toList(),
          },
          'furnishingItems': m.furnishingItems.entries
              .where((e) => e.value > 0)
              .map((e) => {'name': e.key, 'quantity': e.value})
              .toList(),
          'amenities': m.amenities.join(', '),
          'reraNumber': m.reraNumber,
          'city': m.city,
          'locality': m.locality,
          'projectName': m.societyName,
          'address': m.streetAddress,
          'pinCode': m.pincode,
          'pincode': m.pincode,
          'landmark': m.landmark,
          'latitude': m.pinLocation.latitude,
          'longitude': m.pinLocation.longitude,
          'status': 'Draft',
          'creatorRole': 'Partner',
          if (partnerId.isNotEmpty) 'creatorId': partnerId,
        },
        imagePaths: m.photos
            .map((p) => p.imagePath)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList(),
        documentPaths: docPaths,
        floorPlanPath: m.floorPlan.filePath,
        reraCertificatePath: m.reraCertificate.filePath,
        contractData: contractData,
      );

      if (Get.isRegistered<PartnerHomeController>()) {
        await Get.find<PartnerHomeController>().loadProperties();
      }
      _nextStep();
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: _viewModel.currentStep == 5 ? _successAppBar() : _defaultAppBar(),
      body: Column(
        children: [
          if (_viewModel.currentStep < 5) _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Details(),
                _buildStep2Location(),
                _buildStep3Photos(),
                _buildStep4Documents(),
                _buildStep5Review(),
                _buildStep6Success(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _defaultAppBar() {
    return AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kDarkNavy),
        onPressed: () {
          if (_viewModel.currentStep > 0 && _viewModel.currentStep < 5) {
            _prevStep();
          } else {
            Get.back();
          }
        },
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, color: kPrimaryTeal, size: 20),
          SizedBox(width: 6),
          Text('DigiNiwas', style: TextStyle(color: kDarkNavy, fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
      centerTitle: false,
      actions: [
        TextButton(
          onPressed: () {
            Get.snackbar(
              'Draft',
              'Use Submit on the review step to save the listing.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          child: const Text('Save Draft', style: TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  PreferredSizeWidget _successAppBar() {
    return AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kDarkNavy),
        onPressed: () => Get.back(),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, color: kPrimaryTeal, size: 20),
          SizedBox(width: 6),
          Text('DigiNiwas', style: TextStyle(color: kDarkNavy, fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: kDarkNavy),
          onPressed: () {
            Get.snackbar(
              'Help',
              'Complete all steps, then submit to create a draft listing.',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Details', 'Location', 'Photos', 'Documents', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: List.generate(5, (index) {
          bool isCompleted = index < _viewModel.currentStep;
          bool isCurrent = index == _viewModel.currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? kPrimaryTeal : (isCurrent ? kDarkNavy : Colors.white),
                        border: Border.all(color: isCompleted ? kPrimaryTeal : (isCurrent ? kDarkNavy : kBorderGrey)),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text('${index + 1}',
                            style: TextStyle(
                                color: isCurrent ? Colors.white : PartnerColors.textTertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[index],
                        style: TextStyle(
                            fontSize: 9,
                            color: isCurrent ? kDarkNavy : PartnerColors.textTertiary,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      height: 1.5,
                      color: index < _viewModel.currentStep ? kPrimaryTeal : kBorderGrey,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // STEP 1: Details
  // ==========================================
  // ==========================================
  // STEP 1: Details (Contract Compliant)
  // ==========================================
  Widget _buildStep1Details() {
    final m = _viewModel.model;
    final isRent = m.transactionType == 'Rent';
    final isResidential = m.buildingType == 'Residential';

    const residentialTypes = [
      'Apartment',
      'House / Villa',
      'Builder Floor',
      'Penthouse',
      'Studio',
      'Plot / Land',
      'Farmhouse',
    ];

    const commercialTypes = [
      'Office Space',
      'Co-working',
      'Shop / Retail',
      'Showroom',
      'Warehouse',
      'Industrial Shed',
    ];

    final currentPropertyTypes = isResidential ? residentialTypes : commercialTypes;

    const furnishingCatalog = [
      'Ceiling Fan',
      'Air Conditioner',
      'LED Lights',
      'Bed',
      'Television (TV)',
      'Refrigerator',
      'Water Purifier (RO)',
      'Geyser',
      'Sofa',
      'Wardrobe',
      'Washing Machine',
      'Microwave',
      'Dining Table',
      'Modular Kitchen',
      'Curtains',
    ];

    const residentialAmenityCatalog = [
      ('Lift', Icons.elevator_outlined),
      ('Power backup', Icons.bolt_outlined),
      ('Security', Icons.security_outlined),
      ('CCTV', Icons.videocam_outlined),
      ('Gated community', Icons.apartment_outlined),
      ('Gym', Icons.fitness_center_outlined),
      ('Swimming pool', Icons.pool_outlined),
      ('Garden / Landscape', Icons.park_outlined),
      ('Visitor parking', Icons.local_parking_outlined),
      ('EV charging', Icons.ev_station_outlined),
    ];

    const commercialAmenityCatalog = [
      ('Lift', Icons.elevator_outlined),
      ('Power backup', Icons.bolt_outlined),
      ('Security', Icons.security_outlined),
      ('CCTV', Icons.videocam_outlined),
      ('Gym', Icons.fitness_center_outlined),
      ('Visitor parking', Icons.local_parking_outlined),
      ('EV charging', Icons.ev_station_outlined),
    ];

    final amenityCatalog = isResidential ? residentialAmenityCatalog : commercialAmenityCatalog;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('STEP 1 OF 5'),
          const SizedBox(height: 4),
          _stepTitle('Tell us about your property'),
          _stepSubtitle('Detailed properties receive 3x more verified buyer enquiries.'),
          const SizedBox(height: 18),

          // CARD 1: Intent & Type
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('I want to'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _selectableChip(
                        'Sell Property',
                        Icons.sell_outlined,
                        m.transactionType == 'Sell',
                        () => _viewModel.updateField(transactionType: 'Sell'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectableChip(
                        'Rent / Lease',
                        Icons.key_outlined,
                        m.transactionType == 'Rent',
                        () => _viewModel.updateField(transactionType: 'Rent'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _fieldLabel('Property Category'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _selectableChip(
                        'Residential',
                        Icons.home_outlined,
                        m.buildingType == 'Residential',
                        () {
                          _viewModel.updateField(
                            buildingType: 'Residential',
                            propertyType: 'Apartment',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _selectableChip(
                        'Commercial',
                        Icons.apartment_outlined,
                        m.buildingType == 'Commercial',
                        () {
                          final currentAmenities = List<String>.from(m.amenities);
                          final allowedCommercial = commercialAmenityCatalog.map((e) => e.$1).toSet();
                          currentAmenities.removeWhere((a) => !allowedCommercial.contains(a));
                          _viewModel.updateField(
                            buildingType: 'Commercial',
                            propertyType: 'Office Space',
                            amenities: currentAmenities,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _fieldLabel('Property Type'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentPropertyTypes.map((type) {
                    final selected = m.propertyType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      selectedColor: kLightTealBg,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: selected ? kPrimaryTeal : kBorderGrey),
                      labelStyle: TextStyle(
                        color: selected ? kPrimaryTeal : kDarkNavy,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _viewModel.updateField(propertyType: type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _fieldLabel('Property Title'),
                const SizedBox(height: 8),
                _textField(
                  hint: 'e.g. Elegant 3 BHK Apartment in Sector 62',
                  initialValue: m.title,
                  onChanged: (val) => _viewModel.updateField(title: val),
                ),
                const SizedBox(height: 14),
                _fieldLabel('RERA Registration No. (Optional)'),
                const SizedBox(height: 8),
                _textField(
                  hint: 'e.g. PR/GJ/AHMEDABAD/12345/2024',
                  initialValue: m.reraNumber,
                  onChanged: (val) => _viewModel.updateField(reraNumber: val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CARD 2: Pricing Details
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRent ? 'Rental & Financial Terms' : 'Sale Pricing Terms',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (!isRent) ...[
                  _fieldLabel('Expected Selling Price *'),
                  const SizedBox(height: 8),
                  _textField(
                    hint: '0',
                    prefix: '₹ ',
                    initialValue: m.price == 0 ? '' : m.price.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _viewModel.updateField(price: double.tryParse(val) ?? 0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Maintenance Charges'),
                            const SizedBox(height: 8),
                            _textField(
                              hint: '0',
                              prefix: '₹ ',
                              initialValue: m.maintenanceAmount == 0 ? '' : m.maintenanceAmount.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => _viewModel.updateField(maintenanceAmount: double.tryParse(val) ?? 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Frequency'),
                            const SizedBox(height: 8),
                            _dropdownField(
                              value: m.maintenancePeriod,
                              items: const ['Monthly', 'Quarterly', 'Yearly', 'One-Time'],
                              onChanged: (val) {
                                if (val != null) _viewModel.updateField(maintenancePeriod: val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _fieldLabel('Expected Monthly Rent *'),
                  const SizedBox(height: 8),
                  _textField(
                    hint: '0',
                    prefix: '₹ ',
                    initialValue: (m.rent > 0 ? m.rent : m.price) == 0 ? '' : (m.rent > 0 ? m.rent : m.price).toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0;
                      _viewModel.updateField(rent: parsed, price: parsed);
                    },
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Security Deposit'),
                  const SizedBox(height: 8),
                  _textField(
                    hint: '0',
                    prefix: '₹ ',
                    initialValue: m.securityDeposit == 0 ? '' : m.securityDeposit.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _viewModel.updateField(securityDeposit: double.tryParse(val) ?? 0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Maintenance Amount'),
                            const SizedBox(height: 8),
                            _textField(
                              hint: '0',
                              prefix: '₹ ',
                              initialValue: m.maintenanceAmount == 0 ? '' : m.maintenanceAmount.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => _viewModel.updateField(maintenanceAmount: double.tryParse(val) ?? 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Frequency'),
                            const SizedBox(height: 8),
                            _dropdownField(
                              value: m.maintenancePeriod,
                              items: const ['Monthly', 'Quarterly', 'Yearly', 'Included in Rent'],
                              onChanged: (val) {
                                if (val != null) _viewModel.updateField(maintenancePeriod: val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CARD 3: Configuration & Measurements
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Specifications & Space',
                  style: TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Configuration'),
                const SizedBox(height: 10),
                _segmentedControl(
                  options: const ['1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK', '6 BHK', '6+ BHK'],
                  selected: m.configuration,
                  onSelect: (val) {
                    final b = _bedroomsFrom(val);
                    _viewModel.updateField(configuration: val, bedrooms: b);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Carpet Area *'),
                          const SizedBox(height: 8),
                          _textField(
                            hint: '0',
                            suffix: m.areaUnit,
                            initialValue: m.carpetArea == 0 ? '' : m.carpetArea.toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _viewModel.updateField(carpetArea: double.tryParse(val) ?? 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Unit'),
                          const SizedBox(height: 8),
                          _dropdownField(
                            value: m.areaUnit,
                            items: const ['sq.ft', 'sq.yard', 'sq.m'],
                            onChanged: (val) {
                              if (val != null) _viewModel.updateField(areaUnit: val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _fieldLabel('Super Built-up Area (Optional)'),
                const SizedBox(height: 8),
                _textField(
                  hint: '0',
                  suffix: m.areaUnit,
                  initialValue: m.superBuiltupArea == 0 ? '' : m.superBuiltupArea.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _viewModel.updateField(superBuiltupArea: double.tryParse(val) ?? 0),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Bedrooms'),
                          const SizedBox(height: 8),
                          _dropdownField(
                            value: '${m.bedrooms}',
                            items: const ['1', '2', '3', '4', '5'],
                            onChanged: (val) => _viewModel.updateField(bedrooms: int.tryParse(val ?? '1') ?? 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Bathrooms'),
                          const SizedBox(height: 8),
                          _dropdownField(
                            value: '${m.bathrooms}',
                            items: const ['1', '2', '3', '4', '5'],
                            onChanged: (val) => _viewModel.updateField(bathrooms: int.tryParse(val ?? '1') ?? 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Balconies'),
                          const SizedBox(height: 8),
                          _dropdownField(
                            value: '${m.balconies}',
                            items: const ['0', '1', '2', '3', '4'],
                            onChanged: (val) => _viewModel.updateField(balconies: int.tryParse(val ?? '0') ?? 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Floor No.'),
                          const SizedBox(height: 8),
                          _textField(
                            hint: '1',
                            initialValue: '${m.floorNo}',
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _viewModel.updateField(floorNo: int.tryParse(val) ?? 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Total Floors'),
                          const SizedBox(height: 8),
                          _textField(
                            hint: '4',
                            initialValue: '${m.totalFloors}',
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _viewModel.updateField(totalFloors: int.tryParse(val) ?? 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _fieldLabel('Facing Direction'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: m.facing,
                  items: const [
                    'East',
                    'North',
                    'West',
                    'South',
                    'North-East',
                    'North-West',
                    'South-East',
                    'South-West',
                  ],
                  onChanged: (val) {
                    if (val != null) _viewModel.updateField(facing: val);
                  },
                ),
                const SizedBox(height: 18),
                _fieldLabel('Age of Property'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: m.ageOfProperty,
                  items: const [
                    'New Construction',
                    '< 1 Year',
                    '1-5 Years',
                    '5-10 Years',
                    '10+ Years',
                  ],
                  onChanged: (val) {
                    if (val != null) _viewModel.updateField(ageOfProperty: val);
                  },
                ),
                const SizedBox(height: 18),
                _fieldLabel('Possession Status'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: m.possessionStatus,
                  items: const ['Ready to Move', 'Under Construction', 'Immediate', 'New Launch'],
                  onChanged: (val) {
                    if (val != null) _viewModel.updateField(possessionStatus: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CARD 4: Furnishing Status & Item Quantities
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Furnishing Details',
                  style: TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _segmentedControl(
                  options: const ['Unfurnished', 'Semi-Furnished', 'Fully-Furnished'],
                  selected: m.furnishingStatus,
                  onSelect: (val) => _viewModel.updateField(furnishingStatus: val),
                ),
                if (m.furnishingStatus != 'Unfurnished') ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _fieldLabel('Furnishing Items & Quantity'),
                      Text(
                        '${m.furnishingItems.length} selected',
                        style: const TextStyle(fontSize: 11, color: kPrimaryTeal, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: furnishingCatalog.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: kBorderGrey),
                    itemBuilder: (context, index) {
                      final item = furnishingCatalog[index];
                      final count = m.furnishingItems[item] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
                                  color: count > 0 ? kDarkNavy : PartnerColors.textSecondary,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: kScaffoldBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBorderGrey),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 14, color: kDarkNavy),
                                    onPressed: count > 0 ? () => _viewModel.updateFurnishingItem(item, -1) : null,
                                    visualDensity: VisualDensity.compact,
                                    splashRadius: 16,
                                  ),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: count > 0 ? kPrimaryTeal : Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 14, color: kDarkNavy),
                                    onPressed: () => _viewModel.updateFurnishingItem(item, 1),
                                    visualDensity: VisualDensity.compact,
                                    splashRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CARD 5: Amenities
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amenities & Features',
                      style: TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 14),
                    ),
                    Text(
                      '${m.amenities.length} selected',
                      style: const TextStyle(fontSize: 11, color: kPrimaryTeal, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenityCatalog.map((item) {
                    final name = item.$1;
                    final icon = item.$2;
                    final selected = m.amenities.contains(name);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: selected ? kPrimaryTeal : PartnerColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(name),
                        ],
                      ),
                      selected: selected,
                      selectedColor: kLightTealBg,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: selected ? kPrimaryTeal : kBorderGrey),
                      labelStyle: TextStyle(
                        color: selected ? kPrimaryTeal : kDarkNavy,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) => _viewModel.toggleAmenity(name),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // OWNER VERIFICATION CHECKBOX
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: m.isLegalOwner,
                onChanged: (val) => _viewModel.updateField(isLegalOwner: val ?? false),
                activeColor: kPrimaryTeal,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: kDarkNavy, height: 1.4),
                      children: [
                        TextSpan(text: 'I am the legal owner or authorized channel partner to list this property.\n'),
                        TextSpan(text: 'Learn about verification requirements', style: TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoBox(
            icon: Icons.info_outline,
            title: 'High-Demand Factor',
            body: 'Properties with verified specifications, detailed furnishings, and complete amenities get shortlisted faster by home seekers.',
          ),
          const SizedBox(height: 20),
          _primaryButton('Continue to Location →', _nextStep),
          const SizedBox(height: 12),
          _secondaryLinkCenter('Save and Exit'),
          const SizedBox(height: 8),
          _footerSecureText(),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: Location
  // ==========================================
  Widget _buildStep2Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('STEP 2 OF 5'),
          const SizedBox(height: 4),
          _stepTitle('Where is your property located?'),
          _stepSubtitle('Accurate location helps buyers find your property quickly.'),
          const SizedBox(height: 20),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('City'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: _viewModel.model.city,
                  items: const ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Indore'],
                  hint: 'Select city',
                  onChanged: (val) => _viewModel.updateField(city: val),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Locality / Area'),
                const SizedBox(height: 8),
                _textField(
                  initialValue: _viewModel.model.locality,
                  onChanged: (val) => _viewModel.updateField(locality: val),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Project / Society Name'),
                const SizedBox(height: 8),
                _textField(
                  initialValue: _viewModel.model.societyName,
                  onChanged: (val) => _viewModel.updateField(societyName: val),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Street Address / Flat No.'),
                const SizedBox(height: 8),
                _textField(
                  hint: 'e.g. A-401, Sector 9',
                  initialValue: _viewModel.model.streetAddress,
                  onChanged: (val) => _viewModel.updateField(streetAddress: val),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Pincode'),
                          const SizedBox(height: 8),
                          _textField(
                            initialValue: _viewModel.model.pincode,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _viewModel.updateField(pincode: val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Nearest Landmark'),
                          const SizedBox(height: 8),
                          _textField(
                            initialValue: _viewModel.model.landmark,
                            onChanged: (val) => _viewModel.updateField(landmark: val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _interactiveMapPreview(),
          const SizedBox(height: 20),
          _infoBox(
            icon: Icons.shield_outlined,
            title: 'Your exact flat number stays private',
            body: 'Buyers only see your locality and society until a site visit is confirmed.',
          ),
          const SizedBox(height: 20),
          _primaryButton('Continue to Photos', _nextStep),
          const SizedBox(height: 12),
          _secondaryLinkRow(left: 'Save and Exit', onLeft: () => Get.back()),
          const SizedBox(height: 8),
          _footerSecureText(),
        ],
      ),
    );
  }

  Widget _interactiveMapPreview() {
    final pin = _viewModel.model.pinLocation;
    final place = [
      if (_viewModel.model.locality.trim().isNotEmpty) _viewModel.model.locality,
      if (_viewModel.model.city.trim().isNotEmpty) _viewModel.model.city,
    ].join(', ');

    final Set<Marker> googleMarkers = {
      Marker(
        markerId: const MarkerId('selected_pin'),
        position: pin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pin location on map',
                style: TextStyle(
                  color: kDarkNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.my_location, size: 16),
              label: Text(_locating ? 'Locating…' : 'Use my location'),
              style: TextButton.styleFrom(foregroundColor: kPrimaryTeal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: pin,
                    zoom: 15.0,
                  ),
                  markers: googleMarkers,
                  onMapCreated: (controller) {
                    _googleMapController = controller;
                  },
                  onTap: (point) {
                    _viewModel.updateField(pinLocation: point);
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    color: Colors.white.withValues(alpha: 0.95),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: kPrimaryTeal),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.isEmpty
                                ? 'Pinned: ${pin.latitude.toStringAsFixed(5)}, ${pin.longitude.toStringAsFixed(5)}'
                                : 'Pinned to: $place',
                            style:
                            const TextStyle(fontSize: 10, color: kGreyText),
                          ),
                        ),
                        const Text(
                          'Tap map to move pin',
                          style: TextStyle(
                            fontSize: 10,
                            color: kPrimaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: Photos
  // ==========================================
  Widget _buildStep3Photos() {
    final photos = _viewModel.model.photos;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photos', style: TextStyle(color: kPrimaryTeal, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          _stepLabel('STEP 3 OF 5'),
          const SizedBox(height: 4),
          _stepTitle('Add high-quality photos of your property'),
          _stepSubtitle('A picture is worth a thousand words. High-quality photos attract 5x more buyers.'),
          const SizedBox(height: 20),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kLightTealBg,
              border: Border.all(color: kPrimaryTeal.withValues(alpha: 0.4), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 32, color: kPrimaryTeal),
                const SizedBox(height: 8),
                const Text('Click or drag and drop photos here',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkNavy)),
                const Text('Max 10 photos, 15MB each. PNG, JPG',
                    style: TextStyle(color: kGreyText, fontSize: 11)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pillOutlineButton(Icons.photo_library_outlined, 'Gallery',
                            () => _viewModel.pickAndAddPhoto(fromCamera: false)),
                    const SizedBox(width: 10),
                    _pillOutlineButton(Icons.camera_alt_outlined, 'Take Photo',
                            () => _viewModel.pickAndAddPhoto(fromCamera: true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Uploaded Photos (${photos.length}/15)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy)),
              GestureDetector(
                onTap: () => _viewModel.pickAndAddPhoto(label: 'Extra Room'),
                child: const Text('+ Add More',
                    style: TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              if (index == photos.length) {
                return GestureDetector(
                  onTap: () => _viewModel.pickAndAddPhoto(label: 'Exterior View'),
                  child: const DottedPlaceholder(label: '+ Exterior View'),
                );
              }
              final photo = photos[index];
              return _photoThumb(photo, index);
            },
          ),
          const SizedBox(height: 20),
          _infoBox(
            icon: Icons.auto_awesome,
            title: 'Pro Tip: Lighting Matters',
            body: 'Take photos in natural daylight. Open all curtains and turn on interior lights to make spaces look larger and more inviting.',
          ),
          const SizedBox(height: 20),
          _primaryButton('Continue to Documents', _nextStep),
          const SizedBox(height: 12),
          _secondaryLinkRow(left: '← Back to Location', onLeft: _prevStep, right: 'Save and Exit', onRight: () {}),
          const SizedBox(height: 8),
          _footerSecureText(),
        ],
      ),
    );
  }

  Widget _photoThumb(UploadedPhoto photo, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo.imagePath != null
              ? Image.file(File(photo.imagePath!), fit: BoxFit.cover)
              : Container(
            color: const Color(0xFFB9D8CF),
            child: const Center(child: Icon(Icons.image, color: Colors.white70, size: 30)),
          ),
          if (photo.isCover)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: kPrimaryTeal, borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text('Cover Photo', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _viewModel.removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                ),
              ),
              child: Text(photo.label,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4: Documents
  // ==========================================
  // ==========================================
  // STEP 4: Documents
  // ==========================================
  Widget _buildStep4Documents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('STEP 4 OF 5'),
          const SizedBox(height: 4),
          _stepTitle('Upload property documents'),
          _stepSubtitle("Uploading verified documents speeds up approval and helps you earn the 'DigiNiwas Verified' badge."),
          const SizedBox(height: 20),
          _documentCard(
            title: 'Title Deed / Index II Copy',
            required: true,
            subtitle: 'Proof of ownership. PDF, JPG, PNG (Max 10MB)',
            doc: _viewModel.model.titleDeed,
            onUpload: () => _viewModel.uploadDocumentDynamic('titleDeed'),
            onRemove: () => _viewModel.removeDocument('titleDeed'),
          ),
          const SizedBox(height: 14),
          _documentCard(
            title: 'Latest Property Tax Receipt',
            required: false,
            optionalTag: true,
            subtitle: 'Tax payment receipt for credibility. PDF, JPG (Max 10MB)',
            doc: _viewModel.model.taxReceipt,
            onUpload: () => _viewModel.uploadDocumentDynamic('taxReceipt'),
            onRemove: () => _viewModel.removeDocument('taxReceipt'),
          ),
          const SizedBox(height: 14),
          _documentCard(
            title: 'Occupancy Certificate (OC)',
            required: false,
            optionalTag: true,
            subtitle: 'Recommended for completed projects. PDF, JPG (Max 10MB)',
            doc: _viewModel.model.occupancyCertificate,
            onUpload: () => _viewModel.uploadDocumentDynamic('occupancy'),
            onRemove: () => _viewModel.removeDocument('occupancy'),
          ),
          const SizedBox(height: 14),
          _documentCard(
            title: 'Floor Plan / Layout Blueprint',
            required: false,
            optionalTag: true,
            subtitle: 'Blueprints help buyers understand room sizes. PDF, JPG, PNG',
            doc: _viewModel.model.floorPlan,
            onUpload: () => _viewModel.uploadDocumentDynamic('floorPlan'),
            onRemove: () => _viewModel.removeDocument('floorPlan'),
          ),
          const SizedBox(height: 14),
          _documentCard(
            title: 'RERA Registration Certificate',
            required: false,
            optionalTag: true,
            subtitle: 'State RERA certificate for trust and verification.',
            doc: _viewModel.model.reraCertificate,
            onUpload: () => _viewModel.uploadDocumentDynamic('reraCertificate'),
            onRemove: () => _viewModel.removeDocument('reraCertificate'),
          ),
          const SizedBox(height: 20),
          _infoBox(
            icon: Icons.verified_user_outlined,
            title: 'DigiNiwas Trust & Privacy Promise',
            body: 'Your documents are used for verification in accordance with our Privacy Policy and are not displayed publicly.',
          ),
          const SizedBox(height: 20),
          _primaryButton('Continue to Preview →', _nextStep),
          const SizedBox(height: 12),
          _secondaryLinkRow(left: '← Back to Photos', onLeft: _prevStep, right: 'Save and Exit', onRight: () {}),
          const SizedBox(height: 8),
          _footerSecureText(text: 'Your documents are 256-bit encrypted and secure.'),
        ],
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required bool required,
    bool optionalTag = false,
    String? subtitle,
    required UploadedDocument doc,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    final isUploaded = doc.status == 'uploaded';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isUploaded ? Icons.shield_outlined : Icons.description_outlined,
                  color: isUploaded ? kPrimaryTeal : kDarkNavy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 14),
                    children: [
                      TextSpan(text: title),
                      if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent)),
                      if (optionalTag)
                        const TextSpan(text: '  (Optional)', style: TextStyle(color: kGreyText, fontWeight: FontWeight.normal, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              if (isUploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kLightTealBg, borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: kPrimaryTeal),
                      SizedBox(width: 3),
                      Text('Uploaded', style: TextStyle(color: kPrimaryTeal, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(subtitle, style: const TextStyle(color: kGreyText, fontSize: 11)),
            ),
          ],
          const SizedBox(height: 12),
          if (isUploaded)
            Row(
              children: [
                const Icon(Icons.insert_drive_file, size: 16, color: kGreyText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${doc.fileName} (${doc.fileSize})',
                      style: const TextStyle(fontSize: 12, color: kDarkNavy), overflow: TextOverflow.ellipsis),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: onUpload,
              style: OutlinedButton.styleFrom(
                foregroundColor: kDarkNavy,
                side: const BorderSide(color: kBorderGrey),
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload File', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 5: Review
  // ==========================================
  Widget _buildStep5Review() {
    final m = _viewModel.model;
    final isRent = m.transactionType == 'Rent';
    final effectivePrice = isRent ? (m.rent > 0 ? m.rent : m.price) : m.price;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('REVIEW'),
          const SizedBox(height: 4),
          _stepTitle('Review your listing details'),
          _stepSubtitle('Please double-check everything before submitting for verification.'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kLightTealBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: kPrimaryTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Listing Completeness: ${m.qualityScore > 0 ? m.qualityScore : 95}/100 (Ready to Publish)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 13)),
                      const SizedBox(height: 2),
                      const Text('All mandatory details and documents are captured. Verified listings go live on DigiNiwas for instant buyer discovery.',
                          style: TextStyle(fontSize: 11, color: kGreyText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Basic Info
          _reviewSection(
            title: 'Basic Information',
            onEdit: () => _viewModel.setStep(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _reviewKV('Category', '${m.buildingType} (${m.transactionType})')),
                    Expanded(child: _reviewKV('Property Type', m.propertyType)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _reviewKV('Title', m.title.isEmpty ? '${m.propertyType} in ${m.city}' : m.title)),
                    Expanded(child: _reviewKV('Project / Society', m.societyName.isEmpty ? 'Not specified' : m.societyName)),
                  ],
                ),
                if (m.reraNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _reviewKV('RERA ID', m.reraNumber),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Pricing
          _reviewSection(
            title: isRent ? 'Rental & Financial Terms' : 'Pricing Terms',
            onEdit: () => _viewModel.setStep(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _reviewKV(
                        isRent ? 'Monthly Rent' : 'Expected Price',
                        '₹${effectivePrice.toStringAsFixed(0)}',
                      ),
                    ),
                    if (isRent)
                      Expanded(
                        child: _reviewKV(
                          'Security Deposit',
                          m.securityDeposit > 0 ? '₹${m.securityDeposit.toStringAsFixed(0)}' : 'Not required',
                        ),
                      ),
                  ],
                ),
                if (m.maintenanceAmount > 0) ...[
                  const SizedBox(height: 12),
                  _reviewKV('Maintenance', '₹${m.maintenanceAmount.toStringAsFixed(0)} (${m.maintenancePeriod})'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Specifications
          _reviewSection(
            title: 'Specifications & Layout',
            onEdit: () => _viewModel.setStep(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _reviewKV('Configuration', m.configuration)),
                    Expanded(child: _reviewKV('Carpet Area', '${m.carpetArea.toStringAsFixed(0)} ${m.areaUnit}')),
                  ],
                ),
                if (m.superBuiltupArea > 0) ...[
                  const SizedBox(height: 12),
                  _reviewKV('Super Built-up Area', '${m.superBuiltupArea.toStringAsFixed(0)} ${m.areaUnit}'),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _reviewKV('Bedrooms', '${m.bedrooms}')),
                    Expanded(child: _reviewKV('Bathrooms', '${m.bathrooms}')),
                    Expanded(child: _reviewKV('Balconies', '${m.balconies}')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _reviewKV('Floor', 'Floor ${m.floorNo} of ${m.totalFloors}')),
                    Expanded(child: _reviewKV('Facing', m.facing)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _reviewKV('Age of Property', m.ageOfProperty)),
                    Expanded(child: _reviewKV('Possession', m.possessionStatus)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Furnishing & Items
          _reviewSection(
            title: 'Furnishing Details',
            onEdit: () => _viewModel.setStep(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewKV('Status', m.furnishingStatus),
                if (m.furnishingStatus != 'Unfurnished' && m.furnishingItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: m.furnishingItems.entries.map((entry) {
                      return Chip(
                        label: Text('${entry.key} × ${entry.value}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDarkNavy)),
                        backgroundColor: kLightTealBg,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Amenities
          if (m.amenities.isNotEmpty) ...[
            _reviewSection(
              title: 'Amenities (${m.amenities.length})',
              onEdit: () => _viewModel.setStep(0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: m.amenities.map((item) {
                  return Chip(
                    avatar: const Icon(Icons.check_circle, size: 14, color: kPrimaryTeal),
                    label: Text(item, style: const TextStyle(fontSize: 11, color: kDarkNavy)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: kBorderGrey),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Location
          _reviewSection(
            title: 'Location Details',
            onEdit: () => _viewModel.setStep(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.societyName.isNotEmpty
                      ? '${m.societyName}, ${m.streetAddress}'
                      : (m.streetAddress.isNotEmpty ? m.streetAddress : 'Address pinned on map'),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kDarkNavy, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.locality.isNotEmpty ? "${m.locality}, " : ""}${m.city} (${m.pincode})',
                  style: const TextStyle(color: kGreyText, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 13, color: kPrimaryTeal),
                    SizedBox(width: 4),
                    Text('Exact GPS pin stored with listing', style: TextStyle(fontSize: 11, color: kPrimaryTeal)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Photos
          _reviewSection(
            title: 'Photos (${m.photos.length})',
            onEdit: () => _viewModel.setStep(2),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: m.photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) => _photoThumb(m.photos[index], index),
            ),
          ),
          const SizedBox(height: 14),

          // Submitted Documents
          _reviewSection(
            title: 'Submitted Documents',
            onEdit: () => _viewModel.setStep(3),
            child: Column(
              children: [
                _reviewDocRow('Title Deed / Index II', m.titleDeed.status == 'uploaded'),
                const SizedBox(height: 8),
                _reviewDocRow('Latest Property Tax Receipt', m.taxReceipt.status == 'uploaded'),
                const SizedBox(height: 8),
                _reviewDocRow('Occupancy Certificate (OC)', m.occupancyCertificate.status == 'uploaded'),
                const SizedBox(height: 8),
                _reviewDocRow('Floor Plan / Blueprint', m.floorPlan.status == 'uploaded'),
                const SizedBox(height: 8),
                _reviewDocRow('RERA Certificate', m.reraCertificate.status == 'uploaded'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: m.isAgreedToTerms,
                onChanged: (val) => _viewModel.updateField(isAgreedToTerms: val ?? false),
                activeColor: kPrimaryTeal,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: kDarkNavy, height: 1.4),
                      children: [
                        const TextSpan(text: 'I confirm that the information provided is accurate and I am the authorized owner/agent for this property. I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions.',
                          style: const TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(AppRoutes.termsOfService),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _primaryButton(
            _submitting ? 'Submitting…' : 'Submit Listing for Review →',
            _submitting ? () {} : _submitListing,
          ),
          const SizedBox(height: 12),
          _secondaryLinkCenter('Save and Exit'),
          const SizedBox(height: 8),
          _footerSecureText(text: 'Your listing is backed by DigiNiwas Verified Buyer Guarantee.'),
        ],
      ),
    );
  }

  Widget _reviewDocRow(String label, bool uploaded) {
    return Row(
      children: [
        Icon(uploaded ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15, color: uploaded ? kPrimaryTeal : kGreyText),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: kDarkNavy))),
        Text(uploaded ? '(Uploaded)' : '(Pending)',
            style: TextStyle(fontSize: 11, color: uploaded ? kPrimaryTeal : Colors.orange)),
      ],
    );
  }

  Widget _reviewKV(String key, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key, style: const TextStyle(fontSize: 11, color: kGreyText)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDarkNavy)),
      ],
    );
  }

  Widget _reviewSection({required String title, required VoidCallback onEdit, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 14)),
              GestureDetector(
                onTap: onEdit,
                child: const Text('Edit', style: TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ==========================================
  // STEP 6: Success
  // ==========================================
  Widget _buildStep6Success() {
    final m = _viewModel.model;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, color: Colors.grey.shade300),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: kLightTealBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: kPrimaryTeal, size: 34),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Property Submitted',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: kDarkNavy)),
          const SizedBox(height: 8),
          const Text('Your property details have been securely received and are being processed.',
              textAlign: TextAlign.center, style: TextStyle(color: kGreyText, fontSize: 13)),
          const SizedBox(height: 22),
          _propertySummaryCard(m),
          const SizedBox(height: 20),
          _partnerAssignmentCard(),
          const SizedBox(height: 24),
          _primaryButton('Go to My Properties →', () => _viewModel.setStep(0)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Get.offAllNamed(AppRoutes.partnerDashboard),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBorderGrey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Return to Home', style: TextStyle(color: kDarkNavy, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 14),
          _footerSecureText(text: 'Your personal contact details are securely stored and will not be shared directly with buyers without your explicit consent.'),
        ],
      ),
    );
  }

  Widget _propertySummaryCard(PropertySubmissionModel m) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E63), Color(0xFF0F1B2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(child: Icon(Icons.apartment, color: Colors.white24, size: 50)),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: kPrimaryTeal, borderRadius: BorderRadius.circular(6)),
                  child: const Text('For Sale', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.societyName.isEmpty ? 'Green Valley Residency' : m.societyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDarkNavy)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: kGreyText),
                    const SizedBox(width: 3),
                    Text('${m.locality}, ${m.city}', style: const TextStyle(fontSize: 12, color: kGreyText)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('₹${m.price == 0 ? "1.40 Cr" : m.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kDarkNavy)),
                    const SizedBox(width: 8),
                    Text('• ${m.configuration}', style: const TextStyle(fontSize: 12, color: kGreyText)),
                    const SizedBox(width: 4),
                    Text('• ${m.carpetArea == 0 ? "1,850" : m.carpetArea.toStringAsFixed(0)} sq.ft',
                        style: const TextStyle(fontSize: 12, color: kGreyText)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: kLightTealBg, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Text('Listing Reference  #DN-AZ-1048',
                      style: TextStyle(fontSize: 11, color: kPrimaryTeal, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerAssignmentCard() {
    const stages = ['Submitted', 'Assigned', 'Verified', 'Live'];
    const currentStageIndex = 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_outlined, color: kDarkNavy, size: 18),
              SizedBox(width: 8),
              Text('Partner Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(stages.length, (i) {
              final done = i < currentStageIndex;
              final current = i == currentStageIndex;
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done ? kPrimaryTeal : (current ? kLightTealBg : Colors.white),
                            border: Border.all(color: done || current ? kPrimaryTeal : kBorderGrey),
                          ),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : Icon(Icons.circle, size: 8, color: current ? kPrimaryTeal : kBorderGrey),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(stages[i],
                            style: TextStyle(
                                fontSize: 9,
                                color: current ? kPrimaryTeal : kGreyText,
                                fontWeight: current ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                    if (i < stages.length - 1)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          height: 1.5,
                          color: i < currentStageIndex ? kPrimaryTeal : kBorderGrey,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kLightTealBg,
                child: Icon(Icons.person, color: kPrimaryTeal),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Arjun Khanna', style: TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.verified, size: 13, color: kPrimaryTeal),
                      ],
                    ),
                    Text('Senior Property Partner', style: TextStyle(fontSize: 11, color: kGreyText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Chat',
                        'Use unlocked lead contact details to message buyers.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 15, color: Colors.white),
                    label: const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Call',
                        'Use unlocked lead contact details to call buyers.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kBorderGrey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 15, color: kDarkNavy),
                    label: const Text('Call', style: TextStyle(color: kDarkNavy, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED WIDGET HELPERS
  // ==========================================
  Widget _stepLabel(String text) =>
      Text(text, style: const TextStyle(color: kPrimaryTeal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5));

  Widget _stepTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: kDarkNavy, height: 1.3));

  Widget _stepSubtitle(String text) =>
      Padding(padding: const EdgeInsets.only(top: 4), child: Text(text, style: const TextStyle(color: kGreyText, fontSize: 12.5)));

  Widget _fieldLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 13));

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderGrey)),
    child: child,
  );

  Widget _textField({
    String? hint,
    String? initialValue,
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      textAlign: TextAlign.center,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: kDarkNavy, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        hintStyle: TextStyle(color: PartnerColors.textTertiary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorderGrey)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorderGrey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryTeal)),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String hint = 'Select',
  }) {
    final selected = items.contains(value) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Text(hint, style: TextStyle(color: PartnerColors.textTertiary, fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: kGreyText),
          style: const TextStyle(color: kDarkNavy, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _segmentedControl({required List<String> options, required String selected, required ValueChanged<String> onSelect}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kScaffoldBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    opt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kDarkNavy,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _selectableChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? kLightTealBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kPrimaryTeal : kBorderGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: isSelected ? kPrimaryTeal : PartnerColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: TextStyle(color: kDarkNavy, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillOutlineButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: kDarkNavy,
        backgroundColor: Colors.white,
        side: const BorderSide(color: kBorderGrey),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoBox({required IconData icon, required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kLightTealBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryTeal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkNavy, fontSize: 12.5)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(fontSize: 11.5, color: kGreyText, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkNavy,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _secondaryLinkCenter(String text) {
    return Center(
      child: TextButton(
        onPressed: () {
          if (text.toLowerCase().contains('cancel') ||
              text.toLowerCase().contains('back') ||
              text.toLowerCase().contains('exit')) {
            Get.back();
          } else if (text.toLowerCase().contains('home') ||
              text.toLowerCase().contains('dashboard')) {
            Get.offAllNamed(AppRoutes.partnerDashboard);
          } else {
            Get.back();
          }
        },
        child: Text(text, style: const TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _secondaryLinkRow({required String left, required VoidCallback onLeft, String? right, VoidCallback? onRight}) {
    return Row(
      mainAxisAlignment: right != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        TextButton(onPressed: onLeft, child: Text(left, style: const TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.bold, fontSize: 13))),
        if (right != null)
          TextButton(onPressed: onRight, child: Text(right, style: const TextStyle(color: kPrimaryTeal, fontWeight: FontWeight.bold, fontSize: 13))),
      ],
    );
  }

  Widget _footerSecureText({String text = 'Your information is securely saved.'}) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 11, color: kGreyText),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: kGreyText)),
          ),
        ],
      ),
    );
  }
}

// Fixed Dotted Placeholder Tile (Error-free)
class DottedPlaceholder extends StatelessWidget {
  final String label;
  const DottedPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: kGreyText, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: kGreyText, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBorderGrey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}