import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _keyToken = 'nurse_jwt_token';
  static const String _keyPhone = 'nurse_phone';
  static const String _keyIsOnline = 'nurse_is_online';

  static String? _cachedToken;
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

  /// Clear all stored tokens on logout
  static Future<void> clear() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyPhone);
  }
}
