import 'package:diginiwas/features/buyer/presentation/select_city_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/utils/shimmer.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_pill_search_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../controllers/buyer_home_controller.dart';
import '../models/property_filter_model.dart';
import '../models/property_model.dart';

// ================================================================
// DESIGN TOKENS
// ================================================================
const Color _green = Color(0xFF0B6E5F);
const Color _ink = Color(0xFF10222B);
const Color _muted = Color(0xFF5E7076);
const Color _softGreen = Color(0xFFE3F1ED);
const Color _border = Color(0xFFF0F4F3);
const Color _chipGrey = Color(0xFFF1F5F9);

List<BoxShadow> get _cardShadow => [
  BoxShadow(
    color: const Color(0xFF10222B).withValues(alpha: 0.08),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

TextStyle _t(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    TextStyle(
      fontSize: size.sp,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

Map<String, dynamic> _pfPropertyToMap(PfPropertyData p) {
  return {
    '_id': p.sId,
    'propertyId': p.propertyId,
    'title': p.title,
    'name': p.title,
    'locality': p.locality,
    'address': p.address,
    'city': p.city,
    'price': p.price,
    'bedrooms': p.bedrooms,
    'furnishing': p.furnishing,
    'area': p.superBuiltupArea != null ? '${p.superBuiltupArea} sqft' : null,
    'images': p.images?.map((img) => {'url': img.url}).toList(),
    'isCompared': p.isCompared,
    'transactionType': p.transactionType,
    'category': p.category,
    'verificationStatus': p.propertyVerificationStatus,
  };
}

class ExproleName extends StatefulWidget {
  const ExproleName({super.key});

  @override
  State<ExproleName> createState() => _ExproleNameState();
}

typedef ExploreMapScreen = ExproleName;

class _ExproleNameState extends State<ExproleName> {
  final BuyerHomeController controller = Get.find<BuyerHomeController>();
  final TextEditingController searchController = TextEditingController();
  String _selectedSort = 'Default';
  String _selectedQuickFilter = 'All';
  final Map<String, dynamic> _selectedForCompare = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<dynamic> _applySorting(List<dynamic> list, bool isFilterMode) {
    if (_selectedSort == 'Default' || list.isEmpty) return list;
    final sortedList = List<dynamic>.from(list);

    num getPrice(dynamic item) {
      if (isFilterMode && item is PfPropertyData) {
        return item.price ?? 0;
      } else if (item is Map) {
        final p = item['price'];
        if (p is num) return p;
        if (p is String) return num.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
      return 0;
    }

    int getBedrooms(dynamic item) {
      if (isFilterMode && item is PfPropertyData) {
        return int.tryParse(item.bedrooms ?? '') ?? 0;
      } else if (item is Map) {
        final b = item['bedrooms'];
        if (b is num) return b.toInt();
        if (b is String) return int.tryParse(b) ?? 0;
      }
      return 0;
    }

    String getTitle(dynamic item) {
      if (isFilterMode && item is PfPropertyData) {
        return item.title ?? '';
      } else if (item is Map) {
        return item['title']?.toString() ?? item['name']?.toString() ?? '';
      }
      return '';
    }

    switch (_selectedSort) {
      case 'Price: Low to High':
        sortedList.sort((a, b) => getPrice(a).compareTo(getPrice(b)));
        break;
      case 'Price: High to Low':
        sortedList.sort((a, b) => getPrice(b).compareTo(getPrice(a)));
        break;
      case 'Bedrooms: Most First':
        sortedList.sort((a, b) => getBedrooms(b).compareTo(getBedrooms(a)));
        break;
      case 'Name: A to Z':
        sortedList.sort((a, b) => getTitle(a).toLowerCase().compareTo(getTitle(b).toLowerCase()));
        break;
    }
    return sortedList;
  }

  void _showSortBottomSheet(BuildContext context) {
    final options = [
      {'title': 'Default / Featured', 'value': 'Default', 'icon': Icons.star_outline_rounded},
      {'title': 'Newest First', 'value': 'Newest First', 'icon': Icons.auto_awesome_outlined},
      {'title': 'Price: Low to High', 'value': 'Price: Low to High', 'icon': Icons.arrow_upward_rounded},
      {'title': 'Price: High to Low', 'value': 'Price: High to Low', 'icon': Icons.arrow_downward_rounded},
      {'title': 'Bedrooms: Most First', 'value': 'Bedrooms: Most First', 'icon': Icons.bed_outlined},
      {'title': 'Name: A to Z', 'value': 'Name: A to Z', 'icon': Icons.sort_by_alpha_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
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
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sort Properties', style: _t(16, FontWeight.w800, _ink)),
                  if (_selectedSort != 'Default')
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedSort = 'Default');
                        Navigator.pop(ctx);
                      },
                      child: Text('Reset', style: _t(13, FontWeight.w700, _green)),
                    ),
                ],
              ),
              SizedBox(height: 14.h),
              ...options.map((opt) {
                final isSelected = _selectedSort == opt['value'];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  leading: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: isSelected ? _softGreen : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(opt['icon'] as IconData, size: 18.sp, color: isSelected ? _green : _muted),
                  ),
                  title: Text(
                    opt['title'] as String,
                    style: _t(13.5, isSelected ? FontWeight.w700 : FontWeight.w500, isSelected ? _green : _ink),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: _green, size: 20.sp)
                      : null,
                  onTap: () {
                    setState(() => _selectedSort = opt['value'] as String);
                    Navigator.pop(ctx);
                  },
                );
              }),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _onQuickFilterSelected(String filter) {
    setState(() {
      if (_selectedQuickFilter == filter && filter != 'All') {
        _selectedQuickFilter = 'All';
        controller.clearPropertyFilters();
        controller.applyPropertyFilters();
      } else {
        _selectedQuickFilter = filter;
        switch (filter) {
          case 'All':
            controller.clearPropertyFilters();
            controller.applyPropertyFilters();
            break;
          case 'Buy':
            controller.applyPropertyFilters(transactionType: 'Buy');
            break;
          case 'Rent':
            controller.applyPropertyFilters(transactionType: 'Rent');
            break;
          case 'Residential':
            controller.applyPropertyFilters(category: 'Residential');
            break;
          case 'Commercial':
            controller.applyPropertyFilters(category: 'Commercial');
            break;
          case 'Plot':
            controller.applyPropertyFilters(category: 'Plot');
            break;
          case 'Verified':
            controller.applyPropertyFilters(propertyVerificationStatus: 'verified');
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 38.w + 20.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 14.w),
          child: AppAdaptiveBackButton(
            size: 38,
            iconSize: 18,
            color: _ink,
            onPressed: () {
              if (controller.bottomNavIndex.value == 1) {
                controller.changeBottomNavIndex(0);
              } else {
                Get.back();
              }
            },
          ),
        ),
        title: Text('Explore Properties', style: _t(17, FontWeight.w800, _ink)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                if (searchController.text.trim().isNotEmpty) {
                  await controller.searchProperties(searchController.text);
                } else {
                  await controller.applyPropertyFilters();
                }
              },
              color: _green,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final count = controller.isFilterApplied.value
                          ? controller.filteredResultsList.length
                          : controller.searchResultsList.length;
                      return _HeaderSection(
                        searchController: searchController,
                        propertyCount: count,
                        controller: controller,
                        currentSort: _selectedSort,
                        onSortTap: () => _showSortBottomSheet(context),
                        selectedQuickFilter: _selectedQuickFilter,
                        onQuickFilterSelected: _onQuickFilterSelected,
                        onChanged: (keyword) {
                          setState(() {});
                          controller.searchProperties(keyword);
                        },
                        onClear: () {
                          searchController.clear();
                          controller.searchProperties('');
                          setState(() {});
                        },
                      );
                    }),
                  ),
                  const SliverToBoxAdapter(child: _AiSummaryCard()),

                  // Dynamic Search / Filter Results Handler
                  Obx(() {
                    final isSearching = searchController.text.trim().isNotEmpty;
                    final isFilterMode = controller.isFilterApplied.value && !isSearching;
                    final hasActiveQueryOrFilter = isSearching || controller.isFilterApplied.value;

                    if (!hasActiveQueryOrFilter) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 36.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: const BoxDecoration(
                                    color: _softGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.travel_explore_rounded,
                                      size: 40.sp, color: _green),
                                ),
                                SizedBox(height: 18.h),
                                Text('Explore Properties', style: _t(16, FontWeight.w800, _ink)),
                                SizedBox(height: 8.h),
                                Text(
                                  'Search by locality, property name, or apply filters above to view available properties.',
                                  textAlign: TextAlign.center,
                                  style: _t(12.5, FontWeight.w400, _muted, h: 1.45),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final isLoading = isSearching
                        ? controller.searchLoading.value
                        : (isFilterMode ? controller.filterLoading.value : false);

                    if (isLoading) {
                      return const SliverToBoxAdapter(
                        child: PropertyListShimmer(itemCount: 4),
                      );
                    }

                    List<dynamic> rawResults;
                    if (isSearching) {
                      rawResults = controller.searchResultsList;
                    } else if (isFilterMode) {
                      rawResults = controller.filteredResultsList;
                    } else if (controller.filteredResultsList.isNotEmpty) {
                      rawResults = controller.filteredResultsList;
                    } else {
                      rawResults = controller.getAllKnownProperties();
                    }

                    final List<dynamic> results = _applySorting(rawResults, isFilterMode);

                    final bool showEmptyState = results.isEmpty;

                    if (showEmptyState) {
                      final String emptyTitle = isSearching
                          ? 'No Results For "${searchController.text.trim()}"'
                          : (isFilterMode ? 'No Filter Matches' : 'No Properties Found');
                      final String emptyMessage = isSearching
                          ? 'Try searching with a different locality, project name or budget.'
                          : 'Try adjusting your price range, property category or city filters.';
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: AppEmptyState(
                            type: isSearching ? EmptyStateType.search : EmptyStateType.property,
                            title: emptyTitle,
                            message: emptyMessage,
                            actionLabel: 'Reset All Filters',
                            onAction: () {
                              setState(() {
                                _selectedQuickFilter = 'All';
                                _selectedSort = 'Default';
                              });
                              searchController.clear();
                              controller.clearPropertyFilters();
                              controller.applyPropertyFilters();
                            },
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final rawProperty = results[index];
                          final Map<dynamic, dynamic> property = rawProperty is PfPropertyData
                              ? _pfPropertyToMap(rawProperty)
                              : (rawProperty is Map
                              ? Map<dynamic, dynamic>.from(rawProperty)
                              : PropertyModel.fromDynamic(rawProperty).toJson());

                          final propId = property['_id']?.toString() ??
                              property['propertyId']?.toString() ??
                              property['propertyCode']?.toString() ??
                              property['id']?.toString() ??
                              'prop_$index';

                          final bool isItemCompared = _selectedForCompare.containsKey(propId);

                          return StaggeredItemEntrance(
                            index: index,
                            child: _PropertyCard(
                              property: property,
                              isCompared: isItemCompared,
                              controller: controller,
                              onCompareChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedForCompare[propId] = property;
                                  } else {
                                    _selectedForCompare.remove(propId);
                                  }
                                });
                              },
                            ),
                          );
                        },
                        childCount: results.length,
                      ),
                    );
                  }),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),

            if (_selectedForCompare.isNotEmpty)
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
                child: _CompareFloatingBar(
                  count: _selectedForCompare.length,
                  onTapCompare: () {
                    Get.to(() => ComparePropertiesScreen(
                        comparedProperties: _selectedForCompare.values.toList()));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showFilterSheet(BuildContext context, BuyerHomeController controller) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterBottomSheet(controller: controller),
  );
}

