// GET /visits/:id response model
class VisitStatusModel {
  bool? success;
  VisitStatusData? data;

  VisitStatusModel({this.success, this.data});

  VisitStatusModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? VisitStatusData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class VisitStatusData {
  String? sId;
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
  String? createdAt;
  String? updatedAt;
  int? iV;

  VisitStatusData({
    this.sId,
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
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  VisitStatusData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
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
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
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
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}

class VisitBuyerSnapshot {
  String? buyerCode;
  String? name;
  String? phone;
  String? email;
  String? city;

  VisitBuyerSnapshot({this.buyerCode, this.name, this.phone, this.email, this.city});

  VisitBuyerSnapshot.fromJson(Map<String, dynamic> json) {
    buyerCode = json['buyerCode'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    city = json['city'];
  }

  Map<String, dynamic> toJson() => {
    'buyerCode': buyerCode,
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
  };
}

class VisitPropertySnapshot {
  String? propertyCode;
  String? title;
  String? projectName;
  String? category;
  String? city;
  String? locality;
  String? address;
  String? image;
  double? latitude;
  double? longitude;

  VisitPropertySnapshot({
    this.propertyCode,
    this.title,
    this.projectName,
    this.category,
    this.city,
    this.locality,
    this.address,
    this.image,
    this.latitude,
    this.longitude,
  });

  VisitPropertySnapshot.fromJson(Map<String, dynamic> json) {
    propertyCode = json['propertyCode'];
    title = json['title'];
    projectName = json['projectName'];
    category = json['category'];
    city = json['city'];
    locality = json['locality'];
    address = json['address'];
    image = json['image'];
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() => {
    'propertyCode': propertyCode,
    'title': title,
    'projectName': projectName,
    'category': category,
    'city': city,
    'locality': locality,
    'address': address,
    'image': image,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class VisitPartnerSnapshot {
  String? partnerCode;
  String? name;
  String? phone;
  String? email;
  String? partnerType;

  VisitPartnerSnapshot({this.partnerCode, this.name, this.phone, this.email, this.partnerType});

  VisitPartnerSnapshot.fromJson(Map<String, dynamic> json) {
    partnerCode = json['partnerCode'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    partnerType = json['partnerType'];
  }

  Map<String, dynamic> toJson() => {
    'partnerCode': partnerCode,
    'name': name,
    'phone': phone,
    'email': email,
    'partnerType': partnerType,
  };
}

class VisitRequestedBy {
  String? userId;
  String? name;
  String? role;

  VisitRequestedBy({this.userId, this.name, this.role});

  VisitRequestedBy.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    name = json['name'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'role': role,
  };
}

class VisitApprovedBy {
  String? userId;
  String? name;
  String? role;
  String? approvedAt;

  VisitApprovedBy({this.userId, this.name, this.role, this.approvedAt});

  VisitApprovedBy.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    name = json['name'];
    role = json['role'];
    approvedAt = json['approvedAt']?.toString();
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'role': role,
    'approvedAt': approvedAt,
  };
}

class VisitHistory {
  String? action;
  String? fromStatus;
  String? toStatus;
  String? remarks;
  VisitRequestedBy? updatedBy;
  String? sId;
  String? updatedAt;

  VisitHistory({
    this.action,
    this.fromStatus,
    this.toStatus,
    this.remarks,
    this.updatedBy,
    this.sId,
    this.updatedAt,
  });

  VisitHistory.fromJson(Map<String, dynamic> json) {
    action = json['action'];
    fromStatus = json['fromStatus'];
    toStatus = json['toStatus'];
    remarks = json['remarks'];
    updatedBy = json['updatedBy'] != null ? VisitRequestedBy.fromJson(json['updatedBy']) : null;
    sId = json['_id'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() => {
    'action': action,
    'fromStatus': fromStatus,
    'toStatus': toStatus,
    'remarks': remarks,
    if (updatedBy != null) 'updatedBy': updatedBy!.toJson(),
    '_id': sId,
    'updatedAt': updatedAt,
  };
}