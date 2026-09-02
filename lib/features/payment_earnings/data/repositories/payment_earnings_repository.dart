import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/earning_transaction_model.dart';
import '../models/wallet_summary_model.dart';

class PaymentEarningsRepository {
  final ApiClient apiClient;

  PaymentEarningsRepository({required this.apiClient});

  /// Fetch Nurse Earnings Ledger: GET /api/nurse/earnings
  Future<List<EarningTransactionModel>> getEarningsLedger() async {
    try {
      final response = await apiClient.get(ApiEndpoints.earnings);
      if (response != null && response is Map<String, dynamic>) {
        final list = response['data'] ?? response['earnings'] ?? response['ledger'] ?? response['transactions'];
        if (list is List) {
          return list.map((e) => EarningTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      } else if (response != null && response is List) {
        return response.map((e) => EarningTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Request Payout Withdrawal: POST /api/nurse/earnings
  Future<bool> requestWithdrawal(double amount) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.earnings,
        body: {'amount': amount},
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Fetch Wallet Info: GET /api/nurse/wallet
  Future<WalletSummaryModel> getEarningsSummary() async {
    try {
      final walletResponse = await apiClient.get(ApiEndpoints.wallet);
      final ledgerList = await getEarningsLedger();

      if (walletResponse != null && walletResponse is Map<String, dynamic>) {
        final walletData = walletResponse['wallet'] is Map<String, dynamic>
            ? walletResponse['wallet'] as Map<String, dynamic>
            : (walletResponse['data'] is Map<String, dynamic>
                ? walletResponse['data'] as Map<String, dynamic>
                : walletResponse);

        final rawBal = walletData['availableBalance'] ?? walletData['balance'] ?? walletData['walletBalance'];
        String formattedBal = '₹0';
        if (rawBal is num) {
          formattedBal = '₹${rawBal.toStringAsFixed(0)}';
        } else if (rawBal != null && rawBal.toString().isNotEmpty) {
          formattedBal = rawBal.toString().startsWith('₹') ? rawBal.toString() : '₹$rawBal';
        }

        final rawPending = walletData['pendingSettlement'] ?? walletData['pendingAmount'] ?? '0';
        String formattedPending = '₹0';
        if (rawPending is num) {
          formattedPending = '₹${rawPending.toStringAsFixed(0)}';
        } else if (rawPending.toString().isNotEmpty) {
          formattedPending = rawPending.toString().startsWith('₹') ? rawPending.toString() : '₹$rawPending';
        }

        final rawToday = walletData['todayEarnings'] ?? '0';
        String formattedToday = '₹0';
        if (rawToday is num) {
          formattedToday = '₹${rawToday.toStringAsFixed(0)}';
        } else if (rawToday.toString().isNotEmpty) {
          formattedToday = rawToday.toString().startsWith('₹') ? rawToday.toString() : '₹$rawToday';
        }

        final rawTotal = walletData['totalEarnings'] ?? '0';
        String formattedTotal = '₹0';
        if (rawTotal is num) {
          formattedTotal = '₹${rawTotal.toStringAsFixed(0)}';
        } else if (rawTotal.toString().isNotEmpty) {
          formattedTotal = rawTotal.toString().startsWith('₹') ? rawTotal.toString() : '₹$rawTotal';
        }

        return WalletSummaryModel(
          walletBalance: formattedBal,
          todayEarnings: formattedToday,
          totalEarnings: formattedTotal,
          weekEarnings: walletData['weekEarnings']?.toString() ?? formattedToday,
          weekGrowthPercentage: walletData['weekGrowthPercentage']?.toString() ?? '0%',
          monthEarnings: walletData['monthEarnings']?.toString() ?? formattedTotal,
          monthGrowthPercentage: walletData['monthGrowthPercentage']?.toString() ?? '0%',
          pendingAmount: formattedPending,
          recentEarnings: ledgerList,
        );
      }
      return WalletSummaryModel.empty();
    } catch (_) {
      return WalletSummaryModel.empty();
    }
  }
}

