import 'dart:convert';
import 'package:howpa_nurse/core/utils/constants.dart';

String formatImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) {
    return '';
  }
  final clean = rawUrl.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return clean;
  }
  if (clean.startsWith('/')) {
    return '${AppConstants.baseUrl}$clean';
  }
  return '${AppConstants.baseUrl}/$clean';
}

String _extractPatientName(Map<String, dynamic> json) {
  final candidates = <String>[];

  void addIfValid(dynamic val) {
    if (val == null) return;
    if (val is Map) {
      final map = val as Map<String, dynamic>;
      addIfValid(map['name']);
      addIfValid(map['patientName']);
      addIfValid(map['patient_name']);
      addIfValid(map['fullName']);
      addIfValid(map['full_name']);
      addIfValid(map['userName']);
      addIfValid(map['user_name']);
      addIfValid(map['firstName']);
      addIfValid(map['first_name']);
      if (map['firstName'] != null || map['first_name'] != null) {
        final fn = (map['firstName'] ?? map['first_name'] ?? '').toString().trim();
        final ln = (map['lastName'] ?? map['last_name'] ?? '').toString().trim();
        final combined = '$fn $ln'.trim();
        if (combined.isNotEmpty) addIfValid(combined);
      }
      return;
    }
    if (val is List) return;

    var s = val.toString().trim();
    while (s.endsWith('@') || s.endsWith('#') || s.endsWith(r'$')) {
      s = s.substring(0, s.length - 1).trim();
    }
    if (s.isEmpty ||
        s == 'null' ||
        s.toLowerCase() == 'patient' ||
        s.toLowerCase() == 'user' ||
        s.toLowerCase() == 'unknown' ||
        s.startsWith('{') ||
        s.startsWith('[')) {
      return;
    }
    // Ignore 24-character hex MongoDB ObjectIds
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(s)) {
      return;
    }
    candidates.add(s);
  }

  // 1. Root fields
  addIfValid(json['patientName']);
  addIfValid(json['patient_name']);
  addIfValid(json['fullName']);
  addIfValid(json['full_name']);
  addIfValid(json['userName']);
  addIfValid(json['user_name']);
  addIfValid(json['customerName']);
  addIfValid(json['customer_name']);
  addIfValid(json['name']);

  // 2. Root first + last name
  if (json['first_name'] != null || json['firstName'] != null) {
    final fn = (json['firstName'] ?? json['first_name'] ?? '').toString().trim();
    final ln = (json['lastName'] ?? json['last_name'] ?? '').toString().trim();
    final combined = '$fn $ln'.trim();
    if (combined.isNotEmpty) addIfValid(combined);
  }

  // 3. Nested objects
  for (final key in [
    'patientDetails',
    'patient',
    'user',
    'userDetails',
    'customer',
    'customerDetails',
    'bookingFor',
    'bookedFor',
    'patientInfo',
    'userInfo',
  ]) {
    addIfValid(json[key]);
  }

  if (candidates.isNotEmpty) {
    return candidates.first;
  }

  return 'Patient';
}

class VisitRequestItem {
  final String id;
  final String patientName;
  final String address;
  final String distance;
  final String serviceTag;
  final String time;
  final String avatarUrl;
  final String status; // REQUESTED, ACCEPTED, ARRIVING, ARRIVED, STARTED, COMPLETED
  final String notes;
  final List<String> conditionImages;
  final String phoneNumber;
  final double? latitude;
  final double? longitude;
  final bool isVitalsUpdated;
  final String doctorName;
  final bool femaleNursePreferred;

  const VisitRequestItem({
    required this.id,
    required this.patientName,
    required this.address,
    required this.distance,
    required this.serviceTag,
    required this.time,
    required this.avatarUrl,
    this.status = 'REQUESTED',
    this.notes = 'Assigned for nursing home care visit.',
    this.conditionImages = const [],
    this.phoneNumber = '',
    this.latitude,
    this.longitude,
    this.isVitalsUpdated = false,
    this.doctorName = '',
    this.femaleNursePreferred = false,
  });

