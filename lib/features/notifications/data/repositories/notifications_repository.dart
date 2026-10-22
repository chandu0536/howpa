import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_models.dart';

abstract class NotificationsRepository {
  Future<List<NurseNotificationItem>> getNotifications();
  Future<bool> markAllAsRead();
  Future<bool> deleteNotification(String notificationId);
  Future<bool> registerDeviceToken(DeviceTokenRegistrationRequest request);
  Future<bool> unregisterDeviceToken(String token);
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiClient _client;

  NotificationsRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<List<NurseNotificationItem>> getNotifications() async {
    try {
      final response = await _client.get(ApiEndpoints.notifications);
      if (response != null && response is Map<String, dynamic>) {
        final listData = response['notifications'] ?? response['data'];
        if (listData is List) {
          return listData
              .map((item) => NurseNotificationItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<bool> markAllAsRead() async {
    try {
      final response = await _client.patch(ApiEndpoints.notifications, body: {'markAll': true, 'all': true});
      if (response is Map && response['success'] == false) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _client.delete(
        ApiEndpoints.notifications,
        queryParams: {'notificationId': notificationId},
      );
      if (response is Map && response['success'] == false) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> registerDeviceToken(DeviceTokenRegistrationRequest request) async {
    bool registered = false;
    final body = request.toJson();

    // 1. Primary endpoint: /api/nurse/notifications/device-token
    try {
      final response = await _client.post(ApiEndpoints.deviceToken, body: body);
      if (response != null && (response is! Map || response['success'] != false)) {
        registered = true;
      }
    } catch (_) {}

    // 2. Direct nurse device token endpoint: /api/nurse/device-token
    try {
      final response = await _client.post('${ApiEndpoints.baseUrl}/api/nurse/device-token', body: body);
      if (response != null && (response is! Map || response['success'] != false)) {
        registered = true;
      }
    } catch (_) {}

    // 3. Direct nurse FCM token endpoint: /api/nurse/fcm-token
    try {
      final response = await _client.post('${ApiEndpoints.baseUrl}/api/nurse/fcm-token', body: body);
      if (response != null && (response is! Map || response['success'] != false)) {
        registered = true;
      }
    } catch (_) {}

    // 4. Update nurse profile with fcmToken: PUT /api/nurse/profile
    try {
      final response = await _client.put(
        ApiEndpoints.profile,
        body: {
          'fcmToken': request.token,
          'deviceToken': request.token,
          'pushToken': request.token,
          'deviceType': 'android',
          'platform': 'ANDROID',
        },
      );
      if (response != null && (response is! Map || response['success'] != false)) {
        registered = true;
      }
    } catch (_) {}

    // 5. Update nurse settings with deviceToken: PUT /api/nurse/settings
    try {
      final response = await _client.put(
        ApiEndpoints.settings,
        body: {
          'fcmToken': request.token,
          'deviceToken': request.token,
          'deviceType': 'android',
          'platform': 'ANDROID',
        },
      );
      if (response != null && (response is! Map || response['success'] != false)) {
        registered = true;
      }
    } catch (_) {}

    return registered;
  }

  @override
  Future<bool> unregisterDeviceToken(String token) async {
    try {
      final response = await _client.delete(
        ApiEndpoints.deviceToken,
        queryParams: {'token': token},
      );
      if (response is Map && response['success'] == false) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
