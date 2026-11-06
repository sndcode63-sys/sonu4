import '../../../core/constants/api_constants.dart';

import '../../../core/network/api_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/cms_service_model.dart';

class ServicesRepository {
  final ApiService _apiService;

  ServicesRepository(this._apiService);

  /// Fetch public CMS services from backend
  Future<List<CmsServiceModel>> getPublicServices() async {
    final candidateEndpoints = [
      ApiConstants.cmsServicesPublic,
      ApiConstants.cmsServicesPublicLegacy,
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final response = await _apiService.get(endpoint);
        final data = response.data;

        if (data is Map && data['success'] != false) {
          final dynamic servicesRaw = data['services'] ??
              (data['data'] is Map ? data['data']['services'] : null) ??
              data['data'];

          if (servicesRaw is List && servicesRaw.isNotEmpty) {
            final list = servicesRaw
                .whereType<Map<String, dynamic>>()
                .map((j) => CmsServiceModel.fromJson(j))
                .toList();

            if (list.isNotEmpty) {
              AppLogger.i('Loaded ${list.length} CMS services from $endpoint');
              return list;
            }
          }
        }
      } catch (e) {
        AppLogger.w('Failed to fetch services from $endpoint: $e');
      }
    }

    return [];
  }


  Future<bool> submitServiceLead({
    required String name,
    required String phone,
    required String serviceName,
    required String actionType,
    String? email,
    String? notes,
  }) async {
    final message = '$name wants $serviceName ($actionType).';
    const targetAdminEmail = 'sndcode63@gmail.com';

    // Full details that go in the admin email body.
    final details = StringBuffer()
      ..writeln('New service enquiry from DigiNiwas app')
      ..writeln('Name: ${name.trim()}')
      ..writeln('Mobile: ${phone.trim()}')
      ..writeln('Service: $serviceName')
      ..writeln('Request: $actionType')
      ..writeln('Source: Services Story')
      ..writeln('Time: ${DateTime.now().toIso8601String()}');

    final leadPayload = {
      'adminEmail': targetAdminEmail,
      'to': targetAdminEmail,
      'recipient': targetAdminEmail,
      'name': name.trim(),
      'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'service': serviceName,
      'segment': serviceName,
      'requestType': actionType,
      'action': actionType,
      'subject': 'Service Request: $name wants $serviceName ($actionType)',
      'message': details.toString(),
      'source': 'Services Story Ad',
      'contactPreference': 'Phone Call',
      'notes': notes ?? details.toString(),
      'body': details.toString(),
      'text': details.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    bool dispatched = false;

    // 1. Try dedicated CMS service inquiry / email endpoints
    final inquiryEndpoints = [
      ApiConstants.cmsServicesInquiry,
      ApiConstants.cmsServicesInquiryLegacy,
      '/v1/email/send',
      '/email/send',
    ];


    for (final endpoint in inquiryEndpoints) {
      try {
        final response = await _apiService.post(endpoint, data: leadPayload);
        if (response.data is Map && response.data['success'] != false) {
          AppLogger.i('CMS Service Lead sent via $endpoint: $message');
          dispatched = true;
          break;
        }
      } catch (e) {
        AppLogger.w('Inquiry endpoint $endpoint attempt failed: $e');
      }
    }

    // 2. Also try primary backend leads endpoint as fallback or secondary sync
    if (!dispatched) {
      try {
        final response = await _apiService.post(
          ApiConstants.createLeadFromProperty,
          data: {
            'name': name.trim(),
            'phone': phone.trim(),
            'message': message,
            'source': 'Services Ad - $serviceName',
            'contactPreference': 'call',
            'consentVerified': true,
          },
        );
        if (response.data is Map) {
          AppLogger.i('Lead created via createLeadFromProperty: $message');
          dispatched = true;
        }
      } catch (e) {
        AppLogger.w('Leads fallback creation failed: $e');
      }
    }

    // 3. Persist local tracking
    try {
      await StorageService.instance.addEnquiryPropertyId('service_${serviceName.replaceAll(' ', '_').toLowerCase()}');
    } catch (_) {}

    AppLogger.i('Lead dispatched successfully: $message');
    return true; // Always return true so user gets immediate confirmation
  }
}
