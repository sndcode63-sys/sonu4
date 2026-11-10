import 'package:get/get.dart';

import '../../features/partner/presentation/partner_home_screen.dart';
import '../../features/partner/presentation/partner_application_screen.dart';
import '../../features/partner/presentation/partner_change_password_screen.dart';
import '../../features/partner/presentation/partner_team_screen.dart';
import '../../features/partner/presentation/credit_wallet_screen.dart';
import '../../features/partner/presentation/credit_guidelines_screen.dart';
import '../../features/partner/presentation/niwas_ai_screen.dart';
import '../../features/partner/presentation/partner_notifications_screen.dart';
import '../../features/partner/presentation/share_digital_card_screen.dart';
import '../../features/partner/presentation/boost_property_screen.dart';
import '../../features/partner/models/partner_models.dart';
import '../../features/buyer/presentation/buyer_home_screen.dart' as buyer;
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/buyer/presentation/compare_properties_screen.dart';
import '../../features/buyer/presentation/map_view_screen.dart';
import '../../features/buyer/presentation/property_details_screen.dart';
import '../../features/buyer/presentation/recently_viewed_screen.dart';
import '../../features/buyer/presentation/save_properties_screen.dart';
import '../../features/buyer/presentation/notification_screen.dart';
import '../../features/buyer/presentation/view_all_screen.dart';
import '../../features/auth/presentation/otp.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/registration_screen.dart';
import '../../features/auth/presentation/privacy_policy_screen.dart';
import '../../features/auth/presentation/terms_of_service_screen.dart';
import '../../features/seller/presentation/add_property_flow_screen.dart';
import '../../features/seller/presentation/seller_home_screen.dart';
import '../../features/seller/presentation/my_property_seller.dart';
import '../../features/seller/presentation/seller_change_password_screen.dart';
import '../../features/seller/presentation/seller_insights.dart';
import '../../features/seller/presentation/seller_registration_screen.dart';
import '../../features/seller/presentation/seller_notifications_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
// replace stack
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.chooseRole,
      page: () => const ChooseRoleScreen(),
    ),
    GetPage(
      name: AppRoutes.registration,
      page: () => RegistrationScreen(
        role: _arg<String>('role', 'Buyer'),
        loginOnly: _arg<bool>('loginOnly', false),
      ),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => OtpVerificationScreen(
        phoneNumber: _arg<String>('phoneNumber', ''),
        role: _arg<String>('role', 'Buyer'),
        mode: _arg<OtpFlowMode>('mode', OtpFlowMode.register),
      ),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(
      name: AppRoutes.termsOfService,
      page: () => const TermsOfServiceScreen(),
    ),

    // Dashboards
    GetPage(
      name: AppRoutes.buyerHome,
      page: () =>  buyer.HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.sellerHome,
      page: () => const SellerHomeScreen(),
    ),
    GetPage(
      name: AppRoutes.partnerDashboard,
      page: () => const PartnerDashboardScreen(),
    ),

    // Buyer flow
    GetPage(
      name: AppRoutes.propertyDetails,
      page: () => const PropertyDetailsScreen(
      ),
    ),
    GetPage(
      name: AppRoutes.panoramaViewer,
      page: () => const PropertyDetailsScreen(
      ),
    ),
    GetPage(
      name: AppRoutes.compareProperties,
      page: () {
        final args = Get.arguments;
        List<dynamic> props = const [];
        if (args is Map && args['comparedProperties'] is List) {
          props = args['comparedProperties'] as List<dynamic>;
        } else if (args is List) {
          props = args;
        }
        return ComparePropertiesScreen(comparedProperties: props);
      },
    ),
    GetPage(
      name: AppRoutes.exploreMap,
      page: () => const MapViewScreen(),
    ),
    GetPage(
      name: AppRoutes.mapView,
      page: () => const MapViewScreen(),
    ),
    GetPage(
      name: AppRoutes.recentlyViewed,
      page: () => const RecentlyViewedScreen(),
    ),
    GetPage(
      name: AppRoutes.saveProperties,
      page: () => SavedPropertiesScreen(),
    ),
    GetPage(
      name: AppRoutes.buyerNotifications,
      page: () => const NotificationScreen(),
    ),
    GetPage(
      name: AppRoutes.viewAll,
      page: () => ViewAllScreen(
        title: _arg<String>('title', 'Properties'),
        type: _arg<ViewAllType>('type', ViewAllType.property),
      ),
    ),

    // Seller flow
    GetPage(
      name: AppRoutes.sellerRegistration,
      page: () => const SellerRegistrationScreen(),
    ),
    GetPage(
      name: AppRoutes.sellerChangePassword,
      page: () => const SellerChangePasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.myProperties,
      page: () => const MyPropertiesScreen(),
    ),
    GetPage(
      name: AppRoutes.sellerInsights,
      page: () => const SellerInsightsScreen(),
    ),
    GetPage(
      name: AppRoutes.addProperty,
      page: () => const AddPropertyFlowScreen(),
    ),
    GetPage(
      name: AppRoutes.sellerNotifications,
      page: () => const SellerNotificationsScreen(),
    ),

    GetPage(
      name: AppRoutes.partnerLogin,
      // Partner login ab OTP-only hai (phone -> OTP) — common login screen, role=Partner.
      page: () => const RegistrationScreen(role: 'Partner', loginOnly: true),
    ),

    // Agent / partner flow - Uses exact same comprehensive AddPropertyFlowScreen as Seller
    GetPage(
      name: AppRoutes.agentAddProperty,
      page: () => const AddPropertyFlowScreen(),
    ),
    GetPage(
      name: AppRoutes.partnerApply,
      page: () => const PartnerApplicationScreen(),
    ),
    GetPage(
      name: AppRoutes.partnerChangePassword,
      page: () => const PartnerChangePasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.partnerTeam,
      page: () => const PartnerTeamScreen(),
    ),
    GetPage(
      name: AppRoutes.creditWallet,
      page: () => const CreditWalletScreen(),
    ),
    GetPage(
      name: AppRoutes.boostProperty,
      page: () {
        PartnerProperty? prop;
        int initialTabIndex = 0;
        final args = Get.arguments;
        if (args is PartnerProperty) {
          prop = args;
        } else if (args is Map) {
          if (args['property'] is PartnerProperty) {
            prop = args['property'] as PartnerProperty;
          }
          if (args['initialTabIndex'] is int) {
            initialTabIndex = args['initialTabIndex'] as int;
          }
        }
        return BoostPropertyScreen(
          property: prop,
          initialTabIndex: initialTabIndex,
        );
      },
    ),
    GetPage(
      name: AppRoutes.creditGuidelines,
      page: () => const CreditGuidelinesScreen(),
    ),
    GetPage(
      name: AppRoutes.niwasAi,
      page: () => const NiwasAIScreen(),
    ),
    GetPage(
      name: AppRoutes.partnerNotifications,
      page: () => const PartnerNotificationsScreen(),
    ),
    GetPage(
      name: AppRoutes.partnerDigitalCard,
      page: () => const ShareDigitalCardScreen(),
    ),
  ];
}

/// Reads a single value out of `Get.arguments` (expected to be a `Map`),
/// falling back to [fallback] when it's missing.
T _arg<T>(String key, T fallback) {
  final args = Get.arguments;
  if (args is Map && args.containsKey(key)) {
    return args[key] as T;
  }
  return fallback;
}

/// Returns the dashboard route for a given backend role string
/// ('Buyer' / 'Seller' / 'Partner' / 'Agent'), defaulting to the role
/// picker when the role is missing or unrecognised.
String dashboardRouteForRole(String? role) {
  switch (role?.toLowerCase()) {
    case 'seller':
      return AppRoutes.sellerHome;
    case 'partner':
    case 'agent':
      return AppRoutes.partnerDashboard;
    case 'buyer':
      return AppRoutes.buyerHome;
    default:
      return AppRoutes.chooseRole;
  }
}