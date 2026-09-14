class BankDetails {
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String accountHolderName;

  const BankDetails({
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.accountHolderName,
  });

  Map<String, dynamic> toJson() => {
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
      };

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountNumber: json['accountNumber'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountHolderName: json['accountHolderName'] as String? ?? '',
    );
  }
}

class PayoutWithdrawalRequest {
  final double amount;
  final BankDetails bankDetails;

  const PayoutWithdrawalRequest({
    required this.amount,
    required this.bankDetails,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'bankDetails': bankDetails.toJson(),
      };
}

class WalletSummary {
  final double totalBalance;
  final double thisWeekEarnings;
  final double pendingWithdrawals;
  final double totalWithdrawn;

  const WalletSummary({
    this.totalBalance = 0.0,
    this.thisWeekEarnings = 0.0,
    this.pendingWithdrawals = 0.0,
    this.totalWithdrawn = 0.0,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
      thisWeekEarnings: (json['thisWeekEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingWithdrawals: (json['pendingWithdrawals'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DeviceSettingsRequest {
  final String deviceToken;
  final String deviceType;

  const DeviceSettingsRequest({
    required this.deviceToken,
    this.deviceType = 'android',
  });

  Map<String, dynamic> toJson() => {
        'deviceToken': deviceToken,
        'deviceType': deviceType,
      };
}
