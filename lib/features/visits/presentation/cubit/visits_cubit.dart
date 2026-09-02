import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/visits_repository.dart';
import 'visits_state.dart';


class VisitsCubit extends Cubit<VisitsState> {
  final VisitsRepository repository;

  VisitsCubit({required this.repository}) : super(VisitsInitial());

  Future<void> fetchVisits() async {
    emit(VisitsLoading());
    try {
      final broadcastReqs = await repository.getBroadcastRequests();
      final allVisits = await repository.getVisits();
      final completed = await repository.getCompletedHistory();

      final inProgress = allVisits.where((v) {
        final st = v.status.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
        return st == 'IN_PROGRESS' || st == 'ARRIVING' || st == 'ON_THE_WAY' || st == 'ONTHEWAY' || st == 'ARRIVED' || st == 'STARTED';
      }).toList();

      final todayAssigned = allVisits.where((v) {
        final st = v.status.toUpperCase();
        final time = v.appointmentTime.toLowerCase();
        final isTodayTime = time.contains('today') || time.contains('am') || time.contains('pm');
        return (st == 'ASSIGNED' || st == 'CONFIRMED' || st == 'ACCEPTED' || isTodayTime) &&
            !inProgress.contains(v) &&
            !st.contains('UPCOMING');
      }).toList();

      final upcoming = allVisits.where((v) {
        final st = v.status.toUpperCase();
        final time = v.appointmentTime.toLowerCase();
        return st == 'UPCOMING' ||
            st == 'SCHEDULED' ||
            time.contains('tomorrow') ||
            time.contains('scheduled') ||
            (!inProgress.contains(v) && !todayAssigned.contains(v) && st != 'COMPLETED');
      }).toList();

      final allCompleted = [
        ...completed,
        ...allVisits.where((v) => v.status.toUpperCase() == 'COMPLETED' && !completed.any((c) => c.id == v.id)),
      ];

      emit(VisitsLoaded(
        broadcastRequests: broadcastReqs,
        assignedVisits: todayAssigned,
        inProgressVisits: inProgress,
        upcomingVisits: upcoming,
        completedVisits: allCompleted,
      ));
    } catch (e) {
      emit(VisitsError(e.toString()));
    }
  }

  void changeTab(int index) {
    if (state is VisitsLoaded) {
      emit((state as VisitsLoaded).copyWith(selectedTabIndex: index));
    }
  }

  Future<bool> acceptRequest(String appointmentId) async {
    try {
      final success = await repository.acceptBroadcastRequest(appointmentId);
      if (success) {
        if (state is VisitsLoaded) {
          final current = state as VisitsLoaded;
          final updatedBroadcasts = current.broadcastRequests.where((r) => r.appointmentId != appointmentId).toList();
          emit(current.copyWith(
            broadcastRequests: updatedBroadcasts,
            actionMessage: 'Booking request accepted successfully!',
          ));
        }
        await fetchVisits();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateVisitStatus(String appointmentId, String newStatus) async {
    if (state is VisitsLoaded) {
      final current = state as VisitsLoaded;
      final updatedAssigned = current.assignedVisits.map((v) {
        if (v.appointmentId == appointmentId || v.id == appointmentId) {
          return v.copyWith(status: newStatus);
        }
        return v;
      }).toList();
      final updatedUpcoming = current.upcomingVisits.map((v) {
        if (v.appointmentId == appointmentId || v.id == appointmentId) {
          return v.copyWith(status: newStatus);
        }
        return v;
      }).toList();
      final updatedInProgress = current.inProgressVisits.map((v) {
        if (v.appointmentId == appointmentId || v.id == appointmentId) {
          return v.copyWith(status: newStatus);
        }
        return v;
      }).toList();

      if (newStatus == 'ARRIVING' || newStatus == 'IN_PROGRESS' || newStatus == 'STARTED') {
        final existingMatch = [
          ...current.assignedVisits,
          ...current.upcomingVisits,
          ...current.inProgressVisits,
        ].firstWhere(
          (v) => v.appointmentId == appointmentId || v.id == appointmentId,
          orElse: () => VisitModel(
            id: appointmentId,
            appointmentId: appointmentId,
            patientName: 'Patient',
            patientAge: '',
            patientGender: '',
            serviceName: 'Nursing Visit',
            serviceBadge: 'Home Visit',
            appointmentTime: 'Today',
            address: '',
            distance: 'Nearby',
            fee: '₹500',
            status: newStatus,
            avatarUrl: '',
          ),
        );
        final updatedMatch = existingMatch.copyWith(status: newStatus);
        if (!updatedInProgress.any((v) => v.appointmentId == appointmentId || v.id == appointmentId)) {
          updatedInProgress.insert(0, updatedMatch);
        } else {
          final idx = updatedInProgress.indexWhere((v) => v.appointmentId == appointmentId || v.id == appointmentId);
          if (idx != -1) updatedInProgress[idx] = updatedMatch;
        }
      }

      emit(current.copyWith(
        assignedVisits: updatedAssigned,
        upcomingVisits: updatedUpcoming,
        inProgressVisits: updatedInProgress,
      ));
    }

    try {
      await repository.updateVisitStatus(appointmentId, newStatus);
      await fetchVisits();
    } catch (_) {}
  }

  Future<bool> submitVisitReport({
    required String requestId,
    required String findings,
    required String treatmentGiven,
  }) async {
    try {
      final success = await repository.submitVisitReport(
        requestId: requestId,
        findings: findings,
        treatmentGiven: treatmentGiven,
      );
      if (success) {
        await updateVisitStatus(requestId, 'COMPLETED');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

