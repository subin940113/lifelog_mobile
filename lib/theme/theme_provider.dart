import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system; // 시스템 기본

  ThemeMode get mode => _mode;

  bool get isSystem => _mode == ThemeMode.system;
  bool get isLight => _mode == ThemeMode.light;
  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
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
}