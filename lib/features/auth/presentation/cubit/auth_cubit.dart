import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  Future<void> sendOtp(String phoneNumber) async {
    emit(const AuthLoading(message: 'Sending OTP...'));
    try {
      final res = await authRepository.sendOtp(phoneNumber);
      if (res.success) {
        emit(AuthOtpSent(
          phoneNumber: phoneNumber,
          message: res.message,
          debugInfo: res.debugInfo,
        ));
      } else {
        emit(AuthError(res.message.isNotEmpty ? res.message : 'Failed to send OTP'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    emit(const AuthLoading(message: 'Verifying OTP...'));
    try {
      final res = await authRepository.verifyOtp(phoneNumber, otp);
      if (res.success && res.token != null) {
        emit(AuthAuthenticated(
          token: res.token!,
          user: res.user,
          nurseId: res.user?.id,
          isVerified: res.user?.approvalStatus == 'APPROVED',
        ));
      } else {
        emit(AuthError(res.message.isNotEmpty ? res.message : 'Invalid OTP'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void logout() {
    emit(AuthUnauthenticated());
  }
}
