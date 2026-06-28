import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyNotification = 'notification';
  static const _keyLanguage = 'language';
  static const _keyTheme = 'theme_mode';

  // ─── Notification ───────────────────────────────────────────
  Future<String> getNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNotification) ?? 'ON';
  }

  Future<void> saveNotification(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotification, value);
  }

  // ─── Language ────────────────────────────────────────────────
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'ENGLISH';
  }

  Future<void> saveLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
  }

  // ─── Theme Mode ──────────────────────────────────────────────
  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'LIGHT';
  }

  Future<void> saveTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, value);
  }
}
