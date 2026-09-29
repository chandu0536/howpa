import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUI.setDarkStatusBar();

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

class HowpaNurseApp extends StatelessWidget {
  const HowpaNurseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Howpa Nurse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
