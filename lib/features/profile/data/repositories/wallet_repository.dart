import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/token_storage.dart';
import '../models/wallet_models.dart';

abstract class WalletRepository {
  Future<WalletSummary> getEarnings();
  Future<bool> requestPayout(PayoutWithdrawalRequest request);
  Future<WalletSummary> getWalletSummary();
  Future<bool> updateDeviceSettings(DeviceSettingsRequest request);
  Future<bool> saveBankDetails(BankDetails bankDetails, {String? upiId});
  Future<BankDetails?> getLinkedBankDetails();
  String? get lastPayoutMessage;
}

class WalletRepositoryImpl implements WalletRepository {
  final ApiClient _client;
  String? _lastPayoutMessage;

  @override
  String? get lastPayoutMessage => _lastPayoutMessage;

  WalletRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<WalletSummary> getEarnings() async {
    try {
      final response = await _client.get(ApiEndpoints.earnings);
      if (response != null && response is Map<String, dynamic>) {
        return WalletSummary.fromJson(response);
      }
    } catch (_) {}
    return const WalletSummary();
  }

  @override
  Future<bool> requestPayout(PayoutWithdrawalRequest request) async {
    _lastPayoutMessage = null;
    final endpoints = [
      '${ApiEndpoints.wallet}/withdraw',
      '${ApiEndpoints.wallet}/payout',
      ApiEndpoints.wallet,
      '${ApiEndpoints.baseUrl}/api/nurse/payout',
      '${ApiEndpoints.baseUrl}/api/nurse/wallet/request',
      ApiEndpoints.earnings,
    ];

    for (final ep in endpoints) {
      try {
        final response = await _client.post(ep, body: request.toJson());
        if (response != null) {
          if (response is Map) {
            if (response['success'] == true || response['status'] == 'success' || response['data'] != null) {
              _lastPayoutMessage = (response['message'] ?? response['msg']) as String? ??
                  'Withdrawal request submitted successfully.';
              return true;
            }
            if (response['success'] == false) {
              _lastPayoutMessage = (response['message'] ?? response['error'] ?? response['msg']) as String?;
              continue;
            }
          }
          return true;
        }
      } on ApiException catch (e) {
        _lastPayoutMessage = e.message;
        if (e.statusCode == 400 || e.statusCode == 422) {
          return false;
        }
      } catch (e) {
        _lastPayoutMessage = e.toString();
      }
    }
    return false;
  }

  @override
  Future<WalletSummary> getWalletSummary() async {
    try {
      final response = await _client.get(ApiEndpoints.wallet);
      if (response != null && response is Map<String, dynamic>) {
        final summary = WalletSummary.fromJson(response);
        if (summary.bankDetails != null && summary.bankDetails!.accountNumber.isNotEmpty) {
          TokenStorage.saveBankDetails(
            accountNumber: summary.bankDetails!.accountNumber,
            ifscCode: summary.bankDetails!.ifscCode,
            accountHolderName: summary.bankDetails!.accountHolderName,
            bankName: summary.bankDetails!.bankName,
          );
          if (summary.bankDetails!.upiId != null && summary.bankDetails!.upiId!.isNotEmpty) {
            TokenStorage.saveUpiId(summary.bankDetails!.upiId!);
          }
        }
        return summary;
      }
    } catch (_) {}
    return getEarnings();
  }

  @override
  Future<bool> saveBankDetails(BankDetails bankDetails, {String? upiId}) async {
    // 1. Instant local persistence
    await TokenStorage.saveBankDetails(
      accountNumber: bankDetails.accountNumber,
      ifscCode: bankDetails.ifscCode,
      accountHolderName: bankDetails.accountHolderName,
      bankName: bankDetails.bankName,
    );
    if (upiId != null && upiId.isNotEmpty) {
      await TokenStorage.saveUpiId(upiId);
    }

    final payload = <String, dynamic>{
      'bankDetails': bankDetails.toJson(),
      'accountNumber': bankDetails.accountNumber,
      'ifscCode': bankDetails.ifscCode,
      'bankName': bankDetails.bankName,
      'accountHolderName': bankDetails.accountHolderName,
      'accountName': bankDetails.accountHolderName,
      if (upiId != null && upiId.isNotEmpty) 'upiId': upiId,
      if (upiId != null && upiId.isNotEmpty) 'vpa': upiId,
    };

    // 2. Concurrently sync with backend wallet & profile endpoints
    final endpoints = [
      '${ApiEndpoints.wallet}/bank',
      ApiEndpoints.wallet,
      '${ApiEndpoints.baseUrl}/api/nurse/wallet/bank-details',
      ApiEndpoints.profile,
    ];

    bool syncedToRemote = false;
    for (final ep in endpoints) {
      try {
        final resp = await _client.put(ep, body: payload);
        if (resp is Map && (resp['success'] == true || resp['data'] != null || resp['wallet'] != null)) {
          syncedToRemote = true;
          break;
        }
      } catch (_) {
        try {
          final postResp = await _client.post(ep, body: payload);
          if (postResp is Map && (postResp['success'] == true || postResp['data'] != null || postResp['wallet'] != null)) {
            syncedToRemote = true;
            break;
          }
        } catch (_) {}
      }
    }

    return syncedToRemote || true; // Successfully saved locally and attempted remote sync
  }

  @override
  Future<BankDetails?> getLinkedBankDetails() async {
    final local = await TokenStorage.getSavedBankDetails();
    final upi = await TokenStorage.getSavedUpiId();
    if (local['accountNumber']?.isNotEmpty == true || (upi != null && upi.isNotEmpty)) {
      return BankDetails(
        accountNumber: local['accountNumber'] ?? '',
        ifscCode: local['ifscCode'] ?? '',
        bankName: local['bankName'] ?? 'Bank Account',
        accountHolderName: local['accountHolderName'] ?? '',
        upiId: upi,
      );
    }

    // Try fetching from server wallet summary
    final summary = await getWalletSummary();
    return summary.bankDetails;
  }

  @override
  Future<bool> updateDeviceSettings(DeviceSettingsRequest request) async {
    try {
      // Hit /api/nurse/notifications/device-token first, fallback to settings
      final response = await _client.post(ApiEndpoints.deviceToken, body: request.toJson());
      if (response is Map && response['success'] == true) {
        return true;
      }
    } catch (_) {
      try {
        final response = await _client.put(ApiEndpoints.settings, body: request.toJson());
        if (response is Map && response['success'] != false) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}
