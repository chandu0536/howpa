import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthOtpSent extends AuthState {
  final String phoneNumber;
  final String? message;
  final String? debugInfo;

  const AuthOtpSent({
    required this.phoneNumber,
    this.message,
    this.debugInfo,
  });

  @override
  List<Object?> get props => [phoneNumber, message, debugInfo];
}

class AuthAuthenticated extends AuthState {
  final String token;
  final UserModel? user;
  final String? nurseId;
  final bool isVerified;

  const AuthAuthenticated({
    required this.token,
    this.user,
    this.nurseId,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [token, user, nurseId, isVerified];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
