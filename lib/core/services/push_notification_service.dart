// ignore_for_file: deprecated_member_use, avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../../firebase_options.dart';
import '../network/token_storage.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../features/notifications/data/models/notification_models.dart';
import 'booking_notification_manager.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('🔥 [FCM BACKGROUND PUSH NOTIFICATION] Message ID: ${message.messageId}');
  debugPrint('🔥 [FCM BACKGROUND PUSH NOTIFICATION] Data: ${message.data}');

  final data = message.data;
  final type = (data['type'] ?? data['action'] ?? '').toString().toUpperCase();

  // If visit was taken/assigned/cancelled or dismissed, cleanup active buzzer popup
  if (type == 'VISIT_ASSIGNED' ||
      type == 'VISIT_CANCELLED' ||
      type == 'VISIT_TAKEN' ||
      type == 'REQUEST_EXPIRED' ||
      type == 'DISMISS_NURSE_REQUEST' ||
      type == 'DISMISS_POPUP') {
    final requestId = (data['requestId'] ?? data['visitId'] ?? data['id'] ?? '').toString();
    if (requestId.isNotEmpty) {
      BookingNotificationManager.dismissIfMatching(requestId);
    }
  }

  // 1. ELIMINATE DUPLICATE NOTIFICATIONS:
  // If the backend already provided an FCM `notification` block, Android OS automatically
  // displays it in the system tray when in the background. Calling local notifications
  // would display a duplicate notification for the exact same event.
  if (message.notification != null) {
    debugPrint('ℹ️ FCM notification payload automatically rendered by Android OS.');
    return;
  }

  // 2. ELIMINATE DUMMY / SILENT NOTIFICATIONS:
  // Only display a notification for data-only messages if there is genuine, non-silent content.
  try {
    final content = PushNotificationService.extractNotificationContent(message);
    if (content != null &&
        content['title'] != null &&
        content['title']!.isNotEmpty &&
        content['body'] != null &&
        content['body']!.isNotEmpty) {
      await PushNotificationService.initLocalNotifications();
      await PushNotificationService.showSystemNotification(
        title: content['title']!,
        body: content['body']!,
        data: message.data,
      );
    } else {
      debugPrint('ℹ️ Silent/data event processed in background without showing dummy notification.');
    }
  } catch (e) {
    debugPrint('⚠️ Error in background notification handler: $e');
  }
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._internal();
  PushNotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final NotificationsRepository _notificationsRepo = NotificationsRepositoryImpl();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? currentToken;

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isLocalNotificationsInitialized = false;

  /// Global callback for when a notification is tapped
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initialize Local Notifications (Channel, Icon, Large Logo, High Importance)
  static Future<void> initLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;
    try {
      const androidInit = AndroidInitializationSettings('ic_notification');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              instance._handleNotificationAction(data);
            } catch (_) {}
          }
        },
      );

      final List<AndroidNotificationChannel> channels = [
        const AndroidNotificationChannel(
          'howpa_nurse_channel',
          'Howpa Nurse Notifications',
          description: 'Notifications for Howpa Nurse booking requests and updates',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'default',
          'Default Notifications',
          description: 'General updates and admin notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'howpa_channel',
          'Howpa Notifications',
          description: 'Howpa system announcements and notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'fcm_default_channel',
          'FCM Notifications',
          description: 'Push notifications from Admin',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Urgent announcements and visit alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      ];

      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        for (final ch in channels) {
          await androidImpl.createNotificationChannel(ch);
        }
      }

      _isLocalNotificationsInitialized = true;
      debugPrint('✅ [LOCAL NOTIFICATIONS] Initialized successfully with Howpa channel & logo.');
    } catch (e) {
      debugPrint('⚠️ Error initializing local notifications: $e');
    }
  }

  /// Show a system tray notification with the Howpa Logo & Full Matter
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await initLocalNotifications();

      String channelId = 'howpa_nurse_channel';
      String channelName = 'Howpa Nurse Notifications';
      if (data != null) {
        final incomingChannel = (data['channel_id'] ?? data['android_channel_id'] ?? data['channel'])?.toString();
        if (incomingChannel != null && incomingChannel.isNotEmpty) {
          channelId = incomingChannel;
          if (channelId == 'default') {
            channelName = 'Default Notifications';
          } else if (channelId == 'howpa_channel') {
            channelName = 'Howpa Notifications';
          } else if (channelId == 'fcm_default_channel') {
            channelName = 'FCM Notifications';
          } else if (channelId == 'high_importance_channel') {
            channelName = 'High Importance Notifications';
          }
        }
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications for Howpa Nurse booking requests and updates',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF0052FF),
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Howpa Nurse',
        ),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final payloadString = data != null ? jsonEncode(data) : null;

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payloadString,
      );
      debugPrint('🔔 [SYSTEM NOTIFICATION DISPLAYED] Title: $title | Body: $body');
    } catch (e) {
      debugPrint('⚠️ Error showing local system notification: $e');
    }
  }

  /// Extracts comprehensive Title and Matter/Body from both notification and data payloads.
  /// Returns null for silent events or data payloads with no visible notification content
  /// to prevent spurious/dummy notifications.
  static Map<String, String>? extractNotificationContent(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? data['action'] ?? '').toString().toUpperCase();

    // Check if explicitly marked silent or an internal synchronization/cleanup action
    if (data['silent'] == 'true' ||
        data['silent'] == true ||
        type == 'DISMISS_NURSE_REQUEST' ||
        type == 'DISMISS_POPUP' ||
        type == 'SYNC' ||
        type == 'PING') {
      return null;
    }

    final Map<String, dynamic> mergedData = Map<String, dynamic>.from(data);
    if (data['notification'] is Map) {
      mergedData.addAll(Map<String, dynamic>.from(data['notification'] as Map));
    } else if (data['notification'] is String) {
      try {
        final parsed = jsonDecode(data['notification'] as String);
        if (parsed is Map) {
          mergedData.addAll(Map<String, dynamic>.from(parsed));
        }
      } catch (_) {}
    }
    if (data['data'] is Map) {
      mergedData.addAll(Map<String, dynamic>.from(data['data'] as Map));
    } else if (data['data'] is String) {
      try {
        final parsed = jsonDecode(data['data'] as String);
        if (parsed is Map) {
          mergedData.addAll(Map<String, dynamic>.from(parsed));
        }
      } catch (_) {}
    }

    // 1. Resolve Title
    String title = (message.notification?.title ?? '').trim();
    if (title.isEmpty) {
      for (final key in [
        'title',
        'heading',
        'subject',
        'header',
        'notification_title',
        'notificationTitle',
        'alert_title',
        'alertTitle',
        'topic',
      ]) {
        final val = mergedData[key]?.toString().trim();
        if (val != null && val.isNotEmpty && val != 'null') {
          title = val;
          break;
        }
      }
    }

    final patientName = (mergedData['patientName'] ?? mergedData['patient_name'] ?? mergedData['name'] ?? '').toString().trim();

    if (title.isEmpty) {
      if (type.contains('VISIT') || type.contains('BOOKING')) {
        title = patientName.isNotEmpty
            ? '🚨 New Visit: $patientName'
            : '🚨 New Patient Visit Request';
      } else if (type.contains('CANCEL') || type.contains('EXPIRED')) {
        title = 'Visit Request Cancelled';
      } else if (type.contains('ASSIGNED') || type.contains('TAKEN')) {
        title = 'Visit Request Assigned';
      } else if (type.contains('VITAL')) {
        title = 'Patient Vitals Update';
      }
    }

    // 2. Resolve Body / Matter
    String body = (message.notification?.body ?? '').trim();
    if (body.isEmpty) {
      for (final key in [
        'body',
        'message',
        'msg',
        'desc',
        'description',
        'text',
        'alert',
        'content',
        'notification_body',
        'notificationBody',
        'notification_message',
        'notificationMessage',
        'details',
        'note',
      ]) {
        final val = mergedData[key]?.toString().trim();
        if (val != null && val.isNotEmpty && val != 'null') {
          body = val;
          break;
        }
      }
    }

    if (body.isEmpty) {
      final service = (mergedData['service'] ??
              mergedData['serviceTag'] ??
              mergedData['serviceName'] ??
              mergedData['service_tag'] ??
              '')
          .toString()
          .trim();
      final address = (mergedData['address'] ?? mergedData['location'] ?? mergedData['area'] ?? '').toString().trim();

      final parts = <String>[];
      if (patientName.isNotEmpty) parts.add('Patient: $patientName');
      if (service.isNotEmpty) parts.add('Service: $service');
      if (address.isNotEmpty) parts.add('Location: $address');

      if (parts.isNotEmpty) {
        body = parts.join(' • ');
      } else if (type.contains('VISIT') || type.contains('BOOKING')) {
        body = 'A new patient visit request has just arrived nearby. Tap to view and accept.';
      }
    }

    // Smart Fallbacks so admin notifications are NEVER discarded
    if (title.isEmpty && body.isNotEmpty) {
      title = 'Howpa Nurse';
    } else if (body.isEmpty && title.isNotEmpty) {
      body = title;
      title = 'Howpa Nurse';
    }

    if (title.isEmpty && body.isEmpty) {
      return null;
    }

    return {'title': title, 'body': body};
  }

  /// Initialize Firebase & Push Notification Listeners
  Future<void> initialize() async {
    try {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase Core initialized successfully.');
      } catch (e) {
        debugPrint('ℹ️ Firebase.initializeApp status: $e');
      }

      // Initialize Local Notification Channel with Howpa branding
      await initLocalNotifications();

      // Background Message Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Enable Foreground Presentation for heads-up alerts
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Fetch and print FCM Token
      await fetchAndPrintToken();

      // Listen for Token Refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('🔥 [FCM TOKEN REFRESHED]');
        _printTokenBox(newToken);
        currentToken = newToken;
        TokenStorage.saveFcmToken(newToken);
        syncTokenWithBackend(token: newToken);
      });

      // Foreground Push Notification Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🔔 [FOREGROUND PUSH NOTIFICATION RECEIVED]');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body:  ${message.notification?.body}');
        debugPrint('Data:  ${message.data}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        _handleForegroundMessage(message);
      });

      // Notification Clicked from Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 [PUSH NOTIFICATION OPENED APP]');
        debugPrint('Data: ${message.data}');
        _handleNotificationAction(message.data);
      });

      // Initial Message when app opened from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 [PUSH NOTIFICATION INITIAL MESSAGE]');
        debugPrint('Data: ${initialMessage.data}');
        _handleNotificationAction(initialMessage.data);
      }
    } catch (e, stack) {
      debugPrint('⚠️ PushNotificationService initialize error: $e\n$stack');
    }
  }

  /// Request system notification permissions (Android 13+ POST_NOTIFICATIONS & iOS)
  Future<bool> requestNotificationPermissions() async {
    try {
      debugPrint('🔔 [NOTIFICATION PERMISSION] Requesting runtime notification permission...');

      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('🔔 [FIREBASE_MESSAGING] Authorization status: ${settings.authorizationStatus}');

      // Also request notification permission explicitly via Android local notifications on Android 13+
      try {
        final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          final localGranted = await androidImpl.requestNotificationsPermission();
          debugPrint('🔔 [LOCAL_NOTIFICATIONS] Android 13+ permission status: $localGranted');
        }
      } catch (e) {
        debugPrint('ℹ️ Local notification permission check: $e');
      }

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isGranted) {
        debugPrint('✅ [NOTIFICATION PERMISSION] Granted! Fetching and syncing FCM token...');
        await fetchAndPrintToken();
        await syncTokenWithBackend();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ [NOTIFICATION PERMISSION] Denied by user in device settings.');
      }

      return isGranted;
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION PERMISSION] Error: $e');
      return false;
    }
  }

  /// Check current notification permission status
  Future<bool> isNotificationPermissionGranted() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Open app notification settings if permanently disabled
  Future<void> openNotificationSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('⚠️ Could not open app settings: $e');
    }
  }

  /// Fetches FCM token and prints it clearly in the console
  Future<String?> fetchAndPrintToken() async {
    try {
      final token = await _fcm.getToken();
      currentToken = token;
      if (token != null && token.isNotEmpty) {
        await TokenStorage.saveFcmToken(token);
        _printTokenBox(token);
        // Sync with backend if user already logged in
        await syncTokenWithBackend(token: token);
      } else {
        debugPrint('⚠️ FCM Token is null or empty.');
      }
      return token;
    } catch (e) {
      debugPrint('⚠️ Failed to get FCM token: $e');
      return null;
    }
  }

  /// Syncs FCM token with Backend API
  Future<void> syncTokenWithBackend({String? token}) async {
    final fcmToken = token ?? currentToken ?? await TokenStorage.getFcmToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    final jwt = await TokenStorage.getToken();
    if (jwt == null || jwt.isEmpty) {
      debugPrint('ℹ️ User not logged in yet. FCM token will sync upon authentication.');
      return;
    }

    try {
      final success = await _notificationsRepo.registerDeviceToken(
        DeviceTokenRegistrationRequest(
          token: fcmToken,
          platform: defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
        ),
      );
      if (success) {
        debugPrint('✅ FCM Token successfully registered with backend server.');
      } else {
        debugPrint('ℹ️ Device token registration sent to server.');
      }
    } catch (e) {
      debugPrint('⚠️ Error registering FCM token with backend: $e');
    }
  }

  /// Unregister FCM token on logout
  Future<void> unregisterToken() async {
    try {
      final token = currentToken ?? await TokenStorage.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _notificationsRepo.unregisterDeviceToken(token);
      }
      await _fcm.deleteToken();
      currentToken = null;
      debugPrint('✅ FCM Device Token unregistered.');
    } catch (e) {
      debugPrint('⚠️ Error unregistering FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? data['action'] ?? '').toString().toUpperCase();

    // If visit was taken/assigned/cancelled by another nurse or dismissed, auto-dismiss active pop-up!
    if (type == 'VISIT_ASSIGNED' ||
        type == 'VISIT_CANCELLED' ||
        type == 'VISIT_TAKEN' ||
        type == 'REQUEST_EXPIRED' ||
        type == 'DISMISS_NURSE_REQUEST' ||
        type == 'DISMISS_POPUP') {
      final requestId = (data['requestId'] ?? data['visitId'] ?? data['id'] ?? '').toString();
      if (requestId.isNotEmpty) {
        BookingNotificationManager.dismissIfMatching(requestId);
      }
    }

    final content = extractNotificationContent(message);
    if (content == null) return;

    final resolvedTitle = content['title']!;
    final resolvedBody = content['body']!;

    // Show floating in-app banner overlay immediately
    _showForegroundInAppBanner(
      message,
      resolvedTitle: resolvedTitle,
      resolvedBody: resolvedBody,
    );

    // Always show system notification in the status bar tray with sound & vibration
    showSystemNotification(
      title: resolvedTitle,
      body: resolvedBody,
      data: message.data,
    );
  }

  void _showForegroundInAppBanner(
    RemoteMessage message, {
    String? resolvedTitle,
    String? resolvedBody,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = resolvedTitle ?? message.notification?.title ?? message.data['title'] ?? 'Howpa Notification';
    final body = resolvedBody ?? message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  entry?.remove();
                  _handleNotificationAction(message.data);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFFF5C00).withOpacity(0.35), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Howpa App Logo in Foreground Banner
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/howpa_logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF5C00), size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                            ),
                            if (body.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () => entry?.remove(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      navigatorKey.currentState?.overlay?.insert(entry);
      Future.delayed(const Duration(seconds: 5), () {
        if (entry != null && entry.mounted) {
          entry.remove();
        }
      });
    } catch (e) {
      debugPrint('⚠️ Could not show overlay banner: $e');
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
      return;
    }
    final type = (data['type'] ?? data['action'] ?? '').toString().toUpperCase();
    if (type == 'VISIT_REQUEST' || type == 'NEW_REQUEST' || type == 'BOOKING' || type == 'VISIT') {
      navigatorKey.currentState?.pushNamed('/visits');
    } else {
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  void _printTokenBox(String token) {
    // Prints prominently across all consoles (debugPrint, Flutter Run console, logcat)
    print('\n');
    print('╔═══════════════════════════════════════════════════════════════════════════════════════════╗');
    print('║                                  🔥 HOWPA NURSE FCM TOKEN                                 ║');
    print('╠═══════════════════════════════════════════════════════════════════════════════════════════╣');
    print('  $token');
    print('╚═══════════════════════════════════════════════════════════════════════════════════════════╝');
    print('\n');
  }
}
