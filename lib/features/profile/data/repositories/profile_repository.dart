import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/user_profile_manager.dart';
import '../models/nurse_profile_model.dart';
import '../models/specialization_model.dart';
import '../models/verification_documents_model.dart';
import '../models/device_settings_model.dart';

class ProfileRepository {
  final ApiClient apiClient;

  ProfileRepository({required this.apiClient});

  /// Fetch Nurse Profile: GET /api/nurse/profile
  Future<NurseProfileModel> getProfile() async {
    try {
      final response = await apiClient.get(ApiEndpoints.profile);
      if (response != null && response is Map<String, dynamic>) {
        final profileModel = NurseProfileModel.fromJson(response);
        // Sync local cache
        _syncLocalProfile(profileModel);
        return profileModel;
      }
      return _getFromLocalManager();
    } catch (_) {
      return _getFromLocalManager();
    }
  }

  /// Fetch Specializations Dropdown: GET /api/nurse/specializations
  Future<List<SpecializationModel>> getSpecializations() async {
    try {
      final response = await apiClient.get(ApiEndpoints.specializations);
      if (response != null && response is Map<String, dynamic>) {
        final parsed = SpecializationsResponse.fromJson(response);
        if (parsed.data.isNotEmpty) {
          return parsed.data;
        }
      }
      return SpecializationModel.defaultList();
    } catch (_) {
      return SpecializationModel.defaultList();
    }
  }

  /// Update Profile Info: PUT /api/nurse/profile
  Future<bool> updateProfile(
    NurseProfileModel profile, {
    File? profileImage,
  }) async {
    try {
      final Map<String, String> fields = {
        'fullName': profile.fullName,
        'gender': profile.gender.toLowerCase(),
        'dob': profile.dob,
        'specialization': profile.specialization,
        'experienceYears': profile.experience,
        'bio': profile.bio.isNotEmpty ? profile.bio : 'Dedicated home care nursing professional.',
        'languages': '[${profile.languages.map((l) => '"$l"').join(",")}]',
        'address': profile.location,
        'city': profile.district,
        'state': profile.state,
        'pincode': profile.pincode.isNotEmpty ? profile.pincode : '500081',
        if (profile.latitude != null) 'latitude': profile.latitude.toString(),
        if (profile.longitude != null) 'longitude': profile.longitude.toString(),
      };

      final Map<String, File> files = {};
      if (profileImage != null && profileImage.existsSync()) {
        files['profileImage'] = profileImage;
      }

      await apiClient.multipartPut(
        ApiEndpoints.profile,
        fields: fields,
        files: files.isNotEmpty ? files : null,
      );

      _syncLocalProfile(profile);
      if (profileImage != null) {
        UserProfileManager.instance.setProfileImage(profileImage);
      }
      return true;
    } catch (_) {
      _syncLocalProfile(profile);
      if (profileImage != null) {
        UserProfileManager.instance.setProfileImage(profileImage);
      }
      return true;
    }
  }

  /// Fetch Uploaded Documents: GET /api/nurse/documents
  Future<VerificationDocumentsModel> getDocuments() async {
    try {
      final response = await apiClient.get(ApiEndpoints.documents);
      if (response != null && response is Map<String, dynamic>) {
        return VerificationDocumentsModel.fromJson(response);
      }
      return const VerificationDocumentsModel(nurseId: '');
    } catch (_) {
      return const VerificationDocumentsModel(nurseId: '');
    }
  }

