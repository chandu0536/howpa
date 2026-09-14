import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl(),
        super(LoginInitial());

  Future<void> sendOtp(String phoneNumber) async {
    emit(LoginLoading());
    try {
      final success = await _authRepository.sendOtp(phoneNumber);
      if (success) {
        emit(LoginOtpSent(phoneNumber));
      } else {
        emit(const LoginFailure('Failed to send OTP'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    emit(LoginLoading());
    try {
      final request = VerifyOtpRequest(
        phone: phoneNumber,
        otp: otp,
        deviceType: 'android',
      );
      final response = await _authRepository.verifyOtp(request);
      if (response.success) {
        emit(LoginSuccess());
      } else {
        emit(LoginFailure(response.message ?? 'Invalid OTP'));
      }
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
