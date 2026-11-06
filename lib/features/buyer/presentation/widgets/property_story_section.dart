import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/buyer_home_controller.dart';
import '../../models/property_model_story.dart';
import '../property_story_screen.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../../core/widgets/app_image.dart';

// Same tokens as the Home screen design
const Color _sGreen = Color(0xFF0B6E5F);
const Color _sInk = Color(0xFF10222B);
const Color _sMuted = Color(0xFF5E7076);
const Color _sSeen = Color(0xFFD5DEDC);
const Color _sSkeleton = Color(0xFFEEF2F1);

/// Left & right gutter of the whole section (title, "View All" and the
/// first / last story circle all line up on this edge).
const double _kGutter = 20;

/// Entrance stagger: first circle starts after this many ms, then +70ms each
/// (same rhythm as the Home cards).
const int _kBaseDelay = 120;

/// "Property Stories" – sits right below the search bar.
/// Data: boosted / AI-suggested properties. If none → container (promo) stories.
class PropertyStoriesSection extends StatelessWidget {
  final BuyerHomeController controller;
  const PropertyStoriesSection({super.key, required this.controller});

  List<PropertyStoryModel> _stories() {
    final feed = controller.homeFeed.value?.boostedProperties ?? [];
    final standalone = controller.boostedPropertiesData.value?.properties ?? [];

    final List<Map<String, dynamic>> raw = feed.isNotEmpty
        ? feed.map((e) => e.toJson()).toList()
        : standalone.map((e) => e.toJson()).toList();

    final reviews = controller.testimonials
        .where((t) => t.isActive && t.review.trim().isNotEmpty)
        .toList();
    final review = reviews.isNotEmpty ? reviews.first : null;

    if (raw.isEmpty) {
      return const <PropertyStoryModel>[];
    }

    final list = <PropertyStoryModel>[
      for (int i = 0; i < raw.length && i < 10; i++)
        PropertyStoryModel.fromPropertyJson(raw[i], isNew: i == 0),
    ];
    if (review != null) list.add(PropertyStoryModel.fromTestimonial(review));
    return list;
  }

  void _openStories(List<PropertyStoryModel> stories, int index) {
    if (stories.isEmpty) return;
    Get.to(
          () => PropertyStoryScreen(
        stories: stories,
        initialIndex: index,
        controller: controller,
      ),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final feed = controller.homeFeed.value?.boostedProperties ?? [];
      final standalone = controller.boostedPropertiesData.value?.properties ?? [];
      final loading = (controller.isLoading.value || controller.boostedLoading.value) &&
          feed.isEmpty &&
          standalone.isEmpty;
      final seen = PropertyStoryModel.seen.toSet(); // subscribe to changes
      final stories = loading ? <PropertyStoryModel>[] : _stories();
      if (stories.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------- title row (fades + slides in) ----------
          _StoryReveal(
            delay: 0,
            dy: 14,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _kGutter.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Property Stories',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: _sInk)),
                        SizedBox(height: 1.h),
                        Text('Short videos, real stories, real properties.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w400,
                                color: _sMuted)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _StoryTap(
                    onTap: () => _openStories(stories, 0),
                    pressScale: 0.94,
                    hoverScale: 1.04,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text('View All',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: _sGreen)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // ---------- story circles: same gutter, scrolls edge to edge ----------
          if (loading)
            SizedBox(
              height: 74.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(_kGutter.w, 10.h, _kGutter.w, 0),
                itemCount: 5,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (_, __) => Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: const BoxDecoration(
                      color: _sSkeleton, shape: BoxShape.circle),
                ),
              ),
            )
          else
          // Height is driven by the content (circle + label), so there is
          // no leftover empty space under the stories.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: EdgeInsets.fromLTRB(_kGutter.w, 10.h, _kGutter.w, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(stories.length, (i) {
                  final s = stories[i];
                  return Padding(
                    padding: EdgeInsets.only(right: i == stories.length - 1 ? 0 : 8.w),
                    child: AutoFloatWidget(
                      distance: 1.6,
                      phaseShift: (i % 4) * 0.25,
                      duration: Duration(milliseconds: 3000 + (i % 3) * 200),
                      child: _StoryReveal(
                        delay: _kBaseDelay + (i > 5 ? 5 : i) * 70,
                        dy: 18,
                        scaleFrom: 0.86,
                        child: _StoryCircle(
                          story: s,
                          seen: seen.contains(s.id),
                          onTap: () => _openStories(stories, i),
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
//  STORY CIRCLE
//  - unseen ring: slow rotating gradient
//  - "New" badge pops in
//  - press = shrink, hover = small lift (same feel as Home cards)
// ================================================================
class _StoryCircle extends StatefulWidget {
  final PropertyStoryModel story;
  final bool seen;
  final VoidCallback onTap;
  const _StoryCircle({required this.story, required this.seen, required this.onTap});

  @override
  State<_StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<_StoryCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
  AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    if (!widget.seen) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _StoryCircle old) {
    super.didUpdateWidget(old);
    if (widget.seen) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Widget _gradient() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: widget.story.gradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Icon(widget.story.icon, color: Colors.white.withValues(alpha: 0.9), size: 26),
  );

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final size = 64.w;
    final thumb = ImageCase(
      url: story.images.isNotEmpty ? story.images.first : null,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      fallbackIcon: Icons.home_rounded,
    );

    return FluidSpringTap(
      onTap: widget.onTap,
      child: SizedBox(
        width: 74.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AutoPulseCard(
                  enabled: !widget.seen,
                  minScale: 0.97,
                  maxScale: 1.04,
                  duration: const Duration(milliseconds: 2400),
                  child: AnimatedBuilder(
                    animation: _spin,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(child: SizedBox.expand(child: thumb)),
                    ),
                    builder: (context, child) => Container(
                      width: size,
                      height: size,
                      padding: EdgeInsets.all(2.5.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.seen ? _sSeen : null,
                        gradient: widget.seen
                            ? null
                            : SweepGradient(
                          colors: const [
                            Color(0xFF2DD4BF),
                            Color(0xFF10B981),
                            Color(0xFF2DD4BF),
                          ],
                          transform: GradientRotation(_spin.value * 2 * math.pi),
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2.h,
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 13.sp),
                  ),
                ),
                if (story.isNew)
                  Positioned(
                    top: -7.h,
                    child: BadgeJiggle(
                      interval: const Duration(seconds: 3),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: _sGreen,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text('New',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              story.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: _sInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
//  MOTION HELPERS  (same behaviour as Home's _Reveal / _Tap)
// ================================================================

/// Fade + slide-up (+ optional scale). Plays when first built AND again every
/// time the item leaves the scroll viewport and comes back.
class _StoryReveal extends StatefulWidget {
  final Widget child;
  final int delay;
  final double dy;
  final double scaleFrom;
  const _StoryReveal({
    required this.child,
    this.delay = 0,
    this.dy = 26,
    this.scaleFrom = 1.0,
  });

  @override
  State<_StoryReveal> createState() => _StoryRevealState();
}

class _StoryRevealState extends State<_StoryReveal> with SingleTickerProviderStateMixin {
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
          child: Transform.scale(
            scale: widget.scaleFrom + (1 - widget.scaleFrom) * _a.value,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tap target with press-down shrink and (web/desktop/stylus) hover lift.
class _StoryTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressScale;
  const _StoryTap({
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
    this.pressScale = 0.97,
  });

  @override
  State<_StoryTap> createState() => _StoryTapState();
}

class _StoryTapState extends State<_StoryTap> {
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