class AppConstants {
  static const String appName = 'Howpa Nurse';
  static const String appVersion = '1.0.0';

  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyBBfALT0fQbrlVav4d-Fyj7KuVswEnrfck';

  // API Base URL (Configurable)
  static String baseUrl = 'https://howpa.vercel.app';
  static const String loginEndpoint = '/auth/login';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/nurse/profile';
  static const String visitsEndpoint = '/nurse/visits';
  static const String vitalsEndpoint = '/nurse/vitals';

  // Shared Preferences / Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String isOnboardedKey = 'is_onboarded';
}
