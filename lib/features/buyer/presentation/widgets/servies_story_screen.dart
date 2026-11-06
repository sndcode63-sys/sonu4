import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../controllers/buyer_home_controller.dart';
import '../../models/cms_service_model.dart';


/// One "page" of a story (WhatsApp-status style).
/// - image  : shown for [ServiceStoryScreen] image duration (5s)
/// - video  : a 30s slice of the service video (last slice can be shorter)
class _StoryItem {
  final bool isVideo;
  final String imageUrl;
  final int startSec;
  final int durSec;
  final int part;
  final int parts;

  const _StoryItem.image(this.imageUrl)
      : isVideo = false,
        startSec = 0,
        durSec = 5,
        part = 1,
        parts = 1;

  const _StoryItem.video({
    required this.startSec,
    required this.durSec,
    required this.part,
    required this.parts,
  })  : isVideo = true,
        imageUrl = '';
}

class ServiceStoryScreen extends StatefulWidget {
  final List<CmsServiceModel> services;
  final int initialIndex;

  const ServiceStoryScreen({
    super.key,
    required this.services,
    this.initialIndex = 0,
  });

  @override
  State<ServiceStoryScreen> createState() => _ServiceStoryScreenState();
}

class _ServiceStoryScreenState extends State<ServiceStoryScreen>
    with SingleTickerProviderStateMixin {
  static const int _imageSeconds = 5;
  static const int _videoPartSeconds = 30;
  static const Color _green = Color(0xFF007A5E);
  static const Color _brightGreen = Color(0xFF2ECC71);

  /// Action label sent with the lead (goes to admin email).
  static const String _enquiryAction = 'Enquire Now';

  late int _si; // current service index
  int _ci = 0; // current item index inside the service
  List<_StoryItem> _items = [];

  late final AnimationController _imgCtrl;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  VideoPlayerController? _video;
  bool _videoReady = false;

  int _gen = 0; // token for current item
  int _svcGen = 0; // token for current service
  bool _advancing = false;

  bool _holding = false;
  bool _detailsOpen = false;
  bool _sheetOpen = false;
  bool _submittingLead = false;

  final BuyerHomeController _homeController =
  Get.isRegistered<BuyerHomeController>()
      ? Get.find<BuyerHomeController>()
      : Get.put(BuyerHomeController());

  bool get _paused => _holding || _detailsOpen || _sheetOpen;
  CmsServiceModel get _service => widget.services[_si];
  _StoryItem get _cur => _items[_ci];

  @override
  void initState() {
    super.initState();
    _si = widget.initialIndex.clamp(0, widget.services.length - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _imgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _imageSeconds),
    )
      ..addListener(() {
        if (_items.isNotEmpty && !_cur.isVideo) {
          _progress.value = _imgCtrl.value;
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _items.isNotEmpty &&
            !_cur.isVideo) {
          _next();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadService();
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

  // ───────────────────────── Loading / items ─────────────────────────

  List<String> _imagesOf(CmsServiceModel s) {
    if (s.imageTags.isNotEmpty) return s.imageTags;
    if (s.heroImage.isNotEmpty) return [s.heroImage];
    return const [];
  }

  void _loadService() {
    final svc = ++_svcGen;
    _imgCtrl.stop();
    _disposeVideo();

    final s = _service;
    final imgs = _imagesOf(s);
    final hasVideo = (s.videoUrl ?? '').trim().isNotEmpty;

    _items = [
      for (final u in imgs) _StoryItem.image(u),
      // Placeholder – replaced by real 30s parts once duration is known.
      if (hasVideo)
        const _StoryItem.video(
            startSec: 0, durSec: _videoPartSeconds, part: 1, parts: 1),
    ];
    if (_items.isEmpty) _items = [const _StoryItem.image('')];

    _ci = 0;
    _progress.value = 0;
    if (mounted) setState(() {});

    if (hasVideo) _initVideo(svc);
    _startItem();
  }

  void _disposeVideo() {
    final v = _video;
    _video = null;
    _videoReady = false;
    v?.removeListener(_onVideoTick);
    v?.dispose();
  }

  Future<void> _initVideo(int svc) async {
    final url = _service.videoUrl!.trim();
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
    } catch (_) {
      await c.dispose();
      if (!mounted || svc != _svcGen) return;
      // Video failed – drop it from the story.
      final wasOnVideo = _items.isNotEmpty && _cur.isVideo;
      _items.removeWhere((e) => e.isVideo);
      if (wasOnVideo || _items.isEmpty) {
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

    final totalSec =
    math.max(1, (c.value.duration.inMilliseconds / 1000).ceil());
    final parts = (totalSec / _videoPartSeconds).ceil();
    final vItems = [
      for (int i = 0; i < parts; i++)
        _StoryItem.video(
          startSec: i * _videoPartSeconds,
          durSec: math.min(_videoPartSeconds, totalSec - i * _videoPartSeconds),
          part: i + 1,
          parts: parts,
        ),
    ];

    final firstVideo = _items.indexWhere((e) => e.isVideo);
    if (firstVideo < 0) {
      await c.dispose();
      return;
    }
    final waitingOnVideo = _ci == firstVideo;

    _video = c;
    _videoReady = true;
    _items = [..._items.sublist(0, firstVideo), ...vItems];
    setState(() {});

    if (waitingOnVideo) _startItem();
  }

  // ───────────────────────── Playback ─────────────────────────

  Future<void> _startItem() async {
    final gen = ++_gen;
    _advancing = false;
    _imgCtrl.stop();
    _progress.value = 0;
    _video?.removeListener(_onVideoTick);
    _video?.pause();

    if (_items.isEmpty) return;
    final it = _cur;

    if (it.isVideo) {
      if (!_videoReady || _video == null) {
        if (mounted) setState(() {}); // loader; _initVideo will call us again
        return;
      }
      final c = _video!;
      await c.seekTo(Duration(seconds: it.startSec));
      if (!mounted || gen != _gen) return;
      c.addListener(_onVideoTick);
      if (!_paused) await c.play();
    } else {
      if (it.imageUrl.isNotEmpty) {
        try {
          await precacheImage(NetworkImage(it.imageUrl), context);
        } catch (_) {}
        if (!mounted || gen != _gen) return;
      }
      _imgCtrl.duration = const Duration(seconds: _imageSeconds);
      _imgCtrl.forward(from: 0);
      if (_paused) _imgCtrl.stop();
    }
    if (mounted) setState(() {});
  }

  void _onVideoTick() {
    final c = _video;
    if (c == null || _items.isEmpty || !_cur.isVideo) return;
    final it = _cur;
    final posMs = c.value.position.inMilliseconds;
    final startMs = it.startSec * 1000;
    final durMs = it.durSec * 1000;

    _progress.value = ((posMs - startMs) / durMs).clamp(0.0, 1.0);

    final totalMs = c.value.duration.inMilliseconds;
    final ended = posMs >= startMs + durMs - 80 ||
        (totalMs > 0 && posMs >= totalMs - 80);
    if (ended && !_advancing) {
      _advancing = true;
      _next();
    }
  }

  void _applyPause() {
    if (_paused) {
      _imgCtrl.stop();
      _video?.pause();
    } else {
      if (_items.isEmpty) return;
      if (_cur.isVideo) {
        if (_videoReady) _video?.play();
      } else if (_imgCtrl.value < 1.0) {
        _imgCtrl.forward();
      }
    }
  }

  void _next() {
    if (!mounted) return;
    if (_ci < _items.length - 1) {
      setState(() => _ci++);
      _startItem();
    } else if (_si < widget.services.length - 1) {
      setState(() {
        _si++;
        _detailsOpen = false;
      });
      _loadService();
    } else {
      _closeScreen();
    }
  }

  void _prev() {
    if (_ci > 0) {
      setState(() => _ci--);
      _startItem();
    } else if (_si > 0) {
      setState(() {
        _si--;
        _detailsOpen = false;
      });
      _loadService();
    } else {
      _startItem(); // restart first item
    }
  }

  void _closeScreen() {
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleDetails() {
    setState(() => _detailsOpen = !_detailsOpen);
    _applyPause();
  }

  // ───────────────────────── Helpers / UI ─────────────────────────

  String _fmt(int sec) =>
      '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';

  String _subtitle() {
    if (_items.isEmpty) return '';
    final it = _cur;
    if (it.isVideo) {
      return 'Video • ${_fmt(it.startSec)} – ${_fmt(it.startSec + it.durSec)}'
          ' • Part ${it.part}/${it.parts}';
    }
    final imgCount = _items.where((e) => !e.isVideo).length;
    return 'Photo ${_ci + 1}/$imgCount';
  }

  Widget _buildServiceIconWidget(String icon, {double size = 24}) {
    IconData iconData;
    switch (icon.toLowerCase()) {
      case 'shield':
      case 'insurance':
      case 'health':
        iconData = Icons.health_and_safety_rounded;
        break;
      case 'home':
      case 'loan':
      case 'homeloan':
        iconData = Icons.home_work_rounded;
        break;
      case 'currency':
      case 'money':
      case 'personalloan':
        iconData = Icons.account_balance_wallet_rounded;
        break;
      case 'utility':
      case 'electric':
      case 'solar':
        iconData = Icons.bolt_rounded;
        break;
      default:
        iconData = Icons.campaign_rounded;
    }

    return Container(
      width: size * 1.6,
      height: size * 1.6,
      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
      child: Center(child: Icon(iconData, color: Colors.white, size: size)),
    );
  }

  Widget _buildMedia() {
    if (_items.isEmpty) return const SizedBox.shrink();
    final it = _cur;

    if (it.isVideo) {
      final c = _video;
      if (!_videoReady || c == null || !c.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: _brightGreen, strokeWidth: 2.5),
        );
      }
      final size = c.value.size;
      final portrait = c.value.aspectRatio < 1;
      if (portrait) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(c),
            ),
          ),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
      );
    }

    if (it.imageUrl.isEmpty) return Container(color: const Color(0xFF173247));
    return SizedBox.expand(
      child: Image.network(
        it.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF173247)),
        loadingBuilder: (ctx, child, p) => p == null
            ? child
            : const Center(
          child: CircularProgressIndicator(
              color: _brightGreen, strokeWidth: 2.5),
        ),
      ),
    );
  }

  List<Shadow> get _textShadow => const [
    Shadow(color: Colors.black, blurRadius: 6),
    Shadow(color: Colors.black87, blurRadius: 14),
  ];

  Widget _pillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: filled ? _green : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: _brightGreen, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Transparent details container: no fill, white text, green borders.
  Widget _buildDetailsPanel(CmsServiceModel s) {
    final maxH = MediaQuery.of(context).size.height * 0.42;
    final desc = s.description.isNotEmpty ? s.description : s.shortDescription;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // don't let taps fall to next/prev zones
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxH),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _brightGreen, width: 1.5),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: _brightGreen, width: 1.2),
                ),
                child: Text(
                  s.title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    shadows: _textShadow,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                s.heading.isNotEmpty ? s.heading : s.title,
                style: GoogleFonts.poppins(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                  shadows: _textShadow,
                ),
              ),
              if (desc.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.white,
                    height: 1.45,
                    shadows: _textShadow,
                  ),
                ),
              ],
              if (s.features.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: s.features.map((f) {
                    return Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: _brightGreen, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: _brightGreen),
                          SizedBox(width: 4.w),
                          Text(
                            f,
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: _textShadow,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (s.benefits.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  'Benefits',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: _textShadow,
                  ),
                ),
                SizedBox(height: 4.h),
                ...s.benefits.map(
                      (b) => Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 14, color: _brightGreen),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            b,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5.sp,
                              color: Colors.white,
                              height: 1.35,
                              shadows: _textShadow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Lead (Enquire Now) ─────────────────────────

  Future<void> _openLeadBottomSheet() async {
    setState(() => _sheetOpen = true);
    _applyPause();

    String prefilledName = '';
    String prefilledPhone = '';

    try {
      prefilledName = (await StorageService.instance.name)?.trim() ?? '';
      prefilledPhone = (await StorageService.instance.phone)?.trim() ?? '';

      if (prefilledName.isEmpty || prefilledPhone.isEmpty) {
        final userDataStr = await SecureStorageService.instance.getUserData();
        if (userDataStr != null && userDataStr.isNotEmpty) {
          try {
            final Map<String, dynamic> map = jsonDecode(userDataStr);
            if (prefilledName.isEmpty && map['name'] != null) {
              prefilledName = map['name'].toString().trim();
            }
            if (prefilledPhone.isEmpty && map['phone'] != null) {
              prefilledPhone = map['phone'].toString().trim();
            }
          } catch (_) {}
        }
        if (prefilledName.isEmpty) {
          final u = Get.find<BuyerHomeController>().dashboardHeader.value?.user;
          if (u?.name != null) prefilledName = u!.name!;
        }
      }
    } catch (_) {}

    final nameController = TextEditingController(text: prefilledName);
    final phoneController = TextEditingController(text: prefilledPhone);
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey),
      prefixIcon: Icon(icon, color: _green),
      filled: true,
      fillColor: const Color(0xFFF7F9FA),
      contentPadding:
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
    );

    final service = _service;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
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
                        width: 48.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        _buildServiceIconWidget(service.icon, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_enquiryAction - ${service.title}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF173247),
                                ),
                              ),
                              Text(
                                'Our verified advisor will call you to assist.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Your Name',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF173247),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: nameController,
                      decoration: deco('Enter your full name',
                          Icons.person_outline_rounded),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Mobile Number',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF173247),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: deco('Enter 10-digit mobile number',
                          Icons.phone_outlined),
                      validator: (val) {
                        if (val == null || val.trim().length < 10) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _submittingLead
                            ? null
                            : () async {
                          if (!(formKey.currentState?.validate() ??
                              false)) {
                            return;
                          }
                          setModalState(() => _submittingLead = true);

                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();

                          try {
                            // Sends name + mobile + service to admin
                            // email (sndcode63@gmail.com).
                            await _homeController.submitServiceLead(
                              name: name,
                              phone: phone,
                              serviceName: service.title,
                              actionType: _enquiryAction,
                            );
                          } finally {
                            _submittingLead = false;
                          }

                          if (mounted && ctx.mounted) {
                            Navigator.of(ctx).pop();
                            _showSuccessDialog(name, service.title);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: _submittingLead
                            ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                color: Colors.white, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Submit Request',
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

    nameController.dispose();
    phoneController.dispose();
    if (!mounted) return;
    setState(() => _sheetOpen = false);
    _applyPause();
  }

  void _showSuccessDialog(String name, String service) {
    _sheetOpen = true; // keep story paused while dialog is visible
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _green, size: 38),
              ),
              SizedBox(height: 16.h),
              Text(
                'Request Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF173247),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Thank you $name. Your enquiry for "$service" has been received. Our team will contact you shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Great, thanks!',
                    style: GoogleFonts.poppins(
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
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() => _sheetOpen = false);
      _applyPause();
    });
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const Scaffold(backgroundColor: Colors.black);

    final service = _service;
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 400) _closeScreen(); // swipe down
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Media (image / video) – fully fullscreen
            _buildMedia(),

            // 2. Readability gradient
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.2, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Tap zones: left = previous, right = next, hold = pause
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _prev,
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
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _next,
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

            // 4. Progress bars + header
            Positioned(
              top: pad.top + 8.h,
              left: 12.w,
              right: 12.w,
              child: Column(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (_, value, __) {
                      return Row(
                        children: List.generate(_items.length, (i) {
                          final v = i < _ci ? 1.0 : (i == _ci ? value : 0.0);
                          return Expanded(
                            child: Container(
                              height: 3.h,
                              margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                              child: LinearProgressIndicator(
                                value: v,
                                backgroundColor:
                                Colors.white.withValues(alpha: 0.35),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                minHeight: 3.h,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _buildServiceIconWidget(service.icon, size: 18),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: _textShadow,
                              ),
                            ),
                            Text(
                              _subtitle(),
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                                shadows: _textShadow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 26),
                        onPressed: _closeScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 5. Bottom: details panel + two small buttons
            Positioned(
              left: 14.w,
              right: 14.w,
              bottom: pad.bottom + 14.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _detailsOpen
                        ? Padding(
                      key: const ValueKey('details'),
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _buildDetailsPanel(service),
                    )
                        : const SizedBox.shrink(key: ValueKey('none')),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pillButton(
                        label: 'Enquire Now',
                        icon: Icons.chat_bubble_outline_rounded,
                        filled: true,
                        onTap: _openLeadBottomSheet,
                      ),
                      SizedBox(width: 10.w),
                      _pillButton(
                        label: _detailsOpen ? 'Close' : 'Details',
                        icon: _detailsOpen
                            ? Icons.close_rounded
                            : Icons.info_outline_rounded,
                        onTap: _toggleDetails,
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
