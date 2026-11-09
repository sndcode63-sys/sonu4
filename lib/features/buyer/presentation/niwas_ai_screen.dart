import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_image.dart';
import '../controllers/niwas_ai_controller.dart';
import '../models/niwas_ai_models.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';

class NiwasAiScreen extends StatefulWidget {
  const NiwasAiScreen({super.key});

  @override
  State<NiwasAiScreen> createState() => _NiwasAiScreenState();
}

class _NiwasAiScreenState extends State<NiwasAiScreen> {
  late final NiwasAiController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<NiwasAiController>()
        ? Get.find<NiwasAiController>()
        : Get.put(NiwasAiController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = Get.arguments;
      if (args is Map && args['mode'] != null) {
        controller.setMode(args['mode'].toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPushed = Navigator.canPop(context);
    final double bottomInset = isPushed ? 16.h : 30.h;
    final double listBottomSpace = isPushed ? 110.h : 130.h;

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
        backgroundColor: const Color(0xFF071B2F),
        drawer: _buildChatGPTDrawer(context),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        16.w, MediaQuery.of(context).padding.top + 10.h, 16.w, 8.h),
                    child: _buildHeader(),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.messages.isEmpty) {
                        return _buildWelcomeView();
                      }
                      return _buildChatListView();
                    }),
                  ),
                  // Reserved space for bottom input bar and bottom nav
                  SizedBox(height: listBottomSpace),
                ],
              ),

              // Bottom Floating Input Bar with Quick Chips
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: bottomInset,
                child: _buildBottomSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TOP BAR
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () {
                  controller.loadSavedSessions();
                  Scaffold.of(ctx).openDrawer();
                },
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                tooltip: 'Chat History',
              ),
            ),
            if (canPop) ...[
              const AppAdaptiveBackButton(
                color: Colors.white,
                backgroundColor: Color(0xFF0F324D),
                size: 34,
                iconSize: 18,
                margin: EdgeInsets.only(right: 8),
              ),
            ],

            Obx(() {
              final mode = controller.currentMode.value;
              final badgeLabel = mode != null ? controller.getModeTitle(mode) : 'NIWAS AI';
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F324D),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFF007A5E).withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/niwas_ai_icon.png',
                        width: 22.sp, height: 22.sp, fit: BoxFit.contain),
                    SizedBox(width: 5.w),
                    Text(
                      badgeLabel.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (mode != null) ...[
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => controller.startNewChat(),
                        child: Icon(Icons.close_rounded, color: Colors.white70, size: 13.sp),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),

        // ChatGPT-style History Drawer & New Chat Buttons
        Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () {
                  controller.loadSavedSessions();
                  Scaffold.of(ctx).openDrawer();
                },
                icon: const Icon(Icons.history_rounded, color: Color(0xFF4EE1A0)),
                tooltip: 'Chat History',
              ),
            ),
            IconButton(
              onPressed: () => controller.startNewChat(),
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white70),
              tooltip: 'New Chat',
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CHATGPT-STYLE SIDE NAVIGATION DRAWER (NO BOTTOM SHEET)
  // ---------------------------------------------------------------------
  Widget _buildChatGPTDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF071B2F),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drawer Header
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_rounded, color: const Color(0xFF4EE1A0), size: 22.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Chat History',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        controller.startNewChat();
                      },
                      icon: Icon(Icons.add_rounded, size: 18.sp, color: Colors.white),
                      label: Text(
                        'New Chat',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF14354E), height: 1),

            // History Sessions List
            Expanded(
              child: Obx(() {
                final sessions = controller.savedSessions;
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 36.sp, color: const Color(0xFF476077)),
                        SizedBox(height: 10.h),
                        Text(
                          'No chat history yet',
                          style: GoogleFonts.poppins(fontSize: 13.sp, color: const Color(0xFF8A9FA8)),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Start a conversation with Niwas AI',
                          style: GoogleFonts.poppins(fontSize: 11.sp, color: const Color(0xFF5E798E)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (ctx, idx) {
                    final item = sessions[idx];
                    final id = item['id']?.toString() ?? '';
                    final title = item['title']?.toString() ?? 'Chat Conversation';
                    final isCurrent = controller.sessionId.value == id;

                    String dateStr = '';
                    if (item['updatedAt'] != null) {
                      final dt = DateTime.tryParse(item['updatedAt'].toString());
                      if (dt != null) {
                        dateStr = '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF0F3952) : const Color(0xFF0C243B),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF4EE1A0) : const Color(0xFF153B5A),
                          width: isCurrent ? 1.2 : 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            controller.loadSessionHistory(id);
                          },
                          leading: Icon(
                            isCurrent ? Icons.chat_rounded : Icons.history_rounded,
                            size: 18.sp,
                            color: isCurrent ? const Color(0xFF4EE1A0) : const Color(0xFF708CA6),
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5.sp,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? Colors.white : const Color(0xFFD0E1F0),
                            ),
                          ),
                          subtitle: dateStr.isNotEmpty
                              ? Text(
                                  dateStr,
                                  style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF6B8A9E)),
                                )
                              : null,
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 18.sp, color: Colors.redAccent.shade100),
                            onPressed: () => controller.deleteSession(id),
                            tooltip: 'Delete Chat',
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // WELCOME / STARTER VIEW (When no messages sent yet)
  // ---------------------------------------------------------------------
  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          _buildAiAvatar(),
          SizedBox(height: 16.h),
          _buildTitleSection(),
          SizedBox(height: 20.h),
          _buildFeatureGrid(),
          SizedBox(height: 20.h),
          _buildSectionDivider(),
          SizedBox(height: 14.h),
          _buildQuickSuggestions(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // AI SPREADING AURA LOGO AVATAR
  // ---------------------------------------------------------------------
  Widget _buildAiAvatar() {
    return SpreadingAiLogo(size: 80.w);
  }

  // ---------------------------------------------------------------------
  // TITLE & DESCRIPTION
  // ---------------------------------------------------------------------
  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Find your next home, with Niwas AI.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16.5.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Text(
            'Your intelligent property concierge for finding, comparing and exploring verified DigiNiwas homes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              color: const Color(0xFF90A3B8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 2x2 FEATURE ACTIONS GRID
  // ---------------------------------------------------------------------
  Widget _buildFeatureGrid() {
    final features = [
      {
        'icon': Icons.search_rounded,
        'title': 'Find My Home',
        'sub': "Tell me what you're looking for.",
        'mode': NiwasAiController.modeFindHome,
      },
      {
        'icon': Icons.compare_arrows_rounded,
        'title': 'Compare Homes',
        'sub': 'See the differences clearly.',
        'mode': NiwasAiController.modeCompareHomes,
      },
      {
        'icon': Icons.travel_explore_rounded,
        'title': 'Explore Locality',
        'sub': 'Understand the neighbourhood.',
        'mode': NiwasAiController.modeExploreLocality,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Price Trends',
        'sub': 'Market insights & growth.',
        'mode': NiwasAiController.modePriceTrends,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: features.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = features[index];
        return InkWell(
          onTap: () => controller.setMode(item['mode'] as String),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2841),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF007A5E).withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(7.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF091C2E),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(item['icon'] as IconData,
                      color: const Color(0xFF4EE1A0), size: 16.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  item['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item['sub'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5.sp,
                    color: const Color(0xFF869EB5),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // SECTION DIVIDER
  // ---------------------------------------------------------------------
  Widget _buildSectionDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF1A3854), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            'OR ASK NIWAS AI DIRECTLY',
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF67839E),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF1A3854), thickness: 1)),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // QUICK SUGGESTION CHIPS
  // ---------------------------------------------------------------------
  Widget _buildQuickSuggestions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: controller.quickSuggestions.map((prompt) {
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => controller.sendUserMessage(prompt),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F324D),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFF1F5278)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF4EE1A0), size: 12.sp),
                    SizedBox(width: 6.w),
                    Text(
                      prompt,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CHAT LIST VIEW
  // ---------------------------------------------------------------------
  Widget _buildChatListView() {
    return Obx(() {
      final mode = controller.currentMode.value;
      final examplePrompt = mode != null ? controller.getExamplePrompt(mode) : null;
      final bool showExample = examplePrompt != null && controller.messages.length <= 1;

      return ListView.builder(
        controller: controller.scrollController,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: controller.messages.length +
            (showExample ? 1 : 0) +
            (controller.isSending.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < controller.messages.length) {
            final message = controller.messages[index];
            return _buildMessageItem(message);
          }
          if (showExample && index == controller.messages.length) {
            return _buildExamplePromptCard(examplePrompt);
          }
          return _buildLoadingBubble();
        },
      );
    });
  }

  Widget _buildExamplePromptCard(String prompt) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h, left: 34.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F324D),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF007A5E).withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => controller.sendUserMessage(prompt),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: const Color(0xFF4EE1A0), size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example prompt (Tap to Ask):',
                    style: GoogleFonts.poppins(color: const Color(0xFF869EB5), fontSize: 10.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '"$prompt"',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 11.5.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.send_rounded, color: const Color(0xFF4EE1A0), size: 16.sp),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MESSAGE ITEM (User or Assistant)
  // ---------------------------------------------------------------------
  Widget _buildMessageItem(AiChatMessage message) {
    if (message.isUser) {
      return Padding(
        padding: EdgeInsets.only(bottom: 14.h),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: 0.78.sw),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(4.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }

    // Assistant Message
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF005B48),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/niwas_ai_icon.png',
                    width: 14.sp, height: 14.sp, fit: BoxFit.contain),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? const Color(0xFF3B151E)
                        : const Color(0xFF0E2E4B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                    border: Border.all(
                      color: message.isError
                          ? const Color(0xFF782535)
                          : const Color(0xFF1B456C),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          color: message.isError
                              ? const Color(0xFFFFB4C0)
                              : const Color(0xFFE2E8F0),
                          height: 1.4,
                        ),
                      ),
                      if (message.sources.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        const Divider(color: Color(0xFF1B456C), height: 1),
                        SizedBox(height: 6.h),
                        ...message.sources.map((src) => _buildSourceItem(src)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Render recommended properties if any
          if (message.properties.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildPropertiesCarousel(message.properties),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceItem(AiSource source) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: InkWell(
        onTap: () {
          if (source.url != null && source.url!.isNotEmpty) {
            launchUrl(Uri.parse(source.url!),
                mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_rounded,
                color: const Color(0xFF4EE1A0), size: 12.sp),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                '${source.title ?? 'Source'}${source.snippet != null ? ': "${source.snippet}"' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 9.5.sp,
                  color: const Color(0xFF4EE1A0),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LOADING / TYPING ANIMATED SEARCHING WIDGET
  // ---------------------------------------------------------------------
  Widget _buildLoadingBubble() {
    return const _AiSearchingAnimationWidget();
  }

  // ---------------------------------------------------------------------
  // PROPERTY CAROUSEL
  // ---------------------------------------------------------------------
  Widget _buildPropertiesCarousel(List<AiPropertyCard> properties) {
    return SizedBox(
      height: 360.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return _buildPropertyCard(property);
        },
      ),
    );
  }

  Widget _buildPropertyCard(AiPropertyCard property) {
    final imageUrl = property.image ??
        (property.images.isNotEmpty ? property.images.first : '');

    return Container(
      width: 265.w,
      margin: EdgeInsets.only(right: 14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2841),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFF1B3F63)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview + badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                child: ImageCase(
                  url: imageUrl,
                  height: 132.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.home_work_rounded,
                  backgroundColor: const Color(0xFF133959),
                  iconColor: Colors.white70,
                ),
              ),
              if (property.verified)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A5E),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 11.sp, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'VERIFIED',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (property.transactionType != null && property.transactionType!.isNotEmpty)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071B2F).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      property.transactionType!.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4EE1A0),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Details section
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      property.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4EE1A0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12.sp, color: const Color(0xFF00A884)),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        property.formattedLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          color: const Color(0xFF869EB5),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (property.bedrooms != null && property.bedrooms!.isNotEmpty) ...[
                      Icon(Icons.bed_outlined, size: 13.sp, color: const Color(0xFF869EB5)),
                      SizedBox(width: 3.w),
                      Text(
                        '${property.bedrooms} BHK',
                        style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFFCAD7E2)),
                      ),
                      SizedBox(width: 10.w),
                    ],
                    if (property.size != null) ...[
                      Icon(Icons.crop_square_rounded, size: 13.sp, color: const Color(0xFF869EB5)),
                      SizedBox(width: 3.w),
                      Text(
                        '${property.size} ${property.sizeUnit ?? "sqft"}',
                        style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFFCAD7E2)),
                      ),
                      SizedBox(width: 10.w),
                    ],
                    if (property.furnishing != null && property.furnishing!.isNotEmpty) ...[
                      Expanded(
                        child: Text(
                          property.furnishing!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 9.5.sp, color: const Color(0xFFCAD7E2)),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12.h),

                // Action Buttons: View Property & Snapshot Insights
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.propertyDetails, arguments: {
                            'propertyId': property.id,
                            'property': {
                              '_id': property.id,
                              'propertyId': property.id,
                              'title': property.title,
                              'price': property.price,
                              'locality': property.locality,
                              'city': property.city,
                              'bedrooms': property.bedrooms,
                              'images': property.images.map((url) => {'url': url}).toList(),
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A5E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Property',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () => _showPropertySnapshotModal(property.id),
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.all(9.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11385C),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFF1E5279)),
                        ),
                        child: Icon(Icons.analytics_outlined, color: const Color(0xFF4EE1A0), size: 18.sp),
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

  Widget _buildImageFallback() {
    return Container(
      height: 135.h,
      color: const Color(0xFF0A1E31),
      child: const Center(
        child:
        Icon(Icons.home_work_rounded, color: Color(0xFF00A884), size: 36),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PROPERTY SNAPSHOT BOTTOM SHEET (GET /v1/properties/{id}/snapshot)
  // ---------------------------------------------------------------------
  void _showPropertySnapshotModal(String propertyId) {
    controller.fetchPropertySnapshot(propertyId, context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 0.75.sh,
          decoration: BoxDecoration(
            color: const Color(0xFF071B2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: const Color(0xFF1E5279)),
          ),
          padding: EdgeInsets.all(18.w),
          child: Obx(() {
            if (controller.snapshotLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4EE1A0)),
              );
            }
            final snap = controller.activeSnapshot.value;
            if (snap == null) {
              return Center(
                child: Text(
                  'No snapshot data available for this listing.',
                  style:
                  GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          snap.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A5E),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          snap.dataConfidence?['level']?.toString() ??
                              'Verified',
                          style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _buildSnapshotCard(
                    title: 'Price Comparison',
                    headline: snap.priceComparison?['headline']?.toString() ??
                        'Market Rate Analysis',
                    caption: snap.priceComparison?['basis']?.toString() ?? '',
                    icon: Icons.currency_rupee_rounded,
                  ),
                  SizedBox(height: 10.h),
                  _buildSnapshotCard(
                    title: 'Rental Yield',
                    headline: snap.rentalYield?['headline']?.toString() ??
                        'Yield Potential',
                    caption: snap.rentalYield?['basis']?.toString() ?? '',
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                  SizedBox(height: 10.h),
                  _buildSnapshotCard(
                    title: 'Locality Trend',
                    headline: snap.localityTrend?['headline']?.toString() ??
                        'Neighbourhood Growth',
                    caption: snap.localityTrend?['reason']?.toString() ?? '',
                    icon: Icons.trending_up_rounded,
                  ),
                  if (snap.disclaimer != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      snap.disclaimer!,
                      style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: const Color(0xFF67839E),
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSnapshotCard({
    required String title,
    required String headline,
    required String caption,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2841),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF1B3F63)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFF091C2E),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: const Color(0xFF4EE1A0), size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: const Color(0xFF869EB5),
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  headline,
                  style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
                if (caption.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    caption,
                    style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: const Color(0xFF90A3B8),
                        height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BOTTOM SECTION (QUICK CHIPS + FLOATING INPUT BAR)
  // ---------------------------------------------------------------------
  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final mode = controller.currentMode.value;
          final chips = mode != null ? controller.getQuickChips(mode) : <String>[];
          if (chips.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            height: 34.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: chips.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final chip = chips[index];
                return InkWell(
                  onTap: () => controller.handleChipTap(chip),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F324D),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFF007A5E).withValues(alpha: 0.65),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007A5E).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        chip,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4EE1A0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        _buildBottomInputBar(),
      ],
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0C243B),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFF1C466E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showVoiceSearchModal(context),
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                color: Color(0xFF133658),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded,
                  color: const Color(0xFF4EE1A0), size: 18.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller.textController,
              onSubmitted: (_) => controller.sendUserMessage(),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.sp),
              cursorColor: const Color(0xFF4EE1A0),
              decoration: InputDecoration(
                hintText: 'Ask anything about properties...',
                hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF627D98), fontSize: 12.sp),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Obx(() {
            final isSending = controller.isSending.value;
            return GestureDetector(
              onTap: isSending ? null : () => controller.sendUserMessage(),
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: isSending
                      ? const Color(0xFF005B48)
                      : const Color(0xFF00897B),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSending
                      ? SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 18.sp),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showVoiceSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VoiceSearchSheet(
        onRecognized: (text) {
          Navigator.pop(ctx);
          final cleanQuery = text.trim();
          if (cleanQuery.isNotEmpty) {
            controller.textController.text = cleanQuery;
            controller.sendUserMessage(cleanQuery);
            controller.textController.clear();
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
// SIMPLE BOUNCING DOTS SEARCHING ANIMATION
// ---------------------------------------------------------------------
class _AiSearchingAnimationWidget extends StatefulWidget {
  const _AiSearchingAnimationWidget();

  @override
  State<_AiSearchingAnimationWidget> createState() => _AiSearchingAnimationWidgetState();
}

class _AiSearchingAnimationWidgetState extends State<_AiSearchingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h, left: 4.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(5.r),
            decoration: const BoxDecoration(
              color: Color(0xFF005B48),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/niwas_ai_icon.png',
              width: 14.sp,
              height: 14.sp,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Searching',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4EE1A0),
            ),
          ),
          SizedBox(width: 4.w),
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_animCtrl.value - delay) % 1.0;
                  final translateY = -4.h * math.sin(progress * math.pi);
                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      width: 4.5.w,
                      height: 4.5.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4EE1A0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// DYNAMIC SPEECH-TO-TEXT VOICE SEARCH SHEET
// ---------------------------------------------------------------------
class _VoiceSearchSheet extends StatefulWidget {
  final ValueChanged<String> onRecognized;

  const _VoiceSearchSheet({required this.onRecognized});

  @override
  State<_VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends State<_VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _submitted = false;
  bool _isInitializing = true;
  bool _permissionDenied = false;
  String _statusMessage = 'Initializing microphone...';
  String _spokenText = '';
  Timer? _autoSubmitTimer;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initSpeechRecognizer();
  }

  Future<void> _initSpeechRecognizer() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _permissionDenied = false;
      _statusMessage = 'Requesting microphone permission...';
    });

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _permissionDenied = true;
          _isListening = false;
          _statusMessage = 'Microphone permission is required for voice search.';
        });
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'listening') {
            setState(() {
              _isListening = true;
              _statusMessage = 'Listening... Speak now';
            });
          } else if (status == 'notListening' || status == 'done') {
            setState(() {
              _isListening = false;
            });
            if (_spokenText.trim().isNotEmpty && !_submitted) {
              _scheduleAutoSubmit();
            } else if (_spokenText.trim().isEmpty && !_submitted) {
              setState(() {
                _statusMessage = "Didn't catch that. Tap the mic to try again.";
              });
            }
          }
        },
        onError: (errorNotification) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            if (_spokenText.trim().isEmpty) {
              _statusMessage = errorNotification.errorMsg.isNotEmpty
                  ? 'Error: ${errorNotification.errorMsg}. Tap mic to retry.'
                  : 'Could not hear voice. Tap mic to retry.';
            }
          });
        },
        debugLogging: false,
      );

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });

      if (available) {
        _startListening();
      } else {
        setState(() {
          _statusMessage = 'Voice recognition not ready on device. Tap mic to retry.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Voice search initialization failed. Please try again.';
      });
    }
  }

  Future<void> _startListening() async {
    if (_submitted) return;
    if (!_speech.isAvailable) {
      await _initSpeechRecognizer();
      return;
    }

    _autoSubmitTimer?.cancel();
    setState(() {
      _isListening = true;
      _statusMessage = 'Listening... Speak clearly';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted || _submitted) return;
          setState(() {
            _spokenText = result.recognizedWords;
            _statusMessage = 'Hearing your voice...';
          });

          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _scheduleAutoSubmit();
          }
        },
          listenOptions: stt.SpeechListenOptions(
            listenFor: const Duration(seconds: 35),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            listenMode: stt.ListenMode.search,
            cancelOnError: false,
          ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Tap the microphone to speak.';
        });
      }
    }
  }

  void _scheduleAutoSubmit() {
    _autoSubmitTimer?.cancel();
    _autoSubmitTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_submitted && _spokenText.trim().isNotEmpty) {
        _submitRecognizedText();
      }
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      if (_spokenText.trim().isNotEmpty) {
        _submitRecognizedText();
      }
    } else {
      _startListening();
    }
  }

  void _submitRecognizedText() {
    if (_submitted) return;
    final clean = _spokenText.replaceAll('"', '').trim();
    if (clean.isEmpty) return;

    _submitted = true;
    _autoSubmitTimer?.cancel();
    _speech.stop();

    setState(() {
      _isListening = false;
      _statusMessage = 'Searching for "$clean"...';
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        widget.onRecognized(clean);
      }
    });
  }

  @override
  void dispose() {
    _autoSubmitTimer?.cancel();
    _waveCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasWords = _spokenText.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: const Color(0xFF071B2F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: const Color(0xFF007A5E).withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 38.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 18.h),

          // Header Status
          Text(
            _isInitializing
                ? 'Setting Up Voice Search...'
                : _isListening
                    ? 'Listening To You...'
                    : hasWords
                        ? 'Voice Recognized'
                        : 'Voice Search',
            style: GoogleFonts.poppins(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: const Color(0xFF869EB5),
            ),
          ),
          SizedBox(height: 16.h),

          // Live Speech Box
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 64.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0D253F),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: hasWords
                    ? const Color(0xFF4EE1A0).withValues(alpha: 0.7)
                    : Colors.white10,
              ),
            ),
            child: Center(
              child: Text(
                hasWords
                    ? '"$_spokenText"'
                    : 'Speak naturally, e.g. "Find 3 BHK house in Ambala under 70 Lakhs"',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: hasWords ? 14.5.sp : 12.5.sp,
                  fontWeight: hasWords ? FontWeight.w600 : FontWeight.w400,
                  color: hasWords ? const Color(0xFF4EE1A0) : Colors.white38,
                ),
              ),
            ),
          ),
          SizedBox(height: 22.h),

          // Mic and Wave visualizer
          if (_permissionDenied) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_off_rounded, color: Colors.amber),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Microphone permission is denied. Enable it in App Settings to use voice search.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_rounded, color: Colors.black),
              label: Text(
                'Open App Settings',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EE1A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ] else ...[
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isListening)
                      ...List.generate(4, (i) {
                        final h = 12.h +
                            (math.sin((_waveCtrl.value * math.pi) + i) * 22.h)
                                .abs();
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: 4.w,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4EE1A0),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        );
                      }),
                    SizedBox(width: 16.w),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 76.w,
                        height: 76.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? const Color(0xFF007A5E)
                              : hasWords
                                  ? const Color(0xFF0A6847)
                                  : const Color(0xFF133E4D),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? const Color(0xFF4EE1A0)
                                      : const Color(0xFF007A5E))
                                  .withValues(
                                alpha: _isListening
                                    ? 0.45 * _waveCtrl.value
                                    : 0.2,
                              ),
                              blurRadius:
                                  _isListening ? 26 * _waveCtrl.value : 10,
                              spreadRadius:
                                  _isListening ? 8 * _waveCtrl.value : 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : hasWords
                                    ? Icons.check_rounded
                                    : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 34.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    if (_isListening)
                      ...List.generate(4, (i) {
                        final h = 12.h +
                            (math.cos((_waveCtrl.value * math.pi) + i) * 22.h)
                                .abs();
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: 4.w,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4EE1A0),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
            SizedBox(height: 12.h),
            Text(
              _isListening
                  ? 'Tap mic to pause'
                  : hasWords
                      ? 'Tap mic to speak again'
                      : 'Tap mic to start speaking',
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                color: Colors.white54,
              ),
            ),
          ],

          SizedBox(height: 20.h),

          // Action Buttons: Search Now & Cancel
          if (hasWords && !_submitted) ...[
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _submitRecognizedText,
                icon: const Icon(Icons.search_rounded, color: Colors.black),
                label: Text(
                  'Search Now',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EE1A0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],

          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 13.5.sp,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// SPREADING AI LOGO ANIMATION (OUTWARD 360-DEGREE PULSING AURA)
// ---------------------------------------------------------------------
class SpreadingAiLogo extends StatefulWidget {
  final double size;
  const SpreadingAiLogo({super.key, this.size = 80});

  @override
  State<SpreadingAiLogo> createState() => _SpreadingAiLogoState();
}

class _SpreadingAiLogoState extends State<SpreadingAiLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final val = _pulseCtrl.value;
        return SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave 1: Outward spreading aura ring 1
              _buildPulseRing(
                scale: 1.0 + (val * 0.75),
                opacity: (1.0 - val).clamp(0.0, 0.6),
                color: const Color(0xFF00E6A1),
              ),
              // Wave 2: Outward spreading aura ring 2 (phase-shifted)
              _buildPulseRing(
                scale: 1.0 + (((val + 0.33) % 1.0) * 0.65),
                opacity: (1.0 - ((val + 0.33) % 1.0)).clamp(0.0, 0.5),
                color: const Color(0xFF0D9488),
              ),
              // Wave 3: Inner pulse glow ring 3
              _buildPulseRing(
                scale: 1.0 + (((val + 0.66) % 1.0) * 0.45),
                opacity: (1.0 - ((val + 0.66) % 1.0)).clamp(0.0, 0.7),
                color: const Color(0xFF2DD4BF),
              ),
              // Central Glowing Core Avatar
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF00E6A1),
                      Color(0xFF0A685A),
                      Color(0xFF092921),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E6A1).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.8),
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(widget.size * 0.22),
                    child: Image.asset(
                      'assets/images/niwas_ai_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulseRing({
    required double scale,
    required double opacity,
    required Color color,
  }) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: 2.0,
          ),
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity * 0.35),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }
}
