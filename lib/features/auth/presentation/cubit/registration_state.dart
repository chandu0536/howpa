import 'package:equatable/equatable.dart';
import '../../../../features/profile/data/models/specialization_model.dart';

abstract class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

class RegistrationInitial extends RegistrationState {}

class RegistrationSubmitting extends RegistrationState {}

class SpecializationsLoaded extends RegistrationState {
  final List<SpecializationModel> specializations;
  const SpecializationsLoaded(this.specializations);

  @override
  List<Object?> get props => [specializations];
}

class RegistrationSuccess extends RegistrationState {
  final String message;
  const RegistrationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class RegistrationDocumentsSuccess extends RegistrationState {
  final String message;
  const RegistrationDocumentsSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class RegistrationError extends RegistrationState {
  final String message;
  const RegistrationError(this.message);

  @override
  List<Object?> get props => [message];
}

