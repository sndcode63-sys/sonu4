import 'package:get/get.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/partner/controllers/partner_home_controller.dart';
import '../../features/partner/data/partner_repository.dart';
import '../network/api_service.dart';
import '../services/location_service.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';

/// GetX replacement for the old Riverpod `core_providers.dart`.
///
/// Registered here with `Get.put(..., permanent: true)` so every service,
/// repository and controller is available for the lifetime of the app via
/// `Get.find<T>()` — mirroring how the Riverpod providers were global.
///
/// Wired up in `GetMaterialApp(initialBinding: InitialBinding())`.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put<ApiService>(ApiService.instance, permanent: true);
    Get.put<SecureStorageService>(
      SecureStorageService.instance,
      permanent: true,
    );
    Get.put<StorageService>(StorageService.instance, permanent: true);
    Get.put<LocationService>(LocationService(), permanent: true);

    // Repositories
    Get.put<AuthRepository>(
      AuthRepository(Get.find<ApiService>(), Get.find<SecureStorageService>()),
      permanent: true,
    );
    Get.put<PartnerRepository>(
      PartnerRepository(
        Get.find<ApiService>(),
        Get.find<SecureStorageService>(),
      ),
      permanent: true,
    );

    // Controllers
    Get.put<AuthController>(
      AuthController(Get.find<AuthRepository>(), Get.find<LocationService>()),
      permanent: true,
    );
    Get.lazyPut<PartnerHomeController>(
          () => PartnerHomeController(repository: Get.find<PartnerRepository>()),
      fenix: true,
    );
  }
}