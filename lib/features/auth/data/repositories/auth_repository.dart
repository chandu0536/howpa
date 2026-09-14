import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/token_storage.dart';
import '../models/auth_models.dart';

abstract class AuthRepository {
  Future<bool> sendOtp(String phone);
  Future<AuthResponse> verifyOtp(VerifyOtpRequest request);
  Future<bool> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _client;

  AuthRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<bool> sendOtp(String phone) async {
    final request = SendOtpRequest(phone: phone);
    final response = await _client.post(
      ApiEndpoints.sendOtp,
      body: request.toJson(),
      requiresAuth: false,
    );

    if (response is Map) {
      if (response['success'] == false) {
        throw ApiException(
          message: response['message'] as String? ?? 'Failed to send OTP. Please try again.',
        );
      }
    }
    return true;
  }

  @override
  Future<AuthResponse> verifyOtp(VerifyOtpRequest request) async {
    final response = await _client.post(
      ApiEndpoints.verifyOtp,
      body: request.toJson(),
      requiresAuth: false,
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid response from server.');
    }

    final authResponse = AuthResponse.fromJson(response);

    if (!authResponse.success || authResponse.token.isEmpty) {
      throw ApiException(
        message: authResponse.message ?? 'Invalid OTP entered. Please try again.',
      );
    }

    await TokenStorage.saveToken(authResponse.token);
    await TokenStorage.savePhone(request.phone);

    return authResponse;
  }

  @override
  Future<bool> logout() async {
    try {
      await _client.delete(ApiEndpoints.deviceToken);
    } catch (_) {}
    await TokenStorage.clear();
    return true;
  }
}
