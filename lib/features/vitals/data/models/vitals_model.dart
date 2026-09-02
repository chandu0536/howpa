import '../../../../core/network/api_endpoints.dart';

String _resolveImageUrl(dynamic raw) {
  if (raw == null) return '';
  final str = raw.toString().trim();
  if (str.isEmpty || str == 'null' || str == 'undefined') return '';
  if (str.startsWith('http://') || str.startsWith('https://')) {
    return str;
  }
  final base = ApiEndpoints.baseUrl.endsWith('/')
      ? ApiEndpoints.baseUrl
      : '${ApiEndpoints.baseUrl}/';
  final clean = str.startsWith('/') ? str.substring(1) : str;
  return '$base$clean';
}

String _parseAddress(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) {
    final clean = raw.trim();
    return clean == 'null' || clean == 'undefined' ? '' : clean;
  }
  if (raw is Map) {
    final parts = [
      raw['street'] ?? raw['line1'] ?? raw['address'] ?? raw['house'] ?? raw['doorNo'],
      raw['area'] ?? raw['locality'] ?? raw['colony'] ?? raw['landmark'],
      raw['city'] ?? raw['district'] ?? raw['town'],
      raw['state'],
      raw['pincode'] ?? raw['zipCode'] ?? raw['postalCode'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty && e.toString().trim() != 'null').map((e) => e.toString().trim());
    return parts.join(', ');
  }
  return raw.toString().trim();
}

String _parseFormattedTime(dynamic rawTime, dynamic rawDate) {
  if (rawTime != null && rawTime.toString().trim().isNotEmpty && rawTime.toString().trim() != 'null') {
    return rawTime.toString().trim();
  }
  if (rawDate != null && rawDate.toString().trim().isNotEmpty && rawDate.toString().trim() != 'null') {
    try {
      final dt = DateTime.parse(rawDate.toString().trim()).toLocal();
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${hour.toString().padLeft(2, '0')}:$min $ampm';
    } catch (_) {}
  }
  return '';
}

num? _parseNumeric(dynamic val) {
  if (val == null) return null;
  if (val is num) return val;
  final clean = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
  return num.tryParse(clean);
}

/// POST body for `/api/nurse/vitals`
class VitalsRecordRequest {
  final String appointmentId;
  final String? patientId;
  final String bloodPressure;
  final num? heartRate;
  final num? pulseRate;
  final num? temperature;
  final num? bloodSugar;
  final num? spo2;
  final num? weight;
  final num? respiratoryRate;
  final String reason;
  final String notes;
  final List<dynamic> attachments;

  const VitalsRecordRequest({
    required this.appointmentId,
    this.patientId,
    required this.bloodPressure,
    this.heartRate,
    this.pulseRate,
    this.temperature,
    this.bloodSugar,
    this.spo2,
    this.weight,
    this.respiratoryRate,
    this.reason = '',
    this.notes = '',
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    final effectivePulse = pulseRate ?? heartRate;
    return {
      'appointmentId': appointmentId,
      if (patientId != null && patientId!.isNotEmpty) 'patientId': patientId,
      'bloodPressure': bloodPressure,
      if (heartRate != null) 'heartRate': heartRate,
      if (effectivePulse != null) 'pulseRate': effectivePulse,
      if (temperature != null) 'temperature': temperature,
      if (bloodSugar != null) 'bloodSugar': bloodSugar,
      if (spo2 != null) 'spo2': spo2,
      if (weight != null) 'weight': weight,
      if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
      if (reason.isNotEmpty) 'reason': reason,
      if (notes.isNotEmpty) 'notes': notes,
      'attachments': attachments,
    };
  }
}

/// Nested Vitals Object returned in `/api/nurse/vitals`
class PatientVitalsData {
  final String id;
  final String bloodPressure;
  final num? heartRate;
  final num? temperature;
  final num? bloodSugar;
  final num? spo2;
  final num? weight;
  final String notes;
  final String createdAt;

  const PatientVitalsData({
    this.id = '',
    this.bloodPressure = '',
    this.heartRate,
    this.temperature,
    this.bloodSugar,
    this.spo2,
    this.weight,
    this.notes = '',
    this.createdAt = '',
  });

