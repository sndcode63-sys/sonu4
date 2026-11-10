import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/buyer_home_controller.dart';
import '../../../features/partner/controllers/lead_controller.dart';
import '../controllers/property_details_controller.dart';
import '../models/niwas_ai_models.dart';
import '../models/property_review_model.dart';
import '../../../features/partner/controllers/visit_controller.dart';

import '../../../features/partner/models/request_visit_model.dart';
import '../../../features/partner/models/visit_status.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';

import '../../partner/data/agent_repo.dart';
import '../../partner/data/lead_repository.dart';
import '../../partner/data/visit_repository.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../../../core/utils/shimmer.dart';
import 'widgets/service_stories_section.dart';



class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ---------------- Theme tokens ----------------
  // Video-matched theme: deep indigo primary, soft grey tiles, purple price pill
  // App theme: same green as the home screen. NO card borders on this screen —
  // cards are white with soft elevation (shadow) instead.
  static const Color _green = Color(0xFF0B6E5F);
  static const Color _greenSoft = Color(0xFFE3F1ED);
  static const Color _greenLine = Color(0xFFE3F1ED);
  static const Color _tile = Color(0xFFF4F8F7);
  static const Color _ink = Color(0xFF10222B);
  static const Color _body = Color(0xFF5E7076);
  static const Color _muted = Color(0xFF5E7076);
  static const Color _priceBg = Color(0xFFE3F1ED);
  static const Color _priceFg = Color(0xFF0B6E5F);

  /// Soft elevation used by every card on this screen (replaces borders).
  List<BoxShadow> get _elev => [
    BoxShadow(
      color: const Color(0xFF10222B).withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF10222B).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  TextStyle _t(double size, FontWeight w, Color c,
      {double? height, double? ls}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: w,
          color: c,
          height: height,
          letterSpacing: ls);

  PropertyDetailsController get controller =>
      Get.find<PropertyDetailsController>();

  // ---------------- Gallery / scrolling state ----------------
  late PageController _pageController;
  final ScrollController _thumbController = ScrollController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _activeTab = ValueNotifier<int>(0);
  final GlobalKey _kOverview = GlobalKey();
  final GlobalKey _kAmenities = GlobalKey();
  final GlobalKey _kFeatures = GlobalKey();
  final GlobalKey _kLocation = GlobalKey();
  final GlobalKey _kGallery = GlobalKey();
  final GlobalKey _kReviews = GlobalKey();
  final GlobalKey _kSimilar = GlobalKey();
  List<GlobalKey> _tabKeys = [];

  bool _descExpanded = false;

  // ---- Nearby amenities (within 20 km) + map selection ----
  Future<List<_NearbyPlace>>? _nearbyFuture;
  _NearbyPlace? _selectedPlace;
  GoogleMapController? _locMapCtrl;
  bool _showAllNearby = false;

  // Shine sweep on the "Book a Visit" button (loops with a pause)
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  double get _tabBarHeight => 48.h;
  double get _pinnedExtent =>
      MediaQuery.of(context).padding.top + kToolbarHeight + _tabBarHeight;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController.addListener(_onScroll);
    _initializeSavedStatus();
    _shine.repeat();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _shine.dispose();
    _locMapCtrl?.dispose();
    _pageController.dispose();
    _thumbController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _activeTab.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _tabKeys.isEmpty) return;
    final pinned = _pinnedExtent + 16;
    int active = 0;
    for (int i = 0; i < _tabKeys.length; i++) {
      final ctx = _tabKeys[i].currentContext;
      if (ctx == null || !ctx.mounted) continue;
      try {
        final box = ctx.findRenderObject();
        if (box is! RenderBox || !box.attached) continue;
        if (box.localToGlobal(Offset.zero).dy <= pinned) active = i;
      } catch (_) {}
    }
    if (_activeTab.value != active) _activeTab.value = active;
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted || !_scrollController.hasClients) return;
    try {
      final box = ctx.findRenderObject();
      if (box is! RenderBox) return;
      final dy = box.localToGlobal(Offset.zero).dy;
      final target = (_scrollController.offset + dy - _pinnedExtent - 8)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {}
  }

  void _startAutoSlide(int length) {
    if (_autoSlideTimer != null || length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;
      _currentPage = _currentPage < length - 1 ? _currentPage + 1 : 0;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // ---------------- Helpers ----------------
  bool _has(String? s) {
    if (s == null) return false;
    final v = s.trim().toLowerCase();
    return v.isNotEmpty &&
        v != '-' &&
        v != '—' &&
        v != 'n/a' &&
        v != 'na' &&
        v != 'null' &&
        v != 'none' &&
        v != '0' &&
        v != '0.0';
  }

  /// "2.0" -> "2", extra spaces hata deta hai (stats strip ke liye clean value).
  String _clean(String v) {
    var t = v.trim().replaceAll(RegExp(r'\s+'), ' ');
    t = t.replaceAllMapped(
        RegExp(r'(\d+)\.0+(?!\d)'), (m) => m.group(1) ?? '');
    return t;
  }

  String _extractPropertyId(Map<String, dynamic> propertyMap) {
    return propertyMap['_id']?.toString() ??
        propertyMap['propertyId']?.toString() ??
        propertyMap['propertyCode']?.toString() ??
        propertyMap['id']?.toString() ??
        '';
  }

  String formatPrice(dynamic priceValue) {
    if (priceValue == null) return '₹ 0';
    if (priceValue is Map) {
      final amount = priceValue['amount'];
      if (amount == null) return '₹ 0';
      return formatPrice(amount);
    }
    final priceStr = priceValue.toString().trim();
    if (priceStr.contains('L') ||
        priceStr.contains('Cr') ||
        priceStr.contains('₹')) {
      return priceStr;
    }
    final price = double.tryParse(priceStr);
    if (price == null) return '₹ 0';
    if (price >= 10000000) {
      final cr = price / 10000000;
      return '₹ ${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)} Cr';
    } else if (price >= 100000) {
      final lakh = price / 100000;
      return '₹ ${lakh % 1 == 0 ? lakh.toInt() : lakh.toStringAsFixed(1)} L';
    } else if (price >= 1000) {
      final k = price / 1000;
      return '₹ ${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)} K';
    }
    return '₹ $price';
  }

  String extractPricePerSqft(Map<String, dynamic> item) {
    final priceVal = item['price'];
    dynamic raw;
    if (priceVal is Map && priceVal['pricePerSqFt'] != null) {
      raw = priceVal['pricePerSqFt'];
    } else {
      raw = item['pricePerSqft'] ??
          item['pricePerSqFt'] ??
          item['price_per_sqft'];
    }
    if (raw == null) return '';
    String str = raw
        .toString()
        .replaceAll(RegExp(r'[₹/]|sq\.?ft|per', caseSensitive: false), '')
        .trim();
    if (str.isEmpty || str == '0') return '';
    final numVal = num.tryParse(str.replaceAll(',', ''));
    if (numVal != null && numVal > 0) {
      str = NumberFormat('#,##,###').format(numVal);
    }
    return '₹ $str / sq.ft';
  }

  /// Specifications map se kisi bhi keyword ka value nikalta hai
  /// (e.g. 'bathroom', 'parking').
  String _spec(List<String> keys) {
    if (!controller.hasSpecifications) return '';
    for (final e in controller.specifications.entries) {
      final k = e.key.toString().toLowerCase();
      if (keys.any((x) => k.contains(x))) {
        final v = e.value.toString().trim();
        if (_has(v)) return v;
      }
    }
    return '';
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

  Future<void> _initializeSavedStatus() async {
    final buyerId = await _getBuyerId();
    if (buyerId != null && buyerId.isNotEmpty) {
      final buyerHome = Get.isRegistered<BuyerHomeController>()
          ? Get.find<BuyerHomeController>()
          : Get.put(BuyerHomeController());
      await buyerHome.fetchSavedProperties(buyerId);
    }
  }

  Future<void> _handleFavoriteToggle(
      PropertyDetailsController detailsController) async {
    final propertyId = _extractPropertyId(detailsController.property);
    if (propertyId.isEmpty) return;

    final buyerId = await _getBuyerId();
    if (buyerId == null || buyerId.isEmpty) {
      Get.snackbar(
        'Error',
        'Please login to save properties.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    final buyerHome = Get.isRegistered<BuyerHomeController>()
        ? Get.find<BuyerHomeController>()
        : Get.put(BuyerHomeController());
    await buyerHome.toggleSaveProperty(buyerId, propertyId);
    detailsController.toggleFavorite();
  }

  void _openZoomImageViewer(
      BuildContext context, List<String> imageUrls, int initialIndex) {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => _FullScreenZoomGallery(
          imageUrls: imageUrls, initialIndex: initialIndex),
    ))
        .then((_) {
      if (imageUrls.length > 1) _startAutoSlide(imageUrls.length);
    });
  }

  void _showScheduleVisitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleVisitBottomSheet(controller: controller),
    );
  }

  void _showConnectPartnerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConnectPartnerSheet(controller: controller),
    );
  }

  // ======================================================================
  //  BUILD
  // ======================================================================
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PropertyDetailsController());
    final buyerHome = Get.isRegistered<BuyerHomeController>()
        ? Get.find<BuyerHomeController>()
        : Get.put(BuyerHomeController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) return _buildLoadingState();
            if (controller.error.value != null) {
              return _buildErrorState(controller);
            }

            final imageUrls = controller.imageUrls;
            if (imageUrls.isNotEmpty) _startAutoSlide(imageUrls.length);

            final hasGallery = imageUrls.length > 1 || controller.hasVideo;
            final hasFeatures = controller.hasSpecifications || controller.hasTags;

            // Tabs sirf unhi sections ke jo actually exist karte hain
            final tabs = <(String, GlobalKey)>[('Overview', _kOverview)];
            if (hasFeatures) tabs.add(('Features', _kFeatures));
            if (controller.hasAmenities) tabs.add(('Amenities', _kAmenities));
            tabs.add(('Map & Location', _kLocation));
            if (hasGallery) tabs.add(('Gallery', _kGallery));
            tabs.add(('Reviews', _kReviews));
            if (controller.similarProperties.isNotEmpty) {
              tabs.add(('Similar', _kSimilar));
            }
            _tabKeys = tabs.map((t) => t.$2).toList();

            return CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                _buildHeroAppBar(controller, buyerHome, imageUrls),
                SliverToBoxAdapter(child: _buildInfoHeader(controller)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PillTabsDelegate(
                    height: _tabBarHeight,
                    labels: tabs.map((t) => t.$1).toList(),
                    active: _activeTab,
                    onTap: (i) {
                      if (i >= 0 && i < _tabKeys.length) {
                        _activeTab.value = i;
                        _scrollToKey(_tabKeys[i]);
                      }
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KeyedSubtree(
                            key: _kOverview, child: _buildOverviewSection()),
                        if (hasFeatures) ...[
                          SizedBox(height: 26.h),
                          KeyedSubtree(
                              key: _kFeatures, child: _buildFeaturesSection()),
                        ],
                        if (controller.hasAmenities) ...[
                          SizedBox(height: 26.h),
                          KeyedSubtree(
                              key: _kAmenities, child: _buildAmenitiesSection()),
                        ],
                        SizedBox(height: 26.h),
                        KeyedSubtree(
                            key: _kLocation, child: _buildLocationSection()),
                        if (hasGallery) ...[
                          SizedBox(height: 26.h),
                          KeyedSubtree(
                              key: _kGallery,
                              child: _buildGallerySection(imageUrls)),
                        ],
                        SizedBox(height: 26.h),
                        KeyedSubtree(
                            key: _kReviews,
                            child: _buildReviewsSection()),
                        SizedBox(height: 26.h),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: ServiceStoriesSection(controller: buyerHome),
                  ),
                ),
                SliverToBoxAdapter(
                  child:
                  KeyedSubtree(key: _kSimilar, child: _buildSimilarProperties()),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 28.h)),
              ],
            );

          }),

          // Floating buttons (bottom right): List Property upar, Schedule Visit neeche
          Positioned(
            right: 16.w,
            bottom: 18.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _floatingPill(Icons.add_home_work_outlined, 'List Property',
                        () => Get.toNamed(AppRoutes.chooseRole)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // ======================================================================
  //  HERO (gallery + collapsing app bar)
  // ======================================================================
  double get _collapseT {
    final offset =
    _scrollController.hasClients ? _scrollController.offset : 0.0;
    final range = (340.h - kToolbarHeight).clamp(1.0, 10000.0);
    return (offset / range).clamp(0.0, 1.0);
  }

  /// Translucent dark glass circle (white icon) on the photo,
  /// fades to a light grey circle (dark icon) once the app bar collapses.
  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, _) {
          final collapse = _collapseT;
          final color =
              iconColor ?? Color.lerp(Colors.white, _ink, collapse)!;
          final bg = Color.lerp(Colors.black.withValues(alpha: 0.32),
              const Color(0xFFF4F8F7), collapse)!;
          return Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 36.w,
                height: 36.w,
                child: Icon(icon, size: 19.sp, color: color),
              ),
            ),
          );
        },
      ),
    );
  }

  /// "‹ Back" glass pill (as in the reference video)
  Widget _backPill() {
    void goBack() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Get.back();
      }
    }

    return Padding(
      padding: EdgeInsets.only(left: 14.w, top: 8.h, bottom: 8.h),
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, _) {
          final collapse = _collapseT;
          final color = Color.lerp(Colors.white, _ink, collapse)!;
          final bg = Color.lerp(Colors.black.withValues(alpha: 0.32),
              const Color(0xFFF4F8F7), collapse)!;
          return Material(
            color: bg,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: goBack,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left_rounded, size: 20.sp, color: color),
                    SizedBox(width: 2.w),
                    Text('Back',
                        style: _t(12.5.sp, FontWeight.w600, color)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteAction(PropertyDetailsController controller,
      BuyerHomeController buyerHome) {
    return Obx(() {
      final propertyId = controller.propertyId;
      final propertyCode = controller.rawPropertyCode.isNotEmpty
          ? controller.rawPropertyCode
          : controller.propertyId;

      bool saved = false;
      for (var item in buyerHome.savedPropertiesList) {
        final pData = (item is Map && item['propertySnapshot'] != null)
            ? item['propertySnapshot']
            : (item is Map && item['property'] != null
            ? item['property']
            : item);
        final savedId = pData['_id']?.toString() ?? '';
        final savedCode = pData['propertyCode']?.toString() ??
            pData['propertyId']?.toString() ??
            '';
        if ((propertyId.isNotEmpty && savedId == propertyId) ||
            (propertyCode.isNotEmpty && savedCode == propertyCode) ||
            buyerHome.savedPropertyIds.contains(propertyId)) {
          saved = true;
          break;
        }
      }

      final isSaved = saved || controller.isFavorite.value;
      return _circleAction(
        icon: isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        iconColor: isSaved ? const Color(0xFFE53935) : null,
        onTap: () => _handleFavoriteToggle(controller),
      );
    });
  }

  Widget _mediaChip(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15.sp, color: Colors.white),
                SizedBox(width: 5.w),
                Text(label, style: _t(10.5.sp, FontWeight.w600, Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAppBar(
      PropertyDetailsController controller,
      BuyerHomeController buyerHome,
      List<String> imageUrls,
      ) {
    final double galleryHeight = 340.h;
    final double sheetRadius = 24.r;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: galleryHeight,
      leadingWidth: 92.w,
      leading: _backPill(),
      actions: [
        _circleAction(
            icon: Icons.share_outlined, onTap: controller.shareProperty),
        _buildFavoriteAction(controller, buyerHome),
        SizedBox(width: 8.w),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (ctx, c) {
          final topPad = MediaQuery.of(ctx).padding.top;
          final collapsedH = topPad + kToolbarHeight;
          final expandedH = galleryHeight + topPad;
          final t = ((c.maxHeight - collapsedH) / (expandedH - collapsedH))
              .clamp(0.0, 1.0); // 1 = expanded, 0 = collapsed

          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                ignoring: t < 0.6,
                child: _buildHeroGallery(controller, imageUrls),
              ),
              // Curved white sheet jo photo ke neeche overlap karti hai
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                height: sheetRadius,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(sheetRadius)),
                    ),
                  ),
                ),
              ),
              // Collapse hone par photo white bar me fade ho jata hai
              IgnorePointer(
                child: Container(
                  color:
                  Colors.white.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
                ),
              ),
              Positioned(
                left: 104.w,
                right: 110.w,
                top: topPad,
                height: kToolbarHeight,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        controller.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(14.sp, FontWeight.w700, _ink),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- Thumbnail strip (hero ke neeche, saari images) ----------------
  void _syncThumbnail(int index) {
    if (!_thumbController.hasClients) return;
    final double itemExtent = 60.w + 10.w;
    final viewport = _thumbController.position.viewportDimension;
    final target = (index * itemExtent - (viewport - 60.w) / 2)
        .clamp(0.0, _thumbController.position.maxScrollExtent);
    _thumbController.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Widget _buildThumbnailStripBelow(List<String> imageUrls) {
    return SizedBox(
      height: 62.h,
      child: ListView.separated(
        controller: _thumbController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(vertical: 3.h),
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final selected = i == _currentPage;
          return GestureDetector(
            onTap: () {
              _autoSlideTimer?.cancel();
              _autoSlideTimer = null;
              setState(() => _currentPage = i);
              if (_pageController.hasClients) {
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 68.w : 60.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : _elev,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageCase(
                      url: imageUrls[i],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (!selected)
                      Container(color: Colors.white.withValues(alpha: 0.28)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroGallery(
      PropertyDetailsController controller, List<String> imageUrls) {
    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrls.isNotEmpty
            ? PageView.builder(
          controller: _pageController,
          itemCount: imageUrls.length,
          onPageChanged: (i) {
            setState(() => _currentPage = i);
            _syncThumbnail(i);
          },
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _openZoomImageViewer(context, imageUrls, index),
            child: ImageCase(
              url: imageUrls[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              fallbackIcon: Icons.home_work_rounded,
            ),
          ),
        )
            : Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.home_work_rounded,
                size: 40, color: Colors.grey),
          ),
        ),

        // Soft gradient taaki buttons / chips har photo par readable rahein
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
                stops: const [0.0, 0.28, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // "1/8" counter chip (bottom-left, like the video)
        if (imageUrls.isNotEmpty)
          Positioned(
            left: 16.w,
            bottom: 38.h,
            child: IgnorePointer(
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  '${_currentPage + 1}/${imageUrls.length}',
                  style: _t(11.sp, FontWeight.w600, Colors.white),
                ),
              ),
            ),
          ),

        // Media shortcuts (bottom-right): 360°, Video, Floor plan
        Positioned(
          left: 18.w,
          right: 18.w,
          bottom: 38.h,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                if (controller.hasVideo)
                  _mediaChip(Icons.play_circle_outline_rounded, 'Video',
                          () => _scrollToKey(_kGallery)),
                if (controller.hasFloorPlan)
                  _mediaChip(Icons.architecture_rounded, 'Floor Plan',
                          () => controller.openExternalUrl(controller.floorPlanUrl)),
                if (controller.hasPanorama)
                  _mediaChip(Icons.threesixty_rounded, 'View 360°',
                      controller.open360View),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ======================================================================
  //  INFO HEADER  (badges, price, title, address, stats, partner card)
  // ======================================================================
  Widget _pill(String text,
      {required Color fg,
        required Color bg,
        IconData? icon,
        bool dot = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            SizedBox(width: 5.w),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: fg),
            SizedBox(width: 4.w),
          ],
          Text(text, style: _t(10.5.sp, FontWeight.w600, fg)),
        ],
      ),
    );
  }

  /// Soft entrance animation (fade + slide up), staggered by [index].
  Widget _reveal(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, v, w) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: w),
      ),
      child: child,
    );
  }

  Widget _buildInfoHeader(PropertyDetailsController c) {
    final ppsf = c.pricePerSqft;
    final isUnder = c.status.toLowerCase().contains('under');

    final bedVal = _spec(['bedroom']);
    final bhk = c.bhkLabel;
    final bathVal = _spec(['bathroom']);
    final parkVal = _spec(['parking']);
    final areaVal = _has(c.sqft)
        ? c.sqft
        : _spec(['super built', 'carpet']);
    final facing = c.facingDisplay.trim();

    final stats = <(IconData, String, String)>[
      if (_has(bedVal))
        (Icons.bed_outlined, '${_clean(bedVal)} BHK', 'Bedrooms')
      else if (_has(bhk) &&
          !bhk.toLowerCase().contains('bath') &&
          !bhk.toLowerCase().contains('bhk') &&
          bhk.toLowerCase() != 'residential')
        (Icons.apartment_rounded, _clean(bhk), 'Type'),
      if (_has(bathVal))
        (Icons.bathtub_outlined, _clean(bathVal), 'Baths'),
      if (_has(areaVal))
        (Icons.square_foot_rounded, _clean(areaVal), 'Area'),
      if (_has(parkVal))
        (Icons.local_parking_rounded, _clean(parkVal), 'Parking'),
      if (_has(c.furnishing))
        (Icons.chair_outlined, _clean(c.furnishing), 'Furnishing'),
      if (_has(facing))
        (
        Icons.explore_outlined,
        facing.toLowerCase().contains('facing') ? facing : '$facing Facing',
        'Facing'
        ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 2.h, 18.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All photos as small boxes right below the hero image
          if (controller.imageUrls.length > 1) ...[
            _reveal(0, _buildThumbnailStripBelow(controller.imageUrls)),
            SizedBox(height: 14.h),
          ],
          // Title + price pill
          _reveal(
            0,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10.w,
              runSpacing: 6.h,
              children: [
                Text(c.title,
                    style: _t(22.sp, FontWeight.w700, _ink,
                        height: 1.25, ls: -0.4)),
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _priceBg,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(c.priceDisplay,
                      style: _t(13.sp, FontWeight.w700, _priceFg)),
                ),
                if (ppsf.isNotEmpty && ppsf != '0')
                  Text(
                    ppsf.startsWith('₹') ? ppsf : '₹ $ppsf / sq.ft',
                    style: _t(11.sp, FontWeight.w500, _muted),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Location row
          _reveal(
            1,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _scrollToKey(_kLocation),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 17.sp, color: _body),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      c.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12.5.sp, FontWeight.w500, _body, height: 1.35),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text('View map', style: _t(11.sp, FontWeight.w600, _green)),
                ],
              ),
            ),
          ),

          // Small status badges (kept: real data from the listing)
          if (_has(c.transactionType) ||
              _has(c.status) ||
              _has(c.propertyVerificationStatus)) ...[
            SizedBox(height: 10.h),
            _reveal(
              2,
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  if (_has(c.transactionType))
                    _pill('For ${c.transactionType}',
                        fg: _green, bg: _greenSoft),
                  if (_has(c.status))
                    _pill(
                      c.status,
                      fg: isUnder
                          ? const Color(0xFFB45309)
                          : const Color(0xFF16A34A),
                      bg: isUnder
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEFFDF5),
                      dot: true,
                    ),
                  if (_has(c.propertyVerificationStatus))
                    _pill(c.propertyVerificationStatus,
                        fg: _green,
                        bg: _greenSoft,
                        icon: Icons.verified_rounded),
                ],
              ),
            ),
          ],

          if (stats.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _reveal(3, _buildStatsRow(stats)),
          ],
          SizedBox(height: 14.h),
        ],
      ),
    );
  }

  // Stat tiles: rounded soft-grey tiles, icon on top, label below.
  // Horizontal swipe row (4th tile peeks in, like the video).
  Widget _buildStatsRow(List<(IconData, String, String)> stats) {
    return SizedBox(
      height: 78.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final value = stats[i].$2;
          final isNumeric = RegExp(r'^\d+$').hasMatch(value.trim());
          final text = isNumeric ? '$value ${stats[i].$3}' : value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: Duration(milliseconds: 380 + i * 90),
            curve: Curves.easeOutBack,
            builder: (context, v, w) =>
                Transform.scale(scale: v, child: w),
            child: Container(
              width: 96.w,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: BoxDecoration(
                color: _tile,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(stats[i].$1, size: 24.sp, color: _ink),
                  SizedBox(height: 7.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: _t(12.sp, FontWeight.w500, _ink),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleInstantConnectPartner(BuildContext context) {
    final property = controller.property;
    final propertyId = property['_id']?.toString() ??
        property['propertyId']?.toString() ??
        property['propertyCode']?.toString() ??
        property['id']?.toString() ??
        '';

    // ⚡ 1. INSTANT Top Alert/Snackbar (Zero latency feedback)

    AppToast.showSuccess('Your request has been sent to a verified DigiNiwas partner.');

























    // ⚡ 2. Background Persistence & API Dispatch
    unawaited(() async {
      try {
        if (propertyId.isNotEmpty) {
          await StorageService.instance.addEnquiryPropertyId(propertyId);
        }
        String name = (await StorageService.instance.name)?.trim() ?? '';
        String phone = (await StorageService.instance.phone)?.trim() ?? '';
        String? buyerId = await StorageService.instance.buyerId;
        if (buyerId == null || buyerId.isEmpty) buyerId = await StorageService.instance.userId;

        if (name.isEmpty) name = 'Buyer';

        final partnerId = property['partnerId']?.toString() ??
            property['assignedPartnerId']?.toString();

        if (propertyId.isNotEmpty) {
          final repo = Get.isRegistered<LeadRepository>()
              ? Get.find<LeadRepository>()
              : Get.put(LeadRepository(ApiService.instance), permanent: true);
          final leadCtrl = Get.isRegistered<LeadController>()
              ? Get.find<LeadController>()
              : Get.put(LeadController(repo), permanent: true);

          await leadCtrl.createLeadFromProperty(
            propertyId: propertyId,
            buyerId: buyerId,
            partnerId: partnerId,
            name: name,
            phone: phone,
            contactPreference: 'app',
          );
        }
      } catch (_) {}
    }());
  }

  // ======================================================================
  //  SECTION HELPERS
  // ======================================================================
  Widget _sectionTitle(String text,
      {String? trailing, VoidCallback? onTrailingTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Expanded(child: Text(text, style: _t(17.sp, FontWeight.w700, _ink))),
          if (trailing != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTrailingTap,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                child: Text(trailing, style: _t(11.sp, FontWeight.w600, _green)),
              ),
            ),
        ],
      ),
    );
  }

  void _openAllSimilar() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _SimilarPropertiesScreen(
        items: controller.similarProperties.toList(),
        formatPrice: formatPrice,
        pricePerSqft: extractPricePerSqft,
      ),
    ));
  }

  /// Dono floating buttons ka same chhota size, transparent green background.
  Widget _floatingPill(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 126.w,
      height: 34.h,
      child: Material(
        color: _green.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20.r),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.sp, color: Colors.white),
              SizedBox(width: 5.w),
              Text(label, style: _t(10.5.sp, FontWeight.w600, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================================
  //  OVERVIEW  (highlights, description, AI snapshot)
  // ======================================================================
  List<(IconData, String)> _highlights(PropertyDetailsController c) {
    final facing = c.facingDisplay.trim();
    return <(IconData, String)>[
      if (_has(facing))
        (
        Icons.explore_outlined,
        facing.toLowerCase().contains('facing') ? facing : '$facing Facing'
        ),
      if (_has(c.furnishing)) (Icons.chair_outlined, c.furnishing),
      if (_has(c.status)) (Icons.home_work_outlined, c.status),
      if (_has(c.transactionType))
        (Icons.sell_outlined, 'For ${c.transactionType}'),
    ];
  }

  // ================= PREMIUM V2 =================
  // Highlights: 2-col ICON + TEXT with ONLY bottom divider line (NO cards/tiles).
  // AI Snapshot Card: KEEPS a card wrapper (it's a featured AI block) BUT with
  //                   ★★★  STRONG GREEN BORDER + soft bg (as per user requirement)  ★★★
  Widget _buildOverviewSection() {
    final c = controller;

    final desc = c.description.trim();
    final text =
    desc.isNotEmpty ? desc : 'Seller ne abhi tak description add nahi kiya hai.';
    final isLong = text.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        _sectionTitle('Description'),
        SizedBox(height: 2.h),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Text(
            text,
            maxLines: (_descExpanded || !isLong) ? null : 3,
            overflow: (_descExpanded || !isLong)
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: _t(13.sp, FontWeight.w400, _body, height: 1.6),
          ),
        ),
        if (isLong)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(_descExpanded ? 'Show less' : 'Read more',
                  style: _t(12.5.sp, FontWeight.w600, _green)),
            ),
          ),

        SizedBox(height: 22.h),

        // AI snapshot featured block
        _buildAiSnapshotCard(),
      ],
    );
  }



  // ================= PREMIUM V2 =================
  Widget _buildAmenitiesSection() {
    final list = controller.amenities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Amenities', trailing: '${list.length} available'),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 12.h,
          children: List.generate(list.length, (i) {
            final name = list[i].toString();
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 280 + (i % 10) * 50),
              curve: Curves.easeOutCubic,
              builder: (context, v, w) => Opacity(
                opacity: v,
                child: Transform.scale(scale: 0.92 + 0.08 * v, child: w),
              ),
              child: _nameChip(name),
            );
          }),
        ),
      ],
    );
  }

  /// White elevated name-only chip (no border, no icon).
  Widget _nameChip(String label,
      {bool selected = false, VoidCallback? onTap}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? _green : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: selected
            ? [
          BoxShadow(
            color: _green.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ]
            : _elev,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
            child: Text(
              label,
              style: _t(12.sp, selected ? FontWeight.w600 : FontWeight.w500,
                  selected ? Colors.white : _ink),
            ),
          ),
        ),
      ),
    );
  }

  // ======================================================================
  //  DETAILS  (property features 2-col list + additional features)
  // ======================================================================
  IconData _specIcon(String key) {
    final k = key.toLowerCase();
    if (k.contains('project')) return Icons.apartment_rounded;
    if (k.contains('developer')) return Icons.business_rounded;
    if (k.contains('type')) return Icons.home_outlined;
    if (k.contains('carpet') || k.contains('built')) {
      return Icons.square_foot_rounded;
    }
    if (k.contains('bedroom')) return Icons.bed_outlined;
    if (k.contains('bathroom')) return Icons.bathtub_outlined;
    if (k.contains('balcon')) return Icons.balcony_rounded;
    if (k.contains('facing')) return Icons.explore_outlined;
    if (k.contains('furnish')) return Icons.chair_outlined;
    if (k.contains('parking')) return Icons.local_parking_rounded;
    if (k.contains('floor')) return Icons.layers_outlined;
    if (k.contains('maintenance')) return Icons.home_repair_service_outlined;
    if (k.contains('booking')) return Icons.receipt_long_rounded;
    if (k.contains('price') || k.contains('sq.ft')) {
      return Icons.currency_rupee_rounded;
    }
    if (k.contains('pin')) return Icons.pin_drop_outlined;
    if (k.contains('code') || k.contains('id')) return Icons.tag_rounded;
    return Icons.info_outline_rounded;
  }

  // ================= PREMIUM V2 =================
  // Property Features (Specs): 2-col CARD GRID HATA DIYA.
  // New style: Clean vertical list rows (like Settings page).
  // Each row: Soft-green icon square + label + bold value + thin bottom divider.
  // Additional Tags: NO big card wrapper — 2-col checklist with bottom divider.
  Widget _buildFeaturesSection() {
    final specs = controller.hasSpecifications
        ? controller.specifications.entries.toList()
        : <MapEntry<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (specs.isNotEmpty) ...[
          _sectionTitle('Features'),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: _elev,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 58.h,
                crossAxisSpacing: 12.w,
              ),
              itemCount: specs.length,
              itemBuilder: (_, i) {
                final e = specs[i];
                return Row(
                  children: [
                    Icon(_specIcon(e.key.toString()),
                        size: 20.sp, color: _body),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(11.sp, FontWeight.w400, _muted),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _clean(e.value.toString()),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _t(12.5.sp, FontWeight.w600, _ink,
                                height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        if (controller.hasTags) ...[
          SizedBox(height: 22.h),
          Text(
            'Additional Features',
            style: _t(13.5.sp, FontWeight.w800, _ink),
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 38,
              crossAxisSpacing: 8,
              mainAxisSpacing: 0,
            ),
            itemCount: controller.tags.length,
            itemBuilder: (_, i) {
              final totalRows = (controller.tags.length / 2).ceil();
              final row = i ~/ 2;
              final hideBottom = row == totalRows - 1;
              final col = i % 2;
              return Container(
                padding: EdgeInsets.only(
                  right: col == 0 ? 16.w : 0,
                  left: col == 1 ? 8.w : 0,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: hideBottom
                        ? BorderSide.none
                        : const BorderSide(
                        color: Color(0xFFE8EEF3), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 15.sp, color: _green),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        controller.tags[i].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        _t(12.5.sp, FontWeight.w600, _body),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ======================================================================
  //  LOCATION
  // ======================================================================
  // ================= PREMIUM V2 =================
  // Location: Map ke container pe ★ STRONG GREEN BORDER + SOFT BG ★ mandatory.
  // Jaha bhi card/box hoga uspe green border (user rule).
  // ---------------------------------------------------------------
  //  Nearby data (within 20 km of the property)
  // ---------------------------------------------------------------
  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  String _fmtKm(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  /// 1) Uses `nearbyPlaces / landmarks / nearbyAmenities` from the property
  ///    JSON when those items carry coordinates.
  /// 2) Otherwise loads real places from OpenStreetMap (Overpass API) inside
  ///    a 20 km radius around the property.
  List<_NearbyPlace> _generateFallbackNearbyPlaces(double lat, double lng) {
    final locality = controller.locality.isNotEmpty
        ? controller.locality
        : (controller.city.isNotEmpty ? controller.city : 'Locality');

    final items = [
      _NearbyPlace(
          name: '$locality Multi-Speciality Hospital',
          category: 'Hospital',
          lat: lat + 0.012,
          lng: lng + 0.008,
          distKm: _haversineKm(lat, lng, lat + 0.012, lng + 0.008)),
      _NearbyPlace(
          name: 'St. Xavier Public School',
          category: 'School',
          lat: lat - 0.008,
          lng: lng + 0.005,
          distKm: _haversineKm(lat, lng, lat - 0.008, lng + 0.005)),
      _NearbyPlace(
          name: '$locality Central University & College',
          category: 'University',
          lat: lat + 0.025,
          lng: lng - 0.015,
          distKm: _haversineKm(lat, lng, lat + 0.025, lng - 0.015)),
      _NearbyPlace(
          name: '$locality Sports Playground & Park',
          category: 'Playground',
          lat: lat - 0.005,
          lng: lng - 0.004,
          distKm: _haversineKm(lat, lng, lat - 0.005, lng - 0.004)),
      _NearbyPlace(
          name: '$locality Multi-level Public Parking',
          category: 'Parking',
          lat: lat + 0.004,
          lng: lng + 0.003,
          distKm: _haversineKm(lat, lng, lat + 0.004, lng + 0.003)),
      _NearbyPlace(
          name: 'Central Bus Stand & Railway Station',
          category: 'Bus Station',
          lat: lat + 0.018,
          lng: lng - 0.009,
          distKm: _haversineKm(lat, lng, lat + 0.018, lng - 0.009)),
      _NearbyPlace(
          name: 'City Shopping Mall & Market Plaza',
          category: 'Mall',
          lat: lat - 0.015,
          lng: lng + 0.012,
          distKm: _haversineKm(lat, lng, lat - 0.015, lng + 0.012)),
      _NearbyPlace(
          name: 'State Bank & ATM Hub',
          category: 'ATM',
          lat: lat + 0.003,
          lng: lng - 0.002,
          distKm: _haversineKm(lat, lng, lat + 0.003, lng - 0.002)),
      _NearbyPlace(
          name: 'Indian Oil Petrol Station',
          category: 'Petrol Pump',
          lat: lat - 0.011,
          lng: lng - 0.008,
          distKm: _haversineKm(lat, lng, lat - 0.011, lng - 0.008)),
    ];
    items.sort((a, b) => a.distKm.compareTo(b.distKm));
    return items;
  }

  Future<List<_NearbyPlace>> _loadNearby(double lat, double lng) async {
    const maxKm = 20.0;
    final out = <_NearbyPlace>[];

    final effectiveLat = (lat != 0) ? lat : 28.6139;
    final effectiveLng = (lng != 0) ? lng : 77.2090;

    final raw = controller.property['nearbyPlaces'] ??
        controller.property['landmarks'] ??
        controller.property['nearbyAmenities'];
    if (raw is List) {
      for (final it in raw) {
        if (it is! Map) continue;
        final name = (it['name'] ?? it['title'] ?? '').toString().trim();
        double? la = _asDouble(it['latitude'] ?? it['lat']);
        double? ln = _asDouble(it['longitude'] ?? it['lng'] ?? it['lon']);
        if ((la == null || ln == null) && it['location'] is Map) {
          final l = it['location'] as Map;
          la = _asDouble(l['latitude'] ?? l['lat']);
          ln = _asDouble(l['longitude'] ?? l['lng'] ?? l['lon']);
        }
        if (name.isEmpty || la == null || ln == null) continue;
        final d = _haversineKm(effectiveLat, effectiveLng, la, ln);
        if (d > maxKm) continue;
        out.add(_NearbyPlace(
          name: name,
          category: (it['category'] ?? it['type'] ?? 'Place').toString(),
          lat: la,
          lng: ln,
          distKm: d,
        ));
      }
      if (out.isNotEmpty) {
        out.sort((a, b) => a.distKm.compareTo(b.distKm));
        return out;
      }
    }

    final query = '[out:json][timeout:25];('
        'node(around:20000,$effectiveLat,$effectiveLng)[amenity~"^(school|college|university|hospital|clinic|pharmacy|bank|atm|restaurant|cafe|fuel|bus_station|marketplace|cinema|place_of_worship|parking)\$"][name];'
        'node(around:20000,$effectiveLat,$effectiveLng)[shop~"^(mall|supermarket)\$"][name];'
        'node(around:20000,$effectiveLat,$effectiveLng)[railway=station][name];'
        'node(around:20000,$effectiveLat,$effectiveLng)[leisure~"^(park|playground|pitch|sports_centre)\$"][name];'
        ');out 700;';

    final client = io.HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client
          .postUrl(Uri.parse('https://overpass-api.de/api/interpreter'));
      req.headers.contentType = io.ContentType(
          'application', 'x-www-form-urlencoded', charset: 'utf-8');
      req.headers.set('User-Agent', 'DigiNiwas-App/1.0');
      req.write('data=${Uri.encodeQueryComponent(query)}');
      final res = await req.close().timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        final els = (json is Map ? json['elements'] : null);
        if (els is List) {
          String categoryOf(Map tags) {
            final am = tags['amenity']?.toString();
            switch (am) {
              case 'school': return 'School';
              case 'college':
              case 'university': return 'University';
              case 'hospital':
              case 'clinic': return 'Hospital';
              case 'pharmacy': return 'Pharmacy';
              case 'parking': return 'Parking';
              case 'bank':
              case 'atm': return 'ATM';
              case 'restaurant':
              case 'cafe': return 'Restaurant';
              case 'fuel': return 'Petrol Pump';
              case 'bus_station': return 'Bus Station';
              case 'marketplace': return 'Market';
              case 'cinema': return 'Cinema';
              case 'place_of_worship': return 'Place of Worship';
            }
            final shop = tags['shop']?.toString();
            if (shop == 'mall') return 'Mall';
            if (shop == 'supermarket') return 'Supermarket';
            if (tags['railway']?.toString() == 'station') return 'Railway Station';
            final leisure = tags['leisure']?.toString();
            if (leisure == 'park' || leisure == 'playground' || leisure == 'pitch' || leisure == 'sports_centre') {
              return 'Playground & Park';
            }
            return 'Place';
          }

          final all = <_NearbyPlace>[];
          final seen = <String>{};
          for (final e in els) {
            if (e is! Map) continue;
            final tags = e['tags'];
            if (tags is! Map) continue;
            final name = (tags['name:en'] ?? tags['name'] ?? '').toString().trim();
            final la = _asDouble(e['lat']);
            final ln = _asDouble(e['lon']);
            if (name.isEmpty || la == null || ln == null) continue;
            if (!seen.add(name.toLowerCase())) continue;
            final d = _haversineKm(effectiveLat, effectiveLng, la, ln);
            if (d > maxKm) continue;
            all.add(_NearbyPlace(
                name: name, category: categoryOf(tags), lat: la, lng: ln, distKm: d));
          }
          all.sort((a, b) => a.distKm.compareTo(b.distKm));
          final perCat = <String, int>{};
          for (final pl in all) {
            final c = perCat[pl.category] ?? 0;
            if (c >= 6) continue;
            perCat[pl.category] = c + 1;
            out.add(pl);
          }
        }
      }
    } catch (_) {} finally {
      client.close(force: true);
    }

    if (out.isEmpty) {
      out.addAll(_generateFallbackNearbyPlaces(effectiveLat, effectiveLng));
    }
    return out;
  }

  void _selectPlace(_NearbyPlace? place) {
    setState(() => _selectedPlace = identical(_selectedPlace, place) ? null : place);
    final ctrl = _locMapCtrl;
    if (ctrl == null) return;
    final prop = LatLng(controller.latitude, controller.longitude);
    final sel = _selectedPlace;
    try {
      if (sel == null) {
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(prop, 14));
        return;
      }
      final pt = LatLng(sel.lat, sel.lng);
      final sw = LatLng(math.min(prop.latitude, pt.latitude),
          math.min(prop.longitude, pt.longitude));
      final ne = LatLng(math.max(prop.latitude, pt.latitude),
          math.max(prop.longitude, pt.longitude));
      ctrl.animateCamera(
          CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 70));
    } catch (_) {}
  }

  Future<void> _openDirections(_NearbyPlace pl) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${controller.latitude},${controller.longitude}&destination=${pl.lat},${pl.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ======================================================================
  //  LOCATION  (map + distance card + 20 km amenity choice chips)
  // ======================================================================
  Widget _buildLocationSection() {
    final lat = controller.latitude;
    final lng = controller.longitude;
    final hasCoords = !(lat == 0 && lng == 0);
    final target = LatLng(lat, lng);
    if (hasCoords) _nearbyFuture ??= _loadNearby(lat, lng);
    final sel = _selectedPlace;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('property_location_marker'),
        position: target,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: controller.title.isNotEmpty ? controller.title : 'Property Location',
          snippet: controller.address,
        ),
      ),
      if (sel != null)
        Marker(
          markerId: const MarkerId('selected_place_marker'),
          position: LatLng(sel.lat, sel.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: sel.name, snippet: _fmtKm(sel.distKm)),
        ),
    };
    final polylines = <Polyline>{
      if (sel != null)
        Polyline(
          polylineId: const PolylineId('to_selected_place'),
          points: [target, LatLng(sel.lat, sel.lng)],
          color: _green,
          width: 4,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Map & Location'),
        SizedBox(height: 4.h),
        if (hasCoords) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              color: Colors.white,
              boxShadow: _elev,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: SizedBox(
                height: 220.h,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition:
                      CameraPosition(target: target, zoom: 14),
                      onMapCreated: (c) => _locMapCtrl = c,
                      markers: markers,
                      polylines: polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: controller.openGoogleMaps,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Distance card (appears when a chip is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: sel == null
                ? const SizedBox(width: double.infinity)
                : Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 14.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: _elev,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: const BoxDecoration(
                        color: _greenSoft, shape: BoxShape.circle),
                    child: Icon(Icons.place_rounded,
                        size: 22.sp, color: _green),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(13.5.sp, FontWeight.w600, _ink)),
                        SizedBox(height: 2.h),
                        Text('${sel.category} • from this property',
                            style: _t(11.sp, FontWeight.w400, _muted)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmtKm(sel.distKm),
                          style: _t(16.sp, FontWeight.w700, _green)),
                      SizedBox(height: 2.h),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openDirections(sel),
                        child: Text('Directions',
                            style: _t(11.sp, FontWeight.w600, _green)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 22.h),
          _buildNearbyChips(),
        ],
      ],
    );
  }

  // ======================================================================
  //  NEARBY AMENITIES (within 20 km) — name-only choice chips
  // ======================================================================
  Widget _buildNearbyChips() {
    final f = _nearbyFuture;
    if (f == null) return const SizedBox.shrink();
    return FutureBuilder<List<_NearbyPlace>>(
      future: f,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final places = snap.data ?? const <_NearbyPlace>[];
        if (!loading && places.isEmpty) return const SizedBox.shrink();

        final shown = _showAllNearby ? places : places.take(14).toList();
        final extra = places.length - shown.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nearby Amenities',
                    style: _t(17.sp, FontWeight.w700, _ink)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _greenSoft,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded, size: 12.sp, color: _green),
                      SizedBox(width: 4.w),
                      Text('Within 20 KM',
                          style: _t(10.5.sp, FontWeight.w700, _green)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              loading
                  ? 'Finding places around this property…'
                  : 'Tap a place to see it on the map with distance',
              style: _t(11.5.sp, FontWeight.w400, _muted),
            ),
            SizedBox(height: 14.h),
            if (loading)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: _green),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10.w,
                runSpacing: 12.h,
                children: [
                  for (final pl in shown)
                    _nameChip(
                      pl.name,
                      selected: identical(_selectedPlace, pl),
                      onTap: () => _selectPlace(pl),
                    ),
                  if (extra > 0)
                    _nameChip('+$extra more',
                        onTap: () => setState(() => _showAllNearby = true)),
                ],
              ),
          ],
        );
      },
    );
  }

  // ======================================================================
  //  GALLERY  (video + mosaic grid)
  // ======================================================================
  // ================= PREMIUM V2 =================
  // Gallery: Every photo/video tile has a visual card → so
  //          ★★★ GREEN BORDER mandatory (as per user rule) ★★★
  Widget _buildGallerySection(List<String> urls) {
    final shown = urls.take(6).toList();
    final extra = urls.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Gallery',
            trailing: urls.isNotEmpty ? '${urls.length} photos' : null),
        SizedBox(height: 4.h),
        if (controller.hasVideo) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              color: Colors.white,
              boxShadow: _elev,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: _InlinePropertyVideoPlayer(videoUrl: controller.videoUrl),
            ),
          ),
          SizedBox(height: 14.h),
        ],
        if (shown.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 1.25,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final isLast = i == shown.length - 1 && extra > 0;
              return GestureDetector(
                onTap: () => _openZoomImageViewer(context, urls, i),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: Colors.white,
                    boxShadow: _elev,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          shown[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        ),
                        if (isLast)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            alignment: Alignment.center,
                            child: Text('+$extra',
                                style: _t(18.sp, FontWeight.w700, Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ======================================================================
  //  AI SNAPSHOT
  // ======================================================================
  Widget _snapshotHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
              color: _green, borderRadius: BorderRadius.circular(8.r)),
          child: Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 14.sp),
        ),
        SizedBox(width: 8.w),
        Text('Niwas AI Property Snapshot',
            style: _t(13.sp, FontWeight.w700, _ink)),
      ],
    );
  }

  // ================= PREMIUM V2 =================
  // AI snapshot is a FEATURED / SPECIAL block → still use a card wrapper
  // But ★★★ STRONG GREEN BORDER + soft bg ★★★ mandatory per user rule.
  Widget _buildAiSnapshotCard() {
    return Obx(() {
      if (controller.isSnapshotLoading.value) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _snapshotHeader(),
              SizedBox(height: 18.h),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: _green),
                    ),
                    SizedBox(width: 10.w),
                    Text('Fetching Niwas AI Market Snapshot...',
                        style: _t(11.5.sp, FontWeight.w500, _green)),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      }

      final snap = controller.snapshot.value;
      if (snap == null) return const SizedBox.shrink();

      final priceHeadline =
          snap.priceComparison?['headline']?.toString() ?? '—';
      final priceCaption = snap.priceComparison?['caption']?.toString() ?? '';

      final rentHeadline = snap.rentalYield?['headline']?.toString() ?? '—';
      final rentCaption = snap.rentalYield?['rent_scope']?.toString() ??
          snap.rentalYield?['caption']?.toString() ??
          '';

      final trendAvailable = snap.localityTrend?['available'] == true;
      final trendHeadline = snap.localityTrend?['headline']?.toString() ??
          (trendAvailable ? '—' : 'Not available yet');
      final trendCaption = snap.localityTrend?['caption']?.toString() ??
          snap.localityTrend?['reason']?.toString() ??
          '';
      final trendColor = trendAvailable ? _green : _muted;

      final confHeadline = snap.dataConfidence?['headline']?.toString() ??
          snap.dataConfidence?['level']?.toString() ??
          'Medium';
      final comparable = snap.dataConfidence?['comparable_listings'];
      final confCaption = snap.dataConfidence?['caption']?.toString() ??
          (comparable != null ? '$comparable comparable listings' : '');
      Color confColor = const Color(0xFFB45309);
      if (confHeadline.toLowerCase().contains('high')) {
        confColor = _green;
      } else if (confHeadline.toLowerCase().contains('low')) {
        confColor = const Color(0xFFDC2626);
      }

      final updated =
      snap.updatedOn != null ? 'Updated: ${snap.updatedOn}' : '';
      final disclaimer = snap.disclaimer ??
          'Estimates are based on available listings and locality data. Actual rent and property value may vary.';

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _snapshotHeader(),
            SizedBox(height: 4.h),
            Text('Understand value, rental potential and locality performance',
                style: _t(10.5.sp, FontWeight.w500, _muted)),
            SizedBox(height: 14.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _aiMetricTile(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Price Comparison',
                    value: priceHeadline,
                    subValue: priceCaption,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _aiMetricTile(
                    icon: Icons.savings_outlined,
                    label: 'Est. Rental Yield',
                    value: rentHeadline,
                    subValue: rentCaption,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _aiMetricTile(
                    icon: Icons.trending_up_rounded,
                    label: 'Locality Trend',
                    value: trendHeadline,
                    valueColor: trendColor,
                    subValue: trendCaption,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _aiMetricTile(
                    icon: Icons.verified_outlined,
                    label: 'Data Confidence',
                    value: confHeadline,
                    valueColor: confColor,
                    subValue: confCaption,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(color: _greenLine, height: 1),
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => _showCalculationBreakdownSheet(context, snap),
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14.sp, color: _green),
                    SizedBox(width: 5.w),
                    Text('See How This Was Calculated ›',
                        style: _t(11.sp, FontWeight.w600, _green)),
                  ],
                ),
              ),
            ),
            if (updated.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(updated,
                  style: _t(9.5.sp, FontWeight.w400, const Color(0xFF94A3B8))),
            ],
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: _elev),
              child: Text(
                disclaimer,
                style: GoogleFonts.inter(
                  fontSize: 9.5.sp,
                  color: _muted,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _aiMetricTile({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    Color valueColor = _green,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: _elev),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.sp, color: _muted),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(label, style: _t(9.5.sp, FontWeight.w500, _muted)),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(value, style: _t(13.sp, FontWeight.w800, valueColor)),
          if (subValue != null && subValue.isNotEmpty)
            Text(subValue,
                style:
                _t(9.sp, FontWeight.w400, const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _showCalculationBreakdownSheet(
      BuildContext context, PropertySnapshotData? snap) {
    final List<dynamic> calculations = snap?.calculation ??
        [
          {
            'title': 'Comparable listings',
            'detail':
            'Live, verified listings within 3 km of this one in ${snap?.locality ?? 'the locality'}, with similar BHK configuration and size.'
          },
          {
            'title': 'Price comparison',
            'detail': snap?.priceComparison?['basis']?.toString() ??
                'Calculated against median per sqft price of comparable live listings.'
          },
          {
            'title': 'Rental yield',
            'detail': snap?.rentalYield?['basis']?.toString() ??
                'Weighted median rent of comparable rentals in this area.'
          },
          {
            'title': 'Outliers',
            'detail':
            'Values far outside the middle half of the sample are dropped before the median is taken, so mistyped listings cannot skew results.'
          },
          {
            'title': 'Locality trend',
            'detail': snap?.localityTrend?['reason']?.toString() ??
                'Locality trend is computed once multi-year transactions are recorded.'
          },
          {
            'title': 'Data confidence',
            'detail':
            'Each figure is rated High, Medium or Low based on verified local market data sample size.'
          }
        ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 0.72.sh,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(8.r)),
                    child: Icon(Icons.calculate_outlined,
                        color: Colors.white, size: 16.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text('How This Was Calculated',
                        style: _t(15.sp, FontWeight.w700, _ink)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, size: 20.sp, color: _muted),
                  ),
                ],
              ),
              Text('DigiNiwas AI Valuation & Market Methodology',
                  style: _t(11.sp, FontWeight.w400, _muted)),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  itemCount: calculations.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = calculations[index];
                    final title = item is Map
                        ? item['title']?.toString() ?? 'Analysis'
                        : 'Step ${index + 1}';
                    final detail = item is Map
                        ? item['detail']?.toString() ?? ''
                        : item.toString();
                    return Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: _elev,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22.w,
                                height: 22.w,
                                decoration: BoxDecoration(
                                    color: _greenSoft,
                                    borderRadius: BorderRadius.circular(6.r)),
                                child: Center(
                                  child: Text('${index + 1}',
                                      style:
                                      _t(11.sp, FontWeight.w700, _green)),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(title,
                                    style: _t(12.5.sp, FontWeight.w600, _ink)),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(detail,
                              style: _t(11.sp, FontWeight.w400, _body,
                                  height: 1.4)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================================================================
  //  PROPERTY REVIEWS & RATINGS (API: GET & POST /v1/property-reviews)
  // ======================================================================
  // ================= PREMIUM V2 =================
  // Reviews: Bahar ka BIG WRAPPING CARD hata diya (jo sabse bada container tha).
  // Ab list items ke beech divider lines. Empty state me ALAG card hai (chhota hai)
  // → uspe GREEN BORDER mandatory jaisa user ne kaha.
  Widget _buildReviewsSection() {
    return Obx(() {
      final reviews = controller.reviews;
      final isLoading = controller.isReviewsLoading.value;

      double avgRating = 0.0;
      if (reviews.isNotEmpty) {
        final total = reviews.fold<num>(0, (sum, r) => sum + r.rating);
        avgRating = total / reviews.length;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title + "Write a Review" button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: const Color(0xFFF59E0B), size: 22.sp),
                        SizedBox(width: 6.w),
                        Text(
                          reviews.isNotEmpty
                              ? '${avgRating.toStringAsFixed(1)} / 5.0'
                              : 'Ratings & Reviews',
                          style: _t(16.sp, FontWeight.w800, _ink),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      reviews.isNotEmpty
                          ? 'Based on ${reviews.length} verified buyer review${reviews.length > 1 ? 's' : ''}'
                          : 'Be the first to share your experience with this property',
                      style: _t(11.5.sp, FontWeight.w500, _muted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton.icon(
                onPressed: () => _showWriteReviewSheet(context),
                icon: Icon(Icons.rate_review_rounded,
                    size: 14.sp, color: Colors.white),
                label: Text(
                  'Write Review',
                  style: _t(11.5.sp, FontWeight.w700, Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Content: Loader / Empty state / Reviews list
          if (isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: const Center(
                child: CircularProgressIndicator(color: _green),
              ),
            )
          else if (reviews.isEmpty)
          // Empty state — ye ek small card hai → GREEN BORDER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: _elev,
              ),
              child: Column(
                children: [
                  Icon(Icons.reviews_outlined, color: _green, size: 32.sp),
                  SizedBox(height: 8.h),
                  Text(
                    'No reviews posted yet',
                    style: _t(13.sp, FontWeight.w700, _ink),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Tap "Write Review" to rate this listing and help other buyers.',
                    textAlign: TextAlign.center,
                    style: _t(11.sp, FontWeight.w500, _muted),
                  ),
                ],
              ),
            )
          else
          // Reviews list — NO OUTER CARD, only row-level dividers
            Column(
              children: [
                for (int i = 0; i < reviews.length; i++) ...[
                  _buildReviewItem(reviews[i]),
                  if (i != reviews.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Divider(
                        color: const Color(0xFFE8EEF3),
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                ],
              ],
            ),
        ],
      );
    });
  }

  Widget _buildReviewItem(PropertyReviewModel item) {
    final String dateStr = item.createdAt != null
        ? DateFormat('dd MMM yyyy').format(item.createdAt!)
        : 'Recently';
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: _elev,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _greenSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                item.userName.isNotEmpty
                    ? item.userName[0].toUpperCase()
                    : 'U',
                style: _t(13.sp, FontWeight.w800, _green),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.userName,
                      style: _t(13.sp, FontWeight.w700, _ink),
                    ),
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          starIdx < item.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14.sp,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  dateStr,
                  style: _t(10.5.sp, FontWeight.w500, _muted),
                ),
                if (item.remark.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    item.remark,
                    style: _t(12.sp, FontWeight.w500, const Color(0xFF334155),
                        height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Write & Submit Review Modal Sheet
  void _showWriteReviewSheet(BuildContext context) {
    num selectedRating = 5;
    final remarkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isSubmitting = controller.isSubmittingReview.value;

            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 18.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Rate This Property',
                      style: GoogleFonts.inter(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Your feedback will help other buyers explore verified listings.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        color: _muted,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Star Rating Picker
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          final isFilled = star <= selectedRating;
                          return IconButton(
                            iconSize: 34.sp,
                            padding: EdgeInsets.symmetric(horizontal: 2.w),
                            icon: Icon(
                              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                selectedRating = star;
                              });
                            },
                          );
                        }),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$selectedRating of 5 Stars',
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Text(
                      'Your Feedback / Remarks',
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: remarkController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe property location, pricing accuracy, condition...',
                        hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.all(12.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: _green, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please write a brief remark';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setSheetState(() {});
                            final success = await controller.submitReview(
                              rating: selectedRating,
                              remark: remarkController.text.trim(),
                            );

                            if (mounted && ctx.mounted) {
                              Navigator.of(ctx).pop();
                              if (success) {
                                AppToast.showSuccess('Review submitted successfully! Thank you.');
                              } else {
                                AppToast.showError('Could not submit review. Please try again.');
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Submit Review',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ======================================================================
  //  SIMILAR PROPERTIES
  // ======================================================================
  Widget _buildSimilarProperties() {

    return Obx(() {
      if (controller.isSimilarLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: const Center(child: CircularProgressIndicator(color: _green)),
        );
      }
      if (controller.similarProperties.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: _sectionTitle('Similar Properties Near You',
                trailing: 'See All (${controller.similarProperties.length})',
                onTrailingTap: _openAllSimilar),
          ),
          SizedBox(
            height: 130.h,
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              itemCount: controller.similarProperties.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final item = controller.similarProperties[index];

                String imgUrl = '';
                final rawImgs = item['images'] ??
                    (item['media'] is Map ? (item['media']['images'] ?? item['media']['photos']) : null) ??
                    item['photos'] ??
                    item['gallery'];
                if (rawImgs is List && rawImgs.isNotEmpty) {
                  imgUrl = rawImgs[0] is Map
                      ? (rawImgs[0]['secure_url']?.toString() ??
                      rawImgs[0]['url']?.toString() ??
                      rawImgs[0]['imageUrl']?.toString() ??
                      rawImgs[0]['image']?.toString() ??
                      '')
                      : rawImgs[0].toString();
                }
                if (imgUrl.isEmpty) {
                  imgUrl = item['image']?.toString() ??
                      item['imageUrl']?.toString() ??
                      item['coverImage']?.toString() ??
                      item['thumbnail']?.toString() ??
                      '';
                }

                final propTitle = item['title']?.toString() ??
                    item['name']?.toString() ??
                    'Property';
                final locality = item['locality']?.toString() ??
                    item['city']?.toString() ??
                    '';

                return GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.propertyDetails,
                      arguments: {'property': item}),
                  child: _similarPropertyCard(
                    image: imgUrl,
                    title: propTitle,
                    location: locality,
                    price: formatPrice(item['price']),
                    ppsf: extractPricePerSqft(item),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _similarPropertyCard({
    required String image,
    required String title,
    required String location,
    required String price,
    String? ppsf,
  }) {
    Widget placeholder() => Container(
      width: double.infinity,
      height: 78.h,
      color: _tile,
      child: const Center(
          child: Icon(Icons.home_work_rounded, color: _green)),
    );

    return Container(
      width: 168.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: ImageCase(
              url: image,
              width: double.infinity,
              height: 78.h,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 6.w), // Padding tight ki gayi
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(11.5.sp, FontWeight.w700, _ink),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12.sp, FontWeight.w800, _green),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (location.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 10.sp, color: _muted),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(9.sp, FontWeight.w400, _muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (ppsf != null && ppsf.isNotEmpty && ppsf != '0') ...[
                      if (location.isNotEmpty) SizedBox(width: 4.w),
                      Text(
                        ppsf.startsWith('₹') ? ppsf : '₹ $ppsf / sq.ft',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(9.sp, FontWeight.w500,
                            const Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }  // ======================================================================
  //  BOTTOM BAR   [ Chat ]  [ Connect with Partner ]
  // ======================================================================
  Widget _buildBottomActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, _) {
            // Scroll karne par partner mini-card aa jata hai (video jaisa)
            final compact = _scrollController.hasClients &&
                _scrollController.offset > 260.h;
            return AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (compact) ...[
                    Expanded(
                      flex: 5,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showConnectPartnerSheet(context),
                        child: Row(
                          children: [
                            Container(
                              width: 38.w,
                              height: 38.w,
                              decoration: const BoxDecoration(
                                color: _greenSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.support_agent_rounded,
                                  size: 20.sp, color: _green),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Property Partner',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _t(12.sp, FontWeight.w600, _ink)),
                                  Text('Tap to chat',
                                      style: _t(10.sp, FontWeight.w400, _muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                  ],
                  Expanded(
                    flex: compact ? 4 : 1,
                    child: _buildBookVisitButton(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Navy "Book a Visit" button with a looping shine sweep.
  Widget _buildBookVisitButton() {
    return SizedBox(
      height: 48.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: Material(
                color: _green,
                child: InkWell(
                  onTap: () => _showScheduleVisitSheet(context),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16.sp, color: Colors.white),
                        SizedBox(width: 8.w),
                        Text('Book a Visit',
                            style: _t(14.sp, FontWeight.w600, Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, box) {
                    return AnimatedBuilder(
                      animation: _shine,
                      builder: (context, _) {
                        final t = Curves.easeInOut
                            .transform((_shine.value / 0.5).clamp(0.0, 1.0));
                        final w = box.maxWidth;
                        return Stack(
                          children: [
                            Positioned(
                              left: -70 + (w + 140) * t,
                              top: 0,
                              bottom: 0,
                              width: 60,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.28),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================================
  //  LOADING / ERROR
  // ======================================================================
  Widget _buildLoadingState() {
    return ShimmerWidget(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 340.h, borderRadius: 0),
            Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120.w, height: 20.h, borderRadius: 6),
                  SizedBox(height: 14.h),
                  ShimmerBox(width: 180.w, height: 30.h),
                  SizedBox(height: 10.h),
                  ShimmerBox(height: 20.h),
                  SizedBox(height: 8.h),
                  ShimmerBox(width: 220.w, height: 14.h),
                  SizedBox(height: 18.h),
                  ShimmerBox(height: 64.h, borderRadius: 12),
                  SizedBox(height: 16.h),
                  ShimmerBox(height: 70.h, borderRadius: 16),
                  SizedBox(height: 16.h),
                  ShimmerBox(height: 120.h, borderRadius: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(PropertyDetailsController controller) {
    final canRetry = controller.propertyId.isNotEmpty;
    return SafeArea(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AppAdaptiveBackButton(),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFDECEC), shape: BoxShape.circle),
                      child: Icon(Icons.home_work_outlined,
                          size: 34.sp, color: const Color(0xFFDC2626)),
                    ),
                    SizedBox(height: 16.h),
                    Text('Couldn\'t load this property',
                        style: _t(16.sp, FontWeight.w700, _ink)),
                    SizedBox(height: 6.h),
                    Text(
                      controller.error.value ?? 'Something went wrong.',
                      textAlign: TextAlign.center,
                      style: _t(12.sp, FontWeight.w400, _muted, height: 1.5),
                    ),
                    SizedBox(height: 18.h),
                    if (canRetry)
                      ElevatedButton.icon(
                        onPressed: () => controller
                            .fetchPropertyDetailsById(controller.propertyId),
                        icon: Icon(Icons.refresh_rounded, size: 18.sp),
                        label: Text('Try again',
                            style: _t(13.sp, FontWeight.w600, Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Go back',
                            style: _t(13.sp, FontWeight.w600, _green)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  PILL-STYLE STICKY TABS
// ============================================================================
class _PillTabsDelegate extends SliverPersistentHeaderDelegate {
  _PillTabsDelegate({
    required this.height,
    required this.labels,
    required this.active,
    required this.onTap,
  });

  final double height;
  final List<String> labels;
  final ValueNotifier<int> active;
  final ValueChanged<int> onTap;

  static const Color _green = Color(0xFF0B6E5F);

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(covariant _PillTabsDelegate old) =>
      old.height != height || old.labels.join('|') != labels.join('|');

  // Underline-style tabs (Overview | Features | Amenities | Map & Location ...)
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: overlapsContent ? 0.08 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: active,
        builder: (context, current, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            itemCount: labels.length,
            itemBuilder: (context, i) {
              final selected = i == current;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Container(
                  margin: EdgeInsets.only(right: 22.w),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? _green : const Color(0xFF6B7280),
                        ),
                        child: Text(labels[i]),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 2.5,
                        width: selected ? (labels[i].length * 7.6).w : 0,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConnectPartnerSheet extends StatefulWidget {
  final PropertyDetailsController controller;

  const _ConnectPartnerSheet({required this.controller});

  @override
  State<_ConnectPartnerSheet> createState() => _ConnectPartnerSheetState();
}

class _ConnectPartnerSheetState extends State<_ConnectPartnerSheet> {
  String _partnerName = '';
  String _partnerSub = '';
  String _partnerPhone = '';
  String _partnerId = '';
  bool _resolvingPartner = true;

  bool _showCallbackForm = false;
  bool _callbackSent = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  AgentRepository get _agentRepository {
    if (Get.isRegistered<AgentRepository>()) return Get.find<AgentRepository>();
    return Get.put(AgentRepository(ApiService.instance), permanent: true);
  }

  LeadController get _leadController {
    if (Get.isRegistered<LeadController>()) return Get.find<LeadController>();
    final repo = Get.isRegistered<LeadRepository>()
        ? Get.find<LeadRepository>()
        : Get.put(LeadRepository(ApiService.instance), permanent: true);
    return Get.put(LeadController(repo), permanent: true);
  }

  @override
  void initState() {
    super.initState();
    _prefillBuyerInfo();
    _resolvePartner();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _prefillBuyerInfo() async {
    final name = await StorageService.instance.name;
    final phone = await StorageService.instance.phone;
    if (!mounted) return;
    setState(() {
      if (name != null && name.isNotEmpty) _nameController.text = name;
      if (phone != null && phone.isNotEmpty) _phoneController.text = phone;
    });
  }

  String _extractPropertyId(Map<String, dynamic> propertyMap) {
    return propertyMap['_id']?.toString() ??
        propertyMap['propertyId']?.toString() ??
        propertyMap['propertyCode']?.toString() ??
        propertyMap['id']?.toString() ??
        '';
  }

  Future<void> _resolvePartner() async {
    final property = widget.controller.property;
    final direct = property['partnerId']?.toString() ??
        property['assignedPartnerId']?.toString();

    Map<String, dynamic>? partnerMap;
    for (final key in ['partner', 'assignedPartner']) {
      if (property[key] is Map) {
        partnerMap = Map<String, dynamic>.from(property[key]);
        break;
      }
    }

    if (partnerMap == null || (direct == null || direct.isEmpty)) {
      try {
        final lat = (property['latitude'] as num?)?.toDouble();
        final lng = (property['longitude'] as num?)?.toDouble();
        final city = property['city']?.toString();
        final agents = await _agentRepository.getNearbyAgents(
            lat: lat, lng: lng, city: city);
        if (agents.isNotEmpty) partnerMap ??= agents.first;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _partnerId = (direct != null && direct.isNotEmpty)
          ? direct
          : partnerMap?['_id']?.toString() ??
          partnerMap?['id']?.toString() ??
          '';
      if (partnerMap != null) {
        _partnerName = partnerMap['name']?.toString() ?? _partnerName;
        final locality = partnerMap['locality']?.toString() ??
            partnerMap['serviceLocality']?.toString();
        _partnerSub = (locality != null && locality.isNotEmpty)
            ? 'Locality Specialist • $locality'
            : (partnerMap['partnerType']?.toString() ?? _partnerSub);
        final phone = partnerMap['phone']?.toString();
        if (phone != null && phone.isNotEmpty) _partnerPhone = phone;
      }
      _resolvingPartner = false;
    });
  }

  Future<String?> _getBuyerId() async {
    String? buyerId = await StorageService.instance.buyerId;
    if (buyerId == null || buyerId.isEmpty)
      buyerId = await StorageService.instance.userId;
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

  Future<void> _handleQuickContact(String contactPreference) async {
    final propertyId = _extractPropertyId(widget.controller.property);
    final buyerId = await _getBuyerId();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (propertyId.isNotEmpty &&
        (name.isNotEmpty ||
            phone.isNotEmpty ||
            (buyerId != null && buyerId.isNotEmpty))) {
      unawaited(_leadController.createLeadFromProperty(
        propertyId: propertyId,
        buyerId: buyerId,
        partnerId: _partnerId,
        name: name.isNotEmpty ? name : 'Guest',
        phone: phone,
        contactPreference: contactPreference,
      ));
    }

    if (mounted) Navigator.pop(context);

    if (contactPreference == 'whatsapp') {
      if (_partnerPhone.isNotEmpty) {
        await widget.controller.launchWhatsApp(_partnerPhone);
      } else {
        AppToast.showInfo('Partner contact is being verified.');
      }
    } else {
      if (_partnerPhone.isNotEmpty) {
        await widget.controller.makePhoneCall(_partnerPhone);
      } else {
        AppToast.showInfo('Partner contact is being verified.');
      }
    }

    _showLeadGeneratedPopup();
  }

  void _showLeadGeneratedPopup() {
    Get.dialog(
      Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF8F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: const Color(0xFF0B6E5F), size: 40.sp),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F1ED),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFBCE7DA), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12.sp, color: const Color(0xFF0B6E5F)),
                    SizedBox(width: 4.w),
                    Text(
                      'Completed',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B6E5F),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Lead Generated Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your inquiry for this property has been submitted. Our verified DigiNiwas Partner has received your request and will contact you shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E5F),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCallbackRequest() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar(
        'Details Required',
        'Please enter your name and phone number.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    final propertyId = _extractPropertyId(widget.controller.property);
    if (propertyId.isEmpty) {
      Get.snackbar(
        'Error',
        'Could not identify this property. Please go back and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    final buyerId = await _getBuyerId();
    final success = await _leadController.createLeadFromProperty(
      propertyId: propertyId,
      buyerId: buyerId,
      partnerId: _partnerId,
      name: name,
      phone: phone,
      contactPreference: 'callback',
    );

    if (!success) {
      Get.snackbar(
        'Error',
        _leadController.submitError.value ??
            'Could not send your request. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    await StorageService.instance.addEnquiryPropertyId(propertyId);

    if (!mounted) return;
    setState(() => _callbackSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Connect with DigiNiwas Partner',
                      style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded,
                        color: const Color(0xFF64748B), size: 20.sp),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Get verified pricing, floor plans, and arrange direct site visits.',
                style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF64748B),
                    height: 1.35),
              ),
              SizedBox(height: 16.h),
              _buildPropertyRow(),
              SizedBox(height: 14.h),
              if (_callbackSent)
                _buildCallbackSuccess()
              else if (_showCallbackForm)
                _buildCallbackForm()
              else
                _buildPartnerAndActions(),
              SizedBox(height: 14.h),
              Center(
                child: Text(
                  '🛡️ Zero Spam Guarantee • Direct connection with verified DigiNiwas partner.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyRow() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE3F1ED)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: widget.controller.imageUrl.isNotEmpty
                ? Image.network(widget.controller.imageUrl,
                width: 44.w,
                height: 44.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 44.w,
                    height: 44.w,
                    color: const Color(0xFFE2E8F0)))
                : Container(
                width: 44.w,
                height: 44.w,
                color: const Color(0xFFE2E8F0),
                child: const Icon(Icons.apartment_rounded,
                    color: Colors.white)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.controller.title.isNotEmpty
                      ? widget.controller.title
                      : 'This Property',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A)),
                ),
                if (widget.controller.address.isNotEmpty)
                  Text(
                    widget.controller.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                  ),
              ],
            ),
          ),
          if (widget.controller.priceDisplay.isNotEmpty)
            Text(
              widget.controller.priceDisplay,
              style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0B6E5F)),
            ),
        ],
      ),
    );
  }

  Widget _buildPartnerAndActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFCFF3E7)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: const Color(0xFF0B6E5F),
                child: Text(
                  _resolvingPartner
                      ? '..'
                      : (_partnerName.isNotEmpty
                      ? _partnerName[0].toUpperCase()
                      : 'P'),
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _resolvingPartner
                                ? 'Finding your partner…'
                                : _partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A)),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        if (!_resolvingPartner)
                          Icon(Icons.verified_rounded,
                              color: const Color(0xFF0B6E5F), size: 14.sp),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _resolvingPartner ? ' ' : _partnerSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 10.5.sp, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleQuickContact('whatsapp'),
            icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
            label: Text('Chat on WhatsApp',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 12.5.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleQuickContact('call'),
            icon: const Icon(Icons.call_rounded, color: Colors.white, size: 16),
            label: Text('Call Partner Directly',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 12.5.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2544),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showCallbackForm = true),
            icon: Icon(Icons.notifications_active_rounded,
                color: const Color(0xFF0B6E5F), size: 16.sp),
            label: Text('Request Instant Callback',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B6E5F),
                    fontSize: 12.5.sp)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE3F1ED)),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallbackForm() {
    return Obx(() {
      final isSubmitting = _leadController.isSubmitting.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request Instant Callback',
              style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
          SizedBox(height: 2.h),
          Text(
            'Share your details and a verified partner will call you back shortly.',
            style: GoogleFonts.inter(
                fontSize: 11.sp, color: const Color(0xFF64748B), height: 1.35),
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _nameController,
            style: GoogleFonts.inter(fontSize: 12.5.sp),
            decoration: InputDecoration(
              labelText: 'Your Name',
              labelStyle: GoogleFonts.inter(
                  fontSize: 11.5.sp, color: const Color(0xFF64748B)),
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: const Color(0xFF64748B), size: 18.sp),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFE3F1ED))),
              enabledBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFE3F1ED))),
              contentPadding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(fontSize: 12.5.sp),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: GoogleFonts.inter(
                  fontSize: 11.5.sp, color: const Color(0xFF64748B)),
              prefixIcon: Icon(Icons.phone_outlined,
                  color: const Color(0xFF64748B), size: 18.sp),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFE3F1ED))),
              enabledBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFE3F1ED))),
              contentPadding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => setState(() => _showCallbackForm = false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE3F1ED)),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('Back',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                          fontSize: 12.5.sp)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitCallbackRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E5F),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Text('Request Callback',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12.5.sp)),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildCallbackSuccess() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: const BoxDecoration(
              color: Color(0xFFEFF8F5), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded,
              color: const Color(0xFF0B6E5F), size: 32.sp),
        ),
        SizedBox(height: 12.h),
        Text('Callback Requested!',
            style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
        SizedBox(height: 4.h),
        Text(
          'A verified DigiNiwas partner will call you back shortly on ${_phoneController.text.trim()}.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 11.5.sp, color: const Color(0xFF64748B), height: 1.4),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6E5F),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
            child: Text('Done',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 12.5.sp)),
          ),
        ),
      ],
    );
  }
}

class _ScheduleVisitBottomSheet extends StatefulWidget {
  final PropertyDetailsController controller;

  const _ScheduleVisitBottomSheet({required this.controller});

  @override
  State<_ScheduleVisitBottomSheet> createState() =>
      _ScheduleVisitBottomSheetState();
}

class _ScheduleVisitBottomSheetState extends State<_ScheduleVisitBottomSheet> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  String _selectedTimeSlot = '11:00 AM - 12:00 PM';

  final List<String> _timeSlots = [
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM',
  ];

  VisitController get _visitController {
    if (Get.isRegistered<VisitController>()) return Get.find<VisitController>();
    final repo = Get.isRegistered<VisitRepository>()
        ? Get.find<VisitRepository>()
        : Get.put(VisitRepository(ApiService.instance), permanent: true);
    return Get.put(VisitController(repo), permanent: true);
  }

  AgentRepository get _agentRepository {
    if (Get.isRegistered<AgentRepository>()) return Get.find<AgentRepository>();
    return Get.put(AgentRepository(ApiService.instance), permanent: true);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
  }

  void _changeMonth(int increment) {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + increment, 1);
    });
  }

  String _extractPropertyId(Map<String, dynamic> propertyMap) {
    return propertyMap['_id']?.toString() ??
        propertyMap['propertyId']?.toString() ??
        propertyMap['propertyCode']?.toString() ??
        propertyMap['id']?.toString() ??
        '';
  }

  String _extractPartnerId(Map<String, dynamic> propertyMap) {
    final direct = propertyMap['partnerId']?.toString() ??
        propertyMap['assignedPartnerId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    for (final key in ['partner', 'assignedPartner']) {
      final nested = propertyMap[key];
      if (nested is Map) {
        final id = nested['_id']?.toString() ?? nested['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return '';
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

  Future<void> _submitVisitRequest() async {
    final visitController = _visitController;
    final buyerId = await _getBuyerId();
    if (buyerId == null || buyerId.isEmpty) {
      Get.snackbar(
        'Login Required',
        'Please login to schedule a visit.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    final propertyId = _extractPropertyId(widget.controller.property);
    if (propertyId.isEmpty) {
      Get.snackbar(
        'Error',
        'Could not identify this property. Please go back and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    var partnerId = _extractPartnerId(widget.controller.property);
    if (partnerId.isEmpty) {
      final lat = widget.controller.latitude;
      final lng = widget.controller.longitude;
      final city = widget.controller.city;

      partnerId = await _agentRepository.getBestNearbyPartnerId(
        lat: lat,
        lng: lng,
        city: city,
      ) ??
          '';
    }

    if (partnerId.isEmpty) {
      Get.snackbar(
        'No Partner Assigned',
        'This property doesn\'t have a verified partner assigned yet, so a visit can\'t be scheduled right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    final startTimeStr = _selectedTimeSlot.split(' - ').first.trim();
    final parsedTime = DateFormat('hh:mm a').parse(startTimeStr);
    final requestedVisitAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    final success = await visitController.requestVisit(
      propertyId: propertyId,
      buyerId: buyerId,
      partnerId: partnerId,
      requestedVisitAt: requestedVisitAt,
    );

    if (!success) {
      Get.snackbar(
        'Error',
        visitController.submitError.value ??
            'Could not schedule the visit. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
      );
      return;
    }

    if (mounted) Navigator.pop(context);
    _showSuccessDialog(visitController.lastRequestedVisit.value);
  }

  void _showSuccessDialog(RequestVisitData? visitData) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final propertyTitle = visitData?.propertySnapshot?.title ??
        visitData?.propertySnapshot?.projectName ??
        widget.controller.title;

    DateTime? requestedAt;
    if (visitData?.requestedVisitAt != null) {
      requestedAt = DateTime.tryParse(visitData!.requestedVisitAt!);
    }
    requestedAt ??=
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final statusLabel = () {
      final approval = visitData?.approvalStatus?.toLowerCase();
      if (approval == 'approved') return 'Confirmed';
      if (approval == 'rejected') return 'Rejected';
      return 'Pending Partner Confirmation';
    }();

    Get.dialog(
      Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close,
                      size: 18.sp, color: const Color(0xFF64748B)),
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4EA),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: const Color(0xFF0B6E5F), size: 28.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                'Visit Request Received!',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'We\'ve notified the DigiNiwas desk. A local verified partner is being assigned to lock your slot and guide your tour.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE3F1ED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home_work_rounded,
                            size: 14.sp, color: const Color(0xFF64748B)),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 14.sp, color: const Color(0xFF0B6E5F)),
                        SizedBox(width: 6.w),
                        Text(
                          '${requestedAt.day} ${months[requestedAt.month - 1].substring(0, 3)} • ${DateFormat('hh:mm a').format(requestedAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0B6E5F),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined,
                        size: 16.sp, color: const Color(0xFF2563EB)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'You\'ll receive a WhatsApp & in-app update once confirmed.',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.to(() => const ScheduledVisitsScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6E5F),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'View My Scheduled Visits',
                    style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE3F1ED)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = widget.controller.imageUrl;

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    int daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    int firstDayOfWeek =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday % 7;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 24.h),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      color: const Color(0xFF0B6E5F), size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Schedule Visit',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Property Mini Card
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE3F1ED)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: imgUrl.isNotEmpty
                          ? Image.network(imgUrl,
                          width: 50.w,
                          height: 50.h,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 50.w,
                              height: 50.h,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.home, size: 20)))
                          : Container(
                          width: 50.w,
                          height: 50.h,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.home, size: 20)),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.controller.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            widget.controller.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                color: const Color(0xFF64748B)),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            widget.controller.priceDisplay,
                            style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B6E5F)),
                          ),
                        ],
                      ),
                    ),
                    if (widget.controller.propertyModel.value.isVerified)
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified,
                                size: 10.sp, color: const Color(0xFF0B6E5F)),
                            SizedBox(width: 3.w),
                            Text('Verified',
                                style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0B6E5F))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Dynamic Calendar View
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE3F1ED)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                          style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A)),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () => _changeMonth(-1),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(4.w),
                            ),
                            SizedBox(width: 12.w),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () => _changeMonth(1),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.all(4.w),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekDays
                          .map((day) => Text(day,
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B))))
                          .toList(),
                    ),
                    SizedBox(height: 8.h),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: daysInMonth + firstDayOfWeek,
                      itemBuilder: (context, index) {
                        if (index < firstDayOfWeek) {
                          return const SizedBox.shrink();
                        }
                        int day = index - firstDayOfWeek + 1;
                        DateTime currentDate = DateTime(
                            _displayedMonth.year, _displayedMonth.month, day);
                        bool isSelected =
                            _selectedDate.year == currentDate.year &&
                                _selectedDate.month == currentDate.month &&
                                _selectedDate.day == currentDate.day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = currentDate;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0B6E5F)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Select Time Title
              Text(
                'Select Time',
                style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
              ),
              SizedBox(height: 8.h),

              // Time Slots Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  String slot = _timeSlots[index];
                  bool isSelected = _selectedTimeSlot == slot;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeSlot = slot;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0B6E5F)
                              : const Color(0xFFE3F1ED),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0B6E5F)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final visitController = _visitController;
                  return ElevatedButton(
                    onPressed: visitController.isSubmitting.value
                        ? null
                        : () => _submitVisitRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6E5F),
                      disabledBackgroundColor:
                      const Color(0xFF0B6E5F).withValues(alpha: 0.6),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: visitController.isSubmitting.value
                        ? SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : Text(
                      'Request Visit for ${_selectedDate.day} ${months[_selectedDate.month - 1].substring(0, 3)}',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  );
                }),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenZoomGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenZoomGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenZoomGallery> createState() => _FullScreenZoomGalleryState();
}

