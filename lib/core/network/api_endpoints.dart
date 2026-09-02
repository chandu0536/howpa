import 'package:howpa_nurse/core/env.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL (Configured in Env)
  static String get baseUrl => Env.fullApiUrl;

  // 1. Authentication
  static const String sendOtp = '/nurse/auth/send-otp';
  static const String verifyOtp = '/nurse/auth/verify-otp';

  // 2. Profile & Specializations
  static const String profile = '/nurse/profile'; // GET (info) & PUT (update)
  static const String specializations = '/nurse/specializations'; // GET

  // 3. Verification Documents
  static const String documents = '/nurse/documents'; // GET & POST (upload)

  // 4. Dashboard & Location
  static const String dashboard = '/nurse/dashboard'; // GET
  static const String status = '/nurse/status'; // PUT (toggle online)
  static const String location = '/nurse/location'; // POST (update live GPS)

  // 5. Visits & Vitals Workflow
  static const String requests = '/nurse/requests'; // GET (broadcasts near me) & POST (accept broadcast)
  static const String visits = '/nurse/visits'; // PATCH (update status / complete)
  static const String vitals = '/nurse/vitals'; // GET (search) & POST (update record)
  static const String reports = '/nurse/reports'; // POST (submit completion report)
  static const String history = '/nurse/history'; // GET (completed visits history)

  // 6. Wallet & History
  static const String earnings = '/nurse/earnings'; // GET (ledger) & POST (request payout)
  static const String wallet = '/nurse/wallet'; // GET (wallet info)

  // 7. Profile, Settings & Notifications
  static const String settings = '/nurse/settings'; // PUT (device alerts/tracking)
  static const String notifications = '/nurse/notifications'; // GET, PATCH, DELETE
  static const String deviceToken = '/nurse/notifications/device-token'; // POST (register), DELETE (unregister)

  // Backward compatibility aliases
  static const String dashboardStats = dashboard;
  static const String updateDutyStatus = status;
  static const String updateVisitStatus = visits;
  static const String updateVitals = vitals;
  static const String earningsSummary = wallet;
  static const String earningsHistory = earnings;
  static const String withdrawRequest = earnings;
  static const String nurseProfile = profile;
  static const String updateProfile = profile;
}

