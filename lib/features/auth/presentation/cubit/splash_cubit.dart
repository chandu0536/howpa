import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> initSplash() async {
    emit(SplashLoading());
    await Future.delayed(const Duration(seconds: 2));
    emit(SplashNavigateToOnboarding());
  }
}
