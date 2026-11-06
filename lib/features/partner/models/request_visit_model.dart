// POST /visits/request response model.
// Reuses the snapshot/history classes from visit_status_model.dart since
// both endpoints return the identical nested shapes.

import 'package:diginiwas/features/partner/models/visit_status.dart';

class RequestVisitModel {
  bool? success;
  String? message;
  RequestVisitData? data;

  RequestVisitModel({this.success, this.message, this.data});

  RequestVisitModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? RequestVisitData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class RequestVisitData {
  String? visitId;
  String? propertyId;
  String? buyerId;
  String? partnerId;
  String? leadId;
  VisitBuyerSnapshot? buyerSnapshot;
  VisitPropertySnapshot? propertySnapshot;
  VisitPartnerSnapshot? partnerSnapshot;
  String? requestedVisitAt;
  String? approvedVisitAt;
  String? completedAt;
  String? requestSource;
  String? teamOwnerId;
  String? teamApprovalStatus;
  String? teamRemarks;
  String? forwardedToAdminAt;
  String? approvalStatus;
  String? status;
  String? outcome;
  String? requestNotes;
  String? adminRemarks;
  String? partnerRemarks;
  String? followUpAt;
  String? rescheduleReason;
  String? cancellationReason;
  VisitRequestedBy? requestedBy;
  VisitApprovedBy? approvedBy;
  List<VisitHistory>? history;
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  RequestVisitData({
    this.visitId,
    this.propertyId,
    this.buyerId,
    this.partnerId,
    this.leadId,
    this.buyerSnapshot,
    this.propertySnapshot,
    this.partnerSnapshot,
    this.requestedVisitAt,
    this.approvedVisitAt,
    this.completedAt,
    this.requestSource,
    this.teamOwnerId,
    this.teamApprovalStatus,
    this.teamRemarks,
    this.forwardedToAdminAt,
    this.approvalStatus,
    this.status,
    this.outcome,
    this.requestNotes,
    this.adminRemarks,
    this.partnerRemarks,
    this.followUpAt,
    this.rescheduleReason,
    this.cancellationReason,
    this.requestedBy,
    this.approvedBy,
    this.history,
    this.sId,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  RequestVisitData.fromJson(Map<String, dynamic> json) {
    visitId = json['visitId'];
    propertyId = json['propertyId'];
    buyerId = json['buyerId'];
    partnerId = json['partnerId'];
    leadId = json['leadId']?.toString();
    buyerSnapshot = json['buyerSnapshot'] != null
        ? VisitBuyerSnapshot.fromJson(json['buyerSnapshot'])
        : null;
    propertySnapshot = json['propertySnapshot'] != null
        ? VisitPropertySnapshot.fromJson(json['propertySnapshot'])
        : null;
    partnerSnapshot = json['partnerSnapshot'] != null
        ? VisitPartnerSnapshot.fromJson(json['partnerSnapshot'])
        : null;
    requestedVisitAt = json['requestedVisitAt'];
    approvedVisitAt = json['approvedVisitAt']?.toString();
    completedAt = json['completedAt']?.toString();
    requestSource = json['requestSource'];
    teamOwnerId = json['teamOwnerId']?.toString();
    teamApprovalStatus = json['teamApprovalStatus'];
    teamRemarks = json['teamRemarks'];
    forwardedToAdminAt = json['forwardedToAdminAt'];
    approvalStatus = json['approvalStatus'];
    status = json['status'];
    outcome = json['outcome'];
    requestNotes = json['requestNotes'];
    adminRemarks = json['adminRemarks'];
    partnerRemarks = json['partnerRemarks'];
    followUpAt = json['followUpAt']?.toString();
    rescheduleReason = json['rescheduleReason'];
    cancellationReason = json['cancellationReason'];
    requestedBy = json['requestedBy'] != null
        ? VisitRequestedBy.fromJson(json['requestedBy'])
        : null;
    approvedBy = json['approvedBy'] != null
        ? VisitApprovedBy.fromJson(json['approvedBy'])
        : null;
    if (json['history'] != null) {
      history = <VisitHistory>[];
      for (var v in (json['history'] as List)) {
        history!.add(VisitHistory.fromJson(v));
      }
    }
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['visitId'] = visitId;
    data['propertyId'] = propertyId;
    data['buyerId'] = buyerId;
    data['partnerId'] = partnerId;
    data['leadId'] = leadId;
    if (buyerSnapshot != null) data['buyerSnapshot'] = buyerSnapshot!.toJson();
    if (propertySnapshot != null) data['propertySnapshot'] = propertySnapshot!.toJson();
    if (partnerSnapshot != null) data['partnerSnapshot'] = partnerSnapshot!.toJson();
    data['requestedVisitAt'] = requestedVisitAt;
    data['approvedVisitAt'] = approvedVisitAt;
    data['completedAt'] = completedAt;
    data['requestSource'] = requestSource;
    data['teamOwnerId'] = teamOwnerId;
    data['teamApprovalStatus'] = teamApprovalStatus;
    data['teamRemarks'] = teamRemarks;
    data['forwardedToAdminAt'] = forwardedToAdminAt;
    data['approvalStatus'] = approvalStatus;
    data['status'] = status;
    data['outcome'] = outcome;
    data['requestNotes'] = requestNotes;
    data['adminRemarks'] = adminRemarks;
    data['partnerRemarks'] = partnerRemarks;
    data['followUpAt'] = followUpAt;
    data['rescheduleReason'] = rescheduleReason;
    data['cancellationReason'] = cancellationReason;
    if (requestedBy != null) data['requestedBy'] = requestedBy!.toJson();
    if (approvedBy != null) data['approvedBy'] = approvedBy!.toJson();
    if (history != null) data['history'] = history!.map((v) => v.toJson()).toList();
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}