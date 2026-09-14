import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUI.setDarkStatusBar();
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
