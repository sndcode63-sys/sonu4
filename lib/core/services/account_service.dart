import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/buyer/controllers/buyer_home_controller.dart';
import '../../features/partner/controllers/partner_home_controller.dart';
import '../../features/seller/controllers/seller_controller.dart';
import '../constants/api_constants.dart';
import '../network/api_service.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';
import '../utils/app_logger.dart';

class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  /// Deletes the currently authenticated user's account (buyer, seller, or partner).
  ///
  /// According to API specification:
  /// DELETE /api/v1/account
  /// Headers: Authorization: Bearer <JWT_TOKEN>, Content-Type: application/json
  /// Body: { "reason": "..." } (optional)
  ///
  /// The backend identifies the account from the JWT token.
  Future<Map<String, dynamic>> deleteAccount({String? reason}) async {
    try {
      final payload = {
        'reason': (reason != null && reason.trim().isNotEmpty)
            ? reason.trim()
            : 'User requested account deletion',
      };

      final response = await ApiService.instance.delete(
        ApiConstants.deleteAccount,
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {
        'success': true,
        'message': 'Account deleted successfully.',
      };
    } on DioException catch (e) {
      AppLogger.e('Delete account error: ${e.response?.statusCode}', e);
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      String errorMessage = 'Failed to delete account. Please try again.';
      if (responseData is Map && responseData['message'] != null) {
        errorMessage = responseData['message'].toString();
      } else if (statusCode == 401) {
        errorMessage = 'Session expired. Please log in again.';
      } else if (statusCode == 403) {
        errorMessage = 'Account is deleted or access is not allowed.';
      } else if (statusCode == 404) {
        errorMessage = 'Account could not be found.';
      } else if (statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.e('Delete account error', e);
      throw Exception(e.toString());
    }
  }

  /// Clears all local user credentials, cache, and session data.
  Future<void> clearAllSessionData() async {
    try {
      await SecureStorageService.instance.clearTokens();
      await SecureStorageService.instance.clearPendingSellerApplication();
      await SecureStorageService.instance.deleteAll();
    } catch (e) {
      AppLogger.w('Failed to clear secure storage: $e');
    }
    try {
      await StorageService.instance.clearSession();
      await StorageService.instance.clearPendingPartnerApplication();
    } catch (e) {
      AppLogger.w('Failed to clear local storage: $e');
    }
    try {
      if (Get.isRegistered<PartnerHomeController>()) {
        Get.delete<PartnerHomeController>(force: true);
      }
      if (Get.isRegistered<BuyerHomeController>()) {
        Get.delete<BuyerHomeController>(force: true);
      }
      if (Get.isRegistered<SellerController>()) {
        Get.delete<SellerController>(force: true);
      }
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().resetState();
      }
    } catch (e) {
      AppLogger.w('Failed to reset controllers on logout: $e');
    }
  }
}
