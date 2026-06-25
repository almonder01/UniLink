import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notifyPosts = true;
  bool _notifyEvents = true;
  bool _notifyReminders = true;
  bool _notifyClubUpdates = true;

  ThemeMode get themeMode => _themeMode;
  bool get notifyPosts => _notifyPosts;
  bool get notifyEvents => _notifyEvents;
  bool get notifyReminders => _notifyReminders;
  bool get notifyClubUpdates => _notifyClubUpdates;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _fromString(prefs.getString('theme_mode') ?? 'system');
    _notifyPosts = prefs.getBool('notify_posts') ?? true;
    _notifyEvents = prefs.getBool('notify_events') ?? true;
    _notifyReminders = prefs.getBool('notify_reminders') ?? true;
    _notifyClubUpdates = prefs.getBool('notify_clubs') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _toString(mode));
    notifyListeners();
  }

  Future<void> setNotifyPosts(bool val) async {
    _notifyPosts = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_posts', val);
    notifyListeners();
  }

  Future<void> setNotifyEvents(bool val) async {
    _notifyEvents = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_events', val);
    notifyListeners();
  }

  Future<void> setNotifyReminders(bool val) async {
    _notifyReminders = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_reminders', val);
    notifyListeners();
  }

  Future<void> setNotifyClubUpdates(bool val) async {
    _notifyClubUpdates = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_clubs', val);
    notifyListeners();
  }

  ThemeMode _fromString(String val) {
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