  factory VisitRequestItem.fromJson(Map<String, dynamic> json) {
    final patientDetails = json['patientDetails'] is Map ? json['patientDetails'] as Map<String, dynamic> : null;
    final patientObj = json['patient'] is Map ? json['patient'] as Map<String, dynamic> : null;
    final userObj = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final locationObj = json['location'] is Map ? json['location'] as Map<String, dynamic> : null;
    final addressObj = json['address'] is Map ? json['address'] as Map<String, dynamic> : null;

    final patientName = _extractPatientName(json);

    // Parse Address
    String rawAddress = '';
    if (json['patientAddress'] != null && json['patientAddress'].toString().trim().isNotEmpty) {
      rawAddress = json['patientAddress'].toString().trim();
    } else if (json['address'] is String && (json['address'] as String).trim().isNotEmpty) {
      rawAddress = (json['address'] as String).trim();
    } else if (json['serviceAddress'] != null && json['serviceAddress'].toString().trim().isNotEmpty) {
      rawAddress = json['serviceAddress'].toString().trim();
    } else if (json['deliveryAddress'] != null && json['deliveryAddress'].toString().trim().isNotEmpty) {
      rawAddress = json['deliveryAddress'].toString().trim();
    } else if (json['locationAddress'] != null && json['locationAddress'].toString().trim().isNotEmpty) {
      rawAddress = json['locationAddress'].toString().trim();
    } else if (addressObj != null) {
      rawAddress = addressObj['formattedAddress']?.toString() ??
          addressObj['address']?.toString() ??
          addressObj['fullAddress']?.toString() ??
          addressObj['streetAddress']?.toString() ??
          addressObj['street']?.toString() ??
          '';
    } else if (locationObj != null) {
      rawAddress = locationObj['address']?.toString() ??
          locationObj['formattedAddress']?.toString() ??
          locationObj['fullAddress']?.toString() ??
          locationObj['streetAddress']?.toString() ??
          locationObj['name']?.toString() ??
          '';
    } else if (patientDetails?['address'] != null) {
      rawAddress = patientDetails!['address'].toString().trim();
    } else if (patientObj?['address'] != null) {
      rawAddress = patientObj!['address'].toString().trim();
    } else if (userObj?['address'] != null) {
      rawAddress = userObj!['address'].toString().trim();
    } else if (json['location'] is String && (json['location'] as String).trim().isNotEmpty) {
      rawAddress = (json['location'] as String).trim();
    }

    if (rawAddress.trim().isEmpty || rawAddress == 'Selected Delivery Address' || rawAddress == 'Patient Home Address') {
      final city = locationObj?['city']?.toString() ?? addressObj?['city']?.toString() ?? patientDetails?['city']?.toString() ?? '';
      final area = locationObj?['area']?.toString() ?? addressObj?['area']?.toString() ?? patientDetails?['area']?.toString() ?? '';
      if (area.isNotEmpty || city.isNotEmpty) {
        rawAddress = [area, city].where((s) => s.isNotEmpty).join(', ');
      }
    }
    if (rawAddress.trim().isEmpty) {
      rawAddress = 'Patient Address';
    }

    // Parse Phone Number (prioritize direct patient phone fields)
    final phone = json['patientPhone']?.toString() ??
        json['patientMobile']?.toString() ??
        json['phone']?.toString() ??
        json['phoneNumber']?.toString() ??
        json['mobile']?.toString() ??
        json['contactNumber']?.toString() ??
        json['patientContact']?.toString() ??
        patientDetails?['phone']?.toString() ??
        patientDetails?['mobile']?.toString() ??
        patientDetails?['patientPhone']?.toString() ??
        patientObj?['phone']?.toString() ??
        patientObj?['mobile']?.toString() ??
        userObj?['phone']?.toString() ??
        userObj?['mobile']?.toString() ??
        '';

    // Parse Lat & Lng
    double? lat;
    double? lng;
    final rawLat = json['latitude'] ?? json['lat'] ?? locationObj?['latitude'] ?? locationObj?['lat'] ?? patientDetails?['latitude'];
    final rawLng = json['longitude'] ?? json['lng'] ?? locationObj?['longitude'] ?? locationObj?['lng'] ?? patientDetails?['longitude'];
    if (rawLat != null) lat = double.tryParse(rawLat.toString());
    if (rawLng != null) lng = double.tryParse(rawLng.toString());
    if (locationObj?['coordinates'] is List && (locationObj!['coordinates'] as List).length >= 2) {
      final coords = locationObj['coordinates'] as List;
      lng = double.tryParse(coords[0].toString());
      lat = double.tryParse(coords[1].toString());
    }

    // Parse Distance
    final distVal = json['distanceKm'] ?? json['distance_km'] ?? json['distance'] ?? json['dist'] ?? json['distanceText'] ?? json['duration'];
    String distStr = '';
    if (distVal != null && distVal.toString().trim().isNotEmpty && distVal.toString().trim() != 'null') {
      final s = distVal.toString().trim();
      if (s.toLowerCase().contains('km')) {
        distStr = s;
      } else if (double.tryParse(s) != null) {
        distStr = '${double.parse(s).toStringAsFixed(1)} km';
      } else {
        distStr = '$s km';
      }
    }
    if (distStr.isEmpty) {
      distStr = '1.5 km';
    }

    String serviceTag = 'Home Care';
    if (json['services'] is List && (json['services'] as List).isNotEmpty) {
      final firstSvc = (json['services'] as List).first;
      if (firstSvc is Map) {
        serviceTag = firstSvc['name']?.toString() ?? 'Home Care';
      } else {
        serviceTag = firstSvc.toString();
      }
    } else if (json['serviceTag'] != null) {
      serviceTag = json['serviceTag'].toString();
    } else if (json['serviceType'] != null) {
      serviceTag = json['serviceType'].toString();
    } else if (json['serviceName'] != null) {
      serviceTag = json['serviceName'].toString();
    }

    final time = json['scheduledTime']?.toString() ??
        json['time']?.toString() ??
        (json['scheduledDate'] != null ? '${json['scheduledDate']} ${json['scheduledTime'] ?? ""}'.trim() : 'Today • Scheduled');

    final rawAvatar = json['avatarUrl']?.toString() ??
        json['patientAvatar']?.toString() ??
        json['patientPhoto']?.toString() ??
        json['photo']?.toString() ??
        json['image']?.toString() ??
        json['profileImage']?.toString() ??
        patientDetails?['avatarUrl']?.toString() ??
        patientDetails?['photo']?.toString() ??
        patientDetails?['profileImage']?.toString() ??
        patientDetails?['image']?.toString() ??
        patientObj?['avatarUrl']?.toString() ??
        patientObj?['photo']?.toString() ??
        patientObj?['profileImage']?.toString() ??
        patientObj?['image']?.toString() ??
        userObj?['avatarUrl']?.toString() ??
        userObj?['photo']?.toString() ??
        userObj?['profileImage']?.toString();

    final avatar = formatImageUrl(rawAvatar);

    final List<String> conditionImages = [];
    final rawImages = json['conditionImages'] ?? json['woundImages'] ?? json['reportImages'] ?? json['images'] ?? json['photos'];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img != null && img.toString().isNotEmpty) {
          conditionImages.add(formatImageUrl(img.toString()));
        }
      }
    }

    final notes = json['doctorNotes']?.toString() ??
        json['notes']?.toString() ??
        json['instructions']?.toString() ??
        json['reason']?.toString() ??
        json['remarks']?.toString() ??
        'Assigned for nursing home care visit.';

    final bool vitalsUpdated = json['isVitalsUpdated'] == true ||
        json['vitalsRecorded'] == true ||
        json['status'] == 'VITALS_UPDATED' ||
        json['vitalsStatus'] == 'COMPLETED';

    String parsedId = '';
    for (final candidate in [
      json['requestId']?.toString(),
      json['_id']?.toString(),
      json['id']?.toString(),
      json['appointmentId']?.toString(),
      json['orderId']?.toString(),
      json['appointmentNumber']?.toString(),
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty && candidate.trim() != 'null') {
        parsedId = candidate.trim();
        break;
      }
    }

    final doctorObj = json['doctor'] is Map ? json['doctor'] as Map<String, dynamic> : null;
    final doctorDetails = json['doctorDetails'] is Map ? json['doctorDetails'] as Map<String, dynamic> : null;
    final doctorName = json['doctorName']?.toString() ??
        doctorObj?['name']?.toString() ??
        doctorDetails?['name']?.toString() ??
        json['assignedDoctor']?.toString() ??
        '';

    final bool femaleNursePreferred = json['femaleNursePreferred'] == true ||
        json['femalePreferred'] == true ||
        json['femaleNurseOnly'] == true ||
        json['isFemalePreferred'] == true;

    return VisitRequestItem(
      id: parsedId,
      patientName: patientName,
      address: rawAddress,
      distance: distStr,
      serviceTag: serviceTag,
      time: time,
      avatarUrl: avatar,
      status: json['status']?.toString() ?? 'REQUESTED',
      notes: notes,
      conditionImages: conditionImages,
      phoneNumber: phone,
      latitude: lat ?? 12.9716,
      longitude: lng ?? 77.5946,
      isVitalsUpdated: vitalsUpdated,
      doctorName: doctorName,
      femaleNursePreferred: femaleNursePreferred,
    );
  }
}

