import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/payment_earnings_repository.dart';
import 'payment_earnings_state.dart';

class PaymentEarningsCubit extends Cubit<PaymentEarningsState> {
  final PaymentEarningsRepository repository;

  PaymentEarningsCubit({required this.repository}) : super(PaymentEarningsInitial());

  Future<void> fetchEarningsSummary() async {
    emit(PaymentEarningsLoading());
    try {
      final summary = await repository.getEarningsSummary();
      emit(PaymentEarningsLoaded(walletSummary: summary));
    } catch (e) {
      emit(PaymentEarningsError(e.toString()));
    }
  }

  Future<void> requestWithdrawal(double amount) async {
    if (state is! PaymentEarningsLoaded) return;
    final currentState = state as PaymentEarningsLoaded;
    emit(currentState.copyWith(isWithdrawing: true));
    try {
      final success = await repository.requestWithdrawal(amount);
      if (success) {
        emit(currentState.copyWith(
          isWithdrawing: false,
          withdrawSuccessMessage: 'Withdrawal request submitted successfully!',
        ));
      } else {
        emit(currentState.copyWith(isWithdrawing: false));
      }
    } catch (e) {
      emit(currentState.copyWith(isWithdrawing: false));
    }
  }
}
