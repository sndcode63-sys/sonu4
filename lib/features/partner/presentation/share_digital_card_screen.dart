import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/partner_home_controller.dart';
import 'widgets/digital_card_views.dart';

import 'widgets/partner_ui.dart';
// ================================================================
// DESIGN TOKENS
// ================================================================
const Color _primaryTeal = Color(0xFF0A5C4A);
const Color _darkTeal = Color(0xFF063B30);
const Color _ink = Color(0xFF0B1B2E);
const Color _muted = Color(0xFF5B6B7C);
const Color _mint = Color(0xFF9BE5CF);
const Color _softBg = Color(0xFFF6F8FA);
const Color _border = Color(0xFFE3E8ED);

class ShareDigitalCardScreen extends StatefulWidget {
  const ShareDigitalCardScreen({super.key});

  @override
  State<ShareDigitalCardScreen> createState() => _ShareDigitalCardScreenState();
}

class _ShareDigitalCardScreenState extends State<ShareDigitalCardScreen> {
  late final PartnerHomeController c;
  final ScreenshotController _screenshotController = ScreenshotController();

  // Active editable card data
  late PartnerCardData _cardData;
  bool _isCustomized = false;

  // Selected design index: 0 to 7
  int _selectedDesignIndex = 0;
  bool _isExporting = false;

  // Card styles meta for selector
  static const List<Map<String, dynamic>> _cardStyles = [
    {
      'title': '1. Classic Emerald',
      'subtitle': 'Vertical Portrait • WhatsApp Story & Status Ready',
      'badge': 'Vertical',
      'badgeColor': Color(0xFF129B6C),
      'color': Color(0xFF0A5C4A),
      'tag': 'Emerald',
    },
    {
      'title': '2. Royal Dark Luxury',
      'subtitle': 'Horizontal Landscape • Dark Emerald & Gold Luxury',
      'badge': 'Luxury Dark',
      'badgeColor': Color(0xFFD9961F),
      'color': Color(0xFF092921),
      'tag': 'Royal Dark',
    },
    {
      'title': '3. Corporate Minimal',
      'subtitle': 'Horizontal Landscape • Crisp Clean White & Slate',
      'badge': 'Minimal Light',
      'badgeColor': Color(0xFF0A5C4A),
      'color': Color(0xFFEEF2F5),
      'tag': 'Minimal',
    },
    {
      'title': '4. Midnight Gold Executive',
      'subtitle': 'Horizontal Landscape • Obsidian Black & Gold Foil Accent',
      'badge': 'Executive Gold',
      'badgeColor': Color(0xFFD4AF37),
      'color': Color(0xFF141416),
      'tag': 'Gold VIP',
    },
    {
      'title': '5. Sapphire Blue Elite',
      'subtitle': 'Vertical Portrait • Royal Blue & Modern Platinum',
      'badge': 'Sapphire Elite',
      'badgeColor': Color(0xFF2457A6),
      'color': Color(0xFF1D4ED8),
      'tag': 'Sapphire',
    },
    {
      'title': '6. Sunset Amber Prestige',
      'subtitle': 'Horizontal Landscape • Warm Amber Gold & Bronze Glow',
      'badge': 'Sunset Amber',
      'badgeColor': Color(0xFFEA580C),
      'color': Color(0xFF9A3412),
      'tag': 'Sunset',
    },
    {
      'title': '7. Slate Titanium Ultra',
      'subtitle': 'Horizontal Landscape • Architectural Slate & Neon Teal',
      'badge': 'Titanium Tech',
      'badgeColor': Color(0xFF06B6D4),
      'color': Color(0xFF1E293B),
      'tag': 'Titanium',
    },
    {
      'title': '8. Royal Ivory & Forest',
      'subtitle': 'Vertical Portrait • Classic Matte Ivory & Forest Green',
      'badge': 'Royal Ivory',
      'badgeColor': Color(0xFF15803D),
      'color': Color(0xFFFAF7F2),
      'tag': 'Ivory',
    },
  ];

