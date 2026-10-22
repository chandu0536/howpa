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
        if (fcmToken != null) 'deviceToken': fcmToken,
        if (fcmToken != null) 'pushToken': fcmToken,
        if (fcmToken != null) 'token': fcmToken,
        'deviceType': deviceType,
      };
}

class NurseUser {
  final String id;
  final String phone;
  final String? fullName;
  final String? email;
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
  final String? kycStatus;
  final String? verificationStatus;
  final String? role;
  final String? profilePhotoUrl;

  const NurseUser({
    required this.id,
    required this.phone,
    this.fullName,
    this.email,
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
    this.kycStatus,
    this.verificationStatus,
    this.role,
    this.profilePhotoUrl,
  });

  static bool isUnderReviewStatus(String? status) {
    if (status == null) return false;
    final s = status.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    return s == 'UNDER_REVIEW' ||
        s == 'IN_REVIEW' ||
        s == 'REVIEW' ||
        s == 'INREVIEW' ||
        s == 'UNDERREVIEW' ||
        s == 'SUBMITTED' ||
        s == 'AWAITING_APPROVAL' ||
        s == 'WAITING_APPROVAL' ||
        s == 'PENDING_APPROVAL' ||
        s == 'PENDING_VERIFICATION' ||
        s == 'DOCS_SUBMITTED' ||
        s == 'KYC_SUBMITTED' ||
        s == 'DOCUMENTS_SUBMITTED' ||
        s == 'IN_PROGRESS' ||
        s == 'VERIFICATION_IN_PROGRESS';
  }

  bool get isUnderReview {
    if (approvalStatus != null && isUnderReviewStatus(approvalStatus)) return true;
    if (accountStatus != null && isUnderReviewStatus(accountStatus)) return true;
    if (kycStatus != null && isUnderReviewStatus(kycStatus)) return true;
    if (verificationStatus != null && isUnderReviewStatus(verificationStatus)) return true;
    return false;
  }

  bool get isApproved {
    if (isUnderReview) return false;
    final s = approvalStatus?.trim().toUpperCase();
    return (isVerified && s != 'PENDING' && !isUnderReview) ||
        s == 'APPROVED' ||
        s == 'VERIFIED' ||
        s == 'ACTIVE' ||
        s == 'TRUE' ||
        s == '1';
  }

  bool get isRejected {
    final s = approvalStatus?.trim().toUpperCase();
    final a = accountStatus?.trim().toUpperCase();
    return s == 'REJECTED' || a == 'REJECTED' || s == 'BLOCKED' || a == 'BLOCKED';
  }

  bool get isPending {
    if (isApproved || isRejected) return false;
    if (isUnderReview) return true;
    final s = approvalStatus?.trim().toUpperCase();
    final a = accountStatus?.trim().toUpperCase();
    final isPendingStatus = s == 'PENDING' || a == 'PENDING';
    return (isProfileCompleted && isKycSubmitted) || isPendingStatus;
  }