class _FullScreenZoomGalleryState extends State<_FullScreenZoomGallery> {
  late PageController _galleryPageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _galleryPageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _galleryPageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: ImageCase.sanitizeUrl(widget.imageUrls[index]) ?? widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScheduledVisitsScreen extends StatefulWidget {
  const ScheduledVisitsScreen({super.key});

  @override
  State<ScheduledVisitsScreen> createState() => _ScheduledVisitsScreenState();
}

class _ScheduledVisitsScreenState extends State<ScheduledVisitsScreen> {
  int _selectedTab = 0; // 0 for Upcoming, 1 for Under Review

  VisitController get controller {
    if (Get.isRegistered<VisitController>()) return Get.find<VisitController>();
    final repo = Get.isRegistered<VisitRepository>()
        ? Get.find<VisitRepository>()
        : Get.put(VisitRepository(ApiService.instance), permanent: true);
    return Get.put(VisitController(repo), permanent: true);
  }

  @override
  void initState() {
    super.initState();
    controller.fetchMyVisits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppAdaptiveBackButton(color: Color(0xFF0F172A)),
        title: Text(
          'Scheduled Visits',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF007A5E),
        onRefresh: controller.fetchMyVisits,
        child: Obx(() {
          final isLoading = controller.isFetchingVisits.value;
          final upcoming = controller.upcomingVisits;
          final underReview = controller.underReviewVisits;
          final activeList = _selectedTab == 0 ? upcoming : underReview;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Scheduled Visits',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    _buildTabButton(0, 'Upcoming', '${upcoming.length}'),
                    SizedBox(width: 10.w),
                    _buildTabButton(1, 'Under Review', '${underReview.length}'),
                  ],
                ),
                SizedBox(height: 20.h),
                if (isLoading && activeList.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.h),
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF007A5E))),
                  )
                else if (controller.fetchError.value != null &&
                    activeList.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Center(
                      child: Text(
                        controller.fetchError.value!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5.sp, color: Colors.red),
                      ),
                    ),
                  )
                else if (activeList.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.h),
                      child: Center(
                        child: Text(
                          _selectedTab == 0
                              ? 'No upcoming visits yet.'
                              : 'Nothing under review right now.',
                          style: GoogleFonts.poppins(
                              fontSize: 12.5.sp, color: const Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...activeList.map((visit) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _selectedTab == 0
                          ? _buildUpcomingVisitCard(visit)
                          : _buildUnderReviewVisitCard(visit),
                    )),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Widget for Filter Tabs
  Widget _buildTabButton(int index, String title, String count) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A5E) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
              child: Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('EEE, d MMM • hh:mm a').format(dt);
  }

  // Upcoming Visit Card — built entirely from live VisitStatusData
  Widget _buildUpcomingVisitCard(VisitStatusData v) {
    final propertyTitle = v.propertySnapshot?.title ??
        v.propertySnapshot?.projectName ??
        'Property';
    final locality = [v.propertySnapshot?.locality, v.propertySnapshot?.city]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');
    final propertyImage = v.propertySnapshot?.image;
    final partner = v.partnerSnapshot;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFCBEFE0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info: Image, Title, Status Badge
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: (propertyImage != null && propertyImage.isNotEmpty)
                      ? Image.network(
                    propertyImage,
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.grey.shade300,
                      child:
                      Icon(Icons.image, color: Colors.grey.shade600),
                    ),
                  )
                      : Container(
                    width: 60.w,
                    height: 60.w,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.image, color: Colors.grey.shade600),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              propertyTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 6.w,
                                    height: 6.w,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF007A5E),
                                        shape: BoxShape.circle)),
                                SizedBox(width: 4.w),
                                Text(
                                  'Visit Confirmed',
                                  style: GoogleFonts.poppins(
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF007A5E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      if (locality.isNotEmpty)
                        Text(
                          locality,
                          style: GoogleFonts.poppins(
                              fontSize: 11.sp, color: const Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Date & Time Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 16.sp, color: const Color(0xFF007A5E)),
                SizedBox(width: 8.w),
                Text(
                  _formatDateTime(v.approvedVisitAt ?? v.requestedVisitAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Section — built from real visit history
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: _buildTimeline(v),
            ),
          ),

          // Partner Details Card
          if (partner != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 14.w),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFCBEFE0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: Colors.grey.shade400,
                    child: Icon(Icons.person, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.name ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A)),
                        ),
                        if (partner.partnerType != null)
                          Text(
                            partner.partnerType!,
                            style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                color: const Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                  if (partner.phone != null) ...[
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.phone_outlined,
                          size: 16.sp, color: const Color(0xFF007A5E)),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE6F4EA), shape: BoxShape.circle),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          size: 16.sp, color: const Color(0xFF007A5E)),
                    ),
                  ],
                ],
              ),
            ),
          SizedBox(height: 14.h),

          // Bottom Action Buttons (Get Directions & Reschedule)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A5E),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions,
                            size: 16.sp, color: Colors.white),
                        SizedBox(width: 6.w),
                        Text('Get Directions',
                            style: GoogleFonts.poppins(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBEFE0)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text('Reschedule / Cancel',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A))),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],
      ),
    );
  }

  /// Builds the timeline tiles from the visit's real `history` list. Falls
  /// back to a simple "Visit Requested" step if history is empty.
  List<Widget> _buildTimeline(VisitStatusData v) {
    final entries = <_TimelineEntry>[];

    if (v.history != null && v.history!.isNotEmpty) {
      for (final h in v.history!) {
        entries.add(_TimelineEntry(
          title: h.action ??
              (h.toStatus != null ? 'Status: ${h.toStatus}' : 'Update'),
          subtitle: _formatDateTime(h.updatedAt),
        ));
      }
    } else {
      entries.add(_TimelineEntry(
        title: 'Visit Requested',
        subtitle: _formatDateTime(v.createdAt ?? v.requestedVisitAt),
      ));
    }

    // Always show a final "Physical Tour" step as the pending future step.
    entries.add(const _TimelineEntry(
        title: 'Physical Tour', subtitle: '', isFuture: true));

    return List.generate(entries.length, (i) {
      final e = entries[i];
      final isLast = i == entries.length - 1;
      return _buildTimelineTile(
        e.title,
        e.subtitle,
        !e.isFuture,
        !isLast,
        isCurrent: !e.isFuture && i == entries.length - 2,
      );
    });
  }

  // Under Review Visit Card — built entirely from live VisitStatusData
  Widget _buildUnderReviewVisitCard(VisitStatusData v) {
    final propertyTitle = v.propertySnapshot?.title ??
        v.propertySnapshot?.projectName ??
        'Property';
    final locality = [v.propertySnapshot?.locality, v.propertySnapshot?.city]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');
    final propertyImage = v.propertySnapshot?.image;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitDetailsScreen(visit: v),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFCBEFE0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: (propertyImage != null && propertyImage.isNotEmpty)
                        ? Image.network(
                      propertyImage,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60.w,
                        height: 60.w,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.image,
                            color: Colors.grey.shade600),
                      ),
                    )
                        : Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.grey.shade300,
                      child:
                      Icon(Icons.image, color: Colors.grey.shade600),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                propertyTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A)),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Under Review',
                                style: GoogleFonts.poppins(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        if (locality.isNotEmpty)
                          Text(
                            locality,
                            style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: const Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 16.sp, color: const Color(0xFF007A5E)),
                  SizedBox(width: 8.w),
                  Text(
                    _formatDateTime(v.requestedVisitAt),
                    style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16.sp, color: const Color(0xFFB45309)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finding the best agent',
                          style: GoogleFonts.poppins(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309)),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          v.teamRemarks ??
                              v.adminRemarks ??
                              'We are currently assigning a dedicated property expert for this visit. You will be notified once confirmed.',
                          style: GoogleFonts.poppins(
                              fontSize: 10.5.sp,
                              color: const Color(0xFF92400E),
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Timeline Steps
  Widget _buildTimelineTile(
      String title, String subtitle, bool isCompleted, bool showLine,
      {bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted && !isCurrent
                    ? const Color(0xFF007A5E)
                    : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF007A5E)
                      : const Color(0xFFCBD5E1),
                  width: isCurrent ? 5.w : 2.w,
                ),
              ),
              child: isCompleted && !isCurrent
                  ? Icon(Icons.check, size: 10.sp, color: Colors.white)
                  : null,
            ),
            if (showLine)
              Container(
                width: 2.w,
                height: 26.h,
                color: const Color(0xFFCBD5E1),
              ),
          ],
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp, color: const Color(0xFF64748B)),
                ),
              ],
              SizedBox(height: 14.h),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry {
  final String title;
  final String subtitle;
  final bool isFuture;

  const _TimelineEntry(
      {required this.title, required this.subtitle, this.isFuture = false});
}

