import '../../../core/widgets/app_toast.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/buyer_home_controller.dart';
import '../models/property_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/utils/shimmer.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import 'compare_properties_screen.dart';
import 'select_city_screen.dart';

class SavedPropertiesScreen extends StatelessWidget {
  SavedPropertiesScreen({super.key});

  // GetX Controller instance access
  final BuyerHomeController controller = Get.find<BuyerHomeController>();

  // Map to track selection state for comparison (Local UI state per property id)
  final RxMap<String, bool> _comparedSelectionMap = <String, bool>{}.obs;

  // NEW: Sort state
  final RxString _sortOption = 'Recently Saved'.obs;

  // NEW: Quick locality chip filter
  final RxString _selectedLocality = 'All Localities'.obs;

  // NEW: Full filter set — same fields as the Explore screen's filter sheet
  // (Transaction Type, Category, City, Price Range, Verified-only)
  final RxnString _filterTransactionType = RxnString();
  final RxnString _filterCategory = RxnString();
  final RxString _filterCity = ''.obs;
  final Rxn<num> _filterMinPrice = Rxn<num>();
  final Rxn<num> _filterMaxPrice = Rxn<num>();
  final RxBool _filterVerifiedOnly = false.obs;

  // Minimum number of properties required to start a comparison
  static const int _minCompareCount = 2;

  int get _selectedCount =>
      _comparedSelectionMap.values.where((selected) => selected == true).length;

  bool get _isAnyAdvancedFilterActive =>
      _filterTransactionType.value != null ||
          _filterCategory.value != null ||
          _filterCity.value.trim().isNotEmpty ||
          _filterMinPrice.value != null ||
          _filterMaxPrice.value != null ||
          _filterVerifiedOnly.value == true;

  /// Helper to reliably extract the property ID regardless of object nesting
  String _getPropertyId(dynamic item) {
    if (item is PropertyModel && item.id.isNotEmpty) return item.id;
    if (item is Map) {
      for (final key in ['_id', 'id', 'propertyId', 'propertyCode']) {
        final val = item[key]?.toString();
        if (val != null && val.trim().isNotEmpty) return val.trim();
      }
      if (item['property'] is Map) {
        final p = item['property'];
        for (final key in ['_id', 'id', 'propertyId', 'propertyCode']) {
          final val = p[key]?.toString();
          if (val != null && val.trim().isNotEmpty) return val.trim();
        }
      }
      if (item['propertySnapshot'] is Map) {
        final snap = item['propertySnapshot'];
        for (final key in ['_id', 'id', 'propertyId', 'propertyCode']) {
          final val = snap[key]?.toString();
          if (val != null && val.trim().isNotEmpty) return val.trim();
        }
      }
    }
    final model = PropertyModel.fromDynamic(item);
    if (model.id.isNotEmpty) return model.id;
    if (model.propertyCode.isNotEmpty) return model.propertyCode;
    return 'prop_${identityHashCode(item)}';
  }

  void _openComparisonScreen(BuildContext context, List<dynamic> savedList) {
    final selectedItems = savedList.where((item) {
      final id = _getPropertyId(item);
      return id.isNotEmpty && _comparedSelectionMap[id] == true;
    }).toList();

    // At least 2 properties are required for a comparison
    if (selectedItems.length < _minCompareCount) {
      AppToast.showWarning('Please select at least 2 properties to compare.');





      return;
    }

    Get.to(() => ComparePropertiesScreen(comparedProperties: selectedItems));
  }

  void _toggleCompareAll(List<dynamic> savedList) {
    final bool selectAll = _selectedCount != savedList.length;
    for (var item in savedList) {
      final id = _getPropertyId(item);
      if (id.isNotEmpty) {
        _comparedSelectionMap[id] = selectAll;
      }
    }
  }

