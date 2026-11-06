import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:diginiwas/features/buyer/presentation/save_properties_screen.dart';
import 'package:diginiwas/features/buyer/presentation/buyer_profile_screen.dart';
import 'package:diginiwas/features/buyer/presentation/notification_screen.dart';
import 'package:diginiwas/features/buyer/presentation/widgets/property_story_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/buyer_home_controller.dart';
import '../data/view_all_repository.dart';
import '../models/property_model.dart';
import '../models/testimonial_model.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/utils/shimmer.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'explore_map_screen.dart' hide ComparePropertiesScreen;
import 'buyer_map_screen.dart';
import 'niwas_ai_screen.dart';
import 'view_all_screen.dart';
import 'select_city_screen.dart';
import 'widgets/service_stories_section.dart';
import '../../../core/utils/animation_utils.dart';

// ================================================================
//  DESIGN TOKENS  (taken 1:1 from "Home (earlier design)" mockup)
// ================================================================
const Color _green = Color(0xFF0B6E5F);
const Color _deepGreen = Color(0xFF08574B);
const Color _ink = Color(0xFF10222B);
const Color _navy = Color(0xFF10222B);
const Color _muted = Color(0xFF5E7076);
const Color _softGreen = Color(0xFFE3F1ED);
const Color _line = Color(0xFFEEF2F1); // dividers inside cards
const Color _border = Color(0xFFF0F4F3); // card border
const Color _mint = Color(0xFF7FE0C8); // accent on dark overlays
const Color _chipGrey = Color(0xFFF0F4F3);

const String _logoAsset = 'assets/images/diginiwas_logo.png';

// Image assets copied from the design export (assets/images/...)
const String _headerBgAsset = 'assets/images/home_header_bg.png';
const String _aiFindHomeAsset = 'assets/images/discovery_find_home.png';
const String _aiCompareAsset = 'assets/images/discovery_compare_homes.png';
const String _aiLocalityAsset = 'assets/images/discovery_explore_locality.png';
const String _aiPriceAsset = 'assets/images/discovery_price_trends.png';

/// 0 14 34 rgba(16,34,43,.11)  — category card, agent card, quick actions…
List<BoxShadow> get _softShadow => [
  BoxShadow(
    color: const Color(0xFF10222B).withValues(alpha: 0.11),
    blurRadius: 34,
    offset: const Offset(0, 14),
  ),
];

/// 0 16 40 rgba(16,34,43,.13)  — property cards, AI discovery cards
List<BoxShadow> get _cardShadow => [
  BoxShadow(
    color: const Color(0xFF10222B).withValues(alpha: 0.13),
    blurRadius: 40,
    offset: const Offset(0, 16),
  ),
];

/// 0 16 40 rgba(16,34,43,.18)  — floating search bar
List<BoxShadow> get _floatShadow => [
  BoxShadow(
    color: const Color(0xFF10222B).withValues(alpha: 0.18),
    blurRadius: 40,
    offset: const Offset(0, 16),
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

/// White card, 1px #F0F4F3 border.
BoxDecoration _card({double r = 22, List<BoxShadow>? shadow}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(r.r),
  border: Border.all(color: _border, width: 1),
  boxShadow: shadow ?? _softShadow,
);

Color amenityColor(String? markerType) {
  switch (markerType) {
    case 'EDUCATION':
      return const Color(0xFF3B82F6);
    case 'HEALTHCARE':
      return const Color(0xFFEF4444);
    case 'FOOD':
      return const Color(0xFFEAB308);
    default:
      return const Color(0xFF64748B);
  }
}

IconData amenityIcon(String? markerType) {
  switch (markerType) {
    case 'EDUCATION':
      return Icons.school_outlined;
    case 'HEALTHCARE':
      return Icons.local_hospital_outlined;
    case 'FOOD':
      return Icons.restaurant_outlined;
    default:
      return Icons.place_outlined;
  }
}

String _amenityLabel(String? markerType) {
  switch (markerType) {
    case 'EDUCATION':
      return 'School';
    case 'HEALTHCARE':
      return 'Hospital';
    case 'FOOD':
      return 'Restaurant';
    default:
      return 'Place';
  }
}

/// Shared "save property" logic used by every card with a heart icon.
Future<void> _toggleSave(BuyerHomeController controller, String? propertyId) async {
  try {
    String? buyerId = await StorageService.instance.buyerId;
    if (buyerId == null || buyerId.isEmpty) buyerId = await StorageService.instance.userId;
    if (buyerId == null || buyerId.isEmpty) {
      final userJson = await SecureStorageService.instance.getUserData();
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final m = jsonDecode(userJson) as Map<String, dynamic>;
          buyerId = m['id']?.toString() ?? m['_id']?.toString() ?? m['buyerId']?.toString();
        } catch (_) {}
      }
    }
    if (buyerId != null && buyerId.isNotEmpty && propertyId != null) {
      await controller.toggleSaveProperty(buyerId, propertyId);
    }
  } catch (e) {
    debugPrint('HEART EXCEPTION: $e');
  }
}

/// 34px white circle, ink outline heart (red + filled when saved).
class _SaveHeart extends StatelessWidget {
  final BuyerHomeController controller;
  final String? propertyId;
  const _SaveHeart({required this.controller, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _toggleSave(controller, propertyId),
      child: Obx(() {
        final saved = propertyId != null && controller.savedPropertyIds.contains(propertyId);
        return Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10222B).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(saved),
              size: 18.sp,
              color: saved ? const Color(0xFFE53935) : _ink,
            ),
          ),
        );
      }),
    );
  }
}

/// White pill badge on top of property images (Verified / Boosted / New).
class _ImageBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ImageBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return BadgeJiggle(
      interval: const Duration(seconds: 4),
      child: ShimmerGlowEffect(
        borderRadius: BorderRadius.circular(999),
        shimmerColor: const Color(0x330B6E5F),
        pauseDuration: const Duration(seconds: 4),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10222B).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.sp, color: _green),
              SizedBox(width: 4.w),
              Text(label, style: _t(11, FontWeight.w700, _green)),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
//  HEADER BACKGROUND (static scenic background image matching mockup)
// ================================================================
class HeaderBackgroundSlider extends StatelessWidget {
  final Widget child;
  const HeaderBackgroundSlider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(32.r),
      ),
      child: Stack(
        children: [
          // Static Header Image Background (no motion / no expansion)
          Positioned.fill(
            child: Image.asset(
              _headerBgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8F7F2)),
            ),
          ),

          // Soft light blend overlay on left to ensure dark navy & green text is crisp
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.52),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}

