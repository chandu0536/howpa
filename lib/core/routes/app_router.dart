import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_number_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_step1_screen.dart';
import '../../features/auth/presentation/screens/registration_step2_screen.dart';
import '../../features/auth/presentation/screens/verification_in_progress_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/nurse_dashboard_screen.dart';
import '../../features/visits/presentation/screens/visits_screen.dart';
import '../../features/vitals/presentation/screens/vitals_screen.dart';
import '../../features/vitals/presentation/screens/update_vitals_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen.dart';
import '../../features/profile/presentation/screens/payment_earnings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case AppRoutes.phoneLogin:
        return MaterialPageRoute(builder: (_) => const PhoneNumberScreen());

      case AppRoutes.otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OtpScreen(
            countryCode: args?['countryCode'] ?? '+91',
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

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

      case AppRoutes.mainNav:
        return MaterialPageRoute(builder: (_) => const NurseDashboardScreen());

      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const NurseDashboardScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.visits:
        return MaterialPageRoute(builder: (_) => const VisitsScreen());

      case AppRoutes.vitals:
        return MaterialPageRoute(builder: (_) => const VitalsScreen());

      case AppRoutes.updateVitals:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UpdateVitalsScreen(
            patientName: args?['patientName'] ?? 'Patient',
            avatarUrl: args?['avatarUrl'] ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
          ),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.personalDetails:
        return MaterialPageRoute(builder: (_) => const PersonalDetailsScreen());

      case AppRoutes.paymentEarnings:
        return MaterialPageRoute(builder: (_) => const PaymentEarningsScreen());

      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

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
