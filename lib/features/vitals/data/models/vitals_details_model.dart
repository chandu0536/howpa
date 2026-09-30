import 'dart:convert';

class VitalItemEntry {
  final String name;
  final String value;
  final String unit;
  final String details;
  final String status;
  final String fileUrl;

  VitalItemEntry({
    required this.name,
    required this.value,
    this.unit = '',
    this.details = '',
    this.status = 'Normal',
    this.fileUrl = '',
  });

  factory VitalItemEntry.fromJson(Map<String, dynamic> json) => VitalItemEntry(
        name: json['name']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        unit: json['unit']?.toString() ?? '',
        details: json['details']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Normal',
        fileUrl: json['fileUrl']?.toString() ?? json['url']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'unit': unit,
        'details': details,
        'status': status,
        'fileUrl': fileUrl,
      };
}

class ConditionPhotoEntry {
  final String url;
  final String caption;

  ConditionPhotoEntry({required this.url, this.caption = ''});

  factory ConditionPhotoEntry.fromJson(Map<String, dynamic> json) => ConditionPhotoEntry(
        url: json['url']?.toString() ?? '',
        caption: json['caption']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'caption': caption,
      };
}

class OldReportEntry {
  final String url;
  final String name;
  final String type;

  OldReportEntry({required this.url, required this.name, this.type = 'Report'});

  factory OldReportEntry.fromJson(Map<String, dynamic> json) => OldReportEntry(
        url: json['url']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Medical Report',
        type: json['type']?.toString() ?? 'PDF Report',
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'type': type,
      };
}

class PatientVitalsSummary {
  final String id;
  final String requestId;
  final String appointmentId;
  final String familyMemberId;
  final String patientName;
  final String patientPhone;
  final String patientAvatar;
  final String patientAddress;
  final List<VitalItemEntry> vitals;
  final List<ConditionPhotoEntry> conditionPhotos;
  final List<OldReportEntry> oldReports;
  final String notes;
  final String recordedAt;

  PatientVitalsSummary({
    required this.id,
    required this.requestId,
    this.appointmentId = '',
    this.familyMemberId = '',
    this.patientName = 'Patient',
    this.patientPhone = '',
    this.patientAvatar = '',
    this.patientAddress = '',
    this.vitals = const [],
    this.conditionPhotos = const [],
    this.oldReports = const [],
    this.notes = '',
    this.recordedAt = '',
  });

  factory PatientVitalsSummary.fromJson(Map<String, dynamic> json) {
    final rawVitals = json['vitals'] as List? ?? [];
    final rawPhotos = json['conditionPhotos'] as List? ?? [];
    final rawReports = json['oldReports'] as List? ?? [];

    return PatientVitalsSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['requestId']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? json['id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      familyMemberId: json['familyMemberId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? json['patient']?['name']?.toString() ?? 'Patient',
      patientPhone: json['patientPhone']?.toString() ?? json['patient']?['phone']?.toString() ?? '',
      patientAvatar: json['patientAvatar']?.toString() ?? json['patient']?['avatar']?.toString() ?? '',
      patientAddress: json['patientAddress']?.toString() ?? json['patient']?['address']?.toString() ?? '',
      vitals: rawVitals.whereType<Map<String, dynamic>>().map(VitalItemEntry.fromJson).toList(),
      conditionPhotos: rawPhotos.whereType<Map<String, dynamic>>().map(ConditionPhotoEntry.fromJson).toList(),
      oldReports: rawReports.whereType<Map<String, dynamic>>().map(OldReportEntry.fromJson).toList(),
      notes: json['notes']?.toString() ?? '',
      recordedAt: json['recordedAt']?.toString() ?? json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'appointmentId': appointmentId,
        'familyMemberId': familyMemberId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'patientAvatar': patientAvatar,
        'patientAddress': patientAddress,
        'vitals': vitals.map((v) => v.toJson()).toList(),
        'conditionPhotos': conditionPhotos.map((c) => c.toJson()).toList(),
        'oldReports': oldReports.map((r) => r.toJson()).toList(),
        'notes': notes,
        'recordedAt': recordedAt,
      };

  String serialize() => jsonEncode(toJson());

  factory PatientVitalsSummary.deserialize(String source) =>
      PatientVitalsSummary.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
