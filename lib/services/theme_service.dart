import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _prefKey = 'selected_theme_mode';
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else if (savedMode == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else {
        themeModeNotifier.value = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'system';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      await prefs.setString(_prefKey, val);
    } catch (_) {}
  }

  Future<void> cycleTheme() async {
    ThemeMode next;
    if (themeModeNotifier.value == ThemeMode.system) {
      next = ThemeMode.light;
    } else if (themeModeNotifier.value == ThemeMode.light) {
      next = ThemeMode.dark;
    } else {
      next = ThemeMode.system;
    }
    await setThemeMode(next);
  }

  IconData get themeIcon {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String getThemeName(bool isBangla) {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return isBangla ? "লাইট" : "Light";
      case ThemeMode.dark:
        return isBangla ? "ডার্ক" : "Dark";
      case ThemeMode.system:
        return isBangla ? "অটো" : "Auto";
    }
  }
}
