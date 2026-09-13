import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;

  DashboardCubit({required this.repository}) : super(DashboardInitial());

  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent && state is! DashboardLoaded) {
      emit(DashboardLoading());
    }
    try {
      final data = await repository.getDashboardData();
      emit(DashboardLoaded(data: data));
    } catch (e) {
      if (state is! DashboardLoaded) {
        emit(DashboardError(e.toString()));
      }
    }
  }

  Future<void> toggleDutyStatus(bool newStatus) async {
    if (state is! DashboardLoaded) return;
    final current = (state as DashboardLoaded);
    emit(current.copyWith(isTogglingDuty: true));
    try {
      await repository.setDutyStatus(newStatus);
      final updatedData = current.data.copyWith(isOnline: newStatus);
      emit(DashboardLoaded(data: updatedData, isTogglingDuty: false));
    } catch (_) {
      final updatedData = current.data.copyWith(isOnline: newStatus);
      emit(DashboardLoaded(data: updatedData, isTogglingDuty: false));
    }
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double heading = 90,
    double speed = 5,
    double accuracy = 3,
    int battery = 88,
  }) async {
    try {
      await repository.updateLiveLocation(
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
        accuracy: accuracy,
        battery: battery,
      );
    } catch (_) {}
  }
}

