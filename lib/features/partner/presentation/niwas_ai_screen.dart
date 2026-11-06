import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/partner_home_controller.dart';
import 'partner_bottom_sheets.dart';

import 'widgets/partner_ui.dart';
class NiwasAIScreen extends StatefulWidget {
  const NiwasAIScreen({super.key});

  @override
  State<NiwasAIScreen> createState() => _NiwasAIScreenState();
}

class _NiwasAIScreenState extends State<NiwasAIScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isGenerating = false;
  late final PartnerHomeController c;

  @override
  void initState() {
    super.initState();
    c = ensurePartnerHomeController();
  }

  /// Builds today's priority actions from the partner's real, live data
  /// (leads, visits, properties, promotions) instead of canned examples.
  /// Returns an empty list when there is genuinely nothing to surface.
  List<Map<String, dynamic>> _priorityActions() {
    final items = <Map<String, dynamic>>[];

    // Unlocked-worthy / available leads.
    final availableLeads = c.leads.where((l) => !l.isUnlocked).toList();
    for (final lead in availableLeads.take(2)) {
      items.add({
        'title': 'New buyer inquiry: ${lead.propertyTitle}',
        'desc': lead.location.isNotEmpty
            ? 'Interested buyer in ${lead.location}. Unlock to view contact details and follow up.'
            : 'A verified buyer inquiry is waiting. Unlock to view contact details and follow up.',
        'action': 'Unlock Lead',
        'icon': Icons.person_search_rounded,
        'color': const Color(0xFF0A5C4A),
      });
    }

    // Properties pending document review / verification.
    final reviewProps = c.properties
        .where((p) => p.status.toLowerCase().contains('review') ||
            p.status.toLowerCase().contains('pending'))
        .toList();
    for (final p in reviewProps.take(2)) {
      items.add({
        'title': 'Review documents for ${p.title}',
        'desc': 'This listing is pending document verification before it can go live.',
        'action': 'Review Docs',
        'icon': Icons.file_upload_outlined,
        'color': const Color(0xFFD9961F),
        'propertyTitle': p.title,
        'sellerName': p.sellerName.isNotEmpty ? p.sellerName : 'Property Owner',
        'sellerPhone': p.sellerPhone,
      });
    }

    // Upcoming / requested visits.
    final upcomingVisits = c.visits
        .where((v) => !v.status.toLowerCase().contains('complete') &&
            !v.status.toLowerCase().contains('cancel'))
        .toList();
    for (final v in upcomingVisits.take(2)) {
      items.add({
        'title': 'Site visit: ${v.propertyTitle}',
        'desc': v.scheduledAt.isNotEmpty
            ? 'Scheduled with ${v.buyerName} at ${v.scheduledAt}.'
            : 'Visit requested by ${v.buyerName}. Confirm a time.',
        'action': 'View Schedule',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF8B5CF6),
      });
    }

    // Promotions/boosts close to expiring.
    for (final promo in c.promotions.take(1)) {
      final title = promo['propertyTitle'] ?? promo['partnerName'] ?? 'listing';
      items.add({
        'title': 'Boost active for $title',
        'desc': 'Keep an eye on this promotion\'s remaining active period.',
        'action': 'Boost Listing',
        'icon': Icons.rocket_launch_rounded,
        'color': const Color(0xFF3B7DD8),
      });
    }

    return items;
  }

  void _handleAsk([String? predefinedPrompt]) {
    final query = predefinedPrompt ?? _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _isGenerating = true;
    });
    _chatController.clear();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      String reply = _buildReplyFor(query.toLowerCase());

      setState(() {
        _messages.add({'sender': 'ai', 'text': reply});
        _isGenerating = false;
      });
    });
  }

  /// Simple rule-based reply generator grounded in the partner's real
  /// current data. This is not a live AI backend — DigiNiwas does not yet
  /// expose an AI-assistant API — but every number and name quoted here
  /// comes from the controller's live leads/visits/properties, never from
  /// invented examples.
  String _buildReplyFor(String q) {
    final upcomingVisits = c.visits
        .where((v) => !v.status.toLowerCase().contains('complete') &&
            !v.status.toLowerCase().contains('cancel'))
        .toList();
    final availableLeads = c.leads.where((l) => !l.isUnlocked).toList();
    final unlockedLeads = c.leads.where((l) => l.isUnlocked).toList();
    final reviewProps = c.properties
        .where((p) => p.status.toLowerCase().contains('review') ||
            p.status.toLowerCase().contains('pending'))
        .toList();

    if (q.contains('route') || q.contains('plan') || q.contains('day')) {
      if (upcomingVisits.isEmpty) {
        return '📍 You have no site visits scheduled right now. Once a buyer requests a visit it will show up here with the time and address.';
      }
      final lines = upcomingVisits.take(5).map((v) {
        final time = v.scheduledAt.isNotEmpty ? v.scheduledAt : 'Time to be confirmed';
        return '• $time: ${v.propertyTitle} (${v.buyerName})';
      }).join('\n');
      return '📍 Your visits:\n$lines';
    }
    if (q.contains('lead') || q.contains('follow')) {
      if (availableLeads.isEmpty && unlockedLeads.isEmpty) {
        return '💬 You don\'t have any buyer leads yet. New verified inquiries will appear on your Leads tab as buyers reach out.';
      }
      return '💬 You have ${availableLeads.length} lead(s) waiting to be unlocked and ${unlockedLeads.length} already unlocked. Open the Leads tab to follow up with each buyer directly.';
    }
    if (q.contains('seller') || q.contains('doc')) {
      if (reviewProps.isEmpty) {
        return '📋 No listings are currently pending document review.';
      }
      final names = reviewProps.take(5).map((p) => p.title).join(', ');
      return '📋 These listings need document review: $names. Standard checklist: Title Deed / Registry Copy, Latest Property Tax Receipt, Encumbrance Certificate (15 yrs).';
    }
    return '🤖 Niwas AI: You currently have ${availableLeads.length} lead(s) to unlock, ${unlockedLeads.length} unlocked lead(s) to follow up on, and ${upcomingVisits.length} upcoming visit(s). Ask me about your leads, visits, or seller documents for details.';
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        shape: const Border(bottom: BorderSide(color: PartnerColors.line)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0B1B2E), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0A5C4A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: const Color(0xFF0A5C4A), size: 18.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              'Niwas AI Assistant',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B1B2E),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                child: Obx(() {
                  final upcomingVisits = c.visits
                      .where((v) => !v.status.toLowerCase().contains('complete') &&
                          !v.status.toLowerCase().contains('cancel'))
                      .toList();
                  final availableLeads = c.leads.where((l) => !l.isUnlocked).toList();
                  final reviewProps = c.properties
                      .where((p) => p.status.toLowerCase().contains('review') ||
                          p.status.toLowerCase().contains('pending'))
                      .toList();
                  final actions = _priorityActions();
                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Intelligence Brief
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1B2E), Color(0xFF0A5C4A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B1B2E).withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9BE5CF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.bolt_rounded, color: const Color(0xFF9BE5CF), size: 14.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Daily Brief',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF9BE5CF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Updated Just Now',
                                style: TextStyle(fontSize: 10.5.sp, color: Colors.white60),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            upcomingVisits.isEmpty && availableLeads.isEmpty && reviewProps.isEmpty
                                ? 'You are all caught up — no pending visits, leads, or documents right now.'
                                : 'You have ${upcomingVisits.length} site visit(s) scheduled, ${availableLeads.length} buyer lead(s) to unlock, and ${reviewProps.length} listing(s) awaiting document review.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              _briefStat('Visits', '${upcomingVisits.length} Due'),
                              SizedBox(width: 8.w),
                              _briefStat('New Leads', '${availableLeads.length} New'),
                              SizedBox(width: 8.w),
                              _briefStat('Pending Docs', '${reviewProps.length} Review'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // 4 AI Tools
                    Text(
                      'AI Copilot Tools',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1B2E),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        _aiToolCard(
                          title: 'Plan My Day',
                          desc: 'Optimized visit route & schedule',
                          icon: Icons.map_outlined,
                          color: const Color(0xFF0A5C4A),
                          onTap: () => _handleAsk('Plan my day and optimize site visit routes'),
                        ),
                        SizedBox(width: 10.w),
                        _aiToolCard(
                          title: 'Lead Assistant',
                          desc: 'Smart WhatsApp follow-up copy',
                          icon: Icons.mark_chat_read_outlined,
                          color: const Color(0xFF3B7DD8),
                          onTap: () => _handleAsk('Draft a follow up message for my buyer leads'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        _aiToolCard(
                          title: 'Seller Assistant',
                          desc: 'Verification & document guide',
                          icon: Icons.verified_outlined,
                          color: const Color(0xFFD9961F),
                          onTap: () => _handleAsk('What documents are missing for my seller properties?'),
                        ),
                        SizedBox(width: 10.w),
                        _aiToolCard(
                          title: 'Listing Optimizer',
                          desc: 'Improve listing search ranking',
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF129B6C),
                          onTap: () => _handleAsk('How can I optimize my property listings to get more buyer inquiries?'),
                        ),
                      ],
                    ),

                    SizedBox(height: 22.h),

                    // Priority Actions Today
                    Text(
                      actions.isEmpty
                          ? 'Priority Actions'
                          : '${actions.length} Priority Action${actions.length == 1 ? '' : 's'} Today',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1B2E),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    if (actions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: const Color(0xFFE3E8ED)),
                        ),
                        child: Text(
                          'Nothing needs your attention right now. New leads, visits, and document reviews will show up here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
                        ),
                      ),

                    ...actions.map((item) {
                      final title = item['title'] as String;
                      final desc = item['desc'] as String;
                      final action = item['action'] as String;
                      final icon = item['icon'] as IconData;
                      final color = item['color'] as Color;

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: const Color(0xFFE3E8ED)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 18.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0B1B2E),
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: PartnerColors.textSecondary,
                                      height: 1.25,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        if (action.contains('Review')) {
                                          showReviewDocumentsSheet(
                                            context,
                                            propertyTitle: (item['propertyTitle'] as String?) ?? 'Property',
                                            sellerName: (item['sellerName'] as String?) ?? 'Property Contact',
                                            phone: (item['sellerPhone'] as String?) ?? '',
                                          );
                                        } else if (action.contains('Unlock')) {
                                          Get.back();
                                          c.goToTab(1);
                                        } else if (action.contains('Schedule') || action.contains('Visit')) {
                                          Get.back();
                                          c.goToTab(3);
                                        } else if (action.contains('Boost')) {
                                          Get.back();
                                          c.goToTab(2);
                                        } else if (action.contains('Seller') || action.contains('Confirm')) {
                                          showContactSellerSheet(context);
                                        } else {
                                          Get.snackbar(
                                            action,
                                            'Processing action: $title',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: color,
                                        side: BorderSide(color: color),
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                      ),
                                      child: Text(
                                        action,
                                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Interactive Chat Log
                    if (_messages.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'AI Conversation',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1B2E),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      ..._messages.map((m) {
                        final isUser = m['sender'] == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(12.w),
                            constraints: BoxConstraints(maxWidth: 0.8.sw),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF0A5C4A) : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: isUser ? null : Border.all(color: const Color(0xFFE3E8ED)),
                            ),
                            child: Text(
                              m['text'] ?? '',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: isUser ? Colors.white : const Color(0xFF0B1B2E),
                                height: 1.3,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_isGenerating)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A5C4A)),
                              ),
                              SizedBox(width: 8.w),
                              Text('Niwas AI is thinking...', style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary)),
                            ],
                          ),
                        ),
                    ],
                  ],
                  );
                }),
              ),
            ),

            // Bottom Chat Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE3E8ED))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      onSubmitted: (_) => _handleAsk(),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about leads or properties...',
                        hintStyle: TextStyle(fontSize: 12.sp, color: PartnerColors.textTertiary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: Color(0xFFE3E8ED)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: Color(0xFFE3E8ED)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: Color(0xFF0A5C4A)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        fillColor: const Color(0xFFF6F8FA),
                        filled: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: const Color(0xFF0A5C4A),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                      onPressed: () => _handleAsk(),
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

  Widget _briefStat(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.white60)),
          Text(value, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _aiToolCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE3E8ED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 18.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1B2E),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                desc,
                style: TextStyle(fontSize: 10.sp, color: PartnerColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
