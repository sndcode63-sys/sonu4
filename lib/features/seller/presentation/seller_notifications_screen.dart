import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/services/notification_service.dart';
import '../controllers/seller_controller.dart';

/// Presentation helper that adapts raw notification JSON from the backend
/// into strongly typed UI properties without hardcoded data.
class _SellerNotificationItem {
  final Map<String, dynamic> raw;

  _SellerNotificationItem(this.raw);

  String get id =>
      raw['_id']?.toString() ??
          raw['id']?.toString() ??
          raw['notificationId']?.toString() ??
          '';

  String get title =>
      raw['title']?.toString() ??
          raw['notificationTitle']?.toString() ??
          raw['heading']?.toString() ??
          raw['subject']?.toString() ??
          'Notification';

  String get message =>
      raw['message']?.toString() ??
          raw['body']?.toString() ??
          raw['description']?.toString() ??
          raw['text']?.toString() ??
          '';

  String get category {
    final typeStr = (raw['type']?.toString() ??
        raw['category']?.toString() ??
        raw['eventType']?.toString() ??
        '')
        .toUpperCase();
    final titleStr = title.toUpperCase();
    final combined = '$typeStr $titleStr';

    if (combined.contains('PROP') ||
        combined.contains('LIST') ||
        combined.contains('VERIF') ||
        combined.contains('DOC') ||
        combined.contains('STATUS')) {
      return 'Properties';
    }
    if (combined.contains('PARTNER') ||
        combined.contains('AGENT') ||
        combined.contains('ASSIGN') ||
        combined.contains('CONNECT')) {
      return 'Partner';
    }
    if (combined.contains('VISIT') ||
        combined.contains('APPOINT') ||
        combined.contains('SCHEDULE') ||
        combined.contains('TOUR')) {
      return 'Visits';
    }
    if (combined.contains('OFFER') ||
        combined.contains('LEAD') ||
        combined.contains('INQUIR') ||
        combined.contains('ENQUIR') ||
        combined.contains('INTEREST') ||
        combined.contains('BUYER')) {
      return 'Offers';
    }
    return 'General';
  }

  bool get isRead => raw['isRead'] == true || raw['read'] == true;