  @override
  void initState() {
    super.initState();
    c = ensurePartnerHomeController();
    _cardData = PartnerCardData.fromController(c);
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _softBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, topPad + 12.h, 16.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top App Bar
                  _buildHeader(context),
                  SizedBox(height: 16.h),

                  // Header Titles
                  Text(
                    'Share Your Digital Card',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Customise contact info, choose among 8 luxury styles, and download or share instantly.',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: _muted,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // HORIZONTAL QUICK STYLE SELECTOR STRIP (8 CARDS)
                  _buildStyleHorizontalStrip(),
                  SizedBox(height: 14.h),

                  // EDIT CARD DETAILS QUICK BAR
                  _buildEditInfoQuickBar(),
                  SizedBox(height: 14.h),

                  // LIVE CARD VIEWPORT (WRAPPED FOR SCREENSHOT CAPTURE)
                  Center(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey('card_design_$_selectedDesignIndex'),
                          child: DigitalCardRenderer(
                            data: _cardData,
                            designIndex: _selectedDesignIndex,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // CHOOSE HOW YOU WANT TO SHARE
                  Text(
                    'Choose how you want to share',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Quick Action Social Circles
                  _buildQuickShareRow(),
                  SizedBox(height: 20.h),

                  // PRIMARY DOWNLOAD BUTTON (DIRECT SAVE TO DEVICE STORAGE)
                  _buildDownloadButton(),
                  SizedBox(height: 16.h),

                  // OPTIONS TILES
                  _buildOptionTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Edit Card Details',
                    subtitle: 'Modify Phone, WhatsApp Number, Address or Firm Name',
                    trailingBadge: _isCustomized ? 'Customized' : null,
                    onTap: _openEditDetailsModal,
                  ),
                  SizedBox(height: 8.h),
                  _buildOptionTile(
                    icon: Icons.palette_outlined,
                    title: 'Modify Card Design (8 Styles)',
                    subtitle: 'Switch between 8 Vertical & Horizontal designer layouts',
                    onTap: _openDesignSelectorModal,
                  ),
                  SizedBox(height: 8.h),
                  _buildOptionTile(
                    icon: Icons.image_outlined,
                    title: 'Share as Image',
                    subtitle: 'Send high-res photo attachment directly to any app',
                    onTap: _shareCardAsImage,
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay during image capture
          if (_isExporting)
            Container(
              color: PartnerColors.textTertiary,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
                  decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(color: _primaryTeal, strokeWidth: 2.5),
                      ),
                      SizedBox(width: 14.w),
                      Text(
                        'Generating High-Res Card...',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
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

  // ================================================================
  // TOP APP BAR
  // ================================================================
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20.sp, color: _ink),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _openEditDetailsModal,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: _primaryTeal),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 12.sp, color: _primaryTeal),
                    SizedBox(width: 4.w),
                    Text(
                      'Edit Info',
                      style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: _primaryTeal),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EF),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _mint),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 13.sp, color: _primaryTeal),
                  SizedBox(width: 4.w),
                  Text(
                    'Partner Verified',
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: _primaryTeal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // HORIZONTAL QUICK STYLE SELECTOR STRIP (ALL 8 CARDS)
  // ================================================================
  Widget _buildStyleHorizontalStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Card Styles (8 Options)',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            GestureDetector(
              onTap: _openDesignSelectorModal,
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: _primaryTeal,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 38.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: _cardStyles.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final style = _cardStyles[index];
              final isSelected = _selectedDesignIndex == index;
              final Color badgeColor = style['badgeColor'] as Color;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDesignIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryTeal : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? _primaryTeal : _border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _primaryTeal.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '#${index + 1} ${style['tag']}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EDIT CARD INFO QUICK BAR
  // ================================================================
  Widget _buildEditInfoQuickBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(Icons.contact_phone_outlined, size: 16.sp, color: _primaryTeal),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Call: ${_cardData.phone} • WA: ${_cardData.whatsapp}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: _openEditDetailsModal,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 11.sp, color: _primaryTeal),
                  SizedBox(width: 3.w),
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: _primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK SHARE SOCIAL ICONS ROW
  // ================================================================
  Widget _buildQuickShareRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSocialItem(
          icon: Icons.chat_rounded,
          color: const Color(0xFF25D366),
          label: 'WhatsApp',
          onTap: _shareToWhatsApp,
        ),
        _buildSocialItem(
          icon: Icons.facebook_rounded,
          color: const Color(0xFF1877F2),
          label: 'Facebook',
          onTap: _shareToFacebook,
        ),
        _buildSocialItem(
          icon: Icons.link_rounded,
          color: _primaryTeal,
          label: 'Copy Link',
          onTap: _copyProfileLink,
        ),
        _buildSocialItem(
          icon: Icons.more_horiz_rounded,
          color: const Color(0xFF4B5B6C),
          label: 'More',
          onTap: _openShareSheetModal,
        ),
      ],
    );
  }

  Widget _buildSocialItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 7.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PRIMARY DOWNLOAD CARD BUTTON (DIRECT TO STORAGE)
  // ================================================================
  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _downloadCard,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: _darkTeal,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _darkTeal.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, color: Colors.white, size: 19.sp),
            SizedBox(width: 8.w),
            Text(
              'Download Card (Direct to Device)',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // OPTION TILE LIST ITEM
  // ================================================================
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: _primaryTeal, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (trailingBadge != null) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF129B6C).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            trailingBadge,
                            style: TextStyle(
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF129B6C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10.sp, color: _muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _muted, size: 20.sp),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ACTIONS: CAPTURE & DIRECT DOWNLOAD TO DEVICE
  // ================================================================
  Future<File?> _captureCardImage() async {
    setState(() => _isExporting = true);
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) return null;

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/diginiwas_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      Get.snackbar(
        'Capture Notice',
        'Unable to render card image: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  static const MethodChannel _mediaChannel = MethodChannel('com.example.diginiwas/media_saver');

  Future<void> _downloadCard() async {
    setState(() => _isExporting = true);
    try {
      final imageBytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (imageBytes == null) {
        Get.snackbar('Download Error', 'Could not render high-res image.', backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'DigiNiwas_Card_${_cardData.partnerCode}_$timestamp.png';

      String? savedUri;
      File? tempFile;

      // 1. Write to local temp file (always available for preview / share)
      try {
        final tempDir = Directory.systemTemp;
        tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(imageBytes);
      } catch (_) {}

      // 2. Real Save to Device Gallery via Native MediaStore (Android)
      if (Platform.isAndroid) {
        try {
          savedUri = await _mediaChannel.invokeMethod<String>(
            'saveImageToGallery',
            {
              'imageBytes': imageBytes,
              'fileName': fileName,
              'albumName': 'DigiNiwas',
            },
          );
        } catch (e) {
          debugPrint('MediaStore save error: $e');
        }
      }

      // 3. Fallback: Save to public Downloads directory if MediaStore was not reached
      if (savedUri == null) {
        try {
          Directory? targetDir;
          if (Platform.isAndroid) {
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (downloadDir.existsSync()) {
              targetDir = downloadDir;
            } else {
              targetDir = await getExternalStorageDirectory();
            }
          }
          targetDir ??= await getApplicationDocumentsDirectory();
          final file = File('${targetDir.path}/$fileName');
          await file.writeAsBytes(imageBytes);
          savedUri = file.path;
        } catch (e) {
          debugPrint('Fallback storage write error: $e');
        }
      }

      HapticFeedback.heavyImpact();

      // Show real confirmation bottom sheet with "View in Gallery" action
      _showDownloadSuccessSheet(savedUri: savedUri, tempFile: tempFile ?? File(savedUri ?? ''));

    } catch (e) {
      Get.snackbar(
        'Download Notice',
        'Could not save card: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showDownloadSuccessSheet({required String? savedUri, required File tempFile}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 30.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: 56.w,
                height: 56.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F3EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: _primaryTeal, size: 36.sp),
              ),
              SizedBox(height: 14.h),
              Text(
                'Downloaded to Gallery!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Aapka digital visiting card phone ki Gallery / Photos app me "DigiNiwas" album me save ho chuka hai.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5.sp, color: _muted, height: 1.4),
              ),
              SizedBox(height: 20.h),
              if (savedUri != null && Platform.isAndroid) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryTeal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    onPressed: () async {
                      Get.back();
                      try {
                        await _mediaChannel.invokeMethod('openImageInGallery', {'uri': savedUri});
                      } catch (_) {
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(tempFile.path)],
                            text: '${_cardData.name} - DigiNiwas Partner Card',
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_rounded, color: Colors.white, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'View in Gallery / Photos',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => Get.back(),
                      child: Text('Done', style: TextStyle(color: _ink, fontSize: 12.5.sp, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primaryTeal),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () async {
                        Get.back();
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(tempFile.path)],
                            text: '${_cardData.name} - DigiNiwas Partner Visiting Card',
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, size: 14.sp, color: _primaryTeal),
                          SizedBox(width: 4.w),
                          Text('Share Card', style: TextStyle(color: _primaryTeal, fontSize: 12.sp, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // SHARING FLOWS
  // ================================================================
  Future<void> _shareToWhatsApp() async {
    final file = await _captureCardImage();
    if (file == null) return;

    final caption =
        'Namaste! Main ${_cardData.name} (${_cardData.firmName}) - DigiNiwas Verified Real Estate Partner (${_cardData.city}).\n\n'
        '📞 Call: ${_cardData.phone}\n'
        '💬 WhatsApp: ${_cardData.whatsapp}\n'
        '📍 Office / Area: ${_cardData.city}\n\n'
        'Explore verified properties & connect with me: ${_cardData.profileUrl}';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: caption,
        subject: '${_cardData.name} - DigiNiwas Verified Partner',
      ),
    );
  }

  Future<void> _shareToFacebook() async {
    final file = await _captureCardImage();
    if (file == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Connect with ${_cardData.name} (${_cardData.firmName}) - DigiNiwas Verified Real Estate Partner: ${_cardData.profileUrl}',
      ),
    );
  }

  Future<void> _shareCardAsImage() async {
    final file = await _captureCardImage();
    if (file == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text:
            '${_cardData.name} • DigiNiwas Verified Partner (${_cardData.city})\n'
            '📞 Call: ${_cardData.phone} | 💬 WhatsApp: ${_cardData.whatsapp}\n'
            '${_cardData.profileUrl}',
      ),
    );
  }

  void _copyProfileLink() {
    Clipboard.setData(ClipboardData(text: _cardData.profileUrl));
    Get.snackbar(
      'Copied!',
      'Profile link copied to clipboard: ${_cardData.profileUrl}',
      backgroundColor: _darkTeal,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.w),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle_outline_rounded, color: _mint),
    );
  }

  // ================================================================
  // EDIT CARD DETAILS MODAL SHEET (PHONE, WHATSAPP, ADDRESS, NAME)
  // ================================================================
  void _openEditDetailsModal() {
    final nameCtrl = TextEditingController(text: _cardData.name);
    final firmCtrl = TextEditingController(text: _cardData.firmName);
    final phoneCtrl = TextEditingController(text: _cardData.phone);
    final waCtrl = TextEditingController(text: _cardData.whatsapp);
    final addressCtrl = TextEditingController(text: _cardData.city);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomInset + 24.h),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
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
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Card Details',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w900,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Update phone, WhatsApp and address on card',
                              style: TextStyle(fontSize: 11.sp, color: _muted),
                            ),
                          ],
                        ),
                        if (_isCustomized)
                          TextButton(
                            onPressed: () {
                              final defaultData = PartnerCardData.fromController(c);
                              nameCtrl.text = defaultData.name;
                              firmCtrl.text = defaultData.firmName;
                              phoneCtrl.text = defaultData.phone;
                              waCtrl.text = defaultData.whatsapp;
                              addressCtrl.text = defaultData.city;
                              setState(() {
                                _cardData = defaultData;
                                _isCustomized = false;
                              });
                              setModalState(() {});
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(fontSize: 12.sp, color: Colors.redAccent, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // Phone / Contact Number
                    _buildInputField(
                      controller: phoneCtrl,
                      label: 'Contact / Calling Number',
                      hint: 'e.g. +91 98765 43210',
                      icon: Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 14.h),

                    // WhatsApp Number + "Same as Contact" shortcut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WhatsApp Number',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        GestureDetector(
                          onTap: () {
                            waCtrl.text = phoneCtrl.text;
                            setModalState(() {});
                          },
                          child: Text(
                            'Same as Contact',
                            style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w800, color: _primaryTeal),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    _buildInputField(
                      controller: waCtrl,
                      label: '',
                      hint: 'e.g. +91 98765 43210',
                      icon: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 14.h),

                    // Address / Operating City
                    _buildInputField(
                      controller: addressCtrl,
                      label: 'Office Address / Operating City',
                      hint: 'e.g. Sector 62, Noida, NCR',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.streetAddress,
                    ),
                    SizedBox(height: 14.h),

                    // Partner Name
                    _buildInputField(
                      controller: nameCtrl,
                      label: 'Your Name',
                      hint: 'e.g. Rahul Sharma',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                    SizedBox(height: 14.h),

                    // Firm / Agency Name
                    _buildInputField(
                      controller: firmCtrl,
                      label: 'Agency / Firm Name',
                      hint: 'e.g. Sharma Properties',
                      icon: Icons.business_outlined,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 22.h),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryTeal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        onPressed: () {
                          setState(() {
                            _cardData = _cardData.copyWith(
                              name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _cardData.name,
                              firmName: firmCtrl.text.trim().isNotEmpty ? firmCtrl.text.trim() : _cardData.firmName,
                              phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _cardData.phone,
                              whatsapp: waCtrl.text.trim().isNotEmpty ? waCtrl.text.trim() : _cardData.whatsapp,
                              city: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : _cardData.city,
                            );
                            _isCustomized = true;
                          });
                          Get.back();
                          Get.snackbar(
                            'Card Updated!',
                            'Your custom contact details are now reflected on the card.',
                            backgroundColor: _darkTeal,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: Text(
                          'Save & Update Card',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _ink),
          ),
          SizedBox(height: 6.h),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 12.5.sp, color: _ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              prefixIcon: Icon(icon, size: 18.sp, color: _primaryTeal),
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12.sp, color: PartnerColors.textTertiary),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // MODIFY CARD DESIGN MODAL SHEET (ALL 8 DESIGNS)
  // ================================================================
  void _openDesignSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
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
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Select Card Style (8 Types)',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  Text(
                    'Choose the format and visual theme that best suits your brand',
                    style: TextStyle(fontSize: 11.sp, color: _muted),
                  ),
                  SizedBox(height: 16.h),

                  // Scrollable List of 8 Cards
                  Expanded(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: _cardStyles.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final style = _cardStyles[index];
                        final isSelected = _selectedDesignIndex == index;

                        return _buildDesignChoiceTile(
                          title: style['title'] as String,
                          subtitle: style['subtitle'] as String,
                          badge: style['badge'] as String,
                          badgeColor: style['badgeColor'] as Color,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDesignIndex = index);
                            setModalState(() {});
                            Get.back();
                          },
                        );
                      },
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

  Widget _buildDesignChoiceTile({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F3EF) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? _primaryTeal : _border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9.5.sp, color: _muted),
                  ),
                ],
              ),
            ),
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryTeal : PartnerColors.textTertiary,
                  width: 2,
                ),
                color: isSelected ? _primaryTeal : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SHARE VIA MODAL SHEET (MATCHING REFERENCE IMAGE BOTTOM SHEET)
  // ================================================================
  void _openShareSheetModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 32.h),
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
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Share via',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSocialItem(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    label: 'WhatsApp',
                    onTap: () {
                      Get.back();
                      _shareToWhatsApp();
                    },
                  ),
                  _buildSocialItem(
                    icon: Icons.facebook_rounded,
                    color: const Color(0xFF1877F2),
                    label: 'Facebook',
                    onTap: () {
                      Get.back();
                      _shareToFacebook();
                    },
                  ),
                  _buildSocialItem(
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFFE1306C),
                    label: 'Instagram',
                    onTap: () {
                      Get.back();
                      _shareCardAsImage();
                    },
                  ),
                  _buildSocialItem(
                    icon: Icons.link_rounded,
                    color: _primaryTeal,
                    label: 'Copy Link',
                    onTap: () {
                      Get.back();
                      _copyProfileLink();
                    },
                  ),
                  _buildSocialItem(
                    icon: Icons.download_rounded,
                    color: _darkTeal,
                    label: 'Download',
                    onTap: () {
                      Get.back();
                      _downloadCard();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
