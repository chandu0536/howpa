import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../auth/data/models/auth_models.dart';
import '../models/profile_models.dart';

import '../../../../core/services/user_profile_manager.dart';

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

  void _syncUserToManager(NurseUser user) {
    UserProfileManager.instance.updateProfileDetails(
      nurseId: user.id,
      fullName: user.fullName,
      phoneNumber: user.phone,
      email: user.email,
      dob: user.dob,
      gender: user.gender,
      experience: user.experienceYears?.toString(),
      specialization: user.specialization,
      location: user.address,
      area: user.city,
      district: user.city,
      latitude: user.latitude,
      longitude: user.longitude,
      profilePhotoUrl: user.profilePhotoUrl,
    );
  }

  void _safeMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value != null) {
        if (value is String) {
          if (value.trim().isNotEmpty && value.trim() != 'null') {
            target[key] = value;
          } else if (!target.containsKey(key)) {
            target[key] = value;
          }
        } else {
          target[key] = value;
        }
      }
    });
  }

  @override
  Future<NurseUser?> getProfile() async {
    try {
      final response = await _client.get(ApiEndpoints.profile);
      if (response != null && response is Map<String, dynamic>) {
        final Map<String, dynamic> combined = {};
        if (response['nurse'] is Map<String, dynamic>) {
          _safeMerge(combined, response['nurse'] as Map<String, dynamic>);
        }
        if (response['user'] is Map<String, dynamic>) {
          _safeMerge(combined, response['user'] as Map<String, dynamic>);
        }
        if (response['data'] is Map<String, dynamic>) {
          _safeMerge(combined, response['data'] as Map<String, dynamic>);
        }
        if (response['profile'] is Map<String, dynamic>) {
          _safeMerge(combined, response['profile'] as Map<String, dynamic>);
        }
        if (combined.isEmpty) {
          _safeMerge(combined, response);
        }
        final user = NurseUser.fromJson(combined);
        _syncUserToManager(user);
        return user;
      }
    } catch (_) {}

    // Fallback attempt: check nurse status endpoint
    try {
      final statusResp = await _client.get(ApiEndpoints.status);
      if (statusResp != null && statusResp is Map<String, dynamic>) {
        dynamic target = statusResp['data'] ?? statusResp['nurse'] ?? statusResp['user'] ?? statusResp;
        if (target is Map<String, dynamic>) {
          final user = NurseUser.fromJson(target);
          _syncUserToManager(user);
          return user;
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
      files['profileImage'] = profilePhoto;
      files['avatar'] = profilePhoto;
      files['photo'] = profilePhoto;
      files['profilePhoto'] = profilePhoto;
      files['image'] = profilePhoto;
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

    // Immediately cache and sync returned profile photo URL
    if (response is Map<String, dynamic>) {
      final data = response['profile'] ?? response['data'] ?? response['nurse'] ?? response;
      if (data is Map<String, dynamic>) {
        final rawImg = data['profileImage'] ?? data['profilePhoto'] ?? data['avatar'] ?? data['photo'] ?? data['image'];
        final imgUrl = rawImg is Map ? (rawImg['url'] ?? rawImg['key'])?.toString() : rawImg?.toString();
        if (imgUrl != null && imgUrl.isNotEmpty) {
          UserProfileManager.instance.setProfilePhotoUrl(imgUrl);
        }
      }
    }

    return true;
  }

  @override
  Future<KycDocumentsStatus> getDocumentsStatus() async {
    try {
      final response = await _client.get(ApiEndpoints.documents);
      if (response != null && response is Map<String, dynamic>) {
        final Map<String, dynamic> combined = {};
        if (response['documents'] is Map<String, dynamic>) {
          _safeMerge(combined, response['documents'] as Map<String, dynamic>);
        }
        if (response['data'] is Map<String, dynamic>) {
          final d = response['data'] as Map<String, dynamic>;
          if (d['documents'] is Map<String, dynamic>) {
            _safeMerge(combined, d['documents'] as Map<String, dynamic>);
          }
          _safeMerge(combined, d);
        }
        if (response['nurse'] is Map<String, dynamic>) {
          final n = response['nurse'] as Map<String, dynamic>;
          if (n['documents'] is Map<String, dynamic>) {
            _safeMerge(combined, n['documents'] as Map<String, dynamic>);
          }
          _safeMerge(combined, n);
        }
        if (response['user'] is Map<String, dynamic>) {
          final u = response['user'] as Map<String, dynamic>;
          if (u['documents'] is Map<String, dynamic>) {
            _safeMerge(combined, u['documents'] as Map<String, dynamic>);
          }
          _safeMerge(combined, u);
        }
        if (combined.isEmpty) {
          _safeMerge(combined, response);
        }
        return KycDocumentsStatus.fromJson(combined);
      }
    } catch (_) {}

    // Fallback: Check profile endpoint to see if documents are returned there
    try {
      final profileResp = await _client.get(ApiEndpoints.profile);
      if (profileResp != null && profileResp is Map<String, dynamic>) {
        final Map<String, dynamic> combined = {};
        if (profileResp['documents'] is Map<String, dynamic>) {
          _safeMerge(combined, profileResp['documents'] as Map<String, dynamic>);
        }
        if (profileResp['data'] is Map<String, dynamic>) {
          final d = profileResp['data'] as Map<String, dynamic>;
          if (d['documents'] is Map<String, dynamic>) {
            _safeMerge(combined, d['documents'] as Map<String, dynamic>);
          }
          _safeMerge(combined, d);
        }
        if (profileResp['nurse'] is Map<String, dynamic>) {
          final n = profileResp['nurse'] as Map<String, dynamic>;
          if (n['documents'] is Map<String, dynamic>) {
            _safeMerge(combined, n['documents'] as Map<String, dynamic>);
          }
          _safeMerge(combined, n);
        }
        if (combined.isNotEmpty) {
          return KycDocumentsStatus.fromJson(combined);
        }
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

    if (files.isEmpty) {
      return true;
    }

    final response = await _client.multipartRequest(
      method: 'POST',
      url: ApiEndpoints.documents,
      files: files,
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
            .map((item) => SpecializationItem.fromData(item))
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
