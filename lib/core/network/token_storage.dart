import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _keyToken = 'nurse_jwt_token';
  static const String _keyPhone = 'nurse_phone';
  static const String _keyIsOnline = 'nurse_is_online';
  static const String _keyFcmToken = 'nurse_fcm_token';

  static String? _cachedToken;
  static String? _cachedFcmToken;
  static bool? _cachedIsOnline;

  /// Get stored JWT token
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_keyToken);
    return _cachedToken;
  }

  /// Synchronously get cached token if available
  static String? get cachedToken => _cachedToken;

  /// Synchronously get cached online status
  static bool get isOnline => _cachedIsOnline ?? true;

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// Save nurse phone
  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }

  /// Get nurse phone
  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  /// Save duty status (Online/Offline)
  static Future<void> saveOnlineStatus(bool isOnline) async {
    _cachedIsOnline = isOnline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOnline, isOnline);
  }

  /// Get duty status
  static Future<bool> getOnlineStatus() async {
    if (_cachedIsOnline != null) return _cachedIsOnline!;
    final prefs = await SharedPreferences.getInstance();
    _cachedIsOnline = prefs.getBool(_keyIsOnline) ?? true;
    return _cachedIsOnline!;
  }

  /// Save FCM Device Token
  static Future<void> saveFcmToken(String token) async {
    _cachedFcmToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, token);
  }

  /// Get FCM Device Token
  static Future<String?> getFcmToken() async {
    if (_cachedFcmToken != null) return _cachedFcmToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedFcmToken = prefs.getString(_keyFcmToken);
    return _cachedFcmToken;
  }

  /// Save Bank Details for Payouts
  static const String _keyBankAcc = 'payout_bank_acc';
  static const String _keyBankIfsc = 'payout_bank_ifsc';
  static const String _keyBankHolder = 'payout_bank_holder';
  static const String _keyBankName = 'payout_bank_name';
  static const String _keyUpiId = 'payout_upi_id';

  static Future<void> saveBankDetails({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
    required String bankName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBankAcc, accountNumber);
    await prefs.setString(_keyBankIfsc, ifscCode);
    await prefs.setString(_keyBankHolder, accountHolderName);
    await prefs.setString(_keyBankName, bankName);
  }

  static Future<Map<String, String>> getSavedBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accountNumber': prefs.getString(_keyBankAcc) ?? '',
      'ifscCode': prefs.getString(_keyBankIfsc) ?? '',
      'accountHolderName': prefs.getString(_keyBankHolder) ?? '',
      'bankName': prefs.getString(_keyBankName) ?? '',
    };
  }

  static Future<void> saveUpiId(String upiId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUpiId, upiId);
  }

  static Future<String?> getSavedUpiId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUpiId);
  }

  /// Clear all stored tokens and session data on logout
  static Future<void> clear() async {
    _cachedToken = null;
    _cachedFcmToken = null;
    _cachedIsOnline = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyIsOnline);
    await prefs.remove(_keyUpiId);
    await prefs.remove(_keyBankAcc);
    await prefs.remove(_keyBankIfsc);
    await prefs.remove(_keyBankHolder);
    await prefs.remove(_keyBankName);
  }
}