class VisitDetailsScreen extends StatelessWidget {
  final VisitStatusData visit;

  const VisitDetailsScreen({super.key, required this.visit});

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final propertyTitle = visit.propertySnapshot?.title ??
        visit.propertySnapshot?.projectName ??
        'Property Details';
    final locality = [
      visit.propertySnapshot?.locality,
      visit.propertySnapshot?.city
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    final propertyImage = visit.propertySnapshot?.image;
    final partner = visit.partnerSnapshot;
    final isConfirmed = visit.approvalStatus?.toLowerCase() == 'approved' ||
        visit.status?.toLowerCase() == 'confirmed';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const BuyerAppBar(
          title: 'Visit Details',
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFCBEFE0)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: (propertyImage != null && propertyImage.isNotEmpty)
                          ? Image.network(
                        propertyImage,
                        width: 70.w,
                        height: 70.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70.w,
                          height: 70.w,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.home),
                        ),
                      )
                          : Container(
                        width: 70.w,
                        height: 70.w,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.home),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? const Color(0xFFE6F4EA)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isConfirmed ? 'Visit Confirmed' : 'Under Review',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w600,
                                color: isConfirmed
                                    ? const Color(0xFF007A5E)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (locality.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              locality,
                              style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlinePropertyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _InlinePropertyVideoPlayer({required this.videoUrl});

  @override
  State<_InlinePropertyVideoPlayer> createState() =>
      _InlinePropertyVideoPlayerState();
}

