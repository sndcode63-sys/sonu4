import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/services/notification_service.dart';
import '../controllers/partner_home_controller.dart';
import '../models/partner_models.dart';

import 'widgets/partner_ui.dart';
/// Wraps one raw notification map coming from the backend and exposes
/// display-ready fields with safe fallbacks, the same way [PartnerLead]
/// wraps a raw lead map. This keeps the screen fully dynamic: nothing
/// here is hardcoded sample data.
class _NotificationView {
  _NotificationView(this.raw);
  final Map<String, dynamic> raw;

  String get id => asString(raw['_id']) ?? asString(raw['id']) ?? '';

  String get title =>
      asString(raw['title']) ??
      asString(raw['notificationTitle']) ??
      asString(raw['heading']) ??
      'Notification';

  String get message =>
      asString(raw['message']) ??
      asString(raw['body']) ??
      asString(raw['description']) ??
      '';

  String get category {
    final raw0 = (asString(raw['type']) ?? asString(raw['category']) ?? '').toUpperCase();
    if (raw0.contains('LEAD')) return 'Leads';
    if (raw0.contains('VISIT')) return 'Visits';
    if (raw0.contains('CREDIT') || raw0.contains('WALLET') || raw0.contains('PAYMENT') || raw0.contains('BOOST') || raw0.contains('PROMOTION')) {
      return 'Credits';
    }
    if (raw0.contains('ASSIGN') || raw0.contains('TEAM') || raw0.contains('VERIF') || raw0.contains('PROPERTY') || raw0.contains('DOCUMENT')) {
      return 'Assignments';
    }
    return asString(raw['category']) ?? 'General';
  }

  bool get isRead => raw['isRead'] == true || raw['read'] == true;

