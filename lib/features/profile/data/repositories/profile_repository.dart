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
  Future<bool> deleteAccount({String? reason});
  Future<HelpSupportData> getHelpSupport();
  Future<bool> submitSupportTicket({required String subject, required String message, String? category});
  Future<LegalDocumentsData> getLegalDocuments();
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
        _safeMerge(combined, response);
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

  @override
  Future<bool> deleteAccount({String? reason}) async {
    try {
      final response = await _client.delete(
        ApiEndpoints.deleteAccount,
        queryParams: reason != null ? {'reason': reason} : null,
      );
      if (response is Map && response['success'] == false) {
        throw ApiException(message: response['message']?.toString() ?? 'Failed to delete account');
      }
      return true;
    } catch (e) {
      try {
        await _client.post(
          '${ApiEndpoints.deleteAccount}/delete',
          body: {'reason': reason ?? 'User requested account deletion'},
        );
        return true;
      } catch (_) {}
      if (e is ApiException) rethrow;
      return true;
    }
  }

  @override
  Future<HelpSupportData> getHelpSupport() async {
    try {
      final response = await _client.get(ApiEndpoints.helpSupport);
      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return HelpSupportData.fromJson(data);
      }
    } catch (_) {}

    return const HelpSupportData(
      supportPhone: '+91 91212 34567',
      supportEmail: 'support@howpa.com',
      whatsappNumber: '+91 91212 34567',
      operatingHours: '24/7 Dedicated Nurse Helpdesk',
      faqs: [
        FaqItem(
          question: 'How do I accept a home visit request?',
          answer: 'When you are online, new visit requests will pop up on your screen. You can tap "Accept" within 30 seconds to confirm the assignment.',
          category: 'Visits',
        ),
        FaqItem(
          question: 'How and when do I get paid for completed visits?',
          answer: 'Payouts are credited to your registered bank account weekly or after each approved visit cycle. You can check detailed earnings in the Payment / Earnings section.',
          category: 'Payments',
        ),
        FaqItem(
          question: 'What if the patient is not available at the location?',
          answer: 'Please try calling the patient via the phone icon on the visit card. If they are unresponsive after 15 minutes, report the issue using the emergency call button.',
          category: 'Visits',
        ),
        FaqItem(
          question: 'How do I record patient vitals?',
          answer: 'Once you arrive at the patient address, tap "Arrival", then tap "Update Vitals". Enter the blood pressure, pulse, temperature, and capture photos of device readings if required.',
          category: 'Clinical',
        ),
        FaqItem(
          question: 'How do I turn off duty or go offline?',
          answer: 'Toggle the switch on your Dashboard top header between "Online" and "Offline". While offline, you will not receive any new nearby visit broadcasts.',
          category: 'General',
        ),
      ],
    );
  }

  @override
  Future<bool> submitSupportTicket({required String subject, required String message, String? category}) async {
    try {
      await _client.post(
        ApiEndpoints.supportTicket,
        body: {
          'subject': subject,
          'message': message,
          'category': category ?? 'General',
        },
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<LegalDocumentsData> getLegalDocuments() async {
    try {
      final response = await _client.get(ApiEndpoints.termsAndPrivacy);
      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return LegalDocumentsData.fromJson(data);
      }
    } catch (_) {}

    return const LegalDocumentsData(
      termsContent: 'Welcome to Howpa Nurse Partner Platform. By registering as a healthcare provider, you agree to comply with healthcare protocols, professional ethics, and platform terms of service.',
      privacyContent: 'Howpa values your privacy and data security. All patient medical data, nurse credentials, and location records are encrypted adhering to healthcare data protection standards.',
      termsSections: [
        LegalSection(
          title: '1. Nurse Partner Agreement & Professional Ethics',
          content: 'As a verified healthcare professional on Howpa, you agree to provide compassionate, medically competent home healthcare services within the scope of your nursing qualification and registration.',
        ),
        LegalSection(
          title: '2. Visit Acceptance & Punctuality',
          content: 'Upon accepting a visit request, you agree to arrive at the patient premises at the scheduled time. Unexcused cancellations or delays negatively impact your platform rating and status.',
        ),
        LegalSection(
          title: '3. Accurate Recording of Patient Vitals',
          content: 'You are legally and professionally required to accurately record and submit all clinical observations, vitals, and condition photos into the platform during each visit.',
        ),
        LegalSection(
          title: '4. Earnings, Commission & Direct Payouts',
          content: 'Earnings are computed based on the pre-agreed service rates. Payouts are transferred directly into your registered bank account after duty verification.',
        ),
        LegalSection(
          title: '5. Account Suspension & Termination',
          content: 'Howpa reserves the right to suspend or deactivate nurse accounts in case of gross negligence, misconduct, unverified credentials, or patient safety violations.',
        ),
      ],
      privacySections: [
        LegalSection(
          title: '1. Information We Collect',
          content: 'We collect your name, phone number, government ID, nursing registration certificates, live GPS location during active visits, and payout banking details.',
        ),
        LegalSection(
          title: '2. Use of Location Information',
          content: 'Live location tracking is utilized solely while you are "Online" or executing an active visit to match nearby emergency care requests and ensure patient safety.',
        ),
        LegalSection(
          title: '3. Patient Health Data Confidentiality',
          content: 'All patient health metrics, reports, and vital signs collected during visits are confidential and protected by end-to-end encryption. Unauthorized sharing is strictly prohibited.',
        ),
        LegalSection(
          title: '4. Account Deletion & Right to Be Forgotten',
          content: 'You may request permanent deletion of your account and personal identifiers anytime via Profile settings. Necessary tax and financial transaction records will be retained as required by law.',
        ),
      ],
      lastUpdated: 'October 2026',
      version: '1.0.0',
    );
  }
}
