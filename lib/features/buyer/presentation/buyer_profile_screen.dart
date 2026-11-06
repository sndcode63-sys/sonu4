import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';
import '../controllers/buyer_home_controller.dart';
import 'notification_screen.dart';
import 'property_details_screen.dart';
import 'my_inquiries_screen.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/services/account_service.dart';
import '../../../core/widgets/app_dotted_border.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/delete_account_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/logout_confirmation_dialog.dart';
import '../../../core/widgets/app_adaptive_back_button.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoggingOut = false;

  late final BuyerHomeController _controller;

  String _name = 'Guest';
  String _phone = '';
  String? _email;
  String _role = 'Buyer';
  String? _avatarUrl;
  String? _localAvatarPath;
  String? _buyerId;

  int _recentlyViewedCount = 0;
  int _scheduledVisitsCount = 0;
  int _enquiriesCount = 0;

  static const Color _green = Color(0xFF007A5E);
  static const Color _greenSoft = Color(0xFFE8F7F2);
  static const Color _greenLine = Color(0xFFCBEFE0);
  static const Color _tile = Color(0xFFF4FAF8);

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<BuyerHomeController>()
        ? Get.find<BuyerHomeController>()
        : Get.put(BuyerHomeController(), permanent: true);

    final inMemoryUser = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().state.value.userData
        : null;
    final headerUser = _controller.dashboardHeader.value?.user;

    if (inMemoryUser != null) {
      final name = (inMemoryUser['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) _name = name;
      final phone = (inMemoryUser['phone'] as String?)?.trim();
      if (phone != null && phone.isNotEmpty) _phone = phone;
      final email = (inMemoryUser['email'] as String?)?.trim();
      if (email != null && email.isNotEmpty) _email = email;
      final role = (inMemoryUser['role'] as String?)?.trim();
      if (role != null && role.isNotEmpty) _role = role;
      final avatar = (inMemoryUser['avatar'] as String?)?.trim();
      if (avatar != null && avatar.isNotEmpty) _avatarUrl = avatar;
      _buyerId = inMemoryUser['id']?.toString() ??
          inMemoryUser['_id']?.toString() ??
          inMemoryUser['buyerId']?.toString();
    } else if (headerUser != null) {
      if (headerUser.name != null && headerUser.name!.isNotEmpty) _name = headerUser.name!;
      if (headerUser.avatar != null && headerUser.avatar!.isNotEmpty) _avatarUrl = headerUser.avatar!;
    }

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    Map<String, dynamic>? userData = Get.find<AuthController>().state.value.userData;
    userData ??= await Get.find<AuthRepository>().getStoredSession();
    userData ??= await _readSecureUser();

    if (userData != null) {
      final name = (userData['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) _name = name;
      final phone = (userData['phone'] as String?)?.trim();
      if (phone != null && phone.isNotEmpty) _phone = phone;
      final email = (userData['email'] as String?)?.trim();
      if (email != null && email.isNotEmpty) _email = email;
      final role = (userData['role'] as String?)?.trim();
      if (role != null && role.isNotEmpty) _role = role;
      final avatar = (userData['avatar'] as String?)?.trim();
      if (avatar != null && avatar.isNotEmpty) _avatarUrl = avatar;
      _buyerId = userData['id']?.toString() ??
          userData['_id']?.toString() ??
          userData['buyerId']?.toString();
    }

    if (_buyerId == null || _buyerId!.isEmpty) {
      _buyerId = await StorageService.instance.buyerId;
    }
    if (_buyerId == null || _buyerId!.isEmpty) {
      _buyerId = await StorageService.instance.userId;
    }

    _localAvatarPath = await StorageService.instance.localAvatarPath;

    final recentlyViewed = await StorageService.instance.getRecentlyViewedIds();
    final visits = await StorageService.instance.getVisitIds();
    final enquiries = await StorageService.instance.getEnquiryIds();

    if (!mounted) return;
    setState(() {
      _recentlyViewedCount = recentlyViewed.length;
      _scheduledVisitsCount = visits.length;
      _enquiriesCount = enquiries.length;
    });

    if (_controller.dashboardHeader.value == null) {
      unawaited(_controller.loadDashboardHeader());
    }

    if (_buyerId != null && _buyerId!.isNotEmpty) {
      unawaited(_controller.fetchSavedProperties(_buyerId!));
    }
  }

  Future<Map<String, dynamic>?> _readSecureUser() async {
    final raw = await SecureStorageService.instance.getUserData();
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _isLoggingOut = true);
    await Get.find<AuthController>().logout();
    await StorageService.instance.clearSession();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    AppToast.success(context, 'Logged out successfully');
    if (!context.mounted) return;
    Get.offAllNamed(AppRoutes.chooseRole);
  }

  Future<void> _confirmDeleteAccount() async {
    final deleted = await DeleteAccountDialog.show(
      context,
      roleName: 'Buyer',
      onConfirmDelete: (reason) async {
        await AccountService.instance.deleteAccount(reason: reason);
        await AccountService.instance.clearAllSessionData();
      },
    );

    if (deleted == true && mounted) {
      Get.offAllNamed(AppRoutes.chooseRole);
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar(
          'Account Deleted',
          'Account deleted successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF0F172A),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: SafeArea(
          top: false,
          bottom: true,
          child: RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 120.h),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(height: 20.h),
                  _buildStatsGrid(),
                  SizedBox(height: 24.h),
                  _buildSavedSectionHeader(),
                  SizedBox(height: 12.h),
                  _buildSavedPropertiesSection(),
                  SizedBox(height: 20.h),

                  // 1. Activity & Visits Grouped Card (Dividers in between)
                  _buildGroupedMenuCard([
                    _MenuRowData(
                      icon: Icons.calendar_today_outlined,
                      iconBgColor: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Scheduled Visits',
                      onTap: () => Get.to(() => const ScheduledVisitsScreen())?.then((_) => _loadProfile()),
                    ),
                    _MenuRowData(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBgColor: _greenSoft,
                      iconColor: _green,
                      title: 'My Inquiries',
                      onTap: () => Get.to(() => const MyInquiriesScreen())?.then((_) => _loadProfile()),
                    ),
                    _MenuRowData(
                      icon: Icons.favorite_rounded,
                      iconBgColor: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Saved Properties',
                      onTap: () => _controller.changeBottomNavIndex(3),
                    ),
                    _MenuRowData(
                      icon: Icons.history_rounded,
                      iconBgColor: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Recently Viewed',
                      onTap: () => Get.toNamed(AppRoutes.recentlyViewed)?.then((_) => _loadProfile()),
                    ),
                  ]),

                  SizedBox(height: 16.h),

                  // 2. Account & Legal Grouped Card (Dividers in between)
                  _buildGroupedMenuCard([
                    _MenuRowData(
                      icon: Icons.description_outlined,
                      iconBgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      title: 'Terms of Service',
                      onTap: () => Get.toNamed(AppRoutes.termsOfService),
                    ),
                    _MenuRowData(
                      icon: Icons.shield_outlined,
                      iconBgColor: const Color(0xFFE0E7FF),
                      iconColor: const Color(0xFF4F46E5),
                      title: 'Privacy Policy',
                      onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                    ),
                    _MenuRowData(
                      icon: Icons.logout_rounded,
                      iconBgColor: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFE11D48),
                      title: _isLoggingOut ? 'Logging out...' : 'Log Out',
                      titleColor: const Color(0xFFE11D48),
                      onTap: _isLoggingOut ? () {} : _confirmLogout,
                      trailing: _isLoggingOut
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE11D48)),
                            )
                          : null,
                    ),
                    _MenuRowData(
                      icon: Icons.delete_forever_rounded,
                      iconBgColor: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Delete Account',
                      titleColor: const Color(0xFFDC2626),
                      onTap: _confirmDeleteAccount,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 48.w + 10.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 10.w),
        child: AppAdaptiveBackButton(
          color: const Color(0xFF0F172A),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _controller.changeBottomNavIndex(0);
            }
          },
        ),
      ),
      title: Text(
        'Profile',
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      centerTitle: true,
      actions: [
        InkWell(
          onTap: () => Get.to(() => const NotificationScreen()),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Obx(() {
              final unread = _controller.dashboardHeader.value?.unreadNotificationsCount ??
                  _controller.unreadNotificationsCount.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: const Color(0xFF0F172A),
                    size: 22.sp,
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -4.h,
                      right: -4.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: unread > 9 ? 4.w : 1.w, vertical: 1.h),
                        constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        SizedBox(width: 12.w),
        _buildAppBarAvatar(),
        SizedBox(width: 10.w),
      ],
    );
  }

  Widget _buildAppBarAvatar() {
    return Obx(() {
      final networkAvatar = _controller.dashboardHeader.value?.user?.avatar ?? _avatarUrl;
      return CircleAvatar(
        radius: 14.r,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: _avatarImageProvider(networkAvatar),
        child: _avatarImageProvider(networkAvatar) == null
            ? Icon(Icons.person_rounded, size: 16.sp, color: const Color(0xFF94A3B8))
            : null,
      );
    });
  }

  ImageProvider? _avatarImageProvider(String? networkAvatar) {
    final local = _controller.userAvatarLocalPath.value.isNotEmpty
        ? _controller.userAvatarLocalPath.value
        : _localAvatarPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      return FileImage(File(local));
    }
    final net = _controller.userAvatarNetworkUrl.value.isNotEmpty
        ? _controller.userAvatarNetworkUrl.value
        : networkAvatar;
    if (net != null && net.isNotEmpty) {
      return NetworkImage(net);
    }
    return null;
  }

  Future<void> _showPhotoPickerSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: _greenLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Text(
              'Change Profile Picture',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Choose a new photo to display on your profile and home header',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImage(ImageSource.camera);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: AppDottedBorder(
                      radius: 16.r,
                      color: _green,
                      backgroundColor: const Color(0xFFF8FAF9),
                      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: _greenSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt_rounded, color: _green, size: 24.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Take Photo',
                            style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                          Text('Camera', style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImage(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: AppDottedBorder(
                      radius: 16.r,
                      color: const Color(0xFF0284C7),
                      backgroundColor: const Color(0xFFF8FAFC),
                      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE0F2FE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 24.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Upload Gallery',
                            style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                          Text('PNG, JPG', style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if ((_localAvatarPath != null && _localAvatarPath!.isNotEmpty) ||
                _controller.userAvatarLocalPath.value.isNotEmpty) ...[
              SizedBox(height: 12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: const Color(0xFFE11D48), size: 20.sp),
                ),
                title: Text('Remove Photo',
                    style: GoogleFonts.poppins(
                        fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFFE11D48))),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _controller.updateProfileAvatar('');
                  setState(() => _localAvatarPath = null);
                  if (mounted) {
                    AppToast.success(context, 'Profile picture removed');
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        await _controller.updateProfileAvatar(picked.path);
        setState(() => _localAvatarPath = picked.path);
        if (mounted) {
          AppToast.success(context, 'Profile picture updated successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not select photo: $e');
      }
    }
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final headerUser = _controller.dashboardHeader.value?.user;
      final displayName = (headerUser?.name != null && headerUser!.name!.trim().isNotEmpty)
          ? headerUser.name!
          : _name;
      final avatar = headerUser?.avatar ?? _avatarUrl;

      return Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 42.r,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: _avatarImageProvider(avatar),
                  child: _avatarImageProvider(avatar) == null
                      ? Icon(Icons.person_rounded, size: 38.sp, color: const Color(0xFF94A3B8))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _showPhotoPickerSheet,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            displayName,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 3.h),
          if (_phone.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined, size: 12.sp, color: const Color(0xFF64748B)),
                SizedBox(width: 4.w),
                Text(
                  _phone,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (_email != null && _email!.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline_rounded, size: 12.sp, color: const Color(0xFF64748B)),
                SizedBox(width: 4.w),
                Text(
                  _email!,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _greenSoft,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _greenLine, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 12.sp, color: _green),
                SizedBox(width: 4.w),
                Text(
                  '$_role Account',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _tile,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _greenLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildStatItem(
                  'SAVED PROPERTIES',
                  '${_controller.savedPropertiesList.length}',
                  Icons.bookmark_border_rounded,
                  onTap: () => _controller.changeBottomNavIndex(3),
                )),
              ),
              Container(width: 1, height: 44.h, color: _greenLine),
              Expanded(
                child: _buildStatItem(
                  'RECENTLY VIEWED',
                  '$_recentlyViewedCount',
                  Icons.history_rounded,
                  onTap: () => Get.toNamed(AppRoutes.recentlyViewed)?.then((_) => _loadProfile()),
                ),
              ),
            ],
          ),
          Divider(height: 20.h, thickness: 0.8, color: _greenLine),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'SCHEDULED VISITS',
                  '$_scheduledVisitsCount',
                  Icons.calendar_today_outlined,
                  onTap: () => Get.to(() => const ScheduledVisitsScreen())?.then((_) => _loadProfile()),
                ),
              ),
              Container(width: 1, height: 44.h, color: _greenLine),
              Expanded(
                child: _buildStatItem(
                  'MY ENQUIRIES',
                  '$_enquiriesCount',
                  Icons.chat_bubble_outline_rounded,
                  onTap: () => Get.to(() => const MyInquiriesScreen())?.then((_) => _loadProfile()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ],
            ),
            Icon(icon, size: 20.sp, color: _green.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Saved Properties',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        InkWell(
          onTap: () => _controller.changeBottomNavIndex(3),
          child: Text(
            'View All ›',
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPropertiesSection() {
    return Obx(() {
      if (_controller.savedPropertiesLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: const Center(child: CircularProgressIndicator(color: _green)),
        );
      }

      final saved = _controller.savedPropertiesList;
      if (saved.isEmpty) {
        return AppEmptyState(
          type: EmptyStateType.saved,
          imageSize: 85,
          title: 'No Saved Properties',
          message: 'Tap the heart icon on any property to save it here for quick access.',
          actionLabel: 'Explore Homes',
          onAction: () => _controller.changeBottomNavIndex(0),
        );
      }

      final preview = saved.take(2).toList();
      return Column(
        children: [
          for (int i = 0; i < preview.length; i++) ...[
            _buildPropertyCardFromItem(preview[i]),
            if (i != preview.length - 1) SizedBox(height: 14.h),
          ],
        ],
      );
    });
  }

  Widget _buildPropertyCardFromItem(dynamic item) {
    final propertyData = (item is Map && item['propertySnapshot'] != null)
        ? item['propertySnapshot']
        : (item is Map && item['property'] != null ? item['property'] : item);

    final title = (propertyData is Map ? propertyData['title'] : null)?.toString() ?? 'Property';
    final locality = (propertyData is Map ? propertyData['locality'] : null)?.toString() ?? '';
    final city = (propertyData is Map ? propertyData['city'] : null)?.toString() ?? '';
    final location = [locality, city].where((s) => s.isNotEmpty).join(', ');
    final rawPrice = propertyData is Map ? propertyData['price'] : null;
    final price = rawPrice == null ? '—' : formatPrice(rawPrice);
    final bhk = (propertyData is Map ? (propertyData['bedrooms'] ?? propertyData['bhk']) : null)?.toString();
    final sqft = (propertyData is Map ? (propertyData['area'] ?? propertyData['sqft']) : null)?.toString();
    final isVerified = propertyData is Map &&
        (propertyData['propertyVerificationStatus'] == 'verified' || propertyData['isVerified'] == true);

    String? imageUrl;
    if (propertyData is Map) {
      imageUrl = propertyData['image']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        final images = propertyData['images'];
        if (images is List && images.isNotEmpty) {
          final firstImg = images.first;
          if (firstImg is Map) {
            imageUrl = firstImg['url']?.toString();
          } else if (firstImg is String) {
            imageUrl = firstImg;
          }
        }
      }
    }

    return _buildPropertyCard(
      title: title,
      location: location.isNotEmpty ? location : '—',
      price: price,
      bhk: bhk != null ? '$bhk BHK' : '—',
      sqft: sqft != null ? '$sqft Sq Ft' : '—',
      tag: isVerified ? 'Verified' : 'Saved',
      isVerified: isVerified,
      tagColor: isVerified ? _green : const Color(0xFF0F172A),
      image: imageUrl,
      onTap: () {
        Get.toNamed(
          AppRoutes.propertyDetails,
          arguments: {'property': propertyData},
        );
      },
    );
  }

  Widget _buildPropertyCard({
    required String title,
    required String location,
    required String price,
    required String bhk,
    required String sqft,
    required String tag,
    required Color tagColor,
    String? image,
    bool isVerified = false,
    VoidCallback? onTap,
  }) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _greenLine),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImageCase(
                  url: image,
                  height: 155.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                ),
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isVerified) ...[
                          Icon(Icons.verified_outlined, size: 10.sp, color: tagColor),
                          SizedBox(width: 3.w),
                        ],
                        Text(
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: tagColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.favorite_rounded, color: const Color(0xFFE11D48), size: 16.sp),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 11.sp, color: const Color(0xFF64748B)),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5.sp,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.king_bed_outlined, size: 13.sp, color: const Color(0xFF64748B)),
                      SizedBox(width: 4.w),
                      Text(
                        bhk,
                        style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF475569)),
                      ),
                      SizedBox(width: 14.w),
                      Icon(Icons.crop_square_rounded, size: 13.sp, color: const Color(0xFF64748B)),
                      SizedBox(width: 4.w),
                      Text(
                        sqft,
                        style: GoogleFonts.poppins(fontSize: 10.sp, color: const Color(0xFF475569)),
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

  Widget _buildGroupedMenuCard(List<_MenuRowData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFECEFF2), width: 1.0),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? Radius.circular(22.r) : Radius.zero,
                  bottom: isLast ? Radius.circular(22.r) : Radius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: item.iconBgColor,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(item.icon, size: 18.sp, color: item.iconColor),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: item.titleColor ?? const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      item.trailing ??
                          Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: const Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFF1F3F5),
                  indent: 54.w,
                  endIndent: 16.w,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuRowData {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final Widget? trailing;

  const _MenuRowData({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.trailing,
  });
}