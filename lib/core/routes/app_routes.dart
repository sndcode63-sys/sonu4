/// All GetX route names live here. Navigate with `Get.toNamed` /
/// `Get.offNamed` / `Get.offAllNamed` / `Get.back` — see `app_pages.dart`
/// for how each route maps to a screen (`GetPage`).
abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const chooseRole = '/choose-role';
  static const registration = '/registration';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';

  // Dashboards (one per role)
  static const buyerHome = '/buyer-home';
  static const sellerHome = '/seller-home';
  static const partnerDashboard = '/partner-dashboard';

  // Buyer flow
  static const propertyDetails = '/property-details';
  static const panoramaViewer = '/panorama-viewer';
  static const compareProperties = '/compare-properties';
  static const exploreMap = '/explore-map';
  static const mapView = '/map-view';
  static const recentlyViewed = '/recently-viewed';
  static const saveProperties = '/save-properties';
  static const buyerNotifications = '/buyer-notifications';
  static const viewAll = '/view-all';
  static const partnerLogin = '/partner-login';
  static const partnerTeam = '/partner-team';
  static const partnerChangePassword = '/partner-change-password';


  // Seller flow
  static const sellerRegistration = '/seller-registration';
  static const sellerChangePassword = '/seller-change-password';
  static const myProperties = '/my-properties';
  static const addProperty = '/add-property';
  static const sellerInsights = '/seller_insights';
  static const sellerNotifications = '/seller-notifications';

  // Agent / partner flow
  static const agentAddProperty = '/agent-add-property';
  static const boostProperty = '/boost-property';
  static const partnerApply = '/partner-apply';
  static const creditWallet = '/credit-wallet';
  static const creditGuidelines = '/credit-guidelines';
  static const niwasAi = '/niwas-ai';
  static const partnerNotifications = '/partner-notifications';
  static const partnerDigitalCard = '/partner-digital-card';
}
