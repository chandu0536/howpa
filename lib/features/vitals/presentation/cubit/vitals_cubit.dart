import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/vitals_model.dart';
import '../../data/repositories/vitals_repository.dart';
import 'vitals_state.dart';

class VitalsCubit extends Cubit<VitalsState> {
  final VitalsRepository repository;

  VitalsCubit({required this.repository}) : super(VitalsInitial());

  /// 1. Fetch All Assigned Patients & Vitals List: GET /api/nurse/vitals
  Future<void> fetchVitalsList({String? search}) async {
    emit(VitalsLoading());
    try {
      final list = await repository.getVitalsList(search: search);
      emit(VitalsLoaded(
        vitalsList: list,
        vitals: list.isNotEmpty ? list.first : null,
        searchQuery: search ?? '',
      ));
    } catch (e) {
      emit(VitalsError(e.toString()));
    }
  }

  /// 2. Get Vitals for a Specific Appointment: GET /api/nurse/vitals?appointmentId=...
  Future<VitalsModel?> fetchVitalsByAppointment(String appointmentId) async {
    try {
      final vitals = await repository.getVitalsByAppointment(appointmentId);
      if (vitals != null) {
        if (state is VitalsLoaded) {
          final current = state as VitalsLoaded;
          emit(current.copyWith(vitals: vitals));
        }
      }
      return vitals;
    } catch (_) {
      return null;
    }
  }

  /// Backward compatible single patient vitals fetch
  Future<void> fetchVitals(String patientId) async {
    emit(VitalsLoading());
    try {
      final vitals = await repository.getVitals(patientId);
      final list = await repository.getVitalsList();
      emit(VitalsLoaded(vitals: vitals, vitalsList: list));
    } catch (e) {
      emit(VitalsError(e.toString()));
    }
  }

  /// 3. Record / Save Patient Vitals: POST /api/nurse/vitals
  Future<bool> recordVitals({
    required VitalsRecordRequest request,
    String? patientName,
    String? avatarUrl,
  }) async {
    try {
      final success = await repository.recordVitals(request);
      final list = await repository.getVitalsList();

      if (list.isNotEmpty) {
        emit(VitalsLoaded(
          vitalsList: list,
          vitals: list.firstWhere(
            (v) => v.appointmentId == request.appointmentId || v.id == request.appointmentId,
            orElse: () => list.first,
          ),
          updateSuccessMessage: 'Vitals recorded successfully!',
        ));
      } else if (patientName != null && patientName.isNotEmpty) {
        final newRecord = VitalsModel(
          id: request.appointmentId,
          appointmentId: request.appointmentId,
          patientId: request.appointmentId,
          patientName: patientName,
          bloodPressure: request.bloodPressure,
          heartRate: request.heartRate != null ? '${request.heartRate} bpm' : '72 bpm',
          temperature: request.temperature != null ? '${request.temperature} °F' : '98.6 °F',
          bloodSugar: request.bloodSugar != null ? '${request.bloodSugar} mg/dL' : '95 mg/dL',
          spo2: request.spo2 != null ? '${request.spo2}%' : '99%',
          weight: request.weight != null ? '${request.weight} kg' : '68.5 kg',
          hasVitals: true,
          reason: request.reason,
          notes: request.notes,
          lastUpdated: 'Just now',
          avatarUrl: avatarUrl != null && avatarUrl.isNotEmpty
              ? avatarUrl
              : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        );

        final currentList = state is VitalsLoaded ? (state as VitalsLoaded).vitalsList : <VitalsModel>[];
        final updatedList = [
          newRecord,
          ...currentList.where((e) => e.appointmentId != request.appointmentId && e.id != request.appointmentId),
        ];

        emit(VitalsLoaded(
          vitalsList: updatedList,
          vitals: newRecord,
          updateSuccessMessage: 'Vitals recorded successfully!',
        ));
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateVitals(VitalsModel vitals) async {
    if (state is! VitalsLoaded) return;
    final current = state as VitalsLoaded;
    emit(current.copyWith(isUpdating: true));
    try {
      await repository.updateVitals(vitals);
      await fetchVitalsList();
      emit(current.copyWith(
        vitals: vitals,
        isUpdating: false,
        updateSuccessMessage: 'Vitals updated successfully!',
      ));
    } catch (e) {
      emit(current.copyWith(isUpdating: false));
    }
  }
}