class RecordVitalsRequest {
  final String appointmentId;
  final String bloodPressure;
  final int heartRate;
  final double temperature;
  final int bloodSugar;
  final int spo2;
  final double weight;
  final String reason;
  final String notes;
  /// Key = vital name (e.g. 'Blood Pressure'), Value = local file path
  final Map<String, String>? vitalImages;
  final List<String>? conditionImages;
  final List<String>? oldReportFiles;
  final List<Map<String, String>>? customVitals;

  const RecordVitalsRequest({
    required this.appointmentId,
    required this.bloodPressure,
    required this.heartRate,
    required this.temperature,
    required this.bloodSugar,
    required this.spo2,
    required this.weight,
    required this.reason,
    required this.notes,
    this.vitalImages,
    this.conditionImages,
    this.oldReportFiles,
    this.customVitals,
  });

  Map<String, dynamic> toJson() {
    int? sys;
    int? dia;
    final cleanBp = bloodPressure.replaceAll('mmHg', '').trim();
    if (cleanBp.contains('/')) {
      final parts = cleanBp.split('/');
      sys = int.tryParse(parts[0].trim());
      dia = int.tryParse(parts[1].trim());
    }

    return {
      'appointmentId': appointmentId,
      'requestId': appointmentId,
      'bloodPressure': cleanBp,
      'bp': cleanBp,
      // ignore: use_null_aware_elements
      if (sys != null) 'systolicBp': sys,
      // ignore: use_null_aware_elements
      if (dia != null) 'diastolicBp': dia,
      'heartRate': heartRate,
      'pulse': heartRate,
      'temperature': temperature,
      'bloodSugar': bloodSugar,
      'sugar': bloodSugar,
      'spo2': spo2,
      'weight': weight,
      'notes': notes,
      'nurseNotes': notes,
      'reason': reason,
      'symptoms': reason,
      // ignore: use_null_aware_elements
      if (customVitals != null && customVitals!.isNotEmpty)
        'customVitals': customVitals,
    };
  }

