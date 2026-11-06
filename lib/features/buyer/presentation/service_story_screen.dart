import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _green = Color(0xFF0B6E5F);
const Color _mint = Color(0xFF7FE0C8);
const Color _ink = Color(0xFF10222B);
const Color _seen = Color(0xFFD5DEDC);

/// One story bubble.
class StoryItem {
  final String label; // "Villa", "3 BHK", "Plot" ...
  final String? imageUrl; // network image (null -> placeholder)
  final bool isNew; // shows the green "New" pill
  final bool isVideo; // shows the play badge
  final bool seen; // grey ring when already watched
  final Object? payload; // anything you want back in onTap
  const StoryItem({
    required this.label,
    this.imageUrl,
    this.isNew = false,
    this.isVideo = true,
    this.seen = false,
    this.payload,
  });
}

/// Horizontal row of story rings (used for Property Stories and Service Stories).
///
///  * 72px photo, 3px white gap, 3px animated gradient ring
///  * unseen -> slowly rotating green/mint ring · seen -> flat grey ring
///  * "New" pill overlapping the ring, glass play badge bottom-right
///  * press-to-shrink, staggered entrance, no scroll bounce
class StoryRingsRow extends StatefulWidget {
  final List<StoryItem> items;
  final void Function(StoryItem item, int index)? onTap;
  final double size; // photo diameter (logical px before .w)
  const StoryRingsRow({super.key, required this.items, this.onTap, this.size = 72});

  @override
  State<StoryRingsRow> createState() => _StoryRingsRowState();
}

class _StoryRingsRowState extends State<StoryRingsRow> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
  AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  final Set<int> _viewed = {};

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size.w;
    return SizedBox(
      height: d + 14.w + 8.h + 16.h + 8.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        itemCount: widget.items.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (context, i) {
          final it = widget.items[i];
          final seen = it.seen || _viewed.contains(i);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 420 + i * 80),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
            ),
            child: _StoryBubble(
              item: it,
              seen: seen,
              diameter: d,
              spin: _spin,
              onTap: () {
                setState(() => _viewed.add(i));
                widget.onTap?.call(it, i);
              },
            ),
          );
        },
      ),
    );
  }
}

class _StoryBubble extends StatefulWidget {
  final StoryItem item;
  final bool seen;
  final double diameter;
  final Animation<double> spin;
  final VoidCallback onTap;
  const _StoryBubble({
    required this.item,
    required this.seen,
    required this.diameter,
    required this.spin,
    required this.onTap,
  });

  @override
  State<_StoryBubble> createState() => _StoryBubbleState();
}

class _StoryBubbleState extends State<_StoryBubble> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final d = widget.diameter;
    final ring = 3.w;
    final gap = 3.w;
    final outer = d + (ring + gap) * 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.93 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: outer + 6.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // animated gradient ring
                  AnimatedBuilder(
                    animation: widget.spin,
                    builder: (context, _) => Container(
                      width: outer,
                      height: outer,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.seen
                            ? null
                            : SweepGradient(
                          colors: const [_green, _mint, Color(0xFFB8F0DF), _mint, _green],
                          transform: GradientRotation(widget.spin.value * 2 * math.pi),
                        ),
                        color: widget.seen ? _seen : null,
                        boxShadow: widget.seen
                            ? null
                            : [
                          BoxShadow(
                            color: _green.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // white gap
                  Container(
                    width: outer - ring * 2,
                    height: outer - ring * 2,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  // photo
                  ClipOval(
                    child: SizedBox(
                      width: d,
                      height: d,
                      child: _photo(it.imageUrl),
                    ),
                  ),
                  // soft bottom shade so the badge always reads
                  if (it.isVideo)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipOval(
                          child: Padding(
                            padding: EdgeInsets.all(ring + gap),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    _ink.withValues(alpha: 0.28),
                                  ],
                                  stops: const [0.55, 1],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (it.isVideo)
                    Positioned(
                      right: 2.w,
                      bottom: 4.w,
                      child: Container(
                        width: 22.w,
                        height: 22.w,
                        decoration: BoxDecoration(
                          color: _ink.withValues(alpha: 0.78),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.6),
                        ),
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14.sp),
                      ),
                    ),
                  if (it.isNew)
                    Positioned(
                      top: -6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.6),
                          boxShadow: [
                            BoxShadow(
                              color: _green.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'New',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                it.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.sp,
                  fontWeight: widget.seen ? FontWeight.w500 : FontWeight.w700,
                  color: widget.seen ? const Color(0xFF5E7076) : _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photo(String? url) {
    final placeholder = Container(
      color: const Color(0xFFE3F1ED),
      child: Icon(Icons.home_work_rounded, color: _green.withValues(alpha: 0.5), size: 26.sp),
    );
    if (url == null || url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (c, child, p) => p == null ? child : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}