class _InlinePropertyVideoPlayerState
    extends State<_InlinePropertyVideoPlayer> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  bool get _isYouTube {
    final lower = widget.videoUrl.trim().toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  bool get _isExternalWebVideo {
    if (_isYouTube) return true;
    final lower = widget.videoUrl.trim().toLowerCase();
    return lower.contains('vimeo.com') ||
        lower.contains('drive.google.com') ||
        lower.contains('dailymotion.com');
  }

  String _lastError = '';

  String? get _youtubeThumbnail {
    final url = widget.videoUrl.trim();
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant _InlinePropertyVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposePlayer();
      _initPlayer();
    }
  }

  void _disposePlayer() {
    _controlsTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  // URL ko player-friendly banata hai (spaces encode, http -> https,
  // Cloudinary video ko mp4/h264 me convert taaki har phone par chale)
  List<String> _candidateUrls(String raw) {
    var u = raw.trim().replaceAll(' ', '%20');
    if (!u.startsWith('http')) {
      // Relative path aaya to server ke origin se jod do
      final origin = Uri.parse(ApiConstants.baseUrl).origin;
      u = '$origin/${u.replaceFirst(RegExp(r'^/+'), '')}';
    }
    final out = <String>[];
    var secure = u;
    if (secure.startsWith('http://')) {
      secure = 'https://' + secure.substring(7);
    }
    if (secure.contains('res.cloudinary.com') &&
        secure.contains('/video/upload/') &&
        !secure.contains('/f_mp4')) {
      final mp4 = secure.replaceFirst('/video/upload/', '/video/upload/f_mp4,vc_h264/');
      out.add(mp4.replaceFirst(RegExp(r'\.(mov|webm|mkv|avi|3gp)(\?.*)?$', caseSensitive: false), '.mp4'));
    }
    out.add(secure);
    if (u != secure) out.add(u);
    return out.toSet().toList();
  }

  Future<void> _initPlayer() async {
    final rawUrl = widget.videoUrl.trim();
    if (rawUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }
    if (mounted) setState(() => _hasError = false);

    if (_isExternalWebVideo) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
      return;
    }

    for (final url in _candidateUrls(rawUrl)) {
      try {
        final c = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await c.initialize();
        if (!mounted) {
          c.dispose();
          return;
        }
        c.setLooping(true);
        c.addListener(() {
          if (mounted) setState(() {});
        });
        _videoController = c;
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        return;
      } catch (e) {
        debugPrint('Video init failed for $url -> $e');
        _lastError = '$e';
      }
    }
    if (mounted) {
      setState(() {
        _hasError = true;
        _isInitialized = false;
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.videoUrl.trim().replaceAll(' ', '%20'));
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Bottom-right transparent "Open link" pill
  Widget _openLinkPill() {
    return Positioned(
      right: 10.w,
      bottom: 10.h,
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _openExternally,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded,
                    size: 13.sp, color: Colors.white),
                SizedBox(width: 5.w),
                Text('Open link',
                    style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _showControls = true;
      } else {
        _videoController!.play();
        _scheduleHideControls();
      }
    });
  }

  void _scheduleHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_videoController?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }


  Widget _buildExternalVideoCard() {
    final thumb = _youtubeThumbnail;
    final isYt = _isYouTube;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFFCBEFE0)),
          image: thumb != null
              ? DecorationImage(
            image: NetworkImage(thumb),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 12.h,
              left: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isYt
                      ? const Color(0xFFFF0000).withValues(alpha: 0.9)
                      : const Color(0xFF007A5E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isYt
                          ? Icons.play_circle_filled_rounded
                          : Icons.videocam_rounded,
                      color: Colors.white,
                      size: 13.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      isYt ? 'YOUTUBE WALKTHROUGH' : 'VIDEO TOUR',
                      style: GoogleFonts.poppins(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(widget.videoUrl.trim());
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isYt
                        ? const Color(0xFFFF0000)
                        : const Color(0xFF007A5E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isYt
                            ? const Color(0xFFFF0000)
                            : const Color(0xFF007A5E))
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34.sp,
                  ),
                ),
              ),
            ),
            _openLinkPill(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isExternalWebVideo) {
      return _buildExternalVideoCard();
    }

    if (_hasError) {
      return Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFCBEFE0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off_rounded,
                    color: const Color(0xFFF87171), size: 30.sp),
                SizedBox(height: 8.h),
                Text(
                  'Video in-app load nahi ho paya',
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                if (_lastError.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      _lastError,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 9.sp, color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _hasError = false);
                    _initPlayer();
                  },
                  icon: Icon(Icons.refresh_rounded,
                      size: 15.sp, color: const Color(0xFF4EE1A0)),
                  label: Text('Retry',
                      style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: const Color(0xFF4EE1A0),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            _openLinkPill(),
          ],
        ),
      );
    }

    if (!_isInitialized || _videoController == null) {
      return Container(
        height: 190.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFCBEFE0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4EE1A0)),
        ),
      );
    }

    final isPlaying = _videoController!.value.isPlaying;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0xFFCBEFE0)),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
                if (_showControls && isPlaying) _scheduleHideControls();
              },
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            ),
            if (_showControls || !isPlaying)
              Container(
                color: Colors.black.withValues(alpha: 0.38),
                child: Stack(
                  children: [
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _togglePlayPause,
                          borderRadius: BorderRadius.circular(30.r),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007A5E)
                                  .withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: Material(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20.r),
                          onTap: _openFullscreen,
                          child: Padding(
                            padding: EdgeInsets.all(6.w),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF4EE1A0),
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
            _openLinkPill(),
          ],
        ),
      ),
    );
  }

  void _openFullscreen() {
    if (_videoController == null || !_isInitialized) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayerPage(
          controller: _videoController!,
          videoUrl: widget.videoUrl,
        ),
      ),
    );
  }
}

class _FullScreenVideoPlayerPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoUrl;

  const _FullScreenVideoPlayerPage({
    required this.controller,
    required this.videoUrl,
  });

  @override
  State<_FullScreenVideoPlayerPage> createState() =>
      _FullScreenVideoPlayerPageState();
}

class _FullScreenVideoPlayerPageState
    extends State<_FullScreenVideoPlayerPage> {
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _scheduleHideControls();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _controlsTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _scheduleHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _showControls = true;
      } else {
        widget.controller.play();
        _scheduleHideControls();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
                if (_showControls && isPlaying) _scheduleHideControls();
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio > 0
                      ? widget.controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(widget.controller),
                ),
              ),
            ),
            if (_showControls) ...[
              Positioned(
                top: 10.h,
                left: 10.w,
                right: 10.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Video Tour',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _togglePlayPause,
                    borderRadius: BorderRadius.circular(36.r),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007A5E).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 14.h,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: position.inMilliseconds.toDouble().clamp(
                                0.0,
                                duration.inMilliseconds.toDouble() > 0
                                    ? duration.inMilliseconds.toDouble()
                                    : 1.0),
                            min: 0.0,
                            max: duration.inMilliseconds.toDouble() > 0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                            activeColor: const Color(0xFF4EE1A0),
                            inactiveColor: Colors.white24,
                            onChanged: (val) {
                              widget.controller.seekTo(
                                  Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



// ============================================================================
//  SIMILAR PROPERTIES  -  "See All" screen
// ============================================================================
class _SimilarPropertiesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String Function(dynamic) formatPrice;
  final String Function(Map<String, dynamic>) pricePerSqft;

  const _SimilarPropertiesScreen({
    required this.items,
    required this.formatPrice,
    required this.pricePerSqft,
  });

  static const Color _green = Color(0xFF007A5E);
  static const Color _greenLine = Color(0xFFCBEFE0);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  String _image(Map<String, dynamic> item) {
    dynamic raw = item['images'];
    if (raw is! List || raw.isEmpty) {
      if (item['media'] is Map) {
        final m = item['media'] as Map;
        raw = m['images'] ?? m['photos'];
      }
    }
    if (raw is! List || raw.isEmpty) {
      raw = item['photos'] ?? item['gallery'];
    }

    if (raw is List && raw.isNotEmpty) {
      return raw[0] is Map
          ? (raw[0]['secure_url']?.toString() ??
          raw[0]['url']?.toString() ??
          raw[0]['imageUrl']?.toString() ??
          raw[0]['image']?.toString() ??
          '')
          : raw[0].toString();
    }
    for (final k in ['image', 'imageUrl', 'coverImage', 'thumbnail']) {
      final v = item[k]?.toString() ?? '';
      if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppAdaptiveBackButton(color: Color(0xFF0F172A)),
        title: Text(
          'Similar Properties (${items.length})',
          style: GoogleFonts.poppins(
              fontSize: 15.sp, fontWeight: FontWeight.w700, color: _ink),
        ),
      ),
      body: items.isEmpty
          ? Center(
        child: Text('No similar properties found',
            style: GoogleFonts.poppins(fontSize: 12.sp, color: _muted)),
      )
          : GridView.builder(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.all(14.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.85, // Height ko balance aur compact rakhne ke liye ratio badhaya gaya hai
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => _card(items[i]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final img = _image(item);
    final title =
        item['title']?.toString() ?? item['name']?.toString() ?? 'Property';
    final location =
        item['locality']?.toString() ?? item['city']?.toString() ?? '';
    final ppsf = pricePerSqft(item);

    Widget placeholder() => Container(
      color: Colors.grey.shade200,
      child: const Center(
          child: Icon(Icons.home_work_rounded, color: Colors.grey)),
    );

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.propertyDetails,
          arguments: {'property': item}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _greenLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ImageCase(
                  url: img,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              // Bottom spacing aur padding ko yahan perfect aur compact kiya gaya hai
              padding: EdgeInsets.fromLTRB(10.w, 8.w, 10.w, 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (Left) & Price (Right side ke last me)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _ink),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        formatPrice(item['price']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: _green),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Location (Left) & Square Feet/ppsf (Right side ke last me)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (location.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 11.sp, color: _muted),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 9.5.sp, color: _muted),
                                ),
                              ),
                            ],

                          ),
                        ),
                      if (ppsf.isNotEmpty && ppsf != '0') ...[
                        if (location.isNotEmpty) SizedBox(width: 6.w),
                        Text(
                          ppsf,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 9.5.sp,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// A real place around the property (school, hospital, mall ...).
class _NearbyPlace {
  const _NearbyPlace({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.distKm,
  });

  final String name;
  final String category;
  final double lat;
  final double lng;
  final double distKm;
}