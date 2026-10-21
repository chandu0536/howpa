// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:howpa_nurse/core/utils/constants.dart';

String formatImageUrl(String? rawUrl) {
  if (rawUrl == null) return '';
  var clean = rawUrl.trim();
  while ((clean.startsWith('"') && clean.endsWith('"')) ||
      (clean.startsWith("'") && clean.endsWith("'"))) {
    clean = clean.substring(1, clean.length - 1).trim();
  }
  if (clean.isEmpty ||
      clean == 'null' ||
      clean == 'undefined' ||
      clean == '[object Object]' ||
      clean == 'null/null') {
    return '';
  }
  // Data URIs (base64)
  if (clean.startsWith('data:image/') || clean.startsWith('data:application/')) {
    return clean;
  }
  // Protocol-relative URLs (e.g. //res.cloudinary.com/...)
  if (clean.startsWith('//')) {
    clean = 'https:$clean';
  }
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return Uri.encodeFull(clean);
  }
  // Local file paths
  if (clean.startsWith('file://')) {
    return clean;
  }
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  final path = clean.startsWith('/') ? clean : '/$clean';
  return Uri.encodeFull('$base$path');
}

String? _extractUrlFromCandidate(dynamic val) {
  if (val == null) return null;
  if (val is String) {
    var s = val.trim();
    while ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.isEmpty ||
        s == 'null' ||
        s == 'undefined' ||
        s == '[object Object]' ||
        s == 'null/null') {
      return null;
    }
    if (s.startsWith('{') && s.endsWith('}')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          return _extractUrlFromCandidate(decoded);
        }
      } catch (_) {}
    }
    return s;
  }
  if (val is Map) {
    for (final k in [
      'url',
      'avatarUrl',
      'avatar_url',
      'avatar',
      'fileUrl',
      'file_url',
      'secure_url',
      'location',
      'path',
      'link',
      'uri',
      'photo',
      'photoUrl',
      'photo_url',
      'profilePhoto',
      'profile_photo',
      'profilePhotoUrl',
      'profile_photo_url',
      'profileImage',
      'profile_image',
      'profileImageUrl',
      'profile_image_url',
      'recentPhoto',
      'recent_photo',
      'image',
      'imageUrl',
      'image_url',
      'picture',
      'profilePic',
      'profile_pic',
      'key',
    ]) {
      final res = _extractUrlFromCandidate(val[k]);
      if (res != null) return res;
    }
  }
  if (val is List && val.isNotEmpty) {
    return _extractUrlFromCandidate(val.first);
  }
  return null;
}

