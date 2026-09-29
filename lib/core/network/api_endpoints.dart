import '../utils/constants.dart';

class ApiEndpoints {
  static String get baseUrl => AppConstants.baseUrl;

  // 1. Authentication & Onboarding
  static String get sendOtp => '$baseUrl/api/nurse/auth/send-otp';
  static String get verifyOtp => '$baseUrl/api/nurse/auth/verify-otp';

  // 2. Profile & KYC Documents
  static String get profile => '$baseUrl/api/nurse/profile';
  static String get documents => '$baseUrl/api/nurse/documents';

  // 3. Dashboard, Location & Duty Status
  static String get dashboard => '$baseUrl/api/nurse/dashboard';
  static String get location => '$baseUrl/api/nurse/location';
  static String get status => '$baseUrl/api/nurse/status';

  // 4. Requests & Visit Lifecycle
  static String get requests => '$baseUrl/api/nurse/requests';
  static String get requestsAccept => '$baseUrl/api/nurse/requests/accept';
  static String get requestsReject => '$baseUrl/api/nurse/requests/reject';
  static String get visits => '$baseUrl/api/nurse/visits';
  static String get vitals => '$baseUrl/api/nurse/vitals';
  static String get reports => '$baseUrl/api/nurse/reports';
  static String get history => '$baseUrl/api/nurse/history';

  // 5. Wallet, Payouts & Settings
  static String get earnings => '$baseUrl/api/nurse/earnings';
  static String get wallet => '$baseUrl/api/nurse/wallet';
  static String get cares => '$baseUrl/api/nurse/cares';
  static String get specializations => '$baseUrl/api/nurse/specializations';
  static String get settings => '$baseUrl/api/nurse/settings';

  // 6. Notifications & Device Tokens
  static String get notifications => '$baseUrl/api/nurse/notifications';
  static String get deviceToken => '$baseUrl/api/nurse/notifications/device-token';
}
