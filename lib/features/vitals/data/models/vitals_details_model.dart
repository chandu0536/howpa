import 'dart:convert';
import 'package:howpa_nurse/features/visits/data/models/visit_models.dart';

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
        name: json['name']?.toString() ?? json['vitalName']?.toString() ?? json['title']?.toString() ?? '',
        value: json['value']?.toString() ?? json['reading']?.toString() ?? '',
        unit: json['unit']?.toString() ?? '',
        details: json['details']?.toString() ?? json['notes']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Normal',
        fileUrl: json['fileUrl']?.toString() ??
            json['url']?.toString() ??
            json['imageUrl']?.toString() ??
            json['image']?.toString() ??
            json['photo']?.toString() ??
            json['photoUrl']?.toString() ??
            json['meterPhoto']?.toString() ??
            json['meterPhotoUrl']?.toString() ??
            json['meterImage']?.toString() ??
            json['path']?.toString() ??
            json['filePath']?.toString() ??
            json['proofUrl']?.toString() ??
            '',
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
        url: json['url']?.toString() ??
            json['imageUrl']?.toString() ??
            json['image']?.toString() ??
            json['photo']?.toString() ??
            json['photoUrl']?.toString() ??
            json['path']?.toString() ??
            json['filePath']?.toString() ??
            json['fileUrl']?.toString() ??
            '',
        caption: json['caption']?.toString() ?? json['title']?.toString() ?? json['description']?.toString() ?? '',
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
        url: json['url']?.toString() ??
            json['fileUrl']?.toString() ??
            json['documentUrl']?.toString() ??
            json['reportUrl']?.toString() ??
            json['imageUrl']?.toString() ??
            json['image']?.toString() ??
            json['path']?.toString() ??
            json['filePath']?.toString() ??
            '',
        name: json['name']?.toString() ?? json['fileName']?.toString() ?? json['title']?.toString() ?? 'Medical Report',
        type: json['type']?.toString() ?? json['fileType']?.toString() ?? 'Medical Report',
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
  final String? orderId;
  final String familyMemberId;
  final String patientName;
  final String patientPhone;
  final String patientAvatar;
  final String patientAddress;
  final bool isFamilyMember;
  final String patientAge;
  final String patientGender;
  final String relation;
  final List<VitalItemEntry> vitals;
  final List<ConditionPhotoEntry> conditionPhotos;
  final List<OldReportEntry> oldReports;
  final String notes;
  final String recordedAt;

  PatientVitalsSummary({
    required this.id,
    required this.requestId,
    this.appointmentId = '',
    this.orderId,
    this.familyMemberId = '',
    this.patientName = 'Patient',
    this.patientPhone = '',
    this.patientAvatar = '',
    this.patientAddress = '',
    this.isFamilyMember = false,
    this.patientAge = '',
    this.patientGender = '',
    this.relation = '',
    this.vitals = const [],
    this.conditionPhotos = const [],
    this.oldReports = const [],
    this.notes = '',
    this.recordedAt = '',
  });

  factory PatientVitalsSummary.fromJson(Map<String, dynamic> json) {
    dynamic rawVitals = json['vitals'] ?? json['vitalSigns'] ?? json['vital_items'];
    if (rawVitals is String && rawVitals.trim().isNotEmpty) {
      try {
        rawVitals = jsonDecode(rawVitals);
      } catch (_) {}
    }
    final List vitalsList = rawVitals is List ? rawVitals : [];

    dynamic rawPhotos = json['conditionPhotos'] ??
        json['condition_photos'] ??
        json['conditionImages'] ??
        json['condition_images'] ??
        json['woundPhotos'] ??
        json['wound_photos'] ??
        json['photos'];
    if (rawPhotos is String && rawPhotos.trim().isNotEmpty) {
      try {
        rawPhotos = jsonDecode(rawPhotos);
      } catch (_) {}
    }
    final List photosList = rawPhotos is List ? rawPhotos : [];

    dynamic rawReports = json['oldReports'] ??
        json['old_reports'] ??
        json['reports'] ??
        json['medicalReports'] ??
        json['report_files'] ??
        json['reportFiles'] ??
        json['documents'];
    if (rawReports is String && rawReports.trim().isNotEmpty) {
      try {
        rawReports = jsonDecode(rawReports);
      } catch (_) {}
    }
    final List reportsList = rawReports is List ? rawReports : [];

    final List<VitalItemEntry> parsedVitals = [];

    if (vitalsList.isNotEmpty) {
      for (final item in vitalsList) {
        if (item is Map<String, dynamic>) {
          parsedVitals.add(VitalItemEntry.fromJson(item));
        } else if (item is Map) {
          parsedVitals.add(VitalItemEntry.fromJson(Map<String, dynamic>.from(item)));
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
              fileUrl: cv['imagePath']?.toString() ?? cv['fileUrl']?.toString() ?? cv['url']?.toString() ?? '',
            ));
          }
        }
      }
    }

    final List<ConditionPhotoEntry> parsedPhotos = [];
    for (int i = 0; i < photosList.length; i++) {
      final item = photosList[i];
      if (item is Map<String, dynamic>) {
        parsedPhotos.add(ConditionPhotoEntry.fromJson(item));
      } else if (item is Map) {
        parsedPhotos.add(ConditionPhotoEntry.fromJson(Map<String, dynamic>.from(item)));
      } else if (item is String && item.isNotEmpty) {
        parsedPhotos.add(ConditionPhotoEntry(url: item, caption: 'Condition Photo #${i + 1}'));
      }
    }

    final List<OldReportEntry> parsedReports = [];
    for (int i = 0; i < reportsList.length; i++) {
      final item = reportsList[i];
      if (item is Map<String, dynamic>) {
        parsedReports.add(OldReportEntry.fromJson(item));
      } else if (item is Map) {
        parsedReports.add(OldReportEntry.fromJson(Map<String, dynamic>.from(item)));
      } else if (item is String && item.isNotEmpty) {
        final fileName = item.split(RegExp(r'[/\\]')).last;
        parsedReports.add(OldReportEntry(
          url: item,
          name: fileName.isNotEmpty ? fileName : 'Report #${i + 1}',
          type: item.toLowerCase().endsWith('.pdf') ? 'PDF Report' : 'Medical Report',
        ));
      }
    }

    final rawFamilyMemberId = json['familyMemberId']?.toString();
    final bool isFamilyMember = rawFamilyMemberId != null &&
        rawFamilyMemberId.trim().isNotEmpty &&
        rawFamilyMemberId.trim() != 'null';

    final familyMemberObj = json['familyMember'] is Map ? json['familyMember'] as Map<String, dynamic> : null;
    final familyMemberDetails = json['familyMemberDetails'] is Map ? json['familyMemberDetails'] as Map<String, dynamic> : null;
    final memberObj = familyMemberObj ?? familyMemberDetails;

    final String name = memberObj?['name']?.toString() ??
        json['patientName']?.toString() ??
        json['patient']?['name']?.toString() ??
        'Patient';

    final String phone = memberObj?['phone']?.toString() ??
        memberObj?['mobile']?.toString() ??
        json['patientPhone']?.toString() ??
        json['patient']?['phone']?.toString() ??
        '';

    final String avatar = extractAvatarUrl(json);

    final String age = memberObj?['age']?.toString() ??
        memberObj?['patientAge']?.toString() ??
        json['patientAge']?.toString() ??
        json['patient_age']?.toString() ??
        json['age']?.toString() ??
        json['patient']?['age']?.toString() ??
        json['patientDetails']?['age']?.toString() ??
        json['user']?['age']?.toString() ??
        json['demographics']?['age']?.toString() ??
        '';

    final String gender = memberObj?['gender']?.toString() ??
        memberObj?['patientGender']?.toString() ??
        json['patientGender']?.toString() ??
        json['patient_gender']?.toString() ??
        json['gender']?.toString() ??
        json['sex']?.toString() ??
        json['patient']?['gender']?.toString() ??
        json['patientDetails']?['gender']?.toString() ??
        json['user']?['gender']?.toString() ??
        json['demographics']?['gender']?.toString() ??
        '';

    final String rel = memberObj?['relation']?.toString() ??
        memberObj?['relationship']?.toString() ??
        json['relation']?.toString() ??
        json['relationship']?.toString() ??
        (isFamilyMember ? 'Family Member' : '');

    return PatientVitalsSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['requestId']?.toString() ?? json['appointmentId']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? json['id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? json['bookingId']?.toString(),
      familyMemberId: rawFamilyMemberId ?? '',
      patientName: name,
      patientPhone: phone,
      patientAvatar: avatar,
      patientAddress: json['patientAddress']?.toString() ?? json['patient']?['address']?.toString() ?? '',
      isFamilyMember: isFamilyMember,
      patientAge: age,
      patientGender: gender,
      relation: rel,
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
        'orderId': orderId,
        'familyMemberId': familyMemberId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'patientAvatar': patientAvatar,
        'patientAddress': patientAddress,
        'isFamilyMember': isFamilyMember,
        'patientAge': patientAge,
        'patientGender': patientGender,
        'relation': relation,
        'vitals': vitals.map((v) => v.toJson()).toList(),
        'conditionPhotos': conditionPhotos.map((c) => c.toJson()).toList(),
        'oldReports': oldReports.map((r) => r.toJson()).toList(),
        'notes': notes,
        'recordedAt': recordedAt,
      };

  String serialize() => jsonEncode(toJson());

  String get displayOrderId {
    if (orderId != null && orderId!.trim().isNotEmpty && orderId != 'null') {
      return orderId!.trim();
    }
    if (appointmentId.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(appointmentId)) {
      return appointmentId;
    }
    if (requestId.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(requestId)) {
      return requestId;
    }
    if (id.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return id;
    }
    return '';
  }

  factory PatientVitalsSummary.deserialize(String source) =>
      PatientVitalsSummary.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