  Future<String?> _getBuyerId() async {
    String? buyerId = await StorageService.instance.buyerId;
    if (buyerId == null || buyerId.isEmpty) {
      buyerId = await StorageService.instance.userId;
    }
    if (buyerId == null || buyerId.isEmpty) {
      final userJson = await SecureStorageService.instance.getUserData();
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          buyerId = userMap['id']?.toString() ??
              userMap['_id']?.toString() ??
              userMap['buyerId']?.toString();
        } catch (_) {}
      }
    }
    return buyerId;
  }

  // ---------------------------------------------------------------------
  // Helpers to read property fields from a saved-list item
  // ---------------------------------------------------------------------
  dynamic _propertyDataOf(dynamic item) {
    return (item is Map && item['propertySnapshot'] != null)
        ? item['propertySnapshot']
        : (item is Map && item['property'] != null ? item['property'] : item);
  }

  DateTime? _savedDateOf(dynamic item) {
    dynamic raw;
    if (item is Map) {
      raw = item['createdAt'] ?? item['savedAt'] ?? item['updatedAt'];
      if (raw == null) {
        final propertyData = _propertyDataOf(item);
        if (propertyData is Map) {
          raw = propertyData['createdAt'] ?? propertyData['savedAt'];
        }
      }
    }
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  String _localityOf(dynamic item) {
    final model = PropertyModel.fromDynamic(item);
    if (model.locality.isNotEmpty && model.locality != 'Unknown') return model.locality;
    final propertyData = _propertyDataOf(item);
    final locality = (propertyData is Map) ? propertyData['locality']?.toString().trim() : null;
    return (locality == null || locality.isEmpty) ? 'Unknown' : locality;
  }

  num? _priceOf(dynamic item) {
    final model = PropertyModel.fromDynamic(item);
    if (model.priceAmount != null && model.priceAmount! > 0) return model.priceAmount;
    final propertyData = _propertyDataOf(item);
    final raw = (propertyData is Map) ? propertyData['price'] : null;
    if (raw == null) return null;
    return num.tryParse(raw.toString());
  }

  List<String> _availableLocalities(List<dynamic> savedList) {
    final Set<String> localities = {};
    for (var item in savedList) {
      localities.add(_localityOf(item));
    }
    final sorted = localities.toList()..sort();
    return ['All Localities', ...sorted];
  }

  /// Applies locality chip + advanced filter sheet + sort to the raw saved list.
  List<dynamic> _applyFiltersAndSort(List<dynamic> savedList) {
    List<dynamic> result = List<dynamic>.from(savedList);

    // 1. Quick locality chip filter
    if (_selectedLocality.value != 'All Localities') {
      result = result.where((item) => _localityOf(item) == _selectedLocality.value).toList();
    }

    // 2. Advanced filters (Transaction Type, Category, City, Price Range, Verified)
    if (_filterTransactionType.value != null) {
      final tFilter = _filterTransactionType.value!.toLowerCase();
      result = result.where((item) {
        final model = PropertyModel.fromDynamic(item);
        if (model.transactionType.toLowerCase() == tFilter) return true;
        final propertyData = _propertyDataOf(item);
        final t = (propertyData is Map) ? propertyData['transactionType']?.toString() : null;
        return t?.toLowerCase() == tFilter;
      }).toList();
    }

    if (_filterCategory.value != null) {
      final cFilter = _filterCategory.value!.toLowerCase();
      result = result.where((item) {
        final model = PropertyModel.fromDynamic(item);
        if (model.category.toLowerCase() == cFilter) return true;
        final propertyData = _propertyDataOf(item);
        final c = (propertyData is Map) ? propertyData['category']?.toString() : null;
        return c?.toLowerCase() == cFilter;
      }).toList();
    }

    if (_filterCity.value.trim().isNotEmpty) {
      final query = _filterCity.value.trim().toLowerCase();
      result = result.where((item) {
        final model = PropertyModel.fromDynamic(item);
        final city = model.city.toLowerCase();
        final address = model.address.toLowerCase();
        final locality = model.locality.toLowerCase();
        final location = model.formattedLocation.toLowerCase();

        // Also check raw map objects if available
        String rawCity = '';
        String rawAddress = '';
        String rawLocality = '';
        if (item is Map) {
          final prop = item['property'] is Map ? item['property'] : null;
          final snap = item['propertySnapshot'] is Map ? item['propertySnapshot'] : null;
          rawCity = (prop?['city'] ?? snap?['city'] ?? item['city'])?.toString().toLowerCase() ?? '';
          rawAddress = (prop?['address'] ?? snap?['address'] ?? item['address'])?.toString().toLowerCase() ?? '';
          rawLocality = (prop?['locality'] ?? snap?['locality'] ?? item['locality'])?.toString().toLowerCase() ?? '';
        }

        return city.contains(query) ||
            address.contains(query) ||
            locality.contains(query) ||
            location.contains(query) ||
            rawCity.contains(query) ||
            rawAddress.contains(query) ||
            rawLocality.contains(query);
      }).toList();
    }

    if (_filterMinPrice.value != null) {
      result = result.where((item) {
        final price = _priceOf(item);
        return price != null && price >= _filterMinPrice.value!;
      }).toList();
    }

    if (_filterMaxPrice.value != null) {
      result = result.where((item) {
        final price = _priceOf(item);
        return price != null && price <= _filterMaxPrice.value!;
      }).toList();
    }

    if (_filterVerifiedOnly.value == true) {
      result = result.where((item) {
        final model = PropertyModel.fromDynamic(item);
        if (model.isVerified) return true;
        final propertyData = _propertyDataOf(item);
        final status = (propertyData is Map) ? propertyData['propertyVerificationStatus']?.toString() : null;
        return status?.toLowerCase() == 'verified';
      }).toList();
    }

    // 3. Sort by saved date (falls back to list/insertion order if no dates present)
    final bool anyDateAvailable = savedList.any((item) => _savedDateOf(item) != null);

    if (anyDateAvailable) {
      result.sort((a, b) {
        final da = _savedDateOf(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = _savedDateOf(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _sortOption.value == 'Recently Saved' ? db.compareTo(da) : da.compareTo(db);
      });
    } else {
      // No timestamps returned by the API — assume the backend returns items in the
      // order they were saved (oldest first), so "Recently Saved" = reversed order.
      if (_sortOption.value == 'Recently Saved') {
        result = result.reversed.toList();
      }
    }

    return result;
  }

  void _openFilterSheet(BuildContext context, List<dynamic> savedList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedFilterBottomSheet(
        initialTransactionType: _filterTransactionType.value,
        initialCategory: _filterCategory.value,
        initialCity: _filterCity.value,
        initialMinPrice: _filterMinPrice.value,
        initialMaxPrice: _filterMaxPrice.value,
        initialVerifiedOnly: _filterVerifiedOnly.value,
        onReset: () {
          _filterTransactionType.value = null;
          _filterCategory.value = null;
          _filterCity.value = '';
          _filterMinPrice.value = null;
          _filterMaxPrice.value = null;
          _filterVerifiedOnly.value = false;
        },
        onApply: ({
          required String? transactionType,
          required String? category,
          required String city,
          required num? minPrice,
          required num? maxPrice,
          required bool verifiedOnly,
        }) {
          _filterTransactionType.value = transactionType;
          _filterCategory.value = category;
          _filterCity.value = city;
          _filterMinPrice.value = minPrice;
          _filterMaxPrice.value = maxPrice;
          _filterVerifiedOnly.value = verifiedOnly;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Saved tab me ho to Home screen ka PopScope Home tab par le jayega
        if (controller.bottomNavIndex.value == 3) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildTopAppBar(context),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Obx(() {
            if (controller.savedPropertiesLoading.value) {
              return const SavedPropertyShimmer();
            }

            final savedList = controller.savedPropertiesList;

            if (savedList.isEmpty) {
              return AppEmptyState(
                type: EmptyStateType.saved,
                title: 'No Saved Properties Yet',
                message: 'Tap the heart icon on any property to save it here for quick access and side-by-side comparison.',
                actionLabel: 'Explore Properties',
                onAction: () => controller.changeBottomNavIndex(0),
              );
            }

            // Apply locality chip + advanced filters + sort before rendering
            final displayList = _applyFiltersAndSort(savedList);

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 110.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, savedList, displayList),
                      SizedBox(height: 12.h),
                      _buildAiPortfolioInsight(),
                      SizedBox(height: 16.h),
                      if (displayList.isEmpty)
                        _buildNoMatchState()
                      else
                        ...displayList.asMap().entries.map(
                              (entry) => StaggeredItemEntrance(
                            index: entry.key,
                            child: _buildSavedPropertyCard(context, entry.value),
                          ),
                        ),
                    ],
                  ),
                ),

                // Floating Action Bar — only when at least 2 properties are selected
                if (_selectedCount >= _minCompareCount)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    bottom: 30.h,
                    child: _buildComparisonBar(context, displayList),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNoMatchState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: AppEmptyState(
        type: EmptyStateType.search,
        imageSize: 90,
        title: 'No Matching Saved Properties',
        message: 'No saved properties match your active filters or selected locality.',
        actionLabel: 'Clear All Filters',
        onAction: () {
          _selectedLocality.value = 'All Localities';
          _filterTransactionType.value = null;
          _filterCategory.value = null;
          _filterCity.value = '';
          _filterMinPrice.value = null;
          _filterMaxPrice.value = null;
          _filterVerifiedOnly.value = false;
        },
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 38.w + 20.w, // Button size + Left padding
      leading: Padding(
        padding: EdgeInsets.only(left: 10.w), // Left side 10 padding
        child: AppAdaptiveBackButton(
          color: const Color(0xFF0F172A),
          onPressed: () {
            // Saved tab hai (3) -> Home tab par jao, warna normal pop
            if (controller.bottomNavIndex.value == 3) {
              controller.changeBottomNavIndex(0);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
          },
        ),
      ),
      title: Text(
        'Saved Properties',
        style: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      centerTitle: true, // Title ko center mein karne ke liye
      actions: [
        SizedBox(width: 10.w), // Right side 10 padding
      ],
    );
  }

  Widget _buildHeader(BuildContext context, List<dynamic> savedList, List<dynamic> displayList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
              () => Text(
            displayList.length == savedList.length
                ? '${savedList.length} Properties Saved'
                : '${displayList.length} of ${savedList.length} Properties Saved',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Updated recently from your wishlist',
          style: GoogleFonts.poppins(
            fontSize: 11.5.sp,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 10.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              _buildSortDropdownChip(),
              SizedBox(width: 8.w),
              _buildLocalityDropdownChip(savedList),
              SizedBox(width: 8.w),
              _buildCityDropdownChip(context),
              SizedBox(width: 8.w),
              _buildFiltersChip(context, savedList),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => _toggleCompareAll(displayList),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2544),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 14.sp),
                      SizedBox(width: 4.w),
                      Obx(
                            () => Text(
                          _selectedCount == displayList.length && displayList.isNotEmpty
                              ? 'Deselect All'
                              : 'Compare All (${displayList.length})',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // "Recently Saved / Oldest Saved" sort dropdown
  // Highlighted (green) whenever a non-default option ("Oldest Saved") is picked.
  Widget _buildSortDropdownChip() {
    return PopupMenuButton<String>(
      onSelected: (value) => _sortOption.value = value,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => [
        _popupMenuItem('Recently Saved', Icons.history_rounded),
        _popupMenuItem('Oldest Saved', Icons.hourglass_bottom_rounded),
      ],
      child: Obx(() => _dropdownChipContent(
        _sortOption.value,
        active: _sortOption.value != 'Recently Saved',
      )),
    );
  }

  // Quick locality filter dropdown, built from the saved list itself.
  // Highlighted (green) whenever a specific locality (not "All Localities") is picked.
  Widget _buildLocalityDropdownChip(List<dynamic> savedList) {
    return PopupMenuButton<String>(
      onSelected: (value) => _selectedLocality.value = value,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (context) => _availableLocalities(savedList)
          .map((locality) => _popupMenuItem(locality, Icons.location_on_outlined))
          .toList(),
      child: Obx(() => _dropdownChipContent(
        _selectedLocality.value == 'All Localities' ? 'Filter by Locality' : _selectedLocality.value,
        active: _selectedLocality.value != 'All Localities',
      )),
    );
  }

  // Quick City filter chip opening SelectCityScreen
  Widget _buildCityDropdownChip(BuildContext context) {
    return Obx(() {
      final city = _filterCity.value.trim();
      final bool hasCity = city.isNotEmpty;
      final Color borderColor = hasCity ? const Color(0xFF00C896) : const Color(0xFFCBD5E1);
      final Color bgColor = hasCity ? const Color(0xFFE8F7F2) : Colors.white;
      final Color textColor = hasCity ? const Color(0xFF00C896) : const Color(0xFF334155);
      final Color iconColor = hasCity ? const Color(0xFF00C896) : const Color(0xFF64748B);

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final selectedCity = await Get.to<String>(() => SelectCityScreen(selectedCity: city));
                if (selectedCity != null) {
                  _filterCity.value = selectedCity;
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 14.sp, color: iconColor),
                  SizedBox(width: 4.w),
                  Text(
                    hasCity ? city : 'Filter by City',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (hasCity) ...[
              SizedBox(width: 6.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _filterCity.value = '';
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(Icons.close_rounded, size: 14.sp, color: textColor),
                ),
              ),
            ] else ...[
              SizedBox(width: 4.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final selectedCity = await Get.to<String>(() => SelectCityScreen(selectedCity: city));
                  if (selectedCity != null) {
                    _filterCity.value = selectedCity;
                  }
                },
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 14.sp, color: iconColor),
              ),
            ],
          ],
        ),
      );
    });
  }

  // NEW: Full "Filters" chip — opens the same filter set used on the Explore
  // screen (Transaction Type, Category, City, Price Range, Verified-only),
  // applied locally to the saved-properties list.
  Widget _buildFiltersChip(BuildContext context, List<dynamic> savedList) {
    return GestureDetector(
      onTap: () => _openFilterSheet(context, savedList),
      child: Obx(() {
        final active = _isAnyAdvancedFilterActive;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE8F7F2) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: active ? const Color(0xFF007A5E) : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 13.sp, color: active ? const Color(0xFF007A5E) : const Color(0xFF64748B)),
              SizedBox(width: 4.w),
              Text(
                active ? 'Filters •' : 'Filters',
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                  color: active ? const Color(0xFF007A5E) : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  PopupMenuItem<String> _popupMenuItem(String label, IconData icon) {
    return PopupMenuItem<String>(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: const Color(0xFF007A5E)),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _dropdownChipContent(String label, {bool active = false}) {
    final Color borderColor = active ? const Color(0xFF007A5E) : const Color(0xFFCBD5E1);
    final Color bgColor = active ? const Color(0xFFE8F7F2) : Colors.white;
    final Color textColor = active ? const Color(0xFF007A5E) : const Color(0xFF334155);
    final Color iconColor = active ? const Color(0xFF007A5E) : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14.sp, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildAiPortfolioInsight() {
    return Container(
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF007A5E).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF007A5E),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 13.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niwas AI Saved Portfolio Insight',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005B48),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Review your saved properties and schedule free site visits directly with verified agents.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        color: const Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPropertyCard(BuildContext context, dynamic item) {
    final model = PropertyModel.fromDynamic(item);
    final propertyData = model.toJson();
    final propertyId = _getPropertyId(item);
    final title = model.title;
    final location = model.formattedLocation;
    final price = model.formattedPrice;
    final imageUrl = model.primaryImageUrl;

    return Obx(() {
      final bool isCompared = _comparedSelectionMap[propertyId] ?? false;

      return Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isCompared
                ? const Color(0xFF007A5E)
                : const Color(0xFF007A5E).withValues(alpha: 0.35),
            width: isCompared ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImageCase(
                  url: imageUrl,
                  width: double.infinity,
                  height: 165.h,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                ),
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined, size: 11.sp, color: const Color(0xFF007A5E)),
                        SizedBox(width: 3.w),
                        Text(
                          'Verified',
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF007A5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Heart Icon - Tap to Remove / Unsave
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: GestureDetector(
                    onTap: () async {
                      final buyerId = await _getBuyerId();
                      if (buyerId != null && buyerId.isNotEmpty && propertyId.isNotEmpty) {
                        // This will trigger DELETE API and remove it from saved list
                        await controller.toggleSaveProperty(buyerId, propertyId);
                      }
                    },
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite_rounded, // Filled red heart since it's in saved list
                          color: Color(0xFFE11D48),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF007A5E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12.sp, color: const Color(0xFF64748B)),
                      SizedBox(width: 3.w),
                      Text(
                        location,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: () {
                      _comparedSelectionMap[propertyId] = !isCompared;
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            color: isCompared ? const Color(0xFF007A5E) : Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: isCompared ? const Color(0xFF007A5E) : const Color(0xFF94A3B8),
                              width: 1.5,
                            ),
                          ),
                          child: isCompared
                              ? Icon(Icons.check, size: 13.sp, color: Colors.white)
                              : null,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Add to Compare',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.toNamed(
                              AppRoutes.propertyDetails,
                              arguments: {'property': propertyData},
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007A5E),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 9.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            elevation: 0,
                          ),
                          child: Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildComparisonBar(BuildContext context, List<dynamic> savedList) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF007A5E).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.balance_rounded, color: const Color(0xFF007A5E), size: 16.sp),
          ),
          SizedBox(width: 8.w),
          Text(
            '$_selectedCount Selected',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _selectedCount >= _minCompareCount
                ? () => _openComparisonScreen(context, savedList)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005B48),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13.sp, color: Colors.white),
                SizedBox(width: 5.w),
                Text(
                  'Compare',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.arrow_forward_rounded, size: 13.sp, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// NEW: Filter bottom sheet — mirrors the Explore screen's filter set
// (Transaction Type, Category, City, Price Range, Verified-only), but
// applies purely client-side to the already-loaded saved properties list.
// =====================================================================
class _SavedFilterBottomSheet extends StatefulWidget {
  final String? initialTransactionType;
  final String? initialCategory;
  final String initialCity;
  final num? initialMinPrice;
  final num? initialMaxPrice;
  final bool initialVerifiedOnly;
  final VoidCallback onReset;
  final void Function({
  required String? transactionType,
  required String? category,
  required String city,
  required num? minPrice,
  required num? maxPrice,
  required bool verifiedOnly,
  }) onApply;

  const _SavedFilterBottomSheet({
    required this.initialTransactionType,
    required this.initialCategory,
    required this.initialCity,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialVerifiedOnly,
    required this.onReset,
    required this.onApply,
  });

  @override
  State<_SavedFilterBottomSheet> createState() => _SavedFilterBottomSheetState();
}

class _SavedFilterBottomSheetState extends State<_SavedFilterBottomSheet> {
  String? transactionType;
  String? category;
  String? propertyType;
  final Set<String> selectedBhk = {};
  String? furnishing;
  bool onlyVerified = false;
  late final TextEditingController cityController;
  late final TextEditingController minPriceController;
  late final TextEditingController maxPriceController;

  static const Color _green = Color(0xFF0B6E5F);
  static const Color _ink = Color(0xFF10222B);
  static const Color _muted = Color(0xFF5E7076);
  static const Color _softGreen = Color(0xFFE3F1ED);

  @override
  void initState() {
    super.initState();
    transactionType = widget.initialTransactionType;
    category = widget.initialCategory;
    onlyVerified = widget.initialVerifiedOnly;
    cityController = TextEditingController(text: widget.initialCity);
    minPriceController = TextEditingController(text: widget.initialMinPrice?.toString() ?? '');
    maxPriceController = TextEditingController(text: widget.initialMaxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    cityController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  List<String> _getPropertyTypeOptions() {
    switch (category) {
      case 'Residential':
        return ['Flat', 'House', 'Villa', 'Builder Floor', 'Studio', 'Penthouse', 'Duplex'];
      case 'Commercial':
        return ['Office', 'Shop', 'Showroom', 'Commercial Building', 'Restaurant Space', 'Hotel'];
      case 'Plot':
      case 'Plot & Land':
        return ['Residential Plot', 'Commercial Plot', 'Industrial Plot', 'Mixed-use Plot'];
      case 'Agricultural':
        return ['Agricultural Land', 'Farmhouse', 'Plantation'];
      case 'Industrial':
        return ['Warehouse/Godown', 'Factory', 'Industrial Shed'];
      case 'PG / Co-living':
        return ['PG', 'Co-living', 'Shared Accommodation'];
      default:
        return ['Flat', 'House', 'Villa', 'Plot'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePropertyTypes = _getPropertyTypeOptions();

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Saved Properties', style: GoogleFonts.plusJakartaSans(fontSize: 17.sp, fontWeight: FontWeight.w800, color: _ink)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      transactionType = null;
                      category = null;
                      propertyType = null;
                      selectedBhk.clear();
                      furnishing = null;
                      onlyVerified = false;
                      cityController.clear();
                      minPriceController.clear();
                      maxPriceController.clear();
                    });
                    widget.onReset();
                  },
                  child: Text('Reset', style: GoogleFonts.plusJakartaSans(color: _green, fontSize: 13.sp, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFEEF2F1)),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type
                    Text('Transaction Type', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                    SizedBox(height: 8.h),
                    Row(
                      children: ['Buy', 'Rent', 'Lease'].map((t) {
                        final selected = transactionType == t;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: GestureDetector(
                              onTap: () => setState(() => transactionType = selected ? null : t),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 11.h),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? _green : Colors.white,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: selected ? _green : const Color(0xFFE2E8F0)),
                                ),
                                child: Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: selected ? Colors.white : _ink)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // Category
                    Text('Category', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ['Residential', 'Commercial', 'Plot', 'Agricultural', 'Industrial', 'PG / Co-living'].map((c) {
                        final selected = category == c;
                        return _chip(c, selected, () {
                          setState(() {
                            category = selected ? null : c;
                            propertyType = null;
                          });
                        });
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // Property Type
                    if (category != null) ...[
                      Text('Property Type', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: availablePropertyTypes.map((pt) {
                          final selected = propertyType == pt;
                          return _chip(pt, selected, () {
                            setState(() => propertyType = selected ? null : pt);
                          });
                        }).toList(),
                      ),
                      SizedBox(height: 18.h),
                    ],

                    // BHK Bedrooms
                    if (category == 'Residential' || category == null) ...[
                      Text('Bedrooms (BHK)', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: ['Studio', '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'].map((bhk) {
                          final selected = selectedBhk.contains(bhk);
                          return _chip(bhk, selected, () {
                            setState(() {
                              if (selected) {
                                selectedBhk.remove(bhk);
                              } else {
                                selectedBhk.add(bhk);
                              }
                            });
                          });
                        }).toList(),
                      ),
                      SizedBox(height: 18.h),
                    ],

                    // City Location
                    Text('City', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                    SizedBox(height: 8.h),
                    InkWell(
                      onTap: () async {
                        final chosen = await Get.to<String>(() => SelectCityScreen(selectedCity: cityController.text));
                        if (chosen != null) {
                          setState(() => cityController.text = chosen);
                        }
                      },
                      child: IgnorePointer(
                        child: TextField(
                          controller: cityController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w600, color: _ink),
                          decoration: InputDecoration(
                            hintText: 'Select city',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5.sp, color: _muted),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: Icon(Icons.location_on_outlined, color: _green, size: 20.sp),
                            suffixIcon: Icon(Icons.keyboard_arrow_right_rounded, color: _muted, size: 20.sp),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 18.h),

                    // Price Range
                    Text('Price Range', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w600, color: _ink),
                            decoration: InputDecoration(
                              hintText: 'Min',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.sp, color: _muted),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text('to', style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _muted)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w600, color: _ink),
                            decoration: InputDecoration(
                              hintText: 'Max',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.sp, color: _muted),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // Furnishing
                    Text('Furnishing Status', style: GoogleFonts.plusJakartaSans(fontSize: 13.5.sp, fontWeight: FontWeight.w800, color: _ink)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ['Unfurnished', 'Semi-furnished', 'Fully-furnished'].map((f) {
                        final selected = furnishing == f;
                        return _chip(f, selected, () {
                          setState(() => furnishing = selected ? null : f);
                        });
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // Verified Toggle
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(color: _softGreen, borderRadius: BorderRadius.circular(16.r)),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: _green, size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verified Only', style: GoogleFonts.plusJakartaSans(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _ink)),
                                Text('Show physically verified saved items', style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, color: _muted)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: onlyVerified,
                            activeTrackColor: _green,
                            onChanged: (v) => setState(() => onlyVerified = v),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(
                        transactionType: transactionType,
                        category: category,
                        city: cityController.text.trim(),
                        minPrice: num.tryParse(minPriceController.text.trim()),
                        maxPrice: num.tryParse(maxPriceController.text.trim()),
                        verifiedOnly: onlyVerified,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text('Apply Filters', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.sp)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? _softGreen : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: selected ? _green : const Color(0xFFE2E8F0), width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.sp, color: selected ? _green : _ink, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
