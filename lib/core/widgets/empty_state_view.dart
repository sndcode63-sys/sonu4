import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Supported types for rich 3D illustration empty states.
enum EmptyStateType {
  property,
  map,
  documents,
  visits,
  forSale,
  agent,
  search,
  contract,
  nearby,
  gallery,
  team,
  review,
  folder,
  notification,
  commercial,
  saved,
  locations,
  boosted,
  noListings,
  offline,
  custom,
}

extension EmptyStateTypeX on EmptyStateType {
  String get svgPath {
    switch (this) {
      case EmptyStateType.boosted:
      case EmptyStateType.saved:
      case EmptyStateType.commercial:
      case EmptyStateType.property:
      case EmptyStateType.noListings:
      case EmptyStateType.forSale:
        return 'assets/images/empty_states/diginiwas-empty-state-vibrant.svg';
      case EmptyStateType.notification:
        return 'assets/images/empty_states/empty_notification.svg';
      case EmptyStateType.search:
        return 'assets/images/empty_states/empty_search.svg';
      case EmptyStateType.visits:
        return 'assets/images/empty_states/empty_visits.svg';
      case EmptyStateType.map:
      case EmptyStateType.nearby:
      case EmptyStateType.locations:
        return 'assets/images/empty_states/empty_map.svg';
      default:
        return 'assets/images/empty_states/diginiwas-empty-state-vibrant.svg';
    }
  }

  String get assetPath {
    switch (this) {
      case EmptyStateType.property:
        return 'assets/images/empty_states/empty_property.png';
      case EmptyStateType.map:
        return 'assets/images/empty_states/empty_map.png';
      case EmptyStateType.documents:
        return 'assets/images/empty_states/empty_documents.png';
      case EmptyStateType.visits:
        return 'assets/images/empty_states/empty_visits.png';
      case EmptyStateType.forSale:
        return 'assets/images/empty_states/empty_for_sale.png';
      case EmptyStateType.agent:
        return 'assets/images/empty_states/empty_agent.png';
      case EmptyStateType.search:
        return 'assets/images/empty_states/empty_search.png';
      case EmptyStateType.contract:
        return 'assets/images/empty_states/empty_contract.png';
      case EmptyStateType.nearby:
        return 'assets/images/empty_states/empty_nearby.png';
      case EmptyStateType.gallery:
        return 'assets/images/empty_states/empty_gallery.png';
      case EmptyStateType.team:
        return 'assets/images/empty_states/empty_team.png';
      case EmptyStateType.review:
        return 'assets/images/empty_states/empty_review.png';
      case EmptyStateType.folder:
        return 'assets/images/empty_states/empty_folder.png';
      case EmptyStateType.notification:
        return 'assets/images/empty_states/empty_notification.png';
      case EmptyStateType.commercial:
        return 'assets/images/empty_states/empty_commercial.png';
      case EmptyStateType.saved:
        return 'assets/images/empty_states/empty_saved.png';
      case EmptyStateType.locations:
        return 'assets/images/empty_states/empty_locations.png';
      case EmptyStateType.boosted:
        return 'assets/images/empty_states/empty_boosted.png';
      case EmptyStateType.noListings:
        return 'assets/images/empty_states/empty_no_listings.png';
      case EmptyStateType.offline:
        return 'assets/images/empty_states/empty_offline.png';
      case EmptyStateType.custom:
        return 'assets/images/empty_states/empty_property.png';
    }
  }

