import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _userKey = 'current_user';
  static const String _loginTimeKey = 'login_time';
  static const String _sessionDurationKey = 'session_duration';

  // Save user session
  static Future<void> saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userId);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(
        _sessionDurationKey, 7 * 24 * 60 * 60); // 7 days in seconds
  }

  // Get current user ID from session
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  // Check if session is valid
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);
    final sessionDuration = prefs.getInt(_sessionDurationKey) ?? 0;

    if (loginTime == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final sessionEndTime = loginTime + (sessionDuration * 1000);

    return currentTime <= sessionEndTime;
  }

  // Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_sessionDurationKey);
  }

  // Extend session
  static Future<void> extendSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Get session expiry time
  static Future<DateTime?> getSessionExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);
    final sessionDuration = prefs.getInt(_sessionDurationKey) ?? 0;

    if (loginTime == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(
        loginTime + (sessionDuration * 1000));
  }
}
