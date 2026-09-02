import '../../../../core/network/api_endpoints.dart';

String _resolveImageUrl(dynamic raw) {
  if (raw == null) return '';
  final str = raw.toString().trim();
  if (str.isEmpty || str == 'null' || str == 'undefined') return '';
  if (str.startsWith('http://') || str.startsWith('https://')) {
    return str;
  }
  // Strip '/api' from base if appending root asset path
  final baseUrl = ApiEndpoints.baseUrl;
  final rootUrl = baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - 4)
      : baseUrl;
  final base = rootUrl.endsWith('/') ? rootUrl : '$rootUrl/';
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

Map<String, dynamic>? _extractPatientMap(Map<String, dynamic> json) {
  if (json['patient'] is Map<String, dynamic>) {
    return json['patient'] as Map<String, dynamic>;
  }
  if (json['patientId'] is Map<String, dynamic>) {
    return json['patientId'] as Map<String, dynamic>;
  }
  if (json['patientDetails'] is Map<String, dynamic>) {
    return json['patientDetails'] as Map<String, dynamic>;
  }
  if (json['user'] is Map<String, dynamic>) {
    return json['user'] as Map<String, dynamic>;
  }
  if (json['userId'] is Map<String, dynamic>) {
    return json['userId'] as Map<String, dynamic>;
  }
  if (json['data'] is Map<String, dynamic>) {
    final d = json['data'] as Map<String, dynamic>;
    if (d['patient'] is Map<String, dynamic>) return d['patient'] as Map<String, dynamic>;
    if (d['patientId'] is Map<String, dynamic>) return d['patientId'] as Map<String, dynamic>;
    return d;
  }
  if (json['appointment'] is Map<String, dynamic>) {
    final a = json['appointment'] as Map<String, dynamic>;
    if (a['patient'] is Map<String, dynamic>) return a['patient'] as Map<String, dynamic>;
    if (a['patientId'] is Map<String, dynamic>) return a['patientId'] as Map<String, dynamic>;
    return a;
  }
  return null;
}

dynamic _extractCandidateAvatar(Map<String, dynamic> json, Map<String, dynamic>? patientObj) {
  return json['patientPhoto'] ??
      json['patient_photo'] ??
      json['patientImage'] ??
      json['patient_image'] ??
      json['patientAvatar'] ??
      json['patient_avatar'] ??
      json['profileImage'] ??
      json['profile_image'] ??
      json['profilePicture'] ??
      json['profile_picture'] ??
      json['profilePic'] ??
      json['profile_pic'] ??
      json['avatarUrl'] ??
      json['avatar_url'] ??
      json['avatar'] ??
      json['photoUrl'] ??
      json['photo_url'] ??
      json['photo'] ??
      json['image'] ??
      json['imageUrl'] ??
      json['image_url'] ??
      json['picture'] ??
      json['userImage'] ??
      json['userPhoto'] ??
      patientObj?['patientPhoto'] ??
      patientObj?['patient_photo'] ??
      patientObj?['profileImage'] ??
      patientObj?['profile_image'] ??
      patientObj?['profilePicture'] ??
      patientObj?['profile_picture'] ??
      patientObj?['profilePic'] ??
      patientObj?['profile_pic'] ??
      patientObj?['patientImage'] ??
      patientObj?['patient_image'] ??
      patientObj?['patientAvatar'] ??
      patientObj?['patient_avatar'] ??
      patientObj?['avatarUrl'] ??
      patientObj?['avatar_url'] ??
      patientObj?['avatar'] ??
      patientObj?['photoUrl'] ??
      patientObj?['photo_url'] ??
      patientObj?['photo'] ??
      patientObj?['image'] ??
      patientObj?['imageUrl'] ??
      patientObj?['image_url'] ??
      patientObj?['picture'] ??
      json['user']?['profileImage'] ??
      json['user']?['patientPhoto'] ??
      json['user']?['avatar'] ??
      json['user']?['photo'] ??
      json['data']?['patientPhoto'] ??
      json['data']?['patientImage'] ??
      json['data']?['profileImage'] ??
      json['data']?['avatarUrl'] ??
      json['data']?['avatar'] ??
      json['data']?['image'] ??
      json['data']?['photo'] ??
      json['appointment']?['patientPhoto'] ??
      json['appointment']?['profileImage'] ??
      json['appointment']?['patient']?['patientPhoto'] ??
      json['appointment']?['patient']?['profileImage'] ??
      json['appointment']?['patient']?['avatar'] ??
      json['appointment']?['patient']?['photo'];
}

