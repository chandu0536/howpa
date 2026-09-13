class SendOtpRequest {
  final String mobile;

  const SendOtpRequest({required this.mobile});

  Map<String, dynamic> toJson() => {
    'phone': mobile,
    'mobile': mobile,
  };
}

// Alias for backwards compatibility
typedef LoginRequest = SendOtpRequest;

class SendOtpResponse {
  final bool success;
  final String message;
  final String? debugInfo;

  const SendOtpResponse({
    required this.success,
    required this.message,
    this.debugInfo,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'OTP sent successfully',
      debugInfo: json['debugInfo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (debugInfo != null) 'debugInfo': debugInfo,
  };
}

class VerifyOtpRequest {
  final String mobile;
  final String otp;
  final String fcmToken;
  final String deviceType;

  const VerifyOtpRequest({
    required this.mobile,
    required this.otp,
    required this.fcmToken,
    required this.deviceType,
  });

  Map<String, dynamic> toJson() => {
    'phone': mobile,
    'mobile': mobile,
    'otp': otp,
    'fcmToken': fcmToken,
    'deviceType': deviceType,
  };
}

// Alias for backwards compatibility
typedef OtpRequest = VerifyOtpRequest;

class UserModel {
  final String id;
  final String mobile;
  final String email;
  final String role;
  final bool isVerified;
  final bool isProfileCompleted;
  final String profileStatus; // "PENDING", "APPROVED", etc.
  final String approvalStatus; // "PENDING", "APPROVED", etc.
  final String accountStatus; // "ACTIVE", etc.
  final String? nurseCode;
  final String? deviceToken;
  final String? deviceType;

  const UserModel({
    required this.id,
    required this.mobile,
    this.email = '',
    required this.role,
    this.isVerified = false,
    this.isProfileCompleted = false,
    this.profileStatus = 'PENDING',
    this.approvalStatus = 'PENDING',
    this.accountStatus = 'ACTIVE',
    this.nurseCode,
    this.deviceToken,
    this.deviceType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['nurseId']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'nurse',
      isVerified: json['isVerified'] ?? false,
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      profileStatus: json['profileStatus']?.toString() ?? 'PENDING',
      approvalStatus: json['approvalStatus']?.toString() ?? 'PENDING',
      accountStatus: json['accountStatus']?.toString() ?? 'ACTIVE',
      nurseCode: json['nurseCode']?.toString(),
      deviceToken: json['deviceToken']?.toString(),
      deviceType: json['deviceType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mobile': mobile,
    'email': email,
    'role': role,
    'isVerified': isVerified,
    'isProfileCompleted': isProfileCompleted,
    'profileStatus': profileStatus,
    'approvalStatus': approvalStatus,
    'accountStatus': accountStatus,
    if (nurseCode != null) 'nurseCode': nurseCode,
    if (deviceToken != null) 'deviceToken': deviceToken,
    if (deviceType != null) 'deviceType': deviceType,
  };

  UserModel copyWith({
    String? id,
    String? mobile,
    String? email,
    String? role,
    bool? isVerified,
    bool? isProfileCompleted,
    String? profileStatus,
    String? approvalStatus,
    String? accountStatus,
    String? nurseCode,
    String? deviceToken,
    String? deviceType,
  }) {
    return UserModel(
      id: id ?? this.id,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      profileStatus: profileStatus ?? this.profileStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      nurseCode: nurseCode ?? this.nurseCode,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceType: deviceType ?? this.deviceType,
    );
  }
}

class VerifyOtpResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final Map<String, dynamic>? rawProfile;

  const VerifyOtpResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.rawProfile,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['nurse'] != null && json['nurse'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['nurse'] as Map<String, dynamic>);
    } else if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    }

    return VerifyOtpResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? (json['token'] != null ? 'OTP verified successfully' : ''),
      token: json['token']?.toString() ?? json['nurse_token']?.toString(),
      user: parsedUser,
      rawProfile: json['profile'] is Map<String, dynamic> ? json['profile'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (token != null) 'token': token,
    if (user != null) 'user': user!.toJson(),
    if (rawProfile != null) 'profile': rawProfile,
  };
}

// Backward compatibility model
class AuthResponseModel {
  final bool success;
  final String? token;
  final String? message;
  final String? nurseId;
  final bool isVerified;
  final UserModel? user;

  const AuthResponseModel({
    required this.success,
    this.token,
    this.message,
    this.nurseId,
    this.isVerified = false,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['nurse'] != null && json['nurse'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['nurse'] as Map<String, dynamic>);
    } else if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    }

    return AuthResponseModel(
      success: json['success'] ?? true,
      token: json['token']?.toString(),
      message: json['message']?.toString(),
      nurseId: parsedUser?.id ?? json['nurse_id']?.toString() ?? json['_id']?.toString(),
      isVerified: parsedUser?.approvalStatus == 'APPROVED' || (json['isVerified'] ?? json['is_verified'] ?? false),
      user: parsedUser,
    );
  }
}

class RegistrationRequest {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String dob;
  final String gender;
  final String experience;
  final String specialization;
  final String country;
  final String state;
  final String district;
  final String area;
  final String location;
  final String? pincode;
  final String? bio;
  final List<String>? languages;
  final double? latitude;
  final double? longitude;
  final String? qualification;
  final String? registrationNumber;
  final String? idProofType;
  final String? idProofNumber;

  const RegistrationRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.dob,
    required this.gender,
    required this.experience,
    required this.specialization,
    required this.country,
    required this.state,
    required this.district,
    required this.area,
    required this.location,
    this.pincode,
    this.bio,
    this.languages,
    this.latitude,
    this.longitude,
    this.qualification,
    this.registrationNumber,
    this.idProofType,
    this.idProofNumber,
  });

  Map<String, String> toFormDataFields() => {
    'fullName': fullName,
    'gender': gender.toLowerCase(),
    'dob': dob,
    'specialization': specialization,
    'experienceYears': experience,
    'bio': bio ?? 'Dedicated home care nursing professional.',
    'languages': languages != null && languages!.isNotEmpty
        ? '[${languages!.map((l) => '"$l"').join(",")}]'
        : '["English","Hindi"]',
    'address': location.isNotEmpty ? location : (area.isNotEmpty ? area : district),
    'city': district.isNotEmpty ? district : 'Hyderabad',
    'state': state.isNotEmpty ? state : 'Telangana',
    'pincode': pincode ?? '500081',
    'latitude': latitude?.toString() ?? '17.4483',
    'longitude': longitude?.toString() ?? '78.3814',
  };

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone_number': phoneNumber,
    'email': email,
    'dob': dob,
    'gender': gender,
    'experience': experience,
    'specialization': specialization,
    'country': country,
    'state': state,
    'district': district,
    'area': area,
    'location': location,
    'pincode': pincode,
    'bio': bio,
    'languages': languages,
    'latitude': latitude,
    'longitude': longitude,
    'qualification': qualification,
    'registration_number': registrationNumber,
    'id_proof_type': idProofType,
    'id_proof_number': idProofNumber,
  };
}

