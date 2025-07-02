import 'package:flutter/material.dart';

class AppTheme extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Padrão para tema do sistema

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && WidgetsBinding.instance.window.platformBrightness == Brightness.dark);

  void toggleTheme() {
    // Alterna entre claro e escuro se não estiver no modo sistema
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // Se estiver no modo sistema, alternar para o oposto do brilho atual da plataforma
      _themeMode = WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