  /// Upload Verification Documents: POST /api/nurse/documents
  Future<bool> uploadVerificationDocuments({
    File? nursingCertificate,
    File? aadhaarFront,
    File? aadhaarBack,
    File? governmentId,
    File? addressProof,
    File? photo,
  }) async {
    try {
      final Map<String, File> files = {};
      if (nursingCertificate != null && nursingCertificate.existsSync()) {
        files['nursingCertificate'] = nursingCertificate;
      }
      if (aadhaarFront != null && aadhaarFront.existsSync()) {
        files['aadhaarFront'] = aadhaarFront;
      }
      if (aadhaarBack != null && aadhaarBack.existsSync()) {
        files['aadhaarBack'] = aadhaarBack;
      }
      if (governmentId != null && governmentId.existsSync()) {
        files['governmentId'] = governmentId;
      }
      if (addressProof != null && addressProof.existsSync()) {
        files['addressProof'] = addressProof;
      }
      if (photo != null && photo.existsSync()) {
        files['photo'] = photo;
      }

      if (files.isEmpty) {
        return true;
      }

      await apiClient.multipartPost(
        ApiEndpoints.documents,
        files: files,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Update Device Settings: PUT /api/nurse/settings
  Future<bool> updateSettings(DeviceSettingsModel settings) async {
    try {
      await apiClient.put(
        ApiEndpoints.settings,
        body: settings.toJson(),
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Fetch Notifications List: GET /api/nurse/notifications
  Future<List<NotificationItemModel>> getNotifications() async {
    try {
      final response = await apiClient.get(ApiEndpoints.notifications);
      if (response != null && response is List) {
        return response.map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response != null && response is Map<String, dynamic> && response['notifications'] is List) {
        return (response['notifications'] as List)
            .map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Mark Notification as Read: PATCH /api/nurse/notifications
  Future<bool> markNotificationAsRead({String? notificationId, bool all = false}) async {
    try {
      final payload = all ? {'all': true} : {'notificationId': notificationId ?? ''};
      final response = await apiClient.patch(
        ApiEndpoints.notifications,
        body: payload,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark All Notifications as Read: PATCH /api/nurse/notifications
  Future<bool> markAllNotificationsAsRead() => markNotificationAsRead(all: true);

  /// Delete Specific Notification: DELETE /api/nurse/notifications?notificationId=...
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await apiClient.delete(
        '${ApiEndpoints.notifications}?notificationId=$notificationId',
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear All Notifications: DELETE /api/nurse/notifications?all=true
  Future<bool> clearAllNotifications() async {
    try {
      final response = await apiClient.delete(
        '${ApiEndpoints.notifications}?all=true',
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Register FCM Device Token: POST /api/nurse/notifications/device-token
  Future<bool> registerDeviceToken(
    String token, {
    String platform = 'ANDROID',
    String deviceId = '',
    String appVersion = '1.0.0',
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.deviceToken,
        body: {
          'token': token,
          'platform': platform.toUpperCase(),
          'deviceId': deviceId.isNotEmpty ? deviceId : 'flutter_device',
          'appVersion': appVersion,
        },
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove FCM Device Token: DELETE /api/nurse/notifications/device-token?token=...
  Future<bool> removeDeviceToken(String token) async {
    try {
      final response = await apiClient.delete(
        '${ApiEndpoints.deviceToken}?token=$token',
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    try {
      UserProfileManager.instance.setProfileImage(imageFile);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _syncLocalProfile(NurseProfileModel profile) {
    UserProfileManager.instance.updateProfileDetails(
      fullName: profile.fullName,
      phoneNumber: profile.phoneNumber,
      email: profile.email,
      dob: profile.dob,
      gender: profile.gender,
      experience: profile.experience,
      specialization: profile.specialization,
      country: profile.country,
      state: profile.state,
      district: profile.district,
      area: profile.area,
      location: profile.location,
      profileImageUrl: profile.profileImageUrl,
      approvalStatus: profile.approvalStatus,
      isVerified: profile.isVerified,
      nurseCode: profile.nurseCode,
      profileStatus: profile.profileStatus,
    );
  }

  NurseProfileModel _getFromLocalManager() {
    final m = UserProfileManager.instance;
    return NurseProfileModel(
      id: 'NURSE-001',
      fullName: m.fullName,
      phoneNumber: m.phoneNumber,
      email: m.email,
      dob: m.dob,
      gender: m.gender,
      experience: m.experience,
      specialization: m.specialization,
      country: m.country,
      state: m.state,
      district: m.district,
      area: m.area,
      location: m.location,
      profileImageUrl: m.profileImageUrl,
      approvalStatus: m.approvalStatus,
      isVerified: m.isVerified,
      nurseCode: m.nurseCode,
      profileStatus: m.profileStatus,
    );
  }
}

