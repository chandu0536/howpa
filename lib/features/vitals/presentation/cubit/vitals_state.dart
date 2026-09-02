import 'package:equatable/equatable.dart';
import '../../data/models/vitals_model.dart';

abstract class VitalsState extends Equatable {
  const VitalsState();

  @override
  List<Object?> get props => [];
}

class VitalsInitial extends VitalsState {}

class VitalsLoading extends VitalsState {}

class VitalsLoaded extends VitalsState {
  final List<VitalsModel> vitalsList;
  final VitalsModel? vitals;
  final bool isUpdating;
  final String? updateSuccessMessage;
  final String searchQuery;

  const VitalsLoaded({
    this.vitalsList = const [],
    this.vitals,
    this.isUpdating = false,
    this.updateSuccessMessage,
    this.searchQuery = '',
  });

  VitalsLoaded copyWith({
    List<VitalsModel>? vitalsList,
    VitalsModel? vitals,
    bool? isUpdating,
    String? updateSuccessMessage,
    String? searchQuery,
  }) {
    return VitalsLoaded(
      vitalsList: vitalsList ?? this.vitalsList,
      vitals: vitals ?? this.vitals,
      isUpdating: isUpdating ?? this.isUpdating,
      updateSuccessMessage: updateSuccessMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [vitalsList, vitals, isUpdating, updateSuccessMessage, searchQuery];
}

class VitalsError extends VitalsState {
  final String message;

  const VitalsError(this.message);

  @override
  List<Object?> get props => [message];
}

