// POST /leads/from-property request/response model.
//
// Backend source (per ApiConstants.createLeadFromProperty):
//   POST {baseUrl}/leads/from-property
//
// Exact response shape isn't documented anywhere in this repo, so this is
// parsed defensively the same way VisitRepository/AgentRepository handle
// unknown envelopes — it accepts either:
//   { success, message, data: { ...leadFields } }
// or a bare lead object at the root, and never throws on missing fields.
class LeadModel {
  bool? success;
  String? message;
  LeadData? data;

  LeadModel({this.success, this.message, this.data});

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return LeadModel(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString(),
      data: rawData is Map
          ? LeadData.fromJson(Map<String, dynamic>.from(rawData))
          // Some "create" endpoints return the created object at the
          // root instead of nesting it under `data` — fall back to that.
          : LeadData.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class LeadData {
  String? sId;
  String? leadId;
  String? propertyId;
  String? buyerId;
  String? partnerId;
  String? name;
  String? phone;
  String? email;
  String? message;
  String? source;
  String? contactPreference;
  String? status;
  String? createdAt;

  LeadData({
    this.sId,
    this.leadId,
    this.propertyId,
    this.buyerId,
    this.partnerId,
    this.name,
    this.phone,
    this.email,
    this.message,
    this.source,
    this.contactPreference,
    this.status,
    this.createdAt,
  });

  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
        sId: json['_id']?.toString(),
        leadId: json['leadId']?.toString(),
        propertyId: json['propertyId']?.toString(),
        buyerId: json['buyerId']?.toString(),
        partnerId: json['partnerId']?.toString(),
        name: json['name']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        message: json['message']?.toString(),
        source: json['source']?.toString(),
        contactPreference: json['contactPreference']?.toString(),
        status: json['status']?.toString(),
        createdAt: json['createdAt']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        '_id': sId,
        'leadId': leadId,
        'propertyId': propertyId,
        'buyerId': buyerId,
        'partnerId': partnerId,
        'name': name,
        'phone': phone,
        'email': email,
        'message': message,
        'source': source,
        'contactPreference': contactPreference,
        'status': status,
        'createdAt': createdAt,
      };
}
