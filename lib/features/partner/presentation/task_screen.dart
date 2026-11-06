import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../features/partner/models/partner_models.dart';
import '../../../core/routes/app_routes.dart';
import 'partner_bottom_sheets.dart';
import '../../../core/utils/shimmer.dart';

import 'widgets/partner_ui.dart';
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'In Progress',
    'Site Visit Due',
    'Doc Review',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final c = ensurePartnerHomeController();

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.agentAddProperty),
        backgroundColor: PartnerColors.brand,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          '+ Add Property',
          style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final unassigned = c.unassignedProperties;

          final pendingVisits = c.partnerUpcomingVisitsCount;
          final docReviews = c.propReviewCount;
          final completed = c.partnerCompletedVisitsCount;

          List<PartnerVisit> visits = c.visits;
          if (_selectedFilter == 'In Progress') {
            visits = c.visits.where((v) =>
                !v.status.toLowerCase().contains('complete') &&
                !v.status.toLowerCase().contains('cancel')).toList();
          } else if (_selectedFilter == 'Site Visit Due') {
            visits = c.visits.where((v) =>
                v.status.toLowerCase().contains('schedul') ||
                v.status.toLowerCase().contains('pend') ||
                v.status.toLowerCase().contains('request')).toList();
          } else if (_selectedFilter == 'Doc Review') {
            visits = c.visits.where((v) =>
                v.status.toLowerCase().contains('review') ||
                v.status.toLowerCase().contains('doc')).toList();
          } else if (_selectedFilter == 'Completed') {
            visits = c.visits.where((v) =>
                v.status.toLowerCase().contains('complete')).toList();
          }

          return RefreshIndicator(
            onRefresh: c.loadTasks,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 88.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  Text(
                    'Seller Assignments',
                    style: PartnerText.title(21),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Verify & manage seller properties to earn partner brokerage',
                    style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
                  ),

                  SizedBox(height: 14.h),

                  // 3 Metric Counters
                  Row(
                    children: [
                      _metricCounter(
                        label: 'Pending Visit',
                        value: '$pendingVisits',
                        icon: Icons.directions_walk_rounded,
                        color: const Color(0xFFD9961F),
                        bgColor: const Color(0xFFFFFBEB),
                      ),
                      SizedBox(width: 8.w),
                      _metricCounter(
                        label: 'Doc Review',
                        value: '$docReviews',
                        icon: Icons.folder_open_rounded,
                        color: const Color(0xFF0A5C4A),
                        bgColor: const Color(0xFFE8F3EF),
                      ),
                      SizedBox(width: 8.w),
                      _metricCounter(
                        label: 'Completed',
                        value: '$completed',
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF129B6C),
                        bgColor: const Color(0xFFE6F5EE),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Horizontal Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: _filters.map((f) {
                        final isSel = _selectedFilter == f;
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFilter = f),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF0A5C4A) : Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF0A5C4A) : const Color(0xFFC9D2DB),
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? Colors.white : const Color(0xFF0B1B2E),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  if (c.isTeamOwner.value && c.teamPendingVisits.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sub-Agent Pending Visits (Owner Review)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1B2E),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: const Color(0xFFD9961F)),
                          ),
                          child: Text(
                            '${c.teamPendingVisits.length} Actionable',
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFFD9961F)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...c.teamPendingVisits.map((v) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _teamPendingVisitCard(context, c, v),
                        )),
                    SizedBox(height: 14.h),
                  ],
                  if (visits.isEmpty && unassigned.isEmpty && c.teamPendingVisits.isEmpty)
                    _emptyTasksState(context)
                  else ...[
                    if (visits.isNotEmpty) ...[
                      Text(
                        'Assigned Partner Visits',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1B2E),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...visits.map((v) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: _backendVisitCard(context, c, v),
                          )),
                      SizedBox(height: 14.h),
                    ],
                    if (unassigned.isNotEmpty) ...[
                      Text(
                        'Unassigned Seller Properties',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0B1B2E),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...unassigned.map((p) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: _unassignedPropertyCard(p),
                          )),
                    ],
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _metricCounter({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: PartnerShadows.card,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16.sp, color: color),
            ),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B1B2E),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.sp, color: PartnerColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unassignedPropertyCard(PartnerProperty p) {
    return InkWell(
      onTap: () => Get.toNamed(
        AppRoutes.agentAddProperty,
        arguments: {'assignedPropertyId': p.id, 'title': p.title, 'city': p.city},
      ),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: PartnerShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.home_work_outlined, color: const Color(0xFF0A5C4A), size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    p.city.isEmpty ? p.status : '${p.city} • ${p.status}',
                    style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.toNamed(
                AppRoutes.agentAddProperty,
                arguments: {'assignedPropertyId': p.id, 'title': p.title, 'city': p.city},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C4A),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('Claim & List', style: TextStyle(fontSize: 11.sp, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backendVisitCard(BuildContext context, PartnerHomeController c, PartnerVisit v) {
    return InkWell(
      onTap: () => showContactSellerSheet(
        context,
        sellerName: v.buyerName,
        propertyTitle: v.propertyTitle,
      ),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: PartnerShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    v.propertyTitle,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EF),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    v.status,
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0A5C4A)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Buyer: ${v.buyerName} • ${v.scheduledAt.isEmpty ? "Today" : v.scheduledAt}',
              style: TextStyle(fontSize: 11.sp, color: PartnerColors.textSecondary),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => showContactSellerSheet(
                      context,
                      sellerName: v.buyerName,
                      propertyTitle: v.propertyTitle,
                    ),
                    child: Text('Contact', style: TextStyle(fontSize: 11.5.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showUpdateVisitStatusSheet(context, visit: v),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white),
                    label: Text('Update Status', style: TextStyle(fontSize: 11.5.sp, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C4A)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamPendingVisitCard(BuildContext context, PartnerHomeController c, PartnerVisit v) {
    return InkWell(
      onTap: () => c.reviewTeamPendingVisit(v.id, 'Forward'),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: PartnerShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    v.propertyTitle,
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'PENDING OWNER REVIEW',
                    style: TextStyle(fontSize: 9.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFFD9961F)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Buyer: ${v.buyerName} • Scheduled: ${v.scheduledAt.isEmpty ? "Pending" : v.scheduledAt}',
              style: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textSecondary),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => c.reviewTeamPendingVisit(v.id, 'Forward'),
                    icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                    label: Text('Forward to Admin', style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C4A)),
                  ),
                ),
                SizedBox(width: 8.w),
                OutlinedButton.icon(
                  onPressed: () => c.reviewTeamPendingVisit(v.id, 'Reject'),
                  icon: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                  label: Text('Reject', style: TextStyle(fontSize: 11.sp, color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTasksState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: PartnerShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3EF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_turned_in_rounded, size: 36.sp, color: const Color(0xFF0A5C4A)),
          ),
          SizedBox(height: 12.h),
          Text(
            'All Tasks Caught Up!',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B1B2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'You have no pending site visits or seller document verifications.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