  DateTime? get createdAt {
    final val = raw['createdAt'] ?? raw['timestamp'] ?? raw['date'] ?? raw['time'];
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  String get timeLabel {
    final dt = createdAt;
    if (dt == null) {
      final t = raw['time']?.toString() ?? raw['date']?.toString();
      return (t != null && t.isNotEmpty) ? t : '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }

  IconData get icon {
    switch (category) {
      case 'Properties':
        return Icons.apartment_rounded;
      case 'Partner':
        return Icons.handshake_outlined;
      case 'Visits':
        return Icons.calendar_month_rounded;
      case 'Offers':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get iconColor {
    switch (category) {
      case 'Properties':
        return const Color(0xFF165A54);
      case 'Partner':
        return const Color(0xFF0F2544);
      case 'Visits':
        return const Color(0xFFD97706);
      case 'Offers':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF475569);
    }
  }

  Color get iconBg {
    switch (category) {
      case 'Properties':
        return const Color(0xFFE6F4F1);
      case 'Partner':
        return const Color(0xFFEFF6FF);
      case 'Visits':
        return const Color(0xFFFEF3C7);
      case 'Offers':
        return const Color(0xFFD1FAE5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}

class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() => _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState extends State<SellerNotificationsScreen> {
  String _selectedCategory = 'All';

  SellerController get _controller {
    if (Get.isRegistered<SellerController>(tag: 'sellerHome')) {
      return Get.find<SellerController>(tag: 'sellerHome');
    }
    if (Get.isRegistered<SellerController>()) {
      return Get.find<SellerController>();
    }
    return Get.put(SellerController());
  }

  @override
  void initState() {
    super.initState();
    // Load fresh notifications on screen entry
    _controller.fetchNotifications();
  }

  List<_SellerNotificationItem> _getParsedNotifications() {
    return _controller.notificationsList
        .whereType<Map>()
        .map((m) => _SellerNotificationItem(Map<String, dynamic>.from(m)))
        .toList();
  }

  List<_SellerNotificationItem> _getFilteredNotifications(List<_SellerNotificationItem> all) {
    if (_selectedCategory == 'All') return all;
    return all.where((n) => n.category == _selectedCategory).toList();
  }

  void _onNotificationTap(_SellerNotificationItem item) {
    if (!item.isRead && item.id.isNotEmpty) {
      _controller.markNotificationAsRead(item.id);
    }

    // Optional quick routing based on category
    if (item.category == 'Properties') {
      Get.toNamed(AppRoutes.myProperties);
    } else if (item.category == 'Visits') {
      Get.toNamed(AppRoutes.sellerInsights);
    }
  }

  void _markAllAsRead() {
    _controller.markAllNotificationsAsRead();
    Get.snackbar(
      'Notifications Read',
      'All notifications marked as read',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF165A54),
      colorText: Colors.white,
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Clear all notifications?',
            style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w700)),
        content: Text('Saari notifications list se hata di jayengi.',
            style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Clear all',
                style: GoogleFonts.poppins(
                    color: const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _controller.clearAllNotifications();
      Get.snackbar(
        'Cleared',
        'All notifications cleared',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF165A54),
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: const Color(0xFF0F2544)),
          onPressed: () {
            _controller.fetchNotifications();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F2544),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up_rounded, size: 20.sp, color: const Color(0xFF165A54)),
            tooltip: 'Test Notification Sound',
            onPressed: () {
              NotificationService.fireTestNotification(role: 'Seller');
              AppToast.info(context, 'Testing Push Notification with sound...');
            },
          ),
          Obx(() {
            if (_controller.notificationsList.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: _confirmClearAll,
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
            );
          }),
          Obx(() {
            final unread = _controller.unreadNotificationsCount.value;
            if (unread <= 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF165A54),
                ),
              ),
            );
          }),
          SizedBox(width: 8.w),
        ],
      ),
      body: Obx(() {
        final all = _getParsedNotifications();
        final filtered = _getFilteredNotifications(all);

        return RefreshIndicator(
          color: const Color(0xFF165A54),
          onRefresh: () => _controller.fetchNotifications(),
          child: Column(
            children: [
              // Category filter pills
              _buildFilterChips(all),

              // Notification List or Empty State
              Expanded(
                child: _controller.notificationsLoading.value && all.isEmpty
                    ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF165A54)),
                )
                    : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final itemId = item.id.isNotEmpty ? item.id : 'seller_notif_$index';

                    return Dismissible(
                      key: Key('seller_notif_$itemId'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24.sp),
                            SizedBox(width: 6.w),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        _controller.deleteNotification(item.id);
                        AppToast.success(context, 'Notification deleted');
                      },
                      child: _buildNotificationCard(item),
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

  Widget _buildFilterChips(List<_SellerNotificationItem> all) {
    const filters = ['All', 'Properties', 'Partner', 'Visits', 'Offers'];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final isSel = _selectedCategory == filter;
            final count = filter == 'All'
                ? all.length
                : all.where((n) => n.category == filter).length;

            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = filter),
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF165A54) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSel ? const Color(0xFF165A54) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$filter ($count)',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? Colors.white : const Color(0xFF0F2544),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 70.h),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(22.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF165A54).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 46.sp,
                  color: const Color(0xFF165A54),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'No Notifications Yet',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F2544),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _selectedCategory == 'All'
                    ? 'You are all caught up with your properties and visits.'
                    : 'No $_selectedCategory notifications at the moment.',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(_SellerNotificationItem item) {
    return GestureDetector(
      onTap: () => _onNotificationTap(item),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF7FBF9),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBBE5DF),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F2544),
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
                            color: Color(0xFF165A54),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (item.message.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      item.message,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.timeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          color: Colors.black45,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF165A54),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(Icons.arrow_forward_ios_rounded, size: 9.sp, color: const Color(0xFF165A54)),
                        ],
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