  String get defaultTitle {
    switch (this) {
      case EmptyStateType.property:
        return 'No Properties Found';
      case EmptyStateType.map:
        return 'No Properties on Map';
      case EmptyStateType.documents:
        return 'No Documents Available';
      case EmptyStateType.visits:
        return 'No Scheduled Visits';
      case EmptyStateType.forSale:
        return 'No Properties For Sale';
      case EmptyStateType.agent:
        return 'No Agents Found';
      case EmptyStateType.search:
        return 'No Results Found';
      case EmptyStateType.contract:
        return 'No Active Agreements';
      case EmptyStateType.nearby:
        return 'No Nearby Properties';
      case EmptyStateType.gallery:
        return 'No Photos Available';
      case EmptyStateType.team:
        return 'No Team Members Yet';
      case EmptyStateType.review:
        return 'No Reviews Yet';
      case EmptyStateType.folder:
        return 'Folder is Empty';
      case EmptyStateType.notification:
        return 'No Notifications';
      case EmptyStateType.commercial:
        return 'No Commercial Units';
      case EmptyStateType.saved:
        return 'No Saved Properties';
      case EmptyStateType.locations:
        return 'No Locations Found';
      case EmptyStateType.boosted:
        return 'No Boosted Properties';
      case EmptyStateType.noListings:
        return 'No New Listings Yet';
      case EmptyStateType.offline:
        return 'No Internet Connection';
      case EmptyStateType.custom:
        return 'No Data Found';
    }
  }

  String get defaultMessage {
    switch (this) {
      case EmptyStateType.property:
        return 'We couldn\'t find any properties matching your current criteria.';
      case EmptyStateType.map:
        return 'Try zooming out or panning to explore properties in other areas.';
      case EmptyStateType.documents:
        return 'Upload property verification documents to get verified by an agent.';
      case EmptyStateType.visits:
        return 'Schedule a site visit with our verified partners at your convenience.';
      case EmptyStateType.forSale:
        return 'There are currently no listings up for sale in this selection.';
      case EmptyStateType.agent:
        return 'No registered agents found in this area. Check back soon!';
      case EmptyStateType.search:
        return 'Try adjusting your search terms or clearing some filters.';
      case EmptyStateType.contract:
        return 'Legal agreements and draft contracts will appear here.';
      case EmptyStateType.nearby:
        return 'Expand your search radius to discover homes around you.';
      case EmptyStateType.gallery:
        return 'Property photos and walkthrough videos will be displayed here.';
      case EmptyStateType.team:
        return 'Add or invite team members to collaborate.';
      case EmptyStateType.review:
        return 'Be the first to share your experience with this property.';
      case EmptyStateType.folder:
        return 'There are no items stored in this folder.';
      case EmptyStateType.notification:
        return 'You\'re all caught up! Updates and alerts will show here.';
      case EmptyStateType.commercial:
        return 'Explore retail, office, and commercial listings when available.';
      case EmptyStateType.saved:
        return 'Tap the heart icon on any property to save it for later.';
      case EmptyStateType.locations:
        return 'Explore other popular neighborhoods and cities.';
      case EmptyStateType.boosted:
        return 'Promoted listings with verified agents will appear here.';
      case EmptyStateType.noListings:
        return 'New listings are added daily. Stay tuned!';
      case EmptyStateType.offline:
        return 'Check your internet connection and tap retry.';
      case EmptyStateType.custom:
        return 'Nothing to display at this moment.';
    }
  }
}

