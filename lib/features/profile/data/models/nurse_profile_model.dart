class NurseProfileModel {
  final String id;
  final String nurseId;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String dob;
  final String gender;
  final String experience;
  final String specialization;
  final String bio;
  final List<String> languages;
  final String country;
  final String state;
  final String district;
  final String area;
  final String location;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? profileImageUrl;
  final double rating;
  final int totalVisits;
  final int reviewCount;
  final bool isVerified;
  final bool isProfileCompleted;
  final String profileStatus;
  final String approvalStatus;
  final String accountStatus;
  final String nurseCode;

  const NurseProfileModel({
    required this.id,
    this.nurseId = '',
    required this.fullName,
    required this.phoneNumber,
    this.email = '',
    this.dob = '',
    this.gender = '',
    this.experience = '',
    this.specialization = '',
    this.bio = '',
    this.languages = const ['English'],
    this.country = 'India',
    this.state = 'Telangana',
    this.district = 'Hyderabad',
    this.area = 'Yousufguda',
    this.location = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.profileImageUrl,
    this.rating = 5.0,
    this.totalVisits = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isProfileCompleted = true,
    this.profileStatus = 'COMPLETED',
    this.approvalStatus = 'UNDER_REVIEW',
    this.accountStatus = 'ACTIVE',
    this.nurseCode = '',
  });

  bool get isApproved =>
      approvalStatus.toUpperCase() == 'APPROVED' || isVerified;

  bool get isUnderReview =>
      approvalStatus.toUpperCase() == 'UNDER_REVIEW' ||
      approvalStatus.toUpperCase() == 'PENDING';

  bool get isRejected => approvalStatus.toUpperCase() == 'REJECTED';

  factory NurseProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;
    final nurse = json['nurse'] is Map<String, dynamic>
        ? json['nurse'] as Map<String, dynamic>
        : null;

    final rawLangs = profile['languages'];
    List<String> parsedLangs = ['English'];
    if (rawLangs is List) {
      parsedLangs = rawLangs.map((e) => e.toString()).toList();
    }

    final String experienceStr = profile['experienceYears']?.toString() ??
        profile['experience']?.toString() ??
        '0';

    final bool verified = (nurse?['isVerified'] == true) || (profile['isVerified'] == true);
    final String approval = nurse?['approvalStatus']?.toString() ?? profile['approvalStatus']?.toString() ?? 'UNDER_REVIEW';

    return NurseProfileModel(
      id: profile['_id']?.toString() ?? profile['id']?.toString() ?? nurse?['_id']?.toString() ?? 'NURSE-001',
      nurseId: profile['nurseId']?.toString() ?? nurse?['_id']?.toString() ?? '',
      fullName: profile['fullName']?.toString() ?? '',
      phoneNumber: nurse?['mobile']?.toString() ?? profile['phoneNumber']?.toString() ?? '+91 98765 43210',
      email: profile['email']?.toString() ?? nurse?['email']?.toString() ?? '',
      dob: profile['dob']?.toString() ?? '',
      gender: profile['gender']?.toString() ?? '',
      experience: experienceStr,
      specialization: profile['specialization']?.toString() ?? '',
      bio: profile['bio']?.toString() ?? '',
      languages: parsedLangs,
      country: profile['country']?.toString() ?? 'India',
      state: profile['state']?.toString() ?? 'Telangana',
      district: profile['district']?.toString() ?? profile['city']?.toString() ?? 'Hyderabad',
      area: profile['area']?.toString() ?? profile['address']?.toString() ?? '',
      location: profile['address']?.toString() ?? profile['location']?.toString() ?? '',
      pincode: profile['pincode']?.toString() ?? '',
      latitude: (profile['latitude'] as num?)?.toDouble(),
      longitude: (profile['longitude'] as num?)?.toDouble(),
      profileImageUrl: profile['profileImage']?.toString() ?? profile['profileImageUrl']?.toString(),
      rating: (profile['rating'] as num?)?.toDouble() ?? 5.0,
      totalVisits: (profile['completedVisits'] as num?)?.toInt() ?? (profile['totalVisits'] as num?)?.toInt() ?? 0,
      reviewCount: (profile['reviewCount'] as num?)?.toInt() ?? 0,
      isVerified: verified,
      isProfileCompleted: (nurse?['isProfileCompleted'] == true) || (profile['isProfileCompleted'] == true),
      profileStatus: nurse?['profileStatus']?.toString() ?? profile['profileStatus']?.toString() ?? 'COMPLETED',
      approvalStatus: approval,
      accountStatus: nurse?['accountStatus']?.toString() ?? profile['accountStatus']?.toString() ?? 'ACTIVE',
      nurseCode: nurse?['nurseCode']?.toString() ?? profile['nurseCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nurseId': nurseId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'dob': dob,
      'gender': gender,
      'experienceYears': experience,
      'specialization': specialization,
      'bio': bio,
      'languages': languages,
      'country': country,
      'state': state,
      'district': district,
      'area': area,
      'address': location,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'profileImage': profileImageUrl,
      'rating': rating,
      'completedVisits': totalVisits,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'isProfileCompleted': isProfileCompleted,
      'profileStatus': profileStatus,
      'approvalStatus': approvalStatus,
      'accountStatus': accountStatus,
      'nurseCode': nurseCode,
    };
  }

  NurseProfileModel copyWith({
    String? id,
    String? nurseId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? dob,
    String? gender,
    String? experience,
    String? specialization,
    String? bio,
    List<String>? languages,
    String? country,
    String? state,
    String? district,
    String? area,
    String? location,
    String? pincode,
    double? latitude,
    double? longitude,
    String? profileImageUrl,
    double? rating,
    int? totalVisits,
    int? reviewCount,
    bool? isVerified,
    bool? isProfileCompleted,
    String? profileStatus,
    String? approvalStatus,
    String? accountStatus,
    String? nurseCode,
  }) {
    return NurseProfileModel(
      id: id ?? this.id,
      nurseId: nurseId ?? this.nurseId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      experience: experience ?? this.experience,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      area: area ?? this.area,
      location: location ?? this.location,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      totalVisits: totalVisits ?? this.totalVisits,
      reviewCount: reviewCount ?? this.reviewCount,
      isVerified: isVerified ?? this.isVerified,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      profileStatus: profileStatus ?? this.profileStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      nurseCode: nurseCode ?? this.nurseCode,
    );
  }

  static NurseProfileModel mock() {
    return const NurseProfileModel(
      id: 'NURSE-001',
      nurseId: '6a9286b923303db5b97a3bdc',
      fullName: 'Priya Sharma',
      phoneNumber: '+91 98765 43210',
      email: 'priya.sharma@example.com',
      dob: '1995-06-30',
      gender: 'Female',
      experience: '4',
      specialization: 'Elder Care Specialist',
      bio: 'Dedicated home care nursing professional.',
      languages: ['English', 'Hindi'],
      country: 'India',
      state: 'Telangana',
      district: 'Hyderabad',
      area: 'Yousufguda',
      location: '12-3-456, Green Avenue, Near Park',
      pincode: '500081',
      latitude: 17.4483,
      longitude: 78.3814,
      rating: 5.0,
      totalVisits: 0,
      isVerified: false,
      isProfileCompleted: true,
      profileStatus: 'COMPLETED',
      approvalStatus: 'UNDER_REVIEW',
      accountStatus: 'ACTIVE',
      nurseCode: 'NUR-0002',
    );
  }
}

