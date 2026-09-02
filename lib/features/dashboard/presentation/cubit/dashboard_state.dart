import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_data_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardDataModel data;
  final bool isTogglingDuty;

  const DashboardLoaded({
    required this.data,
    this.isTogglingDuty = false,
  });

  DashboardLoaded copyWith({
    DashboardDataModel? data,
    bool? isTogglingDuty,
  }) {
    return DashboardLoaded(
      data: data ?? this.data,
      isTogglingDuty: isTogglingDuty ?? this.isTogglingDuty,
    );
  }

  @override
  List<Object?> get props => [data, isTogglingDuty];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
