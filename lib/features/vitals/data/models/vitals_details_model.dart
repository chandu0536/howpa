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
    final rawPhotos = json['conditionPhotos'] as List? ?? json['condition_photos'] as List? ?? json['conditionImages'] as List? ?? [];
    final rawReports = json['oldReports'] as List? ?? json['old_reports'] as List? ?? json['reports'] as List? ?? [];

    final List<VitalItemEntry> parsedVitals = [];

    if (rawVitals.isNotEmpty) {
      for (final item in rawVitals) {
        if (item is Map<String, dynamic>) {
          parsedVitals.add(VitalItemEntry.fromJson(item));
        }
      }
    }

    // Fallback: If vitals list is not provided or empty, check flat JSON fields
    if (parsedVitals.isEmpty) {
      final bp = json['bloodPressure']?.toString() ?? json['bp']?.toString() ?? json['bpValue']?.toString();
      final hr = json['heartRate']?.toString() ?? json['pulse']?.toString() ?? json['pulseRate']?.toString();
      final temp = json['temperature']?.toString() ?? json['temp']?.toString();
      final sugar = json['bloodSugar']?.toString() ?? json['sugar']?.toString() ?? json['glucose']?.toString();
      final spo2 = json['spo2']?.toString() ?? json['oxygen']?.toString();
      final weight = json['weight']?.toString();

      if (bp != null && bp.isNotEmpty) {
        parsedVitals.add(VitalItemEntry(
          name: 'Blood Pressure',
          value: bp,
          unit: 'mmHg',
          details: 'Standard BP Reading',
          fileUrl: json['bp_image']?.toString() ?? json['bpImage']?.toString() ?? '',
        ));
      }
      if (hr != null && hr.isNotEmpty) {
        parsedVitals.add(VitalItemEntry(
          name: 'Heart Rate',
          value: hr,
          unit: 'bpm',
          details: 'Radial Pulse',
          fileUrl: json['pulse_image']?.toString() ?? json['pulseImage']?.toString() ?? '',
        ));
      }
      if (temp != null && temp.isNotEmpty) {
        parsedVitals.add(VitalItemEntry(
          name: 'Temperature',
          value: temp,
          unit: '°F',
          details: 'Thermometer',
          fileUrl: json['temp_image']?.toString() ?? json['tempImage']?.toString() ?? '',
        ));
      }
      if (sugar != null && sugar.isNotEmpty && sugar != '0') {
        parsedVitals.add(VitalItemEntry(
          name: 'Blood Glucose (Sugar)',
          value: sugar,
          unit: 'mg/dL',
          details: 'Glucometer Reading',
          fileUrl: json['sugar_image']?.toString() ?? json['sugarImage']?.toString() ?? '',
        ));
      }
      if (spo2 != null && spo2.isNotEmpty && spo2 != '0') {
        parsedVitals.add(VitalItemEntry(
          name: 'Pulse Oximeter (SpO2)',
          value: spo2,
          unit: '%',
          details: 'Oxygen Saturation',
          fileUrl: json['spo2_image']?.toString() ?? json['spo2Image']?.toString() ?? '',
        ));
      }
      if (weight != null && weight.isNotEmpty && weight != '0' && weight != '0.0') {
        parsedVitals.add(VitalItemEntry(
          name: 'Weight',
          value: weight,
          unit: 'kg',
          details: 'Body Weight',
          fileUrl: json['weight_image']?.toString() ?? json['weightImage']?.toString() ?? '',
        ));
      }

      if (json['customVitals'] is List) {
        for (final cv in json['customVitals'] as List) {
          if (cv is Map) {
            parsedVitals.add(VitalItemEntry(
              name: cv['type']?.toString() ?? cv['name']?.toString() ?? 'Custom Vital',
              value: cv['value']?.toString() ?? '',
              unit: cv['unit']?.toString() ?? '',
              fileUrl: cv['imagePath']?.toString() ?? cv['fileUrl']?.toString() ?? '',
            ));
          }
        }
      }
    }

    final List<ConditionPhotoEntry> parsedPhotos = [];
    for (final item in rawPhotos) {
      if (item is Map<String, dynamic>) {
        parsedPhotos.add(ConditionPhotoEntry.fromJson(item));
      } else if (item is String && item.isNotEmpty) {
        parsedPhotos.add(ConditionPhotoEntry(url: item, caption: 'Condition Photo'));
      }
    }

    final List<OldReportEntry> parsedReports = [];
    for (final item in rawReports) {
      if (item is Map<String, dynamic>) {
        parsedReports.add(OldReportEntry.fromJson(item));
      } else if (item is String && item.isNotEmpty) {
        parsedReports.add(OldReportEntry(
          url: item,
          name: item.split(RegExp(r'[/\\]')).last,
          type: item.toLowerCase().endsWith('.pdf') ? 'PDF Report' : 'Medical Report',
        ));
      }
    }

    return PatientVitalsSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['requestId']?.toString() ?? json['appointmentId']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? json['id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? json['id']?.toString() ?? '',
      familyMemberId: json['familyMemberId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? json['patient']?['name']?.toString() ?? 'Patient',
      patientPhone: json['patientPhone']?.toString() ?? json['patient']?['phone']?.toString() ?? '',
      patientAvatar: json['patientAvatar']?.toString() ?? json['patient']?['avatar']?.toString() ?? '',
      patientAddress: json['patientAddress']?.toString() ?? json['patient']?['address']?.toString() ?? '',
      vitals: parsedVitals,
      conditionPhotos: parsedPhotos,
      oldReports: parsedReports,
      notes: json['notes']?.toString() ?? json['reason']?.toString() ?? '',
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
