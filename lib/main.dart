import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_ui.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUI.setDarkStatusBar();

  // Initialize Firebase & FCM Push Notification Service
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase push notification initialization warning: $e');
  }

  // Prevent crash & white screens on unexpected UI exceptions
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Captured Flutter Error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Captured PlatformDispatcher Error: $error');
    return true; // Handled safely without crashing the app process
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.healing_rounded, color: Color(0xFF0052FF), size: 36),
              SizedBox(height: 8),
              Text(
                'Something went wrong. Please refresh.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const HowpaNurseApp());
}

class HowpaNurseApp extends StatefulWidget {
  const HowpaNurseApp({super.key});

  @override
  State<HowpaNurseApp> createState() => _HowpaNurseAppState();
}

class _HowpaNurseAppState extends State<HowpaNurseApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger notification permission dialog as soon as the app window is mounted & visible
      PushNotificationService.instance.requestNotificationPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Howpa Nurse',
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
