class UpdateProfileRequest {
  final String fullName;
  final String? email;
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
    this.email,
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
    if (email != null && email!.trim().isNotEmpty) {
      map['email'] = email!.trim();
      map['emailId'] = email!.trim();
      map['email_id'] = email!.trim();
    }
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
    String? extractUrl(dynamic obj) {
      if (obj == null) return null;
      if (obj is String && obj.trim().isNotEmpty && obj.trim() != 'null') return obj.trim();
      if (obj is Map) {
        final u = obj['url']?.toString().trim();
        if (u != null && u.isNotEmpty && u != 'null') return u;
        final k = obj['key']?.toString().trim();
        if (k != null && k.isNotEmpty && k != 'null') return k;
        final f = obj['fileUrl']?.toString().trim();
        if (f != null && f.isNotEmpty && f != 'null') return f;
        final p = obj['path']?.toString().trim();
        if (p != null && p.isNotEmpty && p != 'null') return p;
        final l = obj['location']?.toString().trim();
        if (l != null && l.isNotEmpty && l != 'null') return l;
      }
      return null;
    }

    final cert = json['nursingCertificate'] ??
        json['certificate'] ??
        json['nursing_certificate'] ??
        json['nursingCert'] ??
        json['nursing_cert'] ??
        json['degreeCertificate'] ??
        json['degree_certificate'];

    final aadhaarF = json['aadhaarFront'] ??
        json['aadhaar'] ??
        json['aadhaar_front'] ??
        json['aadhaarCard'] ??
        json['aadhaar_card'] ??
        json['aadhaarCardFront'] ??
        json['aadhaar_card_front'] ??
        json['aadharFront'] ??
        json['aadhar_front'] ??
        json['aadhar'];

    final aadhaarB = json['aadhaarBack'] ??
        json['aadhaar_back'] ??
        json['aadhaarCardBack'] ??
        json['aadhaar_card_back'] ??
        json['aadharBack'] ??
        json['aadhar_back'];

    final govt = json['govtId'] ??
        json['governmentId'] ??
        json['govt_id'] ??
        json['idProof'] ??
        json['id_proof'] ??
        json['idCard'] ??
        json['id_card'];

    final photo = json['avatar'] ??
        json['photo'] ??
        json['profilePhoto'] ??
        json['recentPhoto'] ??
        json['profileImage'] ??
        json['profile_image'] ??
        json['profile_photo'];

    final certUrl = extractUrl(cert);
    final aadhaarFUrl = extractUrl(aadhaarF);
    final aadhaarBUrl = extractUrl(aadhaarB);
    final govtUrl = extractUrl(govt);
    final photoUrl = extractUrl(photo);

    final bool certUploaded = certUrl != null ||
        json['isNursingCertUploaded'] == true ||
        json['nursingCertificateUploaded'] == true ||
        json['is_nursing_cert_uploaded'] == true ||
        json['isNursingCertificateUploaded'] == true;

    final bool aadhaarFUploaded = aadhaarFUrl != null ||
        json['isAadhaarFrontUploaded'] == true ||
        json['aadhaarFrontUploaded'] == true ||
        json['is_aadhaar_front_uploaded'] == true ||
        json['isAadharFrontUploaded'] == true;

    final bool aadhaarBUploaded = aadhaarBUrl != null ||
        json['isAadhaarBackUploaded'] == true ||
        json['aadhaarBackUploaded'] == true ||
        json['is_aadhaar_back_uploaded'] == true ||
        json['isAadharBackUploaded'] == true;

    final bool govtUploaded = govtUrl != null ||
        json['isGovtIdUploaded'] == true ||
        json['govtIdUploaded'] == true ||
        json['is_govt_id_uploaded'] == true;

    final bool photoUploaded = photoUrl != null ||
        json['isPhotoUploaded'] == true ||
        json['photoUploaded'] == true ||
        json['is_photo_uploaded'] == true;

    return KycDocumentsStatus(
      isNursingCertUploaded: certUploaded,
      isAadhaarFrontUploaded: aadhaarFUploaded,
      isAadhaarBackUploaded: aadhaarBUploaded,
      isGovtIdUploaded: govtUploaded,
      isPhotoUploaded: photoUploaded,
      nursingCertUrl: certUrl,
      aadhaarFrontUrl: aadhaarFUrl,
      aadhaarBackUrl: aadhaarBUrl,
      govtIdUrl: govtUrl,
      photoUrl: photoUrl,
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

  factory SpecializationItem.fromData(dynamic item) {
    if (item is String) {
      return SpecializationItem(id: item, name: item);
    } else if (item is Map<String, dynamic>) {
      return SpecializationItem.fromJson(item);
    }
    return const SpecializationItem(id: '1', name: 'General Nursing');
  }

  factory SpecializationItem.fromJson(Map<String, dynamic> json) {
    return SpecializationItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
