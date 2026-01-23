import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _kThemeModeKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system; // 시스템 기본

  ThemeProvider() {
    _restore();
  }

  ThemeMode get mode => _mode;

  bool get isSystem => _mode == ThemeMode.system;
  bool get isLight => _mode == ThemeMode.light;
  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    _persist(mode);
  }

  void setSystem() => setMode(ThemeMode.system);
  void setLight() => setMode(ThemeMode.light);
  void setDark() => setMode(ThemeMode.dark);

  void toggleLightDark() {
    if (_mode == ThemeMode.dark) {
      setLight();
    } else {
      setDark();
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemeModeKey);
      final restored = _decode(saved);
      if (restored != _mode) {
        _mode = restored;
        notifyListeners();
      }
    } catch (_) {
      // ignore restore failures
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, _encode(mode));
    } catch (_) {
      // ignore persistence failures
    }
  }

  String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
