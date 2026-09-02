import 'earning_transaction_model.dart';

class WalletSummaryModel {
  final String walletBalance;
  final String todayEarnings;
  final String totalEarnings;
  final String weekEarnings;
  final String weekGrowthPercentage;
  final String monthEarnings;
  final String monthGrowthPercentage;
  final String pendingAmount;
  final List<EarningTransactionModel> recentEarnings;

  const WalletSummaryModel({
    required this.walletBalance,
    required this.todayEarnings,
    required this.totalEarnings,
    required this.weekEarnings,
    required this.weekGrowthPercentage,
    required this.monthEarnings,
    required this.monthGrowthPercentage,
    required this.pendingAmount,
    required this.recentEarnings,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    return WalletSummaryModel(
      walletBalance: json['walletBalance'] ?? '₹18,200',
      todayEarnings: json['todayEarnings'] ?? '₹3,200',
      totalEarnings: json['totalEarnings'] ?? '₹24,580',
      weekEarnings: json['weekEarnings'] ?? '₹8.4k',
      weekGrowthPercentage: json['weekGrowthPercentage'] ?? '12%',
      monthEarnings: json['monthEarnings'] ?? '₹42k',
      monthGrowthPercentage: json['monthGrowthPercentage'] ?? '08%',
      pendingAmount: json['pendingAmount'] ?? '₹1,500',
      recentEarnings: (json['recentEarnings'] as List<dynamic>?)
              ?.map((e) => EarningTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletBalance': walletBalance,
      'todayEarnings': todayEarnings,
      'totalEarnings': totalEarnings,
      'weekEarnings': weekEarnings,
      'weekGrowthPercentage': weekGrowthPercentage,
      'monthEarnings': monthEarnings,
      'monthGrowthPercentage': monthGrowthPercentage,
      'pendingAmount': pendingAmount,
      'recentEarnings': recentEarnings.map((e) => e.toJson()).toList(),
    };
  }

  static WalletSummaryModel empty() {
    return const WalletSummaryModel(
      walletBalance: '₹0',
      todayEarnings: '₹0',
      totalEarnings: '₹0',
      weekEarnings: '₹0',
      weekGrowthPercentage: '0%',
      monthEarnings: '₹0',
      monthGrowthPercentage: '0%',
      pendingAmount: '₹0',
      recentEarnings: [],
    );
  }

  static WalletSummaryModel mock() {
    return const WalletSummaryModel(
      walletBalance: '₹18,200',
      todayEarnings: '₹3,200',
      totalEarnings: '₹24,580',
      weekEarnings: '₹8.4k',
      weekGrowthPercentage: '12%',
      monthEarnings: '₹42k',
      monthGrowthPercentage: '08%',
      pendingAmount: '₹1,500',
      recentEarnings: [
        EarningTransactionModel(
          id: '1',
          initials: 'AP',
          initialsBgColorValue: 0xFFF3E8FF,
          initialsTextColorValue: 0xFF7E22CE,
          title: 'Wound Dressing — Mrs. Anjali Patel',
          date: '30 Jun 2025  •  11:00 AM',
          amount: '+₹500',
          status: 'Paid',
          isPaid: true,
        ),
        EarningTransactionModel(
          id: '2',
          initials: 'SV',
          initialsBgColorValue: 0xFFDCFCE7,
          initialsTextColorValue: 0xFF15803D,
          title: 'IV Drip — Mr. Suresh Verma',
          date: '29 Jun 2025  •  04:45 PM',
          amount: '+₹650',
          status: 'Paid',
          isPaid: true,
        ),
        EarningTransactionModel(
          id: '3',
          initials: 'NP',
          initialsBgColorValue: 0xFFFFEDD5,
          initialsTextColorValue: 0xFFC2410C,
          title: 'Elder Care Visit — Mrs. Nirmala',
          date: '28 Jun 2025  •  09:30 AM',
          amount: '+₹400',
          status: 'Pending',
          isPaid: false,
        ),
      ],
    );
  }
}
