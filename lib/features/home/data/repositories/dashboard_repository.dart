import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/token_storage.dart';
import '../models/dashboard_models.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getDashboard();
  Future<bool> streamLocation(LiveTelemetryRequest request);
  Future<bool> toggleDutyStatus(bool isOnline);
}

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _client;

  DashboardRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<DashboardStats> getDashboard() async {
    try {
      final response = await _client.get(ApiEndpoints.dashboard);
      if (response != null && response['data'] != null) {
        return DashboardStats.fromJson(response['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return const DashboardStats();
  }

  @override
  Future<bool> streamLocation(LiveTelemetryRequest request) async {
    try {
      await _client.post(ApiEndpoints.location, body: request.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> toggleDutyStatus(bool isOnline) async {
    try {
      final response = await _client.put(ApiEndpoints.status, body: {'isOnline': isOnline});
      if (response is Map && response['success'] == false) {
        return false;
      }
      await TokenStorage.saveOnlineStatus(isOnline);
      return true;
    } catch (_) {
      return false;
    }
  }
}
