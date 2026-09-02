import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/vitals_model.dart';

class VitalsRepository {
  final ApiClient apiClient;

  VitalsRepository({required this.apiClient});

  /// 1. Fetch Patient Vitals List: GET /api/nurse/vitals
  /// Optional query parameters:
  /// - `search`: filter by patient name, phone, or address
  /// - `appointmentId`: filter for a specific appointment
  Future<List<VitalsModel>> getVitalsList({String? search, String? appointmentId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      if (appointmentId != null && appointmentId.trim().isNotEmpty) {
        params['appointmentId'] = appointmentId.trim();
      }

      final response = await apiClient.get(
        ApiEndpoints.vitals,
        queryParameters: params.isNotEmpty ? params : null,
      );

      List<dynamic>? rawList;
      if (response != null) {
        if (response is List) {
          rawList = response;
        } else if (response is Map) {
          final map = response is Map<String, dynamic> ? response : response.cast<String, dynamic>();
          final dynamic dataField = map['data'] ?? map['result'] ?? map['body'];

          if (dataField is List) {
            rawList = dataField;
          } else if (dataField is Map) {
            final nested = dataField.cast<String, dynamic>();
            rawList = (nested['vitals'] ??
                nested['records'] ??
                nested['patients'] ??
                nested['appointments'] ??
                nested['list'] ??
                nested['items'] ??
                nested['data']) as List?;

            if (rawList == null &&
                (nested.containsKey('appointmentId') ||
                    nested.containsKey('patientName') ||
                    nested.containsKey('patientId') ||
                    nested.containsKey('_id') ||
                    nested.containsKey('id') ||
                    nested.containsKey('vitals'))) {
              return [VitalsModel.fromJson(nested)];
            }
          }

          rawList ??= (map['vitals'] ??
              map['records'] ??
              map['patients'] ??
              map['appointments'] ??
              map['list'] ??
              map['items']) as List?;
        }
      }

      if (rawList != null && rawList.isNotEmpty) {
        final List<VitalsModel> list = [];
        for (final item in rawList) {
          if (item is Map) {
            try {
              list.add(VitalsModel.fromJson(item.cast<String, dynamic>()));
            } catch (e, stack) {
              debugPrint('Error parsing VitalsModel item: $e\n$stack');
            }
          }
        }
        return list;
      }

      return [];
    } catch (e, stack) {
      debugPrint('VitalsRepository getVitalsList error: $e\n$stack');
      return [];
    }
  }

  /// 2. Get Vitals for a Specific Appointment: GET /api/nurse/vitals?appointmentId=...
  Future<VitalsModel?> getVitalsByAppointment(String appointmentId) async {
    try {
      final list = await getVitalsList(appointmentId: appointmentId);
      if (list.isNotEmpty) {
        return list.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 3. Record / Save Patient Vitals: POST /api/nurse/vitals
  Future<bool> recordVitals(VitalsRecordRequest request) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.vitals,
        body: request.toJson(),
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] == true ||
            response['status'] == true ||
            response['statusCode'] == 200 ||
            response['data'] != null;
      }
      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// Backward compatible helper
  Future<VitalsModel?> getVitals(String patientId) async {
    try {
      final list = await getVitalsList();
      final matches = list.where((e) => e.patientId == patientId || e.appointmentId == patientId || e.id == patientId);
      if (matches.isNotEmpty) {
        return matches.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateVitals(VitalsModel vitals) async {
    num? parseNum(String text) {
      final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return num.tryParse(clean);
    }

    final appointmentId = vitals.appointmentId.isNotEmpty
        ? vitals.appointmentId
        : (vitals.id.isNotEmpty ? vitals.id : vitals.patientId);

    return recordVitals(
      VitalsRecordRequest(
        appointmentId: appointmentId.isNotEmpty ? appointmentId : '6a9677047d61f0bb7ee9e499',
        bloodPressure: vitals.bloodPressure,
        heartRate: parseNum(vitals.heartRate),
        temperature: parseNum(vitals.temperature),
        bloodSugar: parseNum(vitals.bloodSugar),
        spo2: parseNum(vitals.spo2),
        weight: parseNum(vitals.weight),
        reason: vitals.reason,
        notes: vitals.notes,
      ),
    );
  }
}



