import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/buyer_home_controller.dart';
import '../models/property_model_story.dart';
import 'explore_map_screen.dart' show ExproleName;
import 'widgets/story_lead_sheet.dart';

enum _SlideType { image, gradient, video }

class _Slide {
  final _SlideType type;
  final String url;
  final int startSec;
  final int durSec;
  final int part;
  final int parts;

  const _Slide.image(this.url)
      : type = _SlideType.image,
        startSec = 0,
        durSec = 5,
        part = 1,
        parts = 1;

  const _Slide.gradient()
      : type = _SlideType.gradient,
        url = '',
        startSec = 0,
        durSec = 5,
        part = 1,
        parts = 1;

  const _Slide.video(
      {required this.startSec,
        required this.durSec,
        required this.part,
        required this.parts})
      : type = _SlideType.video,
        url = '';

  bool get isVideo => type == _SlideType.video;
}

/// WhatsApp-status style fullscreen viewer for Property Stories.
/// Slides: images (5s each) → video in 30s parts. Hold = pause, tap L/R = prev/next.
class PropertyStoryScreen extends StatefulWidget {
  final List<PropertyStoryModel> stories;
  final int initialIndex;
  final BuyerHomeController controller;

  const PropertyStoryScreen({
    super.key,
    required this.stories,
    required this.controller,
    this.initialIndex = 0,
  });

  @override
  State<PropertyStoryScreen> createState() => _PropertyStoryScreenState();
}

