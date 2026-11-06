import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/buyer_home_controller.dart';
import '../../seller/controllers/seller_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/utils/shimmer.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final BuyerHomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<BuyerHomeController>()
        ? Get.find<BuyerHomeController>()
        : Get.put(BuyerHomeController());
    controller.fetchNotifications();
  }

  Future<void> _confirmClearAll(BuildContext context) async {
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
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
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
      await controller.clearAllNotifications();
      if (Get.isRegistered<SellerController>()) {
        Get.find<SellerController>().loadDashboardHeader();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (Get.isRegistered<SellerController>()) {
          Get.find<SellerController>().loadDashboardHeader();
        }
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: BuyerAppBar(
          title: 'Notifications',
          actions: [
            IconButton(
              icon: Icon(Icons.volume_up_rounded, size: 20.sp, color: const Color(0xFF007A5E)),
              tooltip: 'Test Notification Sound',
              onPressed: () {
                NotificationService.fireTestNotification(role: 'Buyer');
                AppToast.info(context, 'Testing Push Notification with sound...');
              },
            ),
            Obx(() {
              if (controller.notificationsList.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClearAll(context),
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              );
            }),
            Obx(() {
              final unread = controller.unreadNotificationsCount.value;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  controller.markAllNotificationsAsRead();
                  if (Get.isRegistered<SellerController>()) {
                    Get.find<SellerController>().loadDashboardHeader();
                  }
                },
                child: Text(
                  'Mark read',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007A5E),
                  ),
                ),
              );
            }),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Obx(() {
            if (controller.notificationsLoading.value) {
              return const NotificationShimmer();
            }

            final list = controller.notificationsList;
            if (list.isEmpty) {
              return AppEmptyState(
                type: EmptyStateType.notification,
                title: 'No Notifications Yet',
                message: 'We will notify you about property updates, visits, price drops, and verified listings here.',
                actionLabel: 'Refresh',
                onAction: () => controller.fetchNotifications(),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchNotifications,
              color: const Color(0xFF007A5E),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final itemId = (item is Map)
                      ? (item['_id']?.toString() ?? item['id']?.toString() ?? 'item_$index')
                      : 'item_$index';

                  return Dismissible(
                    key: Key('notif_$itemId'),
                    direction: DismissDirection.endToStart,
                    background: Container(
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
                      controller.deleteNotification(itemId);
                      AppToast.success(context, 'Notification deleted');
                    },
                    child: StaggeredItemEntrance(
                      index: index,
                      child: ScaleTap(
                        onTap: () {
                          if (item is Map) {
                            if (item['_id'] != null) {
                              controller.markNotificationAsRead(item['_id'].toString());
                            }
                            final propId = (item['propertyId'] ?? item['property']?['_id'] ?? item['data']?['propertyId'])?.toString();
                            if (propId != null && propId.isNotEmpty) {
                              Get.toNamed(AppRoutes.propertyDetails, arguments: {'propertyId': propId});
                            }
                          }
                        },
                        child: _NotificationCard(
                          notification: item is Map ? Map<String, dynamic>.from(item) : {'title': item.toString()},
                          onTap: () {
                            if (item is Map) {
                              if (item['_id'] != null) {
                                controller.markNotificationAsRead(item['_id'].toString());
                              }
                              final propId = (item['propertyId'] ?? item['property']?['_id'] ?? item['data']?['propertyId'])?.toString();
                              if (propId != null && propId.isNotEmpty) {
                                Get.toNamed(AppRoutes.propertyDetails, arguments: {'propertyId': propId});
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ??
        notification['body']?.toString() ??
        notification['description']?.toString() ??
        '';
    final time = notification['createdAt']?.toString() ?? notification['date']?.toString() ?? '';
    final isRead = notification['isRead'] == true || notification['read'] == true;
    final type = (notification['type']?.toString() ?? '').toLowerCase();
    final category = notification['category']?.toString() ??
        (type.contains('price')
            ? 'PRICE ALERT'
            : type.contains('visit')
            ? 'SITE VISIT'
            : type.contains('enquiry')
            ? 'INQUIRY'
            : type.contains('verified')
            ? 'VERIFIED'
            : 'PROPERTY');

    final propId = (notification['propertyId'] ??
        notification['property']?['_id'] ??
        notification['data']?['propertyId'])
        ?.toString();

    IconData iconData = Icons.notifications_rounded;
    Color iconColor = const Color(0xFF007A5E);
    Color iconBg = const Color(0xFF007A5E).withValues(alpha: 0.1);

    if (type.contains('property') || type.contains('listing')) {
      iconData = Icons.home_work_rounded;
      iconColor = const Color(0xFF3B82F6);
      iconBg = const Color(0xFF3B82F6).withValues(alpha: 0.1);
    } else if (type.contains('visit') || type.contains('schedule')) {
      iconData = Icons.calendar_month_rounded;
      iconColor = const Color(0xFF8B5CF6);
      iconBg = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
    } else if (type.contains('offer') || type.contains('price') || type.contains('discount')) {
      iconData = Icons.local_offer_rounded;
      iconColor = const Color(0xFFF59E0B);
      iconBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
    } else if (type.contains('verified') || type.contains('rera')) {
      iconData = Icons.verified_rounded;
      iconColor = const Color(0xFF10B981);
      iconBg = const Color(0xFF10B981).withValues(alpha: 0.1);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isRead
                ? const Color(0xFF007A5E).withValues(alpha: 0.3)
                : const Color(0xFF007A5E),
            width: isRead ? 1 : 1.4,
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
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          margin: EdgeInsets.only(left: 6.w),
                          decoration: const BoxDecoration(
                            color: Color(0xFF007A5E),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF475569),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (time.isNotEmpty)
                        Text(
                          _formatDate(time),
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (propId != null && propId.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              'View Property',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF007A5E),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10.sp,
                              color: const Color(0xFF007A5E),
                            ),
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return raw;
    }
  }
}