class BroadcastRequestModel {
  final String appointmentId;
  final String patientName;
  final String patientAge;
  final String patientGender;
  final String address;
  final double? lat;
  final double? lng;
  final String distance;
  final String serviceType;
  final String serviceBadge;
  final String fee;
  final String requestedTime;
  final String avatarUrl;
  final String doctorNote;
  final String phone;

  const BroadcastRequestModel({
    required this.appointmentId,
    required this.patientName,
    this.patientAge = '',
    this.patientGender = '',
    required this.address,
    this.lat,
    this.lng,
    this.distance = '2.4 km away',
    this.serviceType = 'Home Nursing Care',
    this.serviceBadge = 'Urgent',
    this.fee = '₹500',
    this.requestedTime = 'Immediate',
    this.avatarUrl = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    this.doctorNote = 'Please attend to the patient with care as scheduled.',
    this.phone = '',
  });

  factory BroadcastRequestModel.fromJson(Map<String, dynamic> json) {
    final patientObj = _extractPatientMap(json);
    final doctorObj = json['doctor'] is Map<String, dynamic> ? json['doctor'] as Map<String, dynamic> : null;

    final String rawName = json['patientName']?.toString() ??
        patientObj?['name']?.toString() ??
        patientObj?['fullName']?.toString() ??
        patientObj?['patientName']?.toString() ??
        json['name']?.toString() ??
        json['fullName']?.toString() ??
        'Patient';

    final String rawAge = json['patientAge']?.toString() ??
        patientObj?['age']?.toString() ??
        '';

    final String rawGender = json['patientGender']?.toString() ??
        patientObj?['gender']?.toString() ??
        '';

    final dynamic rawAddrSource = json['address'] ??
        patientObj?['address'] ??
        json['location'] ??
        patientObj?['location'];
    final String parsedAddr = _parseAddress(rawAddrSource);
    final String rawAddress = parsedAddr.isNotEmpty ? parsedAddr : 'Location provided upon acceptance';

    final String rawService = json['serviceType']?.toString() ??
        json['serviceName']?.toString() ??
        json['service']?.toString() ??
        json['specialization']?.toString() ??
        'General Home Care';

    // Format fee
    String formattedFee = '₹450';
    final rawFee = json['fee'] ?? json['amount'] ?? json['price'] ?? json['cost'];
    if (rawFee != null) {
      if (rawFee is num) {
        formattedFee = '₹${rawFee.toInt()}';
      } else {
        final feeStr = rawFee.toString().trim();
        formattedFee = feeStr.startsWith('₹') ? feeStr : '₹$feeStr';
      }
    }

    final String rawNote = json['doctorNote']?.toString() ??
        json['note']?.toString() ??
        json['notes']?.toString() ??
        json['description']?.toString() ??
        doctorObj?['note']?.toString() ??
        'Standard home care nursing routine. Please take vitals and assist.';

    final candidateAvatar = _extractCandidateAvatar(json, patientObj);
    final String resolvedAvatar = _resolveImageUrl(candidateAvatar);
    final String rawAvatar = resolvedAvatar.isNotEmpty
        ? resolvedAvatar
        : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=150';

    return BroadcastRequestModel(
      appointmentId: json['appointmentId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          json['nurseRequestId']?.toString() ??
          '',
      patientName: rawName,
      patientAge: rawAge,
      patientGender: rawGender,
      address: rawAddress,
      lat: (json['lat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
      distance: json['distance']?.toString() ?? '1.8 km away',
      serviceType: rawService,
      serviceBadge: json['serviceBadge']?.toString() ?? 'Urgent',
      fee: formattedFee,
      requestedTime: json['requestedTime']?.toString() ?? json['time']?.toString() ?? 'Immediate',
      avatarUrl: rawAvatar,
      doctorNote: rawNote,
      phone: json['phone']?.toString() ??
          patientObj?['phone']?.toString() ??
          patientObj?['mobile']?.toString() ??
          json['mobile']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
    'appointmentId': appointmentId,
    'patientName': patientName,
    'patientAge': patientAge,
    'patientGender': patientGender,
    'address': address,
    'lat': lat,
    'lng': lng,
    'distance': distance,
    'serviceType': serviceType,
    'serviceBadge': serviceBadge,
    'fee': fee,
    'requestedTime': requestedTime,
    'avatarUrl': avatarUrl,
    'doctorNote': doctorNote,
    'phone': phone,
  };
}

class VisitModel {
  final String id;
  final String appointmentId;
  final String patientName;
  final String patientAge;
  final String patientGender;
  final String serviceName;
  final String serviceBadge;
  final String appointmentTime;
  final String address;
  final String distance;
  final String fee;
  final String status; // 'ARRIVING', 'IN_PROGRESS', 'COMPLETED', 'Assigned', etc.
  final String avatarUrl;

  const VisitModel({
    required this.id,
    required this.appointmentId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.serviceName,
    required this.serviceBadge,
    required this.appointmentTime,
    required this.address,
    required this.distance,
    required this.fee,
    required this.status,
    required this.avatarUrl,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    final String resolvedId = json['_id']?.toString() ?? json['id']?.toString() ?? json['appointmentId']?.toString() ?? '';
    final patientObj = _extractPatientMap(json);

    final candidateAvatar = _extractCandidateAvatar(json, patientObj);
    final String resolvedAvatar = _resolveImageUrl(candidateAvatar);

    final dynamic rawAddrSource = json['address'] ??
        patientObj?['address'] ??
        json['location'] ??
        patientObj?['location'];
    final String parsedAddr = _parseAddress(rawAddrSource);

    return VisitModel(
      id: resolvedId,
      appointmentId: json['appointmentId']?.toString() ?? resolvedId,
      patientName: json['patientName']?.toString() ??
          patientObj?['name']?.toString() ??
          patientObj?['fullName']?.toString() ??
          patientObj?['patientName']?.toString() ??
          json['name']?.toString() ??
          'Patient',
      patientAge: json['patientAge']?.toString() ?? patientObj?['age']?.toString() ?? '',
      patientGender: json['patientGender']?.toString() ?? patientObj?['gender']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ??
          json['service']?.toString() ??
          json['specialization']?.toString() ??
          'Nursing Visit',
      serviceBadge: json['serviceBadge']?.toString() ??
          json['badge']?.toString() ??
          json['specialization']?.toString() ??
          'Home Visit',
      appointmentTime: json['appointmentTime']?.toString() ??
          json['time']?.toString() ??
          json['requestedTime']?.toString() ??
          'Today',
      address: parsedAddr.isNotEmpty ? parsedAddr : 'Location provided',
      distance: json['distance']?.toString() ?? '2.4 km away',
      fee: json['fee']?.toString() ?? '₹500',
      status: (json['visitStatus'] != null && json['visitStatus'].toString().trim().isNotEmpty)
          ? json['visitStatus'].toString().trim()
          : (json['status']?.toString() ?? json['appointmentStatus']?.toString() ?? 'Assigned'),
      avatarUrl: resolvedAvatar.isNotEmpty
          ? resolvedAvatar
          : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'serviceName': serviceName,
      'serviceBadge': serviceBadge,
      'appointmentTime': appointmentTime,
      'address': address,
      'distance': distance,
      'fee': fee,
      'status': status,
      'avatarUrl': avatarUrl,
    };
  }

  VisitModel copyWith({
    String? id,
    String? appointmentId,
    String? patientName,
    String? patientAge,
    String? patientGender,
    String? serviceName,
    String? serviceBadge,
    String? appointmentTime,
    String? address,
    String? distance,
    String? fee,
    String? status,
    String? avatarUrl,
  }) {
    return VisitModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      serviceName: serviceName ?? this.serviceName,
      serviceBadge: serviceBadge ?? this.serviceBadge,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class VisitReportModel {
  final String requestId;
  final String findings;
  final String treatmentGiven;

  const VisitReportModel({
    required this.requestId,
    required this.findings,
    required this.treatmentGiven,
  });

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'findings': findings,
    'treatmentGiven': treatmentGiven,
  };
}
