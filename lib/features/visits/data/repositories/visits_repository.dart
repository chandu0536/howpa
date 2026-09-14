import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/visit_models.dart';

abstract class VisitsRepository {
  Future<List<VisitRequestItem>> getNearbyRequests();
  Future<List<VisitRequestItem>> getTodayVisits();
  Future<List<VisitRequestItem>> getUpcomingVisits();
  Future<bool> acceptVisitRequest(String appointmentId);
  Future<bool> rejectVisitRequest(String appointmentId);
  Future<bool> updateVisitStatus(String appointmentId, String status);
  Future<bool> recordPatientVitals(RecordVitalsRequest request);
  Future<List<dynamic>> getVitalsHistory({String? search});
  Future<bool> submitDiagnosticReport(SubmitReportRequest request);
  Future<List<VisitRequestItem>> getCompletedVisitHistory();
}

class VisitsRepositoryImpl implements VisitsRepository {
  final ApiClient _client;

  VisitsRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<List<VisitRequestItem>> getNearbyRequests() async {
    try {
      final response = await _client.get(ApiEndpoints.requests);
      if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => VisitRequestItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<VisitRequestItem>> getTodayVisits() async {
    try {
      final response = await _client.get('${ApiEndpoints.visits}?filter=today');
      if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => VisitRequestItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<VisitRequestItem>> getUpcomingVisits() async {
    try {
      final response = await _client.get('${ApiEndpoints.visits}?filter=upcoming');
      if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => VisitRequestItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<bool> acceptVisitRequest(String appointmentId) async {
    try {
      await _client.post(ApiEndpoints.requests, body: {'appointmentId': appointmentId, 'action': 'accept'});
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> rejectVisitRequest(String appointmentId) async {
    try {
      await _client.post(ApiEndpoints.requests, body: {'appointmentId': appointmentId, 'action': 'reject'});
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> updateVisitStatus(String appointmentId, String status) async {
    try {
      await _client.patch(
        ApiEndpoints.visits,
        body: {'appointmentId': appointmentId, 'status': status},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> recordPatientVitals(RecordVitalsRequest request) async {
    try {
      await _client.post(ApiEndpoints.vitals, body: request.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<dynamic>> getVitalsHistory({String? search}) async {
    try {
      final response = await _client.get(
        ApiEndpoints.vitals,
        queryParams: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      if (response != null && response['data'] is List) {
        return response['data'] as List;
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<bool> submitDiagnosticReport(SubmitReportRequest request) async {
    try {
      await _client.post(ApiEndpoints.reports, body: request.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<VisitRequestItem>> getCompletedVisitHistory() async {
    try {
      final response = await _client.get(ApiEndpoints.history);
      if (response != null && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => VisitRequestItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
