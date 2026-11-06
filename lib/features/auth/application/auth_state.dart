import '../../../core/services/location_service.dart';

enum AuthStatus { idle, loading, otpSent, verified, error }

/// Immutable state consumed by every auth screen via
/// `Get.find<AuthController>().state.value` (wrap reads in `Obx` to
/// rebuild when it changes).
class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.phone,
    this.role = 'Buyer',
    this.userData,
    this.location,
    this.locationError,
  });

  final AuthStatus status;
  final String? errorMessage;
  final String? phone;
  final String role;
  final Map<String, dynamic>? userData;

  /// GPS fix captured on the login/registration screens, if the user
  /// allowed it.
  final LocationResult? location;

  /// Set when the location prompt failed/was denied. Non-fatal — the UI
  /// may surface it as a soft toast but must not block login/registration.
  final String? locationError;

  static const String defaultRole = 'Buyer';

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
    String? phone,
    String? role,
    Map<String, dynamic>? userData,
    LocationResult? location,
    String? locationError,
    bool clearLocationError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      phone: phone ?? this.phone,
      role: role ?? this.role,
      userData: userData ?? this.userData,
      location: location ?? this.location,
      locationError: clearLocationError ? null : (locationError ?? this.locationError),
    );
  }
}
