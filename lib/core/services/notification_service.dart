import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../../features/visits/data/models/visit_model.dart';
import 'sound_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    debugPrint('Handling background message: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<BroadcastRequestModel> _appointmentRequestsController =
      StreamController<BroadcastRequestModel>.broadcast();

  Stream<BroadcastRequestModel> get onAppointmentReceived =>
      _appointmentRequestsController.stream;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for critical notifications like visit assignments.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize({
    Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    // 1. Request FCM permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );

    if (kDebugMode) {
      debugPrint('User granted notification permission: ${settings.authorizationStatus}');
    }

    // 2. Set up Android Notification Channel
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    // 3. Initialize Local Notifications
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (kDebugMode) {
          debugPrint('Notification clicked: ${response.payload}');
        }
      },
    );

    // 4. Set Foreground notification presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Get Device FCM Token
    await _fetchToken();

    // 6. Listen for Token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      if (kDebugMode) {
        debugPrint('FCM Token refreshed: $newToken');
      }
    });

    // 7. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Received foreground notification: ${message.notification?.title ?? message.data}');
      }
      final title = message.notification?.title?.toLowerCase() ?? '';
      final body = message.notification?.body?.toLowerCase() ?? '';
      final type = message.data['type']?.toString().toLowerCase() ?? '';
      final action = message.data['action']?.toString().toLowerCase() ?? '';
      final event = message.data['event']?.toString().toLowerCase() ?? '';
      
      final isAppointment = title.contains('appointment') ||
          title.contains('visit') ||
          title.contains('request') ||
          title.contains('booking') ||
          title.contains('patient') ||
          body.contains('appointment') ||
          body.contains('visit') ||
          body.contains('request') ||
          body.contains('booking') ||
          type.contains('appointment') ||
          type.contains('visit') ||
          type.contains('request') ||
          type.contains('booking') ||
          action.contains('appointment') ||
          action.contains('visit') ||
          action.contains('request') ||
          action.contains('booking') ||
          event.contains('appointment') ||
          event.contains('visit') ||
          event.contains('request');

      if (isAppointment) {
        SoundService.instance.playBuzzer(loop: true);
        try {
          final Map<String, dynamic> mergedData = Map<String, dynamic>.from(message.data);
          if (message.notification != null) {
            mergedData['patientName'] ??= message.notification!.title;
            mergedData['doctorNote'] ??= message.notification!.body;
            final img = message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl;
            if (img != null && img.isNotEmpty) {
              mergedData['avatarUrl'] ??= img;
            }
          }
          final req = BroadcastRequestModel.fromJson(mergedData);
          _appointmentRequestsController.add(req);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing dynamic appointment from FCM: $e');
          }
        }
      }
      _showLocalNotification(message);
    });

    // 8. Handle Notification Opened from Background state
    void handleOpenedNotification(RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Notification opened app with payload: ${message.data}');
      }
      try {
        final Map<String, dynamic> mergedData = Map<String, dynamic>.from(message.data);
        if (message.notification != null) {
          mergedData['patientName'] ??= message.notification!.title;
          mergedData['doctorNote'] ??= message.notification!.body;
          final img = message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl;
          if (img != null && img.isNotEmpty) {
            mergedData['avatarUrl'] ??= img;
          }
        }
        final req = BroadcastRequestModel.fromJson(mergedData);
        _appointmentRequestsController.add(req);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error dispatching appointment on notification open: $e');
        }
      }
      onNotificationOpened?.call(message);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleOpenedNotification);

    // 9. Handle Notification Opened when app was Terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      handleOpenedNotification(initialMessage);
    }
  }

  Future<String?> getDeviceFcmToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken;
    }
    await _fetchToken();
    return _fcmToken;
  }

  Future<void> _fetchToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      if (kDebugMode) {
        debugPrint('FCM Registration Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching FCM token: $e');
      }
    }
  }

  /// Explicitly trigger a local push notification alert for new visit requests
  Future<void> showVisitRequestNotification({
    required String patientName,
    required String serviceType,
    required String fee,
    required String distance,
    String? appointmentId,
  }) async {
    final title = '🚨 New Visit Request: $patientName';
    final body = '$serviceType • $distance • $fee';
    final notificationId = appointmentId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'HowPA Nurse Visit Alert',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: appointmentId ?? '',
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    String? title = message.notification?.title;
    String? body = message.notification?.body;

    // Support data-only push notifications from backend
    if (title == null || title.isEmpty) {
      title = message.data['title']?.toString() ??
          message.data['patientName']?.toString() ??
          message.data['name']?.toString() ??
          'New Patient Visit Request';
    }
    if (body == null || body.isEmpty) {
      final service = message.data['serviceType'] ?? message.data['service'] ?? '';
      final fee = message.data['fee'] ?? '';
      final distance = message.data['distance'] ?? '';
      if (service.toString().isNotEmpty || fee.toString().isNotEmpty) {
        body = '$service ${fee.toString().isNotEmpty ? "• $fee" : ""} ${distance.toString().isNotEmpty ? "• $distance" : ""}'.trim();
      } else {
        body = message.data['body']?.toString() ??
            message.data['doctorNote']?.toString() ??
            'You have received a new patient visit request.';
      }
    }

    final notificationId = message.messageId.hashCode != 0
        ? message.messageId.hashCode
        : DateTime.now().millisecondsSinceEpoch;

    _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'HowPA Nurse Notification',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
}
