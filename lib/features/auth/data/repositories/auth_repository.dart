import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/user_profile_manager.dart';
import '../../../profile/data/models/nurse_profile_model.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  /// Sends OTP to the given mobile number
  Future<SendOtpResponse> sendOtp(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final tenDigitMobile =
        cleanMobile.length > 10 ? cleanMobile.substring(cleanMobile.length - 10) : cleanMobile;

    try {
      final response = await apiClient.post(
        ApiEndpoints.sendOtp,
        body: SendOtpRequest(mobile: tenDigitMobile).toJson(),
      );
      if (response != null && response is Map<String, dynamic>) {
        return SendOtpResponse.fromJson(response);
      }
      return const SendOtpResponse(
        success: true,
        message: 'Nurse OTP sent successfully',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Verifies OTP with FCM token and device type
  Future<VerifyOtpResponse> verifyOtp(
    String mobile,
    String otp, {
    String? fcmToken,
    String? deviceType,
  }) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    final tenDigitMobile =
        cleanMobile.length > 10 ? cleanMobile.substring(cleanMobile.length - 10) : cleanMobile;

    final resolvedDeviceType =
        deviceType ?? (Platform.isIOS ? 'ios' : 'android');

    // Dynamically retrieve the real device FCM token from Firebase SDK on the frontend
    String? liveFcmToken = fcmToken ?? NotificationService.instance.fcmToken;
    if (liveFcmToken == null || liveFcmToken.isEmpty) {
      liveFcmToken = await NotificationService.instance.getDeviceFcmToken();
    }
    final resolvedFcmToken = (liveFcmToken != null && liveFcmToken.isNotEmpty)
        ? liveFcmToken
        : 'fcm_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await apiClient.post(
        ApiEndpoints.verifyOtp,
        body: VerifyOtpRequest(
          mobile: tenDigitMobile,
          otp: otp,
          fcmToken: resolvedFcmToken,
          deviceType: resolvedDeviceType,
        ).toJson(),
      );

      if (response != null && response is Map<String, dynamic>) {
        final result = VerifyOtpResponse.fromJson(response);
        if (result.token != null && result.token!.isNotEmpty) {
          apiClient.setAuthToken(result.token!);
        }

        // Sync details to central UserProfileManager
        if (result.rawProfile != null) {
          final p = result.rawProfile!;
          UserProfileManager.instance.updateProfileDetails(
            fullName: p['fullName']?.toString(),
            phoneNumber: result.user?.mobile ?? tenDigitMobile,
            email: p['email']?.toString(),
            dob: p['dob']?.toString(),
            gender: p['gender']?.toString(),
            experience: p['experienceYears']?.toString() ?? p['experience']?.toString(),
            specialization: p['specialization']?.toString(),
            country: p['country']?.toString(),
            state: p['state']?.toString(),
            district: p['district']?.toString() ?? p['city']?.toString(),
            area: p['address']?.toString() ?? p['area']?.toString(),
            location: p['address']?.toString() ?? p['location']?.toString(),
            profileImageUrl: p['profileImage']?.toString(),
            approvalStatus: result.user?.approvalStatus,
            isVerified: result.user?.isVerified,
            nurseCode: result.user?.nurseCode,
            profileStatus: result.user?.profileStatus,
          );
        } else if (result.user != null) {
          UserProfileManager.instance.updateProfileDetails(
            phoneNumber: result.user!.mobile,
            approvalStatus: result.user!.approvalStatus,
            isVerified: result.user!.isVerified,
            nurseCode: result.user!.nurseCode,
            profileStatus: result.user!.profileStatus,
          );
        }

        return result;
      }
      throw ApiException('Unexpected server response');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<AuthResponseModel> registerNurse(RegistrationRequest request) async {
    try {
      final response = await apiClient.multipartPut(
        ApiEndpoints.profile,
        fields: request.toFormDataFields(),
      );
      if (response != null && response is Map<String, dynamic>) {
        return AuthResponseModel.fromJson(response);
      }
      return const AuthResponseModel(success: true, message: 'Registration submitted successfully');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<bool> checkVerificationStatus() async {
    try {
      final profile = await getVerificationProfile();
      return profile?.isApproved ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the real-time Nurse Profile & Approval status from GET /api/nurse/profile
  Future<NurseProfileModel?> getVerificationProfile() async {
    try {
      final response = await apiClient.get(ApiEndpoints.profile);
      if (response != null && response is Map<String, dynamic>) {
        final profile = NurseProfileModel.fromJson(response);
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
        return profile;
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}

