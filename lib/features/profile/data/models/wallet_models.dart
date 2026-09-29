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
        'accountName': accountHolderName,
        'accountHolderName': accountHolderName,
      };

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountNumber: json['accountNumber'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountHolderName: json['accountName'] as String? ?? json['accountHolderName'] as String? ?? '',
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
    final wallet = json['wallet'] is Map<String, dynamic>
        ? json['wallet'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json);
    final analytics = json['analytics'] is Map<String, dynamic> ? json['analytics'] as Map<String, dynamic> : null;

    final balance = (wallet['availableBalance'] as num?)?.toDouble() ??
        (wallet['walletBalance'] as num?)?.toDouble() ??
        (wallet['totalBalance'] as num?)?.toDouble() ??
        (analytics?['availableBalance'] as num?)?.toDouble() ??
        0.0;

    final todayOrWeekEarnings = (wallet['todayEarnings'] as num?)?.toDouble() ??
        (analytics?['todayEarnings'] as num?)?.toDouble() ??
        (wallet['thisWeekEarnings'] as num?)?.toDouble() ??
        0.0;

    final pending = (wallet['pendingSettlement'] as num?)?.toDouble() ??
        (wallet['pendingWithdrawals'] as num?)?.toDouble() ??
        0.0;

    final withdrawn = (wallet['totalWithdrawn'] as num?)?.toDouble() ??
        (wallet['withdrawn'] as num?)?.toDouble() ??
        0.0;

    return WalletSummary(
      totalBalance: balance,
      thisWeekEarnings: todayOrWeekEarnings,
      pendingWithdrawals: pending,
      totalWithdrawn: withdrawn,
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
        'token': deviceToken,
        'deviceType': deviceType,
        'platform': deviceType.toUpperCase(),
      };
}
