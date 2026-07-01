import 'package:flutter/material.dart';
import '../service/setting_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  String _notification = 'ON';
  String _language = 'ENGLISH';
  String _themeMode = 'LIGHT';

  String get notification => _notification;
  String get language => _language;
  String get themeMode => _themeMode;

  ThemeMode get flutterThemeMode =>
      _themeMode == 'DARK' ? ThemeMode.dark : ThemeMode.light;

  // ─── Load all settings at startup ───────────────────────────
  Future<void> loadSettings() async {
    _notification = await _service.getNotification();
    _language = await _service.getLanguage();
    _themeMode = await _service.getTheme();
    notifyListeners();
  }

  // ─── Notification ───────────────────────────────────────────
  Future<void> setNotification(String value) async {
    await _service.saveNotification(value);
    _notification = value;
    notifyListeners();
  }

  // ─── Language ────────────────────────────────────────────────
  Future<void> setLanguage(String value) async {
    await _service.saveLanguage(value);
    _language = value;
    notifyListeners();
  }

  // ─── Theme ───────────────────────────────────────────────────
  Future<void> setTheme(String value) async {
    await _service.saveTheme(value);
    _themeMode = value;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == 'LIGHT' ? 'DARK' : 'LIGHT';
    await setTheme(next);
  }
}