String extractAvatarUrl(Map<String, dynamic> json) {
  const keysToCheck = [
    'patientAvatar',
    'patient_avatar',
    'patientPhoto',
    'patient_photo',
    'patientImage',
    'patient_image',
    'patientProfilePhoto',
    'patient_profile_photo',
    'patientProfileImage',
    'patient_profile_image',
    'avatar',
    'avatarUrl',
    'avatar_url',
    'photo',
    'photoUrl',
    'photo_url',
    'profilePhoto',
    'profile_photo',
    'profilePhotoUrl',
    'profile_photo_url',
    'profileImage',
    'profile_image',
    'profileImageUrl',
    'profile_image_url',
    'recentPhoto',
    'recent_photo',
    'image',
    'imageUrl',
    'image_url',
    'picture',
    'profilePic',
    'profile_pic',
    'userAvatar',
    'user_avatar',
    'userPhoto',
    'user_photo',
    'userImage',
    'user_image',
  ];

  final familyMemberObj = json['familyMember'] is Map ? json['familyMember'] as Map<String, dynamic> : null;
  final familyMemberDetails = json['familyMemberDetails'] is Map ? json['familyMemberDetails'] as Map<String, dynamic> : null;
  final member = json['member'] is Map ? json['member'] as Map<String, dynamic> : null;
  final memberDetails = json['memberDetails'] is Map ? json['memberDetails'] as Map<String, dynamic> : null;
  final memberObj = familyMemberObj ?? familyMemberDetails ?? member ?? memberDetails;

  final rawFamilyMemberId = json['familyMemberId']?.toString();
  final bool hasFamilyMemberId = rawFamilyMemberId != null &&
      rawFamilyMemberId.trim().isNotEmpty &&
      rawFamilyMemberId.trim() != 'null';
  final bool isFamilyMember = hasFamilyMemberId || memberObj != null || json['isFamilyMember'] == true;

  // 1. If booking for a family member, check the member object first
  if (isFamilyMember && memberObj != null) {
    for (final k in keysToCheck) {
      final u = _extractUrlFromCandidate(memberObj[k]);
      if (u != null) return formatImageUrl(u);
    }
  }

  // 2. Check root JSON fields
  for (final k in keysToCheck) {
    final u = _extractUrlFromCandidate(json[k]);
    if (u != null) return formatImageUrl(u);
  }

  // 3. Check nested objects
  final containers = [
    json['patientDetails'],
    json['patient'],
    json['patientInfo'],
    json['bookingFor'],
    json['bookedFor'],
    json['user'],
    json['userDetails'],
    json['userInfo'],
    json['customer'],
    json['customerDetails'],
    json['familyMember'],
    json['familyMemberDetails'],
    json['member'],
    json['memberDetails'],
    json['documents'],
  ];

  for (final c in containers) {
    if (c is Map) {
      for (final k in keysToCheck) {
        final u = _extractUrlFromCandidate(c[k]);
        if (u != null) return formatImageUrl(u);
      }
    }
  }

  return '';
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

  // 1. If family member booking, check family member objects first
  final hasFamilyId = json['familyMemberId'] != null &&
      json['familyMemberId'].toString().trim().isNotEmpty &&
      json['familyMemberId'].toString().trim() != 'null';
  if (hasFamilyId || json['familyMember'] != null || json['familyMemberDetails'] != null) {
    addIfValid(json['familyMember']);
    addIfValid(json['familyMemberDetails']);
    addIfValid(json['familyMemberName']);
    addIfValid(json['member']);
    addIfValid(json['memberDetails']);
  }

  // 2. Root fields
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

DateTime? _parseDateTime(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val.toLocal();
  final s = val.toString().trim();
  if (s.isEmpty || s == 'null' || s == 'undefined') return null;

  final parsedIso = DateTime.tryParse(s);
  if (parsedIso != null) return parsedIso.toLocal();

  final ddmmyyyy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(s);
  if (ddmmyyyy != null) {
    final day = int.tryParse(ddmmyyyy.group(1)!);
    final month = int.tryParse(ddmmyyyy.group(2)!);
    final year = int.tryParse(ddmmyyyy.group(3)!);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  final yyyymmdd = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(s);
  if (yyyymmdd != null) {
    final year = int.tryParse(yyyymmdd.group(1)!);
    final month = int.tryParse(yyyymmdd.group(2)!);
    final day = int.tryParse(yyyymmdd.group(3)!);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }

  return null;
}

String? _extractPatientAge(Map<String, dynamic> json) {
  final hasFamilyId = json['familyMemberId'] != null &&
      json['familyMemberId'].toString().trim().isNotEmpty &&
      json['familyMemberId'].toString().trim() != 'null';

  final List<dynamic> candidateObjects = [];
  if (hasFamilyId || json['familyMember'] != null || json['familyMemberDetails'] != null || json['member'] != null) {
    if (json['familyMember'] is Map) candidateObjects.add(json['familyMember']);
    if (json['familyMemberDetails'] is Map) candidateObjects.add(json['familyMemberDetails']);
    if (json['member'] is Map) candidateObjects.add(json['member']);
    if (json['memberDetails'] is Map) candidateObjects.add(json['memberDetails']);
  }
  for (final key in [
    'patientDetails',
    'patient',
    'patientInfo',
    'bookingFor',
    'bookedFor',
    'user',
    'userDetails',
    'customer',
    'customerDetails',
    'userInfo',
  ]) {
    if (json[key] is Map) candidateObjects.add(json[key]);
  }

  // 1. Check direct root fields
  for (final k in ['patientAge', 'patient_age', 'age']) {
    final val = json[k];
    if (val != null && val.toString().trim().isNotEmpty && val.toString().trim() != 'null') {
      return val.toString().trim();
    }
  }

  // 2. Check candidate objects
  for (final obj in candidateObjects) {
    if (obj is Map) {
      for (final k in ['patientAge', 'patient_age', 'age']) {
        final val = obj[k];
        if (val != null && val.toString().trim().isNotEmpty && val.toString().trim() != 'null') {
          return val.toString().trim();
        }
      }
    }
  }

  // 3. Date of birth if age not directly given
  for (final k in ['dob', 'dateOfBirth', 'date_of_birth', 'birthDate', 'birth_date']) {
    dynamic val = json[k];
    if (val == null) {
      for (final obj in candidateObjects) {
        if (obj is Map && obj[k] != null) {
          val = obj[k];
          break;
        }
      }
    }
    if (val != null && val.toString().trim().isNotEmpty && val.toString().trim() != 'null') {
      try {
        final dt = _parseDateTime(val.toString().trim());
        if (dt != null) {
          final now = DateTime.now();
          int age = now.year - dt.year;
          if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
            age--;
          }
          if (age >= 0 && age <= 130) {
            return age.toString();
          }
        }
      } catch (_) {}
    }
  }

  return null;
}

String? _extractPatientGender(Map<String, dynamic> json) {
  final hasFamilyId = json['familyMemberId'] != null &&
      json['familyMemberId'].toString().trim().isNotEmpty &&
      json['familyMemberId'].toString().trim() != 'null';

  final List<dynamic> candidateObjects = [];
  if (hasFamilyId || json['familyMember'] != null || json['familyMemberDetails'] != null || json['member'] != null) {
    if (json['familyMember'] is Map) candidateObjects.add(json['familyMember']);
    if (json['familyMemberDetails'] is Map) candidateObjects.add(json['familyMemberDetails']);
    if (json['member'] is Map) candidateObjects.add(json['member']);
    if (json['memberDetails'] is Map) candidateObjects.add(json['memberDetails']);
  }
  for (final key in [
    'patientDetails',
    'patient',
    'patientInfo',
    'bookingFor',
    'bookedFor',
    'user',
    'userDetails',
    'customer',
    'customerDetails',
    'userInfo',
  ]) {
    if (json[key] is Map) candidateObjects.add(json[key]);
  }

  // 1. Check direct root fields
  for (final k in ['patientGender', 'patient_gender', 'gender', 'sex', 'patientSex', 'patient_sex']) {
    final val = json[k];
    if (val != null && val.toString().trim().isNotEmpty && val.toString().trim() != 'null') {
      return val.toString().trim();
    }
  }

  // 2. Check candidate objects
  for (final obj in candidateObjects) {
    if (obj is Map) {
      for (final k in ['patientGender', 'patient_gender', 'gender', 'sex', 'patientSex', 'patient_sex']) {
        final val = obj[k];
        if (val != null && val.toString().trim().isNotEmpty && val.toString().trim() != 'null') {
          return val.toString().trim();
        }
      }
    }
  }

  return null;
}

String formatGender(String? gender) {
  if (gender == null) return '';
  final g = gender.trim().toLowerCase();
  if (g.isEmpty || g == 'null' || g == 'undefined') return '';
  if (g == 'm' || g == 'male') return 'Male';
  if (g == 'f' || g == 'female') return 'Female';
  if (g == 'o' || g == 'other' || g == 'others') return 'Other';
  return gender.trim().substring(0, 1).toUpperCase() + gender.trim().substring(1).toLowerCase();
}

String formatAge(String? age) {
  if (age == null) return '';
  final a = age.trim();
  if (a.isEmpty || a == 'null' || a == 'undefined') return '';
  final digits = a.replaceAll(RegExp(r'[^0-9]'), '').trim();
  if (digits.isNotEmpty) return '$digits yrs';
  if (a.toLowerCase().endsWith('yrs') || a.toLowerCase().endsWith('years')) return a;
  return '$a yrs';
}

String formatDemographics({
  String? gender,
  String? age,
  bool isFamilyMember = false,
  String? bookedByName,
}) {
  final g = formatGender(gender);
  final a = formatAge(age);
  final List<String> parts = [];

  if (g.isNotEmpty && a.isNotEmpty) {
    parts.add(g);
    parts.add(a);
  } else if (g.isNotEmpty) {
    parts.add(g);
    parts.add('Age: --');
  } else if (a.isNotEmpty) {
    parts.add('Gender: --');
    parts.add(a);
  } else {
    parts.add('Gender: --');
    parts.add('Age: --');
  }

  if (isFamilyMember && bookedByName != null && bookedByName.trim().isNotEmpty && bookedByName.trim() != 'null') {
    parts.add('Requested by: ${bookedByName.trim()}');
  }

  return parts.join(' • ');
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
  final DateTime? scheduledDate;

  // Family Member & Patient Demographics (100% Dynamic)
  final String? familyMemberId;
  final bool isFamilyMember;
  final String? patientAge;
  final String? patientGender;
  final String? relation;
  final String? bookedByName;
  final double? price;
  final double? earnings;
  final String? appointmentId;
  final String? requestId;
  final String? orderId;

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
    this.scheduledDate,
    this.familyMemberId,
    this.isFamilyMember = false,
    this.patientAge,
    this.patientGender,
    this.relation,
    this.bookedByName,
    this.price,
    this.earnings,
    this.appointmentId,
    this.requestId,
    this.orderId,
  });

  VisitRequestItem copyWith({
    String? id,
    String? patientName,
    String? address,
    String? distance,
    String? serviceTag,
    String? time,
    String? avatarUrl,
    String? status,
    String? notes,
    List<String>? conditionImages,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    bool? isVitalsUpdated,
    String? doctorName,
    bool? femaleNursePreferred,
    DateTime? scheduledDate,
    String? familyMemberId,
    bool? isFamilyMember,
    String? patientAge,
    String? patientGender,
    String? relation,
    String? bookedByName,
    double? price,
    double? earnings,
    String? appointmentId,
    String? requestId,
    String? orderId,
  }) {
    return VisitRequestItem(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      serviceTag: serviceTag ?? this.serviceTag,
      time: time ?? this.time,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      conditionImages: conditionImages ?? this.conditionImages,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVitalsUpdated: isVitalsUpdated ?? this.isVitalsUpdated,
      doctorName: doctorName ?? this.doctorName,
      femaleNursePreferred: femaleNursePreferred ?? this.femaleNursePreferred,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      isFamilyMember: isFamilyMember ?? this.isFamilyMember,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      relation: relation ?? this.relation,
      bookedByName: bookedByName ?? this.bookedByName,
      price: price ?? this.price,
      earnings: earnings ?? this.earnings,
      appointmentId: appointmentId ?? this.appointmentId,
      requestId: requestId ?? this.requestId,
      orderId: orderId ?? this.orderId,
    );
  }

  String get displayOrderId {
    if (orderId != null && orderId!.trim().isNotEmpty && orderId != 'null') {
      return orderId!.trim();
    }
    if (appointmentId != null && appointmentId!.trim().isNotEmpty && appointmentId != 'null' && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(appointmentId!.trim())) {
      return appointmentId!.trim();
    }
    if (requestId != null && requestId!.trim().isNotEmpty && requestId != 'null' && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(requestId!.trim())) {
      return requestId!.trim();
    }
    if (id.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
      return id;
    }
    return '';
  }

  String get formattedAppointmentDate {
    final d = scheduledDate ?? DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = days[d.weekday - 1];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dayName, $dd-$mm-$yyyy';
  }

  String get formattedDateOnly {
    final d = scheduledDate ?? DateTime.now();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

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

    // Parse Lat & Lng across all candidate structures
    double? lat;
    double? lng;
    final rawLat = json['latitude'] ??
        json['lat'] ??
        json['patientLat'] ??
        json['patientLatitude'] ??
        json['deliveryLat'] ??
        json['serviceLat'] ??
        locationObj?['latitude'] ??
        locationObj?['lat'] ??
        patientDetails?['latitude'] ??
        patientDetails?['lat'] ??
        patientObj?['latitude'] ??
        patientObj?['lat'] ??
        addressObj?['latitude'] ??
        addressObj?['lat'];
    final rawLng = json['longitude'] ??
        json['lng'] ??
        json['patientLng'] ??
        json['patientLongitude'] ??
        json['deliveryLng'] ??
        json['serviceLng'] ??
        locationObj?['longitude'] ??
        locationObj?['lng'] ??
        patientDetails?['longitude'] ??
        patientDetails?['lng'] ??
        patientObj?['longitude'] ??
        patientObj?['lng'] ??
        addressObj?['longitude'] ??
        addressObj?['lng'];
    if (rawLat != null) lat = double.tryParse(rawLat.toString());
    if (rawLng != null) lng = double.tryParse(rawLng.toString());
    if (locationObj?['coordinates'] is List && (locationObj!['coordinates'] as List).length >= 2) {
      final coords = locationObj['coordinates'] as List;
      lng = double.tryParse(coords[0].toString()) ?? lng;
      lat = double.tryParse(coords[1].toString()) ?? lat;
    }
    if (addressObj?['coordinates'] is List && (addressObj!['coordinates'] as List).length >= 2) {
      final coords = addressObj['coordinates'] as List;
      lng = double.tryParse(coords[0].toString()) ?? lng;
      lat = double.tryParse(coords[1].toString()) ?? lat;
    }

    // Parse Distance (eliminate fake fallback and preserve backend distance)
    final distVal = json['distanceKm'] ??
        json['distance_km'] ??
        json['distance'] ??
        json['dist'] ??
        json['distanceText'] ??
        json['duration'];
    String distStr = '';
    if (distVal != null &&
        distVal.toString().trim().isNotEmpty &&
        distVal.toString().trim() != 'null') {
      final s = distVal.toString().trim();
      final lower = s.toLowerCase();
      if (lower.contains('km') ||
          lower.contains('kilometer') ||
          lower.contains('kilometre') ||
          lower.contains('metre') ||
          lower.contains('meter') ||
          lower.contains('mile')) {
        distStr = s;
      } else {
        final numVal = double.tryParse(s.replaceAll(RegExp(r'[^\d.]'), ''));
        if (numVal != null) {
          if (numVal == 0) {
            distStr = '0 km';
          } else if (numVal == numVal.roundToDouble()) {
            distStr = '${numVal.toInt()} km';
          } else {
            distStr = '${numVal.toStringAsFixed(1)} km';
          }
        } else {
          distStr = '$s km';
        }
      }
    }
    // If backend sent dummy "1.5 km" while coordinates are null, or distance is completely empty
    if (distStr.isEmpty || (distStr == '1.5 km' && (lat == null || lng == null))) {
      distStr = (lat != null && lng != null) ? 'Nearby' : '--';
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

    final familyMemberObj = json['familyMember'] is Map ? json['familyMember'] as Map<String, dynamic> : null;
    final familyMemberDetails = json['familyMemberDetails'] is Map ? json['familyMemberDetails'] as Map<String, dynamic> : null;
    final memberObj = familyMemberObj ?? familyMemberDetails;

    final rawFamilyMemberId = json['familyMemberId']?.toString();
    final bool hasFamilyMemberId = rawFamilyMemberId != null &&
        rawFamilyMemberId.trim().isNotEmpty &&
        rawFamilyMemberId.trim() != 'null';

    final bool isFamilyMember = hasFamilyMemberId || memberObj != null || json['isFamilyMember'] == true;
    final String? familyMemberId = hasFamilyMemberId
        ? rawFamilyMemberId.trim()
        : (memberObj?['_id']?.toString() ?? memberObj?['id']?.toString());

    // Patient Age (dynamic from family member, patient, user, or DOB)
    final String? patientAge = _extractPatientAge(json);

    // Patient Gender (dynamic from family member, patient, user, sex)
    final String? patientGender = _extractPatientGender(json);

    // Relationship (dynamic)
    String? relation;
    final rawRelation = memberObj?['relation'] ??
        memberObj?['relationship'] ??
        json['relation'] ??
        json['relationship'] ??
        json['familyRelation'];
    if (rawRelation != null && rawRelation.toString().trim().isNotEmpty && rawRelation.toString().trim() != 'null') {
      relation = rawRelation.toString().trim();
    } else if (isFamilyMember) {
      relation = 'Family Member';
    }

    // Booked By (name of primary user if booking for family member)
    String? bookedByName;
    final rawBookedBy = json['bookedByName'] ??
        json['bookedBy'] ??
        json['userName'] ??
        userObj?['name'] ??
        userObj?['fullName'] ??
        json['customerName'] ??
        (patientDetails != null && patientDetails['name'] != null ? patientDetails['name'] : null);
    if (rawBookedBy != null && rawBookedBy.toString().trim().isNotEmpty && rawBookedBy.toString().trim() != 'null') {
      final s = rawBookedBy.toString().trim();
      if (s.toLowerCase() != patientName.toLowerCase() && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(s)) {
        bookedByName = s;
      }
    }

    final avatar = extractAvatarUrl(json);

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
        json['vitalsCollected'] == true ||
        json['vitalsDone'] == true ||
        json['status'] == 'VITALS_UPDATED' ||
        json['vitalsStatus'] == 'COMPLETED';

    String parsedId = '';
    for (final candidate in [
      json['_id']?.toString(),
      json['id']?.toString(),
      json['requestId']?.toString(),
      json['orderId']?.toString(),
      json['appointmentId']?.toString(),
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

    DateTime? scheduledDate;
    final rawDate = json['scheduledDate'] ??
        json['appointmentDate'] ??
        json['bookingDate'] ??
        json['serviceDate'] ??
        json['visitDate'] ??
        json['date'] ??
        json['preferredDate'] ??
        json['slotDate'] ??
        json['dateTime'] ??
        (json['appointment'] is Map
            ? (json['appointment']['scheduledDate'] ??
                json['appointment']['appointmentDate'] ??
                json['appointment']['date'])
            : null) ??
        (json['order'] is Map
            ? (json['order']['scheduledDate'] ??
                json['order']['appointmentDate'] ??
                json['order']['date'])
            : null) ??
        (json['booking'] is Map
            ? (json['booking']['scheduledDate'] ??
                json['booking']['appointmentDate'] ??
                json['booking']['date'])
            : null);
    if (rawDate != null) {
      scheduledDate = _parseDateTime(rawDate);
    }
    if (scheduledDate == null && json['time'] != null) {
      scheduledDate = _parseDateTime(json['time']);
    }

    final double? price = (json['price'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        (json['serviceCharges'] as num?)?.toDouble();
    final double? earnings = (json['earnings'] as num?)?.toDouble() ?? price;

    String statusStr = 'REQUESTED';
    final nurseStatusUpper = json['nurseStatus']?.toString().toUpperCase();
    final visitStatusUpper = json['visitStatus']?.toString().toUpperCase();
    if (nurseStatusUpper == 'COMPLETED' || nurseStatusUpper == 'DONE' ||
        visitStatusUpper == 'COMPLETED' || visitStatusUpper == 'DONE' ||
        vitalsUpdated) {
      statusStr = 'COMPLETED';
    } else if (json['status'] != null && json['status'].toString().isNotEmpty) {
      statusStr = json['status'].toString();
    } else if (json['nurseStatus'] != null && json['nurseStatus'].toString().isNotEmpty) {
      statusStr = json['nurseStatus'].toString();
    } else if (json['appointmentStatus'] != null && json['appointmentStatus'].toString().isNotEmpty) {
      statusStr = json['appointmentStatus'].toString();
    } else if (json['visitStatus'] != null && json['visitStatus'].toString().isNotEmpty) {
      statusStr = json['visitStatus'].toString();
    }

    final rawAptId = json['appointmentId']?.toString() ??
        json['appointment_id']?.toString() ??
        (json['appointment'] is Map ? (json['appointment']['_id']?.toString() ?? json['appointment']['id']?.toString()) : null);
    final String? parsedAppointmentId = (rawAptId != null && rawAptId.trim().isNotEmpty && rawAptId.trim() != 'null')
        ? rawAptId.trim()
        : null;

    final rawReqId = json['nurseRequestId']?.toString() ??
        json['requestId']?.toString() ??
        json['request_id']?.toString() ??
        json['_id']?.toString() ??
        json['id']?.toString();
    final String? parsedRequestId = (rawReqId != null && rawReqId.trim().isNotEmpty && rawReqId.trim() != 'null')
        ? rawReqId.trim()
        : null;

    String? parsedOrderId;
    final orderCandidates = [
      json['orderId']?.toString(),
      json['order_id']?.toString(),
      json['orderID']?.toString(),
      json['bookingNumber']?.toString(),
      json['booking_number']?.toString(),
      json['bookingId']?.toString(),
      json['booking_id']?.toString(),
      json['requestNumber']?.toString(),
      json['request_number']?.toString(),
      json['orderNumber']?.toString(),
      json['order_number']?.toString(),
      json['nurseBookingId']?.toString(),
      json['nurseOrderId']?.toString(),
      json['bookingCode']?.toString(),
      json['displayBookingId']?.toString(),
      json['order'] is Map ? (json['order'] as Map)['orderId']?.toString() : null,
      json['order'] is Map ? (json['order'] as Map)['id']?.toString() : null,
      json['appointment'] is Map ? (json['appointment'] as Map)['orderId']?.toString() : null,
      json['appointmentNumber']?.toString(),
      json['appointmentId']?.toString(),
    ];

    // Priority 1: Check for explicit Nurse Order ID starting with 'NS', 'NUR', or 'ORD'
    for (final candidate in orderCandidates) {
      if (candidate != null && candidate.trim().isNotEmpty && candidate.trim() != 'null') {
        final c = candidate.trim();
        if (c.startsWith('NS') || c.startsWith('NUR') || c.startsWith('ORD')) {
          parsedOrderId = c;
          break;
        }
      }
    }
    // Priority 2: Fallback to any non-Mongo ObjectId candidate
    if (parsedOrderId == null) {
      for (final candidate in orderCandidates) {
        if (candidate != null && candidate.trim().isNotEmpty && candidate.trim() != 'null') {
          final c = candidate.trim();
          if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(c)) {
            parsedOrderId = c;
            break;
          }
        }
      }
    }
    if (parsedOrderId == null && parsedId.isNotEmpty && (parsedId.startsWith('NS') || parsedId.startsWith('ORD'))) {
      parsedOrderId = parsedId;
    }

    return VisitRequestItem(
      id: parsedId,
      patientName: patientName,
      address: rawAddress,
      distance: distStr,
      serviceTag: serviceTag,
      time: time,
      avatarUrl: avatar,
      status: statusStr,
      notes: notes,
      conditionImages: conditionImages,
      phoneNumber: phone,
      latitude: lat,
      longitude: lng,
      isVitalsUpdated: vitalsUpdated,
      doctorName: doctorName,
      femaleNursePreferred: femaleNursePreferred,
      scheduledDate: scheduledDate,
      familyMemberId: familyMemberId,
      isFamilyMember: isFamilyMember,
      patientAge: patientAge,
      patientGender: patientGender,
      relation: relation,
      bookedByName: bookedByName,
      price: price,
      earnings: earnings,
      appointmentId: parsedAppointmentId,
      requestId: parsedRequestId,
      orderId: parsedOrderId,
    );
  }
}

class RecordVitalsRequest {
  final String appointmentId;
  final String? bloodPressure;
  final dynamic heartRate;
  final dynamic temperature;
  final dynamic bloodSugar;
  final dynamic spo2;
  final dynamic weight;
  final String reason;
  final String notes;
  /// Key = vital name (e.g. 'Blood Pressure'), Value = local file path
  final Map<String, String>? vitalImages;
  final List<String>? conditionImages;
  final List<String>? oldReportFiles;
  final List<Map<String, String>>? customVitals;

  const RecordVitalsRequest({
    required this.appointmentId,
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.bloodSugar,
    this.spo2,
    this.weight,
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
    final cleanBp = bloodPressure?.replaceAll('mmHg', '').trim();
    if (cleanBp != null && cleanBp.contains('/')) {
      final parts = cleanBp.split('/');
      sys = int.tryParse(parts[0].trim());
      dia = int.tryParse(parts[1].trim());
    }

    dynamic formatVal(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      final numVal = num.tryParse(str);
      return numVal ?? str;
    }

    final formattedHr = formatVal(heartRate);
    final formattedTemp = formatVal(temperature);
    final formattedSugar = formatVal(bloodSugar);
    final formattedSpo2 = formatVal(spo2);
    final formattedWeight = formatVal(weight);

    return {
      'appointmentId': appointmentId,
      'requestId': appointmentId,
      if (cleanBp != null && cleanBp.isNotEmpty) ...{
        'bloodPressure': cleanBp,
        'bp': cleanBp,
      },
      if (sys != null) 'systolicBp': sys,
      if (dia != null) 'diastolicBp': dia,
      if (formattedHr != null) ...{
        'heartRate': formattedHr,
        'pulse': formattedHr,
      },
      if (formattedTemp != null) 'temperature': formattedTemp,
      if (formattedSugar != null) ...{
        'bloodSugar': formattedSugar,
        'sugar': formattedSugar,
      },
      if (formattedSpo2 != null) 'spo2': formattedSpo2,
      if (formattedWeight != null) 'weight': formattedWeight,
      'notes': notes,
      'nurseNotes': notes,
      'reason': reason,
      'symptoms': reason,
      if (customVitals != null && customVitals!.isNotEmpty)
        'customVitals': customVitals,
    };
  }

  /// Flat string fields for multipart/form-data
  Map<String, String> toFormFields() {
    int? sys;
    int? dia;
    final cleanBp = bloodPressure?.replaceAll('mmHg', '').trim() ?? '';
    if (cleanBp.contains('/')) {
      final parts = cleanBp.split('/');
      sys = int.tryParse(parts[0].trim());
      dia = int.tryParse(parts[1].trim());
    }

    String? valToStr(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      return str.isEmpty ? null : str;
    }

    final hrStr = valToStr(heartRate);
    final tempStr = valToStr(temperature);
    final sugarStr = valToStr(bloodSugar);
    final spo2Str = valToStr(spo2);
    final weightStr = valToStr(weight);

    return {
      'appointmentId': appointmentId,
      'requestId': appointmentId,
      if (cleanBp.isNotEmpty) ...{
        'bloodPressure': cleanBp,
        'bp': cleanBp,
      },
      if (sys != null) 'systolicBp': sys.toString(),
      if (dia != null) 'diastolicBp': dia.toString(),
      if (hrStr != null) ...{
        'heartRate': hrStr,
        'pulse': hrStr,
      },
      if (tempStr != null) 'temperature': tempStr,
      if (sugarStr != null) ...{
        'bloodSugar': sugarStr,
        'sugar': sugarStr,
      },
      if (spo2Str != null) 'spo2': spo2Str,
      if (weightStr != null) 'weight': weightStr,
      'notes': notes,
      'nurseNotes': notes,
      'reason': reason,
      'symptoms': reason,
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
