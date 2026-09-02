import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashCompleted extends SplashState {
  final bool isLoggedIn;
  final bool isVerified;

  const SplashCompleted({
    this.isLoggedIn = false,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [isLoggedIn, isVerified];
}
