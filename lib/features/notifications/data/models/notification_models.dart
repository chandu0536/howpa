class NurseNotificationItem {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String timeText;
  final bool isRead;

  const NurseNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.timeText,
    this.isRead = false,
  });

  factory NurseNotificationItem.fromJson(Map<String, dynamic> json) {
    return NurseNotificationItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? json['desc'] as String? ?? '',
      type: json['type'] as String?,
      timeText: json['createdAt'] as String? ?? json['time'] as String? ?? 'Recently',
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
    );
  }
}

class DeviceTokenRegistrationRequest {
  final String token;
  final String platform;
  final String? deviceId;
  final String? appVersion;

  const DeviceTokenRegistrationRequest({
    required this.token,
    this.platform = 'ANDROID',
    this.deviceId,
    this.appVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'platform': platform,
        if (deviceId != null) 'deviceId': deviceId,
        if (appVersion != null) 'appVersion': appVersion,
      };
}