class _PropertyStoryScreenState extends State<PropertyStoryScreen>
    with SingleTickerProviderStateMixin {
  static const int _imageSeconds = 5;
  static const int _videoPartSeconds = 30;
  static const Color _green = Color(0xFF007A5E);
  static const Color _neon = Color(0xFF2ECC71);

  late int _si;
  int _ci = 0;
  List<_Slide> _slides = [];

  late final AnimationController _imgCtrl;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  VideoPlayerController? _video;
  bool _videoReady = false;

  int _gen = 0;
  int _svcGen = 0;
  bool _advancing = false;

  bool _holding = false;
  bool _sheetOpen = false;

  PropertyStoryModel get _story => widget.stories[_si];
  _Slide get _cur => _slides[_ci];
  bool get _paused => _holding || _sheetOpen;

  @override
  void initState() {
    super.initState();
    _si = widget.initialIndex.clamp(0, widget.stories.length - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _imgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _imageSeconds),
    )
      ..addListener(() {
        if (_slides.isNotEmpty && !_cur.isVideo) _progress.value = _imgCtrl.value;
      })
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed && _slides.isNotEmpty && !_cur.isVideo) {
          _next();
        }
      });

    // load after first frame (precacheImage needs a ready context)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStory();
    });
  }

  @override
  void dispose() {
    _gen++;
    _svcGen++;
    _imgCtrl.dispose();
    _progress.dispose();
    final v = _video;
    _video = null;
    v?.removeListener(_onVideoTick);
    v?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ───────────── load / slides ─────────────

  void _loadStory() {
    final svc = ++_svcGen;
    _imgCtrl.stop();
    _disposeVideo();
    final seenId = _story.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => PropertyStoryModel.seen.add(seenId));

    final s = _story;
    final hasVideo = (s.videoUrl ?? '').trim().isNotEmpty;
    _slides = [
      for (final u in s.images) _Slide.image(u),
      // promo / no media → two gradient "container" slides
      if (s.images.isEmpty && !hasVideo) ...const [_Slide.gradient(), _Slide.gradient()],
      if (hasVideo)
        const _Slide.video(
            startSec: 0, durSec: _videoPartSeconds, part: 1, parts: 1),
    ];
    _ci = 0;
    _progress.value = 0;
    if (mounted) setState(() {});

    if (hasVideo) _initVideo(svc);
    _startSlide();
  }

  void _disposeVideo() {
    final v = _video;
    _video = null;
    _videoReady = false;
    v?.removeListener(_onVideoTick);
    v?.dispose();
  }

  Future<void> _initVideo(int svc) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(_story.videoUrl!.trim()));
    try {
      await c.initialize();
    } catch (_) {
      await c.dispose();
      if (!mounted || svc != _svcGen) return;
      final wasOnVideo = _slides.isNotEmpty && _cur.isVideo;
      _slides.removeWhere((e) => e.isVideo);
      if (_slides.isEmpty) _slides = [const _Slide.gradient()];
      if (wasOnVideo) {
        _ci = math.min(_ci, _slides.length - 1);
        _next();
      } else {
        setState(() {});
      }
      return;
    }
    if (!mounted || svc != _svcGen) {
      await c.dispose();
      return;
    }

    c.setLooping(false);
    c.setVolume(1.0);
    final total = math.max(1, (c.value.duration.inMilliseconds / 1000).ceil());
    final parts = (total / _videoPartSeconds).ceil();
    final vSlides = [
      for (int i = 0; i < parts; i++)
        _Slide.video(
          startSec: i * _videoPartSeconds,
          durSec: math.min(_videoPartSeconds, total - i * _videoPartSeconds),
          part: i + 1,
          parts: parts,
        ),
    ];
    final first = _slides.indexWhere((e) => e.isVideo);
    if (first < 0) {
      await c.dispose();
      return;
    }
    final waiting = _ci == first;
    _video = c;
    _videoReady = true;
    _slides = [..._slides.sublist(0, first), ...vSlides];
    setState(() {});
    if (waiting) _startSlide();
  }

  // ───────────── playback ─────────────

  Future<void> _startSlide() async {
    final gen = ++_gen;
    _advancing = false;
    _imgCtrl.stop();
    _progress.value = 0;
    _video?.removeListener(_onVideoTick);
    _video?.pause();
    if (_slides.isEmpty) return;
    final sl = _cur;

    if (sl.isVideo) {
      if (!_videoReady || _video == null) {
        if (mounted) setState(() {});
        return;
      }
      final c = _video!;
      await c.seekTo(Duration(seconds: sl.startSec));
      if (!mounted || gen != _gen) return;
      c.addListener(_onVideoTick);
      if (!_paused) await c.play();
    } else {
      if (sl.type == _SlideType.image && sl.url.isNotEmpty) {
        try {
          await precacheImage(NetworkImage(sl.url), context);
        } catch (_) {}
        if (!mounted || gen != _gen) return;
      }
      _imgCtrl.forward(from: 0);
      if (_paused) _imgCtrl.stop();
    }
    if (mounted) setState(() {});
  }

  void _onVideoTick() {
    final c = _video;
    if (c == null || _slides.isEmpty || !_cur.isVideo) return;
    final sl = _cur;
    final pos = c.value.position.inMilliseconds;
    final start = sl.startSec * 1000;
    final dur = sl.durSec * 1000;
    _progress.value = ((pos - start) / dur).clamp(0.0, 1.0);
    final total = c.value.duration.inMilliseconds;
    final ended = pos >= start + dur - 80 || (total > 0 && pos >= total - 80);
    if (ended && !_advancing) {
      _advancing = true;
      _next();
    }
  }

  void _applyPause() {
    if (_paused) {
      _imgCtrl.stop();
      _video?.pause();
    } else if (_slides.isNotEmpty) {
      if (_cur.isVideo) {
        if (_videoReady) _video?.play();
      } else if (_imgCtrl.value < 1.0) {
        _imgCtrl.forward();
      }
    }
    if (mounted) setState(() {});
  }

  void _next() {
    if (!mounted) return;
    if (_ci < _slides.length - 1) {
      setState(() => _ci++);
      _startSlide();
    } else if (_si < widget.stories.length - 1) {
      setState(() => _si++);
      _loadStory();
    } else {
      _close();
    }
  }

  void _prev() {
    if (_ci > 0) {
      setState(() => _ci--);
      _startSlide();
    } else if (_si > 0) {
      setState(() => _si--);
      _loadStory();
    } else {
      _startSlide();
    }
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  // ───────────── actions ─────────────

  Future<String?> _resolveBuyerId() async {
    String? id = await StorageService.instance.buyerId;
    if (id == null || id.isEmpty) id = await StorageService.instance.userId;
    if (id == null || id.isEmpty) {
      final raw = await SecureStorageService.instance.getUserData();
      if (raw != null && raw.isNotEmpty) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          id = m['id']?.toString() ?? m['_id']?.toString() ?? m['buyerId']?.toString();
        } catch (_) {}
      }
    }
    return (id != null && id.isNotEmpty) ? id : null;
  }

  Future<void> _toggleSave() async {
    final pid = _story.propertyId;
    if (pid == null) {
      Get.snackbar('Save', 'Save option property stories par available hai.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 2));
      return;
    }
    HapticFeedback.lightImpact();
    try {
      final buyerId = await _resolveBuyerId();
      if (buyerId == null) {
        Get.snackbar('Login required', 'Please login to save properties');
        return;
      }
      await widget.controller.toggleSaveProperty(buyerId, pid);
    } catch (e) {
      debugPrint('STORY_SAVE error: $e');
    }
  }

  Future<void> _share() async {
    _sheetOpen = true;
    _applyPause();
    try {
      // ignore: deprecated_member_use
      await Share.share(_story.shareText, subject: _story.shareSubject);
    } catch (e) {
      debugPrint('STORY_SHARE error: $e');
    }
    if (!mounted) return;
    _sheetOpen = false;
    _applyPause();
  }

  Future<void> _enquire() async {
    _sheetOpen = true;
    _applyPause();
    final st = _story;
    await showStoryEnquirySheet(
      context,
      heading: 'Enquire Now - ${st.label}',
      subjectName: st.isProperty ? '${st.preTitle}${st.hlTitle}${st.postTitle}' : st.label,
      onSubmit: (name, phone) async {
        // Goes to admin email (sndcode63@gmail.com) via ServicesRepository.
        await widget.controller.submitServiceLead(
          name: name,
          phone: phone,
          serviceName: st.enquirySubject,
          actionType: 'Enquire Now',
          notes: 'Property Story enquiry\n'
              'Name: $name\nMobile: $phone\n'
              'Property: ${st.enquirySubject}',
        );
      },
    );
    if (!mounted) return;
    _sheetOpen = false;
    _applyPause();
  }

  /// Opens the property details screen (same args as the home cards).
  Future<void> _viewDetails() async {
    final json = _story.propertyJson;
    if (json == null) {
      _explore();
      return;
    }
    _sheetOpen = true; // keep story paused while details screen is open
    _applyPause();
    await Get.toNamed(AppRoutes.propertyDetails, arguments: {'property': json});
    if (!mounted) return;
    _sheetOpen = false;
    _applyPause();
  }

  void _explore() {
    Navigator.of(context).pop();
    Get.to(() => const ExproleName());
  }

  // ───────────── UI helpers ─────────────

  List<Shadow> get _sh => const [
    Shadow(color: Colors.black, blurRadius: 6),
    Shadow(color: Colors.black87, blurRadius: 14),
  ];

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _gradientBg(PropertyStoryModel s, {double iconSize = 120}) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: s.gradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Center(
      child: Icon(s.icon, size: iconSize, color: Colors.white.withValues(alpha: 0.25)),
    ),
  );

  Widget _buildMedia() {
    if (_slides.isEmpty) return const SizedBox.shrink();
    final s = _story;
    final sl = _cur;
    switch (sl.type) {
      case _SlideType.gradient:
        return SizedBox.expand(child: _gradientBg(s));
      case _SlideType.image:
        return SizedBox.expand(
          child: Image.network(
            sl.url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradientBg(s),
            loadingBuilder: (c, child, p) => p == null
                ? child
                : const Center(
                child: CircularProgressIndicator(color: _neon, strokeWidth: 2.5)),
          ),
        );
      case _SlideType.video:
        final c = _video;
        if (!_videoReady || c == null || !c.value.isInitialized) {
          return const Center(
              child: CircularProgressIndicator(color: _neon, strokeWidth: 2.5));
        }
        final size = c.value.size;
        if (c.value.aspectRatio < 1) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(c)),
            ),
          );
        }
        return Center(
          child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
        );
    }
  }

  Widget _avatar(PropertyStoryModel s) {
    return Container(
      width: 36.w,
      height: 36.w,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _neon),
      child: ClipOval(
        child: s.images.isNotEmpty
            ? Image.network(s.images.first,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => _gradientBg(s, iconSize: 18))
            : _gradientBg(s, iconSize: 18),
      ),
    );
  }

  /// Transparent box with green border (used for price + Enquire Now).
  Widget _outlineBox({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _neon, width: 1.5),
        ),
        child: child,
      ),
    );
  }

  Widget _priceBox(PropertyStoryModel s) {
    return _outlineBox(
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9.r),
              border: Border.all(color: _neon, width: 1.2),
            ),
            child: Icon(Icons.home_outlined, color: _neon, size: 17.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.price ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                      shadows: _sh),
                ),
                Text(
                  s.priceNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10.sp, color: _neon, shadows: _sh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaBox(String label, IconData icon, VoidCallback onTap) {
    return _outlineBox(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: _sh),
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18.sp),
        ],
      ),
    );
  }

  /// Plain small text (not a button): "View Details ›"
  Widget _viewText(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    shadows: _sh)),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 15.sp),
          ],
        ),
      ),
    );
  }

  Widget _specPanel(List<StorySpec> specs) {
    return Container(
      width: 132.w,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _neon.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < specs.length; i++) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Row(
                children: [
                  Icon(specs[i].icon, color: _neon, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      specs[i].text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10.5.sp, color: Colors.white, shadows: _sh),
                    ),
                  ),
                ],
              ),
            ),
            if (i != specs.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          ],
        ],
      ),
    );
  }

  Widget _saveButton() {
    final pid = _story.propertyId;
    return Obx(() {
      // Always read the observable (even when pid == null) – GetX requires it.
      final inSaved = widget.controller.savedPropertyIds.contains(pid ?? '');
      final saved = pid != null && inSaved;
      return GestureDetector(
        onTap: _toggleSave,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: saved ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: Icon(
            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: saved ? const Color(0xFFFF4D6A) : Colors.white,
            size: 27.sp,
          ),
        ),
      );
    });
  }

  // ───────────── build ─────────────

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    final s = _story;
    final sl = _cur;
    final pad = MediaQuery.of(context).padding;

    final subtitle = sl.isVideo
        ? '${_ci + 1}/${_slides.length} • Video ${_fmt(sl.startSec)}–${_fmt(sl.startSec + sl.durSec)}'
        : '${_ci + 1}/${_slides.length}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 400) _close();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(),

            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.28, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // tap zones
            Positioned.fill(
              child: Row(
                children: [
                  for (final z in const [1, 2])
                    Expanded(
                      flex: z,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: z == 1 ? _prev : _next,
                        onLongPressStart: (_) {
                          _holding = true;
                          _applyPause();
                        },
                        onLongPressEnd: (_) {
                          _holding = false;
                          _applyPause();
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),

            // centre play icon on video while paused
            if (sl.isVideo && _paused)
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 62.w,
                    height: 62.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36.sp),
                  ),
                ),
              ),

            // top: progress + header
            Positioned(
              top: pad.top + 8.h,
              left: 12.w,
              right: 12.w,
              child: Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (_, v, __) => Row(
                      children: List.generate(_slides.length, (i) {
                        final val = i < _ci ? 1.0 : (i == _ci ? v : 0.0);
                        return Expanded(
                          child: Container(
                            height: 3.h,
                            margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                            child: LinearProgressIndicator(
                              value: val,
                              minHeight: 3.h,
                              backgroundColor: Colors.white.withValues(alpha: 0.35),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _avatar(s),
                      SizedBox(width: 9.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: _sh)),
                            Text(subtitle,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5.sp,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shadows: _sh)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _close,
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 19.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // info: location chip, title, tagline
            Positioned(
              top: pad.top + 86.h,
              left: 14.w,
              right: 14.w,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.location.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004637).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: _neon.withValues(alpha: 0.55)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, color: _neon, size: 14.sp),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(s.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 12.h),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.poppins(
                            fontSize: 25.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            shadows: _sh),
                        children: [
                          TextSpan(text: s.preTitle),
                          TextSpan(text: s.hlTitle, style: const TextStyle(color: _neon)),
                          TextSpan(text: s.postTitle),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    if (s.reviewText != null && s.reviewText!.isNotEmpty)
                      Text(
                        '"${s.reviewText}"',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 1.4,
                            shadows: _sh),
                      )
                    else
                      Text(
                        s.tagline.join('  |  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.sp, color: Colors.white, shadows: _sh),
                      ),
                  ],
                ),
              ),
            ),

            // bottom: spec panel, [price | Enquire Now] row, message bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.specs.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(right: 14.w, bottom: 10.h),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _specPanel(s.specs),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                    child: Column(
                      children: [
                        if (s.price != null)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _priceBox(s)),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: _ctaBox('Enquire Now',
                                      Icons.chat_bubble_outline_rounded, _enquire),
                                ),
                              ],
                            ),
                          ),
                        _viewText(
                          s.isProperty ? 'View Details' : 'View Properties',
                          s.isProperty ? _viewDetails : _explore,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, pad.bottom + 12.h),
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _enquire,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22.r),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text('Send message...',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: Colors.white.withValues(alpha: 0.65))),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        SizedBox(width: 30.w, child: Center(child: _saveButton())), // ❤️ left of share
                        SizedBox(width: 14.w),
                        GestureDetector(
                          onTap: _share,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(Icons.send_outlined, color: Colors.white, size: 25.sp),
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
}
