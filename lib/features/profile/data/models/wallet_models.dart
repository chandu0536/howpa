class BankDetails {
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String accountHolderName;
  final String? upiId;

  const BankDetails({
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.accountHolderName,
    this.upiId,
  });

  Map<String, dynamic> toJson() => {
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankName': bankName,
        'accountName': accountHolderName,
        'accountHolderName': accountHolderName,
        if (upiId != null && upiId!.isNotEmpty) 'upiId': upiId,
      };

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountNumber: json['accountNumber'] as String? ?? json['account_number'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? json['ifsc'] as String? ?? '',
      bankName: json['bankName'] as String? ?? json['bank_name'] as String? ?? '',
      accountHolderName: json['accountName'] as String? ??
          json['accountHolderName'] as String? ??
          json['account_holder_name'] as String? ??
          json['beneficiaryName'] as String? ??
          '',
      upiId: json['upiId'] as String? ?? json['upi_id'] as String? ?? json['vpa'] as String?,
    );
  }
}

class PayoutWithdrawalRequest {
  final double amount;
  final String paymentMethod; // 'BANK' or 'UPI'
  final BankDetails? bankDetails;
  final String? upiId;
  final String? notes;

  const PayoutWithdrawalRequest({
    required this.amount,
    this.paymentMethod = 'BANK',
    this.bankDetails,
    this.upiId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'payoutAmount': amount,
        'withdrawalAmount': amount,
        'paymentMethod': paymentMethod,
        'method': paymentMethod,
        if (upiId != null && upiId!.isNotEmpty) 'upiId': upiId,
        if (upiId != null && upiId!.isNotEmpty) 'vpa': upiId,
        if (bankDetails != null) ...{
          'bankDetails': bankDetails!.toJson(),
          'accountNumber': bankDetails!.accountNumber,
          'ifscCode': bankDetails!.ifscCode,
          'bankName': bankDetails!.bankName,
          'accountHolderName': bankDetails!.accountHolderName,
          'accountName': bankDetails!.accountHolderName,
        },
        if (notes != null) 'notes': notes,
      };
}

class WalletSummary {
  final double totalBalance;
  final double thisWeekEarnings;
  final double pendingWithdrawals;
  final double totalWithdrawn;
  final BankDetails? bankDetails;

  const WalletSummary({
    this.totalBalance = 0.0,
    this.thisWeekEarnings = 0.0,
    this.pendingWithdrawals = 0.0,
    this.totalWithdrawn = 0.0,
    this.bankDetails,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] is Map<String, dynamic>
        ? json['wallet'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json);
    final analytics = json['analytics'] is Map<String, dynamic> ? json['analytics'] as Map<String, dynamic> : null;

    final balance = (wallet['availableBalance'] as num?)?.toDouble() ??
        (wallet['walletBalance'] as num?)?.toDouble() ??
        (wallet['totalBalance'] as num?)?.toDouble() ??
        (wallet['totalEarnings'] as num?)?.toDouble() ??
        (analytics?['availableBalance'] as num?)?.toDouble() ??
        0.0;

    final todayOrWeekEarnings = (wallet['weeklyEarnings'] as num?)?.toDouble() ??
        (wallet['thisWeekEarnings'] as num?)?.toDouble() ??
        (analytics?['weeklyEarnings'] as num?)?.toDouble() ??
        (wallet['todayEarnings'] as num?)?.toDouble() ??
        (analytics?['todayEarnings'] as num?)?.toDouble() ??
        0.0;

    final pending = (wallet['pendingSettlement'] as num?)?.toDouble() ??
        (wallet['pendingWithdrawals'] as num?)?.toDouble() ??
        0.0;

    final withdrawn = (wallet['totalWithdrawn'] as num?)?.toDouble() ??
        (wallet['withdrawn'] as num?)?.toDouble() ??
        0.0;

    BankDetails? bank;
    final rawBank = wallet['bankDetails'] ?? json['bankDetails'] ?? wallet['bank'];
    if (rawBank is Map<String, dynamic>) {
      final acc = rawBank['accountNumber'] ?? rawBank['account_number'] ?? rawBank['accNo'];
      final name = rawBank['accountName'] ?? rawBank['accountHolderName'] ?? rawBank['holderName'];
      if ((acc != null && acc.toString().isNotEmpty) || (name != null && name.toString().isNotEmpty)) {
        bank = BankDetails.fromJson(rawBank);
      }
    }

    return WalletSummary(
      totalBalance: balance,
      thisWeekEarnings: todayOrWeekEarnings,
      pendingWithdrawals: pending,
      totalWithdrawn: withdrawn,
      bankDetails: bank,
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
