class DocumentProofItem {
  final String url;
  final String key;
  final bool verified;

  const DocumentProofItem({
    this.url = '',
    this.key = '',
    this.verified = false,
  });

  bool get hasFile => url.isNotEmpty || key.isNotEmpty;

  factory DocumentProofItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return DocumentProofItem(
        url: json['url']?.toString() ?? '',
        key: json['key']?.toString() ?? '',
        verified: json['verified'] ?? false,
      );
    } else if (json is String) {
      return DocumentProofItem(url: json, key: json);
    }
    return const DocumentProofItem();
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'key': key,
    'verified': verified,
  };
}

class VerificationDocumentsModel {
  final String nurseId;
  final DocumentProofItem nursingCertificate;
  final DocumentProofItem aadhaarFront;
  final DocumentProofItem aadhaarBack;
  final DocumentProofItem governmentId;
  final DocumentProofItem addressProof;
  final DocumentProofItem photo;
  final String status; // "PENDING", "APPROVED", "REJECTED"
  final String verificationRemark;
  final String? approvedAt;
  final String? submittedAt;

  const VerificationDocumentsModel({
    required this.nurseId,
    this.nursingCertificate = const DocumentProofItem(),
    this.aadhaarFront = const DocumentProofItem(),
    this.aadhaarBack = const DocumentProofItem(),
    this.governmentId = const DocumentProofItem(),
    this.addressProof = const DocumentProofItem(),
    this.photo = const DocumentProofItem(),
    this.status = 'PENDING',
    this.verificationRemark = '',
    this.approvedAt,
    this.submittedAt,
  });

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';

  factory VerificationDocumentsModel.fromJson(Map<String, dynamic> json) {
    final docs = json['documents'] is Map<String, dynamic>
        ? json['documents'] as Map<String, dynamic>
        : json;

    return VerificationDocumentsModel(
      nurseId: docs['nurseId']?.toString() ?? '',
      nursingCertificate: DocumentProofItem.fromJson(docs['nursingCertificate']),
      aadhaarFront: DocumentProofItem.fromJson(docs['aadhaarFront']),
      aadhaarBack: DocumentProofItem.fromJson(docs['aadhaarBack']),
      governmentId: DocumentProofItem.fromJson(docs['governmentId']),
      addressProof: DocumentProofItem.fromJson(docs['addressProof']),
      photo: DocumentProofItem.fromJson(docs['photo']),
      status: docs['status']?.toString() ?? 'PENDING',
      verificationRemark: docs['verificationRemark']?.toString() ?? '',
      approvedAt: docs['approvedAt']?.toString(),
      submittedAt: docs['submittedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nurseId': nurseId,
    'nursingCertificate': nursingCertificate.toJson(),
    'aadhaarFront': aadhaarFront.toJson(),
    'aadhaarBack': aadhaarBack.toJson(),
    'governmentId': governmentId.toJson(),
    'addressProof': addressProof.toJson(),
    'photo': photo.toJson(),
    'status': status,
    'verificationRemark': verificationRemark,
    if (approvedAt != null) 'approvedAt': approvedAt,
    if (submittedAt != null) 'submittedAt': submittedAt,
  };
}
