import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String? _selectedRole;

  static const Map<String, String> _apiRole = {
    'buyer': 'Buyer',
    'seller': 'Seller',
    'partner': 'Partner',
  };

  static const Map<String, String> _roleMessages = {
    'buyer': 'Great choice! Setting you up to find verified properties.',
    'seller': 'Awesome! Let’s get your properties listed for trusted buyers.',
    'partner': 'Welcome aboard! Ready to grow your real estate network.',
  };

  void _handleContinue() {
    final selected = _selectedRole;
    if (selected == null) return;

    // Agent / Partner flow — partners log in with their own
    // credentials instead of the generic OTP registration screen.
    if (selected == 'partner') {
      Get.toNamed(AppRoutes.partnerLogin);
      return;
    }

    // Buyer & Seller both go through phone OTP registration / login first
    Get.toNamed(AppRoutes.registration, arguments: {'role': _apiRole[selected]!});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD4F1F4), // Light cyan/blue top
              Color(0xFFF7FBFD), // Soft white middle
              Colors.white,      // Pure white bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 440.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 10.h),
                            Image.asset(
                              'assets/images/app_logo.png',
                              height: 75.h,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.home_work_rounded,
                                    size: 48.sp,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'DIGINIWAS',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'Choose Your Role',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Tell us how you want to use\nDigiNiwas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.sp,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 28.h),
                            _buildRoleCard(
                              roleKey: 'buyer',
                              title: 'Buyer',
                              subtitle: 'Find your perfect property with verified listings',
                              iconOrAsset: Icons.apartment_rounded,
                              assetPath: 'assets/images/buyer_role.png',
                            ),
                            SizedBox(height: 14.h),
                            _buildRoleCard(
                              roleKey: 'seller',
                              title: 'Seller',
                              subtitle: 'Sell your property faster with trusted buyers',
                              iconOrAsset: Icons.real_estate_agent_rounded,
                              assetPath: 'assets/images/seller_role.png',
                            ),
                            SizedBox(height: 14.h),
                            _buildRoleCard(
                              roleKey: 'partner',
                              title: 'Partner / Agent',
                              subtitle: 'Grow your real estate business with DigiNiwas',
                              iconOrAsset: Icons.business_center_rounded,
                              assetPath: 'assets/images/partner_role.png',
                            ),

                            // Polite interactive feedback message banner
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _selectedRole != null
                                  ? Container(
                                key: ValueKey(_selectedRole),
                                margin: EdgeInsets.only(top: 20.h),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.primary,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        _roleMessages[_selectedRole]!,
                                        style: TextStyle(
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : const SizedBox.shrink(),
                            ),
                            SizedBox(height: 32.h),
                            AppButton(
                              label: 'Continue',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: _selectedRole == null ? null : _handleContinue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String subtitle,
    required IconData iconOrAsset,
    required String assetPath,
  }) {
    final bool isSelected = _selectedRole == roleKey;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(0, isSelected ? -3.h : 0, 0),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: isSelected ? 18 : 8,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54.w,
              height: 54.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.05),
                        ]
                      : [
                          AppColors.softBackground,
                          AppColors.softBackground,
                        ],
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  iconOrAsset,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 26.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.8,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}