  factory NurseUser.fromJson(Map<String, dynamic> json) {
    // Check all possible status field keys
    final rawApprovalStatus = json['approvalStatus'] ?? json['approval_status'];
    final rawVerificationStatus = json['verificationStatus'] ?? json['verification_status'];
    final rawKycStatus = json['kycStatus'] ?? json['kyc_status'] ?? json['documentStatus'] ?? json['document_status'];
    final rawAccountStatus = json['accountStatus'] ?? json['account_status'];
    final rawGeneralStatus = json['status'] ?? json['state'];

    final List<String?> candidateStatuses = [
      rawApprovalStatus?.toString(),
      rawVerificationStatus?.toString(),
      rawKycStatus?.toString(),
      rawGeneralStatus?.toString(),
      rawAccountStatus?.toString(),
    ];
    if (json['kyc'] is Map) {
      candidateStatuses.add(json['kyc']['status']?.toString());
      candidateStatuses.add(json['kyc']['approvalStatus']?.toString());
    }
    if (json['documents'] is Map) {
      candidateStatuses.add(json['documents']['status']?.toString());
    }
    if (json['verification'] is Map) {
      candidateStatuses.add(json['verification']['status']?.toString());
    }

    final bool isReviewOrSubmitted = candidateStatuses.any((s) => isUnderReviewStatus(s));

    final bool isApprovedStatus = candidateStatuses.any((s) {
      if (s == null) return false;
      final u = s.trim().toUpperCase();
      return u == 'APPROVED' || u == 'VERIFIED' || u == 'ACTIVE';
    });

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

    final bool verified = (isApprovedStatus ||
        (isApprovedFlag && !isReviewOrSubmitted) ||
        (isVerifiedFlag && !isReviewOrSubmitted)) &&
        !isReviewOrSubmitted;

    final rawPhoto = json['profilePhotoUrl'] ??
        json['profile_photo_url'] ??
        json['profilePhoto'] ??
        json['profile_photo'] ??
        json['avatarUrl'] ??
        json['avatar_url'] ??
        json['avatar'] ??
        json['photoUrl'] ??
        json['photo_url'] ??
        json['photo'] ??
        json['image'] ??
        json['profileImage'] ??
        json['profile_image'] ??
        (json['documents'] is Map ? (json['documents']['recentPhoto'] ?? json['documents']['avatar'] ?? json['documents']['photo']) : null);
    final photoStr = rawPhoto is Map ? (rawPhoto['url'] ?? rawPhoto['key'])?.toString() : rawPhoto?.toString();

    String? nameStr;
    for (final key in ['fullName', 'full_name', 'name', 'nurse_name', 'nurseName', 'userName', 'user_name']) {
      final val = json[key]?.toString();
      if (val != null && val.trim().isNotEmpty && val.trim() != 'null') {
        nameStr = val.trim();
        break;
      }
    }
    if (nameStr == null && (json['firstName'] != null || json['first_name'] != null)) {
      final fn = (json['firstName'] ?? json['first_name'] ?? '').toString().trim();
      final ln = (json['lastName'] ?? json['last_name'] ?? '').toString().trim();
      if ('$fn $ln'.trim().isNotEmpty) {
        nameStr = '$fn $ln'.trim();
      }
    }

    String? emailStr = json['email']?.toString() ?? json['emailId']?.toString() ?? json['email_id']?.toString();
    if (emailStr != null && (emailStr.trim().isEmpty || emailStr.trim() == 'null')) {
      emailStr = null;
    }

    String? dobStr = json['dob']?.toString() ?? json['dateOfBirth']?.toString() ?? json['date_of_birth']?.toString();
    if (dobStr != null && (dobStr.trim().isEmpty || dobStr.trim() == 'null')) {
      dobStr = null;
    }

    String? genderStr = json['gender']?.toString() ?? json['sex']?.toString();
    if (genderStr != null && (genderStr.trim().isEmpty || genderStr.trim() == 'null')) {
      genderStr = null;
    }

    // Check if actual documents have non-empty URLs or keys uploaded
    bool hasActualDocs = false;
    final docsObj = json['documents'];
    if (docsObj is Map<String, dynamic>) {
      for (final val in docsObj.values) {
        if (val is Map) {
          final u = val['url']?.toString().trim();
          final k = val['key']?.toString().trim();
          if ((u != null && u.isNotEmpty && u != 'null') || (k != null && k.isNotEmpty && k != 'null')) {
            hasActualDocs = true;
            break;
          }
        } else if (val is String && val.trim().isNotEmpty && val.trim() != 'null') {
          hasActualDocs = true;
          break;
        }
      }
    } else if (json['nursingCertificate'] != null && json['nursingCertificate'].toString().trim().isNotEmpty && json['nursingCertificate'].toString() != 'null') {
      hasActualDocs = true;
    } else if (json['aadhaarFront'] != null && json['aadhaarFront'].toString().trim().isNotEmpty && json['aadhaarFront'].toString() != 'null') {
      hasActualDocs = true;
    } else if (json['certificate'] != null && json['certificate'].toString().trim().isNotEmpty && json['certificate'].toString() != 'null') {
      hasActualDocs = true;
    }

    final bool hasFullName = nameStr != null && nameStr.trim().isNotEmpty && nameStr.trim() != 'Nurse';

    final bool isProfileCompletedExplicit = json['isProfileCompleted'] == true ||
        json['is_profile_completed'] == true ||
        json['profileCompleted'] == true ||
        json['isProfileComplete'] == true;

    final bool isKycSubmittedExplicit = json['isKycSubmitted'] == true ||
        json['isKycSubmitted'] == 1 ||
        json['isKycSubmitted'] == 'true' ||
        json['is_kyc_submitted'] == true ||
        json['is_kyc_submitted'] == 1 ||
        json['is_kyc_submitted'] == 'true' ||
        json['kycSubmitted'] == true ||
        json['kyc_submitted'] == true ||
        json['isKycUploaded'] == true ||
        json['kycUploaded'] == true ||
        json['documentsSubmitted'] == true ||
        json['isDocumentsSubmitted'] == true ||
        json['step'] == 2 ||
        json['step'] == 3 ||
        json['step'] == '2' ||
        json['step'] == '3' ||
        json['registrationStep'] == 2 ||
        json['registrationStep'] == 3 ||
        json['registration_step'] == 2 ||
        json['registration_step'] == 3;

    final bool profileCompletedVal = isReviewOrSubmitted ||
        (isProfileCompletedExplicit && hasFullName) ||
        hasFullName ||
        hasActualDocs;

    final bool kycSubmittedVal = isReviewOrSubmitted ||
        isKycSubmittedExplicit ||
        hasActualDocs;

    double? lat;
    final rawLat = json['latitude'] ??
        json['lat'] ??
        (json['location'] is Map
            ? (json['location']['coordinates'] is List
                ? json['location']['coordinates'][1]
                : json['location']['latitude'] ?? json['location']['lat'])
            : null);
    if (rawLat is num) {
      lat = rawLat.toDouble();
    } else if (rawLat is String) {
      lat = double.tryParse(rawLat);
    }

    double? lng;
    final rawLng = json['longitude'] ??
        json['lng'] ??
        json['lon'] ??
        (json['location'] is Map
            ? (json['location']['coordinates'] is List
                ? json['location']['coordinates'][0]
                : json['location']['longitude'] ?? json['location']['lng'] ?? json['location']['lon'])
            : null);
    if (rawLng is num) {
      lng = rawLng.toDouble();
    } else if (rawLng is String) {
      lng = double.tryParse(rawLng);
    }

    final String chosenApprovalStatus = verified
        ? 'APPROVED'
        : (isReviewOrSubmitted
            ? 'UNDER_REVIEW'
            : (rawApprovalStatus?.toString() ?? rawGeneralStatus?.toString() ?? (kycSubmittedVal ? 'PENDING' : null) ?? 'PENDING'));

    return NurseUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? json['nurseId']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['mobile']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      fullName: nameStr,
      email: emailStr?.trim(),
      gender: genderStr?.trim(),
      dob: dobStr?.trim(),
      specialization: json['specialization'] as String?,
      experienceYears: json['experienceYears'] is int
          ? json['experienceYears'] as int
          : int.tryParse(json['experienceYears']?.toString() ?? ''),
      address: json['address'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      latitude: lat,
      longitude: lng,
      isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool? ?? true,
      isVerified: verified,
      isKycSubmitted: kycSubmittedVal,
      isProfileCompleted: profileCompletedVal,
      approvalStatus: chosenApprovalStatus,
      accountStatus: rawAccountStatus?.toString(),
      kycStatus: rawKycStatus?.toString() ?? (isReviewOrSubmitted ? 'UNDER_REVIEW' : null),
      verificationStatus: rawVerificationStatus?.toString() ?? (isReviewOrSubmitted ? 'UNDER_REVIEW' : null),
      role: json['role'] as String?,
      profilePhotoUrl: photoStr,
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
        'kycStatus': kycStatus,
        'verificationStatus': verificationStatus,
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
    Map<String, dynamic>? rawUserData = data['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['user'] as Map<String, dynamic>)
        : (data['nurse'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['nurse'] as Map<String, dynamic>)
            : (json['user'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(json['user'] as Map<String, dynamic>)
                : (json['nurse'] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(json['nurse'] as Map<String, dynamic>)
                    : (data['profile'] is Map<String, dynamic>
                        ? Map<String, dynamic>.from(data['profile'] as Map<String, dynamic>)
                        : null))));

    Map<String, dynamic> combinedUserData = {};
    if (rawUserData != null) {
      combinedUserData.addAll(rawUserData);
    } else if (data.containsKey('phone') || data.containsKey('mobile') || data.containsKey('_id') || data.containsKey('fullName')) {
      combinedUserData.addAll(data);
    }

    // Merge status and metadata from data and root json into combinedUserData if missing
    for (final key in [
      'status',
      'approvalStatus',
      'approval_status',
      'verificationStatus',
      'verification_status',
      'kycStatus',
      'kyc_status',
      'documentStatus',
      'document_status',
      'accountStatus',
      'account_status',
      'state',
      'isApproved',
      'is_approved',
      'isVerified',
      'is_verified',
      'isKycSubmitted',
      'is_kyc_submitted',
      'kycSubmitted',
      'isProfileCompleted',
      'is_profile_completed',
      'documents',
      'step',
      'registrationStep',
      'registration_step',
    ]) {
      if (!combinedUserData.containsKey(key) || combinedUserData[key] == null) {
        if (data.containsKey(key) && data[key] != null) {
          combinedUserData[key] = data[key];
        } else if (json.containsKey(key) && json[key] != null) {
          combinedUserData[key] = json[key];
        }
      }
    }

    return AuthResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      token: data['token'] as String? ?? data['nurseToken'] as String? ?? json['token'] as String? ?? '',
      nurse: combinedUserData.isNotEmpty ? NurseUser.fromJson(combinedUserData) : null,
    );
  }
}
