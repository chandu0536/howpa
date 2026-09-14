class SendOtpRequest {
  final String phone;

  const SendOtpRequest({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

class VerifyOtpRequest {
  final String phone;
  final String otp;
  final String? fcmToken;
  final String deviceType;

  const VerifyOtpRequest({
    required this.phone,
    required this.otp,
    this.fcmToken,
    this.deviceType = 'android',
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp': otp,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'deviceType': deviceType,
      };
}

class NurseUser {
  final String id;
  final String phone;
  final String? fullName;
  final String? gender;
  final String? dob;
  final String? specialization;
  final int? experienceYears;
  final String? address;
  final String? city;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final bool isVerified;
  final bool isKycSubmitted;
  final bool isProfileCompleted;
  final String? approvalStatus;
  final String? accountStatus;
  final String? role;
  final String? profilePhotoUrl;

  const NurseUser({
    required this.id,
    required this.phone,
    this.fullName,
    this.gender,
    this.dob,
    this.specialization,
    this.experienceYears,
    this.address,
    this.city,
    this.pincode,
    this.latitude,
    this.longitude,
    this.isOnline = true,
    this.isVerified = false,
    this.isKycSubmitted = false,
    this.isProfileCompleted = false,
    this.approvalStatus,
    this.accountStatus,
    this.role,
    this.profilePhotoUrl,
  });

  bool get isApproved {
    final s = approvalStatus?.trim().toUpperCase();
    final a = accountStatus?.trim().toUpperCase();
    return isVerified ||
        s == 'APPROVED' ||
        s == 'VERIFIED' ||
        s == 'ACTIVE' ||
        s == 'TRUE' ||
        s == '1' ||
        a == 'APPROVED' ||
        a == 'VERIFIED' ||
        a == 'ACTIVE' ||
        a == 'TRUE' ||
        a == '1';
  }

  bool get isRejected {
    final s = approvalStatus?.trim().toUpperCase();
    final a = accountStatus?.trim().toUpperCase();
    return s == 'REJECTED' || a == 'REJECTED';
  }

  bool get isPending {
    if (isApproved || isRejected) return false;
    final s = approvalStatus?.trim().toUpperCase();
    final a = accountStatus?.trim().toUpperCase();
    return s == 'PENDING' ||
        s == 'UNDER_REVIEW' ||
        s == 'SUBMITTED' ||
        s == 'IN_REVIEW' ||
        a == 'PENDING' ||
        isKycSubmitted ||
        isProfileCompleted;
  }

  factory NurseUser.fromJson(Map<String, dynamic> json) {
    // Check all possible status field keys
    final rawStatus = json['approvalStatus'] ??
        json['approval_status'] ??
        json['verificationStatus'] ??
        json['verification_status'] ??
        json['kycStatus'] ??
        json['kyc_status'] ??
        json['status'] ??
        json['state'];
    final status = rawStatus?.toString();
    final statusUpper = status?.trim().toUpperCase();

    final rawAccStatus = json['accountStatus'] ?? json['account_status'];
    final accStatus = rawAccStatus?.toString();
    final accStatusUpper = accStatus?.trim().toUpperCase();

    // Check all possible boolean/flag fields
    final bool isApprovedFlag = json['isApproved'] == true ||
        json['isApproved'] == 1 ||
        json['isApproved'] == 'true' ||
        json['is_approved'] == true ||
        json['is_approved'] == 1 ||
        json['is_approved'] == 'true' ||
        json['approved'] == true ||
        json['approved'] == 1 ||
        json['approved'] == 'true';

    final bool isVerifiedFlag = json['isVerified'] == true ||
        json['isVerified'] == 1 ||
        json['isVerified'] == 'true' ||
        json['is_verified'] == true ||
        json['is_verified'] == 1 ||
        json['is_verified'] == 'true' ||
        json['verified'] == true ||
        json['verified'] == 1 ||
        json['verified'] == 'true';

    final bool verified = isApprovedFlag ||
        isVerifiedFlag ||
        statusUpper == 'APPROVED' ||
        statusUpper == 'VERIFIED' ||
        statusUpper == 'ACTIVE' ||
        accStatusUpper == 'APPROVED' ||
        accStatusUpper == 'VERIFIED' ||
        accStatusUpper == 'ACTIVE';

    return NurseUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? json['nurseId']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['mobile']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? json['nurse_name'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] as String?,
      specialization: json['specialization'] as String?,
      experienceYears: json['experienceYears'] is int
          ? json['experienceYears'] as int
          : int.tryParse(json['experienceYears']?.toString() ?? ''),
      address: json['address'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool? ?? true,
      isVerified: verified,
      isKycSubmitted: json['isKycSubmitted'] as bool? ??
          json['is_kyc_submitted'] as bool? ??
          json['kycSubmitted'] as bool? ??
          false,
      isProfileCompleted: json['isProfileCompleted'] as bool? ??
          json['is_profile_completed'] as bool? ??
          json['profileCompleted'] as bool? ??
          false,
      approvalStatus: statusUpper == 'APPROVED' || verified ? 'APPROVED' : status,
      accountStatus: accStatus,
      role: json['role'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String? ??
          json['avatarUrl'] as String? ??
          json['avatar'] as String? ??
          json['profile_photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'fullName': fullName,
        'gender': gender,
        'dob': dob,
        'specialization': specialization,
        'experienceYears': experienceYears,
        'address': address,
        'city': city,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'isOnline': isOnline,
        'isVerified': isVerified,
        'isKycSubmitted': isKycSubmitted,
        'isProfileCompleted': isProfileCompleted,
        'approvalStatus': approvalStatus,
        'accountStatus': accountStatus,
        'role': role,
        'profilePhotoUrl': profilePhotoUrl,
      };
}

class AuthResponse {
  final bool success;
  final String? message;
  final String token;
  final NurseUser? nurse;

  const AuthResponse({
    required this.success,
    this.message,
    required this.token,
    this.nurse,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] as Map<String, dynamic> : json;
    final userData = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : (data['nurse'] is Map<String, dynamic>
            ? data['nurse'] as Map<String, dynamic>
            : (json['user'] is Map<String, dynamic>
                ? json['user'] as Map<String, dynamic>
                : (json['nurse'] is Map<String, dynamic>
                    ? json['nurse'] as Map<String, dynamic>
                    : null)));

    return AuthResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      token: data['token'] as String? ?? data['nurseToken'] as String? ?? json['token'] as String? ?? '',
      nurse: userData != null ? NurseUser.fromJson(userData) : null,
    );
  }
}
