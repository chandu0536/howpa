class DeviceSettingsModel {
  final bool pushNotificationsEnabled;
  final bool locationTrackingEnabled;
  final String? deviceToken;
  final String? deviceType;

  const DeviceSettingsModel({
    this.pushNotificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.deviceToken,
    this.deviceType,
  });

  factory DeviceSettingsModel.fromJson(Map<String, dynamic> json) {
    return DeviceSettingsModel(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      locationTrackingEnabled: json['locationTrackingEnabled'] ?? true,
      deviceToken: json['deviceToken']?.toString(),
      deviceType: json['deviceType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'pushNotificationsEnabled': pushNotificationsEnabled,
    'locationTrackingEnabled': locationTrackingEnabled,
    if (deviceToken != null && deviceToken!.isNotEmpty) 'deviceToken': deviceToken,
    if (deviceType != null && deviceType!.isNotEmpty) 'deviceType': deviceType,
  };
}

class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime? createdAt;
  final bool isRead;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'GENERAL',
    this.createdAt,
    this.isRead = false,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'isRead': isRead,
  };
}