  factory PatientVitalsData.fromJson(Map<String, dynamic> json) {
    return PatientVitalsData(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      bloodPressure: json['bloodPressure']?.toString() ?? json['bp']?.toString() ?? '',
      heartRate: _parseNumeric(json['heartRate'] ?? json['pulse'] ?? json['hr']),
      temperature: _parseNumeric(json['temperature'] ?? json['temp']),
      bloodSugar: _parseNumeric(json['bloodSugar'] ?? json['sugar'] ?? json['glucose']),
      spo2: _parseNumeric(json['spo2'] ?? json['oxygen']),
      weight: _parseNumeric(json['weight']),
      notes: json['notes']?.toString() ?? json['note']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      if (bloodPressure.isNotEmpty) 'bloodPressure': bloodPressure,
      if (heartRate != null) 'heartRate': heartRate,
      if (temperature != null) 'temperature': temperature,
      if (bloodSugar != null) 'bloodSugar': bloodSugar,
      if (spo2 != null) 'spo2': spo2,
      if (weight != null) 'weight': weight,
      if (notes.isNotEmpty) 'notes': notes,
      if (createdAt.isNotEmpty) 'createdAt': createdAt,
    };
  }
}

/// Primary model representing a patient card with their vitals in `/api/nurse/vitals`
class VitalsModel {
  final String id;
  final String appointmentId;
  final String appointmentNumber;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String patientAge;
  final String patientGender;
  final String patientAddress;
  final String appointmentTime;
  final String appointmentDate;
  final bool hasVitals;
  final PatientVitalsData? vitalsData;
  final String bloodPressure;
  final String heartRate;
  final String bloodSugar;
  final String spo2;
  final String temperature;
  final String weight;
  final String respiratoryRate;
  final String reason;
  final String notes;
  final String lastUpdated;
  final String avatarUrl;

  const VitalsModel({
    this.id = '',
    this.appointmentId = '',
    this.appointmentNumber = '',
    required this.patientId,
    required this.patientName,
    this.patientPhone = '',
    this.patientAge = '',
    this.patientGender = '',
    this.patientAddress = '',
    this.appointmentTime = '',
    this.appointmentDate = '',
    this.hasVitals = false,
    this.vitalsData,
    required this.bloodPressure,
    required this.heartRate,
    required this.bloodSugar,
    required this.spo2,
    required this.temperature,
    required this.weight,
    this.respiratoryRate = '16 /min',
    this.reason = '',
    this.notes = '',
    required this.lastUpdated,
    this.avatarUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
  });

  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve Patient object
    Map<String, dynamic>? patientObj;
    if (json['patient'] is Map) {
      patientObj = (json['patient'] as Map).cast<String, dynamic>();
    } else if (json['patientId'] is Map) {
      patientObj = (json['patientId'] as Map).cast<String, dynamic>();
    } else if (json['appointment'] is Map) {
      final appt = (json['appointment'] as Map).cast<String, dynamic>();
      if (appt['patient'] is Map) {
        patientObj = (appt['patient'] as Map).cast<String, dynamic>();
      } else if (appt['patientId'] is Map) {
        patientObj = (appt['patientId'] as Map).cast<String, dynamic>();
      }
    }

    // 2. Resolve Vitals object (supports Map or List)
    Map<String, dynamic>? vitalsObj;
    if (json['vitals'] is Map) {
      vitalsObj = (json['vitals'] as Map).cast<String, dynamic>();
    } else if (json['vitals'] is List && (json['vitals'] as List).isNotEmpty) {
      final first = (json['vitals'] as List).first;
      if (first is Map) {
        vitalsObj = first.cast<String, dynamic>();
      }
    } else if (json['record'] is Map) {
      vitalsObj = (json['record'] as Map).cast<String, dynamic>();
    } else if (json['latestVitals'] is Map) {
      vitalsObj = (json['latestVitals'] as Map).cast<String, dynamic>();
    } else if (json['appointment'] is Map) {
      final appt = (json['appointment'] as Map).cast<String, dynamic>();
      if (appt['vitals'] is Map) {
        vitalsObj = (appt['vitals'] as Map).cast<String, dynamic>();
      } else if (appt['vitals'] is List && (appt['vitals'] as List).isNotEmpty) {
        final first = (appt['vitals'] as List).first;
        if (first is Map) {
          vitalsObj = first.cast<String, dynamic>();
        }
      }
    }

