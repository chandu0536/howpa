import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Core
import 'core/network/api_client.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_ui.dart';

// Repositories
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/visits/data/repositories/visits_repository.dart';
import 'features/vitals/data/repositories/vitals_repository.dart';
import 'features/payment_earnings/data/repositories/payment_earnings_repository.dart';
import 'features/profile/data/repositories/profile_repository.dart';

// Cubits
import 'features/auth/presentation/cubit/splash_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/registration_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/visits/presentation/cubit/visits_cubit.dart';
import 'features/vitals/presentation/cubit/vitals_cubit.dart';
import 'features/payment_earnings/presentation/cubit/payment_earnings_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUi.setLightStatusBar();
  await SystemUi.lockPortrait();

  // Log all Cubit/Bloc state transitions in Debug Console
  Bloc.observer = AppBlocObserver();

  // Initialize Firebase & Notifications in background without blocking UI startup
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    NotificationService().initialize();
  }).catchError((e) {
    if (kDebugMode) {
      debugPrint('Firebase initialization notice: $e');
    }
  });

  final apiClient = ApiClient();

  runApp(MyApp(apiClient: apiClient));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;

  const MyApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(apiClient: apiClient),
        ),
        RepositoryProvider<DashboardRepository>(
          create: (_) => DashboardRepository(apiClient: apiClient),
        ),
        RepositoryProvider<VisitsRepository>(
          create: (_) => VisitsRepository(apiClient: apiClient),
        ),
        RepositoryProvider<VitalsRepository>(
          create: (_) => VitalsRepository(apiClient: apiClient),
        ),
        RepositoryProvider<PaymentEarningsRepository>(
          create: (_) => PaymentEarningsRepository(apiClient: apiClient),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (_) => ProfileRepository(apiClient: apiClient),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SplashCubit>(
            create: (ctx) => SplashCubit(
              authRepository: ctx.read<AuthRepository>(),
            ),
          ),
          BlocProvider<AuthCubit>(
            create: (ctx) => AuthCubit(
              authRepository: ctx.read<AuthRepository>(),
            ),
          ),
          BlocProvider<RegistrationCubit>(
            create: (ctx) => RegistrationCubit(
              authRepository: ctx.read<AuthRepository>(),
              profileRepository: ctx.read<ProfileRepository>(),
            ),
          ),
          BlocProvider<DashboardCubit>(
            create: (ctx) => DashboardCubit(
              repository: ctx.read<DashboardRepository>(),
            ),
          ),
          BlocProvider<VisitsCubit>(
            create: (ctx) => VisitsCubit(
              repository: ctx.read<VisitsRepository>(),
            ),
          ),
          BlocProvider<VitalsCubit>(
            create: (ctx) => VitalsCubit(
              repository: ctx.read<VitalsRepository>(),
            ),
          ),
          BlocProvider<PaymentEarningsCubit>(
            create: (ctx) => PaymentEarningsCubit(
              repository: ctx.read<PaymentEarningsRepository>(),
            ),
          ),
          BlocProvider<ProfileCubit>(
            create: (ctx) => ProfileCubit(
              repository: ctx.read<ProfileRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Howpa Nurse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
