import 'package:equatable/equatable.dart';
import '../../data/models/visit_model.dart';

abstract class VisitsState extends Equatable {
  const VisitsState();

  @override
  List<Object?> get props => [];
}

class VisitsInitial extends VisitsState {}

class VisitsLoading extends VisitsState {}

class VisitsLoaded extends VisitsState {
  final List<BroadcastRequestModel> broadcastRequests;
  final List<VisitModel> assignedVisits;
  final List<VisitModel> inProgressVisits;
  final List<VisitModel> upcomingVisits;
  final List<VisitModel> completedVisits;
  final int selectedTabIndex;
  final String? actionMessage;

  const VisitsLoaded({
    this.broadcastRequests = const [],
    required this.assignedVisits,
    required this.inProgressVisits,
    this.upcomingVisits = const [],
    required this.completedVisits,
    this.selectedTabIndex = 0,
    this.actionMessage,
  });

  VisitsLoaded copyWith({
    List<BroadcastRequestModel>? broadcastRequests,
    List<VisitModel>? assignedVisits,
    List<VisitModel>? inProgressVisits,
    List<VisitModel>? upcomingVisits,
    List<VisitModel>? completedVisits,
    int? selectedTabIndex,
    String? actionMessage,
  }) {
    return VisitsLoaded(
      broadcastRequests: broadcastRequests ?? this.broadcastRequests,
      assignedVisits: assignedVisits ?? this.assignedVisits,
      inProgressVisits: inProgressVisits ?? this.inProgressVisits,
      upcomingVisits: upcomingVisits ?? this.upcomingVisits,
      completedVisits: completedVisits ?? this.completedVisits,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        broadcastRequests,
        assignedVisits,
        inProgressVisits,
        upcomingVisits,
        completedVisits,
        selectedTabIndex,
        actionMessage,
      ];
}

class VisitsError extends VisitsState {
  final String message;

  const VisitsError(this.message);

  @override
  List<Object?> get props => [message];
}

