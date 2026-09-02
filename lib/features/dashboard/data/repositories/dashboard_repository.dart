import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/dashboard_data_model.dart';

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository({required this.apiClient});

  /// Fetch Dashboard Stats & Schedule: GET /api/nurse/dashboard
  Future<DashboardDataModel> getDashboardData() async {
    try {
      final response = await apiClient.get(ApiEndpoints.dashboard);
      if (response != null && response is Map<String, dynamic>) {
        return DashboardDataModel.fromJson(response);
      }
      return DashboardDataModel.empty();
    } catch (_) {
      return DashboardDataModel.empty();
    }
  }

  /// Toggle Online Status: PUT /api/nurse/status
  Future<bool> setDutyStatus(bool isOnDuty) async {
    try {
      final response = await apiClient.put(
        ApiEndpoints.status,
        body: {'isOnline': isOnDuty},
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Update Live Location (Proximity): POST /api/nurse/location
  Future<bool> updateLiveLocation({
    required double latitude,
    required double longitude,
    double heading = 90,
    double speed = 5,
    double accuracy = 3,
    int battery = 88,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.location,
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'heading': heading,
          'speed': speed,
          'accuracy': accuracy,
          'battery': battery,
        },
      );
      if (response != null && response is Map<String, dynamic>) {
        return response['success'] ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}

