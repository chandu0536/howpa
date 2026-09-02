import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final AuthRepository authRepository;

  SplashCubit({required this.authRepository}) : super(SplashInitial());

  Future<void> initializeApp() async {
    emit(SplashLoading());
    await Future.delayed(const Duration(seconds: 3));
    // When authentication persistence is checked:
    emit(const SplashCompleted(isLoggedIn: false));
  }
}
