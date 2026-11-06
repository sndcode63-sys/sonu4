import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_pill_search_bar.dart';
import '../../../features/partner/controllers/partner_home_controller.dart';
import '../../../features/partner/models/partner_models.dart';
import '../../../core/routes/app_routes.dart';
import 'partner_bottom_sheets.dart';
import '../../../core/utils/shimmer.dart';

import 'widgets/partner_ui.dart';

class AgentLeadsScreen extends StatefulWidget {
  const AgentLeadsScreen({super.key});

  @override
  State<AgentLeadsScreen> createState() => _AgentLeadsScreenState();
}

class _AgentLeadsScreenState extends State<AgentLeadsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => _searchQuery.value = _searchCtrl.text.trim());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PartnerTheme(child: Builder(builder: _partnerBody));

  Widget _partnerBody(BuildContext context) {
    final c = ensurePartnerHomeController();

    return Scaffold(
      backgroundColor: PartnerColors.canvas,
      body: SafeArea(
        child: Obx(() {
          final dash = c.leadsDashboard.value;
          final allLeads = c.filteredLeads;
          final q = _searchQuery.value.toLowerCase();
          final leads = q.isEmpty
              ? allLeads
              : allLeads.where((l) =>
                  l.buyerName.toLowerCase().contains(q) ||
                  l.propertyTitle.toLowerCase().contains(q) ||
                  l.phone.contains(q) ||
                  l.location.toLowerCase().contains(q)).toList();
          final availableLeads = c.leads.where((l) => !l.isUnlocked).toList();
          final unlockedLeads = c.leads.where((l) => l.isUnlocked).toList();
          final availableCount = dash?.available ?? availableLeads.length;
          final unlockedCount = dash?.unlocked ?? unlockedLeads.length;
          final followUpCount = dash?.followUp ?? 0;
          final closedCount = dash?.converted ?? 0;

          return RefreshIndicator(
            onRefresh: c.loadLeads,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 88.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle + Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buyer Leads',
                              style: PartnerText.title(21),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              'Unlock verified buyer contacts & schedule site visits',
                              style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // ElevatedButton.icon(
                      //   onPressed: () => showCreateManualLeadSheet(context),
                      //   icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      //   label: Text(
                      //     'Add Lead',
                      //     style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      //   ),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: const Color(0xFF0A5C4A),
                      //     padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      //     elevation: 0,
                      //   ),
                      // ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Credit Banner
                  _creditBanner(context, c),

                  SizedBox(height: 14.h),

                  // 4 Metric Counters
                  Row(
                    children: [
                      _counter('New Leads', '$availableCount', Icons.person_search_outlined, const Color(0xFF0A5C4A), const Color(0xFFE8F3EF)),
                      SizedBox(width: 6.w),
                      _counter('Unlocked', '$unlockedCount', Icons.lock_open_rounded, const Color(0xFF3B7DD8), const Color(0xFFE9F0FB)),
                      SizedBox(width: 6.w),
                      _counter('Site Visits', '$followUpCount', Icons.directions_walk_rounded, const Color(0xFFD9961F), const Color(0xFFFFFBEB)),
                      SizedBox(width: 6.w),
                      _counter('Closed', '$closedCount', Icons.verified_rounded, const Color(0xFF129B6C), const Color(0xFFE6F5EE)),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Floating Search Bar
                  AppPillSearchBar(
                    controller: _searchCtrl,
                    hintText: 'Search leads by buyer name, phone, or title...',
                    onChanged: (v) => _searchQuery.value = v,
                    onClear: () => _searchQuery.value = '',
                  ),

                  SizedBox(height: 14.h),

                  // Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: [
                        _filterTab(c, 'Available', availableCount),
                        SizedBox(width: 8.w),
                        _filterTab(c, 'Unlocked', unlockedCount),
                        SizedBox(width: 8.w),
                        _filterTab(c, 'Follow-ups', followUpCount),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  if (c.leadsLoading.value)
                    Padding(
                      padding: EdgeInsets.all(40),
                      child: ShimmerGroup(
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: ShimmerBox(
                                height: 130.h,
                                width: double.infinity,
                                borderRadius: 16.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (leads.isEmpty)
                    _emptyLeadsState(context)
                  else ...[
                    ...leads.map((lead) => Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: _dynamicLeadCard(context, c, lead),
                        )),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _creditBanner(BuildContext context, PartnerHomeController c) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: PartnerShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: PartnerColors.goldSoft,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, size: 22.sp, color: PartnerColors.gold),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${c.creditBalance.value}',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1B2E),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        'Credits Available',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: PartnerColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.creditGuidelines),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Unlock lead: 25 Credits',
                          style: TextStyle(fontSize: 10.5.sp, color: const Color(0xFF0A5C4A), fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(Icons.info_outline_rounded, size: 12.sp, color: const Color(0xFF0A5C4A)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () => showTopUpCreditsSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5C4A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('+ Top Up', style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _counter(String label, String value, IconData icon, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        decoration: BoxDecoration(
          border: Border.all(color: PartnerColors.line),
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
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
              child: Icon(icon, size: 15.sp, color: textColor),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B1B2E),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5.sp, color: PartnerColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(PartnerHomeController c, String tab, int count) {
    final selected = c.leadsTab.value.toLowerCase() == tab.toLowerCase() ||
        (tab == 'Follow-ups' && c.leadsTab.value.toLowerCase().contains('follow'));
    return GestureDetector(
      onTap: () => c.leadsTab.value = tab == 'Follow-ups' ? 'Follow-up' : tab,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? PartnerColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? PartnerColors.brand : PartnerColors.line,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x290A5C4A), blurRadius: 10, offset: Offset(0, 4))]
              : null,
        ),
        child: Text(
          '$tab ($count)',
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF0B1B2E),
          ),
        ),
      ),
    );
  }

  Widget _emptyLeadsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E8ED)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x080B1B2E),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3EF),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_rounded, size: 36.sp, color: const Color(0xFF0A5C4A)),
          ),
          SizedBox(height: 12.h),
          Text(
            'No Buyer Leads Yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0B1B2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'When prospective buyers inquire about properties in your territory, verified leads will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: PartnerColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _dynamicLeadCard(BuildContext context, PartnerHomeController c, PartnerLead lead) {
    final unlocked = lead.isUnlocked;
    void openCard() {
      if (unlocked) {
        showContactSellerSheet(
          context,
          sellerName: lead.buyerName,
          phone: lead.phone,
          propertyTitle: lead.propertyTitle,
        );
      } else {
        c.unlockLead(lead);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: PartnerShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header (tap = open / unlock) ----------
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: openCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PartnerIconChip(
                      icon: unlocked ? Icons.person_rounded : Icons.lock_outline_rounded,
                      color: unlocked ? PartnerColors.success : PartnerColors.brand,
                      background: unlocked ? PartnerColors.successTint : PartnerColors.brandTint,
                      size: 42,
                      iconSize: 21,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unlocked ? '${lead.buyerName} • ${lead.phone}' : lead.propertyTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: PartnerText.title(14),
                          ),
                          SizedBox(height: 6.h),
                          Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              unlocked
                                  ? const PartnerStatusChip(
                                      label: 'Unlocked',
                                      tone: PartnerTone.success,
                                      icon: Icons.lock_open_rounded,
                                      dense: true,
                                    )
                                  : const PartnerStatusChip(
                                      label: 'Verified inquiry',
                                      tone: PartnerTone.brand,
                                      icon: Icons.verified_rounded,
                                      dense: true,
                                    ),
                              if (lead.status.trim().isNotEmpty)
                                PartnerStatusChip(
                                  label: lead.status,
                                  tone: PartnerTone.neutral,
                                  dense: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------- Info strip ----------
          Container(
            margin: EdgeInsets.symmetric(horizontal: 14.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: PartnerColors.canvas,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _leadInfo(Icons.location_on_outlined, 'Location', lead.location),
                ),
                Container(width: 1, height: 28.h, color: PartnerColors.line),
                SizedBox(width: 12.w),
                Expanded(
                  child: _leadInfo(Icons.account_balance_wallet_outlined, 'Budget', lead.budget),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ---------- Actions ----------
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: unlocked
                ? _unlockedLeadActions(context, c, lead)
                : _lockedLeadActions(context, c, lead),
          ),
        ],
      ),
    );
  }

  Widget _leadInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: PartnerColors.textTertiary),
        SizedBox(width: 6.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: PartnerText.body(9.5, color: PartnerColors.textTertiary, weight: FontWeight.w600)),
              SizedBox(height: 1.h),
              Text(
                value.trim().isEmpty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PartnerText.body(11.5, color: PartnerColors.ink, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lockedLeadActions(BuildContext context, PartnerHomeController c, PartnerLead lead) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: c.unlockLoading.value ? null : () => c.unlockLead(lead),
            icon: Icon(Icons.lock_open_rounded, size: 16.sp, color: Colors.white),
            label: Text(
              'Unlock Contact • ${lead.unlockCost} Credits',
              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: PartnerColors.brand,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => showRejectLeadSheet(context, lead: lead),
            icon: Icon(Icons.close_rounded, size: 14.sp, color: PartnerColors.textSecondary),
            label: Text(
              'Not Interested / Reject',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: PartnerColors.textSecondary),
            ),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
      ],
    );
  }

  Widget _leadBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r));
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: filled ? Colors.white : color,
      ),
    );
    final ic = Icon(icon, size: 15.sp, color: filled ? Colors.white : color);
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: ic,
        label: text,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
          shape: shape,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: ic,
      label: text,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        backgroundColor: color.withValues(alpha: 0.04),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
        shape: shape,
      ),
    );
  }

  Widget _unlockedLeadActions(BuildContext context, PartnerHomeController c, PartnerLead lead) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: _leadBtn(
                label: 'Call',
                icon: Icons.phone_rounded,
                color: PartnerColors.brand,
                filled: true,
                onTap: () => showContactSellerSheet(
                  context,
                  sellerName: lead.buyerName,
                  phone: lead.phone,
                  propertyTitle: lead.propertyTitle,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 4,
              child: _leadBtn(
                label: 'Follow Up',
                icon: Icons.update_rounded,
                color: PartnerColors.brand,
                onTap: () => c.setLeadStatus(lead, 'Follow_Up'),
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              height: 40.h,
              width: 42.w,
              child: OutlinedButton(
                onPressed: () => _showScheduleVisitDialog(
                  context,
                  c,
                  buyerName: lead.buyerName,
                  propertyTitle: lead.propertyTitle,
                  buyerId: lead.buyerId,
                  propertyId: lead.propertyId,
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: PartnerColors.brand.withValues(alpha: 0.35)),
                  backgroundColor: PartnerColors.brand.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Icon(Icons.event_available_outlined, size: 18.sp, color: PartnerColors.brand),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _leadBtn(
                label: 'Note',
                icon: Icons.edit_note_rounded,
                color: PartnerColors.textSecondary,
                onTap: () => showAddContactHistorySheet(context, lead: lead),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _leadBtn(
                label: 'Convert',
                icon: Icons.check_circle_outline_rounded,
                color: PartnerColors.success,
                onTap: () => showConvertLeadSheet(context, lead: lead),
              ),
            ),
            if (c.isTeamOwner.value) ...[
              SizedBox(width: 8.w),
              Expanded(
                child: _leadBtn(
                  label: lead.isAllocatedToSubAgent ? 'Reassign' : 'Assign',
                  icon: Icons.person_add_alt_1_outlined,
                  color: PartnerColors.info,
                  onTap: () => showAllocateLeadSheet(context, lead: lead),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 6.h),
        Divider(height: 1, color: PartnerColors.lineSoft),
        SizedBox(height: 4.h),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => showRejectLeadSheet(context, lead: lead),
                icon: Icon(Icons.cancel_outlined, size: 14.sp, color: PartnerColors.danger),
                label: Text('Reject', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: PartnerColors.danger)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
            Container(width: 1, height: 18.h, color: PartnerColors.lineSoft),
            Expanded(
              child: TextButton.icon(
                onPressed: () => showCloseLeadSheet(context, lead: lead),
                icon: Icon(Icons.archive_outlined, size: 14.sp, color: PartnerColors.textSecondary),
                label: Text('Close', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: PartnerColors.textSecondary)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showScheduleVisitDialog(
    BuildContext context,
    PartnerHomeController c, {
    required String buyerName,
    required String propertyTitle,
    String? buyerId,
    String? propertyId,
  }) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '11:00 AM';
    String? chosenPropertyId = (propertyId != null && propertyId.isNotEmpty)
        ? propertyId
        : (c.properties.isNotEmpty ? c.properties.first.id : null);
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
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
                        Text(
                          'Schedule Site Visit',
                          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Buyer: $buyerName • $propertyTitle',
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0A5C4A), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Visit Date',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                    ),
                    SizedBox(height: 6.h),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF0A5C4A),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF0B1B2E),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FA),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFE3E8ED)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16.sp, color: const Color(0xFF0A5C4A)),
                            SizedBox(width: 8.w),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
                              style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0B1B2E)),
                            ),
                            const Spacer(),
                            Icon(Icons.edit_calendar_outlined, size: 16.sp, color: PartnerColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Select Preferred Time Slot',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: ['10:00 AM', '11:30 AM', '02:00 PM', '04:30 PM', '06:00 PM'].map((slot) {
                        final isSel = selectedSlot == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedSlot = slot);
                          },
                          labelStyle: TextStyle(
                            fontSize: 11.5.sp,
                            color: isSel ? Colors.white : PartnerColors.ink,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          selectedColor: const Color(0xFF0A5C4A),
                        );
                      }).toList(),
                    ),
                    if (propertyId == null && c.properties.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      Text(
                        'Select Property for Visit',
                        style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FA),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFE3E8ED)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: chosenPropertyId,
                            isExpanded: true,
                            items: c.properties.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(
                                  '${p.title} (${p.city})',
                                  style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0B1B2E)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => chosenPropertyId = val);
                            },
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 14.h),
                    Text(
                      'Special Visit Instructions / Notes',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0B1B2E)),
                    ),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Buyer interested in seeing club house & parking spot',
                        hintStyle: TextStyle(fontSize: 11.5.sp, color: PartnerColors.textTertiary),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: Color(0xFFE3E8ED)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final targetPropId = chosenPropertyId ?? propertyId;
                          if (targetPropId == null || targetPropId.isEmpty) {
                            Get.snackbar(
                              'Property Required',
                              'Please link a property to schedule this site visit.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await c.createVisitRequest(
                            propertyId: targetPropId,
                            buyerId: buyerId,
                            requestedVisitAt: selectedDate,
                            notes: '${notesCtrl.text.trim()} (Time: $selectedSlot)',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A5C4A),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm & Schedule Visit',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
