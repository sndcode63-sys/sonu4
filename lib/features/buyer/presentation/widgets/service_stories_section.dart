import 'dart:async';

import 'package:diginiwas/features/buyer/presentation/widgets/servies_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/buyer_home_controller.dart';
import '../../models/cms_service_model.dart';
import '../../../../core/utils/animation_utils.dart';

// Same tokens as the Home screen design
const Color _green = Color(0xFF0B6E5F);
const Color _ink = Color(0xFF10222B);
const Color _muted = Color(0xFF5E7076);
const Color _softGreen = Color(0xFFE3F1ED);
const Color _border = Color(0xFFF0F4F3);

/// Left & right gutter (same as every other Home section).
const double _kGutter = 20;

List<BoxShadow> get _softShadow => [
  BoxShadow(
    color: const Color(0xFF10222B).withValues(alpha: 0.11),
    blurRadius: 34,
    offset: const Offset(0, 14),
  ),
];

TextStyle _t(double size, FontWeight w, Color c, {double? h}) =>
    GoogleFonts.plusJakartaSans(fontSize: size.sp, fontWeight: w, color: c, height: h);

class ServiceStoriesSection extends StatelessWidget {
  final BuyerHomeController controller;

  const ServiceStoriesSection({
    super.key,
    required this.controller,
  });

  IconData _iconFor(String icon) {
    switch (icon.toLowerCase()) {
      case 'shield':
      case 'insurance':
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'home':
      case 'loan':
      case 'homeloan':
        return Icons.home_work_outlined;
      case 'currency':
      case 'money':
      case 'personalloan':
        return Icons.account_balance_wallet_outlined;
      case 'utility':
      case 'electric':
      case 'solar':
        return Icons.bolt_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  void _open(List<CmsServiceModel> services, int index) {
    Get.to(
          () => ServiceStoryScreen(services: services, initialIndex: index),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final services = controller.cmsServices;
      if (services.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------- section title (same as other Home sections) ----------
          _Reveal(
            dy: 14,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _kGutter.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _Breathe(child: Icon(Icons.campaign_outlined, size: 18.sp, color: _green)),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Service Stories & Offers',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(16, FontWeight.w800, _ink)),
                              SizedBox(height: 1.h),
                              Text('Curated services and offers just for you',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _t(11, FontWeight.w400, _muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _Tap(
                    onTap: () => _open(services, 0),
                    pressScale: 0.94,
                    hoverScale: 1.04,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text('View All', style: _t(13, FontWeight.w700, _green)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // ---------- horizontal cards (same card style as Home) ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: _kGutter.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(services.length, (index) {
                final service = services[index];
                final heroImg = service.heroImage.isNotEmpty
                    ? service.heroImage
                    : (service.imageTags.isNotEmpty ? service.imageTags.first : '');
                return Padding(
                  padding: EdgeInsets.only(right: index == services.length - 1 ? 0 : 12.w),
                  child: AutoFloatWidget(
                    distance: 1.8,
                    phaseShift: (index % 4) * 0.25,
                    duration: Duration(milliseconds: 3200 + (index % 3) * 200),
                    child: _Reveal(
                      delay: 80 + (index > 5 ? 5 : index) * 70,
                      dy: 18,
                      child: _ServiceCard(
                        service: service,
                        heroImg: heroImg,
                        icon: _iconFor(service.icon),
                        showNew: service.isNew || index == 0,
                        onTap: () => _open(services, index),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    });
  }
}

// ================================================================
//  SERVICE CARD  (white · radius 22 · padding 8 · image radius 16)
// ================================================================
class _ServiceCard extends StatelessWidget {
  final CmsServiceModel service;
  final String heroImg;
  final IconData icon;
  final bool showNew;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.heroImg,
    required this.icon,
    required this.showNew,
    required this.onTap,
  });

  Widget _placeholder() => Container(
    color: _softGreen,
    child: Center(child: Icon(Icons.home_work_outlined, color: _green, size: 28.sp)),
  );

  @override
  Widget build(BuildContext context) {
    return FluidSpringTap(
      onTap: onTap,
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: _border, width: 1),
          boxShadow: _softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------- image + badges ----------
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                height: 112.h,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: heroImg.isNotEmpty
                          ? Image.network(
                        heroImg,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _placeholder(),
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                          : _placeholder(),
                    ),
                    if (showNew)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: BadgeJiggle(
                          interval: const Duration(seconds: 4),
                          child: ShimmerGlowEffect(
                            borderRadius: BorderRadius.circular(999),
                            shimmerColor: const Color(0x330B6E5F),
                            pauseDuration: const Duration(seconds: 4),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
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
                                  Icon(Icons.auto_awesome_outlined, size: 11.sp, color: _green),
                                  SizedBox(width: 3.w),
                                  Text('New', style: _t(10, FontWeight.w700, _green)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: AutoPulseCard(
                        minScale: 0.94,
                        maxScale: 1.06,
                        duration: const Duration(milliseconds: 2200),
                        child: Container(
                          width: 28.w,
                          height: 28.w,
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
                          child: Icon(icon, size: 15.sp, color: _green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- text ----------
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 10.h, 4.w, 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(13, FontWeight.w700, _ink)),
                  SizedBox(height: 3.h),
                  Text(service.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(11, FontWeight.w400, _muted, h: 1.35)),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('View Details', style: _t(12, FontWeight.w700, _green)),
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: const BoxDecoration(color: _softGreen, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_forward_rounded, size: 14.sp, color: _green),
                      ),
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

// ================================================================
//  MOTION HELPERS  (same behaviour as Home's _Reveal / _Tap / _Breathe)
// ================================================================

/// Fade + slide-up. Plays when first built AND again every time the item
/// leaves the scroll viewport and comes back.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int delay;
  final double dy;
  const _Reveal({required this.child, this.delay = 0, this.dy = 26});

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
        _c.value = 0; // silently reset while offscreen
      } else if (_hidden && near) {
        _hidden = false;
        _c.forward(from: 0); // play again as it scrolls back in
      }
    } catch (_) {
      // Element may be inactive or unmounted during fast scroll
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
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressScale;
  const _Tap({
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
    this.pressScale = 0.97,
  });

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? widget.pressScale : (_hover ? widget.hoverScale : 1.0);
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

/// Gentle looping scale "breathing" for the small accent icon.
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