  /// Flat string fields for multipart/form-data
  Map<String, String> toFormFields() {
    int? sys;
    int? dia;
    final cleanBp = bloodPressure.replaceAll('mmHg', '').trim();
    if (cleanBp.contains('/')) {
      final parts = cleanBp.split('/');
      sys = int.tryParse(parts[0].trim());
      dia = int.tryParse(parts[1].trim());
    }

    return {
      'appointmentId': appointmentId,
      'requestId': appointmentId,
      'bloodPressure': cleanBp,
      'bp': cleanBp,
      // ignore: use_null_aware_elements — Map<String, String> requires non-null; if-check is intentional
      if (sys != null) 'systolicBp': sys.toString(),
      // ignore: use_null_aware_elements
      if (dia != null) 'diastolicBp': dia.toString(),
      'heartRate': heartRate.toString(),
      'pulse': heartRate.toString(),
      'temperature': temperature.toString(),
      'bloodSugar': bloodSugar.toString(),
      'sugar': bloodSugar.toString(),
      'spo2': spo2.toString(),
      'weight': weight.toString(),
      'notes': notes,
      'nurseNotes': notes,
      'reason': reason,
      'symptoms': reason,
      // ignore: use_null_aware_elements
      if (customVitals != null && customVitals!.isNotEmpty)
        'customVitals': jsonEncode(customVitals),
    };
  }
}

class SubmitReportRequest {
  final String appointmentId;
  final String summary;
  final String observations;
  final String nurseNotes;
  final int visitDuration;

  const SubmitReportRequest({
    required this.appointmentId,
    required this.summary,
    required this.observations,
    required this.nurseNotes,
    required this.visitDuration,
  });

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'requestId': appointmentId,
        'summary': summary,
        'observations': observations,
        'nurseRemarks': observations,
        'nurseNotes': nurseNotes,
        'visitDuration': visitDuration,
      };
}