// ================================================================
// DIGINIWAS COMPLETE PROPERTY FILTER BOTTOM SHEET
// ================================================================
class _FilterBottomSheet extends StatefulWidget {
  final BuyerHomeController controller;
  const _FilterBottomSheet({required this.controller});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  // Main Filter Flow: Transaction -> Location -> Category -> Property Type -> Relevant Specs
  String transactionType = 'Buy'; // Buy, Rent, Lease
  String category = 'Residential'; // Residential, Commercial, Plot & Land, Agricultural, Industrial, PG / Co-living
  String? propertyType;
  final Set<String> selectedBhk = {};
  String? selectedFurnishing;
  String? selectedPossession;
  String? selectedListedBy;
  bool onlyVerified = false;
  int selectedRadiusKm = 5; // 1, 3, 5, 10, 20 km

  final TextEditingController cityController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  final TextEditingController amenitySearchController = TextEditingController();

  final Set<String> selectedAmenities = {};

  double sliderPriceValue = 50; // In lakhs for Buy, in thousands for Rent

  static const List<String> _allAmenities = [
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

  @override
  void initState() {
    super.initState();
    final applied = widget.controller.currentAppliedFilters.value;
    if (applied != null) {
      transactionType = applied.transactionType ?? 'Buy';
      category = applied.category ?? 'Residential';
      onlyVerified = applied.propertyVerificationStatus == 'verified';
      cityController.text = applied.city ?? widget.controller.userCurrentLocation.value;
      if (applied.minPrice != null) minPriceController.text = applied.minPrice.toString();
      if (applied.maxPrice != null) maxPriceController.text = applied.maxPrice.toString();
    } else if (cityController.text.isEmpty) {
      cityController.text = widget.controller.userCurrentLocation.value;
    }
  }

  @override
  void dispose() {
    cityController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    amenitySearchController.dispose();
    super.dispose();
  }

  List<String> _getPropertyTypeOptions() {
    switch (category) {
      case 'Residential':
        return ['Flat', 'House', 'Villa', 'Builder Floor', 'Studio', 'Penthouse', 'Duplex'];
      case 'Commercial':
        return ['Office', 'Shop', 'Showroom', 'Commercial Building', 'Restaurant Space', 'Hotel'];
      case 'Plot & Land':
      case 'Plot':
        return ['Residential Plot', 'Commercial Plot', 'Industrial Plot', 'Mixed-use Plot'];
      case 'Agricultural':
        return ['Agricultural Land', 'Farmhouse', 'Plantation'];
      case 'Industrial':
        return ['Warehouse/Godown', 'Factory', 'Industrial Shed', 'Industrial Building'];
      case 'PG / Co-living':
        return ['PG', 'Co-living', 'Shared Accommodation'];
      default:
        return ['Flat', 'House', 'Villa', 'Plot'];
    }
  }

  void _onCategoryChanged(String newCategory) {
    setState(() {
      category = newCategory;
      propertyType = null; // Clear incompatible property type
    });
  }

  void _onTransactionChanged(String newTx) {
    setState(() {
      transactionType = newTx;
      if (transactionType != 'Rent' && category == 'PG / Co-living') {
        category = 'Residential';
      }
      propertyType = null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      // Clear optional filters while keeping Location & Transaction
      propertyType = null;
      selectedBhk.clear();
      selectedFurnishing = null;
      selectedPossession = null;
      selectedListedBy = null;
      onlyVerified = false;
      minPriceController.clear();
      maxPriceController.clear();
      selectedAmenities.clear();
      sliderPriceValue = 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    final availablePropertyTypes = _getPropertyTypeOptions();
    final filteredAmenities = _allAmenities
        .where((a) => a.toLowerCase().contains(amenitySearchController.text.trim().toLowerCase()))
        .toList();

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          children: [
            // Sheet Handle
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

            // Header Title & Clear All
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Filters', style: _t(18, FontWeight.w800, _ink)),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: Text('Clear Optional', style: _t(13, FontWeight.w600, _muted)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: _ink, size: 22.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 1, color: _border),

            // Filter Scrollable Sections
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TRANSACTION TYPE (Buy, Rent, Lease)
                    _sectionHeading('I want to'),
                    SizedBox(height: 8.h),
                    Row(
                      children: ['Buy', 'Rent', 'Lease'].map((tx) {
                        final selected = transactionType == tx;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: GestureDetector(
                              onTap: () => _onTransactionChanged(tx),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(vertical: 11.h),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? _green : Colors.white,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: selected ? _green : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  tx,
                                  style: _t(13, FontWeight.w700, selected ? Colors.white : _ink),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // 2. LOCATION & RADIUS
                    _sectionHeading('Location & Radius'),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: cityController,
                      style: _t(13, FontWeight.w600, _ink),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: 'Search city, locality, landmark...',
                        hintStyle: _t(12.5, FontWeight.w400, _muted),
                        prefixIcon: Icon(Icons.location_on_outlined, color: _green, size: 20.sp),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(color: _green, width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text('Radius:', style: _t(12, FontWeight.w600, _muted)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [1, 3, 5, 10, 20].map((r) {
                                final selected = selectedRadiusKm == r;
                                return GestureDetector(
                                  onTap: () => setState(() => selectedRadiusKm = r),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 6.w),
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      color: selected ? _green : _chipGrey,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text('$r km',
                                        style: _t(11, FontWeight.w700, selected ? Colors.white : _muted)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // 3. PROPERTY CATEGORY
                    _sectionHeading('Property Category'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        'Residential', 'Commercial', 'Plot & Land',
                        'Agricultural', 'Industrial',
                        if (transactionType == 'Rent') 'PG / Co-living',
                      ].map((cat) {
                        final selected = category == cat;
                        return _chip(cat, selected, () => _onCategoryChanged(cat));
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // 4. PROPERTY TYPE (Dynamically loaded for selected Category)
                    _sectionHeading('$category Types'),
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

                    // 5. BHK BEDROOMS (For Residential / PG)
                    if (category == 'Residential' || category == 'PG / Co-living') ...[
                      SizedBox(height: 18.h),
                      _sectionHeading('Bedrooms (BHK)'),
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
                    ],

                    SizedBox(height: 18.h),

                    // 6. BUDGET RANGE
                    _sectionHeading(transactionType == 'Rent' ? 'Monthly Rent Range' : 'Price Range'),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            style: _t(13, FontWeight.w600, _ink),
                            decoration: InputDecoration(
                              hintText: 'Min Price',
                              hintStyle: _t(12, FontWeight.w400, _muted),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text('to', style: _t(12, FontWeight.w600, _muted)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            style: _t(13, FontWeight.w600, _ink),
                            decoration: InputDecoration(
                              hintText: 'Max Price',
                              hintStyle: _t(12, FontWeight.w400, _muted),
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

                    // 7. FURNISHING
                    _sectionHeading('Furnishing Status'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ['Unfurnished', 'Semi-furnished', 'Fully-furnished'].map((f) {
                        final selected = selectedFurnishing == f;
                        return _chip(f, selected, () {
                          setState(() => selectedFurnishing = selected ? null : f);
                        });
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // 8. POSSESSION / AVAILABILITY
                    _sectionHeading(transactionType == 'Rent' ? 'Availability' : 'Possession Status'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: (transactionType == 'Rent'
                          ? ['Immediate', 'Within 15 Days', 'Within 30 Days']
                          : ['Ready to Move', 'Under Construction']).map((pos) {
                        final selected = selectedPossession == pos;
                        return _chip(pos, selected, () {
                          setState(() => selectedPossession = selected ? null : pos);
                        });
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // 9. LISTED BY
                    _sectionHeading('Listed By'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ['Owner', 'Agent', 'Builder'].map((lb) {
                        final selected = selectedListedBy == lb;
                        return _chip(lb, selected, () {
                          setState(() => selectedListedBy = selected ? null : lb);
                        });
                      }).toList(),
                    ),

                    SizedBox(height: 18.h),

                    // 10. AMENITIES
                    _sectionHeading('Amenities (Must match all selected)'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: filteredAmenities.map((amenity) {
                        final selected = selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity, style: _t(11.5, selected ? FontWeight.w700 : FontWeight.w500, selected ? Colors.white : _ink)),
                          selected: selected,
                          selectedColor: _green,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: selected ? _green : const Color(0xFFE2E8F0)),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                selectedAmenities.add(amenity);
                              } else {
                                selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 16.h),

                    // 11. VERIFIED TOGGLE
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: _softGreen,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: _green, size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DigiNiwas Verified Only', style: _t(13, FontWeight.w700, _ink)),
                                Text('Show 100% physically inspected properties', style: _t(11, FontWeight.w400, _muted)),
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

            // FIXED BOTTOM APPLY BUTTON
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
                      widget.controller.applyPropertyFilters(
                        transactionType: transactionType,
                        category: category,
                        city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                        minPrice: num.tryParse(minPriceController.text.trim()),
                        maxPrice: num.tryParse(maxPriceController.text.trim()),
                        propertyVerificationStatus: onlyVerified ? 'verified' : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: Text('Show Properties', style: _t(14, FontWeight.w800, Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Text(title, style: _t(13.5, FontWeight.w800, _ink));
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
          border: Border.all(
            color: selected ? _green : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: _t(12, selected ? FontWeight.w700 : FontWeight.w500, selected ? _green : _ink),
        ),
      ),
    );
  }
}

// ================================================================
// HEADER SECTION
// ================================================================
class _SearchSuggestion {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String type;

  _SearchSuggestion({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.type,
  });
}

class _HeaderSection extends StatefulWidget {
  final TextEditingController searchController;
  final int propertyCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final BuyerHomeController controller;
  final String currentSort;
  final VoidCallback onSortTap;
  final String selectedQuickFilter;
  final ValueChanged<String> onQuickFilterSelected;

  const _HeaderSection({
    required this.searchController,
    required this.propertyCount,
    required this.onChanged,
    required this.onClear,
    required this.controller,
    required this.currentSort,
    required this.onSortTap,
    required this.selectedQuickFilter,
    required this.onQuickFilterSelected,
  });

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && widget.searchController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<_SearchSuggestion> _computeSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final List<_SearchSuggestion> list = [];

    list.add(_SearchSuggestion(
      title: 'Search "$query"',
      subtitle: 'in all properties',
      icon: Icons.search_rounded,
      iconColor: _green,
      value: query,
      type: 'query',
    ));

    final matchingCities = SelectCityScreen.popularCities
        .followedBy(SelectCityScreen.allCities)
        .toSet()
        .where((c) => c.toLowerCase().contains(q))
        .take(3);
    for (final city in matchingCities) {
      list.add(_SearchSuggestion(
        title: city,
        subtitle: 'City',
        icon: Icons.location_city_rounded,
        iconColor: const Color(0xFFEF4444),
        value: city,
        type: 'city',
      ));
    }

    final allProps = widget.controller.getAllKnownProperties();
    final seenLocalities = <String>{};
    for (final prop in allProps) {
      final locality = prop['locality']?.toString() ?? '';
      final city = prop['city']?.toString() ?? '';
      if (locality.isNotEmpty && locality.toLowerCase().contains(q) && !seenLocalities.contains(locality.toLowerCase())) {
        seenLocalities.add(locality.toLowerCase());
        list.add(_SearchSuggestion(
          title: locality,
          subtitle: city.isNotEmpty ? 'Locality in $city' : 'Locality',
          icon: Icons.place_outlined,
          iconColor: const Color(0xFF3B82F6),
          value: locality,
          type: 'locality',
        ));
        if (list.length >= 6) break;
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPillSearchBar(
            controller: widget.searchController,
            focusNode: _focusNode,
            autofocus: false,
            hintText: 'Search locality, property or budget...',
            onChanged: (val) {
              setState(() {
                _showSuggestions = val.trim().isNotEmpty;
              });
              widget.onChanged(val);
            },
            onClear: () {
              setState(() {
                _showSuggestions = false;
              });
              _focusNode.unfocus();
              widget.onClear();
            },
          ),

          if (_showSuggestions && widget.searchController.text.trim().isNotEmpty) ...[
            Builder(
              builder: (context) {
                final suggestions = _computeSuggestions(widget.searchController.text);
                if (suggestions.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(top: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: suggestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final s = entry.value;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              widget.searchController.text = s.value;
                              setState(() {
                                _showSuggestions = false;
                              });
                              _focusNode.unfocus();
                              if (s.type == 'city') {
                                widget.controller.applyPropertyFilters(city: s.value);
                              } else {
                                widget.controller.searchProperties(s.value);
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(7.r),
                                    decoration: BoxDecoration(
                                      color: s.iconColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(s.icon, size: 16.sp, color: s.iconColor),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.title, style: _t(13, FontWeight.w600, _ink)),
                                        if (s.subtitle != null)
                                          Text(s.subtitle!, style: _t(11, FontWeight.w400, _muted)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.north_west_rounded, size: 14.sp, color: _muted),
                                ],
                              ),
                            ),
                          ),
                          if (index < suggestions.length - 1)
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],

          SizedBox(height: 14.h),
          Obx(() {
            final isFilterMode = widget.controller.isFilterApplied.value;
            final showCount = isFilterMode || widget.searchController.text.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showCount ? '${widget.propertyCount} Properties Found' : 'Explore Properties',
                  style: _t(19, FontWeight.w800, _ink),
                ),
                Text(
                  isFilterMode
                      ? 'Results matching your selected filters'
                      : (widget.searchController.text.isEmpty
                      ? 'Live results based on your preferences'
                      : 'Live search results matching your query'),
                  style: _t(12, FontWeight.w400, _muted),
                ),
              ],
            );
          }),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterButton(
                  icon: Icons.sort_rounded,
                  label: widget.currentSort == 'Default' ? 'Sort' : 'Sorted',
                  isSelected: widget.currentSort != 'Default',
                  onTap: widget.onSortTap,
                ),
                SizedBox(width: 8.w),
                Obx(() => _buildFilterButton(
                  icon: Icons.tune_rounded,
                  label: widget.controller.isFilterApplied.value ? 'Filters •' : 'Filters',
                  isSelected: widget.controller.isFilterApplied.value,
                  onTap: () => _showFilterSheet(context, widget.controller),
                )),
                SizedBox(width: 8.w),
                Obx(() {
                  final city = widget.controller.currentAppliedFilters.value?.city;
                  final hasCity = city != null && city.trim().isNotEmpty;
                  return _buildFilterButton(
                    icon: Icons.location_on_rounded,
                    label: hasCity ? city : 'City',
                    isSelected: hasCity,
                    onTap: () async {
                      final selectedCity = await Get.to<String>(() => SelectCityScreen(selectedCity: city));
                      if (selectedCity != null) {
                        widget.controller.applyPropertyFilters(city: selectedCity.trim().isEmpty ? null : selectedCity);
                      }
                    },
                  );
                }),
                SizedBox(width: 8.w),
                _buildFilterButton(
                  icon: Icons.map_outlined,
                  label: 'Map View',
                  isPrimary: true,
                  onTap: () {
                    Get.toNamed(AppRoutes.exploreMap);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickChip('All', Icons.grid_view_rounded),
                SizedBox(width: 8.w),
                _buildQuickChip('Buy', Icons.shopping_bag_outlined),
                SizedBox(width: 8.w),
                _buildQuickChip('Rent', Icons.key_outlined),
                SizedBox(width: 8.w),
                _buildQuickChip('Residential', Icons.apartment_rounded),
                SizedBox(width: 8.w),
                _buildQuickChip('Commercial', Icons.storefront_outlined),
                SizedBox(width: 8.w),
                _buildQuickChip('Plot', Icons.landscape_outlined),
                SizedBox(width: 8.w),
                _buildQuickChip('Verified', Icons.verified_user_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, IconData icon) {
    final isSelected = widget.selectedQuickFilter == label;
    return GestureDetector(
      onTap: () => widget.onQuickFilterSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? _green : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5.sp,
              color: isSelected ? Colors.white : _muted,
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: _t(11.5, isSelected ? FontWeight.w700 : FontWeight.w500, isSelected ? Colors.white : _ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isPrimary = false,
  }) {
    Color bgColor;
    Color textColor;
    Border border;

    if (isPrimary) {
      bgColor = _ink;
      textColor = Colors.white;
      border = Border.all(color: Colors.transparent);
    } else if (isSelected) {
      bgColor = _softGreen;
      textColor = _green;
      border = Border.all(color: _green, width: 1.2);
    } else {
      bgColor = Colors.white;
      textColor = _ink;
      border = Border.all(color: const Color(0xFFE2E8F0), width: 1.1);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.sp, color: textColor),
            SizedBox(width: 5.w),
            Text(label, style: _t(12, FontWeight.w700, textColor)),
          ],
        ),
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFBCE7DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16.sp, color: _green),
              SizedBox(width: 6.w),
              Text('Niwas AI Smart Summary', style: _t(13, FontWeight.w800, _green)),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Found verified properties matching your preferences. Explore features, pricing, and exact locations below.',
            style: _t(11.5, FontWeight.w400, _ink, h: 1.35),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PROPERTY CARD
// ================================================================
class _PropertyCard extends StatelessWidget {
  final dynamic property;
  final bool? isCompared;
  final BuyerHomeController controller;
  final ValueChanged<bool?> onCompareChanged;

  const _PropertyCard({
    required this.property,
    this.isCompared,
    required this.controller,
    required this.onCompareChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = property['title'] ?? property['name'] ?? 'Property';
    final locality = property['locality'] ?? '';
    final city = property['city'] ?? '';
    final price = property['price']?.toString() ?? '0';
    final bedrooms = property['bedrooms']?.toString() ?? '3';
    final furnishing = property['furnishing'] ?? 'Ready';
    final area = property['area']?.toString() ?? '1,150 sqft';
    final bool effectiveIsCompared = isCompared ?? (property['isCompared'] == true);

    String? imageUrl;
    final images = property['images'] ?? property['photos'] ?? property['gallery'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first is Map
          ? (images.first['secure_url']?.toString() ??
              images.first['url']?.toString() ??
              images.first['imageUrl']?.toString() ??
              images.first['image']?.toString())
          : images.first?.toString();
    }
    if ((imageUrl == null || imageUrl.isEmpty) && property['image'] is String) {
      imageUrl = property['image'];
    }
    if ((imageUrl == null || imageUrl.isEmpty) && property['imageUrl'] is String) {
      imageUrl = property['imageUrl'];
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _border, width: 1),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child: ImageCase(
                  url: imageUrl,
                  height: 165.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.home_work_rounded,
                ),
              ),
              Positioned(
                top: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13.sp, color: _green),
                      SizedBox(width: 4.w),
                      Text('Verified', style: _t(11, FontWeight.w700, _green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(15, FontWeight.w800, _ink)),
                    ),
                    SizedBox(width: 8.w),
                    Text('₹ $price', style: _t(15, FontWeight.w800, _green)),
                  ],
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13.sp, color: _muted),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text('$locality, $city', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(11.5, FontWeight.w400, _muted)),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(color: _softGreen, borderRadius: BorderRadius.circular(6.r)),
                  child: Text('MATCHES YOUR BUDGET', style: _t(9.5, FontWeight.w800, _green)),
                ),
                SizedBox(height: 10.h),
                const Divider(height: 1, color: _border),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecItem('BHK', '$bedrooms BHK'),
                    _buildSpecItem('Area', area),
                    _buildSpecItem('Possession', furnishing),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onCompareChanged(!effectiveIsCompared),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: effectiveIsCompared ? _green : const Color(0xFFCBD5E1)),
                          backgroundColor: effectiveIsCompared ? _softGreen : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18.sp,
                              width: 18.sp,
                              child: Checkbox(
                                value: effectiveIsCompared,
                                onChanged: onCompareChanged,
                                activeColor: _green,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text('Compare', style: _t(12, FontWeight.w700, effectiveIsCompared ? _green : _ink)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.propertyDetails,
                            arguments: {'property': property},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          padding: EdgeInsets.symmetric(vertical: 11.h),
                          elevation: 0,
                        ),
                        child: Text('View Details', style: _t(12, FontWeight.w800, Colors.white)),
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
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _t(10, FontWeight.w400, _muted)),
        SizedBox(height: 2.h),
        Text(value, style: _t(12, FontWeight.w700, _ink)),
      ],
    );
  }
}

class _CompareFloatingBar extends StatelessWidget {
  final int count;
  final VoidCallback onTapCompare;

  const _CompareFloatingBar({required this.count, required this.onTapCompare});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: Colors.white,
                child: Text('$count', style: _t(11, FontWeight.w800, _green)),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Compare properties', style: _t(13, FontWeight.w800, Colors.white)),
                  Text('Side by side analysis', style: _t(10, FontWeight.w400, Colors.white70)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onTapCompare,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minimumSize: Size.zero,
            ),
            child: Text('Compare →', style: _t(12, FontWeight.w800, _green)),
          ),
        ],
      ),
    );
  }
}

class ComparePropertiesScreen extends StatefulWidget {
  final List<dynamic> comparedProperties;

  const ComparePropertiesScreen({
    super.key,
    required this.comparedProperties,
  });

  @override
  State<ComparePropertiesScreen> createState() => _ComparePropertiesScreenState();
}

class _ComparePropertiesScreenState extends State<ComparePropertiesScreen> {
  late List<dynamic> _properties;

  @override
  void initState() {
    super.initState();
    _properties = List.from(widget.comparedProperties);
  }

  void _removeProperty(int index) {
    setState(() {
      _properties.removeAt(index);
    });
  }

  String _generateAiInsight() {
    if (_properties.isEmpty) return '';
    if (_properties.length == 1) {
      final title = _properties[0]['title'] ?? _properties[0]['name'] ?? 'Property';
      final locality = _properties[0]['locality'] ?? _properties[0]['address'] ?? '';
      return '$title is a great choice in $locality.';
    }
    final t1 = _properties[0]['title'] ?? _properties[0]['name'] ?? 'First property';
    final t2 = _properties[1]['title'] ?? _properties[1]['name'] ?? 'Second property';
    return '$t1 fits budget better, while $t2 offers high connectivity across ${_properties.length} compared properties.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      appBar: _buildAppBar(context),
      body: _properties.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopPropertyCards(),
            SizedBox(height: 20.h),
            _buildComparisonTable(),
            SizedBox(height: 20.h),
            _buildAiInsightCard(),
            SizedBox(height: 20.h),
            _buildNeedHelpCard(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(8.r),
        child: AppAdaptiveBackButton(
          size: 38,
          iconSize: 18,
          color: _ink,
          onPressed: () => Get.back(),
        ),
      ),
      title: Text('Compare (${_properties.length}) Properties', style: _t(16, FontWeight.w800, _ink)),
      centerTitle: true,
    );
  }

  Widget _buildTopPropertyCards() {
    final bool isMultiScroll = _properties.length > 2;

    if (isMultiScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: List.generate(_properties.length, (index) {
            return Container(
              width: 165.w,
              margin: EdgeInsets.only(right: 12.w),
              child: _buildPropertyCardItem(_properties[index], index),
            );
          }),
        ),
      );
    }

    return Row(
      children: List.generate(_properties.length, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == 0 && _properties.length > 1 ? 12.w : 0,
            ),
            child: _buildPropertyCardItem(_properties[index], index),
          ),
        );
      }),
    );
  }

  Widget _buildPropertyCardItem(dynamic item, int index) {
    final title = item['title'] ?? item['name'] ?? 'Property';
    final locality = item['locality'] ?? item['address'] ?? '';
    final price = item['price']?.toString() ?? '0';

    String? imageUrl;
    final images = item['images'] ?? item['photos'] ?? item['gallery'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first is Map
          ? (images.first['secure_url']?.toString() ??
              images.first['url']?.toString() ??
              images.first['imageUrl']?.toString() ??
              images.first['image']?.toString())
          : images.first?.toString();
    }
    if ((imageUrl == null || imageUrl.isEmpty) && item['image'] is String) {
      imageUrl = item['image'];
    }
    if ((imageUrl == null || imageUrl.isEmpty) && item['imageUrl'] is String) {
      imageUrl = item['imageUrl'];
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _cardShadow,
      ),
      padding: EdgeInsets.all(8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: ImageCase(
                  url: imageUrl,
                  height: 105.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.home_work_rounded,
                ),
              ),
              Positioned(
                top: 6.h,
                right: 6.w,
                child: GestureDetector(
                  onTap: () => _removeProperty(index),
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 13.sp, color: _ink),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(12.5, FontWeight.w800, _ink)),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 10.sp, color: _muted),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(locality, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(9.5, FontWeight.w400, _muted)),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text('₹ $price', style: _t(14, FontWeight.w800, _green)),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final bool isMulti = _properties.length > 2;

    Widget tableContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          _buildDynamicTableRow(
            icon: Icons.grid_view_rounded,
            label: 'Configuration',
            values: _properties.map((e) => '${e['bedrooms'] ?? '2'} BHK').toList(),
            isFirst: true,
          ),
          _buildDynamicTableRow(
            icon: Icons.crop_square_rounded,
            label: 'Carpet Area',
            values: _properties.map((e) => e['area']?.toString() ?? '1,240 sq.ft').toList(),
          ),
          _buildDynamicTableRow(
            icon: Icons.calendar_today_outlined,
            label: 'Possession',
            values: _properties.map((e) => e['furnishing']?.toString() ?? 'Ready to Move').toList(),
          ),
          _buildDynamicTableRow(
            icon: Icons.sell_outlined,
            label: 'Price',
            values: _properties.map((e) => '₹ ${e['price'] ?? '85 L'}').toList(),
            isHighlighted: true,
          ),
          _buildDynamicTableRow(
            icon: Icons.location_on_outlined,
            label: 'Locality',
            values: _properties.map((e) => e['locality']?.toString() ?? 'Bopal').toList(),
          ),
          _buildDynamicTableRow(
            icon: Icons.verified_user_outlined,
            label: 'Verification',
            values: _properties.map((e) => 'Verified').toList(),
            isVerifiedTag: true,
            isLast: true,
          ),
        ],
      ),
    );

    if (isMulti) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: 120.w + (_properties.length * 115.w),
          child: tableContent,
        ),
      );
    }

    return tableContent;
  }

  Widget _buildDynamicTableRow({
    required IconData icon,
    required String label,
    required List<String> values,
    bool isHighlighted = false,
    bool isVerifiedTag = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: _border),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 110.w,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                child: Row(
                  children: [
                    Icon(icon, size: 14.sp, color: _muted),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(label, style: _t(10, FontWeight.w500, _muted)),
                    ),
                  ],
                ),
              ),
            ),
            ...List.generate(values.length, (i) {
              return Expanded(
                child: Row(
                  children: [
                    Container(width: 1, color: _border),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
                          child: isVerifiedTag
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 12.sp, color: _green),
                              SizedBox(width: 2.w),
                              Text(values[i], style: _t(10.5, FontWeight.w700, _green)),
                            ],
                          )
                              : Text(
                            values[i],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _t(11, isHighlighted ? FontWeight.w800 : FontWeight.w600, isHighlighted ? _green : _ink),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFBCE7DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('AI', style: _t(11, FontWeight.w800, Colors.white)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niwas AI Insight', style: _t(12.5, FontWeight.w800, _green)),
                    SizedBox(height: 3.h),
                    Text(_generateAiInsight(), style: _t(11.5, FontWeight.w700, _ink, h: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(color: Color(0xFFBCE7DA), thickness: 0.8),
          SizedBox(height: 4.h),
          Text(
            'Use this guidance with property documents and a site inspection.',
            style: _t(9.5, FontWeight.w400, _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: const BoxDecoration(
              color: _softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, color: _green, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text('Need local help?', style: _t(13.5, FontWeight.w800, _ink)),
          SizedBox(height: 4.h),
          Text(
            'Connect with a verified DigiNiwas\npartner for property details and availability.',
            textAlign: TextAlign.center,
            style: _t(10.5, FontWeight.w400, _muted, h: 1.3),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Connect with DigiNiwas Partner', style: _t(11.5, FontWeight.w700, Colors.white)),
                  SizedBox(width: 4.w),
                  Icon(Icons.arrow_forward_rounded, size: 14.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows_rounded, size: 48.sp, color: _muted),
          SizedBox(height: 8.h),
          Text('No properties selected to compare', style: _t(13, FontWeight.w500, _muted)),
        ],
      ),
    );
  }
}
