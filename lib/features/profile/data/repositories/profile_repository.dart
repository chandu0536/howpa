import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../auth/data/models/auth_models.dart';
import '../models/profile_models.dart';

abstract class ProfileRepository {
  Future<NurseUser?> getProfile();
  Future<bool> updateProfile(UpdateProfileRequest request, {File? profilePhoto});
  Future<KycDocumentsStatus> getDocumentsStatus();
  Future<bool> uploadKycDocuments({
    File? nursingCertificate,
    File? aadhaarFront,
    File? aadhaarBack,
    File? govtId,
    File? recentPhoto,
    Map<String, File>? extraFiles,
  });
  Future<List<SpecializationItem>> getMasterSpecializations();
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _client;

  ProfileRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<NurseUser?> getProfile() async {
    try {
      final response = await _client.get(ApiEndpoints.profile);
      if (response != null && response is Map<String, dynamic>) {
        dynamic target = response['data'] ?? response['nurse'] ?? response['user'] ?? response['profile'] ?? response;
        if (target is Map<String, dynamic>) {
          if (target['nurse'] is Map<String, dynamic>) {
            target = target['nurse'];
          } else if (target['user'] is Map<String, dynamic>) {
            target = target['user'];
          } else if (target['profile'] is Map<String, dynamic>) {
            target = target['profile'];
          }
          return NurseUser.fromJson(target as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    // Fallback attempt: check nurse status endpoint
    try {
      final statusResp = await _client.get(ApiEndpoints.status);
      if (statusResp != null && statusResp is Map<String, dynamic>) {
        dynamic target = statusResp['data'] ?? statusResp['nurse'] ?? statusResp['user'] ?? statusResp;
        if (target is Map<String, dynamic>) {
          return NurseUser.fromJson(target);
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<bool> updateProfile(UpdateProfileRequest request, {File? profilePhoto}) async {
    final fields = request.toFormFields();
    final files = <String, File>{};
    if (profilePhoto != null && profilePhoto.existsSync()) {
      files['avatar'] = profilePhoto;
    }

    final response = await _client.multipartRequest(
      method: 'PUT',
      url: ApiEndpoints.profile,
      fields: fields,
      files: files.isNotEmpty ? files : null,
    );

    if (response is Map && response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to update profile details',
      );
    }
    return true;
  }

  @override
  Future<KycDocumentsStatus> getDocumentsStatus() async {
    try {
      final response = await _client.get(ApiEndpoints.documents);
      if (response != null && response['data'] != null) {
        return KycDocumentsStatus.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return const KycDocumentsStatus();
  }

  @override
  Future<bool> uploadKycDocuments({
    File? nursingCertificate,
    File? aadhaarFront,
    File? aadhaarBack,
    File? govtId,
    File? recentPhoto,
    Map<String, File>? extraFiles,
  }) async {
    final files = <String, File>{};
    if (nursingCertificate != null && nursingCertificate.existsSync()) {
      files['nursingCertificate'] = nursingCertificate;
      files['certificate'] = nursingCertificate;
    }
    if (aadhaarFront != null && aadhaarFront.existsSync()) {
      files['aadhaarFront'] = aadhaarFront;
      files['aadhaar'] = aadhaarFront;
    }
    if (aadhaarBack != null && aadhaarBack.existsSync()) {
      files['aadhaarBack'] = aadhaarBack;
    }
    if (govtId != null && govtId.existsSync()) {
      files['govtId'] = govtId;
      files['governmentId'] = govtId;
    }
    if (recentPhoto != null && recentPhoto.existsSync()) {
      files['avatar'] = recentPhoto;
      files['profilePhoto'] = recentPhoto;
      files['photo'] = recentPhoto;
    }
    if (extraFiles != null) {
      for (final entry in extraFiles.entries) {
        if (entry.value.existsSync()) {
          files[entry.key] = entry.value;
        }
      }
    }

    final response = await _client.multipartRequest(
      method: 'POST',
      url: ApiEndpoints.documents,
      files: files.isNotEmpty ? files : null,
    );

    if (response is Map && response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'Failed to upload KYC documents',
      );
    }
    return true;
  }

  @override
  Future<List<SpecializationItem>> getMasterSpecializations() async {
    try {
      final response = await _client.get(ApiEndpoints.specializations, requiresAuth: false);
      if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => SpecializationItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return const [
      SpecializationItem(id: '1', name: 'General Care'),
      SpecializationItem(id: '2', name: 'Elder Care'),
      SpecializationItem(id: '3', name: 'Post-Surgery Care'),
      SpecializationItem(id: '4', name: 'Critical Care'),
      SpecializationItem(id: '5', name: 'Pediatric Care'),
      SpecializationItem(id: '6', name: 'Palliative Care'),
    ];
  }
}
