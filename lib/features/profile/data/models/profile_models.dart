class UpdateProfileRequest {
  final String fullName;
  final String gender;
  final String dob;
  final String specialization;
  final String experienceYears;
  final String? bio;
  final List<String> languages;
  final String address;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;

  const UpdateProfileRequest({
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.specialization,
    required this.experienceYears,
    this.bio,
    this.languages = const ['English', 'Telugu', 'Hindi'],
    required this.address,
    required this.city,
    required this.pincode,
    this.latitude,
    this.longitude,
  });

  Map<String, String> toFormFields() {
    final map = <String, String>{
      'fullName': fullName,
      'gender': gender,
      'dob': dob,
      'specialization': specialization,
      'experienceYears': experienceYears,
      'languages': languages.join(', '),
      'address': address,
      'city': city,
      'pincode': pincode,
    };
    if (bio != null) map['bio'] = bio!;
    if (latitude != null) map['latitude'] = latitude.toString();
    if (longitude != null) map['longitude'] = longitude.toString();
    return map;
  }
}

class KycDocumentsStatus {
  final bool isNursingCertUploaded;
  final bool isAadhaarFrontUploaded;
  final bool isAadhaarBackUploaded;
  final bool isGovtIdUploaded;
  final bool isPhotoUploaded;
  final String? nursingCertUrl;
  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;
  final String? govtIdUrl;
  final String? photoUrl;
  final String status; // PENDING, APPROVED, REJECTED
  final String? rejectionReason;

  const KycDocumentsStatus({
    this.isNursingCertUploaded = false,
    this.isAadhaarFrontUploaded = false,
    this.isAadhaarBackUploaded = false,
    this.isGovtIdUploaded = false,
    this.isPhotoUploaded = false,
    this.nursingCertUrl,
    this.aadhaarFrontUrl,
    this.aadhaarBackUrl,
    this.govtIdUrl,
    this.photoUrl,
    this.status = 'PENDING',
    this.rejectionReason,
  });

  factory KycDocumentsStatus.fromJson(Map<String, dynamic> json) {
    final cert = json['nursingCertificate'] ?? json['certificate'] ?? json['nursing_certificate'];
    final aadhaarF = json['aadhaarFront'] ?? json['aadhaar'] ?? json['aadhaar_front'] ?? json['aadhaarCard'];
    final aadhaarB = json['aadhaarBack'] ?? json['aadhaar_back'];
    final govt = json['govtId'] ?? json['governmentId'] ?? json['govt_id'] ?? json['idProof'];
    final photo = json['avatar'] ?? json['photo'] ?? json['profilePhoto'] ?? json['recentPhoto'];

    return KycDocumentsStatus(
      isNursingCertUploaded: cert != null || json['isNursingCertUploaded'] == true,
      isAadhaarFrontUploaded: aadhaarF != null || json['isAadhaarFrontUploaded'] == true,
      isAadhaarBackUploaded: aadhaarB != null || json['isAadhaarBackUploaded'] == true,
      isGovtIdUploaded: govt != null || json['isGovtIdUploaded'] == true,
      isPhotoUploaded: photo != null || json['isPhotoUploaded'] == true,
      nursingCertUrl: cert is String ? cert : null,
      aadhaarFrontUrl: aadhaarF is String ? aadhaarF : null,
      aadhaarBackUrl: aadhaarB is String ? aadhaarB : null,
      govtIdUrl: govt is String ? govt : null,
      photoUrl: photo is String ? photo : null,
      status: (json['status'] ?? json['approvalStatus'] ?? 'PENDING').toString(),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}

class SpecializationItem {
  final String id;
  final String name;
  final String? description;

  const SpecializationItem({
    required this.id,
    required this.name,
    this.description,
  });

  factory SpecializationItem.fromJson(Map<String, dynamic> json) {
    return SpecializationItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
