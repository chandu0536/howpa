import 'package:flutter/material.dart';
import 'app_routes.dart';

// Auth Screens
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_number_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/registration_step1_screen.dart';
import '../../features/auth/presentation/screens/registration_step2_screen.dart';
import '../../features/auth/presentation/screens/verification_in_progress_screen.dart';

// Feature Screens
import '../../features/dashboard/presentation/screens/nurse_dashboard_screen.dart';
import '../../features/visits/presentation/screens/visits_screen.dart';
import '../../features/vitals/presentation/screens/vitals_screen.dart';
import '../../features/vitals/presentation/screens/update_vitals_screen.dart';
import '../../features/payment_earnings/presentation/screens/payment_earnings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case AppRoutes.phoneNumber:
        return MaterialPageRoute(builder: (_) => const PhoneNumberScreen());

      case AppRoutes.otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OtpScreen(
            countryCode: args?['countryCode'] ?? '+91',
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );

      case AppRoutes.registrationStep1:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RegistrationStep1Screen(
            phoneNumber: args?['phoneNumber'] ?? '+91 98765 43210',
          ),
        );

      case AppRoutes.registrationStep2:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RegistrationStep2Screen(
            phoneNumber: args?['phoneNumber'] ?? '+91 98765 43210',
          ),
        );

      case AppRoutes.verificationInProgress:
        return MaterialPageRoute(builder: (_) => const VerificationInProgressScreen());

      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const NurseDashboardScreen());

      case AppRoutes.visits:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => VisitsScreen(
            initialTabIndex: args?['initialTabIndex'] ?? 0,
            highlightedPatientName: args?['highlightedPatientName'],
          ),
        );

      case AppRoutes.vitals:
        return MaterialPageRoute(builder: (_) => const VitalsScreen());

      case AppRoutes.updateVitals:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UpdateVitalsScreen(
            patientName: args?['patientName'] ?? 'Mrs. Anjali Patel',
            avatarUrl: args?['avatarUrl'] ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
          ),
        );

      case AppRoutes.paymentEarnings:
        return MaterialPageRoute(builder: (_) => const PaymentEarningsScreen());

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.personalDetails:
        return MaterialPageRoute(builder: (_) => const PersonalDetailsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