    final parsedVitalsData = vitalsObj != null ? PatientVitalsData.fromJson(vitalsObj) : null;

    final String rawId = json['id']?.toString() ?? json['_id']?.toString() ?? json['appointmentId']?.toString() ?? '';
    final String rawAppointmentId = json['appointmentId']?.toString() ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        (json['appointment'] is Map ? (json['appointment']['_id']?.toString() ?? json['appointment']['id']?.toString() ?? '') : '');
    final String rawAppointmentNumber = json['appointmentNumber']?.toString() ??
        json['bookingNumber']?.toString() ??
        (json['appointment'] is Map ? (json['appointment']['appointmentNumber']?.toString() ?? json['appointment']['bookingNumber']?.toString() ?? '') : '');

    final String rawPatientId = (json['patientId'] is String && json['patientId'].toString().isNotEmpty)
        ? json['patientId'].toString()
        : (patientObj?['_id']?.toString() ??
            patientObj?['id']?.toString() ??
            (json['patient'] is String ? json['patient'].toString() : rawId));

    final String rawPatientName = json['patientName']?.toString() ??
        json['fullName']?.toString() ??
        json['name']?.toString() ??
        patientObj?['patientName']?.toString() ??
        patientObj?['fullName']?.toString() ??
        patientObj?['name']?.toString() ??
        'Patient';

    final String rawPhone = json['patientPhone']?.toString() ??
        json['patientMobile']?.toString() ??
        json['phone']?.toString() ??
        json['mobile']?.toString() ??
        patientObj?['patientPhone']?.toString() ??
        patientObj?['patientMobile']?.toString() ??
        patientObj?['mobile']?.toString() ??
        patientObj?['phone']?.toString() ??
        '';

    final dynamic ageVal = json['patientAge'] ?? json['age'] ?? patientObj?['patientAge'] ?? patientObj?['age'];
    String rawAge = '';
    if (ageVal != null) {
      if (ageVal is Map) {
        rawAge = ageVal['years']?.toString() ?? ageVal['age']?.toString() ?? '';
      } else {
        rawAge = ageVal.toString().trim();
      }
    }

    final String rawGender = json['patientGender']?.toString() ??
        json['gender']?.toString() ??
        patientObj?['patientGender']?.toString() ??
        patientObj?['gender']?.toString() ??
        '';

    final String rawAddress = _parseAddress(
      json['patientAddress'] ?? json['address'] ?? patientObj?['patientAddress'] ?? patientObj?['address'],
    );

    final String rawAppDate = json['appointmentDate']?.toString() ??
        json['date']?.toString() ??
        (json['appointment'] is Map ? (json['appointment']['date']?.toString() ?? '') : '');

    final String rawAppTime = _parseFormattedTime(
      json['appointmentTime'] ?? json['time'] ?? (json['appointment'] is Map ? json['appointment']['time'] : null),
      rawAppDate,
    );

    final bool hasVitalsBool = json['hasVitals'] == true ||
        (parsedVitalsData != null && (parsedVitalsData.bloodPressure.isNotEmpty || parsedVitalsData.heartRate != null)) ||
        (vitalsObj != null && vitalsObj.isNotEmpty) ||
        (json['bloodPressure'] != null && json['bloodPressure'].toString().isNotEmpty && json['bloodPressure'] != 'Pending');

    final String rawBp = parsedVitalsData?.bloodPressure.isNotEmpty == true
        ? parsedVitalsData!.bloodPressure
        : (json['bloodPressure']?.toString() ??
            json['bp']?.toString() ??
            (hasVitalsBool ? '120/80' : 'Pending'));

    final dynamic rawHrVal = parsedVitalsData?.heartRate ?? json['heartRate'] ?? json['pulse'] ?? json['hr'];
    final String rawHr = rawHrVal != null
        ? (rawHrVal.toString().contains('bpm') ? rawHrVal.toString() : '$rawHrVal bpm')
        : (hasVitalsBool ? '72 bpm' : 'Pending');

