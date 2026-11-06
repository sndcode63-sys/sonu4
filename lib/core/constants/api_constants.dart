class ApiConstants {
  ApiConstants._();

  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl =
      'https://api.diginiwas.com/api';



  // ============================================================
  // AUTH ENDPOINTS (Per DigiNiwas Authentication API Guide)
  // ============================================================

  // POST /api/v1/auths/register
  static const String register = '/v1/auths/register';
  static const String registerLegacy = '/auths/register';

  // POST /api/v1/auths/login-password
  static const String loginPassword = '/v1/auths/login-password';
  static const String loginPasswordLegacy = '/auths/login-password';

  // Legacy fallback OTP endpoints
  static const String sendOtp = '/auths/send-otp';
  static const String loginOtp = '/auths/login-otp';
  static const String loginOtpSend = '/v1/auths/login-otp/send';
  static const String loginOtpResend = '/v1/auths/login-otp/resend';
  static const String loginOtpVerify = '/v1/auths/login-otp/verify';

  // Pre-login check phone account (Public endpoint, no JWT)
  // POST /api/v1/auths/firebase-phone-login/check-account
  static const String checkPhoneAccount = '/v1/auths/firebase-phone-login/check-account';

  // Firebase Phone Login (Buyer, Seller, Partner)
  // POST /api/v1/auths/firebase-phone-login
  static const String firebaseLogin = '/v1/auths/firebase-phone-login';
  static const String firebaseLoginLegacy = '/auths/firebase-phone-login';

  // Common Forgot / Reset / Change password (Buyer / Seller / Partner)
  // POST /api/v1/auth/forgot-password
  // POST /api/v1/auth/reset-password
  // PATCH /api/v1/auth/change-password
  static const String forgotPassword = '/v1/auth/forgot-password';
  static const String resetPassword = '/v1/auth/reset-password';
  static const String changePassword = '/v1/auth/change-password';

  // DELETE /api/v1/account
  static const String deleteAccount =
      '/v1/account';


  // ============================================================
  // BUYER APP ENDPOINTS - V1
  // ============================================================

  // ------------------------------------------------------------
  // Home Feed
  // GET /api/v1/home/feed
  // ------------------------------------------------------------

  static const String homeFeed =
      '/v1/home/feed';


  // ------------------------------------------------------------
  // Dashboard Header
  // GET /api/v1/user/dashboard-header
  // ------------------------------------------------------------

  static const String dashboardHeader =
      '/v1/user/dashboard-header';


  // ------------------------------------------------------------
  // Property Categories
  // GET /api/v1/properties/categories
  // ------------------------------------------------------------

  static const String propertyCategories =
      '/v1/properties/categories';


  // ------------------------------------------------------------
  // Boosted Properties
  // GET /api/v1/properties/boosted
  // ------------------------------------------------------------

  static const String boostedProperties =
      '/v1/properties/boosted';


  // ------------------------------------------------------------
  // Explore Nearby
  // GET /api/v1/properties/explore-nearby
  // Query: propertyId, radius
  // ------------------------------------------------------------

  static const String exploreNearby =
      '/v1/properties/explore-nearby';


  // ------------------------------------------------------------
  // New Listings
  // GET /api/v1/properties/new-listings
  // ------------------------------------------------------------

  static const String newListings =
      '/v1/properties/new-listings';


  // ------------------------------------------------------------
  // Popular Locations
  // GET /api/v1/locations/popular
  // ------------------------------------------------------------

  static const String popularLocations =
      '/v1/locations/popular';

  // ==================== CMS / Testimonials & Services ====================
  // GET /api/v1/cms/testimonials
  static const String testimonials = '/v1/cms/testimonials';
  static const String testimonialsLegacy = '/cms/testimonials';

  // CMS Services Endpoints
  // GET /api/v1/cms/services/public
  static const String cmsServicesPublic = '/v1/cms/services/public';
  static const String cmsServicesPublicLegacy = '/cms/services/public';
  // POST /api/v1/cms/services/inquiry
  static const String cmsServicesInquiry = '/v1/cms/services/inquiry';
  static const String cmsServicesInquiryLegacy = '/cms/services/inquiry';

  // ==================== Property Reviews ====================
  // GET /api/v1/property-reviews/property/:propertyId
  static String propertyReviews(String propertyId) =>
      '/v1/property-reviews/property/$propertyId';
  static String propertyReviewsLegacy(String propertyId) =>
      '/property-reviews/property/$propertyId';

  // POST /api/v1/property-reviews
  static const String submitPropertyReview = '/v1/property-reviews';
  static const String submitPropertyReviewLegacy = '/property-reviews';




  // ------------------------------------------------------------
  // Nearby Agents
  // GET /api/v1/agents/nearby
  // ==================== Partner Auth ====================
  static const String partnerLogin = '/v1/partner-auth/login';
  static const String partnerLoginLegacy = '/partner-auth/login';
  static const String partnerChangePassword = '/v1/partner-auth/change-password';

  // ==================== Partner Applications ====================
  static const String partnerApplications = '/v1/partner-applications';
  static const String partnerApplicationsLegacy = '/partner-applications';
  static const String partnerApplicationsRegister = '/v1/partner-applications/register';

  // ==================== Partners ====================
  static const String partners = '/partners';
  static const String partnersSummary = '/partners/summary';
  static const String partnersProperties = '/partners/properties';
  static const String partnersUnassignedProperties =
      '/partners/properties/unassigned';
  static const String partnersAvailable = '/partners/partners/available';
  static const String partnersApprovedNotVerified =
      '/partners/approved-not-verified';
  static const String partnersDelete = '/partners/delete';

  // ==================== Team Partners ====================
  static const String teamPartners = '/team-partners';

  // ==================== Credits ====================
  static const String creditsDashboard = '/credits/dashboard';
  static const String creditsByPartner = '/credits/partners';
  static const String creditsPartnerWallet = '/credits/partner';
  static const String creditsHistory = '/credits/history';
  static const String creditsPurchaseComplete = '/credits/purchase/complete';
  static const String creditsRefund = '/credits/refund';
  static const String creditSettings = '/credit-settings';

  // -------------------- Razorpay Credit Purchase (Partner) --------------------
  // Flow: create order -> Razorpay Checkout -> verify payment (backend adds credits)
  static const String razorpayKeyId = 'rzp_test_TbqasYW5XomtGN';
  static const String razorpayKeySecret = '0al2zio2fUbaVo6CneJlU8hv';

  // POST /api/v1/credits/purchase/order   Body: { "amountInRupees": 500 }
  static const String creditsPurchaseOrder = '/v1/credits/purchase/order';

  // POST /api/v1/credits/purchase/verify
  // Body: { razorpay_order_id, razorpay_payment_id, razorpay_signature }
  static const String creditsPurchaseVerify = '/v1/credits/purchase/verify';

  // POST /api/v1/credits/admin/add  (Admin JWT — Razorpay NOT used here)
  static const String creditsAdminAdd = '/v1/credits/admin/add';

  // ==================== Leads (Partner) ====================
  static const String leadsDashboard = '/leads/dashboard';
  static const String leads = '/leads';
  static const String leadsByPartner = '/leads/partner';
  // PATCH /leads/:id/allocate-subpartner
  static String leadAllocateSubPartner(String id) =>
      '/leads/$id/allocate-subpartner';
  // PATCH /leads/:id/remove-subpartner-allocation
  static String leadRemoveSubPartnerAllocation(String id) =>
      '/leads/$id/remove-subpartner-allocation';
  // PATCH /leads/:id/convert
  static String leadConvert(String id) => '/leads/$id/convert';
  // PATCH /leads/:id/reject
  static String leadReject(String id) => '/leads/$id/reject';
  // PATCH /leads/:id/close
  static String leadClose(String id) => '/leads/$id/close';
  // PATCH /leads/:id/review
  static String leadReview(String id) => '/leads/$id/review';

  // ==================== Visits (Partner) ====================
  static const String visitsSummary = '/visits/summary';
  static const String visitsByPartner = '/visits/partner';
  static const String visits = '/visits';
  static const String visitsRequest = '/visits/request';
  // GET /visits/team/:ownerId/pending
  static String visitsTeamPending(String ownerId) =>
      '/visits/team/$ownerId/pending';
  // PATCH /visits/:id/review        (partner reviews the visit)
  static String visitReview(String id) => '/visits/$id/review';
  // PATCH /visits/:id/team-review   (team owner reviews a sub-agent's visit)
  static String visitTeamReview(String id) => '/visits/$id/team-review';


  // ==================== New Properties (Partner) ====================
  static const String newProperties = '/newproperties';
  static const String newPropertiesAll = '/newproperties/all';
  static const String newPropertiesFilter = '/newproperties/filter';
  static const String newPropertiesByPartner = '/newproperties/partner';

  // ==================== Property Publishing ====================
  static const String propertyPublishingSummary =
      '/property-publishing/summary';
  static const String propertyPublishingReady = '/property-publishing/ready';
  static const String propertyPublishingLive = '/property-publishing/live';

  // ==================== Promotions / Boost Operations ====================
  // GET /api/v1/promotion-plans?targetType=PROPERTY or PARTNER
  static const String promotionPlans = '/v1/promotion-plans';
  static const String promotions = '/v1/promotions';
  // GET  /v1/promotions/my                (auth) logged-in partner's own requests
  static const String promotionsMy = '/v1/promotions/my';
  // POST /v1/promotions/partner/request   (auth) promote the partner profile
  static const String promotionsPartnerRequest = '/v1/promotions/partner/request';
  // POST /v1/promotions/property/request  (auth) promote a property
  static const String promotionsPropertyRequest = '/v1/promotions/property/request';
  // GET  /v1/promotions/partner-requests  (auth) incoming seller requests to partner
  static const String promotionsPartnerRequests = '/v1/promotions/partner-requests';
  // POST /v1/promotions/seller-request (auth) seller submits boost request to partner
  static const String promotionsSellerRequest = '/v1/promotions/seller-request';
  // GET /v1/promotions/seller-requests  (auth) seller lists submitted boost requests
  static const String promotionsSellerRequests = '/v1/promotions/seller-requests';
  // GET /v1/promotions/seller-request/:id (auth) seller boost status and admin outcome
  static String getSellerRequestById(String id) => '/v1/promotions/seller-request/';
  // PATCH /v1/promotions/seller-request/:id/approve (auth) partner accepts seller request
  static String approveSellerRequest(String id) => '/v1/promotions/seller-request//approve';
  // PATCH /v1/promotions/seller-request/:id/reject  (auth) partner rejects seller request
  static String rejectSellerRequest(String id) => '/v1/promotions/seller-request//reject';
  // Discovery: Active promoted properties & partners
  static const String promotionsActiveProperties = '/v1/promotions/active/properties';
  static const String promotionsActivePartners = '/v1/promotions/active/partners';
  static const String boostOperationsDashboard =
      '/boost-operations/dashboard';
  static const String boostOperations = '/boost-operations';


  static const String nearbyAgents =
      '/v1/agents/nearby';


  // ============================================================
  // PROPERTY ENDPOINTS
  // ============================================================

  // ------------------------------------------------------------
  // Get All Properties
  // GET /api/properties
  // ------------------------------------------------------------

  static const String getProperties =
      '/properties';


  // ------------------------------------------------------------
  // Search Properties
  // GET /api/properties/search/list
  // ------------------------------------------------------------

  static const String searchProperties =
      '/properties/search/list';


  // ------------------------------------------------------------
  // Filter Properties
  // GET /api/properties/filter
  // ------------------------------------------------------------

  static const String filterProperties =
      '/properties/filter';


  // ------------------------------------------------------------
  // New Properties Filter
  // GET /api/newproperties/filter
  // ------------------------------------------------------------


  // ------------------------------------------------------------
  // Get Property By ID
  // GET /api/properties/:id
  // ------------------------------------------------------------

  static const String getPropertyById =
      '/properties';


  // ------------------------------------------------------------
  // Create Property
  // POST /api/v1/properties
  // ------------------------------------------------------------

  static const String createProperty =
      '/v1/properties';


  // ------------------------------------------------------------
  // Create New Property (Seller "Add Property" flow)
  // POST /api/newproperties  (multipart/form-data — supports
  // images[], floorPlan, reraCertificate, video file fields)
  // ------------------------------------------------------------

  static const String createNewProperty =
      '/newproperties';

  // ------------------------------------------------------------
  // Property Category Endpoints (DigiNiwas Property CRUD API Doc)
  // Base: https://diginiwas.com/digi/api
  // ------------------------------------------------------------
  static const String residentialSale = '/residential-sale';
  static const String commercialSale = '/commercial-sale';
  static const String residentialRent = '/rental-properties';
  static const String commercialRent = '/commercial-rental-properties';

  static String residentialSaleById(String id) => '/residential-sale/$id';
  static String commercialSaleById(String id) => '/commercial-sale/$id';
  static String residentialRentById(String id) => '/rental-properties/$id';
  static String commercialRentById(String id) => '/commercial-rental-properties/$id';


  // ------------------------------------------------------------
  // Update Property
  // PATCH /api/v1/properties/:id
  // ------------------------------------------------------------

  static String updateProperty(String propertyId) =>
      '/v1/properties/$propertyId';


  // ------------------------------------------------------------
  // Delete Property
  // DELETE /api/v1/properties/:id/delete
  // ------------------------------------------------------------

  static String deleteProperty(String propertyId) =>
      '/v1/properties/$propertyId/delete';


  // ------------------------------------------------------------
  // Update Property Status
  // PATCH /api/v1/properties/:id/status
  // ------------------------------------------------------------

  static String updatePropertyStatus(String propertyId) =>
      '/v1/properties/$propertyId/status';


  // ------------------------------------------------------------
  // Boost Property
  // PATCH /api/v1/properties/:id/boost
  // ------------------------------------------------------------

  static String boostProperty(String propertyId) =>
      '/v1/properties/$propertyId/boost';


  // ------------------------------------------------------------
  // Remove Property Boost
  // PATCH /api/v1/properties/:id/unboost
  // ------------------------------------------------------------

  static String removePropertyBoost(String propertyId) =>
      '/v1/properties/$propertyId/unboost';


  // ------------------------------------------------------------
  // Get All Properties - V1
  // GET /api/v1/properties/all
  // ------------------------------------------------------------

  static const String getAllPropertiesV1 =
      '/v1/properties/all';


  // ------------------------------------------------------------
  // Get Admin Properties
  // GET /api/v1/properties/admin
  // ------------------------------------------------------------

  static const String getAdminProperties =
      '/v1/properties/admin';


  // ------------------------------------------------------------
  // Get Boosted Properties - V1
  // GET /api/v1/properties/boosted
  // ------------------------------------------------------------

  static const String getBoostedPropertiesV1 =
      '/v1/properties/boosted';


  // ------------------------------------------------------------
  // Get New Listings - V1
  // GET /api/v1/properties/new-listings
  // ------------------------------------------------------------

  static const String getNewListingsV1 =
      '/v1/properties/new-listings';


  // ------------------------------------------------------------
  // Get Properties By Partner
  // GET /api/v1/properties/partner/:partnerId
  // ------------------------------------------------------------

  static String getPropertiesByPartner(String partnerId) =>
      '/v1/properties/partner/$partnerId';


  // ============================================================
  // SAVED PROPERTY ENDPOINTS
  // ============================================================

  // ------------------------------------------------------------
  // Save Property
  // POST /api/saved-properties
  // ------------------------------------------------------------

  static const String saveProperty =
      '/saved-properties';


  // ------------------------------------------------------------
  // Get Buyer Saved Properties
  // GET /api/saved-properties/buyer/:buyerId
  // ------------------------------------------------------------

  static String getBuyerSavedProperties(String buyerId) =>
      '/saved-properties/buyer/$buyerId';


  // ------------------------------------------------------------
  // Check Saved Property
  // GET /api/saved-properties/check/:buyerId/:propertyId
  // ------------------------------------------------------------

  static String checkSavedProperty(
      String buyerId,
      String propertyId,
      ) =>
      '/saved-properties/check/$buyerId/$propertyId';


  // ------------------------------------------------------------
  // Remove Saved Property
  // DELETE /api/saved-properties/:buyerId/:propertyId
  // ------------------------------------------------------------

  static String removeSavedProperty(
      String buyerId,
      String propertyId,
      ) =>
      '/saved-properties/$buyerId/$propertyId';


  // ============================================================
  // NOTIFICATIONS ENDPOINTS
  // ============================================================

  static const String notifications = '/notifications';
  static String userNotifications(String userId) => '/notifications/user/$userId';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';


  // ============================================================
  // LEAD / ENQUIRY ENDPOINTS
  // ============================================================

  // ------------------------------------------------------------
  // Create Lead From Property
  // POST /api/leads/from-property
  // ------------------------------------------------------------

  static const String createLeadFromProperty =
      '/leads/from-property';


  // ------------------------------------------------------------
  // Get Partner Leads - V1
  // GET /api/v1/leads/partner/:partnerId
  // ------------------------------------------------------------

  static String getPartnerLeads(String partnerId) =>
      '/v1/leads/partner/$partnerId';


  // ------------------------------------------------------------
  // Get Lead By ID - V1
  // GET /api/v1/leads/:id
  // ------------------------------------------------------------

  static String getLeadById(String leadId) =>
      '/v1/leads/$leadId';


  // ============================================================
  // VISIT ENDPOINTS
  // ============================================================

  // ------------------------------------------------------------
  // Request Property Visit
  // POST /api/visits/request
  // ------------------------------------------------------------

  static const String requestVisit =
      '/visits/request';


  // ------------------------------------------------------------
  // Get Visit By ID
  // GET /api/visits/:id
  // ------------------------------------------------------------

  static String getVisitById(String visitId) =>
      '/visits/$visitId';


  // ------------------------------------------------------------
  // Get Visits By Partner - V1
  // GET /api/v1/visits/partner/:partnerId
  // ------------------------------------------------------------

  static String getVisitsByPartner(String partnerId) =>
      '/v1/visits/partner/$partnerId';


  // ------------------------------------------------------------
  // Visit Summary
  // GET /api/v1/visits/summary
  // ------------------------------------------------------------

  static const String visitSummary =
      '/v1/visits/summary';


  // ============================================================
  // SELLER ENDPOINTS - V1
  // ============================================================

  // ============================================================
  // SELLER APPLICATION / REGISTRATION
  // ============================================================

  // ------------------------------------------------------------
  // Register Seller Application
  // POST /api/v1/sellers/applications/register
  // ------------------------------------------------------------

  static const String registerSellerApplication =
      '/v1/sellers/applications/register';


  // ------------------------------------------------------------
  // Resend Seller Email OTP
  // POST /api/v1/sellers/applications/resend-email-otp
  // ------------------------------------------------------------

  static const String resendSellerEmailOtp =
      '/v1/sellers/applications/resend-email-otp';


  // ------------------------------------------------------------
  // Resend Seller Phone OTP
  // POST /api/v1/sellers/applications/resend-phone-otp
  // ------------------------------------------------------------

  static const String resendSellerPhoneOtp =
      '/v1/sellers/applications/resend-phone-otp';


  // ------------------------------------------------------------
  // Verify Seller Email OTP
  // POST /api/v1/sellers/applications/verify-email
  // ------------------------------------------------------------

  static const String verifySellerEmailOtp =
      '/v1/sellers/applications/verify-email';


  // ------------------------------------------------------------
  // Verify Seller Phone OTP
  // POST /api/v1/sellers/applications/verify-phone
  // ------------------------------------------------------------

  static const String verifySellerPhoneOtp =
      '/v1/sellers/applications/verify-phone';


  // ============================================================
  // SELLER AUTH
  // ============================================================

  // ------------------------------------------------------------
  // Seller Login
  // POST /api/v1/sellers/auth/login
  // ------------------------------------------------------------

  static const String sellerLogin =
      '/v1/sellers/auth/login';


  // ------------------------------------------------------------
  // Send Seller Login OTP
  // POST /api/v1/sellers/auth/send-login-otp
  // ------------------------------------------------------------

  static const String sendSellerLoginOtp =
      '/v1/sellers/auth/send-login-otp';


  // ------------------------------------------------------------
  // Seller Login With OTP
  // POST /api/v1/sellers/auth/login-with-otp
  // ------------------------------------------------------------

  static const String sellerLoginWithOtp =
      '/v1/sellers/auth/login-with-otp';


  // ------------------------------------------------------------
  // Change Seller Password
  // PATCH /api/v1/sellers/auth/change-password
  // ------------------------------------------------------------

  static const String changeSellerPassword =
      '/v1/sellers/auth/change-password';


  // ============================================================
  // SELLER MANAGEMENT
  // ============================================================

  // ------------------------------------------------------------
  // Get All Sellers
  // GET /api/v1/sellers
  //
  // Query:
  // $or, city, isVerified, search, verified
  // ------------------------------------------------------------

  static const String getAllSellers =
      '/v1/sellers';


  // ------------------------------------------------------------
  // Get Seller By ID
  // GET /api/v1/sellers/:id
  // ------------------------------------------------------------

  static String getSellerById(String sellerId) =>
      '/v1/sellers/$sellerId';


  // ------------------------------------------------------------
  // Get Seller Summary
  // GET /api/v1/sellers/:id/summary
  // ------------------------------------------------------------

  static String getSellerSummary(String sellerId) =>
      '/v1/sellers/$sellerId/summary';


  // ------------------------------------------------------------
  // Get Seller Properties
  // GET /api/v1/sellers/:id/properties
  // ------------------------------------------------------------

  static String getSellerProperties(String sellerId) =>
      '/v1/sellers/$sellerId/properties';


  // ------------------------------------------------------------
  // Get Seller Property By ID
  // GET /api/v1/sellers/:sellerId/properties/:propertyId
  // ------------------------------------------------------------

  static String getSellerPropertyById(
      String sellerId,
      String propertyId,
      ) =>
      '/v1/sellers/$sellerId/properties/$propertyId';


  // ============================================================
  // SELLER HOME - SUPPORTING APIs
  // ============================================================

  // ------------------------------------------------------------
  // Seller/Partner Leads
  // GET /api/v1/leads/partner/:partnerId
  // ------------------------------------------------------------

  static String sellerPartnerLeads(String partnerId) =>
      '/v1/leads/partner/$partnerId';


  // ------------------------------------------------------------
  // Seller My Promotions
  // GET /api/v1/promotions/my
  // ------------------------------------------------------------

  static const String sellerMyPromotions =
      '/v1/promotions/my';


  // ------------------------------------------------------------
  // Seller/Partner Visits
  // GET /api/v1/visits/partner/:partnerId
  // ------------------------------------------------------------

  static String sellerPartnerVisits(String partnerId) =>
      '/v1/visits/partner/$partnerId';


  // ============================================================
  // PROPERTY PUBLISHING
  // ============================================================

  // ------------------------------------------------------------
  // Final Review Property
  // GET /api/v1/property-publishing/:id/final-review
  // Admin Bearer
  // ------------------------------------------------------------

  static String finalReviewProperty(String propertyId) =>
      '/v1/property-publishing/$propertyId/final-review';


  // ============================================================
  // TIMEOUT
  // ============================================================

  static const int connectTimeout = 60000;

  static const int receiveTimeout = 60000;

  static const int sendTimeout = 120000;

  /// Dedicated extended timeout for media and document uploads (5 minutes)
  static const int uploadTimeout = 300000;


  // ============================================================
  // HEADERS
  // ============================================================

  static const String authHeader =
      'Authorization';

  static const String contentTypeHeader =
      'Content-Type';
}