import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../data/visit_repository.dart';
import '../models/request_visit_model.dart';
import '../models/visit_status.dart';

/// GetX controller for the schedule-visit flow. Register as a permanent
/// singleton in your InitialBinding, same pattern as AuthController:
///   Get.put<VisitRepository>(VisitRepository(ApiService.instance), permanent: true);
///   Get.put<VisitController>(VisitController(Get.find<VisitRepository>()), permanent: true);
class VisitController extends GetxController {
  VisitController(this._repository);

  final VisitRepository _repository;

  // ---- Submit a new visit request ----------------------------------
  final RxBool isSubmitting = false.obs;
  final RxnString submitError = RxnString();
  final Rx<RequestVisitData?> lastRequestedVisit = Rx<RequestVisitData?>(null);

  /// Called from the Schedule Visit bottom sheet's "Request Visit" button.
  /// Returns true on success; on failure, [submitError] holds a message.
  Future<bool> requestVisit({
    required String propertyId,
    required String buyerId,
    required String partnerId,
    required DateTime requestedVisitAt,
    String? requestNotes,
  }) async {
    isSubmitting.value = true;
    submitError.value = null;
    try {
      final result = await _repository.requestVisit(
        propertyId: propertyId,
        buyerId: buyerId,
        partnerId: partnerId,
        requestedVisitAt: requestedVisitAt,
        requestNotes: requestNotes,
      );

      if (result.success == true && result.data != null) {
        lastRequestedVisit.value = result.data;
        final visitId = result.data!.sId ?? result.data!.visitId;
        if (visitId != null && visitId.isNotEmpty) {
          await StorageService.instance.addVisitId(visitId);
        }
        // 🔔 Fire real push notification with sound
        unawaited(NotificationService.showHousingStyleNotification(
          title: 'Site Visit Confirmed! 📅',
          body: 'Your property tour has been scheduled. The assigned partner agent will coordinate with you.',
          summaryText: 'DigiNiwas Visits',
          data: {'visitId': visitId ?? '', 'type': 'visit_update'},
        ));
        // Refresh the list in the background so ScheduledVisitsScreen is
        // already up to date if the user navigates there next.
        unawaited(fetchMyVisits());
        return true;
      }

      submitError.value = result.message ?? 'Could not schedule the visit. Please try again.';
      return false;
    } on DioException catch (e) {
      // Surface the backend's own validation message (e.g. "propertyId,
      // partnerId, buyerId and requestedVisitAt are required.") instead of
      // a generic one, so mistakes like a missing field are obvious.
      submitError.value = _extractServerMessage(e) ?? 'Could not schedule the visit. Please try again.';
      return false;
    } catch (_) {
      submitError.value = 'Something went wrong while scheduling the visit. Please try again.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  String? _extractServerMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return null;
  }

  // ---- Fetch / track existing visits --------------------------------
  final RxBool isFetchingVisits = false.obs;
  final RxnString fetchError = RxnString();
  final RxList<VisitStatusData> myVisits = <VisitStatusData>[].obs;

  /// Fetches the live status of every visit ID stored locally on this
  /// device (there is no bulk "list my visits" endpoint available, so
  /// this calls GET /visits/:id once per stored ID).
  Future<void> fetchMyVisits() async {
    isFetchingVisits.value = true;
    fetchError.value = null;
    try {
      final ids = await StorageService.instance.getVisitIds();
      final results = <VisitStatusData>[];

      for (final id in ids) {
        try {
          final res = await _repository.getVisitById(id);
          if (res.success == true && res.data != null) {
            results.add(res.data!);
          }
        } catch (_) {
          // Skip a single failed visit lookup rather than failing the
          // whole screen — e.g. a stale/deleted visit ID.
        }
      }

      myVisits.value = results;
    } catch (_) {
      fetchError.value = 'Could not load your scheduled visits.';
    } finally {
      isFetchingVisits.value = false;
    }
  }

  // ---- Derived lists for the two ScheduledVisitsScreen tabs ---------
  // NOTE: the exact enum values your backend uses for `status` /
  // `approvalStatus` are an assumption below — confirm against real API
  // responses and adjust these filters if the values differ.
  List<VisitStatusData> get upcomingVisits => myVisits
      .where((v) =>
  v.approvalStatus?.toLowerCase() == 'approved' &&
      v.status?.toLowerCase() != 'completed' &&
      v.status?.toLowerCase() != 'cancelled')
      .toList();

  List<VisitStatusData> get underReviewVisits => myVisits
      .where((v) =>
  v.approvalStatus?.toLowerCase() != 'approved' &&
      v.status?.toLowerCase() != 'cancelled' &&
      v.status?.toLowerCase() != 'completed')
      .toList();
}