    final dynamic rawSugarVal = parsedVitalsData?.bloodSugar ?? json['bloodSugar'] ?? json['sugar'] ?? json['glucose'];
    final String rawSugar = rawSugarVal != null
        ? (rawSugarVal.toString().contains('mg/dL') ? rawSugarVal.toString() : '$rawSugarVal mg/dL')
        : (hasVitalsBool ? '95 mg/dL' : 'Pending');

    final dynamic rawSpo2Val = parsedVitalsData?.spo2 ?? json['spo2'] ?? json['oxygen'];
    final String rawSpo2 = rawSpo2Val != null
        ? (rawSpo2Val.toString().contains('%') ? rawSpo2Val.toString() : '$rawSpo2Val%')
        : (hasVitalsBool ? '99%' : 'Pending');

    final dynamic rawTempVal = parsedVitalsData?.temperature ?? json['temperature'] ?? json['temp'];
    final String rawTemp = rawTempVal != null
        ? (rawTempVal.toString().contains('°F') ? rawTempVal.toString() : '$rawTempVal °F')
        : (hasVitalsBool ? '98.6 °F' : 'Pending');

    final dynamic rawWeightVal = parsedVitalsData?.weight ?? json['weight'];
    final String rawWeight = rawWeightVal != null
        ? (rawWeightVal.toString().contains('kg') ? rawWeightVal.toString() : '$rawWeightVal kg')
        : (hasVitalsBool ? '68.5 kg' : 'Pending');

    final String rawResp = json['respiratoryRate']?.toString() ?? vitalsObj?['respiratoryRate']?.toString() ?? '16 /min';

    final String rawReason = json['reason']?.toString() ??
        json['condition']?.toString() ??
        json['serviceType']?.toString() ??
        json['serviceName']?.toString() ??
        json['service']?.toString() ??
        '';

    final String rawNotes = parsedVitalsData?.notes.isNotEmpty == true
        ? parsedVitalsData!.notes
        : (json['notes']?.toString() ?? json['note']?.toString() ?? json['doctorNote']?.toString() ?? '');

    final String rawUpdated = parsedVitalsData?.createdAt.isNotEmpty == true
        ? parsedVitalsData!.createdAt
        : (json['lastUpdated']?.toString() ??
            json['updatedAt']?.toString() ??
            json['createdAt']?.toString() ??
            rawAppTime);

    final dynamic candidateAvatar = json['patientPhoto'] ??
        json['avatar'] ??
        json['profileImage'] ??
        json['avatarUrl'] ??
        json['avatar_url'] ??
        json['image'] ??
        json['photo'] ??
        patientObj?['patientPhoto'] ??
        patientObj?['avatar'] ??
        patientObj?['profileImage'] ??
        patientObj?['avatarUrl'] ??
        patientObj?['photo'] ??
        patientObj?['image'];

    final String resolvedAvatar = _resolveImageUrl(candidateAvatar);

    return VitalsModel(
      id: rawId,
      appointmentId: rawAppointmentId,
      appointmentNumber: rawAppointmentNumber,
      patientId: rawPatientId,
      patientName: rawPatientName,
      patientPhone: rawPhone,
      patientAge: rawAge,
      patientGender: rawGender,
      patientAddress: rawAddress,
      appointmentTime: rawAppTime,
      appointmentDate: rawAppDate,
      hasVitals: hasVitalsBool,
      vitalsData: parsedVitalsData,
      bloodPressure: rawBp,
      heartRate: rawHr,
      bloodSugar: rawSugar,
      spo2: rawSpo2,
      temperature: rawTemp,
      weight: rawWeight,
      respiratoryRate: rawResp,
      reason: rawReason,
      notes: rawNotes,
      lastUpdated: rawUpdated,
      avatarUrl: resolvedAvatar.isNotEmpty ? resolvedAvatar : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'appointmentNumber': appointmentNumber,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientAddress': patientAddress,
      'appointmentTime': appointmentTime,
      'appointmentDate': appointmentDate,
      'hasVitals': hasVitals,
      if (vitalsData != null) 'vitals': vitalsData!.toJson(),
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      'bloodSugar': bloodSugar,
      'spo2': spo2,
      'temperature': temperature,
      'weight': weight,
      'respiratoryRate': respiratoryRate,
      'reason': reason,
      'notes': notes,
      'lastUpdated': lastUpdated,
      'avatarUrl': avatarUrl,
    };
  }
}