/// Full screen or section-level empty state view with 3D illustration and optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.type = EmptyStateType.custom,
    this.title,
    this.message,
    this.illustrationAsset,
    this.fallbackIcon,
    this.imageSize = 95,
    this.actionLabel,
    this.onAction,
    this.isRightAlignedAction = true,
  });

  /// Factory for a horizontal card empty state suitable for carousels
  /// (e.g. Boosted Properties or New Listings horizontal scroll).
  static Widget horizontalCard({
    Key? key,
    required EmptyStateType type,
    String? title,
    String? message,
    double? width,
    double? height,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppEmptyStateHorizontalCard(
      key: key,
      type: type,
      title: title,
      message: message,
      width: width,
      height: height,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? illustrationAsset;
  final IconData? fallbackIcon;
  final double imageSize;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isRightAlignedAction;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? type.defaultTitle;
    final effectiveMessage = message ?? type.defaultMessage;
    final effectiveAsset = illustrationAsset ?? (type.svgPath.isNotEmpty ? type.svgPath : type.assetPath);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIllustration(effectiveAsset),
            SizedBox(height: 10.h),
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 4.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 290.w),
              child: Text(
                effectiveMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 10.h),
              Align(
                alignment: isRightAlignedAction ? Alignment.centerRight : Alignment.center,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: const Color(0xFF007A5E),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF007A5E),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13.sp,
                          color: const Color(0xFF007A5E),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(String assetPath) {
    final isSvg = assetPath.endsWith('.svg');

    return Stack(
      alignment: Alignment.center,
      children: [
        // Subtle ambient glow behind illustration
        Container(
          width: (imageSize * 1.05).w,
          height: (imageSize * 0.85).w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF007A5E).withValues(alpha: 0.08),
                const Color(0xFF33CC99).withValues(alpha: 0.02),
                Colors.transparent,
              ],
            ),
          ),
        ),
        if (isSvg)
          SvgPicture.asset(
            assetPath,
            width: (imageSize * 1.1).w,
            height: (imageSize * 0.78).h,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => _buildFallbackIcon(),
          )
        else
          Image.asset(
            assetPath,
            width: imageSize.w,
            height: (imageSize * 0.78).h,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => _buildFallbackIcon(),
          ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: (imageSize * 0.7).w,
      height: (imageSize * 0.7).w,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        fallbackIcon ?? _resolveDefaultIcon(type),
        size: 32.sp,
        color: AppColors.primary,
      ),
    );
  }

  IconData _resolveDefaultIcon(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.notification:
        return Icons.notifications_none_rounded;
      case EmptyStateType.saved:
        return Icons.favorite_border_rounded;
      case EmptyStateType.property:
      case EmptyStateType.noListings:
      case EmptyStateType.forSale:
        return Icons.home_work_outlined;
      case EmptyStateType.search:
        return Icons.search_off_rounded;
      case EmptyStateType.map:
      case EmptyStateType.nearby:
      case EmptyStateType.locations:
        return Icons.map_outlined;
      case EmptyStateType.visits:
        return Icons.calendar_today_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

/// Compact horizontal card empty state formatted for horizontal carousels (e.g. Boosted Properties).
class AppEmptyStateHorizontalCard extends StatelessWidget {
  const AppEmptyStateHorizontalCard({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.width,
    this.height,
    this.actionLabel,
    this.onAction,
  });

  final EmptyStateType type;
  final String? title;
  final String? message;
  final double? width;
  final double? height;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? type.defaultTitle;
    final effectiveMessage = message ?? type.defaultMessage;
    final assetPath = type.svgPath.isNotEmpty ? type.svgPath : type.assetPath;
    final isSvg = assetPath.endsWith('.svg');

    return Container(
      width: width ?? 280.w,
      height: height ?? 175.h,
      margin: EdgeInsets.only(right: 14.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Illustration on transparent background
          SizedBox(
            width: 82.w,
            height: 82.w,
            child: isSvg
                ? SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.bolt_rounded,
                      size: 36.sp,
                      color: const Color(0xFF007A5E),
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  effectiveTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  effectiveMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFF007A5E),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF007A5E),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 11.sp,
                            color: const Color(0xFF007A5E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility widget for previously used EmptyStateView.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.illustrationAsset,
    this.emptyStateType,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String message;
  final String? title;
  final IconData icon;
  final String? illustrationAsset;
  final EmptyStateType? emptyStateType;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (emptyStateType != null) {
      return AppEmptyState(
        type: emptyStateType!,
        title: title,
        message: message,
        illustrationAsset: illustrationAsset,
        fallbackIcon: icon,
        imageSize: compact ? 80 : 120,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }

    return AppEmptyState(
      type: EmptyStateType.custom,
      title: title,
      message: message,
      illustrationAsset: illustrationAsset,
      fallbackIcon: icon,
      imageSize: compact ? 80 : 120,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