  DateTime? get createdAt {
    final v = raw['createdAt'] ?? raw['timestamp'] ?? raw['date'] ?? raw['time'];
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  String get timeLabel {
    final dt = createdAt;
    if (dt == null) {
      final t = asString(raw['time']);
      return (t != null && t.isNotEmpty) ? t : '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }

  String? get actionLabel => asString(raw['actionLabel']);

  int? get targetTab {
    switch (category) {
      case 'Leads':
        return 1;
      case 'Assignments':
        return 2;
      case 'Visits':
        return 3;
      default:
        return null;
    }
  }

  String? get targetRoute {
    if (category == 'Credits') return AppRoutes.creditWallet;
    return null;
  }

  IconData get icon {
    switch (category) {
      case 'Leads':
        return Icons.person_search_rounded;
      case 'Visits':
        return Icons.calendar_month_rounded;
      case 'Credits':
        return Icons.stars_rounded;
      case 'Assignments':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (category) {
      case 'Leads':
        return const Color(0xFF0A5C4A);
      case 'Visits':
        return const Color(0xFFD9961F);
      case 'Credits':
        return const Color(0xFF129B6C);
      case 'Assignments':
        return const Color(0xFF0B1B2E);
      default:
        return const Color(0xFF5B6B7C);
    }
  }

  Color get iconBg {
    switch (category) {
      case 'Leads':
        return const Color(0xFFE8F3EF);
      case 'Visits':
        return const Color(0xFFFFFBEB);
      case 'Credits':
        return const Color(0xFFE6F5EE);
      case 'Assignments':
        return const Color(0xFFE9F0FB);
      default:
        return const Color(0xFFEEF2F5);
    }
  }
}

class PartnerNotificationsScreen extends StatefulWidget {
  const PartnerNotificationsScreen({super.key});

  @override
  State<PartnerNotificationsScreen> createState() => _PartnerNotificationsScreenState();
}

class _PartnerNotificationsScreenState extends State<PartnerNotificationsScreen> {
  String selectedFilter = 'All';
  late final PartnerHomeController c;

  @override
  void initState() {
    super.initState();
    c = ensurePartnerHomeController();
    // Always pull the latest notifications when the screen opens.
    c.fetchNotifications();
  }

  List<_NotificationView> _views() =>
      c.notificationsList.map((raw) => _NotificationView(raw)).toList();

  List<_NotificationView> _filtered(List<_NotificationView> all) {
    if (selectedFilter == 'All') return all;
    return all.where((n) => n.category == selectedFilter).toList();
  }

  void markAllAsRead() {
    c.markAllNotificationsAsRead();
    Get.snackbar(
      'Marked as Read',
      'All notifications marked as read.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0A5C4A),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void handleNotificationTap(_NotificationView item) {
    if (!item.isRead) c.markNotificationAsRead(item.id);

    if (item.targetTab != null) {
      Get.back(); // close notifications screen
      c.goToTab(item.targetTab!);
    } else if (item.targetRoute != null) {
      Get.toNamed(item.targetRoute!);
    }
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: const Color(0xFF0B1B2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0B1B2E),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up_rounded, size: 20.sp, color: const Color(0xFF0A5C4A)),
            tooltip: 'Test Notification Sound',
            onPressed: () {
              NotificationService.fireTestNotification(role: 'Agent/Partner');
              AppToast.info(context, 'Testing Push Notification with sound...');
            },
          ),
          Obx(() {
            if (c.unreadNotificationsCount.value <= 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: markAllAsRead,
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A5C4A),
                ),
              ),
            );
          }),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        final all = _views();
        final list = _filtered(all);

        return RefreshIndicator(
          onRefresh: c.fetchNotifications,
          child: Column(
            children: [
              // Filter Tabs
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: PartnerColors.line)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: ['All', 'Leads', 'Visits', 'Credits', 'Assignments'].map((filter) {
                      final isSel = selectedFilter == filter;
                      final count = filter == 'All'
                          ? all.length
                          : all.where((n) => n.category == filter).length;

                      return GestureDetector(
                        onTap: () => setState(() => selectedFilter = filter),
                        child: Container(
                          margin: EdgeInsets.only(right: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFEEF2F5),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFE3E8ED),
                            ),
                          ),
                          child: Text(
                            '$filter ($count)',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF0B1B2E),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Notification List
              Expanded(
                child: c.notificationsLoading.value && all.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C4A)))
                    : list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 60.h),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A5C4A).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.notifications_none_rounded,
                                        size: 44.sp,
                                        color: const Color(0xFF0A5C4A),
                                      ),
                                    ),
                                    SizedBox(height: 14.h),
                                    Text(
                                      'No Notifications',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B1B2E),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'You are all caught up in this category.',
                                      style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              final itemId = item.id.isNotEmpty ? item.id : 'partner_notif_$index';

                              return Dismissible(
                                key: Key('partner_notif_$itemId'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: EdgeInsets.only(bottom: 10.h),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD64545),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24.sp),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onDismissed: (_) {
                                  c.deleteNotification(item.id);
                                  AppToast.success(context, 'Notification deleted');
                                },
                                child: _notificationCard(item),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _notificationCard(_NotificationView item) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : PartnerColors.brandMist,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: item.isRead ? PartnerColors.line : PartnerColors.brand.withValues(alpha: 0.28),
        ),
        boxShadow: item.isRead ? PartnerShadows.card : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(item.icon, size: 20.sp, color: item.iconColor),
          ),
          SizedBox(width: 12.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1B2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        margin: EdgeInsets.only(left: 6.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0A5C4A),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: PartnerColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.timeLabel,
                      style: TextStyle(fontSize: 10.5.sp, color: PartnerColors.textTertiary),
                    ),
                    if (item.actionLabel != null || item.targetTab != null || item.targetRoute != null)
                      GestureDetector(
                        onTap: () => handleNotificationTap(item),
                        child: Row(
                          children: [
                            Text(
                              item.actionLabel ?? 'View',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A5C4A),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(Icons.arrow_forward_ios_rounded, size: 9.sp, color: const Color(0xFF0A5C4A)),
                          ],
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
}
