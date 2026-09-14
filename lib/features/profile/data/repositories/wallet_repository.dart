import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/wallet_models.dart';

abstract class WalletRepository {
  Future<WalletSummary> getEarnings();
  Future<bool> requestPayout(PayoutWithdrawalRequest request);
  Future<WalletSummary> getWalletSummary();
  Future<bool> updateDeviceSettings(DeviceSettingsRequest request);
}

class WalletRepositoryImpl implements WalletRepository {
  final ApiClient _client;

  WalletRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<WalletSummary> getEarnings() async {
    try {
      final response = await _client.get(ApiEndpoints.earnings);
      if (response != null && response['data'] != null) {
        return WalletSummary.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return const WalletSummary();
  }

  @override
  Future<bool> requestPayout(PayoutWithdrawalRequest request) async {
    try {
      final response = await _client.post(ApiEndpoints.earnings, body: request.toJson());
      if (response is Map && response['success'] == false) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<WalletSummary> getWalletSummary() async {
    try {
      final response = await _client.get(ApiEndpoints.wallet);
      if (response != null && response['data'] != null) {
        return WalletSummary.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return const WalletSummary();
  }

  @override
  Future<bool> updateDeviceSettings(DeviceSettingsRequest request) async {
    try {
      final response = await _client.put(ApiEndpoints.settings, body: request.toJson());
      if (response is Map && response['success'] == false) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