// ================================================================
//  HOME SCREEN
// ================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BuyerHomeController controller = Get.isRegistered<BuyerHomeController>()
      ? Get.find<BuyerHomeController>()
      : Get.put(BuyerHomeController(), permanent: true);

  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _showCompact = ValueNotifier<bool>(false);
  BitmapDescriptor? _pinIcon;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.hasClients && _scroll.offset > 230;
      if (show != _showCompact.value) _showCompact.value = show;
    });
    _loadPinIcon();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _showCompact.dispose();
    super.dispose();
  }

  /// Map marker from the design: 32px green circle, 3px white ring, white house.
  Future<void> _loadPinIcon() async {
    try {
      const size = 84.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      const center = Offset(size / 2, size / 2);
      // soft shadow
      c.drawCircle(
        center.translate(0, 3),
        size / 2 - 2,
        Paint()
          ..color = const Color(0x4010222B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      c.drawCircle(center, size / 2 - 2, Paint()..color = Colors.white..isAntiAlias = true);
      c.drawCircle(center, size / 2 - 10, Paint()..color = _green..isAntiAlias = true);
      final tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(Icons.home_outlined.codePoint),
          style: TextStyle(
            fontSize: 38,
            fontFamily: Icons.home_outlined.fontFamily,
            package: Icons.home_outlined.fontPackage,
            color: Colors.white,
          ),
        ),
      )..layout();
      tp.paint(c, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
      final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null || !mounted) return;
      // ignore: deprecated_member_use
      setState(() => _pinIcon = BitmapDescriptor.fromBytes(Uint8List.view(bd.buffer)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isHomeTab = controller.bottomNavIndex.value == 0;
      final bool showInitialShimmer =
          controller.isLoading.value && controller.homeFeed.value == null;

      return PopScope(
        canPop: isHomeTab,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && controller.bottomNavIndex.value != 0) {
            controller.changeBottomNavIndex(0);
          }
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            bottom: false,
            child: showInitialShimmer ? const HomeShimmer() : _buildBody(context),
          ),
          bottomNavigationBar: showInitialShimmer ? const SizedBox.shrink() : _buildBottomNav(),
        ),
      );
    });
  }

  Widget _sectionLoader({double height = 120, double? cardWidth}) =>
      HorizontalPropertyShimmer(height: height.h, cardWidth: cardWidth ?? 230.w);

  Widget _cachedImage(
      String? url, {
        required double width,
        required double height,
        BoxFit fit = BoxFit.cover,
        IconData fallbackIcon = Icons.home_work_rounded,
        BorderRadius? borderRadius,
      }) {
    return ImageCase(
      url: url,
      width: width,
      height: height,
      fit: fit,
      fallbackIcon: fallbackIcon,
      borderRadius: borderRadius,
    );
  }

  Widget _buildBody(BuildContext context) {
    return IndexedStack(
      index: controller.bottomNavIndex.value.clamp(0, 4),
      children: [
        Stack(
          children: [
            // bottom: false -> content scrolls underneath the floating glass nav
            SafeArea(top: false, bottom: false, child: _buildContent(context)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showCompact,
                builder: (_, show, __) => IgnorePointer(
                  ignoring: !show,
                  child: AnimatedOpacity(
                    opacity: show ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: _buildCompactBar(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        const ExproleName(),
        const NiwasAiScreen(),
        SavedPropertiesScreen(),
        const ProfileScreen(),
      ],
    );
  }

  // ---------------------------------------------------------------
  //  CONTENT  (section order = design order)
  // ---------------------------------------------------------------
  Widget _buildContent(BuildContext context) {
    final sections = _sections(context);
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      color: _green,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHeaderBlock(context)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                return _Reveal(
                  key: ValueKey('home_section_$i'),
                  child: sections[i],
                );
              },
              childCount: sections.length,
            ),
          ),
        ],
      ),
    );
  }

  /// Every section is built lazily (SliverList) and fades/slides in the
  /// first time it scrolls into range. Obx is used only where Rx values are read.
  List<Widget> _sections(BuildContext context) {
    Widget rx(Widget Function() b) => Obx(() => b());
    return [
      rx(() => controller.error.value != null ? _buildFeedErrorBanner() : const SizedBox.shrink()),
      Padding(padding: EdgeInsets.only(top: 18.h), child: rx(_buildCategoryChips)),

      // Instant Category Filter Results (Appears immediately right below chips when Buy/Rent/Plot/Commercial is tapped)
      Padding(
        padding: EdgeInsets.only(top: 18.h),
        child: rx(() {
          final selectedTab = controller.selectedCategoryTab.value;
          if (selectedTab == null) {
            return _buildQuickAiSection();
          }

          final title = '$selectedTab Properties';
          final raw = controller.categoryFilterData.value?.properties ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                title,
                showViewAll: true,
                onViewAll: () {
                  Get.to(() => ViewAllScreen(
                    title: title,
                    type: ViewAllType.property,
                    propertyItems: _mapPropertyLikeList(raw),
                    controller: controller,
                  ));
                },
              ),
              _buildRecommendedCards(),
            ],
          );
        }),
      ),

      // Recommended For You / Quick AI depending on selection mode
      Padding(
        padding: EdgeInsets.only(top: 22.h),
        child: rx(() {
          final selectedTab = controller.selectedCategoryTab.value;
          if (selectedTab != null) {
            return _buildQuickAiSection();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                'Recommended For You',
                showViewAll: true,
                onViewAll: () {
                  final raw = controller.homeFeed.value?.recommendedProperties ?? [];
                  Get.to(() => ViewAllScreen(
                    title: 'Recommended For You',
                    type: ViewAllType.property,
                    propertyItems: _mapPropertyLikeList(raw),
                    controller: controller,
                  ));
                },
              ),
              _buildRecommendedCards(),
            ],
          );
        }),
      ),
      Padding(padding: EdgeInsets.only(top: 22.h), child: rx(_buildBoostedSection)),
      Padding(padding: EdgeInsets.only(top: 6.h), child: rx(_buildHeroBanners)),
      Padding(
        padding: EdgeInsets.only(top: 22.h),
        child: rx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Explore Near You'),
            _buildExploreMap(context),
            if ((controller.exploreNearby.value?.map?.markers ?? []).isNotEmpty) ...[
              SizedBox(height: 18.h),
              _buildMapAmenitiesList(),
            ],
          ],
        )),
      ),
      Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: ServiceStoriesSection(controller: controller)),
      Padding(
        padding: EdgeInsets.only(top: 22.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'New Listings',
              leadingIcon: Icons.auto_awesome_outlined,
              showViewAll: true,
              onViewAll: () => Get.to(() => ViewAllScreen(
                title: 'New Listings',
                type: ViewAllType.property,
                section: ViewAllSection.newListings,
                controller: controller,
                badgeLabel: 'New',
                badgeColor: _green,
              )),
            ),
            rx(_buildNewListings),
          ],
        ),
      ),
      rx(() => (controller.homeFeed.value?.popularAreas ?? []).isEmpty
          ? const SizedBox.shrink()
          : Padding(
        padding: EdgeInsets.only(top: 22.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              _popularTitle(),
              leadingIcon: Icons.star_outline_rounded,
              showViewAll: true,
              onViewAll: _openPopularViewAll,
            ),
            _buildPopularAreas(),
          ],
        ),
      )),
      Padding(
        padding: EdgeInsets.only(top: 22.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Verified Agents Near You',
              showViewAll: true,
              onViewAll: () => Get.to(() => ViewAllScreen(
                title: 'Verified Agents Near You',
                type: ViewAllType.agent,
                agentItems: controller.homeFeed.value?.agents ?? [],
                onAgentTap: _showAgentProfileBottomSheet,
              )),
            ),
            rx(_buildVerifiedAgent),
          ],
        ),
      ),
      Padding(padding: EdgeInsets.only(top: 24.h), child: const FutureEcosystemWidget()),
      Padding(
          padding: EdgeInsets.only(top: 26.h),
          child: _buildCommunityTestimonialsSection(context)),
      Padding(padding: EdgeInsets.only(top: 24.h), child: _buildFollowUsCard()),
      Padding(padding: EdgeInsets.only(top: 22.h), child: _buildQuickActions(context)),
      // floating nav sits on top of the content -> leave room for it
      // (Scaffold extendBody puts the nav height into padding.bottom)
      Builder(
        builder: (ctx) => SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16.h),
      ),
    ];
  }

  String _popularTitle() {
    final city = controller.homeFeed.value?.location?.city;
    return (city != null && city.isNotEmpty) ? 'Popular near $city' : 'Popular Near You';
  }

  void _openPopularViewAll() {
    Get.to(() => ViewAllScreen(
      title: _popularTitle(),
      type: ViewAllType.popularArea,
      section: ViewAllSection.popularAreas,
    ));
  }

  List<Map<String, dynamic>> _mapPropertyLikeList(List items) {
    return items.map<Map<String, dynamic>>((p) {
      final imgs = <String>[];
      if (p.images != null) {
        for (var img in p.images) {
          if (img.url != null) imgs.add(img.url as String);
        }
      }
      return {
        'title': p.title,
        'locality': p.locality,
        'city': p.city,
        'bedrooms': p.bedrooms,
        'furnishing': p.furnishing,
        'price': p.price,
        'images': imgs,
        'json': p.toJson(),
      };
    }).toList();
  }

  Widget _buildFeedErrorBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF5B5B5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: const Color(0xFFC62828), size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              controller.error.value ?? 'Could not load home feed.',
              style: _t(11.5, FontWeight.w400, const Color(0xFFC62828)),
            ),
          ),
          TextButton(
            onPressed: controller.loadHomeFeed,
            child: Text('Retry', style: _t(11.5, FontWeight.w700, const Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  //  HEADER  (hero + search bar overlapping by 28px)
  //  hero padding 22/20/76 · radius 0 0 32 32
  // ---------------------------------------------------------------
  void _openSearch() => Get.to(() => const ExproleName());

  Widget _buildHeaderBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 26.h),
              child: _buildHeroHeader(context),
            ),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 0,
              child: _buildSearchBar(),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        PropertyStoriesSection(controller: controller),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 180.h + topPad,
      child: HeaderBackgroundSlider(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, topPad + 8.h, 20.w, 34.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top Location & Notification Bell / Profile Avatar
              Row(
                children: [
                  Expanded(
                    child: _locationRow(
                      fontSize: 13.5,
                      weight: FontWeight.w700,
                      color: _ink,
                      pinColor: const Color(0xFF00A884),
                      pinSize: 18,
                      chevronSize: 16,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _bell(onDark: false),
                  SizedBox(width: 8.w),
                  _avatar(solid: false),
                ],
              ),

              // 2. Greeting, Name & Verified Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${controller.greetingByTime()},',
                    style: _t(20, FontWeight.w800, _ink, h: 1.1),
                  ),
                  SizedBox(height: 2.h),
                  Obx(() {
                    final name = (controller.buyerName.value.isNotEmpty &&
                        controller.buyerName.value != 'DG')
                        ? controller.buyerName.value
                        : 'Rahul';
                    return Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(22, FontWeight.w800, const Color(0xFF00A884), h: 1.1),
                    );
                  }),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 15.sp, color: const Color(0xFF00A884)),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'Verified homes match your preferences',
                          style: _t(11.5, FontWeight.w600, const Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 52px high pill · radius 28 · light mint filter icon button matching screenshot
  Widget _buildSearchBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openSearch,
      child: Container(
        height: 52.h,
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 6.w, 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: _floatShadow,
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: const Color(0xFF94A3B8), size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Search locality, property or price range',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(12.5, FontWeight.w400, const Color(0xFF94A3B8)),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () async {
                final city = await Get.to<String>(() => const SelectCityScreen());
                if (city != null && city.isNotEmpty) {
                  controller.applyPropertyFilters(city: city);
                  Get.to(() => const ExproleName());
                }
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.tune_rounded, color: const Color(0xFF00A884), size: 18.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow({
    required double fontSize,
    FontWeight weight = FontWeight.w500,
    Color color = _navy,
    Color pinColor = _green,
    double? pinSize,
    double? chevronSize,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: pinColor, size: (pinSize ?? fontSize + 4).sp),
        SizedBox(width: 4.w),
        Flexible(
          child: Obx(() {
            final loc = controller.userCurrentLocation.value;
            final text = (loc.isNotEmpty && !loc.toLowerCase().contains('fetching'))
                ? loc
                : 'Select Location';
            return Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(fontSize, weight, color),
            );
          }),
        ),
      ],
    );
  }

  /// 40px circle, rgba(255,255,255,.18) on the hero.
  Widget _bell({bool onDark = false}) {
    return InkWell(
      onTap: () async {
        await Get.to(() => const NotificationScreen());
        controller.fetchNotifications();
      },
      borderRadius: BorderRadius.circular(24.r),
      child: Obx(() {
        final unread = controller.unreadNotificationsCount.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: onDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: onDark
                    ? null
                    : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _Wiggle(
                active: unread > 0,
                child: Icon(Icons.notifications_none_rounded,
                    color: onDark ? Colors.white : _navy, size: 20.sp),
              ),
            ),
            if (unread > 0)
              Positioned(
                top: 9.w,
                right: 10.w,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _avatar({required bool solid}) {
    return Obx(() {
      final localPath = controller.userAvatarLocalPath.value;
      final networkUrl = controller.userAvatarNetworkUrl.value.isNotEmpty
          ? controller.userAvatarNetworkUrl.value
          : (controller.dashboardHeader.value?.user?.avatar ?? '');
      final hasLocal = localPath.isNotEmpty && File(localPath).existsSync();
      final hasNetwork = networkUrl.isNotEmpty;
      final name = controller.buyerName.value;
      final initials =
      name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : 'RA';

      return InkWell(
        onTap: () => controller.changeBottomNavIndex(4),
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: solid ? _green : const Color(0xFFE3F6EE),
            shape: BoxShape.circle,
            border: solid ? null : Border.all(color: const Color(0xFF38C79A), width: 1.5),
            image: hasLocal
                ? DecorationImage(image: FileImage(File(localPath)), fit: BoxFit.cover)
                : (hasNetwork
                ? DecorationImage(image: NetworkImage(networkUrl), fit: BoxFit.cover)
                : null),
          ),
          alignment: Alignment.center,
          child: (!hasLocal && !hasNetwork)
              ? Text(initials, style: _t(14, FontWeight.w700, solid ? Colors.white : _deepGreen))
              : null,
        ),
      );
    });
  }

  Widget _brandLogo() {
    return Image.asset(
      _logoAsset,
      height: 32.h,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/app_logo.png',
        height: 32.h,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Compact white bar that fades in once the hero header has scrolled away.
  Widget _buildCompactBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        topPad + 8.h,
        20.w,
        14.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand + Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _brandLogo(),
                SizedBox(height: 5.h),
                _locationRow(fontSize: 12),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Notification
          _bell(),

          SizedBox(width: 12.w),

          // Profile Avatar
          _avatar(solid: false),
        ],
      ),
    );
  }
  // ---------------------------------------------------------------
  //  CATEGORY CARD  (one card, 4 columns, 1px dividers)
  //  margin 18/20/0 · radius 22 · padding 14 · icon 48 · gap 7
  // ---------------------------------------------------------------
  Widget _buildCategoryChips() {
    final items = [
      (Icons.home_outlined, 'Buy', _green, _softGreen),
      (Icons.key_rounded, 'Rent', const Color(0xFF2563EB), const Color(0xFFE8F0FE)),
      (Icons.location_on_outlined, 'Plot', const Color(0xFF16A34A), const Color(0xFFE6F6EA)),
      (Icons.apartment_rounded, 'Commercial', const Color(0xFF7C3AED), const Color(0xFFF0EAFE)),
    ];
    final apiCategories = controller.categoryFilterData.value?.categories ?? [];
    int? countFor(String label) {
      for (final c in apiCategories) {
        if ((c.name ?? '').toLowerCase() == label.toLowerCase()) return c.count;
      }
      return null;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AutoFloatWidget(
        distance: 1.2,
        duration: const Duration(milliseconds: 4000),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: _card(r: 22),
          child: IntrinsicHeight(
            child: Row(
              children: List.generate(items.length * 2 - 1, (i) {
                if (i.isOdd) {
                  return const VerticalDivider(width: 1, thickness: 1, color: _line);
                }
                final (icon, label, color, bg) = items[i ~/ 2];
                final selected = controller.selectedCategoryTab.value == label;
                final count = countFor(label);
                return Expanded(
                  child: FluidSpringTap(
                    onTap: () => controller.onCategoryChipTap(label),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutoPulseCard(
                          enabled: selected,
                          minScale: 0.95,
                          maxScale: 1.05,
                          duration: const Duration(milliseconds: 2000),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: selected ? Border.all(color: color, width: 1.8) : null,
                            ),
                            child: Icon(icon, color: color, size: 24.sp),
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(12, selected ? FontWeight.w700 : FontWeight.w600, _ink)),
                        if (selected && count != null)
                          Text('$count found', style: _t(8.5, FontWeight.w500, _green)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  SECTION TITLE  — 16 / w800, "View All" = plain green 13 / w700
  // ---------------------------------------------------------------
  Widget _buildSectionTitle(
      String title, {
        bool showViewAll = false,
        VoidCallback? onViewAll,
        IconData? leadingIcon,
      }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  _Breathe(child: Icon(leadingIcon, size: 18.sp, color: _green)),
                  SizedBox(width: 6.w),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(16, FontWeight.w800, _ink),
                  ),
                ),
              ],
            ),
          ),
          if (showViewAll)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onViewAll,
              child: Text('View All', style: _t(13, FontWeight.w700, _green)),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  //  QUICK AI DISCOVERY  (2x2, 84px photo + title/subtitle)
  // ---------------------------------------------------------------
  Widget _buildQuickAiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick AI Discovery', style: _t(16, FontWeight.w800, _ink)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Get.to(() => const NiwasAiScreen()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Breathe(child: Icon(Icons.auto_awesome_outlined, size: 14.sp, color: _green)),
                    SizedBox(width: 4.w),
                    Text('Powered by Niwas AI', style: _t(12, FontWeight.w700, _green)),
                    SizedBox(width: 4.w),
                    Icon(Icons.chevron_right_rounded, size: 16.sp, color: _green),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildQuickAiGrid(),
      ],
    );
  }

  Widget _buildQuickAiGrid() {
    final cards = [
      (
      title: 'Find My Home',
      subtitle: 'AI-matched properties',
      mode: 'find_home',
      asset: _aiFindHomeAsset,
      ),
      (
      title: 'Compare Homes',
      subtitle: 'Side-by-side comparison',
      mode: 'compare_homes',
      asset: _aiCompareAsset,
      ),
      (
      title: 'Explore Locality',
      subtitle: 'Area insights & amenities',
      mode: 'explore_locality',
      asset: _aiLocalityAsset,
      ),
      (
      title: 'Price Trends',
      subtitle: 'Market insights & growth',
      mode: 'price_trends',
      asset: _aiPriceAsset,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          mainAxisExtent: 144.h,
        ),
        itemBuilder: (context, i) {
          final c = cards[i];
          return AutoFloatWidget(
            distance: 2.2,
            phaseShift: i * 0.25,
            duration: Duration(milliseconds: 3000 + i * 250),
            child: FluidSpringTap(
              onTap: () => Get.to(() => const NiwasAiScreen(), arguments: {'mode': c.mode}),
              child: Container(
                decoration: _card(r: 20, shadow: _cardShadow),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 84.h,
                        width: double.infinity,
                        child: Image.asset(
                          c.asset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: _softGreen),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(14, FontWeight.w700, _ink)),
                            Text(c.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(12, FontWeight.w400, _muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  //  RECOMMENDED  (250px cards, 150px image, VIEW DETAILS button)
  // ---------------------------------------------------------------
  Widget _buildRecommendedCards() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(controller.selectedCategoryTab.value ?? 'all'),
        child: _buildRecommendedCardsInner(),
      ),
    );
  }

  static List<String> _extractPropertyImages(dynamic item) {
    if (item == null) return const [];
    if (item is PropertyModel && item.images.isNotEmpty) return item.images;

    final List<String> list = [];

    void addUrl(dynamic raw) {
      if (raw == null) return;
      final clean = ImageCase.sanitizeUrl(raw.toString());
      if (clean != null && clean.isNotEmpty && !list.contains(clean)) {
        list.add(clean);
      }
    }

    // 1. If item itself has an .images property
    try {
      final dynamic imgs = (item as dynamic).images;
      if (imgs is List && imgs.isNotEmpty) {
        for (final img in imgs) {
          if (img is String) {
            addUrl(img);
          } else if (img is Map) {
            addUrl(img['secure_url'] ?? img['url'] ?? img['imageUrl'] ?? img['image'] ?? img['path']);
          } else if (img != null) {
            try {
              final u = (img as dynamic).secure_url?.toString() ??
                  (img as dynamic).url?.toString() ??
                  (img as dynamic).image?.toString() ??
                  (img as dynamic).imageUrl?.toString();
              addUrl(u);
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 2. If item has a .media property
    if (list.isEmpty) {
      try {
        final dynamic media = (item as dynamic).media;
        if (media is Map) {
          final mImgs = media['images'] ?? media['photos'];
          if (mImgs is List) {
            for (final m in mImgs) {
              if (m is String) {
                addUrl(m);
              } else if (m is Map) {
                addUrl(m['secure_url'] ?? m['url'] ?? m['imageUrl'] ?? m['image'] ?? m['path']);
              }
            }
          }
        }
      } catch (_) {}
    }

    // 3. If item itself has an .image property
    if (list.isEmpty) {
      try {
        final dynamic single = (item as dynamic).image;
        addUrl(single);
      } catch (_) {}
    }

    // 4. Fallback to json representation
    Map<String, dynamic> json = {};
    if (item is Map<String, dynamic>) {
      json = item;
    } else if (item is Map) {
      json = Map<String, dynamic>.from(item);
    } else {
      try {
        final dynamic j = (item as dynamic).toJson();
        if (j is Map) json = Map<String, dynamic>.from(j);
      } catch (_) {}
    }

    if (list.isEmpty && json.isNotEmpty) {
      dynamic raw = json['images'];
      if (raw is! List || raw.isEmpty) {
        if (json['media'] is Map) {
          final m = json['media'] as Map;
          raw = m['images'] ?? m['photos'];
        }
      }
      if (raw is! List || raw.isEmpty) {
        raw = json['photos'] ?? json['gallery'];
      }

      if (raw is List) {
        for (final it in raw) {
          if (it is String) {
            addUrl(it);
          } else if (it is Map) {
            addUrl(it['secure_url'] ?? it['url'] ?? it['image'] ?? it['path'] ?? it['imageUrl']);
          }
        }
      }
      if (list.isEmpty) {
        for (final k in ['image', 'imageUrl', 'coverImage', 'thumbnail', 'photo', 'cover']) {
          final val = json[k];
          if (val != null) {
            addUrl(val);
            if (list.isNotEmpty) break;
          }
        }
      }
    }


    return list;
  }

  Widget _buildRecommendedCardsInner() {
    if (controller.selectedCategoryTab.value != null) {
      if (controller.categoryFilterLoading.value) return _sectionLoader(height: 380);
      final filtered = controller.categoryFilterData.value?.properties ?? [];
      if (filtered.isEmpty) {
        return _buildEmptySectionMessage(
          'No ${controller.selectedCategoryTab.value!} properties found near your selected location.',
          title: 'No ${controller.selectedCategoryTab.value!} Properties',
          type: controller.selectedCategoryTab.value?.toLowerCase() == 'commercial'
              ? EmptyStateType.commercial
              : EmptyStateType.property,
          actionLabel: 'Explore All',
          onAction: () => controller.changeBottomNavIndex(1),
        );
      }
      return _recommendedCardsList(
        count: filtered.length,
        titleAt: (i) => filtered[i].title,
        localityAt: (i) => filtered[i].locality,
        cityAt: (i) => filtered[i].city,
        bedroomsAt: (i) => filtered[i].bedrooms,
        furnishingAt: (i) => filtered[i].furnishing,
        priceAt: (i) => filtered[i].price,
        imageUrlsAt: (i) => _extractPropertyImages(filtered[i]),
        jsonAt: (i) => filtered[i].toJson(),
      );
    }

    final properties = controller.homeFeed.value?.recommendedProperties ?? [];
    if (properties.isEmpty) {
      return _buildEmptySectionMessage(
        'No recommended properties available right now. Tap Explore to browse all listings.',
        title: 'No Properties Available',
        type: EmptyStateType.property,
        actionLabel: 'Explore All',
        onAction: () => controller.changeBottomNavIndex(1),
      );
    }
    return _recommendedCardsList(
      count: properties.length,
      titleAt: (i) => properties[i].title,
      localityAt: (i) => properties[i].locality,
      cityAt: (i) => properties[i].city,
      bedroomsAt: (i) => properties[i].bedrooms,
      furnishingAt: (i) => properties[i].furnishing,
      priceAt: (i) => properties[i].price,
      imageUrlsAt: (i) => _extractPropertyImages(properties[i]),
      jsonAt: (i) => properties[i].toJson(),
    );
  }

  Widget _recommendedCardsList({
    required int count,
    required String? Function(int) titleAt,
    required String? Function(int) localityAt,
    required String? Function(int) cityAt,
    required String? Function(int) bedroomsAt,
    required String? Function(int) furnishingAt,
    required int? Function(int) priceAt,
    required List<String> Function(int) imageUrlsAt,
    required Map<String, dynamic> Function(int) jsonAt,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(count, (i) {
          return Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 12.w),
            child: AutoFloatWidget(
              distance: 1.8,
              phaseShift: (i % 4) * 0.22,
              duration: Duration(milliseconds: 3200 + (i % 3) * 250),
              child: RecommendedPropertyCard(
                revealDelay: (i > 5 ? 5 : i) * 70,
                propertyJson: jsonAt(i),
                title: titleAt(i),
                locality: localityAt(i),
                city: cityAt(i),
                bedrooms: bedroomsAt(i),
                furnishing: furnishingAt(i),
                price: priceAt(i),
                imageUrls: imageUrlsAt(i),
                controller: controller,
                cachedImageBuilder: _cachedImage,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptySectionMessage(
      String message, {
        String? title,
        EmptyStateType type = EmptyStateType.property,
        String? actionLabel,
        VoidCallback? onAction,
        String? customSvgPath,
      }) {
    final effectiveTitle = title ?? type.defaultTitle;
    final isPropertySection = (type == EmptyStateType.property ||
        type == EmptyStateType.boosted ||
        type == EmptyStateType.noListings ||
        type == EmptyStateType.forSale ||
        type == EmptyStateType.commercial);
    final effectiveSvg = customSvgPath ??
        (isPropertySection
            ? 'assets/images/empty_states/diginiwas-empty-state-vibrant.svg'
            : (type.svgPath.isNotEmpty
            ? type.svgPath
            : 'assets/images/empty_states/diginiwas-empty-state-vibrant.svg'));
    final isSvg = effectiveSvg.endsWith('.svg');

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSvg
                ? SvgPicture.asset(effectiveSvg, width: 120.w, height: 85.h, fit: BoxFit.contain)
                : Image.asset(effectiveSvg, width: 85.w, height: 85.w, fit: BoxFit.contain),
            SizedBox(height: 8.h),
            Text(effectiveTitle,
                textAlign: TextAlign.center, style: _t(13.5, FontWeight.w600, _ink)),
            SizedBox(height: 3.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 290.w),
              child: Text(message,
                  textAlign: TextAlign.center, style: _t(11, FontWeight.w400, _muted, h: 1.35)),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 8.h),
              _Tap(
                onTap: onAction,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: _green, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(actionLabel, style: _t(11, FontWeight.w600, _green)),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_rounded, size: 12.sp, color: _green),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  BOOSTED / AI SUGGESTED  (250px cards, 130px image, no button)
  // ---------------------------------------------------------------
  Widget _buildBoostedSection() {
    if (controller.isLoading.value || controller.boostedLoading.value) {
      return _sectionLoader(height: 190, cardWidth: 250.w);
    }
    final feedProps = controller.homeFeed.value?.boostedProperties ?? [];
    final standaloneProps = controller.boostedPropertiesData.value?.properties ?? [];
    final hasFeed = feedProps.isNotEmpty;

    if (!hasFeed && standaloneProps.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ai Suggested Properties', leadingIcon: Icons.auto_awesome_outlined),
          _buildEmptySectionMessage(
            'Ai Suggested high-visibility properties will appear here when promoted.',
            title: 'No Ai Suggested Properties Yet',
            type: EmptyStateType.boosted,
            actionLabel: 'Explore All',
            onAction: () => controller.changeBottomNavIndex(1),
          ),
        ],
      );
    }

    final count = hasFeed ? feedProps.length : standaloneProps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Boosted Properties',
          leadingIcon: Icons.bolt_outlined,
          showViewAll: true,
          onViewAll: () => Get.to(() => ViewAllScreen(
            title: 'Boosted Properties',
            type: ViewAllType.property,
            section: ViewAllSection.boosted,
            controller: controller,
            badgeLabel: 'Boosted',
            badgeColor: const Color(0xFFE5A000),
          )),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(count, (index) {
              final dynamic item = hasFeed ? feedProps[index] : standaloneProps[index];
              final urls = _extractPropertyImages(item);
              final Map<String, dynamic> propertyJson = item.toJson();
              final id = propertyJson['_id']?.toString() ?? propertyJson['propertyId']?.toString();
              return Padding(
                padding: EdgeInsets.only(right: index == count - 1 ? 0 : 12.w),
                child: SizedBox(
                  width: 250.w,
                  child: AmbientBorderGlow(
                    glowColor: const Color(0xFFE5A000),
                    borderRadius: 22.r,
                    duration: Duration(milliseconds: 2400 + (index % 3) * 300),
                    child: _PropertyCard(
                      revealDelay: (index > 5 ? 5 : index) * 70,
                      imageUrls: urls,
                      imageHeight: 130,
                      badgeLabel: 'Boosted',
                      badgeIcon: Icons.bolt_rounded,
                      title: item.title ?? 'Property',
                      subtitle: formatPropertyLocation(
                        locality: item.locality,
                        city: item.city,
                        address: item.address,
                        distanceKm: item.distanceKm,
                        sameCity: item.sameCity,
                      ),
                      priceText: formatPrice(item.price),
                      propertyId: id,
                      controller: controller,
                      onTap: () => Get.toNamed(AppRoutes.propertyDetails,
                          arguments: {'property': propertyJson}),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  //  HERO BANNER  (180px · radius 24 · dots bottom-left)
  // ---------------------------------------------------------------
  Widget _buildHeroBanners() {
    if (controller.isLoading.value) {
      return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0), child: _sectionLoader(height: 180));
    }
    final banners = controller.homeFeed.value?.banners ?? [];
    final urls = <String>[];
    final tags = <String>[];
    final titles = <String>[];
    String read(dynamic b, List<String> keys) {
      for (final k in keys) {
        try {
          final v = k == 'tag'
              ? b.tag
              : k == 'subtitle'
              ? b.subtitle
              : k == 'title'
              ? b.title
              : b.headline;
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        } catch (_) {}
      }
      return '';
    }

    for (final b in banners) {
      final u = b.image;
      if (u is String && u.isNotEmpty) {
        urls.add(u);
        tags.add(read(b, ['tag', 'subtitle']));
        titles.add(read(b, ['title', 'headline']));
      }
    }
    if (urls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
      child: HeroBannerCarousel(imageUrls: urls, tags: tags, titles: titles),
    );
  }

  // ---------------------------------------------------------------
  //  EXPLORE MAP  (200px · radius 20 · circle pins · info card)
  // ---------------------------------------------------------------
  Widget _buildExploreMap(BuildContext context) {
    if (controller.exploreLoading.value && controller.homeFeed.value == null) {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w), child: _sectionLoader(height: 200));
    }

    final feed = controller.homeFeed.value;
    final Set<Marker> markers = {};
    LatLng? firstPropertyLocation;
    final pin = _pinIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    void addPropertyMarker(String id, double lat, double lng) {
      if (lat == 0.0 && lng == 0.0) return;
      firstPropertyLocation ??= LatLng(lat, lng);
      markers.add(Marker(
        markerId: MarkerId('prop_$id'),
        position: LatLng(lat, lng),
        icon: pin,
        anchor: const Offset(0.5, 0.5),
      ));
    }

    for (final p in (feed?.recommendedProperties ?? [])) {
      if (p.latitude != null && p.longitude != null) {
        addPropertyMarker(
            p.id ?? p.propertyId ?? '${p.latitude}_${p.longitude}', p.latitude!, p.longitude!);
      }
    }
    for (final p in (feed?.boostedProperties ?? [])) {
      if (p.latitude != null && p.longitude != null) {
        addPropertyMarker(
            p.id ?? p.propertyId ?? '${p.latitude}_${p.longitude}', p.latitude!, p.longitude!);
      }
    }

    LatLng center;
    if (controller.userCoordinates.value != null) {
      center = controller.userCoordinates.value!;
    } else if (feed?.location?.latitude != null && feed?.location?.longitude != null) {
      final lat = double.tryParse(feed!.location!.latitude.toString()) ?? 0.0;
      final lng = double.tryParse(feed.location!.longitude.toString()) ?? 0.0;
      center = (lat != 0.0 && lng != 0.0)
          ? LatLng(lat, lng)
          : (firstPropertyLocation ?? const LatLng(28.6139, 77.2090));
    } else {
      center = firstPropertyLocation ?? const LatLng(28.6139, 77.2090);
    }

    final loc = controller.userCurrentLocation.value;
    final String title = loc.isNotEmpty && loc != 'India' && loc != 'Fetching location...'
        ? 'Properties near $loc'
        : (feed?.location?.city != null && feed!.location!.city!.isNotEmpty
        ? 'Properties near ${feed.location!.city}'
        : 'Properties Near You');

    void openMap() => Get.toNamed(AppRoutes.mapView);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: openMap,
                  child: AbsorbPointer(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: center, zoom: 13.0),
                      mapType: MapType.normal,
                      markers: markers,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 14.h,
                child: AutoFloatWidget(
                  distance: 2.0,
                  duration: const Duration(milliseconds: 3200),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10222B).withValues(alpha: 0.2),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(13, FontWeight.w700, _ink)),
                              Text(
                                markers.isNotEmpty
                                    ? '${markers.length} properties available on map'
                                    : 'Explore properties near your location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(11, FontWeight.w400, _muted),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        FluidSpringTap(
                          onTap: openMap,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                                color: _green, borderRadius: BorderRadius.circular(10.r)),
                            child: Text('View Map', style: _t(12, FontWeight.w700, Colors.white)),
                          ),
                        ),
                      ],
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

  // ---------------------------------------------------------------
  //  NEARBY PLACES & AMENITIES  (white card, rows with dividers)
  // ---------------------------------------------------------------
  String? _markerDistance(dynamic m) {
    try {
      final d = m.distanceKm ?? m.distance;
      if (d == null) return null;
      if (d is num) return '${d.toStringAsFixed(1)} km';
      final s = d.toString();
      return s.isEmpty ? null : (s.toLowerCase().contains('km') ? s : '$s km');
    } catch (_) {
      return null;
    }
  }

  Widget _buildMapAmenitiesList() {
    final markers = controller.exploreNearby.value?.map?.markers ?? [];
    if (markers.isEmpty) return const SizedBox.shrink();
    final shown = markers.take(3).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: _card(r: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text('Nearby Places & Amenities', style: _t(14, FontWeight.w800, _ink)),
            ),
            ...List.generate(shown.length, (i) {
              final m = shown[i];
              final type = m.markerType ?? 'PLACE';
              final dist = _markerDistance(m);
              return _Reveal(
                  delay: i * 90,
                  dy: 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    decoration: BoxDecoration(
                      border: i == 0 ? null : const Border(top: BorderSide(color: _line)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: _softGreen,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(amenityIcon(type), size: 20.sp, color: _green),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name ?? 'Location',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(13, FontWeight.w700, _ink)),
                              Text(_amenityLabel(type), style: _t(11, FontWeight.w400, _muted)),
                            ],
                          ),
                        ),
                        if (dist != null) Text(dist, style: _t(11, FontWeight.w700, _green)),
                      ],
                    ),
                  ));
            }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  NEW LISTINGS  (horizontal, 250px cards, 140px image)
  // ---------------------------------------------------------------
  Widget _buildNewListings() {
    if (controller.isLoading.value) return _sectionLoader(height: 240);
    final listings = controller.homeFeed.value?.newListings ?? [];
    if (listings.isEmpty) {
      return _buildEmptySectionMessage(
        'New properties are added daily. Tap below to browse all properties.',
        title: 'No New Listings Yet',
        type: EmptyStateType.noListings,
        actionLabel: 'Browse All',
        onAction: () => controller.changeBottomNavIndex(1),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(listings.length, (i) {
          final item = listings[i];
          return Padding(
            padding: EdgeInsets.only(right: i == listings.length - 1 ? 0 : 12.w),
            child: SizedBox(
              width: 250.w,
              child: AutoFloatWidget(
                distance: 1.6,
                phaseShift: ((i + 2) % 4) * 0.23,
                duration: Duration(milliseconds: 3400 + (i % 2) * 300),
                child: NewListingCard(
                  revealDelay: (i > 5 ? 5 : i) * 70,
                  item: item,
                  controller: controller,
                  onTap: () => Get.toNamed(AppRoutes.propertyDetails,
                      arguments: {'property': item.toJson()}),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  POPULAR AREAS  (230x160 photo cards, dark overlay, text bottom)
  // ---------------------------------------------------------------
  Widget _popularCardShell({
    required Widget background,
    required String title,
    required String count,
    required VoidCallback onTap,
    int delay = 0,
  }) {
    return AutoFloatWidget(
      distance: 2.0,
      phaseShift: (delay * 0.001) % 1.0,
      duration: const Duration(milliseconds: 3600),
      child: FluidSpringTap(
        onTap: onTap,
        child: Container(
          width: 230.w,
          height: 160.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10222B).withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Stack(
            children: [
              Positioned.fill(child: background),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10222B).withValues(alpha: 0.42),
                  ),
                ),
              ),
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(15, FontWeight.w800, Colors.white)),
                    Text(count, style: _t(12, FontWeight.w400, Colors.white)),
                    SizedBox(height: 2.h),
                    Text('Explore all properties', style: _t(11, FontWeight.w700, _mint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPopularAreas() {
    if (controller.isLoading.value) return _sectionLoader(height: 160);
    final areas = controller.homeFeed.value?.popularAreas ?? [];
    if (areas.isEmpty) return const SizedBox.shrink();

    final total = areas.fold<int>(0, (s, a) => s + ((a.propertyCount ?? 0) as num).toInt());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          _popularCardShell(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_green, _deepGreen],
                ),
              ),
              child: Align(
                alignment: const Alignment(0.6, -0.5),
                child: Icon(Icons.location_city_rounded,
                    size: 64.sp, color: Colors.white.withValues(alpha: 0.25)),
              ),
            ),
            title: 'All Areas',
            count: '$total Properties',
            onTap: _openPopularViewAll,
          ),
          ...areas.map((area) {
            final idx = areas.indexOf(area);
            return Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: _popularCardShell(
                background: _cachedImage(area.image,
                    width: 230.w, height: 160.h, fallbackIcon: Icons.location_city_rounded),
                delay: (idx + 1 > 5 ? 5 : idx + 1) * 70,
                title: area.locality ?? '',
                count: '${area.propertyCount ?? 0} Properties',
                onTap: () {
                  final propertyData = {
                    'title': '${area.locality ?? 'Popular'} Area Properties',
                    'locality': area.locality ?? '',
                    'city': controller.homeFeed.value?.location?.city ?? 'Indore',
                    'images': area.image != null ? [{'url': area.image}] : [],
                    'price': 'Explore Available',
                    'description':
                    'Explore ${area.propertyCount ?? 0}+ verified properties available in ${area.locality ?? 'this area'}.',
                    'category': 'Residential',
                    'transactionType': 'Sale / Rent',
                  };
                  Get.toNamed(AppRoutes.propertyDetails, arguments: {'property': propertyData});
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  //  VERIFIED AGENTS  (300px cards, WhatsApp + Call buttons)
  // ---------------------------------------------------------------
  Widget _buildVerifiedAgent() {
    if (controller.isLoading.value) return _sectionLoader(height: 150);
    final agents = controller.homeFeed.value?.agents ?? [];
    if (agents.isEmpty) {
      return _buildEmptySectionMessage(
        'No registered agents found in this area yet.',
        title: 'No Verified Agents',
        type: EmptyStateType.agent,
      );
    }
    return _VerifiedAgentsList(
      agents: agents,
      cachedImageBuilder: _cachedImage,
      onProfileTap: _showAgentProfileBottomSheet,
      onWhatsApp: (agent) {
        final phone = (agent.contact?.phone ?? agent.phone ?? '').toString();
        _launchAgentWhatsApp(phone, (agent.name ?? 'Agent').toString());
      },
      onCall: (agent) {
        final phone = (agent.contact?.phone ?? agent.phone ?? '').toString();
        if (phone.isNotEmpty) _makeAgentCall(phone);
      },
    );
  }

  void _showAgentProfileBottomSheet(BuildContext context, dynamic agent) {
    final name = agent.name ?? 'Verified Agent';
    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'A';
    final avatar = agent.avatar;
    final businessName = agent.business?.businessName;
    final businessType = agent.business?.businessType;
    final gstin = agent.business?.gstin;
    final officeAddress = agent.business?.officeAddress;
    final role = agent.role ?? agent.accountType ?? 'Real Estate Agent';
    final subtitle = (businessName != null && businessName.isNotEmpty) ? businessName : role;
    final distance = agent.distanceKm;
    final isVerified = agent.isVerified == true;
    final phone = agent.contact?.phone ?? agent.phone ?? '';
    final canCall = agent.contact?.canCall == true || phone.isNotEmpty;
    final reraStatus = agent.rera?.verificationStatus;
    final reraNumber = agent.rera?.registrationNumber;
    final serviceLocalities = agent.location?.serviceLocalities ?? [];

    Widget sectionLabel(String t) => Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(t, style: _t(13, FontWeight.w700, _ink)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 8.h),
                    child: Column(
                      children: [
                        Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2.r)),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Agent Profile Details', style: _t(16, FontWeight.w700, _ink)),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: Icon(Icons.close_rounded, size: 22.sp, color: _muted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(40.r),
                                      child: (avatar != null && avatar.isNotEmpty)
                                          ? Image.network(avatar,
                                          width: 80.w,
                                          height: 80.w,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _largeInitialAvatar(initial))
                                          : _largeInitialAvatar(initial),
                                    ),
                                    if (isVerified)
                                      Container(
                                        width: 22.w,
                                        height: 22.w,
                                        decoration: const BoxDecoration(
                                            color: Colors.white, shape: BoxShape.circle),
                                        child: Icon(Icons.verified_rounded,
                                            color: const Color(0xFF00A884), size: 20.sp),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Text(name, style: _t(18, FontWeight.w700, _ink)),
                                SizedBox(height: 3.h),
                                Text(subtitle,
                                    textAlign: TextAlign.center,
                                    style: _t(11.5, FontWeight.w500, _muted)),
                                if (isVerified) ...[
                                  SizedBox(height: 10.h),
                                  Container(
                                    padding:
                                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F7F2),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                          color: const Color(0xFFBCE7DA), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_user_outlined,
                                            size: 13.sp, color: _green),
                                        SizedBox(width: 5.w),
                                        Text('DigiNiwas Verified Partner',
                                            style: _t(11, FontWeight.w600, _green)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            alignment: WrapAlignment.center,
                            children: [
                              if (distance != null)
                                _tagBadge(
                                    '${distance is double ? distance.toStringAsFixed(1) : distance} km away'),
                              if (reraStatus != null) _tagBadge('RERA: $reraStatus'),
                            ],
                          ),
                          if (businessName != null ||
                              businessType != null ||
                              (gstin != null && gstin.isNotEmpty) ||
                              (officeAddress != null && officeAddress.isNotEmpty)) ...[
                            SizedBox(height: 18.h),
                            sectionLabel('Business Details'),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: const Color(0xFFEDF2F7)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (businessName != null && businessName.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Text('Company: $businessName',
                                          style: _t(11.5, FontWeight.w600, _ink)),
                                    ),
                                  if (businessType != null && businessType.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Text('Type: $businessType',
                                          style: _t(11, FontWeight.w400, _muted)),
                                    ),
                                  if (gstin != null && gstin.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Text('GSTIN: $gstin',
                                          style: _t(11, FontWeight.w400, _muted)),
                                    ),
                                  if (officeAddress != null && officeAddress.isNotEmpty)
                                    Text('Office: $officeAddress',
                                        style: _t(11, FontWeight.w400, _muted)),
                                ],
                              ),
                            ),
                          ],
                          if (reraNumber != null && reraNumber.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            sectionLabel('RERA Registration'),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: const Color(0xFFEDF2F7)),
                              ),
                              child: Text('Reg No: $reraNumber',
                                  style: _t(11.5, FontWeight.w600, _ink)),
                            ),
                          ],
                          if (serviceLocalities.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            sectionLabel('Service Localities'),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children:
                              serviceLocalities.map<Widget>((l) => _tagBadge('$l')).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    bottom: true,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _launchAgentWhatsApp(phone, name);
                              },
                              icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.sp),
                              label: Text('WhatsApp', style: _t(14, FontWeight.w700, _green)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _green,
                                side: const BorderSide(color: _green, width: 1.5),
                                minimumSize: Size.fromHeight(42.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r)),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: canCall && phone.isNotEmpty
                                  ? () {
                                Navigator.of(sheetContext).pop();
                                _makeAgentCall(phone);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: Size.fromHeight(42.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r)),
                              ),
                              icon: Icon(Icons.call_outlined, size: 18.sp),
                              label: Text('Call Agent', style: _t(14, FontWeight.w700, Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _largeInitialAvatar(String initial) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: const BoxDecoration(color: Color(0xFFA8E6CF), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: _t(26, FontWeight.w700, _navy)),
    );
  }

  Future<void> _makeAgentCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _launchAgentWhatsApp(String phone, String name) async {
    final String clean = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse(
        'https://wa.me/$clean?text=Hello $name, I found your profile on DigiNiwas and want to connect.');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _tagBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration:
      BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20.r)),
      child: Text(label, style: _t(10.5, FontWeight.w500, const Color(0xFF475569))),
    );
  }

  // ---------------------------------------------------------------
  //  BOTTOM NAV  (floating · transparent glass · 66px pill · 62px AI button)
  // ---------------------------------------------------------------
  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        // floating: stays away from the screen edges
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: 66.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10222B).withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: BackdropFilter(
                  // transparent glass: content behind the bar shows blurred
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _navItem(icon: Icons.home_outlined, label: 'Home', index: 0),
                        _navItem(icon: Icons.explore_outlined, label: 'Explore', index: 1),
                        SizedBox(width: 62.w),
                        _navItem(icon: Icons.favorite_border_rounded, label: 'Saved', index: 3),
                        _navItem(icon: Icons.person_outline_rounded, label: 'Profile', index: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -22.h,
              child: _AiFab(onTap: () => controller.changeBottomNavIndex(2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final selected = controller.bottomNavIndex.value == index;
    // slightly darker than before so labels stay readable on the glass bar
    const inactive = Color(0xFF5E7076);
    final color = selected ? _green : inactive;

    return InkWell(
      onTap: () => controller.changeBottomNavIndex(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: const Duration(milliseconds: 220),
                builder: (_, c, __) => Icon(icon, color: c, size: 22.sp),
              ),
            ),
            SizedBox(height: 3.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: _t(11, FontWeight.w600, color),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  TESTIMONIALS  (heading + horizontal 290px light cards)
  // ---------------------------------------------------------------
  Widget _buildCommunityTestimonialsSection(BuildContext context) {
    return Obx(() {
      final items = controller.testimonials.toList();
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What Our Clients Say', style: _t(16, FontWeight.w800, _ink)),
                Padding(
                  padding: EdgeInsets.only(top: 4.h, bottom: 12.h),
                  child: Text(
                    'Real experiences from people using DigiNiwas to discover, compare and move closer to their next property.',
                    style: _t(12, FontWeight.w400, _muted, h: 1.5),
                  ),
                ),
              ],
            ),
          ),
          TestimonialCarousel(items: items),
        ],
      );
    });
  }

  // ---------------------------------------------------------------
  //  FOLLOW US  (dark #10222B card, 3 round icon buttons)
  // ---------------------------------------------------------------
  Widget _buildFollowUsCard() {
    Widget social(Widget icon, String url) {
      return FluidSpringTap(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: 42.w,
          height: 42.w,
          margin: EdgeInsets.only(left: 10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(child: icon),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AutoFloatWidget(
        distance: 1.5,
        duration: const Duration(milliseconds: 3800),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10222B).withValues(alpha: 0.28),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Follow Us', style: _t(12, FontWeight.w400, Colors.white.withValues(alpha: 0.7))),
                  SizedBox(height: 2.h),
                  Text('@diginiwas', style: _t(17, FontWeight.w800, Colors.white)),
                ],
              ),
              Row(
                children: [
                  social(Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20.sp),
                      'https://www.instagram.com/'),
                  social(Icon(Icons.facebook_outlined, color: Colors.white, size: 20.sp),
                      'https://www.facebook.com/'),
                  social(Text('in', style: _t(14, FontWeight.w800, Colors.white)),
                      'https://www.linkedin.com/'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  QUICK ACTIONS  (2x2 grid of cards)
  // ---------------------------------------------------------------
  Widget _buildQuickActions(BuildContext context) {
    Widget action(IconData icon, String title, String sub, VoidCallback onTap,
        {int delay = 0}) {
      return AutoFloatWidget(
        distance: 1.8,
        phaseShift: (delay * 0.002) % 1.0,
        duration: Duration(milliseconds: 3200 + delay * 2),
        child: FluidSpringTap(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: _card(r: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoPulseCard(
                  minScale: 0.94,
                  maxScale: 1.06,
                  duration: const Duration(milliseconds: 2200),
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                        color: _softGreen, borderRadius: BorderRadius.circular(12.r)),
                    child: Icon(icon, color: _green, size: 22.sp),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(title, style: _t(13, FontWeight.w700, _ink)),
                Text(sub, style: _t(11, FontWeight.w400, _muted)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          child: Text('Quick Actions', style: _t(16, FontWeight.w800, _ink)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: GridView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              mainAxisExtent: 112.h,
            ),
            children: [
              action(Icons.chat_bubble_outline_rounded, 'Feedback', 'Share your thoughts',
                      () => _showFeedbackDialog(context), delay: 0),
              action(Icons.star_outline_rounded, 'Rate Us', 'Rate on Play Store',
                      () => _showRateUsDialog(context), delay: 80),
              action(Icons.share_outlined, 'Share', 'Invite your friends', () async {
                // ignore: deprecated_member_use
                await Share.share(
                  'Find verified properties and connect with trusted partners on DigiNiwas! Download now: https://diginiwas.com',
                  subject: 'DigiNiwas Property Search',
                );
              }, delay: 160),
              action(Icons.headset_mic_outlined, 'Raise Support', "We're here to help",
                      () => _showSupportDialog(context), delay: 240),
            ],
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    int rating = 5;
    final textController = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            title: Row(
              children: [
                Icon(Icons.rate_review_outlined, color: _green, size: 22.sp),
                SizedBox(width: 8.w),
                Text('Share Feedback', style: _t(16, FontWeight.w700, _navy)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How was your experience using DigiNiwas?',
                      style: _t(12, FontWeight.w400, Colors.grey.shade700)),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        iconSize: 30.sp,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFFFB800),
                        ),
                        onPressed: () => setState(() => rating = i + 1),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us how we can improve...',
                      hintStyle: _t(11.5, FontWeight.w400, Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.all(12.w),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(color: _green, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel', style: _t(14, FontWeight.w500, Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                    'Feedback Received',
                    'Thank you for helping us improve DigiNiwas!',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: _green,
                    colorText: Colors.white,
                    margin: EdgeInsets.all(16.w),
                    borderRadius: 12.r,
                    duration: const Duration(seconds: 3),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: Text('Submit', style: _t(14, FontWeight.w600, Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRateUsDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Icon(Icons.stars_rounded, color: const Color(0xFFFFB800), size: 48.sp),
            SizedBox(height: 8.h),
            Text('Enjoying DigiNiwas?', style: _t(16, FontWeight.w700, _navy)),
          ],
        ),
        content: Text(
          'Your ratings inspire us to provide verified properties and seamless services. Please take a moment to rate us!',
          textAlign: TextAlign.center,
          style: _t(12, FontWeight.w400, Colors.grey.shade700),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Later', style: _t(14, FontWeight.w500, Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Thank You!',
                'We truly appreciate your support and rating!',
                snackPosition: SnackPosition.TOP,
                backgroundColor: _green,
                colorText: Colors.white,
                margin: EdgeInsets.all(16.w),
                borderRadius: 12.r,
                duration: const Duration(seconds: 3),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            ),
            child: Text('Rate 5 Stars', style: _t(14, FontWeight.w600, Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    Widget tile(IconData icon, Color fg, Color bg, String title, String sub, VoidCallback onTap) {
      return ListTile(
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.r)),
          child: Icon(icon, color: fg, size: 20.sp),
        ),
        title: Text(title, style: _t(13, FontWeight.w600, _ink)),
        subtitle: Text(sub, style: _t(11, FontWeight.w400, Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      );
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.headset_mic_rounded, color: _green, size: 24.sp),
                SizedBox(width: 10.w),
                Text('DigiNiwas Support', style: _t(16, FontWeight.w700, _navy)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
              ],
            ),
            SizedBox(height: 14.h),
            Text('How would you like to connect with our support desk?',
                style: _t(12, FontWeight.w400, Colors.grey.shade600)),
            SizedBox(height: 18.h),
            tile(Icons.email_outlined, _green, const Color(0xFFE6F4EA), 'Email Support',
                'support@diginiwas.com', () async {
                  Get.back();
                  final uri = Uri.parse(
                      'mailto:support@diginiwas.com?subject=Support%20Request%20-%20DigiNiwas');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                }),
            SizedBox(height: 8.h),
            tile(Icons.phone_in_talk_outlined, const Color(0xFF0284C7), const Color(0xFFE0F2FE),
                'Call Support Helpline', '+91 8000 000 000 (Mon - Sat, 9am - 7pm)', () async {
                  Get.back();
                  final uri = Uri.parse('tel:+918000000000');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                }),
            SizedBox(height: 12.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ================================================================
//  EXPLORE MAP WRAPPER
// ================================================================
class ExploreMapViewScreen extends StatelessWidget {
  const ExploreMapViewScreen({super.key});

  @override
  Widget build(BuildContext context) => const BuyerMapScreen();
}

// ================================================================
//  HERO BANNER CAROUSEL  (180px · radius 24 · dots bottom-left)
//  Overlay rgba(16,34,43,.48) + tag / headline / Explore button are
//  shown only when the banner provides a title; otherwise the plain
//  image is shown.
// ================================================================
class HeroBannerCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> tags;
  final List<String> titles;
  const HeroBannerCarousel({
    super.key,
    required this.imageUrls,
    this.tags = const [],
    this.titles = const [],
  });

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.imageUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_pageController.hasClients) {
          _currentPage = (_currentPage + 1) % widget.imageUrls.length;
          _pageController.animateToPage(_currentPage,
              duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _at(List<String> l, int i) => i < l.length ? l[i] : '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10222B).withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) {
                final title = _at(widget.titles, i);
                final tag = _at(widget.tags, i);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageCase(
                      url: widget.imageUrls[i],
                      width: double.infinity,
                      height: 180.h,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.landscape_rounded,
                    ),
                    if (title.isNotEmpty) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10222B).withValues(alpha: 0.48),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tag.isNotEmpty)
                              Text(tag.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(11, FontWeight.w700, _mint, ls: 0.66)),
                            SizedBox(height: 8.h),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 220.w),
                              child: Text(title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(20, FontWeight.w800, Colors.white, h: 1.25)),
                            ),
                            SizedBox(height: 14.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                              decoration: BoxDecoration(
                                color: _green,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text('Explore', style: _t(12, FontWeight.w700, Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                left: 20.w,
                bottom: 12.h,
                child: Row(
                  children: List.generate(widget.imageUrls.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: 5.w),
                      width: active ? 18.w : 4.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : const Color(0x99FFFFFF),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
//  SHARED PROPERTY CARD
//  white · radius 22 · padding 10 · border #F0F4F3 · image radius 16
//  title 15/700 + price 15/800 green · sub 12 muted · optional button
// ================================================================
class _PropertyCard extends StatefulWidget {
  final List<String> imageUrls;
  final double imageHeight;
  final String badgeLabel;
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final String priceText;
  final String? propertyId;
  final BuyerHomeController controller;
  final VoidCallback onTap;
  final bool showButton;
  final int revealDelay;

  const _PropertyCard({
    required this.imageUrls,
    required this.imageHeight,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.propertyId,
    required this.controller,
    required this.onTap,
    this.showButton = false,
    this.revealDelay = 0,
  });

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.imageUrls.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_pageController.hasClients) {
          _currentPage = (_currentPage + 1) % widget.imageUrls.length;
          _pageController.animateToPage(_currentPage,
              duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _image(String? url) {
    final radius = BorderRadius.circular(16.r);
    return LayoutBuilder(
      builder: (context, c) => ImageCase(
        url: url,
        width: c.maxWidth.isFinite ? c.maxWidth : 250.w,
        height: widget.imageHeight.h,
        fit: BoxFit.cover,
        fallbackIcon: Icons.home_work_rounded,
        borderRadius: radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _Reveal(delay: widget.revealDelay, child: _buildCard());

  Widget _buildCard() {
    final urls = widget.imageUrls;
    return FluidSpringTap(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: _card(r: 22, shadow: _cardShadow),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    height: widget.imageHeight.h,
                    width: double.infinity,
                    child: urls.isNotEmpty
                        ? PageView.builder(
                      controller: _pageController,
                      itemCount: urls.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, i) => _image(urls[i]),
                    )
                        : _image(null),
                  ),
                ),
                Positioned(
                  left: 10.w,
                  top: 10.h,
                  child: _ImageBadge(label: widget.badgeLabel, icon: widget.badgeIcon),
                ),
                Positioned(
                  right: 10.w,
                  top: 10.h,
                  child: _SaveHeart(controller: widget.controller, propertyId: widget.propertyId),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(15, FontWeight.w700, _ink)),
                      ),
                      SizedBox(width: 8.w),
                      Text(widget.priceText, style: _t(15, FontWeight.w800, _green)),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12, FontWeight.w400, _muted)),
                  if (widget.showButton) ...[
                    SizedBox(height: 10.h),
                    _Shine(
                        radius: 12.r,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('VIEW DETAILS', style: _t(12, FontWeight.w800, Colors.white)),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: Colors.white),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
//  NEW LISTING CARD  (full-width, 140px image, "New" badge)
// ================================================================
class NewListingCard extends StatelessWidget {
  final dynamic item;
  final BuyerHomeController controller;
  final VoidCallback onTap;
  final int revealDelay;

  const NewListingCard({
    super.key,
    this.revealDelay = 0,
    required this.item,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = _HomeScreenState._extractPropertyImages(item);
    String? propertyId;
    try {
      final j = item.toJson() as Map<String, dynamic>;
      propertyId = j['_id']?.toString() ?? j['propertyId']?.toString();
    } catch (_) {}

    return _PropertyCard(
      revealDelay: revealDelay,
      imageUrls: imageUrls,
      imageHeight: 140,
      badgeLabel: 'New',
      badgeIcon: Icons.auto_awesome_outlined,
      title: item.title ?? 'Property',
      subtitle: formatPropertyLocation(
        locality: item.locality,
        city: item.city,
        address: item.address,
        distanceKm: item.distanceKm,
        sameCity: item.sameCity,
      ),
      priceText: formatPrice(item.price),
      propertyId: propertyId,
      controller: controller,
      onTap: onTap,
    );
  }
}

// ================================================================
//  RECOMMENDED PROPERTY CARD  (250px, 150px image, VIEW DETAILS)
// ================================================================
class RecommendedPropertyCard extends StatelessWidget {
  final Map<String, dynamic> propertyJson;
  final String? title;
  final String? locality;
  final String? city;
  final String? bedrooms;
  final String? furnishing;
  final int? price;
  final List<String> imageUrls;
  final BuyerHomeController controller;
  final int revealDelay;
  final Widget Function(String? url,
      {required double width,
      required double height,
      BoxFit fit,
      IconData fallbackIcon,
      BorderRadius? borderRadius}) cachedImageBuilder;

  const RecommendedPropertyCard({
    super.key,
    this.revealDelay = 0,
    required this.propertyJson,
    required this.title,
    required this.locality,
    required this.city,
    required this.bedrooms,
    required this.furnishing,
    required this.price,
    required this.imageUrls,
    required this.controller,
    required this.cachedImageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final propertyId = propertyJson['_id']?.toString() ?? propertyJson['propertyId']?.toString();
    final loc = formatPropertyLocation(
      locality: locality,
      city: city,
      address: propertyJson['address']?.toString(),
      distanceKm: propertyJson['distanceKm'],
      sameCity: propertyJson['sameCity'] as bool?,
    );
    final bhk = formatBedrooms(
      bedrooms,
      category: propertyJson['category']?.toString(),
      bathrooms: propertyJson['bathrooms'],
    );
    final effectiveImages = imageUrls.isNotEmpty
        ? imageUrls
        : _HomeScreenState._extractPropertyImages(propertyJson);

    return SizedBox(
      width: 250.w,
      child: _PropertyCard(
        revealDelay: revealDelay,
        imageUrls: effectiveImages,
        imageHeight: 150,
        badgeLabel: 'Verified',
        badgeIcon: Icons.check_rounded,
        title: title ?? '',
        subtitle: bhk.isNotEmpty ? '$loc · $bhk' : loc,
        priceText: formatPrice(price),
        propertyId: propertyId,
        controller: controller,
        showButton: true,
        onTap: () => Get.toNamed(AppRoutes.propertyDetails, arguments: {'property': propertyJson}),
      ),
    );
  }
}

// ================================================================
//  VERIFIED AGENT CARD  (300px · avatar 52 · chips · WhatsApp + Call)
// ================================================================
class AutoSlideAgentCard extends StatelessWidget {
  final dynamic agent;
  final String initial;
  final Widget Function(String? url,
      {required double width,
      required double height,
      BoxFit fit,
      IconData fallbackIcon,
      BorderRadius? borderRadius}) cachedImageBuilder;
  final Function(BuildContext, dynamic) onProfileTap;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final int revealDelay;

  const AutoSlideAgentCard({
    super.key,
    this.revealDelay = 0,
    required this.agent,
    required this.initial,
    required this.cachedImageBuilder,
    required this.onProfileTap,
    this.onWhatsApp,
    this.onCall,
  });

  dynamic _read(dynamic Function() f) {
    try {
      return f();
    } catch (_) {
      return null;
    }
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, maxLines: 1, style: _t(10, FontWeight.w700, fg)),
  );

  Widget _btn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? Colors.white : _green;
    return Expanded(
      child: FluidSpringTap(
        onTap: onTap,
        child: Container(
          height: 42.h,
          decoration: BoxDecoration(
            color: filled ? _green : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: filled ? null : Border.all(color: _green, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: fg),
              SizedBox(width: 8.w),
              Text(label, style: _t(14, FontWeight.w700, fg)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _read(() => agent.distanceKm);
    final rera = _read(() => agent.rera?.verificationStatus);
    final hasAvatar = (agent.avatar?.isNotEmpty == true);
    final distText = distance == null
        ? null
        : '${distance is num ? distance.toStringAsFixed(1) : distance} km away';

    return FluidSpringTap(
      onTap: () => onProfileTap(context, agent),
      child: Container(
        width: 300.w,
        padding: EdgeInsets.all(14.r),
        decoration: _card(r: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AutoPulseCard(
                  minScale: 0.97,
                  maxScale: 1.03,
                  duration: const Duration(milliseconds: 2800),
                  child: ClipOval(
                    child: hasAvatar
                        ? cachedImageBuilder(agent.avatar,
                        width: 52.w, height: 52.w, fallbackIcon: Icons.person)
                        : Container(
                      width: 52.w,
                      height: 52.w,
                      color: const Color(0xFFCFE4DD),
                      alignment: Alignment.center,
                      child: Icon(Icons.person_outline_rounded, size: 26.sp, color: _green),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agent.name ?? 'Agent',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(15, FontWeight.w700, _ink)),
                      SizedBox(height: 3.h),
                      BadgeJiggle(
                        interval: const Duration(seconds: 4),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14.sp, color: _green),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text('DigiNiwas Verified Partner',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(11, FontWeight.w700, _green)),
                            ),
                          ],
                        ),
                      ),
                      if (distText != null || rera != null) ...[
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: [
                            if (distText != null) _pill(distText, _chipGrey, const Color(0xFF41555B)),
                            if (rera != null) _pill('RERA: $rera', _softGreen, _green),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _btn(
                  context: context,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  filled: false,
                  onTap: onWhatsApp ?? () => onProfileTap(context, agent),
                ),
                SizedBox(width: 10.w),
                _btn(
                  context: context,
                  icon: Icons.call_outlined,
                  label: 'Call Agent',
                  filled: true,
                  onTap: onCall ?? () => onProfileTap(context, agent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedAgentsList extends StatelessWidget {
  const _VerifiedAgentsList({
    required this.agents,
    required this.cachedImageBuilder,
    required this.onProfileTap,
    this.onWhatsApp,
    this.onCall,
  });

  final List<dynamic> agents;
  final Widget Function(String? url,
      {required double width,
      required double height,
      BoxFit fit,
      IconData fallbackIcon,
      BorderRadius? borderRadius}) cachedImageBuilder;
  final void Function(BuildContext, dynamic) onProfileTap;
  final void Function(dynamic agent)? onWhatsApp;
  final void Function(dynamic agent)? onCall;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(agents.length, (i) {
          final agent = agents[i];
          final initial = (agent.name?.trim().isNotEmpty == true)
              ? agent.name!.trim().substring(0, 1).toUpperCase()
              : 'A';
          return Padding(
            padding: EdgeInsets.only(right: i == agents.length - 1 ? 0 : 12.w),
            child: AutoSlideAgentCard(
              revealDelay: (i > 5 ? 5 : i) * 70,
              agent: agent,
              initial: initial,
              cachedImageBuilder: cachedImageBuilder,
              onProfileTap: (ctx, ag) => onProfileTap(ctx, ag),
              onWhatsApp: onWhatsApp == null ? null : () => onWhatsApp!(agent),
              onCall: onCall == null ? null : () => onCall!(agent),
            ),
          );
        }),
      ),
    );
  }
}

// ================================================================
//  FUTURE ECOSYSTEM  (white card · badge · title · list rows)
// ================================================================
class FutureEcosystemWidget extends StatelessWidget {
  const FutureEcosystemWidget({super.key});

  static const _services = [
    (Icons.apartment_outlined, 'Property Mgmt', 'End-to-end property management services.', false),
    (Icons.build_outlined, 'Maintenance', 'Reliable maintenance services at your doorstep.', false),
    (Icons.groups_outlined, 'Tenant Support', 'Quick tenant support and issue resolution.', false),
    (Icons.currency_rupee_rounded, 'Rent Collection', 'Hassle-free rent collection and tracking.', true),
    (Icons.shopping_cart_outlined, 'Groceries', 'Daily groceries delivered to your home.', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AutoFloatWidget(
        distance: 1.5,
        duration: const Duration(milliseconds: 3800),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: _card(r: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BadgeJiggle(
                interval: const Duration(seconds: 4),
                child: ShimmerGlowEffect(
                  borderRadius: BorderRadius.circular(999),
                  shimmerColor: const Color(0x44FFFFFF),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_outlined, size: 14.sp, color: Colors.white),
                        SizedBox(width: 6.w),
                        Text('FUTURE ECOSYSTEM',
                            style: _t(10, FontWeight.w800, Colors.white, ls: 0.6)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text('Beyond Properties, Endless Possibilities.',
                  style: _t(19, FontWeight.w800, _ink, h: 1.25)),
            Padding(
              padding: EdgeInsets.only(top: 8.h, bottom: 6.h),
              child: Text(
                'DigiNiwas is building an ecosystem that makes life easier for customers and helps businesses grow together.',
                style: _t(12, FontWeight.w400, _muted, h: 1.5),
              ),
            ),
            ..._services.map((s) {
              final (icon, title, desc, filled) = s;
              return _Reveal(
                  delay: _services.indexOf(s) * 80,
                  dy: 14,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                              color: _softGreen, borderRadius: BorderRadius.circular(12.r)),
                          child: Icon(icon, color: _green, size: 22.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: _t(13, FontWeight.w700, _ink)),
                              Text(desc, style: _t(11, FontWeight.w400, _muted, h: 1.4)),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: filled ? _green : _chipGrey,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Coming Soon',
                              style: _t(10, FontWeight.w700, filled ? Colors.white : _muted)),
                        ),
                      ],
                    ),
                  ));
            }),
          ],
        ),
      ),
    ),
  );
}
}

// ================================================================
//  TESTIMONIALS  (horizontal 290px white cards · 5 amber stars)
// ================================================================
class TestimonialCarousel extends StatelessWidget {
  final List<TestimonialModel> items;
  const TestimonialCarousel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final t = items[i];
          return Padding(
            padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 12.w),
            child: AutoFloatWidget(
              distance: 2.0,
              phaseShift: (i % 3) * 0.33,
              duration: Duration(milliseconds: 3400 + (i % 2) * 300),
              child: FluidSpringTap(
                child: Container(
                  width: 290.w,
                  padding: EdgeInsets.all(16.r),
                  decoration: _card(r: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerGlowEffect(
                        borderRadius: BorderRadius.circular(8.r),
                        shimmerColor: const Color(0x33F2A33A),
                        pauseDuration: const Duration(seconds: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (_) => Padding(
                              padding: EdgeInsets.only(right: 3.w),
                              child: Icon(Icons.star_rounded, size: 14.sp, color: const Color(0xFFF2A33A)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Text(t.review,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: _t(13, FontWeight.w400, _ink, h: 1.5)),
                      ),
                      Text(t.name, style: _t(13, FontWeight.w700, _ink)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ================================================================
//  SOCIAL SPEED DIAL (kept for compatibility, not used on home)
// ================================================================
class SocialSpeedDialMenu extends StatefulWidget {
  const SocialSpeedDialMenu({super.key});

  @override
  State<SocialSpeedDialMenu> createState() => _SocialSpeedDialMenuState();
}

class _SocialSpeedDialMenuState extends State<SocialSpeedDialMenu>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _ac;
  late Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expand = CurvedAnimation(parent: _ac, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _ac.forward() : _ac.reverse();
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _btn(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () {
        _toggle();
        _openUrl(url);
      },
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(child: Icon(icon, color: color, size: 20.sp)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60.w,
      height: 200.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _expand,
            builder: (context, child) => Transform.scale(
              scale: _expand.value,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: _expand.value,
                child: IgnorePointer(
                  ignoring: !_isOpen,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _btn(Icons.work_outline_rounded, const Color(0xFF0A66C2),
                          'https://www.linkedin.com/'),
                      SizedBox(height: 8.h),
                      _btn(Icons.facebook_rounded, const Color(0xFF1877F2),
                          'https://www.facebook.com/'),
                      SizedBox(height: 8.h),
                      _btn(Icons.camera_alt_outlined, const Color(0xFFE4405F),
                          'https://www.instagram.com/'),
                      SizedBox(height: 54.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.w),
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: _isOpen ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(_isOpen ? Icons.close_rounded : Icons.share_rounded,
                        color: Colors.white, size: 22.sp),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ================================================================
//  MOTION HELPERS
// ================================================================

/// Fade + slide-up. Plays when first built AND again every time the item
/// leaves the scroll viewport and comes back (vertical or horizontal).
class _Reveal extends StatefulWidget {
  final Widget child;
  final int delay;
  final double dy;
  const _Reveal({super.key, required this.child, this.delay = 0, this.dy = 26});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;
  ScrollableState? _sc;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay <= 0) {
      _c.forward();
    } else {
      _timer = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted && !_hidden) _c.forward();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final n = Scrollable.maybeOf(context);
    if (!identical(n, _sc)) {
      _sc?.position.removeListener(_check);
      _sc = n;
      _sc?.position.addListener(_check);
    }
  }

  @override
  void deactivate() {
    _sc?.position.removeListener(_check);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _sc?.position.addListener(_check);
  }

  void _check() {
    if (!mounted || _sc == null) return;
    try {
      if (!context.mounted) return;
      final ro = context.findRenderObject();
      final scContext = _sc?.context;
      if (scContext == null || !scContext.mounted) return;
      final vo = scContext.findRenderObject();
      if (ro is! RenderBox || vo is! RenderBox) return;
      if (!ro.attached || !vo.attached || !ro.hasSize || !vo.hasSize) return;
      final item = ro.localToGlobal(Offset.zero) & ro.size;
      final view = vo.localToGlobal(Offset.zero) & vo.size;
      final far = !item.overlaps(view.inflate(60));
      final near = item.overlaps(view.deflate(30));
      if (far && !_hidden) {
        _hidden = true;
        _timer?.cancel();
        _c.value = 0; // silently reset, offscreen
      } else if (_hidden && near) {
        _hidden = false;
        _c.forward(from: 0); // play again as it scrolls back in
      }
    } catch (_) {
      // Element may be inactive or being recycled during fast scroll.
    }
  }

  @override
  void dispose() {
    _sc?.position.removeListener(_check);
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.dy),
          child: child,
        ),
      ),
    );
  }
}

/// Tap target with press-down shrink and (web/desktop/stylus) hover lift.
/// Optional [revealDelay] adds a staggered entrance.
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  const _Tap({
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
  });

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  static const double _pressScale = 0.97;
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? _pressScale : (_hover ? widget.hoverScale : 1.0);
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Soft light sweep across a button every few seconds.
class _Shine extends StatefulWidget {
  final Widget child;
  final double radius;
  const _Shine({required this.child, required this.radius});

  @override
  State<_Shine> createState() => _ShineState();
}

class _ShineState extends State<_Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: LayoutBuilder(
                builder: (context, cons) {
                  final w = cons.maxWidth;
                  return AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform((_c.value / 0.55).clamp(0.0, 1.0));
                      return Transform.translate(
                        offset: Offset(-w * 0.6 + t * w * 1.8, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: w * 0.45,
                            height: double.infinity,
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gentle looping scale "breathing" for small accent icons.
class _Breathe extends StatefulWidget {
  final Widget child;
  const _Breathe({required this.child});

  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: 0.92 + 0.2 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
    );
  }
}

/// Short bell-ring shake every few seconds while [active].
class _Wiggle extends StatefulWidget {
  final Widget child;
  final bool active;
  const _Wiggle({required this.child, required this.active});

  @override
  State<_Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<_Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = (_c.value / 0.18).clamp(0.0, 1.0);
        final angle = t >= 1.0 ? 0.0 : 0.35 * (1 - t) * math.sin(t * math.pi * 6);
        return Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child);
      },
    );
  }
}

/// Center bottom-nav AI button: floats slightly and emits a soft pulse ring.
class _AiFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AiFab({required this.onTap});

  @override
  State<_AiFab> createState() => _AiFabState();
}

class _AiFabState extends State<_AiFab> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 62.w;
    return _Tap(
      onTap: widget.onTap,
      hoverScale: 1.06,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final ring = Curves.easeOut.transform(t);
            final float = math.sin(t * math.pi * 2) * -2.0;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + 0.5 * ring,
                  child: Opacity(
                    opacity: (0.38 * (1 - ring)).clamp(0.0, 1.0),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 2),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, float),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10222B).withValues(alpha: 0.24),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/niwas_ai_icon.png',
                        width: 42.w,
                        height: 32.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}