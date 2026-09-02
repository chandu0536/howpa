import '../../../../core/network/api_endpoints.dart';

String _resolveImageUrl(dynamic raw) {
  if (raw == null) return '';
  final str = raw.toString().trim();
  if (str.isEmpty || str == 'null' || str == 'undefined') return '';
  if (str.startsWith('http://') || str.startsWith('https://')) {
    return str;
  }
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
      json['user']?['photo'];
}

class ScheduleItemModel {
  final String id;
  final String patientName;
  final String timeRange;
  final String address;
  final String avatarUrl;
  final String serviceType;
  final String status;
  final String phone;

  const ScheduleItemModel({
    required this.id,
    required this.patientName,
    required this.timeRange,
    required this.address,
    required this.avatarUrl,
    required this.serviceType,
    required this.status,
    this.phone = '',
  });

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    final patientObj = _extractPatientMap(json);

    final String patient = json['patientName']?.toString() ??
        patientObj?['name']?.toString() ??
        patientObj?['fullName']?.toString() ??
        patientObj?['patientName']?.toString() ??
        json['name']?.toString() ??
        json['fullName']?.toString() ??
        'Patient';

    final candidateAvatar = _extractCandidateAvatar(json, patientObj);
    final String avatar = _resolveImageUrl(candidateAvatar);

    final dynamic rawAddrSource = json['address'] ??
        patientObj?['address'] ??
        json['location'] ??
        patientObj?['location'] ??
        json['patientAddress'];
    final String addr = _parseAddress(rawAddrSource);

    final String phoneNum = json['phone']?.toString() ??
        patientObj?['phone']?.toString() ??
        patientObj?['mobile']?.toString() ??
        json['mobile']?.toString() ??
        '';

    return ScheduleItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['visitId']?.toString() ?? '',
      patientName: patient,
      timeRange: json['timeRange']?.toString() ??
          json['time']?.toString() ??
          json['scheduledTime']?.toString() ??
          json['slot']?.toString() ??
          'Scheduled',
      address: addr.isNotEmpty ? addr : 'Location provided',
      avatarUrl: avatar.isNotEmpty ? avatar : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      serviceType: json['serviceType']?.toString() ??
          json['service']?.toString() ??
          json['treatment']?.toString() ??
          'Home Nursing Care',
      status: (json['visitStatus'] != null && json['visitStatus'].toString().trim().isNotEmpty)
          ? json['visitStatus'].toString().trim()
          : (json['status']?.toString() ?? 'Scheduled'),
      phone: phoneNum,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'timeRange': timeRange,
      'address': address,
      'avatarUrl': avatarUrl,
      'serviceType': serviceType,
      'status': status,
      'phone': phone,
    };
  }
}

class DashboardDataModel {
  final bool isOnline;
  final int todayVisits;
  final int completedVisits;
  final int waitingRequests;
  final int upcomingVisits;
  final String todayEarnings;
  final double rating;
  final List<ScheduleItemModel> todaySchedule;
  final List<dynamic> recentNotifications;

  const DashboardDataModel({
    required this.isOnline,
    required this.todayVisits,
    required this.completedVisits,
    this.waitingRequests = 0,
    this.upcomingVisits = 0,
    required this.todayEarnings,
    required this.rating,
    required this.todaySchedule,
    this.recentNotifications = const [],
  });

  // Backward compatibility getters
  bool get isOnDuty => isOnline;
  int get pendingVisits => upcomingVisits > 0 ? upcomingVisits : (todayVisits > completedVisits ? todayVisits - completedVisits : 0);

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawEarnings = data['todayEarnings'] ?? data['earnings'];
    String formattedEarnings = '₹0';
    if (rawEarnings is num) {
      final isWhole = rawEarnings == rawEarnings.roundToDouble();
      formattedEarnings = '₹${isWhole ? rawEarnings.toInt() : rawEarnings.toStringAsFixed(2)}';
    } else if (rawEarnings != null && rawEarnings.toString().isNotEmpty) {
      final s = rawEarnings.toString().trim();
      formattedEarnings = s.startsWith('₹') ? s : '₹$s';
    }

    final scheduleList = (data['todaySchedule'] as List<dynamic>?)
            ?.map((e) => ScheduleItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final onlineVal = data['isOnline'] ?? data['isOnDuty'];
    final bool resolvedOnline = onlineVal == true || onlineVal == 'true' || onlineVal == 1;

    return DashboardDataModel(
      isOnline: resolvedOnline,
      todayVisits: (data['todayVisits'] as num?)?.toInt() ?? 0,
      completedVisits: (data['completedVisits'] as num?)?.toInt() ?? 0,
      waitingRequests: (data['waitingRequests'] as num?)?.toInt() ?? 0,
      upcomingVisits: (data['upcomingVisits'] as num?)?.toInt() ?? (data['pendingVisits'] as num?)?.toInt() ?? 0,
      todayEarnings: formattedEarnings,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      todaySchedule: scheduleList,
      recentNotifications: data['recentNotifications'] as List<dynamic>? ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
      'todayVisits': todayVisits,
      'completedVisits': completedVisits,
      'waitingRequests': waitingRequests,
      'upcomingVisits': upcomingVisits,
      'todayEarnings': todayEarnings,
      'rating': rating,
      'todaySchedule': todaySchedule.map((e) => e.toJson()).toList(),
      'recentNotifications': recentNotifications,
    };
  }

  DashboardDataModel copyWith({
    bool? isOnline,
    int? todayVisits,
    int? completedVisits,
    int? waitingRequests,
    int? upcomingVisits,
    String? todayEarnings,
    double? rating,
    List<ScheduleItemModel>? todaySchedule,
    List<dynamic>? recentNotifications,
  }) {
    return DashboardDataModel(
      isOnline: isOnline ?? this.isOnline,
      todayVisits: todayVisits ?? this.todayVisits,
      completedVisits: completedVisits ?? this.completedVisits,
      waitingRequests: waitingRequests ?? this.waitingRequests,
      upcomingVisits: upcomingVisits ?? this.upcomingVisits,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      rating: rating ?? this.rating,
      todaySchedule: todaySchedule ?? this.todaySchedule,
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }

  static DashboardDataModel empty() {
    return const DashboardDataModel(
      isOnline: true,
      todayVisits: 0,
      completedVisits: 0,
      waitingRequests: 0,
      upcomingVisits: 0,
      todayEarnings: '₹0',
      rating: 5.0,
      todaySchedule: [],
      recentNotifications: [],
    );
  }

  static DashboardDataModel mock() {
    return const DashboardDataModel(
      isOnline: true,
      todayVisits: 6,
      completedVisits: 4,
      waitingRequests: 1,
      upcomingVisits: 2,
      todayEarnings: '₹3,200',
      rating: 4.9,
      todaySchedule: [
        ScheduleItemModel(
          id: '1',
          patientName: 'Mrs. Anjali Patel',
          timeRange: '10:00 AM - 11:30 AM',
          address: 'Flat 402, Green Valley Apts, Banjara Hills, Hyderabad',
          avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
          serviceType: 'Wound Dressing',
          status: 'Confirmed',
        ),
        ScheduleItemModel(
          id: '2',
          patientName: 'Mr. Suresh Verma',
          timeRange: '02:00 PM - 03:00 PM',
          address: 'Plot 18, Road No. 12, Jubilee Hills, Hyderabad',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          serviceType: 'IV Drip & Medication',
          status: 'Upcoming',
        ),
      ],
    );
  }
}

