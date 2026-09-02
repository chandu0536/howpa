import 'package:equatable/equatable.dart';
import '../../data/models/wallet_summary_model.dart';

abstract class PaymentEarningsState extends Equatable {
  const PaymentEarningsState();

  @override
  List<Object?> get props => [];
}

class PaymentEarningsInitial extends PaymentEarningsState {}

class PaymentEarningsLoading extends PaymentEarningsState {}

class PaymentEarningsLoaded extends PaymentEarningsState {
  final WalletSummaryModel walletSummary;
  final bool isWithdrawing;
  final String? withdrawSuccessMessage;

  const PaymentEarningsLoaded({
    required this.walletSummary,
    this.isWithdrawing = false,
    this.withdrawSuccessMessage,
  });

  PaymentEarningsLoaded copyWith({
    WalletSummaryModel? walletSummary,
    bool? isWithdrawing,
    String? withdrawSuccessMessage,
  }) {
    return PaymentEarningsLoaded(
      walletSummary: walletSummary ?? this.walletSummary,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      withdrawSuccessMessage: withdrawSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [walletSummary, isWithdrawing, withdrawSuccessMessage];
}

class PaymentEarningsError extends PaymentEarningsState {
  final String message;

  const PaymentEarningsError(this.message);

  @override
  List<Object?> get props => [message];
}
