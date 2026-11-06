import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppAnimations {
  // 1. Fade Transition Wrapper
  static Widget fadeIn({
    required Widget child,
    required AnimationController controller,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    final Animation<double> fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeIn),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: child,
    );
  }

  // 2. Slide Up Transition (Jaise Bottom Sheet ya Cards niche se upar aate hain)
  static Widget slideUp({
    required Widget child,
    required AnimationController controller,
    Offset beginOffset = const Offset(0, 0.15),
  }) {
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }

  // 3. Scale Animation (Buttons ya Icons ke liye pop effect)
  static Widget scale({
    required Widget child,
    required AnimationController controller,
    double beginScale = 0.85,
  }) {
    final Animation<double> scaleAnimation = Tween<double>(
      begin: beginScale,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: child,
    );
  }
}

/// Interactive scale-on-touch wrapper with spring bounce effect.
/// Perfect for cards, chips, buttons, and list items.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 110),
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Entrance animation combining smooth fade and subtle vertical slide.
class FadeSlideEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Staggered item entrance for lists and grids.
class StaggeredItemEntrance extends StatelessWidget {
  final int index;
  final Widget child;
  final int maxDelayItems;
  final int stepMs;

  const StaggeredItemEntrance({
    super.key,
    required this.index,
    required this.child,
    this.maxDelayItems = 8,
    this.stepMs = 45,
  });

  @override
  Widget build(BuildContext context) {
    final delayIndex = index.clamp(0, maxDelayItems);
    return FadeSlideEntrance(
      delay: Duration(milliseconds: delayIndex * stepMs),
      child: child,
    );
  }
}

/// Gentle continuous floating animation with sine-wave motion.
/// Gives cards an organic, living feel.
class AutoFloatWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double distance;
  final double phaseShift;
  final bool enabled;

  const AutoFloatWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3400),
    this.distance = 2.4,
    this.phaseShift = 0.0,
    this.enabled = true,
  });

  @override
  State<AutoFloatWidget> createState() => _AutoFloatWidgetState();
}

class _AutoFloatWidgetState extends State<AutoFloatWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = (_c.value + widget.phaseShift) % 1.0;
        final dy = math.sin(t * math.pi * 2) * widget.distance;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
    );
  }
}

/// Gentle continuous breathing / pulsing scale animation for highlight cards.
class AutoPulseCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double maxScale;
  final double minScale;
  final double phaseShift;
  final bool enabled;

  const AutoPulseCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2800),
    this.maxScale = 1.015,
    this.minScale = 0.992,
    this.phaseShift = 0.0,
    this.enabled = true,
  });

  @override
  State<AutoPulseCard> createState() => _AutoPulseCardState();
}

class _AutoPulseCardState extends State<AutoPulseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final curveVal = Curves.easeInOut.transform(_c.value);
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * curveVal;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }
}

/// Sweeping shimmer sheen highlight across a card or badge at regular intervals.
class ShimmerGlowEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration pauseDuration;
  final Color shimmerColor;
  final BorderRadius? borderRadius;

  const ShimmerGlowEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.pauseDuration = const Duration(seconds: 4),
    this.shimmerColor = const Color(0x33FFFFFF),
    this.borderRadius,
  });

  @override
  State<ShimmerGlowEffect> createState() => _ShimmerGlowEffectState();
}

class _ShimmerGlowEffectState extends State<ShimmerGlowEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _loop();
  }

  void _loop() async {
    while (mounted) {
      await Future.delayed(widget.pauseDuration);
      if (!mounted) break;
      await _c.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                if (!_c.isAnimating) return const SizedBox.shrink();
                final t = _c.value;
                return FractionallySizedBox(
                  widthFactor: 0.45,
                  alignment: Alignment(-2.0 + t * 4.0, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          widget.shimmerColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Playful periodic jiggle/wobble for badges (e.g. "Verified", "New", "100%").
class BadgeJiggle extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final double maxAngle;

  const BadgeJiggle({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 4),
    this.maxAngle = 0.07,
  });

  @override
  State<BadgeJiggle> createState() => _BadgeJiggleState();
}

class _BadgeJiggleState extends State<BadgeJiggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    _runLoop();
  }

  void _runLoop() async {
    while (mounted) {
      await Future.delayed(widget.interval);
      if (!mounted) break;
      await _c.forward(from: 0.0);
    }
  }

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
      builder: (context, child) {
        final t = _c.value;
        final angle = t == 0.0 || t == 1.0
            ? 0.0
            : math.sin(t * math.pi * 4) * widget.maxAngle * (1 - t);
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
    );
  }
}

/// Fluid spring tap interaction with natural bounce back on release.
class FluidSpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final HitTestBehavior behavior;

  const FluidSpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.965,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<FluidSpringTap> createState() => _FluidSpringTapState();
}

class _FluidSpringTapState extends State<FluidSpringTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.pressScale,
  ).animate(CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOutCubic,
    reverseCurve: Curves.easeOutBack,
  ));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap != null ? (_) => _c.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _c.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _c.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Ambient glow aura around special cards (e.g. Boosted properties).
class AmbientBorderGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double borderRadius;
  final Duration duration;

  const AmbientBorderGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF00C853),
    this.borderRadius = 22.0,
    this.duration = const Duration(milliseconds: 2400),
  });

  @override
  State<AmbientBorderGlow> createState() => _AmbientBorderGlowState();
}

class _AmbientBorderGlowState extends State<AmbientBorderGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

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
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final opacity = 0.12 + 0.22 * t;
        final blur = 8.0 + 8.0 * t;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: opacity),
                blurRadius: blur,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}